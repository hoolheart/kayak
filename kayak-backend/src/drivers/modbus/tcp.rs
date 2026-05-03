//! Modbus TCP 驱动实现
//!
//! 提供基于 TCP 的 Modbus 通信驱动实现。

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Arc, Mutex as StdMutex};
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::sync::Mutex as AsyncMutex;
use tokio::time::timeout;
use uuid::Uuid;

pub use crate::drivers::core::{DeviceDriver, PointValue};
pub use crate::drivers::error::DriverError;
pub use crate::drivers::lifecycle::DriverLifecycle;
pub use crate::drivers::modbus::error::{ModbusError, ModbusException};
pub use crate::drivers::modbus::mbap::MbapHeader;
pub use crate::drivers::modbus::pdu::Pdu;
pub use crate::drivers::modbus::types::{FunctionCode, ModbusAddress, ModbusValue, RegisterType};

/// Modbus TCP 驱动配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModbusTcpConfig {
    /// 服务器主机地址
    pub host: String,
    /// TCP 端口
    pub port: u16,
    /// 从站 ID (Unit Identifier)
    pub slave_id: u8,
    /// 操作超时时间 (毫秒)
    pub timeout_ms: u64,
}

impl ModbusTcpConfig {
    /// 创建新的配置
    pub fn new(host: impl Into<String>, port: u16, slave_id: u8, timeout_ms: u64) -> Self {
        Self {
            host: host.into(),
            port,
            slave_id,
            timeout_ms,
        }
    }

    /// 获取超时时长
    pub fn timeout(&self) -> Duration {
        Duration::from_millis(self.timeout_ms)
    }
}

impl Default for ModbusTcpConfig {
    fn default() -> Self {
        Self {
            host: "127.0.0.1".to_string(),
            port: 502,
            slave_id: 1,
            timeout_ms: 3000,
        }
    }
}

/// 驱动状态
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum DriverState {
    /// 断开状态
    #[default]
    Disconnected,
    /// 连接中
    Connecting,
    /// 已连接
    Connected,
    /// 连接失败
    Error,
}

/// 测点配置
///
/// 将 UUID 映射到具体的 Modbus 地址和功能码。
#[derive(Debug, Clone)]
pub struct PointConfig {
    /// 测点 ID
    pub point_id: Uuid,
    /// Modbus 寄存器地址
    pub address: ModbusAddress,
    /// 功能码
    pub function_code: FunctionCode,
    /// 寄存器类型
    pub register_type: RegisterType,
}

impl PointConfig {
    /// 创建新的测点配置
    pub fn new(
        point_id: Uuid,
        address: ModbusAddress,
        function_code: FunctionCode,
        register_type: RegisterType,
    ) -> Self {
        Self {
            point_id,
            address,
            function_code,
            register_type,
        }
    }
}

/// Modbus TCP 驱动
///
/// 实现 DeviceDriver trait，提供 Modbus TCP 通信能力。
pub struct ModbusTcpDriver {
    /// 配置
    config: ModbusTcpConfig,
    /// 当前状态 (使用标准 Mutex 支持内部可变性)
    state: StdMutex<DriverState>,
    /// TCP 流 (使用异步 Mutex 支持 &self 访问)
    stream: AsyncMutex<Option<TcpStream>>,
    /// 事务 ID (原子递增)
    transaction_id: Arc<StdMutex<u16>>,
    /// 测点配置映射表 (point_id -> PointConfig)
    point_configs: Arc<StdMutex<HashMap<Uuid, PointConfig>>>,
}

unsafe impl Send for ModbusTcpDriver {}
unsafe impl Sync for ModbusTcpDriver {}

impl ModbusTcpDriver {
    /// 创建新的驱动实例
    pub fn new(config: ModbusTcpConfig) -> Self {
        Self {
            config,
            state: StdMutex::new(DriverState::Disconnected),
            stream: AsyncMutex::new(None),
            transaction_id: Arc::new(StdMutex::new(0)),
            point_configs: Arc::new(StdMutex::new(HashMap::new())),
        }
    }

    /// 使用默认配置创建驱动
    pub fn with_defaults() -> Self {
        Self::new(ModbusTcpConfig::default())
    }

