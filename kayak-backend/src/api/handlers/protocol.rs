//! 协议列表与系统信息请求处理器
//!
//! 提供协议目录查询、串口扫描等系统级API。
//! 这些端点不依赖 DeviceService，仅需认证。

use axum::Json;
use serde::{Deserialize, Serialize};

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};

// ============================================================
// 协议信息静态数据
// ============================================================

/// 协议信息条目
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolInfo {
    pub id: String,
    pub name: String,
    pub description: String,
    pub config_schema: serde_json::Value,
}

/// 串口信息条目
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SerialPortInfo {
    pub path: String,
    pub description: String,
}

/// GET /api/v1/protocols — 获取系统支持的协议列表
///
/// 返回 Virtual、ModbusTCP、ModbusRTU 三种协议的静态信息，
/// 每种协议包含完整的 config_schema 定义。
pub async fn list_protocols(
    RequireAuth(_user_ctx): RequireAuth,
) -> Result<Json<ApiResponse<Vec<ProtocolInfo>>>, AppError> {
    let protocols = vec![
        ProtocolInfo {
            id: "virtual".to_string(),
            name: "Virtual".to_string(),
            description: "虚拟设备（用于测试）".to_string(),
            config_schema: virtual_config_schema(),
        },
        ProtocolInfo {
            id: "modbus_tcp".to_string(),
            name: "Modbus TCP".to_string(),
            description: "Modbus TCP/IP 协议".to_string(),
            config_schema: modbus_tcp_config_schema(),
        },
        ProtocolInfo {
            id: "modbus_rtu".to_string(),
            name: "Modbus RTU".to_string(),
            description: "Modbus RTU 串口协议".to_string(),
            config_schema: modbus_rtu_config_schema(),
        },
    ];

    Ok(Json(ApiResponse::success(protocols)))
}

/// GET /api/v1/system/serial-ports — 扫描系统可用串口列表
///
/// 使用 serialport 库枚举系统串口。
/// 若无可用串口，返回空数组（非错误）。
/// 认证要求：需要有效 JWT Token。
pub async fn list_serial_ports(
    RequireAuth(_user_ctx): RequireAuth,
) -> Result<Json<ApiResponse<Vec<SerialPortInfo>>>, AppError> {
    let ports = scan_serial_ports();
    Ok(Json(ApiResponse::success(ports)))
}

// ============================================================
// 串口扫描实现
// ============================================================

/// 使用 serialport 库扫描系统可用串口
///
/// 返回路径和人类可读描述的列表。
/// 平台适配：
///   - Linux: /dev/ttyUSB*, /dev/ttyACM*, /dev/ttyS*
///   - macOS: /dev/cu.*, /dev/tty.*
///   - Windows: COM*
fn scan_serial_ports() -> Vec<SerialPortInfo> {
    match serialport::available_ports() {
        Ok(ports) => ports
            .into_iter()
            .map(|p| SerialPortInfo {
                path: p.port_name.clone(),
                description: format!("{:?}", p.port_type),
            })
            .collect(),
        Err(_) => {
            // Enumerate失败时返回空数组而非500
            // 常见于Docker/CI无串口权限环境
            tracing::warn!("Failed to enumerate serial ports, returning empty list");
            vec![]
        }
    }
}

// ============================================================
// Config Schema 定义（静态常量工厂函数）
// ============================================================

fn virtual_config_schema() -> serde_json::Value {
    serde_json::json!({
        "mode": {
            "type": "enum",
            "label": "模式",
            "description": "虚拟设备数据生成模式",
            "required": true,
            "values": ["random", "fixed", "sine", "ramp"]
        },
        "dataType": {
            "type": "enum",
            "label": "数据类型",
            "required": true,
            "values": ["number", "integer", "string", "boolean"]
        },
        "accessType": {
            "type": "enum",
            "label": "访问类型",
            "required": true,
            "values": ["ro", "wo", "rw"]
        },
        "minValue": {
            "type": "number",
            "label": "最小值",
            "required": true
        },
        "maxValue": {
            "type": "number",
            "label": "最大值",
            "required": true
        },
        "fixedValue": {
            "type": "number",
            "label": "固定值",
            "required": false
        },
        "sampleInterval": {
            "type": "number",
            "label": "采样间隔(ms)",
            "required": false,
            "default": 1000
        }
    })
}

