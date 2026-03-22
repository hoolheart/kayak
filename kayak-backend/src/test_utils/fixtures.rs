//! 测试数据工厂 (Fixtures)
//!
//! 提供标准化的测试数据生成

use crate::models::entities::*;
use chrono::Utc;
use uuid::Uuid;

/// 用户数据工厂
pub struct UserFactory;

impl UserFactory {
    /// 创建默认用户
    pub fn default() -> User {
        User {
            id: Uuid::new_v4(),
            email: "user@example.com".to_string(),
            password_hash: "$2b$12$...".to_string(),
            username: Some("Test User".to_string()),
            avatar_url: None,
            status: "active".to_string(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    /// 创建带自定义邮箱的用户
    pub fn with_email(email: impl Into<String>) -> User {
        let mut user = Self::default();
        user.email = email.into();
        user
    }

    /// 创建创建请求
    pub fn create_request() -> CreateUserRequest {
        CreateUserRequest {
            email: "new@example.com".to_string(),
            password_hash: "hashed_password".to_string(),
            username: Some("New User".to_string()),
        }
    }
}

/// 工作台数据工厂
pub struct WorkbenchFactory;

impl WorkbenchFactory {
    /// 创建默认工作台
    pub fn default() -> Workbench {
        Workbench {
            id: Uuid::new_v4(),
            name: "Test Workbench".to_string(),
            description: Some("A test workbench".to_string()),
            owner_type: OwnerType::User,
            owner_id: Uuid::new_v4(),
            status: WorkbenchStatus::Active,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    /// 创建带名称的工作台
    pub fn with_name(name: impl Into<String>) -> Workbench {
        let mut wb = Self::default();
        wb.name = name.into();
        wb
    }

    /// 创建创建请求
    pub fn create_request(owner_id: Uuid) -> CreateWorkbenchRequest {
        CreateWorkbenchRequest {
            name: "New Workbench".to_string(),
            description: Some("Description".to_string()),
            owner_type: OwnerType::User,
            owner_id,
        }
    }
}

/// 设备数据工厂
pub struct DeviceFactory;

impl DeviceFactory {
    /// 创建默认设备
    pub fn default(workbench_id: Uuid) -> Device {
        Device {
            id: Uuid::new_v4(),
            workbench_id,
            parent_id: None,
            name: "Test Device".to_string(),
            protocol_type: ProtocolType::Virtual,
            protocol_params: None,
            manufacturer: Some("Test Manufacturer".to_string()),
            model: Some("Model X".to_string()),
            sn: Some("SN12345".to_string()),
            status: DeviceStatus::Offline,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    /// 创建子设备
    pub fn child(workbench_id: Uuid, parent_id: Uuid) -> Device {
        let mut device = Self::default(workbench_id);
        device.parent_id = Some(parent_id);
        device.name = "Child Device".to_string();
        device
    }
}

/// 测点数据工厂
pub struct PointFactory;

impl PointFactory {
    /// 创建默认测点
    pub fn default(device_id: Uuid) -> Point {
        Point {
            id: Uuid::new_v4(),
            device_id,
            name: "Test Point".to_string(),
            data_type: DataType::Number,
            access_type: AccessType::Ro,
            unit: Some("°C".to_string()),
            min_value: Some(-50.0),
            max_value: Some(150.0),
            default_value: Some("0.0".to_string()),
            status: PointStatus::Active,
            metadata: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    /// 创建温度测点
    pub fn temperature(device_id: Uuid) -> Point {
        let mut point = Self::default(device_id);
        point.name = "Temperature".to_string();
        point.unit = Some("°C".to_string());
        point
    }

    /// 创建控制测点
    pub fn control(device_id: Uuid) -> Point {
        let mut point = Self::default(device_id);
        point.name = "Control".to_string();
        point.access_type = AccessType::Rw;
        point.data_type = DataType::Boolean;
        point
    }
}
