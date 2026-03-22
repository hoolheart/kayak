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
    /// 数值（浮点数）
    Number,
    /// 整数
    Integer,
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

#[cfg(test)]
mod tests {
    use super::*;

    // TC-S1-016-11: 创建测点（基本字段）测试
    #[test]
    fn test_create_point_basic() {
        let device_id = Uuid::new_v4();
        let point = Point::new(
            device_id,
            "Temperature".to_string(),
            DataType::Number,
            AccessType::Ro,
        );

        assert_eq!(point.device_id, device_id);
        assert_eq!(point.name, "Temperature");
        assert_eq!(point.data_type, DataType::Number);
        assert_eq!(point.access_type, AccessType::Ro);
        assert_eq!(point.status, PointStatus::Active);
    }

    // TC-S1-016-12: 创建多个测点（验证UUID唯一性）测试
    #[test]
    fn test_point_uuid_uniqueness() {
        let device_id = Uuid::new_v4();
        let point1 = Point::new(
            device_id,
            "Point 1".to_string(),
            DataType::Number,
            AccessType::Ro,
        );
        let point2 = Point::new(
            device_id,
            "Point 2".to_string(),
            DataType::Integer,
            AccessType::Rw,
        );
        assert_ne!(point1.id, point2.id);
    }

    // TC-S1-016-13: AccessType::Ro（只读）测点测试
    #[test]
    fn test_access_type_ro() {
        let point = Point::new(
            Uuid::new_v4(),
            "Sensor Read".to_string(),
            DataType::Number,
            AccessType::Ro,
        );
        assert_eq!(point.access_type, AccessType::Ro);
    }

    // TC-S1-016-14: AccessType::Wo（只写）测点测试
    #[test]
    fn test_access_type_wo() {
        let point = Point::new(
            Uuid::new_v4(),
            "Control Write".to_string(),
            DataType::Boolean,
            AccessType::Wo,
        );
        assert_eq!(point.access_type, AccessType::Wo);
    }

    // TC-S1-016-15: AccessType::Rw（读写）测点测试
    #[test]
    fn test_access_type_rw() {
        let point = Point::new(
            Uuid::new_v4(),
            "Setting RW".to_string(),
            DataType::Integer,
            AccessType::Rw,
        );
        assert_eq!(point.access_type, AccessType::Rw);
    }

    // TC-S1-016-16: DataType::Number（浮点数）测点测试
    #[test]
    fn test_data_type_number() {
        let point = Point::new(
            Uuid::new_v4(),
            "Temperature".to_string(),
            DataType::Number,
            AccessType::Ro,
        );
        assert_eq!(point.data_type, DataType::Number);
    }

    // TC-S1-016-17: DataType::Integer（整数）测点测试
    #[test]
    fn test_data_type_integer() {
        let point = Point::new(
            Uuid::new_v4(),
            "Counter".to_string(),
            DataType::Integer,
            AccessType::Rw,
        );
        assert_eq!(point.data_type, DataType::Integer);
    }

    // TC-S1-016-18: DataType::String（字符串）测点测试
    #[test]
    fn test_data_type_string() {
        let point = Point::new(
            Uuid::new_v4(),
            "Status Text".to_string(),
            DataType::String,
            AccessType::Ro,
        );
        assert_eq!(point.data_type, DataType::String);
    }

    // TC-S1-016-19: DataType::Boolean（布尔值）测点测试
    #[test]
    fn test_data_type_boolean() {
        let point = Point::new(
            Uuid::new_v4(),
            "On/Off".to_string(),
            DataType::Boolean,
            AccessType::Wo,
        );
        assert_eq!(point.data_type, DataType::Boolean);
    }

    // TC-S1-016-21: 测点带数值范围测试
    #[test]
    fn test_point_with_value_range() {
        let mut point = Point::new(
            Uuid::new_v4(),
            "Bounded".to_string(),
            DataType::Number,
            AccessType::Rw,
        );
        point.min_value = Some(0.0);
        point.max_value = Some(100.0);
        assert_eq!(point.min_value, Some(0.0));
        assert_eq!(point.max_value, Some(100.0));
    }

    // TC-S1-016-22: 测点带单位测试
    #[test]
    fn test_point_with_unit() {
        let mut point = Point::new(
            Uuid::new_v4(),
            "Temperature".to_string(),
            DataType::Number,
            AccessType::Ro,
        );
        point.unit = Some("°C".to_string());
        assert_eq!(point.unit, Some("°C".to_string()));
    }

    // TC-S1-016-25: Point 转 PointResponse 测试
    #[test]
    fn test_point_to_response() {
        let device_id = Uuid::new_v4();
        let point = Point::new(
            device_id,
            "Temperature".to_string(),
            DataType::Number,
            AccessType::Ro,
        );
        let response = PointResponse::from(point.clone());

        assert_eq!(response.id, point.id);
        assert_eq!(response.device_id, point.device_id);
        assert_eq!(response.name, point.name);
        assert_eq!(response.data_type, point.data_type);
        assert_eq!(response.access_type, point.access_type);
        assert_eq!(response.status, point.status);
        assert_eq!(response.created_at, point.created_at);
        assert_eq!(response.updated_at, point.updated_at);
    }

    // TC-S1-016-28: DataType JSON 序列化测试
    #[test]
    fn test_data_type_serialization() {
        assert_eq!(
            serde_json::to_string(&DataType::Number).unwrap(),
            "\"number\""
        );
        assert_eq!(
            serde_json::to_string(&DataType::Integer).unwrap(),
            "\"integer\""
        );
        assert_eq!(
            serde_json::to_string(&DataType::String).unwrap(),
            "\"string\""
        );
        assert_eq!(
            serde_json::to_string(&DataType::Boolean).unwrap(),
            "\"boolean\""
        );
    }

    // TC-S1-016-29: AccessType JSON 序列化测试
    #[test]
    fn test_access_type_serialization() {
        assert_eq!(serde_json::to_string(&AccessType::Ro).unwrap(), "\"ro\"");
        assert_eq!(serde_json::to_string(&AccessType::Wo).unwrap(), "\"wo\"");
        assert_eq!(serde_json::to_string(&AccessType::Rw).unwrap(), "\"rw\"");
    }

    // TC-S1-016-30: JSON 反序列化测试
    #[test]
    fn test_json_deserialization() {
        let data_type: DataType = serde_json::from_str("\"integer\"").unwrap();
        assert_eq!(data_type, DataType::Integer);
        let access: AccessType = serde_json::from_str("\"rw\"").unwrap();
        assert_eq!(access, AccessType::Rw);
    }

    // TC-S1-016-34: PointStatus JSON 反序列化测试
    #[test]
    fn test_point_status_deserialization() {
        let status: PointStatus = serde_json::from_str("\"active\"").unwrap();
        assert_eq!(status, PointStatus::Active);
        let status: PointStatus = serde_json::from_str("\"disabled\"").unwrap();
        assert_eq!(status, PointStatus::Disabled);
    }

    // TC-S1-016-35: 测点数值范围边界（min > max）测试
    #[test]
    fn test_point_boundary_min_greater_than_max() {
        let mut point = Point::new(
            Uuid::new_v4(),
            "Test".to_string(),
            DataType::Number,
            AccessType::Rw,
        );
        point.min_value = Some(100.0);
        point.max_value = Some(0.0);
        // 验证值被设置（业务验证应在服务层进行）
        assert_eq!(point.min_value, Some(100.0));
        assert_eq!(point.max_value, Some(0.0));
    }
}
