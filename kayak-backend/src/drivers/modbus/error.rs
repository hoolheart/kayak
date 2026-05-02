use serde::{Deserialize, Serialize};
use std::time::Duration;

use crate::drivers::error::DriverError;

/// Modbus 异常码 (Exception Codes)
///
/// 对应 Modbus 协议定义的异常响应：
/// - 01: 非法功能 (Illegal Function)
/// - 02: 非法数据地址 (Illegal Data Address)
/// - 03: 非法数据值 (Illegal Data Value)
/// - 04: 从站设备故障 (Server Device Failure)
/// - 05: 确认 (Acknowledge)
/// - 06: 服务器忙 (Server Busy)
/// - 08: 内存奇偶校验错误 (Memory Parity Error)
///
/// 注意：0x07 和 0x08 是诊断功能码，不是异常码。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[repr(u8)]
pub enum ModbusException {
    /// 非法功能 - 服务器不理解请求的功能码
    IllegalFunction = 0x01,
    /// 非法数据地址 - 请求的地址超出范围
    IllegalDataAddress = 0x02,
    /// 非法数据值 - 请求的数据值无效
    IllegalDataValue = 0x03,
    /// 从站设备故障 - 服务器执行失败
    ServerDeviceFailure = 0x04,
    /// 确认 - 服务器接受请求但需要更长时间处理
    Acknowledge = 0x05,
    /// 服务器忙 - 服务器忙于处理长时间请求
    ServerBusy = 0x06,
    /// 内存奇偶校验错误 - 内存奇偶校验失败
    MemoryParityError = 0x08,
    /// 网关路径不可用 (扩展)
    GatewayPathUnavailable = 0x0A,
    /// 网关目标设备响应失败 (扩展)
    GatewayTargetDeviceFailedToRespond = 0x0B,
    /// 未知异常码
    Unknown(u8),
}

impl ModbusException {
    /// 从 u8 值创建 ModbusException
    pub fn from_u8(value: u8) -> Self {
        match value {
            0x01 => Self::IllegalFunction,
            0x02 => Self::IllegalDataAddress,
            0x03 => Self::IllegalDataValue,
            0x04 => Self::ServerDeviceFailure,
            0x05 => Self::Acknowledge,
            0x06 => Self::ServerBusy,
            0x08 => Self::MemoryParityError,
            0x0A => Self::GatewayPathUnavailable,
            0x0B => Self::GatewayTargetDeviceFailedToRespond,
            other => Self::Unknown(other),
        }
    }

    /// 获取异常码的 u8 值
    pub fn code(&self) -> u8 {
        match self {
            Self::IllegalFunction => 0x01,
            Self::IllegalDataAddress => 0x02,
            Self::IllegalDataValue => 0x03,
            Self::ServerDeviceFailure => 0x04,
            Self::Acknowledge => 0x05,
            Self::ServerBusy => 0x06,
            Self::MemoryParityError => 0x08,
            Self::GatewayPathUnavailable => 0x0A,
            Self::GatewayTargetDeviceFailedToRespond => 0x0B,
            Self::Unknown(code) => *code,
        }
    }

    /// 判断是否为已知异常码
    pub fn is_known(&self) -> bool {
        !matches!(self, Self::Unknown(_))
    }
}

impl std::fmt::Display for ModbusException {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let name = match self {
            Self::IllegalFunction => "IllegalFunction",
            Self::IllegalDataAddress => "IllegalDataAddress",
            Self::IllegalDataValue => "IllegalDataValue",
            Self::ServerDeviceFailure => "ServerDeviceFailure",
            Self::Acknowledge => "Acknowledge",
            Self::ServerBusy => "ServerBusy",
            Self::MemoryParityError => "MemoryParityError",
            Self::GatewayPathUnavailable => "GatewayPathUnavailable",
            Self::GatewayTargetDeviceFailedToRespond => "GatewayTargetDeviceFailedToRespond",
            Self::Unknown(code) => return write!(f, "Unknown(0x{:02X})", code),
        };
        write!(f, "{}", name)
    }
}

