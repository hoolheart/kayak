//! 健康检查处理器
//!
//! 提供服务健康状态检查接口

use axum::{response::IntoResponse, Json};
use serde::Serialize;

/// 健康检查响应结构
#[derive(Debug, Serialize)]
pub struct HealthResponse {
    /// 服务状态
    pub status: &'static str,
    /// 服务版本
    pub version: &'static str,
    /// 时间戳（ISO 8601格式）
    pub timestamp: String,
}

/// 健康检查处理器
///
/// GET /health
///
/// 返回服务运行状态，用于：
/// - 负载均衡健康检查
/// - 监控探针
/// - 启动完成确认
pub async fn health_check() -> impl IntoResponse {
    let response = HealthResponse {
        status: "healthy",
        version: env!("CARGO_PKG_VERSION"),
        timestamp: format_timestamp(),
    };

    Json(response)
}

/// 格式化当前时间戳为ISO 8601格式
fn format_timestamp() -> String {
    use time::OffsetDateTime;
    OffsetDateTime::now_utc()
        .format(&time::format_description::well_known::Rfc3339)
        .unwrap_or_else(|_| "1970-01-01T00:00:00Z".to_string())
}
