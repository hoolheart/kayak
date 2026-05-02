//! Modbus 核心数据类型与错误定义
//!
//! 提供 Modbus TCP/RTU 协议的核心数据类型、错误处理和帧解析支持。

pub mod constants;
pub mod error;
pub mod mbap;
pub mod pdu;
pub mod rtu;
pub mod tcp;
pub mod types;

pub use constants::*;
pub use error::{ModbusError, ModbusException, ParseError};
pub use mbap::MbapHeader;
pub use pdu::Pdu;
pub use rtu::{ModbusRtuConfig, ModbusRtuDriver, Parity, PointConfig as RtuPointConfig};
pub use tcp::{ModbusTcpConfig, ModbusTcpDriver, PointConfig as TcpPointConfig};
pub use types::{FunctionCode, ModbusAddress, ModbusValue, RegisterType};
