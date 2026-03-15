//! 错误类型定义
//!
//! 定义应用中使用的统一错误类型和响应格式

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use thiserror::Error;
use tracing::error;

/// 应用错误类型
#[derive(Debug, Error)]
pub enum AppError {
    /// 无效请求参数
    #[error("Bad request: {0}")]
    BadRequest(String),

    /// 资源未找到
    #[error("Resource not found: {0}")]
    NotFound(String),

    /// 内部服务器错误
    #[error("Internal server error: {0}")]
    InternalError(String),

    /// 验证错误
    #[error("Validation error: {0}")]
    ValidationError(String),

    /// 配置错误
    #[error("Configuration error: {0}")]
    ConfigError(String),

    /// 超时错误
    #[error("Request timeout")]
    Timeout,

    /// CORS错误
    #[error("CORS error: {0}")]
    CorsError(String),
}

/// 错误响应结构
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub code: u16,
    pub message: String,
    pub timestamp: String,
}

impl AppError {
    /// 获取对应的HTTP状态码
    pub fn status_code(&self) -> StatusCode {
        match self {
            AppError::BadRequest(_) => StatusCode::BAD_REQUEST,
            AppError::NotFound(_) => StatusCode::NOT_FOUND,
            AppError::ValidationError(_) => StatusCode::UNPROCESSABLE_ENTITY,
            AppError::ConfigError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::Timeout => StatusCode::REQUEST_TIMEOUT,
            AppError::CorsError(_) => StatusCode::FORBIDDEN,
            AppError::InternalError(_) => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    /// 转换为错误响应
    fn to_error_response(&self) -> ErrorResponse {
        ErrorResponse {
            code: self.status_code().as_u16(),
            message: self.to_string(),
            timestamp: current_timestamp(),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let status = self.status_code();
        let body = Json(self.to_error_response());

        // 记录错误日志
        if status.is_server_error() {
            error!(error = %self, "Server error occurred");
        } else {
            tracing::debug!(error = %self, "Client error occurred");
        }

        (status, body).into_response()
    }
}

/// 从其他错误类型转换
impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        AppError::InternalError(err.to_string())
    }
}

impl From<config::ConfigError> for AppError {
    fn from(err: config::ConfigError) -> Self {
        AppError::ConfigError(err.to_string())
    }
}

impl From<serde_json::Error> for AppError {
    fn from(err: serde_json::Error) -> Self {
        AppError::BadRequest(format!("JSON parse error: {err}"))
    }
}

/// 统一错误处理函数（用于 Tower 的 HandleErrorLayer）
pub async fn handle_error(err: tower::BoxError) -> impl IntoResponse {
    if err.is::<tower::timeout::error::Elapsed>() {
        AppError::Timeout
    } else {
        AppError::InternalError(err.to_string())
    }
}

/// 获取当前时间戳（ISO 8601格式）
fn current_timestamp() -> String {
    use time::OffsetDateTime;
    OffsetDateTime::now_utc()
        .format(&time::format_description::well_known::Rfc3339)
        .unwrap_or_else(|_| "1970-01-01T00:00:00Z".to_string())
}
