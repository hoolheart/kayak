//! 环节执行引擎
//!
//! 负责解析过程定义并按线性顺序执行环节。
//!
//! # 线程安全
//! `StepEngine` 本身不要求 `Sync`，但可以在多个线程间共享（通过 `Arc`），
//! 因为 `execute` 方法每次调用都创建独立的 `ExecutionContext`。

// Note: clippy warning about await_holding_lock is suppressed because
// the lock is intentionally held across the step execution for consistency.
#![allow(clippy::await_holding_lock)]

use std::sync::Arc;

use super::adapter::DriverAccessAdapter;
use super::executor::{DriverAccess, StepExecutor};
use super::listener::ExecutionListener;
use super::steps::{
    ControlStepExecutor, DelayStepExecutor, EndStepExecutor, ReadStepExecutor, StartStepExecutor,
};
use super::types::*;
use crate::drivers::manager::DeviceManager;
use chrono::Utc;

/// 环节执行引擎
pub struct StepEngine {
    /// 设备管理器，用于获取驱动实例
    device_manager: Arc<DeviceManager>,
    /// 可选的执行监听器
    listener: Option<Arc<dyn ExecutionListener>>,
}

impl StepEngine {
    /// 创建新的执行引擎
    pub fn new(
        device_manager: Arc<DeviceManager>,
        listener: Option<Arc<dyn ExecutionListener>>,
    ) -> Self {
        Self {
            device_manager,
            listener,
        }
    }

    /// 执行过程定义
    ///
    /// # Arguments
    /// * `process_def` - 已解析的过程定义（调用方负责在调用前完成 JSON 解析）
    /// * `device_id` - 要使用的设备 ID（S2-009 阶段使用单一设备）
    ///
    /// # Returns
    /// * `Ok(ExecutionContext)` - 执行成功，context.status == Completed
    /// * `Err(EngineError::ExecutionFailed { context, source_error })` - 执行失败，
    ///   context.status == Failed，调用方可从错误变体中获取上下文
    /// * `Err(EngineError::DeviceNotFound)` - 指定设备不存在
    /// * `Err(EngineError::LockError)` - 获取驱动锁失败
    pub async fn execute(
        &self,
        process_def: &ProcessDefinition,
        device_id: uuid::Uuid,
    ) -> Result<ExecutionContext, EngineError> {
        let mut context = ExecutionContext::new();
        let total_steps = process_def.steps.len();

        // 空过程：立即完成
        if total_steps == 0 {
            context.status = ExecutionStatus::Completed;
            return Ok(context);
        }

        // 获取设备驱动
        let driver_lock = self
            .device_manager
            .get_device(device_id)
            .ok_or(EngineError::DeviceNotFound(device_id))?;

        for step in process_def.steps.iter() {
            // 通知监听器
            if let Some(ref listener) = self.listener {
                listener.step_started(step);
            }

            let start_time = Utc::now();

            // 获取驱动的只读引用（读锁）
            // 注意：DeviceDriver::read_point/write_point 使用 &self（非 &mut self），
            // 因此读锁足够。锁在此作用域内持有，步骤执行完毕后自动释放。
            let result = {
                let driver = driver_lock.read().map_err(|_| {
                    EngineError::LockError("Failed to acquire driver lock".to_string())
                })?;

                // 构建 DriverAccess 适配器（泛型版本，支持任何 DeviceDriver 实现）
                let driver_access = DriverAccessAdapter::new(&*driver);

                // 执行环节
                self.execute_step(step, &mut context, &driver_access).await
            };

            let end_time = Utc::now();

            match result {
                Ok(step_result) => {
                    // 成功
                    if let Some(ref listener) = self.listener {
                        listener.step_completed(step, &step_result);
                    }
                    context.log_step(
                        step.id().to_string(),
                        step.step_type(),
                        step.name().to_string(),
                        start_time,
                        end_time,
                        StepStatus::Success,
                        None,
                    );
                }
                Err(e) => {
                    // 失败：记录日志，停止执行
                    if let Some(ref listener) = self.listener {
                        listener.step_failed(step, &e);
                    }
                    context.log_step(
                        step.id().to_string(),
                        step.step_type(),
                        step.name().to_string(),
                        start_time,
                        end_time,
                        StepStatus::Failed,
                        Some(e.to_string()),
                    );
                    context.status = ExecutionStatus::Failed;

                    let process_result = ProcessResult::from_context(&context, total_steps);

                    if let Some(ref listener) = self.listener {
                        listener.process_completed(&process_result);
                    }

                    return Err(EngineError::ExecutionFailed {
                        context,
                        source_error: e,
                    });
                }
            }
        }

        // 所有步骤执行完毕
        context.status = ExecutionStatus::Completed;

        let process_result = ProcessResult::from_context(&context, total_steps);

        if let Some(ref listener) = self.listener {
            listener.process_completed(&process_result);
        }

        Ok(context)
    }

