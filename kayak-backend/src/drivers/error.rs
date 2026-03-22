//! 设备驱动错误类型定义

use std::time::Duration;

/// 设备驱动错误类型
#[derive(Debug, Clone)]
pub enum DriverError {
    /// 设备未连接
    NotConnected,
    /// 设备已连接（重复连接）
    AlreadyConnected,
    /// 操作超时
    Timeout { duration: Duration },
    /// 无效的值
    InvalidValue { message: String },
    /// 尝试写入只读测点
    ReadOnlyPoint,
    /// 配置错误
    ConfigError(String),
    /// IO错误
    IoError(String),
}

impl std::fmt::Display for DriverError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DriverError::NotConnected => write!(f, "Device not connected"),
            DriverError::AlreadyConnected => write!(f, "Device already connected"),
            DriverError::Timeout { duration } => {
                write!(f, "Operation timeout after {:?}", duration)
            }
            DriverError::InvalidValue { message } => write!(f, "Invalid value: {}", message),
            DriverError::ReadOnlyPoint => write!(f, "Cannot write to read-only point"),
            DriverError::ConfigError(msg) => write!(f, "Configuration error: {}", msg),
            DriverError::IoError(msg) => write!(f, "IO error: {}", msg),
        }
    }
}

impl std::error::Error for DriverError {}

impl From<std::io::Error> for DriverError {
    fn from(err: std::io::Error) -> Self {
        DriverError::IoError(err.to_string())
    }
}

/// VirtualConfig 验证错误
#[derive(Debug, Clone)]
pub enum VirtualConfigError {
    /// 无效的范围（min >= max）
    InvalidRange { min: f64, max: f64 },
}

impl std::fmt::Display for VirtualConfigError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            VirtualConfigError::InvalidRange { min, max } => {
                write!(f, "Invalid range: min ({}) >= max ({})", min, max)
            }
        }
    }
}

impl std::error::Error for VirtualConfigError {}

impl From<VirtualConfigError> for DriverError {
    fn from(err: VirtualConfigError) -> Self {
        DriverError::ConfigError(err.to_string())
    }
}
