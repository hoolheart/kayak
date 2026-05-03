//! Modbus RTU 驱动实现
//!
//! 提供基于串行通信的 Modbus RTU 协议驱动实现。
//!
//! # RTU 帧格式
//!
//! RTU 帧结构: `[slave_id, function_code, data..., crc_low, crc_high]`
//!
//! - slave_id: 从站地址 (1 byte)
//! - function_code: 功能码 (1 byte)
//! - data: 数据部分 (可变长度)
//! - crc: CRC16 校验 (2 bytes, 低字节在前)
//!
//! # CRC16 计算
//!
//! Modbus RTU 使用 CRC16-MODBUS 算法：
//! - 多项式: 0x8005 (对应反射形式 0xA001)
//! - 初始值: 0xFFFF
//! - 低字节在前 (little-endian)

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Arc, Mutex as StdMutex};
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::sync::Mutex as AsyncMutex;
use tokio::time::timeout;
use tokio_serial::{SerialPortBuilderExt, SerialStream};
use uuid::Uuid;

pub use crate::drivers::core::{DeviceDriver, PointValue};
pub use crate::drivers::error::DriverError;
pub use crate::drivers::lifecycle::DriverLifecycle;
pub use crate::drivers::modbus::error::{ModbusError, ModbusException};
pub use crate::drivers::modbus::pdu::Pdu;
pub use crate::drivers::modbus::types::{FunctionCode, ModbusAddress, RegisterType};

/// 串口校验位配置
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum Parity {
    /// 无校验
    #[default]
    None,
    /// 偶校验
    Even,
    /// 奇校验
    Odd,
}

impl Parity {
    /// 转换为 serialport crate 的校验位配置
    pub fn to_serialport_parity(&self) -> serialport::Parity {
        match self {
            Parity::None => serialport::Parity::None,
            Parity::Even => serialport::Parity::Even,
            Parity::Odd => serialport::Parity::Odd,
        }
    }
}

/// Modbus RTU 驱动配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModbusRtuConfig {
    /// 串口路径 (如 "/dev/ttyUSB0" 或 "COM3")
    pub port: String,
    /// 波特率 (如 9600, 19200, 115200)
    pub baud_rate: u32,
    /// 数据位 (7 或 8)
    pub data_bits: u8,
    /// 停止位 (1 或 2)
    pub stop_bits: u8,
    /// 校验位
    pub parity: Parity,
    /// 操作超时时间 (毫秒)
    pub timeout_ms: u64,
    /// 从站 ID (1-247)
    pub slave_id: u8,
}

impl ModbusRtuConfig {
    /// 创建新的配置
    pub fn new(
        port: impl Into<String>,
        baud_rate: u32,
        data_bits: u8,
        stop_bits: u8,
        parity: Parity,
        timeout_ms: u64,
        slave_id: u8,
    ) -> Self {
        Self {
            port: port.into(),
            baud_rate,
            data_bits,
            stop_bits,
            parity,
            timeout_ms,
            slave_id,
        }
    }

    /// 获取超时时长
    pub fn timeout(&self) -> Duration {
        Duration::from_millis(self.timeout_ms)
    }

    /// 验证从站 ID 是否有效 (1-247)
    pub fn is_valid_slave_id(&self) -> bool {
        (1..=247).contains(&self.slave_id)
    }
}