    /// 执行单个环节
    async fn execute_step(
        &self,
        step: &StepDefinition,
        context: &mut ExecutionContext,
        driver: &dyn DriverAccess,
    ) -> Result<StepResult, ExecutionError> {
        match step {
            StepDefinition::Start { .. } => StartStepExecutor.execute(step, context, driver).await,
            StepDefinition::Read { .. } => ReadStepExecutor.execute(step, context, driver).await,
            StepDefinition::Control { .. } => {
                ControlStepExecutor.execute(step, context, driver).await
            }
            StepDefinition::Delay { .. } => DelayStepExecutor.execute(step, context, driver).await,
            StepDefinition::End { .. } => EndStepExecutor.execute(step, context, driver).await,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::drivers::lifecycle::DriverLifecycle;
    use crate::drivers::wrapper::DriverWrapper;
    use crate::drivers::VirtualDriver;

    fn create_test_engine() -> (StepEngine, uuid::Uuid) {
        let manager = Arc::new(DeviceManager::new());
        let device_id = uuid::Uuid::new_v4();
        let driver = DriverWrapper::new_virtual(VirtualDriver::new());
        manager
            .register_device(device_id, driver)
            .expect("Failed to register device");

        let engine = StepEngine::new(manager, None);
        (engine, device_id)
    }

    #[tokio::test]
    async fn test_execute_empty_process() {
        let (engine, device_id) = create_test_engine();
        let process_def = ProcessDefinition {
            version: "1.0".to_string(),
            steps: vec![],
        };

        let result = engine.execute(&process_def, device_id).await;
        assert!(result.is_ok());
        let ctx = result.unwrap();
        assert_eq!(ctx.status, ExecutionStatus::Completed);
        assert!(ctx.logs.is_empty());
    }

    #[tokio::test]
    async fn test_execute_simple_start_end() {
        let (engine, device_id) = create_test_engine();
        let process_def = ProcessDefinition {
            version: "1.0".to_string(),
            steps: vec![
                StepDefinition::Start {
                    id: "s1".to_string(),
                    name: "Start".to_string(),
                },
                StepDefinition::End {
                    id: "e1".to_string(),
                    name: "End".to_string(),
                },
            ],
        };

        let result = engine.execute(&process_def, device_id).await;
        assert!(result.is_ok());
        let ctx = result.unwrap();
        assert_eq!(ctx.status, ExecutionStatus::Completed);
        assert_eq!(ctx.logs.len(), 2);
        assert_eq!(ctx.logs[0].step_type, StepType::Start);
        assert_eq!(ctx.logs[1].step_type, StepType::End);
    }

    #[tokio::test]
    async fn test_execute_full_process() {
        let (engine, device_id) = create_test_engine();

        // Connect the virtual driver first
        {
            let driver_lock = engine.device_manager.get_device(device_id).unwrap();
            let mut driver = driver_lock.write().unwrap();
            driver.connect().await.unwrap();
        }

        let process_def = ProcessDefinition {
            version: "1.0".to_string(),
            steps: vec![
                StepDefinition::Start {
                    id: "s1".to_string(),
                    name: "Start".to_string(),
                },
                StepDefinition::Read {
                    id: "r1".to_string(),
                    name: "Read Temp".to_string(),
                    point_id: "00000000-0000-0000-0000-000000000001".to_string(),
                    target_var: "temperature".to_string(),
                },
                StepDefinition::Delay {
                    id: "d1".to_string(),
                    name: "Wait 10ms".to_string(),
                    duration_ms: 10,
                },
                StepDefinition::End {
                    id: "e1".to_string(),
                    name: "End".to_string(),
                },
            ],
        };

        let result = engine.execute(&process_def, device_id).await;
        assert!(result.is_ok());
        let ctx = result.unwrap();
        assert_eq!(ctx.status, ExecutionStatus::Completed);
        assert_eq!(ctx.logs.len(), 4);
        assert!(ctx.get_variable("temperature").is_some());
    }

    #[tokio::test]
    async fn test_execute_device_not_found() {
        let (engine, _) = create_test_engine();
        let process_def = ProcessDefinition {
            version: "1.0".to_string(),
            steps: vec![StepDefinition::Start {
                id: "s1".to_string(),
                name: "Start".to_string(),
            }],
        };

        let fake_id = uuid::Uuid::new_v4();
        let result = engine.execute(&process_def, fake_id).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            EngineError::DeviceNotFound(id) => assert_eq!(id, fake_id),
            _ => panic!("Expected DeviceNotFound error"),
        }
    }

    #[tokio::test]
    async fn test_execute_with_listener() {
        use std::sync::atomic::{AtomicUsize, Ordering};

        struct TestListener {
            started: AtomicUsize,
            completed: AtomicUsize,
        }

        impl ExecutionListener for TestListener {
            fn step_started(&self, _step: &StepDefinition) {
                self.started.fetch_add(1, Ordering::SeqCst);
            }
            fn step_completed(&self, _step: &StepDefinition, _result: &StepResult) {
                self.completed.fetch_add(1, Ordering::SeqCst);
            }
        }

        let manager = Arc::new(DeviceManager::new());
        let device_id = uuid::Uuid::new_v4();
        let driver = DriverWrapper::new_virtual(VirtualDriver::new());
        manager
            .register_device(device_id, driver)
            .expect("Failed to register device");

        let listener = Arc::new(TestListener {
            started: AtomicUsize::new(0),
            completed: AtomicUsize::new(0),
        });
        let engine = StepEngine::new(manager, Some(listener.clone()));

        let process_def = ProcessDefinition {
            version: "1.0".to_string(),
            steps: vec![
                StepDefinition::Start {
                    id: "s1".to_string(),
                    name: "Start".to_string(),
                },
                StepDefinition::End {
                    id: "e1".to_string(),
                    name: "End".to_string(),
                },
            ],
        };

        let result = engine.execute(&process_def, device_id).await;
        assert!(result.is_ok());
        assert_eq!(listener.started.load(Ordering::SeqCst), 2);
        assert_eq!(listener.completed.load(Ordering::SeqCst), 2);
    }

    #[tokio::test]
    async fn test_execute_fail_fast_on_read_error() {
        use std::sync::atomic::{AtomicUsize, Ordering};

        // Register a VirtualDriver but DON'T connect it — read_point will fail
        let manager = Arc::new(DeviceManager::new());
        let device_id = uuid::Uuid::new_v4();
        let driver = DriverWrapper::new_virtual(VirtualDriver::new());
        manager
            .register_device(device_id, driver)
            .expect("Failed to register device");

        struct FailListener {
            step_failed: AtomicUsize,
            process_completed: AtomicUsize,
        }

        impl ExecutionListener for FailListener {
            fn step_failed(&self, _step: &StepDefinition, _error: &ExecutionError) {
                self.step_failed.fetch_add(1, Ordering::SeqCst);
            }
            fn process_completed(&self, _result: &ProcessResult) {
                self.process_completed.fetch_add(1, Ordering::SeqCst);
            }
        }

        let listener = Arc::new(FailListener {
            step_failed: AtomicUsize::new(0),
            process_completed: AtomicUsize::new(0),
        });
        let engine = StepEngine::new(manager, Some(listener.clone()));

        // Process: Start -> Read -> Control -> End
        // Read should fail (driver not connected), Control and End should NOT execute
        let process_def = ProcessDefinition {
            version: "1.0".to_string(),
            steps: vec![
                StepDefinition::Start {
                    id: "s1".to_string(),
                    name: "Start".to_string(),
                },
                StepDefinition::Read {
                    id: "r1".to_string(),
                    name: "Read Temp".to_string(),
                    point_id: "00000000-0000-0000-0000-000000000001".to_string(),
                    target_var: "temperature".to_string(),
                },
                StepDefinition::Control {
                    id: "c1".to_string(),
                    name: "Control".to_string(),
                    point_id: "00000000-0000-0000-0000-000000000001".to_string(),
                    value: crate::drivers::core::PointValue::Number(50.0),
                },
                StepDefinition::End {
                    id: "e1".to_string(),
                    name: "End".to_string(),
                },
            ],
        };

        let result = engine.execute(&process_def, device_id).await;
        assert!(result.is_err());

        match result.unwrap_err() {
            EngineError::ExecutionFailed {
                context,
                source_error,
            } => {
                // Status should be Failed
                assert_eq!(context.status, ExecutionStatus::Failed);
                // Only Start and Read should have logs (Read failed)
                assert_eq!(context.logs.len(), 2);
                assert_eq!(context.logs[0].step_type, StepType::Start);
                assert_eq!(context.logs[0].status, StepStatus::Success);
                assert_eq!(context.logs[1].step_type, StepType::Read);
                assert_eq!(context.logs[1].status, StepStatus::Failed);
                // Error should be a driver error
                assert!(matches!(source_error, ExecutionError::DriverError(_)));
            }
            _ => panic!("Expected ExecutionFailed error"),
        }

        // Listener callbacks should have fired
        assert_eq!(listener.step_failed.load(Ordering::SeqCst), 1);
        assert_eq!(listener.process_completed.load(Ordering::SeqCst), 1);
    }
}