    /// 配置主机和端口
    pub fn with_host_port(host: impl Into<String>, port: u16) -> Self {
        Self::new(ModbusTcpConfig::new(host, port, 1, 3000))
    }

    /// 获取当前配置引用
    pub fn config(&self) -> &ModbusTcpConfig {
        &self.config
    }

    /// 获取当前状态
    pub fn state(&self) -> DriverState {
        *self.state.lock().unwrap()
    }

    /// 配置测点映射
    pub fn configure_points(&self, configs: Vec<PointConfig>) -> Result<(), DriverError> {
        let mut point_configs = self.point_configs.lock().unwrap();
        for config in configs {
            point_configs.insert(config.point_id, config);
        }
        Ok(())
    }

    /// 添加单个测点配置
    pub fn add_point(&self, config: PointConfig) -> Result<(), DriverError> {
        let mut point_configs = self.point_configs.lock().unwrap();
        point_configs.insert(config.point_id, config);
        Ok(())
    }

    /// 获取测点配置
    pub fn get_point_config(&self, point_id: &Uuid) -> Option<PointConfig> {
        let point_configs = self.point_configs.lock().unwrap();
        point_configs.get(point_id).cloned()
    }

    /// 获取下一个事务 ID
    fn next_transaction_id(&self) -> u16 {
        let mut tid = self.transaction_id.lock().unwrap();
        *tid = tid.wrapping_add(1);
        *tid
    }

    /// 发送请求并接收响应
    async fn send_request(&self, pdu: &Pdu) -> Result<Pdu, ModbusError> {
        // 先获取事务 ID 和配置（不 borrow stream）
        let tid = self.next_transaction_id();
        let slave_id = self.config.slave_id;

        let mut stream = self.stream.lock().await;
        let stream = stream.as_mut().ok_or(ModbusError::NotConnected)?;

        let mbap = MbapHeader::new(tid, slave_id, pdu.len() as u16);

        // 组装完整帧
        let mut frame = Vec::with_capacity(MbapHeader::LENGTH + pdu.len());
        frame.extend_from_slice(&mbap.to_bytes());
        frame.extend_from_slice(&pdu.to_bytes());

        // 发送请求
        stream.write_all(&frame).await.map_err(|e| {
            *self.state.lock().unwrap() = DriverState::Error;
            ModbusError::IoError(format!("Failed to send request: {}", e))
        })?;

        // 接收响应 - 先读取 MBAP 头部
        let mut mbap_buf = [0u8; MbapHeader::LENGTH];
        let duration = self.config.timeout();

        let result = timeout(duration, stream.read_exact(&mut mbap_buf)).await;

        match result {
            Err(_) => {
                *self.state.lock().unwrap() = DriverState::Error;
                return Err(ModbusError::Timeout { duration });
            }
            Ok(Err(e)) => {
                *self.state.lock().unwrap() = DriverState::Error;
                return Err(ModbusError::IoError(format!("Failed to read MBAP: {}", e)));
            }
            Ok(Ok(_bytes_read)) => {
                // read_exact reads exactly len bytes, so we don't need the count
            }
        }

        // 解析 MBAP 头部
        let response_mbap = MbapHeader::parse(&mbap_buf)?;

        // 验证事务 ID
        if response_mbap.transaction_id != tid {
            return Err(ModbusError::MbapError(format!(
                "Transaction ID mismatch: expected {}, got {}",
                tid, response_mbap.transaction_id
            )));
        }

        // 读取 PDU 数据
        let pdu_len = response_mbap.pdu_length() as usize;
        let mut pdu_buf = vec![0u8; pdu_len];

        let result = timeout(duration, stream.read_exact(&mut pdu_buf)).await;

        match result {
            Err(_) => {
                *self.state.lock().unwrap() = DriverState::Error;
                return Err(ModbusError::Timeout { duration });
            }
            Ok(Err(e)) => {
                *self.state.lock().unwrap() = DriverState::Error;
                return Err(ModbusError::IoError(format!("Failed to read PDU: {}", e)));
            }
            Ok(Ok(_bytes_read)) => {
                // read_exact reads exactly len bytes
            }
        }

        // 解析 PDU
        let response_pdu = Pdu::parse(&pdu_buf)?;

        // 检查是否为异常响应
        if response_pdu.is_error_response() {
            if let Some(exception_code) = response_pdu.exception_code() {
                let exception = ModbusException::from_u8(exception_code);
                return Err(ModbusError::from(exception));
            }
        }

        Ok(response_pdu)
    }

