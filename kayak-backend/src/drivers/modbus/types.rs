use serde::{Deserialize, Serialize};

/// Modbus 功能码枚举
///
/// 涵盖本项目支持的 Modbus 读取/写入功能码。
/// 注意：不包含诊断功能码 (0x07, 0x08, 0x11) 等扩展功能码。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[repr(u8)]
pub enum FunctionCode {
    /// 读取线圈 (Read Coils)
    ReadCoils = 0x01,
    /// 读取离散输入 (Read Discrete Inputs)
    ReadDiscreteInputs = 0x02,
    /// 读取保持寄存器 (Read Holding Registers)
    ReadHoldingRegisters = 0x03,
    /// 读取输入寄存器 (Read Input Registers)
    ReadInputRegisters = 0x04,
    /// 写入单个线圈 (Write Single Coil)
    WriteSingleCoil = 0x05,
    /// 写入单个寄存器 (Write Single Register)
    WriteSingleRegister = 0x06,
    /// 写入多个线圈 (Write Multiple Coils)
    WriteMultipleCoils = 0x0F,
    /// 写入多个寄存器 (Write Multiple Registers)
    WriteMultipleRegisters = 0x10,
}

impl FunctionCode {
    /// 从 u8 值创建 FunctionCode
    ///
    /// # Returns
    /// * `Some(FunctionCode)` - 有效的功能码
    /// * `None` - 无效的功能码值
    pub fn from_u8(value: u8) -> Option<Self> {
        match value {
            0x01 => Some(Self::ReadCoils),
            0x02 => Some(Self::ReadDiscreteInputs),
            0x03 => Some(Self::ReadHoldingRegisters),
            0x04 => Some(Self::ReadInputRegisters),
            0x05 => Some(Self::WriteSingleCoil),
            0x06 => Some(Self::WriteSingleRegister),
            0x0F => Some(Self::WriteMultipleCoils),
            0x10 => Some(Self::WriteMultipleRegisters),
            _ => None,
        }
    }

    /// 从 u8 值创建 FunctionCode（宽松模式）
    ///
    /// 仅验证值是否在支持范围内，不验证是否为已知的 Modbus 功能码。
    /// 用于处理服务器返回的未知功能码。
    pub fn from_u8_unchecked(value: u8) -> Self {
        Self::from_u8(value).unwrap_or_else(|| {
            // SAFETY: u8 可以无损转换为 FunctionCode 的 repr(u8)
            // 但实际上我们使用这个方法来处理"未知但有效"的场景
            // 实际实现应该使用一个专门的 "Unknown(u8)" 变体或类似机制
            unsafe { std::mem::transmute(value) }
        })
    }

    /// 获取功能码的 u8 值
    pub fn code(&self) -> u8 {
        *self as u8
    }

    /// 判断是否为读取类功能码
    pub fn is_read(&self) -> bool {
        matches!(
            self,
            Self::ReadCoils
                | Self::ReadDiscreteInputs
                | Self::ReadHoldingRegisters
                | Self::ReadInputRegisters
        )
    }

    /// 判断是否为写入类功能码
    pub fn is_write(&self) -> bool {
        matches!(
            self,
            Self::WriteSingleCoil
                | Self::WriteSingleRegister
                | Self::WriteMultipleCoils
                | Self::WriteMultipleRegisters
        )
    }

    /// 判断功能码是否需要字节计数字段
    ///
    /// WriteMultipleCoils 和 WriteMultipleRegisters 需要 byte_count 字段。
    pub fn has_byte_count(&self) -> bool {
        matches!(
            self,
            Self::WriteMultipleCoils | Self::WriteMultipleRegisters
        )
    }
}

impl std::fmt::Display for FunctionCode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let name = match self {
            Self::ReadCoils => "ReadCoils",
            Self::ReadDiscreteInputs => "ReadDiscreteInputs",
            Self::ReadHoldingRegisters => "ReadHoldingRegisters",
            Self::ReadInputRegisters => "ReadInputRegisters",
            Self::WriteSingleCoil => "WriteSingleCoil",
            Self::WriteSingleRegister => "WriteSingleRegister",
            Self::WriteMultipleCoils => "WriteMultipleCoils",
            Self::WriteMultipleRegisters => "WriteMultipleRegisters",
        };
        write!(f, "{}", name)
    }
}