/// Modbus 错误类型
///
/// 涵盖 Modbus 协议层和通信层的所有错误：
/// - ModbusException: Modbus 协议定义的异常响应
/// - Protocol: 协议解析错误
/// - Communication: 通信错误（超时、连接等）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ModbusError {
    // ========== Modbus 异常响应 ==========
    /// 非法功能
    IllegalFunction,
    /// 非法数据地址
    IllegalDataAddress,
    /// 非法数据值
    IllegalDataValue,
    /// 从站设备故障
    ServerDeviceFailure,
    /// 确认
    Acknowledge,
    /// 服务器忙
    ServerBusy,
    /// 内存奇偶校验错误
    MemoryParityError,

    // ========== 协议错误 ==========
    /// 无效的功能码
    InvalidFunctionCode(u8),
    /// 无效的地址
    InvalidAddress(u16),
    /// 无效的值
    InvalidValue(String),
    /// 无效的 PDU 数据长度
    InvalidPduLength { expected: usize, actual: usize },
    /// MBAP 解析错误
    MbapError(String),
    /// PDU 解析错误
    PduError(String),
    /// 帧不完整
    IncompleteFrame,
    /// 帧校验失败
    FrameChecksumMismatch { expected: u16, actual: u16 },

    // ========== 通信错误 ==========
    /// 连接失败
    ConnectionFailed(String),
    /// 连接超时
    Timeout { duration: Duration },
    /// 连接被拒绝
    ConnectionRefused,
    /// 设备未连接
    NotConnected,
    /// 远程主机关闭连接
    RemoteHostClosedConnection,
    /// IO 错误
    IoError(String),

    // ========== 其他 ==========
    /// 未知错误
    Unknown(String),
}

impl ModbusError {
    // ========== 工厂方法 ==========

    /// 创建超时错误
    pub fn timeout(duration: Duration) -> Self {
        Self::Timeout { duration }
    }

    /// 创建 IO 错误
    pub fn io_error(message: impl Into<String>) -> Self {
        Self::IoError(message.into())
    }

    /// 创建协议错误
    pub fn protocol_error(message: impl Into<String>) -> Self {
        Self::MbapError(message.into())
    }

    // ========== 查询方法 ==========

    /// 判断是否为通信超时错误
    pub fn is_timeout(&self) -> bool {
        matches!(self, Self::Timeout { .. })
    }

    /// 判断是否为连接错误
    pub fn is_connection_error(&self) -> bool {
        matches!(
            self,
            Self::ConnectionFailed(_)
                | Self::ConnectionRefused
                | Self::NotConnected
                | Self::RemoteHostClosedConnection
        )
    }

    /// 判断是否为协议错误
    pub fn is_protocol_error(&self) -> bool {
        matches!(
            self,
            Self::InvalidFunctionCode(_)
                | Self::InvalidAddress(_)
                | Self::InvalidValue(_)
                | Self::InvalidPduLength { .. }
                | Self::MbapError(_)
                | Self::PduError(_)
                | Self::IncompleteFrame
                | Self::FrameChecksumMismatch { .. }
        )
    }

    /// 获取错误码（用于日志和调试）
    pub fn error_code(&self) -> &'static str {
        match self {
            Self::IllegalFunction => "EX_ILLEGAL_FUNCTION",
            Self::IllegalDataAddress => "EX_ILLEGAL_DATA_ADDRESS",
            Self::IllegalDataValue => "EX_ILLEGAL_DATA_VALUE",
            Self::ServerDeviceFailure => "EX_SERVER_DEVICE_FAILURE",
            Self::Acknowledge => "EX_ACKNOWLEDGE",
            Self::ServerBusy => "EX_SERVER_BUSY",
            Self::MemoryParityError => "EX_MEMORY_PARITY_ERROR",
            Self::InvalidFunctionCode(_) => "ERR_INVALID_FUNCTION_CODE",
            Self::InvalidAddress(_) => "ERR_INVALID_ADDRESS",
            Self::InvalidValue(_) => "ERR_INVALID_VALUE",
            Self::InvalidPduLength { .. } => "ERR_INVALID_PDU_LENGTH",
            Self::MbapError(_) => "ERR_MBAP",
            Self::PduError(_) => "ERR_PDU",
            Self::IncompleteFrame => "ERR_INCOMPLETE_FRAME",
            Self::FrameChecksumMismatch { .. } => "ERR_CHECKSUM_MISMATCH",
            Self::ConnectionFailed(_) => "ERR_CONNECTION_FAILED",
            Self::Timeout { .. } => "ERR_TIMEOUT",
            Self::ConnectionRefused => "ERR_CONNECTION_REFUSED",
            Self::NotConnected => "ERR_NOT_CONNECTED",
            Self::RemoteHostClosedConnection => "ERR_REMOTE_CLOSED",
            Self::IoError(_) => "ERR_IO",
            Self::Unknown(_) => "ERR_UNKNOWN",
        }
    }
}

