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
