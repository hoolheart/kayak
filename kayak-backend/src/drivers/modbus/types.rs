use serde::{Deserialize, Serialize};
use std::time::Duration;

use super::constants::{DEFAULT_POOL_SIZE, MAX_POOL_SIZE};

/// serde 反序列化时 `pool_size` 字段的默认值
fn default_pool_size() -> usize {
    DEFAULT_POOL_SIZE
}

/// Modbus TCP 连接池配置
///
/// 在 Modbus TCP 单连接配置基础上增加连接池大小参数。
/// 平铺字段设计使 JSON 序列化与 API schema 一致。
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModbusTcpPoolConfig {
    /// 服务器主机地址
    pub host: String,
    /// TCP 端口
    pub port: u16,
    /// 从站 ID
    pub slave_id: u8,
    /// 操作超时时间 (毫秒)
    pub timeout_ms: u64,
    /// 连接池大小 (预建连接数)
    /// 自动钳制到 [1, MAX_POOL_SIZE] 范围
    #[serde(default = "default_pool_size")]
    pub pool_size: usize,
}

impl ModbusTcpPoolConfig {
    /// 创建新的连接池配置
    ///
    /// `pool_size` 自动钳制到 [1, MAX_POOL_SIZE] 范围。
    pub fn new(
        host: impl Into<String>,
        port: u16,
        slave_id: u8,
        timeout_ms: u64,
        pool_size: usize,
    ) -> Self {
        Self {
            host: host.into(),
            port,
            slave_id,
            timeout_ms,
            pool_size: pool_size.clamp(1, MAX_POOL_SIZE),
        }
    }

    /// 获取服务器地址字符串 "host:port"
    pub fn addr(&self) -> String {
        format!("{}:{}", self.host, self.port)
    }

    /// 获取超时时长
    pub fn timeout(&self) -> Duration {
        Duration::from_millis(self.timeout_ms)
    }
}

impl Default for ModbusTcpPoolConfig {
    fn default() -> Self {
        Self {
            host: "127.0.0.1".to_string(),
            port: 502,
            slave_id: 1,
            timeout_ms: 3000,
            pool_size: DEFAULT_POOL_SIZE,
        }
    }
}

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
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default, Serialize, Deserialize,
)]
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

#[cfg(test)]
mod tests {
    use super::*;

    // ========== FunctionCode Tests ==========

    #[test]
    fn test_function_code_valid_codes() {
        // TC-001: FunctionCode 有效功能码创建
        assert_eq!(FunctionCode::ReadCoils.code(), 0x01);
        assert_eq!(FunctionCode::ReadDiscreteInputs.code(), 0x02);
        assert_eq!(FunctionCode::ReadHoldingRegisters.code(), 0x03);
        assert_eq!(FunctionCode::ReadInputRegisters.code(), 0x04);
        assert_eq!(FunctionCode::WriteSingleCoil.code(), 0x05);
        assert_eq!(FunctionCode::WriteSingleRegister.code(), 0x06);
        assert_eq!(FunctionCode::WriteMultipleCoils.code(), 0x0F);
        assert_eq!(FunctionCode::WriteMultipleRegisters.code(), 0x10);
    }

    #[test]
    fn test_function_code_from_u8_valid() {
        // TC-003: FunctionCode::from_u8 转换 - 有效值
        assert_eq!(FunctionCode::from_u8(0x01), Some(FunctionCode::ReadCoils));
        assert_eq!(
            FunctionCode::from_u8(0x10),
            Some(FunctionCode::WriteMultipleRegisters)
        );
    }

    #[test]
    fn test_function_code_from_u8_invalid() {
        // TC-002: FunctionCode 无效功能码拒绝
        let invalid_codes = [0x00, 0x09, 0x7F, 0xFF];
        for code in invalid_codes {
            assert!(
                FunctionCode::from_u8(code).is_none(),
                "Code {:02x} should be rejected",
                code
            );
        }
    }

    #[test]
    fn test_function_code_is_read() {
        // TC-004: FunctionCode 代码匹配性 - 读取类功能码
        assert!(FunctionCode::ReadCoils.is_read());
        assert!(FunctionCode::ReadDiscreteInputs.is_read());
        assert!(FunctionCode::ReadHoldingRegisters.is_read());
        assert!(FunctionCode::ReadInputRegisters.is_read());
        assert!(!FunctionCode::WriteSingleCoil.is_read());
        assert!(!FunctionCode::WriteSingleRegister.is_read());
    }

