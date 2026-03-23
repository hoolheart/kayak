//! 测点服务错误类型

use crate::models::entities::point::{AccessType, DataType, PointStatus};
use thiserror::Error;
use uuid::Uuid;

#[derive(Error, Debug)]
pub enum PointError {
    #[error("Point not found")]
    NotFound,

    #[error("Device not found")]
    DeviceNotFound,

    #[error("Access denied")]
    AccessDenied,

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Read only point")]
    ReadOnlyPoint,

    #[error("Device not connected")]
    DeviceNotConnected,

    #[error("Database error: {0}")]
    DatabaseError(String),
}

/// 创建测点实体
pub struct CreatePointEntity {
    pub device_id: Uuid,
    pub name: String,
    pub data_type: DataType,
    pub access_type: AccessType,
    pub unit: Option<String>,
    pub description: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
}

/// 更新测点实体
pub struct UpdatePointEntity {
    pub name: Option<String>,
    pub unit: Option<String>,
    pub description: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
    pub status: Option<PointStatus>,
}
