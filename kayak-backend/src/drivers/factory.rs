//! 驱动工厂
//!
//! 根据协议类型和配置创建设备驱动包装器。
//! 支持从数据库配置动态创建设备驱动。

use crate::models::entities::device::ProtocolType;

use super::error::DriverError;
use super::modbus::rtu::{ModbusRtuConfig, ModbusRtuDriver};
use super::modbus::tcp::{ModbusTcpConfig, ModbusTcpDriver};
use super::r#virtual::{VirtualConfig, VirtualDriver};
use super::wrapper::DriverWrapper;

/// 驱动工厂
///
/// 根据协议类型和配置创建对应的 DriverWrapper。
/// 新协议支持通过扩展 create_driver 方法实现。
pub struct DriverFactory;

impl DriverFactory {
    /// 根据协议类型和配置创建驱动包装器
    ///
    /// # Arguments
    /// * `protocol` - 协议类型
    /// * `config` - 协议配置（JSON格式）
    ///
    /// # Returns
    /// * `Ok(DriverWrapper)` - 创建成功
    /// * `Err(DriverError)` - 配置错误或协议不支持
    pub fn create(
        protocol: ProtocolType,
        config: serde_json::Value,
    ) -> Result<DriverWrapper, DriverError> {
        match protocol {
            ProtocolType::Virtual => {
                let config: VirtualConfig = serde_json::from_value(config).map_err(|e| {
                    DriverError::ConfigError(format!("Invalid virtual config: {}", e))
                })?;
                let driver = VirtualDriver::with_config(config)
                    .map_err(|e| DriverError::ConfigError(e.to_string()))?;
                Ok(DriverWrapper::new_virtual(driver))
            }
            ProtocolType::ModbusTcp => {
                let config: ModbusTcpConfig = serde_json::from_value(config).map_err(|e| {
                    DriverError::ConfigError(format!("Invalid Modbus TCP config: {}", e))
                })?;
                let driver = ModbusTcpDriver::new(config);
                Ok(DriverWrapper::new_modbus_tcp(driver))
            }
            ProtocolType::ModbusRtu => {
                let config: ModbusRtuConfig = serde_json::from_value(config).map_err(|e| {
                    DriverError::ConfigError(format!("Invalid Modbus RTU config: {}", e))
                })?;
                let driver = ModbusRtuDriver::new(config);
                Ok(DriverWrapper::new_modbus_rtu(driver))
            }
            _ => Err(DriverError::ConfigError(format!(
                "Protocol {:?} not yet implemented",
                protocol
            ))),
        }
    }

    /// 创建默认的 VirtualDriver（用于测试）
    pub fn create_virtual_default() -> DriverWrapper {
        DriverWrapper::new_virtual(VirtualDriver::new())
    }

    /// 从 Device 实体创建设动包装器
    ///
    /// 从设备实体提取协议类型和配置，创建设动包装器。
    ///
    /// # Arguments
    /// * `device` - 设备实体引用
    ///
    /// # Returns
    /// * `Ok(DriverWrapper)` - 创建成功
    /// * `Err(DriverError)` - 设备无有效配置或协议不支持
    pub fn from_device(
        device: &crate::models::entities::device::Device,
    ) -> Result<DriverWrapper, DriverError> {
        Self::create(
            device.protocol_type,
            device
                .protocol_params
                .clone()
                .unwrap_or(serde_json::json!({})),
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_virtual_driver() {
        let config = serde_json::json!({
            "mode": "Random",
            "data_type": "Number",
            "access_type": "RO",
            "min_value": 0.0,
            "max_value": 100.0,
            "sample_interval_ms": 1000
        });

        let result = DriverFactory::create(ProtocolType::Virtual, config);
        assert!(result.is_ok());
    }

    #[test]
    fn test_create_unsupported_protocol() {
        let config = serde_json::json!({});
        let result = DriverFactory::create(ProtocolType::Can, config);
        assert!(result.is_err());
    }

    #[test]
    fn test_create_virtual_default() {
        let wrapper = DriverFactory::create_virtual_default();
        assert_eq!(wrapper.driver_type(), "virtual");
    }

    #[test]
    fn test_create_modbus_tcp_driver() {
        let config = serde_json::json!({
            "host": "127.0.0.1",
            "port": 502,
            "slave_id": 1,
            "timeout_ms": 3000
        });

        let result = DriverFactory::create(ProtocolType::ModbusTcp, config);
        assert!(result.is_ok());
    }

    #[test]
    fn test_create_modbus_rtu_driver() {
        let config = serde_json::json!({
            "port": "/dev/ttyUSB0",
            "baud_rate": 9600,
            "data_bits": 8,
            "stop_bits": 1,
            "parity": "None",
            "timeout_ms": 3000,
            "slave_id": 1
        });

        let result = DriverFactory::create(ProtocolType::ModbusRtu, config);
        assert!(result.is_ok());
    }
}