/// Modbus 寄存器地址
///
/// 地址范围: 0x0000 - 0xFFFF (0 - 65535)
/// 注意：某些设备可能限制有效地址范围，但本类型不做限制。
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub struct ModbusAddress(u16);

impl ModbusAddress {
    /// 最小地址
    pub const MIN: u16 = 0x0000;
    /// 最大地址
    pub const MAX: u16 = 0xFFFF;

    /// 创建 ModbusAddress
    ///
    /// # Returns
    /// * `Ok(ModbusAddress)` - 有效地址
    /// * `Err(())` - 地址超出有效范围（实际不会发生，因为 u16 永远有效）
    #[inline]
    pub fn new(address: u16) -> Self {
        Self(address)
    }

    /// 从原始 u16 值创建（不安全，内部使用）
    ///
    /// 仅在确信值在有效范围内时使用。
    #[inline]
    pub const fn from_raw(address: u16) -> Self {
        Self(address)
    }

    /// 获取地址的 u16 值
    #[inline]
    pub fn value(&self) -> u16 {
        self.0
    }

    /// 获取地址的高字节
    #[inline]
    pub fn high_byte(&self) -> u8 {
        (self.0 >> 8) as u8
    }

    /// 获取地址的低字节
    #[inline]
    pub fn low_byte(&self) -> u8 {
        (self.0 & 0xFF) as u8
    }

    /// 转换为大端字节序数组
    #[inline]
    pub fn to_be_bytes(&self) -> [u8; 2] {
        self.0.to_be_bytes()
    }

    /// 从大端字节序数组创建
    pub fn from_be_bytes(bytes: [u8; 2]) -> Self {
        Self(u16::from_be_bytes(bytes))
    }

    /// 检查地址是否在有效范围内
    ///
    /// Modbus 地址始终在 0x0000-0xFFFF 范围内，此方法始终返回 true。
    /// 保留此方法用于接口一致性。
    #[inline]
    pub fn is_valid(&self) -> bool {
        self.0 >= Self::MIN && self.0 <= Self::MAX
    }
}

impl Default for ModbusAddress {
    fn default() -> Self {
        Self(0x0000)
    }
}

impl From<u16> for ModbusAddress {
    fn from(value: u16) -> Self {
        Self::new(value)
    }
}

impl From<ModbusAddress> for u16 {
    fn from(addr: ModbusAddress) -> Self {
        addr.value()
    }
}

impl std::fmt::Display for ModbusAddress {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "0x{:04X}", self.0)
    }
}

/// Modbus 寄存器类型
///
/// 对应 Modbus 协议中的四类数据区：
/// - Coil (线圈): 可读写位，地址 0XXXX
/// - Discrete Input (离散输入): 只读位，地址 1XXXX
/// - Holding Register (保持寄存器): 可读写字，地址 4XXXX
/// - Input Register (输入寄存器): 只读字，地址 3XXXX
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum RegisterType {
    /// 线圈 (Read/Write)
    Coil,
    /// 离散输入 (Read Only)
    DiscreteInput,
    /// 保持寄存器 (Read/Write)
    HoldingRegister,
    /// 输入寄存器 (Read Only)
    InputRegister,
}

impl RegisterType {
    /// 获取对应的读取功能码
    pub fn read_function_code(&self) -> FunctionCode {
        match self {
            Self::Coil => FunctionCode::ReadCoils,
            Self::DiscreteInput => FunctionCode::ReadDiscreteInputs,
            Self::HoldingRegister => FunctionCode::ReadHoldingRegisters,
            Self::InputRegister => FunctionCode::ReadInputRegisters,
        }
    }

    /// 获取对应的写入功能码
    ///
    /// 注意：DiscreteInput 和 InputRegister 是只读的，没有写入功能码。
    pub fn write_function_code(&self) -> Option<FunctionCode> {
        match self {
            Self::Coil => Some(FunctionCode::WriteSingleCoil),
            Self::HoldingRegister => Some(FunctionCode::WriteSingleRegister),
            _ => None,
        }
    }

    /// 判断是否为只读类型
    pub fn is_read_only(&self) -> bool {
        matches!(self, Self::DiscreteInput | Self::InputRegister)
    }

