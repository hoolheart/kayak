//! 环节执行引擎模块
//!
//! 提供试验过程的环节执行能力，支持 Start、Read、Control、Delay、End
//! 五种基础环节类型的线性顺序执行。
//!
//! # 架构
//! - `StepEngine`: 核心引擎，负责编排环节执行
//! - `ExecutionListener`: 执行事件监听器 trait
//! - `StepExecutor`: 环节执行器 trait
//! - `DriverAccess`: 设备访问抽象 trait
//! - `DriverAccessAdapter`: 将 DeviceDriver 适配为 DriverAccess
//!
//! # 使用示例
//! ```ignore
//! let engine = StepEngine::new(device_manager, None);
//! let process_def = ProcessDefinition::from_json(json_value)?;
//! let context = engine.execute(&process_def, device_id).await?;
//! ```

mod adapter;
mod executor;
mod listener;
mod step_engine;
mod steps;
mod types;

// 公开导出所有类型
pub use adapter::DriverAccessAdapter;
pub use executor::{DriverAccess, StepExecutor};
pub use listener::ExecutionListener;
pub use step_engine::StepEngine;
pub use steps::{
    ControlStepExecutor, DelayStepExecutor, EndStepExecutor, ReadStepExecutor, StartStepExecutor,
};
pub use types::{
    EngineError, ExecutionContext, ExecutionError, ExecutionStatus,
    ParseError, ProcessDefinition, ProcessResult, StepDefinition, StepLogEntry, StepResult,
    StepStatus, StepType,
};
