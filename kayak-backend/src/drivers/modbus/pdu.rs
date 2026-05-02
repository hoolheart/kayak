use serde::{Deserialize, Serialize};

use super::error::ModbusError;
use super::types::{FunctionCode, ModbusAddress};

/// Modbus PDU (Protocol Data Unit)
///
/// PDU 是 Modbus 协议的核心数据单元，包含：
/// - Function Code (1 byte): 功能码
/// - Data (0-252 bytes): 数据内容
///
/// ```text
/// +-------------+-------------+
/// | Function    |    Data     |
/// |   Code      |   (N bytes) |
/// +-------------+-------------+
/// ```
///
/// PDU 最大长度为 253 字节 (1 byte function code + 252 bytes data)。
/// 这受限于 Modbus PDU 最大长度 256 字节减去 MBAP 头部的 3 字节。
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Pdu {
    /// 功能码
    pub function_code: FunctionCode,
    /// 原始数据字节
    pub data: Vec<u8>,
}

impl Pdu {
    /// PDU 的最大长度
    pub const MAX_LENGTH: usize = 253;
    /// PDU 的最小长度
    pub const MIN_LENGTH: usize = 1;

    /// 创建新的 PDU
    pub fn new(function_code: FunctionCode, data: Vec<u8>) -> Result<Self, ModbusError> {
        let total_len = 1 + data.len();
        if total_len > Self::MAX_LENGTH {
            return Err(ModbusError::InvalidPduLength {
                expected: Self::MAX_LENGTH,
                actual: total_len,
            });
        }
        Ok(Self {
            function_code,
            data,
        })
    }

    /// 从字节数组解析 PDU
    ///
    /// # Arguments
    /// * `data` - 至少 1 字节的 PDU 数据
    ///
    /// # Returns
    /// * `Ok(Pdu)` - 解析成功
    /// * `Err(ModbusError)` - 解析失败
    pub fn parse(data: &[u8]) -> Result<Self, ModbusError> {
        if data.is_empty() {
            return Err(ModbusError::IncompleteFrame);
        }

        let function_code =
            FunctionCode::from_u8(data[0]).ok_or(ModbusError::InvalidFunctionCode(data[0]))?;

        Ok(Self {
            function_code,
            data: data[1..].to_vec(),
        })
    }

