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

// ============================================================
// R1-S2-005: 连接测试结果
// ============================================================

/// 设备连接测试结果
#[derive(Debug, Clone, Serialize)]
pub struct TestConnectionResult {
    /// 连接是否成功
    pub connected: bool,
    /// 结果描述消息
    pub message: String,
    /// 连接延迟（毫秒），仅在 connected=true 时有意义
    pub latency_ms: i64,
}

// ============================================================
// R1-S2-011: 连接状态响应
// ============================================================

/// 设备连接状态
#[derive(Debug, Clone, Serialize)]
pub struct DeviceConnectionStatus {
    /// 状态字符串: "connected" | "disconnected" | "error"
    pub status: String,
}
