//! 设备驱动核心 trait 和数据类型定义

use uuid::Uuid;
use async_trait::async_trait;
use serde::{Serialize, Deserialize};

pub use super::error::{DriverError, VirtualConfigError};

/// 表示测点的值，支持多种数据类型
#[derive(Debug, Clone, PartialEq, PartialOrd, Serialize, Deserialize)]
pub enum PointValue {
    /// 浮点数
    Number(f64),
    /// 整数
    Integer(i64),
    /// 字符串
    String(String),
    /// 布尔值
    Boolean(bool),
}

impl PointValue {
    /// 获取值的类型描述
    pub fn type_name(&self) -> &'static str {
        match self {
            PointValue::Number(_) => "Number",
            PointValue::Integer(_) => "Integer",
            PointValue::String(_) => "String",
            PointValue::Boolean(_) => "Boolean",
        }
    }

    /// 转换为 f64（如果可能）
    pub fn to_f64(&self) -> Option<f64> {
        match self {
            PointValue::Number(n) => Some(*n),
            PointValue::Integer(n) => Some(*n as f64),
            PointValue::Boolean(b) => Some(if *b { 1.0 } else { 0.0 }),
            PointValue::String(_) => None,
        }
    }
}

/// 虚拟设备的数据生成模式
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub enum VirtualMode {
    /// 随机数据模式
    #[default]
    Random,
    /// 固定值模式
    Fixed,
    /// 正弦波模式
    Sine,
    /// 斜坡（线性递增）模式
    Ramp,
}

/// 支持的数据类型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub enum DataType {
    /// 浮点数（默认）
    #[default]
    Number,
    /// 整数
    Integer,
    /// 字符串
    String,
    /// 布尔值
    Boolean,
}

/// 测点访问类型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub enum AccessType {
    /// 只读
    #[default]
    RO,
    /// 只写
    WO,
    /// 读写
    RW,
}

/// 设备驱动统一接口
///
/// 所有设备驱动必须实现此trait，提供标准化的连接、读写接口。
/// 使用依赖倒置原则，使业务逻辑与具体驱动实现解耦。
#[async_trait]
pub trait DeviceDriver: Send + Sync {
    /// 驱动配置类型
    type Config: Send + Sync;
    /// 驱动错误类型
    type Error: Send + Sync + std::fmt::Debug + std::fmt::Display + From<DriverError>;

    /// 连接到设备
    async fn connect(&mut self) -> Result<(), Self::Error>;

    /// 断开设备连接
    async fn disconnect(&mut self) -> Result<(), Self::Error>;

    /// 读取测点值
    ///
    /// # Arguments
    /// * `point_id` - 测点UUID
    ///
    /// # Returns
    /// * `Ok(PointValue)` - 读取成功
    /// * `Err(DriverError::NotConnected)` - 设备未连接
    fn read_point(&self, point_id: Uuid) -> Result<PointValue, Self::Error>;

    /// 写入测点值
    ///
    /// # Arguments
    /// * `point_id` - 测点UUID
    /// * `value` - 要写入的值
    fn write_point(&self, point_id: Uuid, value: PointValue) -> Result<(), Self::Error>;

    /// 检查设备是否已连接
    fn is_connected(&self) -> bool;
}
