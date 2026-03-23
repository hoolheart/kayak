//! 测点服务数据类型

use crate::drivers::PointValue;
use crate::models::entities::point::{AccessType, DataType, PointStatus};
use serde::Serialize;
use uuid::Uuid;

/// 测点DTO
#[derive(Debug, Clone, Serialize)]
pub struct PointDto {
    pub id: Uuid,
    pub device_id: Uuid,
    pub name: String,
    pub data_type: DataType,
    pub access_type: AccessType,
    pub unit: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
    pub status: PointStatus,
    pub created_at: String,
    pub updated_at: String,
}

/// 分页测点DTO
#[derive(Debug, Clone, Serialize)]
pub struct PagedPointDto {
    pub total: i64,
    pub page: i64,
    pub size: i64,
    pub items: Vec<PointDto>,
}

/// 测点值DTO
#[derive(Debug, Clone, Serialize)]
pub struct PointValueDto {
    pub point_id: Uuid,
    pub value: PointValue,
    pub timestamp: String,
}
