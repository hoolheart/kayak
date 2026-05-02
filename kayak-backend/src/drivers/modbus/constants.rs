/// Modbus TCP 默认端口
pub const MODBUS_TCP_PORT: u16 = 502;

/// Modbus RTU 默认端口（用于串口网关）
pub const MODBUS_RTU_PORT: u16 = 502;

/// MBAP 头部长度
pub const MBAP_HEADER_LENGTH: usize = 7;

/// PDU 最大长度
pub const MAX_PDU_LENGTH: usize = 253;

/// MBAP + PDU 最大帧长度
pub const MAX_FRAME_LENGTH: usize = MBAP_HEADER_LENGTH + MAX_PDU_LENGTH;

/// 最小读取数量
pub const MIN_READ_QUANTITY: u16 = 1;

/// 最大读取数量（线圈/离散输入）
pub const MAX_READ_COILS: u16 = 2000;
pub const MAX_READ_DISCRETE_INPUTS: u16 = 2000;

/// 最大读取数量（寄存器）
pub const MAX_READ_HOLDING_REGISTERS: u16 = 125;
pub const MAX_READ_INPUT_REGISTERS: u16 = 125;

/// 最大写入数量
pub const MAX_WRITE_COILS: u16 = 1968;
pub const MAX_WRITE_REGISTERS: u16 = 123;

/// 线圈 ON 值（Modbus 协议规定）
pub const COIL_ON: u16 = 0xFF00;

/// 线圈 OFF 值（Modbus 协议规定）
pub const COIL_OFF: u16 = 0x0000;

/// 默认事务标识符起始值
pub const DEFAULT_TRANSACTION_ID: u16 = 0;

/// 默认从站标识符
pub const DEFAULT_UNIT_ID: u8 = 1;

/// 协议标识符（Modbus TCP 固定为 0）
pub const MODBUS_PROTOCOL_ID: u16 = 0x0000;
