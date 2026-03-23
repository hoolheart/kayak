//! 设备服务数据类型

use crate::models::entities::device::{DeviceStatus, ProtocolType};
use serde::Serialize;
use uuid::Uuid;

/// 设备DTO
#[derive(Debug, Clone, Serialize)]
pub struct DeviceDto {
    pub id: Uuid,
    pub workbench_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub name: String,
    pub protocol_type: ProtocolType,
    pub protocol_params: Option<serde_json::Value>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub sn: Option<String>,
    pub status: DeviceStatus,
    pub created_at: String,
    pub updated_at: String,
}

/// 分页设备DTO
#[derive(Debug, Clone, Serialize)]
pub struct PagedDeviceDto {
    pub total: i64,
    pub page: i64,
    pub size: i64,
    pub items: Vec<DeviceDto>,
}