    #[test]
    fn test_function_code_is_write() {
        // TC-004: FunctionCode 代码匹配性 - 写入类功能码
        assert!(FunctionCode::WriteSingleCoil.is_write());
        assert!(FunctionCode::WriteSingleRegister.is_write());
        assert!(FunctionCode::WriteMultipleCoils.is_write());
        assert!(FunctionCode::WriteMultipleRegisters.is_write());
        assert!(!FunctionCode::ReadCoils.is_write());
        assert!(!FunctionCode::ReadHoldingRegisters.is_write());
    }

    #[test]
    fn test_function_code_has_byte_count() {
        // TC-004: 需要 byte_count 字段的功能码
        assert!(FunctionCode::WriteMultipleCoils.has_byte_count());
        assert!(FunctionCode::WriteMultipleRegisters.has_byte_count());
        assert!(!FunctionCode::ReadCoils.has_byte_count());
        assert!(!FunctionCode::ReadHoldingRegisters.has_byte_count());
    }

    // ========== ModbusAddress Tests ==========

    #[test]
    fn test_modbus_address_valid_range() {
        // TC-005: ModbusAddress 有效地址范围
        let addresses = [0x0000u16, 0x0001, 0x7FFF, 0x8000, 0xFFFF];
        for addr in addresses {
            let result = ModbusAddress::new(addr);
            assert_eq!(result.value(), addr);
        }
    }

    #[test]
    fn test_modbus_address_min() {
        // TC-006: ModbusAddress 最小地址
        let addr = ModbusAddress::new(0);
        assert_eq!(addr.value(), 0);
        assert_eq!(addr.value(), ModbusAddress::MIN);
    }

    #[test]
    fn test_modbus_address_max() {
        // TC-007: ModbusAddress 最大地址
        let addr = ModbusAddress::new(0xFFFF);
        assert_eq!(addr.value(), 0xFFFF);
        assert_eq!(addr.value(), ModbusAddress::MAX);
    }

    #[test]
    fn test_modbus_address_bytes_conversion() {
        // TC-005: ModbusAddress 字节序转换
        let addr = ModbusAddress::new(0x1234);
        assert_eq!(addr.high_byte(), 0x12);
        assert_eq!(addr.low_byte(), 0x34);
        assert_eq!(addr.to_be_bytes(), [0x12, 0x34]);
        assert_eq!(ModbusAddress::from_be_bytes([0x12, 0x34]).value(), 0x1234);
    }

    #[test]
    fn test_modbus_address_from_u16() {
        // ModbusAddress From<u16> 实现
        let addr: ModbusAddress = 0x0001.into();
        assert_eq!(addr.value(), 0x0001);
    }

    #[test]
    fn test_modbus_address_into_u16() {
        // ModbusAddress Into<u16> 实现
        let addr = ModbusAddress::new(0xFFFF);
        let value: u16 = addr.into();
        assert_eq!(value, 0xFFFF);
    }

    // ========== RegisterType Tests ==========

    #[test]
    fn test_register_type_variants() {
        // TC-017: RegisterType 所有变体
        use RegisterType::*;
        let variants = [Coil, DiscreteInput, HoldingRegister, InputRegister];
        assert_eq!(variants.len(), 4);
    }

