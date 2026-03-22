//! 设备实体模型
//!
//! 定义设备表的数据结构和相关枚举

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 协议类型枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ProtocolType {
    /// 虚拟设备
    Virtual,
    /// Modbus TCP
    ModbusTcp,
    /// Modbus RTU
    ModbusRtu,
    /// CAN总线
    Can,
    /// VISA协议
    Visa,
    /// MQTT
    Mqtt,
}

/// 设备状态枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum DeviceStatus {
    /// 离线
    #[default]
    Offline,
    /// 在线
    Online,
    /// 错误
    Error,
}

/// 设备实体
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Device {
    /// 设备ID (UUID)
    pub id: Uuid,
    /// 所属工作台ID
    pub workbench_id: Uuid,
    /// 父设备ID (支持嵌套)
    pub parent_id: Option<Uuid>,
    /// 设备名称
    pub name: String,
    /// 协议类型
    pub protocol_type: ProtocolType,
    /// 协议参数 (JSON格式)
    pub protocol_params: Option<serde_json::Value>,
    /// 制造商
    pub manufacturer: Option<String>,
    /// 型号
    pub model: Option<String>,
    /// 序列号
    pub sn: Option<String>,
    /// 状态
    pub status: DeviceStatus,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 更新时间
    pub updated_at: DateTime<Utc>,
}

impl Device {
    /// 创建设备
    pub fn new(
        workbench_id: Uuid,
        name: String,
        protocol_type: ProtocolType,
        parent_id: Option<Uuid>,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            workbench_id,
            parent_id,
            name,
            protocol_type,
            protocol_params: None,
            manufacturer: None,
            model: None,
            sn: None,
            status: DeviceStatus::Offline,
            created_at: now,
            updated_at: now,
        }
    }
}

/// 创建设备请求DTO
#[derive(Debug, Deserialize)]
pub struct CreateDeviceRequest {
    pub workbench_id: Uuid,
    pub name: String,
    pub protocol_type: ProtocolType,
    pub parent_id: Option<Uuid>,
    pub protocol_params: Option<serde_json::Value>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub sn: Option<String>,
}

/// 更新设备请求DTO
#[derive(Debug, Deserialize, Default)]
pub struct UpdateDeviceRequest {
    pub name: Option<String>,
    pub protocol_params: Option<serde_json::Value>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub sn: Option<String>,
    pub status: Option<DeviceStatus>,
}