    /// 将 PDU 序列化为字节数组
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut bytes = Vec::with_capacity(1 + self.data.len());
        bytes.push(self.function_code.code());
        bytes.extend_from_slice(&self.data);
        bytes
    }

    /// 获取 PDU 总长度
    pub fn len(&self) -> usize {
        1 + self.data.len()
    }

    /// 判断 PDU 是否为空
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }

    // ========== 读取类 PDU 构造 ==========

    /// 创建 ReadCoils 请求 PDU
    pub fn read_coils(address: ModbusAddress, quantity: u16) -> Result<Self, ModbusError> {
        if quantity == 0 || quantity > 2000 {
            return Err(ModbusError::InvalidValue(format!(
                "Invalid quantity {} for ReadCoils (must be 1-2000)",
                quantity
            )));
        }
        let mut data = Vec::with_capacity(4);
        data.extend_from_slice(&address.to_be_bytes());
        data.extend_from_slice(&quantity.to_be_bytes());
        Self::new(FunctionCode::ReadCoils, data)
    }

    /// 创建 ReadDiscreteInputs 请求 PDU
    pub fn read_discrete_inputs(
        address: ModbusAddress,
        quantity: u16,
    ) -> Result<Self, ModbusError> {
        if quantity == 0 || quantity > 2000 {
            return Err(ModbusError::InvalidValue(format!(
                "Invalid quantity {} for ReadDiscreteInputs (must be 1-2000)",
                quantity
            )));
        }
        let mut data = Vec::with_capacity(4);
        data.extend_from_slice(&address.to_be_bytes());
        data.extend_from_slice(&quantity.to_be_bytes());
        Self::new(FunctionCode::ReadDiscreteInputs, data)
    }

    /// 创建 ReadHoldingRegisters 请求 PDU
    pub fn read_holding_registers(
        address: ModbusAddress,
        quantity: u16,
    ) -> Result<Self, ModbusError> {
        if quantity == 0 || quantity > 125 {
            return Err(ModbusError::InvalidValue(format!(
                "Invalid quantity {} for ReadHoldingRegisters (must be 1-125)",
                quantity
            )));
        }
        let mut data = Vec::with_capacity(4);
        data.extend_from_slice(&address.to_be_bytes());
        data.extend_from_slice(&quantity.to_be_bytes());
        Self::new(FunctionCode::ReadHoldingRegisters, data)
    }

    /// 创建 ReadInputRegisters 请求 PDU
    pub fn read_input_registers(
        address: ModbusAddress,
        quantity: u16,
    ) -> Result<Self, ModbusError> {
        if quantity == 0 || quantity > 125 {
            return Err(ModbusError::InvalidValue(format!(
                "Invalid quantity {} for ReadInputRegisters (must be 1-125)",
                quantity
            )));
        }
        let mut data = Vec::with_capacity(4);
        data.extend_from_slice(&address.to_be_bytes());
        data.extend_from_slice(&quantity.to_be_bytes());
        Self::new(FunctionCode::ReadInputRegisters, data)
    }

    // ========== 写入类 PDU 构造 ==========

    /// 创建 WriteSingleCoil 请求 PDU
    ///
    /// Modbus 协议规定：线圈值 0xFF00 表示 ON，0x0000 表示 OFF
    pub fn write_single_coil(address: ModbusAddress, value: bool) -> Result<Self, ModbusError> {
        let mut data = Vec::with_capacity(4);
        data.extend_from_slice(&address.to_be_bytes());
        // Modbus 编码：ON = 0xFF00, OFF = 0x0000
        let register_value: u16 = if value { 0xFF00 } else { 0x0000 };
        data.extend_from_slice(&register_value.to_be_bytes());
        Self::new(FunctionCode::WriteSingleCoil, data)
    }

    /// 创建 WriteSingleRegister 请求 PDU
    pub fn write_single_register(address: ModbusAddress, value: u16) -> Result<Self, ModbusError> {
        let mut data = Vec::with_capacity(4);
        data.extend_from_slice(&address.to_be_bytes());
        data.extend_from_slice(&value.to_be_bytes());
        Self::new(FunctionCode::WriteSingleRegister, data)
    }

    /// 创建 WriteMultipleCoils 请求 PDU
    pub fn write_multiple_coils(
        address: ModbusAddress,
        values: &[bool],
    ) -> Result<Self, ModbusError> {
        let quantity = values.len() as u16;
        if quantity == 0 || quantity > 1968 {
            return Err(ModbusError::InvalidValue(format!(
                "Invalid quantity {} for WriteMultipleCoils (must be 1-1968)",
                quantity
            )));
        }

        let byte_count = ((quantity + 7) / 8) as u8;
        let mut data = Vec::with_capacity(5 + byte_count as usize);
        data.extend_from_slice(&address.to_be_bytes());
        data.extend_from_slice(&quantity.to_be_bytes());
        data.push(byte_count);

        // 将布尔值打包成字节
        for chunk in values.chunks(8) {
            let mut byte = 0u8;
            for (i, &v) in chunk.iter().enumerate() {
                if v {
                    byte |= 1 << i;
                }
            }
            data.push(byte);
        }

        Self::new(FunctionCode::WriteMultipleCoils, data)
    }

    /// 创建 WriteMultipleRegisters 请求 PDU
    pub fn write_multiple_registers(
        address: ModbusAddress,
        values: &[u16],
    ) -> Result<Self, ModbusError> {
        let quantity = values.len() as u16;
        if quantity == 0 || quantity > 123 {
            return Err(ModbusError::InvalidValue(format!(
                "Invalid quantity {} for WriteMultipleRegisters (must be 1-123)",
                quantity
            )));
        }

        let byte_count = (quantity * 2) as u8;
        let mut data = Vec::with_capacity(5 + byte_count as usize);
        data.extend_from_slice(&address.to_be_bytes());
        data.extend_from_slice(&quantity.to_be_bytes());
        data.push(byte_count);

        for &value in values {
            data.extend_from_slice(&value.to_be_bytes());
        }

        Self::new(FunctionCode::WriteMultipleRegisters, data)
    }

    // ========== 解析方法 ==========

    /// 解析 ReadCoils/ReadDiscreteInputs 响应
    ///
    /// # Returns
    /// * `Ok(Vec<bool>)` - 线圈值数组
    pub fn parse_coils_response(&self) -> Result<Vec<bool>, ModbusError> {
        if self.data.is_empty() {
            return Err(ModbusError::PduError("Empty coils response".into()));
        }

        let byte_count = self.data[0] as usize;
        if self.data.len() < 1 + byte_count {
            return Err(ModbusError::IncompleteFrame);
        }

        let mut coils = Vec::with_capacity(byte_count * 8);
        for &byte in &self.data[1..=byte_count] {
            for i in 0..8 {
                coils.push((byte & (1 << i)) != 0);
            }
        }

        Ok(coils)
    }

    /// 解析 ReadRegisters 响应
    ///
    /// # Returns
    /// * `Ok(Vec<u16>)` - 寄存器值数组
    pub fn parse_registers_response(&self) -> Result<Vec<u16>, ModbusError> {
        if self.data.is_empty() {
            return Err(ModbusError::PduError("Empty registers response".into()));
        }

        let byte_count = self.data[0] as usize;
        if self.data.len() < 1 + byte_count || byte_count % 2 != 0 {
            return Err(ModbusError::PduError(
                "Invalid registers response format".into(),
            ));
        }

        let mut registers = Vec::with_capacity(byte_count / 2);
        for chunk in self.data[1..].chunks(2) {
            registers.push(u16::from_be_bytes([chunk[0], chunk[1]]));
        }

        Ok(registers)
    }

    /// 判断是否为错误响应（功能码 + 0x80）
    pub fn is_error_response(&self) -> bool {
        self.function_code.code() & 0x80 != 0
    }

    /// 获取异常码（如果这是错误响应）
    pub fn exception_code(&self) -> Option<u8> {
        if self.is_error_response() && !self.data.is_empty() {
            Some(self.data[0])
        } else {
            None
        }
    }

    /// 从 PDU 提取起始地址（适用于读取/写入请求）
    pub fn start_address(&self) -> Option<ModbusAddress> {
        if self.data.len() >= 2 {
            Some(ModbusAddress::from_raw(u16::from_be_bytes([
                self.data[0],
                self.data[1],
            ])))
        } else {
            None
        }
    }

    /// 从 PDU 提取数量（适用于读取请求）
    pub fn quantity(&self) -> Option<u16> {
        if self.data.len() >= 4 {
            Some(u16::from_be_bytes([self.data[2], self.data[3]]))
        } else {
            None
        }
    }
}

impl std::fmt::Display for Pdu {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "Pdu {{ {}: {} bytes }}",
            self.function_code,
            self.data.len()
        )
    }
}