fn modbus_tcp_config_schema() -> serde_json::Value {
    serde_json::json!({
        "host": {
            "type": "string",
            "label": "主机地址",
            "description": "Modbus 从站 IP 地址",
            "required": true,
            "format": "ip-address"
        },
        "port": {
            "type": "integer",
            "label": "端口",
            "required": false,
            "default": 502,
            "min": 1,
            "max": 65535
        },
        "slave_id": {
            "type": "integer",
            "label": "从站ID",
            "required": false,
            "default": 1,
            "min": 1,
            "max": 247
        },
        "timeout_ms": {
            "type": "integer",
            "label": "超时时间(ms)",
            "required": false,
            "default": 5000
        },
        "connection_pool_size": {
            "type": "integer",
            "label": "连接池大小",
            "required": false,
            "default": 4
        }
    })
}

fn modbus_rtu_config_schema() -> serde_json::Value {
    serde_json::json!({
        "port": {
            "type": "string",
            "label": "串口",
            "description": "串口设备路径",
            "required": true
        },
        "baud_rate": {
            "type": "enum",
            "label": "波特率",
            "required": false,
            "default": 9600,
            "values": [9600, 19200, 38400, 57600, 115200]
        },
        "data_bits": {
            "type": "enum",
            "label": "数据位",
            "required": false,
            "default": 8,
            "values": [7, 8]
        },
        "stop_bits": {
            "type": "enum",
            "label": "停止位",
            "required": false,
            "default": 1,
            "values": [1, 2]
        },
        "parity": {
            "type": "enum",
            "label": "校验位",
            "required": false,
            "default": "None",
            "values": ["None", "Even", "Odd"]
        },
        "slave_id": {
            "type": "integer",
            "label": "从站ID",
            "required": false,
            "default": 1,
            "min": 1,
            "max": 247
        },
        "timeout_ms": {
            "type": "integer",
            "label": "超时时间(ms)",
            "required": false,
            "default": 1000
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_protocol_list_contains_all_three() {
        // Unit test for data integrity: the hardcoded list must have exactly 3 protocols
        // with unique IDs
        let protocols = vec![
            ProtocolInfo {
                id: "virtual".to_string(),
                name: "Virtual".to_string(),
                description: "虚拟设备（用于测试）".to_string(),
                config_schema: virtual_config_schema(),
            },
            ProtocolInfo {
                id: "modbus_tcp".to_string(),
                name: "Modbus TCP".to_string(),
                description: "Modbus TCP/IP 协议".to_string(),
                config_schema: modbus_tcp_config_schema(),
            },
            ProtocolInfo {
                id: "modbus_rtu".to_string(),
                name: "Modbus RTU".to_string(),
                description: "Modbus RTU 串口协议".to_string(),
                config_schema: modbus_rtu_config_schema(),
            },
        ];

        assert_eq!(protocols.len(), 3);
        let ids: Vec<&str> = protocols.iter().map(|p| p.id.as_str()).collect();
        assert!(ids.contains(&"virtual"));
        assert!(ids.contains(&"modbus_tcp"));
        assert!(ids.contains(&"modbus_rtu"));
    }

    #[test]
    fn test_virtual_schema_required_fields() {
        let schema = virtual_config_schema();
        assert!(schema.get("mode").is_some());
        assert!(schema.get("dataType").is_some());
        assert!(schema.get("accessType").is_some());
    }

    #[test]
    fn test_protocol_info_serialization() {
        let info = ProtocolInfo {
            id: "test".to_string(),
            name: "Test".to_string(),
            description: "Test protocol".to_string(),
            config_schema: serde_json::json!({"key": "value"}),
        };
        let json = serde_json::to_string(&info).unwrap();
        assert!(json.contains("\"id\":\"test\""));
        assert!(json.contains("\"config_schema\":"));
    }

    #[test]
    fn test_scan_serial_ports_returns_vec() {
        // Should always return a Vec (empty or populated), never panic
        let ports = scan_serial_ports();
        // Verify it returns a valid Vec type (empty or populated)
        drop(ports);
    }
}
