//! 驱动包装器 - 类型擦除实现
//!
//! 使用 enum 实现类型擦除，统一封装所有设备驱动类型。
//! 为 AnyDriver 提供统一的 DriverAccess 和 DriverLifecycle 接口。

use async_trait::async_trait;
use uuid::Uuid;

use super::core::{DeviceDriver, PointValue};
use super::error::DriverError;
use super::lifecycle::DriverLifecycle;
use super::modbus::rtu::ModbusRtuDriver;
use super::modbus::tcp::ModbusTcpDriver;
use super::r#virtual::VirtualDriver;
use crate::engine::DriverAccess;
use crate::engine::ExecutionError;

/// 统一驱动类型枚举
///
/// 所有设备驱动的类型擦除包装。使用 enum 而非 trait object 的原因：
/// 1. 编译时分发，零运行时开销
/// 2. 类型安全，无需 downcast
/// 3. Rust 惯用的 ADT 实现方式
#[allow(dead_code)]
pub enum AnyDriver {
    /// 虚拟设备驱动
    Virtual(VirtualDriver),
    /// Modbus TCP 驱动
    ModbusTcp(ModbusTcpDriver),
    /// Modbus RTU 驱动
    ModbusRtu(ModbusRtuDriver),
    // 预留扩展:
    // Can(CanDriver),
    // Visa(VisaDriver),
    // Mqtt(MqttDriver),
}

/// 驱动包装器
///
/// 为 AnyDriver 提供统一接口，实现 DriverAccess 和 DriverLifecycle。
/// 这是 DeviceManager 实际存储的类型。
pub struct DriverWrapper {
    inner: AnyDriver,
}

impl DriverWrapper {
    /// 使用 VirtualDriver 创建包装器
    pub fn new_virtual(driver: VirtualDriver) -> Self {
        Self {
            inner: AnyDriver::Virtual(driver),
        }
    }

    /// 使用 ModbusTcpDriver 创建包装器
    pub fn new_modbus_tcp(driver: ModbusTcpDriver) -> Self {
        Self {
            inner: AnyDriver::ModbusTcp(driver),
        }
    }

    /// 使用 ModbusRtuDriver 创建包装器
    pub fn new_modbus_rtu(driver: ModbusRtuDriver) -> Self {
        Self {
            inner: AnyDriver::ModbusRtu(driver),
        }
    }

    /// 获取内部驱动的协议类型名称
    pub fn driver_type(&self) -> &'static str {
        match &self.inner {
            AnyDriver::Virtual(_) => "virtual",
            AnyDriver::ModbusTcp(_) => "modbus_tcp",
            AnyDriver::ModbusRtu(_) => "modbus_rtu",
        }
    }
}

// Safety: DriverWrapper contains only Send + Sync types
unsafe impl Send for DriverWrapper {}
unsafe impl Sync for DriverWrapper {}

// 实现 DriverLifecycle（连接管理）
#[async_trait]
impl DriverLifecycle for DriverWrapper {
    async fn connect(&mut self) -> Result<(), DriverError> {
        match &mut self.inner {
            AnyDriver::Virtual(d) => d.connect().await,
            AnyDriver::ModbusTcp(d) => DriverLifecycle::connect(d).await,
            AnyDriver::ModbusRtu(d) => DriverLifecycle::connect(d).await,
        }
    }

    async fn disconnect(&mut self) -> Result<(), DriverError> {
        match &mut self.inner {
            AnyDriver::Virtual(d) => d.disconnect().await,
            AnyDriver::ModbusTcp(d) => DriverLifecycle::disconnect(d).await,
            AnyDriver::ModbusRtu(d) => DriverLifecycle::disconnect(d).await,
        }
    }

    fn is_connected(&self) -> bool {
        match &self.inner {
            AnyDriver::Virtual(d) => d.is_connected(),
            AnyDriver::ModbusTcp(d) => DriverLifecycle::is_connected(d),
            AnyDriver::ModbusRtu(d) => DriverLifecycle::is_connected(d),
        }
    }
}

// 实现 DriverAccess（引擎访问接口）
impl DriverAccess for DriverWrapper {
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, ExecutionError> {
        match &self.inner {
            AnyDriver::Virtual(d) => d
                .read_point(point_id)
                .map_err(|e: DriverError| ExecutionError::DriverError(e.to_string())),
            AnyDriver::ModbusTcp(d) => d
                .read_point(point_id)
                .map_err(|e: DriverError| ExecutionError::DriverError(e.to_string())),
            AnyDriver::ModbusRtu(d) => d
                .read_point(point_id)
                .map_err(|e: DriverError| ExecutionError::DriverError(e.to_string())),
        }
    }

    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), ExecutionError> {
        match &self.inner {
            AnyDriver::Virtual(d) => d
                .write_point(point_id, value)
                .map_err(|e: DriverError| ExecutionError::DriverError(e.to_string())),
            AnyDriver::ModbusTcp(d) => d
                .write_point(point_id, value)
                .map_err(|e: DriverError| ExecutionError::DriverError(e.to_string())),
            AnyDriver::ModbusRtu(d) => d
                .write_point(point_id, value)
                .map_err(|e: DriverError| ExecutionError::DriverError(e.to_string())),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_driver_wrapper_new_virtual() {
        let driver = VirtualDriver::new();
        let wrapper = DriverWrapper::new_virtual(driver);
        assert_eq!(wrapper.driver_type(), "virtual");
    }

    #[test]
    fn test_driver_wrapper_driver_access() {
        let driver = VirtualDriver::new();
        let wrapper = DriverWrapper::new_virtual(driver);

        // DriverAccess 应该可以调用
        let point_id = Uuid::new_v4();
        // 注意：VirtualDriver 默认未连接，read_point 会返回错误
        let result = wrapper.read_point(point_id);
        assert!(result.is_err());
    }
}
