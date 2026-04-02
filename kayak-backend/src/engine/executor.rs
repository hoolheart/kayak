//! 环节执行器 trait 和设备访问抽象 trait
//!
//! 定义了环节执行器的统一接口，以及设备访问的抽象层。

use async_trait::async_trait;
use uuid::Uuid;

use super::types::{ExecutionContext, ExecutionError, StepDefinition, StepResult};
use crate::drivers::core::PointValue;

/// 设备访问抽象 trait
///
/// 为环节执行器提供统一的设备测点读写接口，屏蔽具体驱动实现的差异。
/// 引擎通过此 trait 向 StepExecutor 提供设备访问能力，遵循依赖倒置原则。
///
/// # 实现方式
/// - 对于 S2-009 阶段，可为 `VirtualDriver` 提供 blanket impl
/// - 未来可为其他驱动类型（Modbus、CAN 等）分别实现此 trait
pub trait DriverAccess: Send + Sync {
    /// 读取指定测点的值
    ///
    /// # 注意
    /// 此方法为同步调用，实现应保证快速返回，避免长时间阻塞。
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError>;

    /// 向指定测点写入值
    ///
    /// # 注意
    /// 此方法为同步调用，实现应保证快速返回，避免长时间阻塞。
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError>;
}

/// 环节执行器 trait
///
/// 每种环节类型（Start、Read、Control、Delay、End）实现此 trait，
/// 提供统一的执行接口。
///
/// # 依赖倒置
/// 此 trait 通过 `DriverAccess` trait 抽象设备访问，不依赖任何具体驱动类型。
/// 这使得 StepExecutor 可与任何实现了 DriverAccess 的驱动配合使用。
#[async_trait]
pub trait StepExecutor: Send + Sync {
    /// 返回此执行器处理的环节类型名称
    ///
    /// # 用途
    /// 此方法主要用于日志记录和调试目的。引擎在分发环节执行时，
    /// 可通过此方法获取环节类型的字符串表示，用于日志输出和错误信息。
    /// 例如：`"Executing step [{}] type: {}"`, step.id(), executor.step_type()
    fn step_type(&self) -> &str;

    /// 执行环节
    ///
    /// # Arguments
    /// * `step` - 环节定义
    /// * `context` - 执行上下文（可变引用，用于存储变量和日志）
    /// * `driver` - 设备访问抽象（Read/Control 环节使用）
    ///
    /// # Returns
    /// * `Ok(StepResult)` - 执行成功
    /// * `Err(ExecutionError)` - 执行失败
    async fn execute(
        &self,
        step: &StepDefinition,
        context: &mut ExecutionContext,
        driver: &dyn DriverAccess,
    ) -> Result<StepResult, ExecutionError>;
}