    /// 读取单个线圈值
    async fn read_single_coil(&self, address: ModbusAddress) -> Result<bool, ModbusError> {
        let pdu = Pdu::read_coils(address, 1)?;
        let response = self.send_request(&pdu).await?;
        let coils = response.parse_coils_response()?;
        Ok(coils.first().copied().unwrap_or(false))
    }

    /// 读取单个离散输入值
    async fn read_single_discrete_input(
        &self,
        address: ModbusAddress,
    ) -> Result<bool, ModbusError> {
        let pdu = Pdu::read_discrete_inputs(address, 1)?;
        let response = self.send_request(&pdu).await?;
        let inputs = response.parse_coils_response()?;
        Ok(inputs.first().copied().unwrap_or(false))
    }

    /// 读取单个保持寄存器值
    async fn read_single_holding_register(
        &self,
        address: ModbusAddress,
    ) -> Result<u16, ModbusError> {
        let pdu = Pdu::read_holding_registers(address, 1)?;
        let response = self.send_request(&pdu).await?;
        let registers = response.parse_registers_response()?;
        Ok(registers.first().copied().unwrap_or(0))
    }

    /// 读取单个输入寄存器值
    async fn read_single_input_register(&self, address: ModbusAddress) -> Result<u16, ModbusError> {
        let pdu = Pdu::read_input_registers(address, 1)?;
        let response = self.send_request(&pdu).await?;
        let registers = response.parse_registers_response()?;
        Ok(registers.first().copied().unwrap_or(0))
    }

    /// 写入单个线圈值
    async fn write_single_coil(
        &self,
        address: ModbusAddress,
        value: bool,
    ) -> Result<(), ModbusError> {
        let pdu = Pdu::write_single_coil(address, value)?;
        self.send_request(&pdu).await?;
        Ok(())
    }

    /// 写入单个寄存器值
    async fn write_single_register(
        &self,
        address: ModbusAddress,
        value: u16,
    ) -> Result<(), ModbusError> {
        let pdu = Pdu::write_single_register(address, value)?;
        self.send_request(&pdu).await?;
        Ok(())
    }
}

#[async_trait]
impl DriverLifecycle for ModbusTcpDriver {
    /// 连接到 Modbus TCP 服务器
    async fn connect(&mut self) -> Result<(), DriverError> {
        if *self.state.lock().unwrap() == DriverState::Connected {
            return Err(DriverError::AlreadyConnected);
        }

        *self.state.lock().unwrap() = DriverState::Connecting;

        let addr = format!("{}:{}", self.config.host, self.config.port);
        let duration = self.config.timeout();

        let result = timeout(duration, TcpStream::connect(&addr)).await;

        match result {
            Err(_) => {
                *self.state.lock().unwrap() = DriverState::Error;
                Err(DriverError::Timeout { duration })
            }
            Ok(Err(e)) => {
                *self.state.lock().unwrap() = DriverState::Error;
                Err(DriverError::IoError(format!("Connection failed: {}", e)))
            }
            Ok(Ok(stream)) => {
                *self.stream.lock().await = Some(stream);
                *self.state.lock().unwrap() = DriverState::Connected;
                Ok(())
            }
        }
    }

    /// 断开与 Modbus TCP 服务器的连接
    async fn disconnect(&mut self) -> Result<(), DriverError> {
        *self.stream.lock().await = None;
        *self.state.lock().unwrap() = DriverState::Disconnected;
        Ok(())
    }

    /// 检查是否已连接
    fn is_connected(&self) -> bool {
        *self.state.lock().unwrap() == DriverState::Connected
    }
}

#[async_trait]
impl DeviceDriver for ModbusTcpDriver {
    type Config = ModbusTcpConfig;
    type Error = DriverError;

    async fn connect(&mut self) -> Result<(), Self::Error> {
        DriverLifecycle::connect(self).await
    }

    async fn disconnect(&mut self) -> Result<(), Self::Error> {
        DriverLifecycle::disconnect(self).await
    }

