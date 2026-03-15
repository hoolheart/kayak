//! 测点实体模型
//!
//! 定义测点表的数据结构和相关枚举

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 数据类型枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DataType {
    /// 整数
    Integer,
    /// 浮点数
    Float,
    /// 字符串
    String,
    /// 布尔值
    Boolean,
}

/// 访问类型枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AccessType {
    /// 只读
    Ro,
    /// 只写
    Wo,
    /// 读写
    Rw,
}

/// 测点状态枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum PointStatus {
    /// 正常
    #[default]
    Active,
    /// 禁用
    Disabled,
}

/// 测点实体
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Point {
    /// 测点ID (UUID)
    pub id: Uuid,
    /// 所属设备ID
    pub device_id: Uuid,
    /// 测点名称
    pub name: String,
    /// 数据类型
    pub data_type: DataType,
    /// 访问类型
    pub access_type: AccessType,
    /// 单位
    pub unit: Option<String>,
    /// 最小值
    pub min_value: Option<f64>,
    /// 最大值
    pub max_value: Option<f64>,
    /// 默认值
    pub default_value: Option<String>,
    /// 状态
    pub status: PointStatus,
    /// 元数据 (JSON格式)
    pub metadata: Option<serde_json::Value>,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 更新时间
    pub updated_at: DateTime<Utc>,
}

impl Point {
    /// 创建测点
    pub fn new(
        device_id: Uuid,
        name: String,
        data_type: DataType,
        access_type: AccessType,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            device_id,
            name,
            data_type,
            access_type,
            unit: None,
            min_value: None,
            max_value: None,
            default_value: None,
            status: PointStatus::Active,
            metadata: None,
            created_at: now,
            updated_at: now,
        }
    }
}

/// 创建测点请求DTO
#[derive(Debug, Deserialize)]
pub struct CreatePointRequest {
    pub device_id: Uuid,
    pub name: String,
    pub data_type: DataType,
    pub access_type: AccessType,
    pub unit: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
}

/// 更新测点请求DTO
#[derive(Debug, Deserialize, Default)]
pub struct UpdatePointRequest {
    pub name: Option<String>,
    pub unit: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
    pub status: Option<PointStatus>,
}

/// 测点响应DTO
#[derive(Debug, Serialize)]
pub struct PointResponse {
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
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<Point> for PointResponse {
    fn from(point: Point) -> Self {
        Self {
            id: point.id,
            device_id: point.device_id,
            name: point.name,
            data_type: point.data_type,
            access_type: point.access_type,
            unit: point.unit,
            min_value: point.min_value,
            max_value: point.max_value,
            default_value: point.default_value,
            status: point.status,
            created_at: point.created_at,
            updated_at: point.updated_at,
        }
    }
}
