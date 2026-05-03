//! 设备服务错误类型

use crate::models::entities::device::{DeviceStatus, ProtocolType};
use thiserror::Error;
use uuid::Uuid;

#[derive(Error, Debug)]
pub enum DeviceError {
    #[error("Device not found")]
    NotFound,

    #[error("Workbench not found")]
    WorkbenchNotFound,

    #[error("Access denied")]
    AccessDenied,

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Invalid parent: circular reference detected")]
    CircularReference,

    #[error("Connection failed: {0}")]
    ConnectionFailed(String),

    #[error("Database error: {0}")]
    DatabaseError(String),
}

/// 创建设备实体
pub struct CreateDeviceEntity {
    pub workbench_id: Uuid,
    pub name: String,
    pub protocol_type: ProtocolType,
    pub parent_id: Option<Uuid>,
    pub protocol_params: Option<serde_json::Value>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub sn: Option<String>,
}

/// 更新设备实体
pub struct UpdateDeviceEntity {
    pub name: Option<String>,
    pub protocol_params: Option<serde_json::Value>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub sn: Option<String>,
    pub status: Option<DeviceStatus>,
}