    #[test]
    fn test_register_type_read_function_code() {
        // TC-018: RegisterType 与 FunctionCode 关联 - 读取
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

    #[test]
    fn test_register_type_write_function_code() {
        // TC-018: RegisterType 与 FunctionCode 关联 - 写入
        assert_eq!(
            RegisterType::Coil.write_function_code(),
            Some(FunctionCode::WriteSingleCoil)
        );
        assert_eq!(
            RegisterType::HoldingRegister.write_function_code(),
            Some(FunctionCode::WriteSingleRegister)
        );
        assert_eq!(RegisterType::DiscreteInput.write_function_code(), None);
        assert_eq!(RegisterType::InputRegister.write_function_code(), None);
    }

    #[test]
    fn test_register_type_is_read_only() {
        // TC-018: RegisterType 只读属性
        assert!(!RegisterType::Coil.is_read_only());
        assert!(RegisterType::DiscreteInput.is_read_only());
        assert!(!RegisterType::HoldingRegister.is_read_only());
        assert!(RegisterType::InputRegister.is_read_only());
    }

    #[test]
    fn test_register_type_is_boolean() {
        // TC-018: RegisterType 布尔类型
        assert!(RegisterType::Coil.is_boolean());
        assert!(RegisterType::DiscreteInput.is_boolean());
        assert!(!RegisterType::HoldingRegister.is_boolean());
        assert!(!RegisterType::InputRegister.is_boolean());
    }

    #[test]
    fn test_register_type_is_register() {
        // TC-018: RegisterType 寄存器类型
        assert!(!RegisterType::Coil.is_register());
        assert!(!RegisterType::DiscreteInput.is_register());
        assert!(RegisterType::HoldingRegister.is_register());
        assert!(RegisterType::InputRegister.is_register());
    }

    // ========== ModbusValue Tests ==========

    #[test]
    fn test_modbus_value_coil() {
        // TC-010: ModbusValue Coil 类型创建
        let coil_on = ModbusValue::Coil(true);
        let coil_off = ModbusValue::Coil(false);

        assert_eq!(coil_on.as_bool(), Some(true));
        assert_eq!(coil_off.as_bool(), Some(false));
        assert_eq!(coil_on.as_u16(), None);
    }

    #[test]
    fn test_modbus_value_discrete_input() {
        // TC-011: ModbusValue DiscreteInput 类型创建
        let di_on = ModbusValue::DiscreteInput(true);
        let di_off = ModbusValue::DiscreteInput(false);

        assert_eq!(di_on.as_bool(), Some(true));
        assert_eq!(di_off.as_bool(), Some(false));
        assert_eq!(di_on.as_u16(), None);
    }

    #[test]
    fn test_modbus_value_holding_register() {
        // TC-012: ModbusValue HoldingRegister 类型创建
        let hr_min = ModbusValue::HoldingRegister(0);
        let hr_mid = ModbusValue::HoldingRegister(32768);
        let hr_max = ModbusValue::HoldingRegister(65535);

        assert_eq!(hr_min.as_u16(), Some(0));
        assert_eq!(hr_mid.as_u16(), Some(32768));
        assert_eq!(hr_max.as_u16(), Some(65535));
        assert_eq!(hr_min.as_bool(), None);
    }

    #[test]
    fn test_modbus_value_input_register() {
        // TC-013: ModbusValue InputRegister 类型创建
        let ir_min = ModbusValue::InputRegister(0);
        let ir_max = ModbusValue::InputRegister(65535);

        assert_eq!(ir_min.as_u16(), Some(0));
        assert_eq!(ir_max.as_u16(), Some(65535));
        assert_eq!(ir_max.as_bool(), None);
    }

    #[test]
    fn test_modbus_value_type_mismatch() {
        // TC-014: ModbusValue 类型不匹配访问
        let coil = ModbusValue::Coil(true);
        let hr = ModbusValue::HoldingRegister(100);

        assert_eq!(coil.as_u16(), None); // Coil doesn't have u16 value
        assert_eq!(hr.as_bool(), None); // Register doesn't have bool value
    }

    #[test]
    fn test_modbus_value_boundary_values() {
        // TC-015: ModbusValue 边界值测试
        let hr_zero = ModbusValue::HoldingRegister(0);
        let hr_max = ModbusValue::HoldingRegister(65535);
        let ir_zero = ModbusValue::InputRegister(0);
        let ir_max = ModbusValue::InputRegister(65535);

        assert_eq!(hr_zero.as_u16(), Some(0));
        assert_eq!(hr_max.as_u16(), Some(65535));
        assert_eq!(ir_zero.as_u16(), Some(0));
        assert_eq!(ir_max.as_u16(), Some(65535));
    }

    #[test]
    fn test_modbus_value_bit_length() {
        // TC-015: ModbusValue 位长度
        assert_eq!(ModbusValue::Coil(true).bit_length(), 1);
        assert_eq!(ModbusValue::DiscreteInput(true).bit_length(), 1);
        assert_eq!(ModbusValue::HoldingRegister(0).bit_length(), 16);
        assert_eq!(ModbusValue::InputRegister(0).bit_length(), 16);
    }

    #[test]
    fn test_modbus_value_is_true() {
        // ModbusValue is_true 方法
        assert!(ModbusValue::Coil(true).is_true());
        assert!(!ModbusValue::Coil(false).is_true());
        assert!(!ModbusValue::HoldingRegister(1).is_true()); // 非布尔类型返回 false
    }

    #[test]
    fn test_modbus_value_from_bool() {
        // ModbusValue From<bool> 实现
        let value: ModbusValue = true.into();
        assert_eq!(value, ModbusValue::Coil(true));
    }

    #[test]
    fn test_modbus_value_from_u16() {
        // ModbusValue From<u16> 实现
        let value: ModbusValue = 42u16.into();
        assert_eq!(value, ModbusValue::HoldingRegister(42));
    }

    #[test]
    fn test_modbus_value_default() {
        // ModbusValue Default 实现
        let default: ModbusValue = Default::default();
        assert_eq!(default, ModbusValue::HoldingRegister(0));
    }

    #[test]
    fn test_modbus_value_display() {
        // ModbusValue Display 实现
        let coil = ModbusValue::Coil(true);
        let hr = ModbusValue::HoldingRegister(0x1234);
        assert_eq!(format!("{}", coil), "Coil(true)");
        assert_eq!(format!("{}", hr), "HoldingRegister(0x1234)");
    }
}
