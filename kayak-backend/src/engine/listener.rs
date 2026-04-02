//! 执行监听器 trait
//!
//! 实现此 trait 的监听器会在引擎执行过程中收到回调通知。
//! 所有回调方法提供默认空实现，允许监听器只关注感兴趣的事件。
//!
//! # 注意
//! 此 trait 定义需与测试用例文档保持一致。所有方法均有默认空实现，
//! 测试中的 MockExecutionListener 可选择性地覆盖需要验证的回调。

use super::types::{ExecutionError, ProcessResult, StepDefinition, StepResult};

/// 执行监听器 trait
///
/// 实现此 trait 的监听器会在引擎执行过程中收到回调通知。
/// 所有回调方法提供默认空实现，允许监听器只关注感兴趣的事件。
pub trait ExecutionListener: Send + Sync {
    /// 环节开始执行时调用
    fn step_started(&self, _step: &StepDefinition) {
        // 默认空实现
    }

    /// 环节成功完成时调用
    fn step_completed(&self, _step: &StepDefinition, _result: &StepResult) {
        // 默认空实现
    }

    /// 环节执行失败时调用
    fn step_failed(&self, _step: &StepDefinition, _error: &ExecutionError) {
        // 默认空实现
    }

    /// 整个过程执行完成时调用（无论成功或失败）
    fn process_completed(&self, _result: &ProcessResult) {
        // 默认空实现
    }
}