impl std::fmt::Display for ModbusError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::IllegalFunction => write!(f, "Illegal function"),
            Self::IllegalDataAddress => write!(f, "Illegal data address"),
            Self::IllegalDataValue => write!(f, "Illegal data value"),
            Self::ServerDeviceFailure => write!(f, "Server device failure"),
            Self::Acknowledge => write!(f, "Acknowledge"),
            Self::ServerBusy => write!(f, "Server busy"),
            Self::MemoryParityError => write!(f, "Memory parity error"),
            Self::InvalidFunctionCode(code) => write!(f, "Invalid function code: 0x{:02X}", code),
            Self::InvalidAddress(addr) => write!(f, "Invalid address: 0x{:04X}", addr),
            Self::InvalidValue(msg) => write!(f, "Invalid value: {}", msg),
            Self::InvalidPduLength { expected, actual } => {
                write!(
                    f,
                    "Invalid PDU length: expected {}, got {}",
                    expected, actual
                )
            }
            Self::MbapError(msg) => write!(f, "MBAP error: {}", msg),
            Self::PduError(msg) => write!(f, "PDU error: {}", msg),
            Self::IncompleteFrame => write!(f, "Incomplete frame"),
            Self::FrameChecksumMismatch { expected, actual } => {
                write!(
                    f,
                    "Checksum mismatch: expected 0x{:04X}, got 0x{:04X}",
                    expected, actual
                )
            }
            Self::ConnectionFailed(msg) => write!(f, "Connection failed: {}", msg),
            Self::Timeout { duration } => write!(f, "Timeout after {:?}", duration),
            Self::ConnectionRefused => write!(f, "Connection refused"),
            Self::NotConnected => write!(f, "Not connected"),
            Self::RemoteHostClosedConnection => write!(f, "Remote host closed connection"),
            Self::IoError(msg) => write!(f, "IO error: {}", msg),
            Self::Unknown(msg) => write!(f, "Unknown error: {}", msg),
        }
    }
}

impl std::error::Error for ModbusError {}

// ========== From 实现 ==========

impl From<std::io::Error> for ModbusError {
    fn from(err: std::io::Error) -> Self {
        match err.kind() {
            std::io::ErrorKind::TimedOut => Self::Timeout {
                duration: Duration::from_secs(0), // 未知时长
            },
            std::io::ErrorKind::ConnectionRefused => Self::ConnectionRefused,
            std::io::ErrorKind::NotConnected => Self::NotConnected,
            std::io::ErrorKind::UnexpectedEof => Self::RemoteHostClosedConnection,
            _ => Self::IoError(err.to_string()),
        }
    }
}

impl From<ModbusException> for ModbusError {
    fn from(exc: ModbusException) -> Self {
        match exc {
            ModbusException::IllegalFunction => Self::IllegalFunction,
            ModbusException::IllegalDataAddress => Self::IllegalDataAddress,
            ModbusException::IllegalDataValue => Self::IllegalDataValue,
            ModbusException::ServerDeviceFailure => Self::ServerDeviceFailure,
            ModbusException::Acknowledge => Self::Acknowledge,
            ModbusException::ServerBusy => Self::ServerBusy,
            ModbusException::MemoryParityError => Self::MemoryParityError,
            ModbusException::GatewayPathUnavailable => {
                Self::Unknown("Gateway path unavailable".into())
            }
            ModbusException::GatewayTargetDeviceFailedToRespond => {
                Self::Unknown("Gateway target device failed to respond".into())
            }
            ModbusException::Unknown(code) => {
                Self::Unknown(format!("Unknown exception code: 0x{:02X}", code))
            }
        }
    }
}

// ========== Into<DriverError> 实现 ==========