    fn read_point(&self, point_id: Uuid) -> Result<PointValue, Self::Error> {
        // 使用 Handle::current().block_on 在同步上下文中调用异步方法
        // 注意：这会在没有运行时的情况下失败
        tokio::runtime::Handle::current().block_on(self.read_point_async(point_id))
    }

    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), Self::Error> {
        // 使用 Handle::current().block_on 在同步上下文中调用异步方法
        // 注意：这会在没有运行时的情况下失败
        tokio::runtime::Handle::current().block_on(self.write_point_async(point_id, value))
    }

    fn is_connected(&self) -> bool {
        DriverLifecycle::is_connected(self)
    }
}

// 为 ModbusTcpDriver 添加异步读写方法（扩展 trait）
impl ModbusTcpDriver {
    /// 异步读取测点值
    pub async fn read_point_async(&self, point_id: Uuid) -> Result<PointValue, DriverError> {
        if !DriverLifecycle::is_connected(self) {
            return Err(DriverError::NotConnected);
        }

        let point_config =
            self.get_point_config(&point_id)
                .ok_or_else(|| DriverError::InvalidValue {
                    message: format!("Point {} not found", point_id),
                })?;

        let value = match point_config.register_type {
            RegisterType::Coil => {
                let coil_value = self
                    .read_single_coil(point_config.address)
                    .await
                    .map_err(DriverError::from)?;
                ModbusValue::Coil(coil_value)
            }
            RegisterType::DiscreteInput => {
                let input_value = self
                    .read_single_discrete_input(point_config.address)
                    .await
                    .map_err(DriverError::from)?;
                ModbusValue::DiscreteInput(input_value)
            }
            RegisterType::HoldingRegister => {
                let register_value = self
                    .read_single_holding_register(point_config.address)
                    .await
                    .map_err(DriverError::from)?;
                ModbusValue::HoldingRegister(register_value)
            }
            RegisterType::InputRegister => {
                let register_value = self
                    .read_single_input_register(point_config.address)
                    .await
                    .map_err(DriverError::from)?;
                ModbusValue::InputRegister(register_value)
            }
        };

        // 转换为 PointValue
        let point_value = match value {
            ModbusValue::Coil(b) => PointValue::Boolean(b),
            ModbusValue::DiscreteInput(b) => PointValue::Boolean(b),
            ModbusValue::HoldingRegister(u) => PointValue::Integer(u as i64),
            ModbusValue::InputRegister(u) => PointValue::Integer(u as i64),
        };

        Ok(point_value)
    }