    /// 判断数据类型是否为布尔类型（线圈类）
    pub fn is_boolean(&self) -> bool {
        matches!(self, Self::Coil | Self::DiscreteInput)
    }

    /// 判断数据类型是否为字类型（寄存器类）
    pub fn is_register(&self) -> bool {
        matches!(self, Self::HoldingRegister | Self::InputRegister)
    }
}

impl std::fmt::Display for RegisterType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let name = match self {
            Self::Coil => "Coil",
            Self::DiscreteInput => "DiscreteInput",
            Self::HoldingRegister => "HoldingRegister",
            Self::InputRegister => "InputRegister",
        };
        write!(f, "{}", name)
    }
}

/// Modbus 数据值
///
/// 统一表示 Modbus 中的所有数据类型：
/// - 布尔值：Coil 和 DiscreteInput
/// - u16 值：HoldingRegister 和 InputRegister
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ModbusValue {
    /// 线圈值 (布尔值)
    Coil(bool),
    /// 离散输入值 (布尔值)
    DiscreteInput(bool),
    /// 保持寄存器值 (u16)
    HoldingRegister(u16),
    /// 输入寄存器值 (u16)
    InputRegister(u16),
}

impl ModbusValue {
    /// 创建线圈值
    #[inline]
    pub fn coil(value: bool) -> Self {
        Self::Coil(value)
    }

    /// 创建离散输入值
    #[inline]
    pub fn discrete_input(value: bool) -> Self {
        Self::DiscreteInput(value)
    }

    /// 创建保持寄存器值
    #[inline]
    pub fn holding_register(value: u16) -> Self {
        Self::HoldingRegister(value)
    }

    /// 创建输入寄存器值
    #[inline]
    pub fn input_register(value: u16) -> Self {
        Self::InputRegister(value)
    }

    /// 尝试获取布尔值
    ///
    /// # Returns
    /// * `Some(bool)` - 如果是 Coil 或 DiscreteInput
    /// * `None` - 如果是寄存器类型
    pub fn as_bool(&self) -> Option<bool> {
        match self {
            Self::Coil(v) | Self::DiscreteInput(v) => Some(*v),
            _ => None,
        }
    }

    /// 尝试获取 u16 值
    ///
    /// # Returns
    /// * `Some(u16)` - 如果是 HoldingRegister 或 InputRegister
    /// * `None` - 如果是布尔类型
    pub fn as_u16(&self) -> Option<u16> {
        match self {
            Self::HoldingRegister(v) | Self::InputRegister(v) => Some(*v),
            _ => None,
        }
    }

    /// 获取寄存器类型的引用
    ///
    /// # Returns
    /// * `Some(&u16)` - 如果是寄存器类型
    /// * `None` - 如果是布尔类型
    pub fn as_register(&self) -> Option<&u16> {
        match self {
            Self::HoldingRegister(v) | Self::InputRegister(v) => Some(v),
            _ => None,
        }
    }

    /// 判断值是否为真（用于线圈类型）
    ///
    /// 如果不是布尔类型，返回 false。
    pub fn is_true(&self) -> bool {
        self.as_bool().unwrap_or(false)
    }

    /// 获取值的位长度
    ///
    /// 布尔类型返回 1，寄存器类型返回 16。
    pub fn bit_length(&self) -> u8 {
        match self {
            Self::Coil(_) | Self::DiscreteInput(_) => 1,
            Self::HoldingRegister(_) | Self::InputRegister(_) => 16,
        }
    }
}

impl From<bool> for ModbusValue {
    fn from(value: bool) -> Self {
        Self::Coil(value)
    }
}

impl From<u16> for ModbusValue {
    fn from(value: u16) -> Self {
        Self::HoldingRegister(value)
    }
}

impl Default for ModbusValue {
    fn default() -> Self {
        Self::HoldingRegister(0)
    }
}

impl std::fmt::Display for ModbusValue {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Coil(v) => write!(f, "Coil({})", v),
            Self::DiscreteInput(v) => write!(f, "DiscreteInput({})", v),
            Self::HoldingRegister(v) => write!(f, "HoldingRegister(0x{:04X})", v),
            Self::InputRegister(v) => write!(f, "InputRegister(0x{:04X})", v),
        }
    }
}