impl From<ModbusError> for DriverError {
    fn from(err: ModbusError) -> Self {
        match err {
            // Modbus 异常映射到 InvalidValue
            ModbusError::IllegalFunction => DriverError::InvalidValue {
                message: "Illegal function".into(),
            },
            ModbusError::IllegalDataAddress => DriverError::InvalidValue {
                message: "Illegal data address".into(),
            },
            ModbusError::IllegalDataValue => DriverError::InvalidValue {
                message: "Illegal data value".into(),
            },
            ModbusError::ServerDeviceFailure => DriverError::InvalidValue {
                message: "Server device failure".into(),
            },
            ModbusError::Acknowledge => DriverError::InvalidValue {
                message: "Acknowledge".into(),
            },
            ModbusError::ServerBusy => DriverError::InvalidValue {
                message: "Server busy".into(),
            },
            ModbusError::MemoryParityError => DriverError::InvalidValue {
                message: "Memory parity error".into(),
            },
            // 通信错误直接映射
            ModbusError::Timeout { duration } => DriverError::Timeout { duration },
            ModbusError::NotConnected => DriverError::NotConnected,
            ModbusError::ConnectionFailed(msg) => DriverError::IoError(msg),
            ModbusError::ConnectionRefused => DriverError::IoError("Connection refused".into()),
            ModbusError::RemoteHostClosedConnection => {
                DriverError::IoError("Remote host closed connection".into())
            }
            // 其他错误映射为 InvalidValue 或 IoError
            ModbusError::InvalidFunctionCode(code) => DriverError::InvalidValue {
                message: format!("Invalid function code: 0x{:02X}", code),
            },
            ModbusError::InvalidAddress(addr) => DriverError::InvalidValue {
                message: format!("Invalid address: 0x{:04X}", addr),
            },
            ModbusError::InvalidValue(msg) => DriverError::InvalidValue { message: msg },
            other => DriverError::IoError(other.to_string()),
        }
    }
}

/// Parse error for MBAP/PDU parsing failures
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParseError {
    /// 错误描述
    pub message: String,
    /// 解析失败的字节偏移量（如果有）
    pub offset: Option<usize>,
}

impl ParseError {
    /// 创建新的解析错误
    pub fn new(message: impl Into<String>) -> Self {
        Self {
            message: message.into(),
            offset: None,
        }
    }

    /// 创建带偏移量的解析错误
    pub fn with_offset(message: impl Into<String>, offset: usize) -> Self {
        Self {
            message: message.into(),
            offset: Some(offset),
        }
    }
}

impl std::fmt::Display for ParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.offset {
            Some(offset) => write!(f, "Parse error at offset {}: {}", offset, self.message),
            None => write!(f, "Parse error: {}", self.message),
        }
    }
}

impl std::error::Error for ParseError {}

