//! 设备驱动生命周期管理 trait
//!
//! 定义连接、断开等需要可变访问的操作。
//! 从 DeviceDriver trait 中分离出来，使 DeviceManager 可以统一存储和管理
//! 异构驱动类型的生命周期。

use async_trait::async_trait;

use super::error::DriverError;

/// 设备驱动生命周期管理 trait
///
/// 所有设备驱动（通过 DriverWrapper）必须实现此 trait，提供标准化的连接管理接口。
/// 与 `DeviceDriver` trait 的区别：
/// - `DeviceDriver`：由具体驱动实现（VirtualDriver, ModbusTcpDriver 等）
/// - `DriverLifecycle`：由 `DriverWrapper` 实现，对外提供统一接口
#[async_trait]
pub trait DriverLifecycle: Send + Sync {
    /// 连接到设备
    ///
    /// # Returns
    /// * `Ok(())` - 连接成功
    /// * `Err(DriverError::AlreadyConnected)` - 设备已连接（可选）
    async fn connect(&mut self) -> Result<(), DriverError>;

    /// 断开设备连接
    ///
    /// # Returns
    /// * `Ok(())` - 断开成功
    /// * `Err(DriverError::NotConnected)` - 设备未连接（可选）
    async fn disconnect(&mut self) -> Result<(), DriverError>;

    /// 检查设备是否已连接
    fn is_connected(&self) -> bool;
}