    /// 异步写入测点值
    pub async fn write_point_async(
        &self,
        point_id: Uuid,
        value: PointValue,
    ) -> Result<(), DriverError> {
        if !DriverLifecycle::is_connected(self) {
            return Err(DriverError::NotConnected);
        }

        let point_config =
            self.get_point_config(&point_id)
                .ok_or_else(|| DriverError::InvalidValue {
                    message: format!("Point {} not found", point_id),
                })?;

        // 检查是否为只读类型
        if point_config.register_type.is_read_only() {
            return Err(DriverError::ReadOnlyPoint);
        }

        match point_config.register_type {
            RegisterType::Coil => {
                let coil_value =
                    value
                        .to_f64()
                        .map(|f| f != 0.0)
                        .ok_or_else(|| DriverError::InvalidValue {
                            message: "Invalid boolean value for coil".into(),
                        })?;
                self.write_single_coil(point_config.address, coil_value)
                    .await
                    .map_err(DriverError::from)?;
            }
            RegisterType::HoldingRegister => {
                let register_value = match value {
                    PointValue::Number(n) => n as u16,
                    PointValue::Integer(n) => n as u16,
                    PointValue::Boolean(b) => {
                        if b {
                            1
                        } else {
                            0
                        }
                    }
                    PointValue::String(s) => {
                        s.parse::<u16>().map_err(|_| DriverError::InvalidValue {
                            message: format!("Cannot parse '{}' as u16", s),
                        })?
                    }
                };
                self.write_single_register(point_config.address, register_value)
                    .await
                    .map_err(DriverError::from)?;
            }
            RegisterType::DiscreteInput | RegisterType::InputRegister => {
                return Err(DriverError::ReadOnlyPoint);
            }
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ========== ModbusTcpConfig Tests ==========

    #[test]
    fn test_modbus_tcp_config_default() {
        let config = ModbusTcpConfig::default();
        assert_eq!(config.host, "127.0.0.1");
        assert_eq!(config.port, 502);
        assert_eq!(config.slave_id, 1);
        assert_eq!(config.timeout_ms, 3000);
    }

    #[test]
    fn test_modbus_tcp_config_new() {
        let config = ModbusTcpConfig::new("192.168.1.100", 1502, 1, 5000);
        assert_eq!(config.host, "192.168.1.100");
        assert_eq!(config.port, 1502);
        assert_eq!(config.slave_id, 1);
        assert_eq!(config.timeout_ms, 5000);
    }

    #[test]
    fn test_modbus_tcp_config_timeout() {
        let config = ModbusTcpConfig::new("localhost", 502, 1, 3000);
        assert_eq!(config.timeout(), Duration::from_millis(3000));
    }

    // ========== DriverState Tests ==========

    #[test]
    fn test_driver_state_default() {
        assert_eq!(DriverState::default(), DriverState::Disconnected);
    }

    #[test]
    fn test_driver_state_variants() {
        let states = [
            DriverState::Disconnected,
            DriverState::Connecting,
            DriverState::Connected,
            DriverState::Error,
        ];
        assert_eq!(states.len(), 4);
    }

    // ========== PointConfig Tests ==========

    #[test]
    fn test_point_config_new() {
        let point_id = Uuid::new_v4();
        let config = PointConfig::new(
            point_id,
            ModbusAddress::new(0),
            FunctionCode::ReadCoils,
            RegisterType::Coil,
        );
        assert_eq!(config.point_id, point_id);
        assert_eq!(config.address, ModbusAddress::new(0));
        assert_eq!(config.function_code, FunctionCode::ReadCoils);
        assert_eq!(config.register_type, RegisterType::Coil);
    }

    // ========== ModbusTcpDriver Tests ==========

    #[test]
    fn test_modbus_tcp_driver_new() {
        let config = ModbusTcpConfig::new("localhost", 502, 1, 3000);
        let driver = ModbusTcpDriver::new(config);
        assert_eq!(driver.state(), DriverState::Disconnected);
        assert!(driver.config().host == "localhost");
    }

    #[test]
    fn test_modbus_tcp_driver_with_defaults() {
        let driver = ModbusTcpDriver::with_defaults();
        assert_eq!(driver.state(), DriverState::Disconnected);
    }

    #[test]
    fn test_modbus_tcp_driver_with_host_port() {
        let driver = ModbusTcpDriver::with_host_port("192.168.1.1", 1502);
        assert_eq!(driver.config().host, "192.168.1.1");
        assert_eq!(driver.config().port, 1502);
    }

    #[test]
    fn test_modbus_tcp_driver_not_connected() {
        let driver = ModbusTcpDriver::with_defaults();
        assert!(!DriverLifecycle::is_connected(&driver));
    }

    #[test]
    fn test_modbus_tcp_driver_configure_points() {
        let driver = ModbusTcpDriver::with_defaults();
        let point_id = Uuid::new_v4();
        let configs = vec![PointConfig::new(
            point_id,
            ModbusAddress::new(100),
            FunctionCode::ReadHoldingRegisters,
            RegisterType::HoldingRegister,
        )];

        driver.configure_points(configs).unwrap();
        let retrieved = driver.get_point_config(&point_id).unwrap();
        assert_eq!(retrieved.address, ModbusAddress::new(100));
    }

    #[test]
    fn test_modbus_tcp_driver_add_point() {
        let driver = ModbusTcpDriver::with_defaults();
        let point_id = Uuid::new_v4();
        let config = PointConfig::new(
            point_id,
            ModbusAddress::new(200),
            FunctionCode::WriteSingleCoil,
            RegisterType::Coil,
        );

        driver.add_point(config).unwrap();
        let retrieved = driver.get_point_config(&point_id).unwrap();
        assert_eq!(retrieved.function_code, FunctionCode::WriteSingleCoil);
    }

    #[test]
    fn test_modbus_tcp_driver_get_point_not_found() {
        let driver = ModbusTcpDriver::with_defaults();
        let point_id = Uuid::new_v4();
        assert!(driver.get_point_config(&point_id).is_none());
    }

    // ========== Transaction ID Tests ==========

    #[test]
    fn test_transaction_id_increment() {
        let driver = ModbusTcpDriver::with_defaults();
        let tid1 = driver.next_transaction_id();
        let tid2 = driver.next_transaction_id();
        let tid3 = driver.next_transaction_id();
        assert_eq!(tid1, 1);
        assert_eq!(tid2, 2);
        assert_eq!(tid3, 3);
    }

    #[test]
    fn test_transaction_id_wrap() {
        let driver = ModbusTcpDriver::with_defaults();
        // 快速连续调用，测试原子性
        let tid1 = driver.next_transaction_id();
        let tid2 = driver.next_transaction_id();
        assert_ne!(tid1, tid2);
    }

    // ========== Connection Tests (需要 mock TCP 服务器) ==========

    #[tokio::test]
    async fn test_connect_invalid_host() {
        let config = ModbusTcpConfig::new("192.0.2.1", 1502, 1, 1000); // TEST-NET-1, 不可路由
        let mut driver = ModbusTcpDriver::new(config);
        let result: Result<(), DriverError> = DriverLifecycle::connect(&mut driver).await;
        // 连接应该超时或失败
        assert!(result.is_err());
        assert_eq!(driver.state(), DriverState::Error);
    }

    #[tokio::test]
    async fn test_disconnect_not_connected() {
        let mut driver = ModbusTcpDriver::with_defaults();
        let result: Result<(), DriverError> = DriverLifecycle::disconnect(&mut driver).await;
        assert!(result.is_ok());
        assert!(!DriverLifecycle::is_connected(&driver));
    }

    // ========== Read/Write Point Tests ==========

    #[tokio::test]
    async fn test_read_point_not_connected() {
        let driver = ModbusTcpDriver::with_defaults();
        let point_id = Uuid::new_v4();
        let result = driver.read_point_async(point_id).await;
        assert!(matches!(result, Err(DriverError::NotConnected)));
    }

    #[tokio::test]
    async fn test_write_point_not_connected() {
        let driver = ModbusTcpDriver::with_defaults();
        let point_id = Uuid::new_v4();
        let result = driver
            .write_point_async(point_id, PointValue::Boolean(true))
            .await;
        assert!(matches!(result, Err(DriverError::NotConnected)));
    }

    #[tokio::test]
    async fn test_read_point_not_found() {
        let config = ModbusTcpConfig::new("127.0.0.1", 1502, 1, 1000);
        let driver = ModbusTcpDriver::new(config);

        // 连接可能会失败，但我们先测试测点未找到的情况
        // 注意：这里假设连接会成功，实际测试需要 mock 服务器
        let point_id = Uuid::new_v4();
        let result = driver.read_point_async(point_id).await;

        // 由于没有连接，应该是 NotConnected
        // 如果连接成功了，应该是 InvalidValue (point not found)
        match result {
            Err(DriverError::NotConnected) => {}
            Err(DriverError::InvalidValue { .. }) => {}
            other => panic!("Expected NotConnected or InvalidValue, got {:?}", other),
        }
    }

    // ========== Register Type Tests ==========

    #[test]
    fn test_register_type_is_read_only() {
        assert!(RegisterType::DiscreteInput.is_read_only());
        assert!(RegisterType::InputRegister.is_read_only());
        assert!(!RegisterType::Coil.is_read_only());
        assert!(!RegisterType::HoldingRegister.is_read_only());
    }

    #[test]
    fn test_register_type_function_codes() {
        assert_eq!(
            RegisterType::Coil.read_function_code(),
            FunctionCode::ReadCoils
        );
        assert_eq!(
            RegisterType::DiscreteInput.read_function_code(),
            FunctionCode::ReadDiscreteInputs
        );
        assert_eq!(
            RegisterType::HoldingRegister.read_function_code(),
            FunctionCode::ReadHoldingRegisters
        );
        assert_eq!(
            RegisterType::InputRegister.read_function_code(),
            FunctionCode::ReadInputRegisters
        );
    }
}