impl From<ParseError> for ModbusError {
    fn from(err: ParseError) -> Self {
        ModbusError::MbapError(err.message)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    // ========== ModbusException Tests ==========

    #[test]
    fn test_modbus_exception_from_u8() {
        // TC-027: ModbusError From u8 构造
        assert_eq!(
            ModbusException::from_u8(0x01),
            ModbusException::IllegalFunction
        );
        assert_eq!(
            ModbusException::from_u8(0x02),
            ModbusException::IllegalDataAddress
        );
        assert_eq!(
            ModbusException::from_u8(0x03),
            ModbusException::IllegalDataValue
        );
        assert_eq!(
            ModbusException::from_u8(0x04),
            ModbusException::ServerDeviceFailure
        );
        assert_eq!(ModbusException::from_u8(0x05), ModbusException::Acknowledge);
        assert_eq!(ModbusException::from_u8(0x06), ModbusException::ServerBusy);
        assert_eq!(
            ModbusException::from_u8(0x08),
            ModbusException::MemoryParityError
        );
    }

    #[test]
    fn test_modbus_exception_unknown() {
        // TC-028: ModbusError Invalid 异常码
        assert_eq!(
            ModbusException::from_u8(0x00),
            ModbusException::Unknown(0x00)
        );
        assert_eq!(
            ModbusException::from_u8(0x09),
            ModbusException::Unknown(0x09)
        );
        assert_eq!(
            ModbusException::from_u8(0xFF),
            ModbusException::Unknown(0xFF)
        );
    }

    #[test]
    fn test_modbus_exception_code() {
        // TC-020-025: ModbusException 异常码映射
        assert_eq!(ModbusException::IllegalFunction.code(), 0x01);
        assert_eq!(ModbusException::IllegalDataAddress.code(), 0x02);
        assert_eq!(ModbusException::IllegalDataValue.code(), 0x03);
        assert_eq!(ModbusException::ServerDeviceFailure.code(), 0x04);
        assert_eq!(ModbusException::Acknowledge.code(), 0x05);
        assert_eq!(ModbusException::ServerBusy.code(), 0x06);
        assert_eq!(ModbusException::MemoryParityError.code(), 0x08);
    }

    #[test]
    fn test_modbus_exception_is_known() {
        // ModbusException 已知异常码判断
        assert!(ModbusException::IllegalFunction.is_known());
        assert!(!ModbusException::Unknown(0x00).is_known());
    }

    // ========== ModbusError Tests ==========

    #[test]
    fn test_modbus_error_illegal_function() {
        // TC-020: ModbusError 异常码映射 - IllegalFunction
        let error = ModbusError::IllegalFunction;
        assert_eq!(error.error_code(), "EX_ILLEGAL_FUNCTION");
    }

    #[test]
    fn test_modbus_error_illegal_data_address() {
        // TC-021: ModbusError 异常码映射 - IllegalDataAddress
        let error = ModbusError::IllegalDataAddress;
        assert_eq!(error.error_code(), "EX_ILLEGAL_DATA_ADDRESS");
    }

    #[test]
    fn test_modbus_error_illegal_data_value() {
        // TC-022: ModbusError 异常码映射 - IllegalDataValue
        let error = ModbusError::IllegalDataValue;
        assert_eq!(error.error_code(), "EX_ILLEGAL_DATA_VALUE");
    }

    #[test]
    fn test_modbus_error_server_device_failure() {
        // TC-023: ModbusError 异常码映射 - ServerDeviceFailure
        let error = ModbusError::ServerDeviceFailure;
        assert_eq!(error.error_code(), "EX_SERVER_DEVICE_FAILURE");
    }

    #[test]
    fn test_modbus_error_acknowledge() {
        // TC-024: ModbusError Acknowledge 异常码
        let error = ModbusError::Acknowledge;
        assert_eq!(error.error_code(), "EX_ACKNOWLEDGE");
    }

    #[test]
    fn test_modbus_error_server_busy() {
        // TC-025: ModbusError ServerBusy 异常码
        let error = ModbusError::ServerBusy;
        assert_eq!(error.error_code(), "EX_SERVER_BUSY");
    }

    #[test]
    fn test_modbus_error_timeout() {
        // TC-026a: ModbusError Timeout 通信错误
        let timeout = ModbusError::Timeout {
            duration: Duration::from_secs(5),
        };
        assert!(timeout.is_timeout());
        assert_eq!(timeout.error_code(), "ERR_TIMEOUT");
    }

    #[test]
    fn test_modbus_error_is_connection_error() {
        // ModbusError 连接错误判断
        assert!(ModbusError::ConnectionFailed("test".into()).is_connection_error());
        assert!(ModbusError::ConnectionRefused.is_connection_error());
        assert!(ModbusError::NotConnected.is_connection_error());
        assert!(ModbusError::RemoteHostClosedConnection.is_connection_error());
        assert!(!ModbusError::Timeout {
            duration: Duration::ZERO
        }
        .is_connection_error());
    }

    #[test]
    fn test_modbus_error_is_protocol_error() {
        // ModbusError 协议错误判断
        assert!(ModbusError::InvalidFunctionCode(0xFF).is_protocol_error());
        assert!(ModbusError::InvalidAddress(0).is_protocol_error());
        assert!(ModbusError::IncompleteFrame.is_protocol_error());
        assert!(!ModbusError::Timeout {
            duration: Duration::ZERO
        }
        .is_protocol_error());
    }

    // ========== ModbusError to DriverError Conversion ==========

    #[test]
    fn test_modbus_error_to_driver_error_illegal_function() {
        // TC-026: ModbusError 转换为 DriverError
        let driver_error: DriverError = ModbusError::IllegalFunction.into();
        assert!(matches!(driver_error, DriverError::InvalidValue { .. }));
    }

    #[test]
    fn test_modbus_error_to_driver_error_illegal_data_address() {
        // TC-026: ModbusError 转换为 DriverError
        let driver_error: DriverError = ModbusError::IllegalDataAddress.into();
        assert!(matches!(driver_error, DriverError::InvalidValue { .. }));
    }

    #[test]
    fn test_modbus_error_to_driver_error_timeout() {
        // TC-026a: ModbusError Timeout 转换为 DriverError
        let timeout = ModbusError::Timeout {
            duration: Duration::from_secs(5),
        };
        let driver_error: DriverError = timeout.into();
        assert!(
            matches!(driver_error, DriverError::Timeout { duration } if duration == Duration::from_secs(5))
        );
    }

    #[test]
    fn test_modbus_error_to_driver_error_not_connected() {
        // ModbusError NotConnected 转换为 DriverError
        let error: DriverError = ModbusError::NotConnected.into();
        assert!(matches!(error, DriverError::NotConnected));
    }

    #[test]
    fn test_modbus_error_to_driver_error_connection_failed() {
        // ModbusError ConnectionFailed 转换为 DriverError
        let error: DriverError = ModbusError::ConnectionFailed("connection refused".into()).into();
        assert!(matches!(error, DriverError::IoError(_)));
    }

    #[test]
    fn test_modbus_error_to_driver_error_invalid_function_code() {
        // ModbusError InvalidFunctionCode 转换为 DriverError
        let error: DriverError = ModbusError::InvalidFunctionCode(0xFF).into();
        assert!(matches!(error, DriverError::InvalidValue { .. }));
    }

    #[test]
    fn test_modbus_error_to_driver_error_invalid_address() {
        // ModbusError InvalidAddress 转换为 DriverError
        let error: DriverError = ModbusError::InvalidAddress(0xFFFF).into();
        assert!(matches!(error, DriverError::InvalidValue { .. }));
    }

    // ========== ModbusException to ModbusError Conversion ==========

    #[test]
    fn test_modbus_exception_to_modbus_error() {
        let exc = ModbusException::IllegalFunction;
        let error: ModbusError = exc.into();
        assert!(matches!(error, ModbusError::IllegalFunction));

        let exc = ModbusException::IllegalDataAddress;
        let error: ModbusError = exc.into();
        assert!(matches!(error, ModbusError::IllegalDataAddress));
    }

    #[test]
    fn test_modbus_exception_unknown_to_modbus_error() {
        let exc = ModbusException::Unknown(0xFF);
        let error: ModbusError = exc.into();
        assert!(matches!(error, ModbusError::Unknown(_)));
    }

    // ========== ParseError Tests ==========

    #[test]
    fn test_parse_error_new() {
        let error = ParseError::new("test error");
        assert_eq!(error.message, "test error");
        assert_eq!(error.offset, None);
    }

    #[test]
    fn test_parse_error_with_offset() {
        let error = ParseError::with_offset("test error", 10);
        assert_eq!(error.message, "test error");
        assert_eq!(error.offset, Some(10));
    }

    #[test]
    fn test_parse_error_display() {
        let error = ParseError::new("test error");
        assert_eq!(format!("{}", error), "Parse error: test error");

        let error = ParseError::with_offset("test error", 10);
        assert_eq!(format!("{}", error), "Parse error at offset 10: test error");
    }

    #[test]
    fn test_parse_error_to_modbus_error() {
        let parse_error = ParseError::new("MBAP parse failed");
        let modbus_error: ModbusError = parse_error.into();
        assert!(matches!(modbus_error, ModbusError::MbapError(_)));
    }

    // ========== ModbusError Display Tests ==========

    #[test]
    fn test_modbus_error_display() {
        assert_eq!(
            format!("{}", ModbusError::IllegalFunction),
            "Illegal function"
        );
        assert_eq!(
            format!("{}", ModbusError::IllegalDataAddress),
            "Illegal data address"
        );
        assert_eq!(
            format!(
                "{}",
                ModbusError::Timeout {
                    duration: Duration::from_secs(5)
                }
            ),
            "Timeout after 5s"
        );
    }
}