impl Default for ModbusRtuConfig {
    fn default() -> Self {
        Self {
            port: "/dev/ttyUSB0".to_string(),
            baud_rate: 9600,
            data_bits: 8,
            stop_bits: 1,
            parity: Parity::None,
            timeout_ms: 3000,
            slave_id: 1,
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

/// Modbus RTU 驱动
///
/// 实现 DeviceDriver trait，提供 Modbus RTU 串口通信能力。
pub struct ModbusRtuDriver {
    /// 配置
    config: ModbusRtuConfig,
    /// 当前状态
    state: StdMutex<DriverState>,
    /// 串口 (使用 Mutex 支持内部可变性)
    stream: AsyncMutex<Option<SerialStream>>,
    /// 测点配置映射表 (point_id -> PointConfig)
    point_configs: Arc<StdMutex<HashMap<Uuid, PointConfig>>>,
}

unsafe impl Send for ModbusRtuDriver {}
unsafe impl Sync for ModbusRtuDriver {}

impl ModbusRtuDriver {
    /// 创建新的驱动实例
    pub fn new(config: ModbusRtuConfig) -> Self {
        Self {
            config,
            state: StdMutex::new(DriverState::Disconnected),
            stream: AsyncMutex::new(None),
            point_configs: Arc::new(StdMutex::new(HashMap::new())),
        }
    }

    /// 使用默认配置创建驱动
    pub fn with_defaults() -> Self {
        Self::new(ModbusRtuConfig::default())
    }

    /// 使用常用配置创建驱动
    pub fn with_port(port: impl Into<String>) -> Self {
        Self::new(ModbusRtuConfig {
            port: port.into(),
            ..Default::default()
        })
    }

    /// 获取当前配置引用
    pub fn config(&self) -> &ModbusRtuConfig {
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

    // ========== CRC16 计算 ==========

    /// 计算 CRC16-MODBUS
    ///
    /// 使用标准 Modbus CRC16 算法：
    /// - 多项式: 0x8005
    /// - 初始值: 0xFFFF
    /// - 低字节在前
    pub fn calculate_crc16(data: &[u8]) -> u16 {
        let mut crc: u16 = 0xFFFF;

        for &byte in data {
            crc ^= byte as u16;

            for _ in 0..8 {
                if crc & 0x0001 != 0 {
                    crc = (crc >> 1) ^ 0xA001;
                } else {
                    crc >>= 1;
                }
            }
        }

        crc
    }

    /// 验证 CRC16
    ///
    /// # Arguments
    /// * `data` - 要验证的数据 (不包含 CRC)
    /// * `crc` - 接收到的 CRC (低字节在前)
    ///
    /// # Returns
    /// * `Ok(())` - CRC 验证通过
    /// * `Err(ModbusError)` - CRC 验证失败
    pub fn verify_crc16(data: &[u8], crc: u16) -> Result<(), ModbusError> {
        let calculated = Self::calculate_crc16(data);
        if calculated == crc {
            Ok(())
        } else {
            Err(ModbusError::FrameChecksumMismatch {
                expected: calculated,
                actual: crc,
            })
        }
    }

    /// 从字节数组解析 CRC (低字节在前)
    pub fn parse_crc(bytes: &[u8]) -> Option<u16> {
        if bytes.len() < 2 {
            return None;
        }
        // 低字节在前
        Some(u16::from(bytes[0]) | (u16::from(bytes[1]) << 8))
    }

    // ========== RTU 帧组装与解析 ==========

    /// 组装 RTU 请求帧
    ///
    /// 帧格式: [slave_id, function_code, data..., crc_low, crc_high]
    fn build_rtu_frame(&self, pdu: &Pdu) -> Vec<u8> {
        let mut frame = Vec::with_capacity(1 + pdu.len() + 2);
        frame.push(self.config.slave_id);
        frame.extend_from_slice(&pdu.to_bytes());

        // 计算 CRC (包含 slave_id + pdu)
        let crc = Self::calculate_crc16(&frame);
        frame.push((crc & 0xFF) as u8); // 低字节
        frame.push(((crc >> 8) & 0xFF) as u8); // 高字节

        frame
    }

    /// 解析 RTU 响应帧
    ///
    /// 帧格式: [slave_id, function_code, data..., crc_low, crc_high]
    ///
    /// 注意: 此方法用于解析完整的 RTU 帧。对于串口通信中的响应读取，
    /// `send_request` 方法使用更精细的分步读取策略来处理变长响应。
    pub fn parse_rtu_frame(&self, frame: &[u8]) -> Result<(u8, Pdu), ModbusError> {
        // 最小帧长: slave_id(1) + function_code(1) + crc(2) = 4 bytes
        if frame.len() < 4 {
            return Err(ModbusError::IncompleteFrame);
        }

        let slave_id = frame[0];

        // 验证从站 ID 匹配
        if slave_id != self.config.slave_id {
            return Err(ModbusError::InvalidValue(format!(
                "Slave ID mismatch: expected {}, got {}",
                self.config.slave_id, slave_id
            )));
        }

        // 提取 PDU 部分 (不含 slave_id 和 CRC)
        let pdu_data = &frame[1..frame.len() - 2];
        let pdu = Pdu::parse(pdu_data)?;

        // 验证 CRC
        let received_crc =
            Self::parse_crc(&frame[frame.len() - 2..]).ok_or(ModbusError::IncompleteFrame)?;
        let data_for_crc = &frame[..frame.len() - 2]; // 不含 CRC 部分
        Self::verify_crc16(data_for_crc, received_crc)?;

        Ok((slave_id, pdu))
    }

    // ========== 串口读写 ==========

    /// 发送请求并接收响应
    ///
    /// 响应读取流程:
    /// 1. 读取固定头部 (slave_id + function_code = 2 bytes)
    /// 2. 判断响应类型 (正常响应/异常响应/读取响应)
    /// 3. 对于读取响应,读取 byte_count 并计算总帧长度
    /// 4. 读取剩余字节
    /// 5. 验证 CRC
    async fn send_request(&self, pdu: &Pdu) -> Result<Pdu, ModbusError> {
        let mut stream = self.stream.lock().await;
        let stream = stream.as_mut().ok_or(ModbusError::NotConnected)?;

        // 组装 RTU 帧
        let frame = self.build_rtu_frame(pdu);
        let duration = self.config.timeout();

        // 发送请求 (使用 AsyncWriteExt)
        stream.write_all(&frame).await.map_err(|e| {
            *self.state.lock().unwrap() = DriverState::Error;
            ModbusError::IoError(format!("Failed to send request: {}", e))
        })?;

        // 刷新确保数据发出
        stream.flush().await.map_err(|e| {
            *self.state.lock().unwrap() = DriverState::Error;
            ModbusError::IoError(format!("Failed to flush: {}", e))
        })?;

        // ========== 步骤 1: 读取固定头部 (slave_id + function_code = 2 bytes) ==========
        let mut header = [0u8; 2];
        let result = timeout(duration, stream.read_exact(&mut header)).await;

        match result {
            Err(_) => {
                *self.state.lock().unwrap() = DriverState::Error;
                return Err(ModbusError::Timeout { duration });
            }
            Ok(Err(e)) => {
                *self.state.lock().unwrap() = DriverState::Error;
                return Err(ModbusError::IoError(format!(
                    "Failed to read response header: {}",
                    e
                )));
            }
            Ok(Ok(_)) => {}
        }

        // 验证从站 ID 匹配
        let slave_id = header[0];
        if slave_id != self.config.slave_id {
            return Err(ModbusError::InvalidValue(format!(
                "Slave ID mismatch: expected {}, got {}",
                self.config.slave_id, slave_id
            )));
        }

        let function_code_byte = header[1];

        // ========== 步骤 2: 判断响应类型 ==========

        // 检查是否为异常响应 (功能码最高位被置位)
        if function_code_byte & 0x80 != 0 {
            // 异常响应: [slave_id, function_code+0x80, exception_code, crc_low, crc_high]
            // 还需要读取 1 字节 (exception_code) + 2 字节 (CRC)
            let mut remaining = [0u8; 3];
            let result = timeout(duration, stream.read_exact(&mut remaining)).await;

            match result {
                Err(_) => {
                    *self.state.lock().unwrap() = DriverState::Error;
                    return Err(ModbusError::Timeout { duration });
                }
                Ok(Err(e)) => {
                    *self.state.lock().unwrap() = DriverState::Error;
                    return Err(ModbusError::IoError(format!(
                        "Failed to read exception response: {}",
                        e
                    )));
                }
                Ok(Ok(_)) => {}
            }

            // 组装完整帧并验证 CRC
            let mut full_frame = Vec::with_capacity(5);
            full_frame.extend_from_slice(&header);
            full_frame.extend_from_slice(&remaining);

            let received_crc =
                Self::parse_crc(&full_frame[3..5]).ok_or(ModbusError::IncompleteFrame)?;
            let data_for_crc = &full_frame[..3]; // slave_id + function_code + exception_code
            Self::verify_crc16(data_for_crc, received_crc)?;

            // 提取异常码
            let exception_code = remaining[0];
            let exception = ModbusException::from_u8(exception_code);
            return Err(ModbusError::from(exception));
        }

        // 解析功能码
        let function_code = FunctionCode::from_u8(function_code_byte)
            .ok_or(ModbusError::InvalidFunctionCode(function_code_byte))?;

        // ========== 步骤 3: 根据功能码确定响应长度 ==========

        let total_frame_len = match function_code {
            // 读取响应: [slave_id, function_code, byte_count, data..., crc_low, crc_high]
            FunctionCode::ReadCoils | FunctionCode::ReadDiscreteInputs => {
                // 读取 byte_count (1 byte)
                let mut byte_count_buf = [0u8; 1];
                let result = timeout(duration, stream.read_exact(&mut byte_count_buf)).await;
                match result {
                    Err(_) => {
                        *self.state.lock().unwrap() = DriverState::Error;
                        return Err(ModbusError::Timeout { duration });
                    }
                    Ok(Err(e)) => {
                        *self.state.lock().unwrap() = DriverState::Error;
                        return Err(ModbusError::IoError(format!(
                            "Failed to read byte count: {}",
                            e
                        )));
                    }
                    Ok(Ok(_)) => {}
                }

                let byte_count = byte_count_buf[0] as usize;
                // 总长度 = slave_id(1) + function_code(1) + byte_count(1) + data(byte_count) + crc(2)
                1 + 1 + 1 + byte_count + 2
            }
            FunctionCode::ReadHoldingRegisters | FunctionCode::ReadInputRegisters => {
                // 读取 byte_count (1 byte)
                let mut byte_count_buf = [0u8; 1];
                let result = timeout(duration, stream.read_exact(&mut byte_count_buf)).await;
                match result {
                    Err(_) => {
                        *self.state.lock().unwrap() = DriverState::Error;
                        return Err(ModbusError::Timeout { duration });
                    }
                    Ok(Err(e)) => {
                        *self.state.lock().unwrap() = DriverState::Error;
                        return Err(ModbusError::IoError(format!(
                            "Failed to read byte count: {}",
                            e
                        )));
                    }
                    Ok(Ok(_)) => {}
                }

                let byte_count = byte_count_buf[0] as usize;
                // 总长度 = slave_id(1) + function_code(1) + byte_count(1) + data(byte_count) + crc(2)
                1 + 1 + 1 + byte_count + 2
            }
            // 写入单个线圈响应: [slave_id, function_code, address(2), value(2), crc(2)] = 8 bytes
            FunctionCode::WriteSingleCoil => 8,
            // 写入单个寄存器响应: [slave_id, function_code, address(2), value(2), crc(2)] = 8 bytes
            FunctionCode::WriteSingleRegister => 8,
            // 写入多个线圈响应: [slave_id, function_code, address(2), quantity(2), crc(2)] = 8 bytes
            FunctionCode::WriteMultipleCoils => 8,
            // 写入多个寄存器响应: [slave_id, function_code, address(2), quantity(2), crc(2)] = 8 bytes
            FunctionCode::WriteMultipleRegisters => 8,
        };

        // ========== 步骤 4: 读取剩余字节 ==========

        // 已经读取了 2 字节 (header)，还需要读取剩余字节
        let already_read = 2usize;
        let remaining_len = total_frame_len.saturating_sub(already_read);

        let mut response_buf = Vec::with_capacity(total_frame_len);
        response_buf.extend_from_slice(&header);
        response_buf.resize(total_frame_len, 0);

        if remaining_len > 0 {
            let result = timeout(
                duration,
                stream.read_exact(&mut response_buf[already_read..]),
            )
            .await;

            match result {
                Err(_) => {
                    *self.state.lock().unwrap() = DriverState::Error;
                    return Err(ModbusError::Timeout { duration });
                }
                Ok(Err(e)) => {
                    *self.state.lock().unwrap() = DriverState::Error;
                    return Err(ModbusError::IoError(format!(
                        "Failed to read response data: {}",
                        e
                    )));
                }
                Ok(Ok(_)) => {}
            }
        }

        // ========== 步骤 5: 验证 CRC ==========

        let received_crc = Self::parse_crc(&response_buf[response_buf.len() - 2..])
            .ok_or(ModbusError::IncompleteFrame)?;
        let data_for_crc = &response_buf[..response_buf.len() - 2]; // 不含 CRC 部分
        Self::verify_crc16(data_for_crc, received_crc)?;

        // 提取 PDU (function_code + data)
        let pdu_data = &response_buf[1..response_buf.len() - 2];
        let response_pdu = Pdu::parse(pdu_data)?;

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
                PointValue::Boolean(coil_value)
            }
            RegisterType::DiscreteInput => {
                let input_value = self
                    .read_single_discrete_input(point_config.address)
                    .await
                    .map_err(DriverError::from)?;
                PointValue::Boolean(input_value)
            }
            RegisterType::HoldingRegister => {
                let register_value = self
                    .read_single_holding_register(point_config.address)
                    .await
                    .map_err(DriverError::from)?;
                PointValue::Integer(register_value as i64)
            }
            RegisterType::InputRegister => {
                let register_value = self
                    .read_single_input_register(point_config.address)
                    .await
                    .map_err(DriverError::from)?;
                PointValue::Integer(register_value as i64)
            }
        };

        Ok(value)
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

#[async_trait]
impl DriverLifecycle for ModbusRtuDriver {
    /// 连接到 Modbus RTU 从站
    async fn connect(&mut self) -> Result<(), DriverError> {
        if *self.state.lock().unwrap() == DriverState::Connected {
            return Err(DriverError::AlreadyConnected);
        }

        *self.state.lock().unwrap() = DriverState::Connecting;

        // 打开串口
        let port = serialport::new(&self.config.port, self.config.baud_rate)
            .data_bits(match self.config.data_bits {
                7 => serialport::DataBits::Seven,
                8 => serialport::DataBits::Eight,
                _ => serialport::DataBits::Eight,
            })
            .stop_bits(match self.config.stop_bits {
                1 => serialport::StopBits::One,
                2 => serialport::StopBits::Two,
                _ => serialport::StopBits::One,
            })
            .parity(self.config.parity.to_serialport_parity())
            .timeout(self.config.timeout())
            .open_native_async()
            .map_err(|e| {
                *self.state.lock().unwrap() = DriverState::Error;
                DriverError::IoError(format!("Failed to open serial port: {}", e))
            })?;

        *self.stream.lock().await = Some(port);
        *self.state.lock().unwrap() = DriverState::Connected;
        Ok(())
    }

    /// 断开与 Modbus RTU 从站的连接
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
impl DeviceDriver for ModbusRtuDriver {
    type Config = ModbusRtuConfig;
    type Error = DriverError;

    async fn connect(&mut self) -> Result<(), Self::Error> {
        DriverLifecycle::connect(self).await
    }

    async fn disconnect(&mut self) -> Result<(), Self::Error> {
        DriverLifecycle::disconnect(self).await
    }

    fn read_point(&self, point_id: Uuid) -> Result<PointValue, Self::Error> {
        tokio::runtime::Handle::current().block_on(self.read_point_async(point_id))
    }

    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), Self::Error> {
        tokio::runtime::Handle::current().block_on(self.write_point_async(point_id, value))
    }

    fn is_connected(&self) -> bool {
        DriverLifecycle::is_connected(self)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ========== ModbusRtuConfig Tests ==========

    #[test]
    fn test_modbus_rtu_config_default() {
        let config = ModbusRtuConfig::default();
        assert_eq!(config.port, "/dev/ttyUSB0");
        assert_eq!(config.baud_rate, 9600);
        assert_eq!(config.data_bits, 8);
        assert_eq!(config.stop_bits, 1);
        assert_eq!(config.parity, Parity::None);
        assert_eq!(config.timeout_ms, 3000);
        assert_eq!(config.slave_id, 1);
    }

    #[test]
    fn test_modbus_rtu_config_new() {
        let config = ModbusRtuConfig::new("/dev/ttyUSB1", 19200, 8, 1, Parity::Even, 5000, 2);
        assert_eq!(config.port, "/dev/ttyUSB1");
        assert_eq!(config.baud_rate, 19200);
        assert_eq!(config.parity, Parity::Even);
        assert_eq!(config.slave_id, 2);
        assert_eq!(config.timeout_ms, 5000);
    }

    #[test]
    fn test_modbus_rtu_config_timeout() {
        let config = ModbusRtuConfig::default();
        assert_eq!(config.timeout(), Duration::from_millis(3000));
    }

    #[test]
    fn test_modbus_rtu_config_valid_slave_id() {
        let mut config = ModbusRtuConfig::default();
        assert!(config.is_valid_slave_id());

        config.slave_id = 0;
        assert!(!config.is_valid_slave_id());

        config.slave_id = 248;
        assert!(!config.is_valid_slave_id());

        config.slave_id = 1;
        assert!(config.is_valid_slave_id());

        config.slave_id = 247;
        assert!(config.is_valid_slave_id());
    }

    // ========== Parity Tests ==========

    #[test]
    fn test_parity_default() {
        assert_eq!(Parity::default(), Parity::None);
    }

    #[test]
    fn test_parity_to_serialport_parity() {
        assert_eq!(
            Parity::None.to_serialport_parity(),
            serialport::Parity::None
        );
        assert_eq!(
            Parity::Even.to_serialport_parity(),
            serialport::Parity::Even
        );
        assert_eq!(Parity::Odd.to_serialport_parity(), serialport::Parity::Odd);
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

    // ========== ModbusRtuDriver Tests ==========

    #[test]
    fn test_modbus_rtu_driver_new() {
        let config = ModbusRtuConfig::new("/dev/ttyUSB0", 9600, 8, 1, Parity::None, 3000, 1);
        let driver = ModbusRtuDriver::new(config);
        assert_eq!(driver.state(), DriverState::Disconnected);
    }

    #[test]
    fn test_modbus_rtu_driver_with_defaults() {
        let driver = ModbusRtuDriver::with_defaults();
        assert_eq!(driver.state(), DriverState::Disconnected);
        assert_eq!(driver.config().port, "/dev/ttyUSB0");
    }

    #[test]
    fn test_modbus_rtu_driver_with_port() {
        let driver = ModbusRtuDriver::with_port("/dev/ttyAMA0");
        assert_eq!(driver.config().port, "/dev/ttyAMA0");
    }

    #[test]
    fn test_modbus_rtu_driver_not_connected() {
        let driver = ModbusRtuDriver::with_defaults();
        assert!(!DriverLifecycle::is_connected(&driver));
    }

    #[test]
    fn test_modbus_rtu_driver_configure_points() {
        let driver = ModbusRtuDriver::with_defaults();
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
    fn test_modbus_rtu_driver_add_point() {
        let driver = ModbusRtuDriver::with_defaults();
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
    fn test_modbus_rtu_driver_get_point_not_found() {
        let driver = ModbusRtuDriver::with_defaults();
        let point_id = Uuid::new_v4();
        assert!(driver.get_point_config(&point_id).is_none());
    }

    // ========== CRC16 Tests ==========

    #[test]
    fn test_crc16_calculation() {
        // TC-RTU-102: CRC16 计算验证
        // 测试数据: [0x01, 0x03, 0x00, 0x00, 0x00, 0x01]
        // 预期 CRC: 0x0A84 (低字节在前)
        let data = [0x01, 0x03, 0x00, 0x00, 0x00, 0x01];
        let crc = ModbusRtuDriver::calculate_crc16(&data);
        assert_eq!(
            crc, 0x0A84,
            "CRC16 calculation failed for standard test data"
        );
    }

    #[test]
    fn test_crc16_additional_test_cases() {
        // TC-RTU-102: 额外的 CRC16 测试数据
        // [0x01, 0x03, 0x00, 0x00, 0x00, 0x0A] -> CRC: 0xCDC5
        let data1 = [0x01, 0x03, 0x00, 0x00, 0x00, 0x0A];
        let crc1 = ModbusRtuDriver::calculate_crc16(&data1);
        assert_eq!(crc1, 0xCDC5);

        // [0x01, 0x05, 0x00, 0x00, 0xFF, 0x00] -> CRC: 0x3A8C
        let data2 = [0x01, 0x05, 0x00, 0x00, 0xFF, 0x00];
        let crc2 = ModbusRtuDriver::calculate_crc16(&data2);
        assert_eq!(crc2, 0x3A8C);
    }

    #[test]
    fn test_crc16_verify_valid() {
        let data = [0x01, 0x03, 0x00, 0x00, 0x00, 0x01];
        let crc = ModbusRtuDriver::calculate_crc16(&data);
        assert!(ModbusRtuDriver::verify_crc16(&data, crc).is_ok());
    }

    #[test]
    fn test_crc16_verify_invalid() {
        let data = [0x01, 0x03, 0x00, 0x00, 0x00, 0x01];
        let wrong_crc = 0x0000;
        let result = ModbusRtuDriver::verify_crc16(&data, wrong_crc);
        assert!(result.is_err());
        if let Err(ModbusError::FrameChecksumMismatch { expected, actual }) = result {
            assert_eq!(expected, 0x0A84);
            assert_eq!(actual, 0x0000);
        } else {
            panic!("Expected FrameChecksumMismatch error");
        }
    }

    #[test]
    fn test_parse_crc() {
        // 低字节在前
        let bytes = [0x84, 0x0A]; // 0x0A84
        let crc = ModbusRtuDriver::parse_crc(&bytes);
        assert_eq!(crc, Some(0x0A84));

        // 字节不足
        let bytes_short = [0x0A];
        assert_eq!(ModbusRtuDriver::parse_crc(&bytes_short), None);
    }

    // ========== RTU Frame Tests ==========

    #[test]
    fn test_rtu_frame_build_read_holding_registers() {
        // TC-RTU-101: RTU 帧组装 - 基本结构
        let config = ModbusRtuConfig::default();
        let driver = ModbusRtuDriver::new(config);

        let pdu = Pdu::read_holding_registers(ModbusAddress::new(0), 1).unwrap();
        let frame = driver.build_rtu_frame(&pdu);

        // 预期帧: [0x01, 0x03, 0x00, 0x00, 0x00, 0x01, 0x84, 0x0A]
        //                                    |--- PDU ---|   |--- CRC ---|
        assert_eq!(frame.len(), 8);
        assert_eq!(frame[0], 0x01); // slave_id
        assert_eq!(frame[1], 0x03); // function_code
        assert_eq!(frame[2], 0x00); // address high
        assert_eq!(frame[3], 0x00); // address low
        assert_eq!(frame[4], 0x00); // quantity high
        assert_eq!(frame[5], 0x01); // quantity low
        assert_eq!(frame[6], 0x84); // CRC low
        assert_eq!(frame[7], 0x0A); // CRC high
    }

    #[test]
    fn test_rtu_frame_build_write_single_coil_on() {
        // TC-RTU-301: 写入线圈 ON (0xFF00)
        let config = ModbusRtuConfig::default();
        let driver = ModbusRtuDriver::new(config);

        let pdu = Pdu::write_single_coil(ModbusAddress::new(0), true).unwrap();
        let frame = driver.build_rtu_frame(&pdu);

        // 预期帧: [0x01, 0x05, 0x00, 0x00, 0xFF, 0x00, CRC_L, CRC_H]
        assert_eq!(frame.len(), 8);
        assert_eq!(frame[0], 0x01); // slave_id
        assert_eq!(frame[1], 0x05); // function_code
        assert_eq!(frame[4], 0xFF); // value high (ON = 0xFF00)
        assert_eq!(frame[5], 0x00); // value low

        // 验证 CRC
        let crc = ModbusRtuDriver::parse_crc(&frame[6..8]).unwrap();
        let data_for_crc = &frame[..6];
        assert!(ModbusRtuDriver::verify_crc16(data_for_crc, crc).is_ok());
    }

    #[test]
    fn test_rtu_frame_build_write_single_coil_off() {
        // TC-RTU-302: 写入线圈 OFF (0x0000)
        let config = ModbusRtuConfig::default();
        let driver = ModbusRtuDriver::new(config);

        let pdu = Pdu::write_single_coil(ModbusAddress::new(0), false).unwrap();
        let frame = driver.build_rtu_frame(&pdu);

        assert_eq!(frame.len(), 8);
        assert_eq!(frame[4], 0x00); // value high (OFF = 0x0000)
        assert_eq!(frame[5], 0x00); // value low
    }

    #[test]
    fn test_rtu_frame_build_write_single_register() {
        // TC-RTU-303: 写入保持寄存器
        let config = ModbusRtuConfig::default();
        let driver = ModbusRtuDriver::new(config);

        let pdu = Pdu::write_single_register(ModbusAddress::new(0), 0x1234).unwrap();
        let frame = driver.build_rtu_frame(&pdu);

        assert_eq!(frame.len(), 8);
        assert_eq!(frame[4], 0x12); // value high
        assert_eq!(frame[5], 0x34); // value low
    }

    // ========== Connection Tests (需要真实串口或 mock) ==========

    #[tokio::test]
    async fn test_disconnect_not_connected() {
        let mut driver = ModbusRtuDriver::with_defaults();
        let result: Result<(), DriverError> = DriverLifecycle::disconnect(&mut driver).await;
        assert!(result.is_ok());
        assert!(!DriverLifecycle::is_connected(&driver));
    }

    // ========== Read/Write Point Tests ==========

    #[tokio::test]
    async fn test_read_point_not_connected() {
        let driver = ModbusRtuDriver::with_defaults();
        let point_id = Uuid::new_v4();
        let result = driver.read_point_async(point_id).await;
        assert!(matches!(result, Err(DriverError::NotConnected)));
    }

    #[tokio::test]
    async fn test_write_point_not_connected() {
        let driver = ModbusRtuDriver::with_defaults();
        let point_id = Uuid::new_v4();
        let result = driver
            .write_point_async(point_id, PointValue::Boolean(true))
            .await;
        assert!(matches!(result, Err(DriverError::NotConnected)));
    }

    #[tokio::test]
    async fn test_read_point_not_found() {
        let config = ModbusRtuConfig::new("/dev/ttyUSB0", 9600, 8, 1, Parity::None, 1000, 1);
        let driver = ModbusRtuDriver::new(config);

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
