//! Start 环节执行器
//!
//! 开始环节：标记试验开始，初始化执行上下文。
//! 此环节是幂等的——重复执行不会产生额外副作用。

use async_trait::async_trait;
use chrono::Utc;

use super::super::executor::{DriverAccess, StepExecutor};
use super::super::types::{
    ExecutionContext, ExecutionError, ExecutionStatus, StepDefinition, StepResult,
};

/// Start 环节执行器
pub struct StartStepExecutor;

#[async_trait]
impl StepExecutor for StartStepExecutor {
    fn step_type(&self) -> &str {
        "Start"
    }

    async fn execute(
        &self,
        _step: &StepDefinition,
        context: &mut ExecutionContext,
        _driver: &dyn DriverAccess,
    ) -> Result<StepResult, ExecutionError> {
        let start = std::time::Instant::now();

        // 幂等：仅在未设置时记录开始时间
        if context.start_time.is_none() {
            context.start_time = Some(Utc::now());
        }
        context.status = ExecutionStatus::Running;

        Ok(StepResult {
            duration_ms: start.elapsed().as_millis() as u64,
            data: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::drivers::core::PointValue;
    use uuid::Uuid;

    #[tokio::test]
    async fn test_start_sets_running_status() {
        let mut ctx = ExecutionContext::new();
        let executor = StartStepExecutor;
        let result = executor
            .execute(
                &StepDefinition::Start {
                    id: "s1".to_string(),
                    name: "Start".to_string(),
                },
                &mut ctx,
                &MockDriver,
            )
            .await
            .unwrap();

        assert_eq!(ctx.status, ExecutionStatus::Running);
        assert!(ctx.start_time.is_some());
        assert!(result.data.is_none());
    }

    #[tokio::test]
    async fn test_start_is_idempotent() {
        let mut ctx = ExecutionContext::new();
        let executor = StartStepExecutor;

        executor
            .execute(
                &StepDefinition::Start {
                    id: "s1".to_string(),
                    name: "Start".to_string(),
                },
                &mut ctx,
                &MockDriver,
            )
            .await
            .unwrap();
        let first_time = ctx.start_time.unwrap();

        // Execute again
        executor
            .execute(
                &StepDefinition::Start {
                    id: "s1".to_string(),
                    name: "Start".to_string(),
                },
                &mut ctx,
                &MockDriver,
            )
            .await
            .unwrap();

        // start_time should not change
        assert_eq!(ctx.start_time.unwrap(), first_time);
        assert_eq!(ctx.status, ExecutionStatus::Running);
    }

    struct MockDriver;
    impl DriverAccess for MockDriver {
        fn read_point(&self, _point_id: Uuid) -> Result<PointValue, ExecutionError> {
            unreachable!("read_point should not be called in Start tests")
        }
        fn write_point(&self, _point_id: Uuid, _value: PointValue) -> Result<(), ExecutionError> {
            unreachable!("write_point should not be called in Start tests")
        }
    }
}