/// 设备响应DTO
#[derive(Debug, Serialize)]
pub struct DeviceResponse {
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
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<Device> for DeviceResponse {
    fn from(device: Device) -> Self {
        Self {
            id: device.id,
            workbench_id: device.workbench_id,
            parent_id: device.parent_id,
            name: device.name,
            protocol_type: device.protocol_type,
            protocol_params: device.protocol_params,
            manufacturer: device.manufacturer,
            model: device.model,
            sn: device.sn,
            status: device.status,
            created_at: device.created_at,
            updated_at: device.updated_at,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // TC-S1-016-01: 创建设备（无父设备）测试
    #[test]
    fn test_create_device_without_parent() {
        let workbench_id = Uuid::new_v4();
        let device = Device::new(
            workbench_id,
            "Test Device".to_string(),
            ProtocolType::Virtual,
            None,
        );

        assert!(device.parent_id.is_none());
        assert_eq!(device.status, DeviceStatus::Offline);
        assert_eq!(device.name, "Test Device");
        assert_eq!(device.protocol_type, ProtocolType::Virtual);
    }

    // TC-S1-016-02: 创建设备（带父设备）测试
    #[test]
    fn test_create_device_with_parent() {
        let workbench_id = Uuid::new_v4();
        let parent_id = Uuid::new_v4();
        let device = Device::new(
            workbench_id,
            "Child Device".to_string(),
            ProtocolType::ModbusTcp,
            Some(parent_id),
        );

        assert_eq!(device.parent_id, Some(parent_id));
        assert_ne!(device.id, parent_id);
    }

    // TC-S1-016-03: 验证UUID唯一性
    #[test]
    fn test_device_uuid_uniqueness() {
        let workbench_id = Uuid::new_v4();
        let device1 = Device::new(
            workbench_id,
            "Device 1".to_string(),
            ProtocolType::Virtual,
            None,
        );
        let device2 = Device::new(
            workbench_id,
            "Device 2".to_string(),
            ProtocolType::Virtual,
            None,
        );
        assert_ne!(device1.id, device2.id);
    }

    // TC-S1-016-05: 设备树形结构（三层）测试
    #[test]
    fn test_device_tree_structure() {
        let workbench_id = Uuid::new_v4();
        let grandparent = Device::new(
            workbench_id,
            "Grandparent".to_string(),
            ProtocolType::Virtual,
            None,
        );
        let parent = Device::new(
            workbench_id,
            "Parent".to_string(),
            ProtocolType::Virtual,
            Some(grandparent.id),
        );
        let child = Device::new(
            workbench_id,
            "Child".to_string(),
            ProtocolType::Virtual,
            Some(parent.id),
        );

        assert!(grandparent.parent_id.is_none());
        assert_eq!(parent.parent_id, Some(grandparent.id));
        assert_eq!(child.parent_id, Some(parent.id));
    }

    // TC-S1-016-08: ProtocolType 枚举所有变体测试
    #[test]
    fn test_protocol_type_variants() {
        let workbench_id = Uuid::new_v4();
        for protocol in &[
            ProtocolType::Virtual,
            ProtocolType::ModbusTcp,
            ProtocolType::ModbusRtu,
            ProtocolType::Can,
            ProtocolType::Visa,
            ProtocolType::Mqtt,
        ] {
            let device = Device::new(workbench_id, format!("{:?}", protocol), *protocol, None);
            assert_eq!(device.protocol_type, *protocol);
        }
    }

    // TC-S1-016-23: Device 转 DeviceResponse 测试
    #[test]
    fn test_device_to_response() {
        let workbench_id = Uuid::new_v4();
        let device = Device::new(
            workbench_id,
            "Test Device".to_string(),
            ProtocolType::Virtual,
            None,
        );
        let response = DeviceResponse::from(device.clone());

        assert_eq!(response.id, device.id);
        assert_eq!(response.workbench_id, device.workbench_id);
        assert_eq!(response.name, device.name);
        assert_eq!(response.protocol_type, device.protocol_type);
        assert_eq!(response.status, device.status);
        assert_eq!(response.created_at, device.created_at);
        assert_eq!(response.updated_at, device.updated_at);
    }

    // TC-S1-016-27: ProtocolType JSON 序列化测试
    #[test]
    fn test_protocol_type_serialization() {
        let json = serde_json::to_string(&ProtocolType::Virtual).unwrap();
        assert_eq!(json, "\"virtual\"");
        let json = serde_json::to_string(&ProtocolType::ModbusTcp).unwrap();
        assert_eq!(json, "\"modbus_tcp\"");
    }

    // TC-S1-016-30: JSON 反序列化测试
    #[test]
    fn test_protocol_type_deserialization() {
        let protocol: ProtocolType = serde_json::from_str("\"virtual\"").unwrap();
        assert_eq!(protocol, ProtocolType::Virtual);
    }

    // DeviceStatus 反序列化测试
    #[test]
    fn test_device_status_deserialization() {
        let status1: DeviceStatus = serde_json::from_str("\"online\"").unwrap();
        assert_eq!(status1, DeviceStatus::Online);
        let status2: DeviceStatus = serde_json::from_str("\"error\"").unwrap();
        assert_eq!(status2, DeviceStatus::Error);
        let status3: DeviceStatus = serde_json::from_str("\"offline\"").unwrap();
        assert_eq!(status3, DeviceStatus::Offline);
    }

    // TC-S1-016-33: 设备可选字段（带值）测试
    #[test]
    fn test_device_optional_fields_with_values() {
        let workbench_id = Uuid::new_v4();
        let mut device = Device::new(
            workbench_id,
            "Test".to_string(),
            ProtocolType::ModbusTcp,
            None,
        );
        device.manufacturer = Some("Acme Corp".to_string());
        device.model = Some("Model-X".to_string());
        device.sn = Some("SN12345".to_string());
        device.protocol_params = Some(serde_json::json!({"host": "192.168.1.1", "port": 502}));

        assert_eq!(device.manufacturer, Some("Acme Corp".to_string()));
        assert_eq!(device.model, Some("Model-X".to_string()));
        assert_eq!(device.sn, Some("SN12345".to_string()));
        assert!(device.protocol_params.is_some());
    }
}
