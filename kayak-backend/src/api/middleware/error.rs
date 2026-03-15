//! 错误处理中间件
//!
//! 提供全局错误处理功能

use axum::{
    extract::Request,
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use tracing::{error, warn};

/// 全局错误处理中间件
///
/// 捕获所有未处理的错误，转换为统一的错误响应格式
pub async fn error_handler(req: Request, next: Next) -> Response {
    let path = req.uri().path().to_string();
    let method = req.method().to_string();

    let response = next.run(req).await;

    let status = response.status();

    // 记录错误响应
    if status.is_server_error() {
        error!(
            method = %method,
            path = %path,
            status = %status,
            "Server error response"
        );
    } else if status.is_client_error() && status != StatusCode::NOT_FOUND {
        warn!(
            method = %method,
            path = %path,
            status = %status,
            "Client error response"
        );
    }

    response
}

/// 错误响应结构
#[derive(Debug, Serialize)]
pub struct NotFoundResponse {
    pub code: u16,
    pub message: String,
    pub timestamp: String,
}

/// 404 处理
///
/// 当没有路由匹配时返回的统一响应
pub async fn not_found_handler() -> impl IntoResponse {
    let body = Json(NotFoundResponse {
        code: StatusCode::NOT_FOUND.as_u16(),
        message: "The requested resource was not found".to_string(),
        timestamp: current_timestamp(),
    });

    (StatusCode::NOT_FOUND, body)
}

/// 获取当前时间戳
fn current_timestamp() -> String {
    use time::OffsetDateTime;
    OffsetDateTime::now_utc()
        .format(&time::format_description::well_known::Rfc3339)
        .unwrap_or_else(|_| "1970-01-01T00:00:00Z".to_string())
}
