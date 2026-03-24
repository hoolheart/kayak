//! 错误类型定义
//!
//! 定义应用中使用的统一错误类型和响应格式

use axum::{
    extract::rejection::{JsonRejection, QueryRejection},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use thiserror::Error;
use tracing::error;

/// 统一API成功响应
#[derive(Debug, Serialize)]
pub struct ApiResponse<T> {
    pub code: u16,
    pub message: String,
    pub data: T,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timestamp: Option<String>,
}

impl<T: Serialize> ApiResponse<T> {
    /// 创建成功响应
    pub fn success(data: T) -> Self {
        Self {
            code: 200,
            message: "success".to_string(),
            data,
            timestamp: Some(current_timestamp()),
        }
    }

    /// 创建带自定义消息的成功响应
    pub fn success_with_message(data: T, message: impl Into<String>) -> Self {
        Self {
            code: 200,
            message: message.into(),
            data,
            timestamp: Some(current_timestamp()),
        }
    }

    /// 创建创建成功的响应 (201)
    pub fn created(data: T) -> Self {
        Self {
            code: 201,
            message: "created".to_string(),
            data,
            timestamp: Some(current_timestamp()),
        }
    }
}

/// 统一API错误响应
#[derive(Debug, Serialize)]
pub struct ApiErrorResponse {
    pub code: u16,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<Vec<FieldError>>,
    pub timestamp: String,
}

/// 字段级错误
#[derive(Debug, Clone, Serialize)]
pub struct FieldError {
    pub field: String,
    pub message: String,
}

impl FieldError {
    pub fn new(field: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            field: field.into(),
            message: message.into(),
        }
    }
}

/// 应用错误类型
#[derive(Debug, Error)]
pub enum AppError {
    // ===== 客户端错误 (4xx) =====
    /// 无效请求参数
    #[error("Bad request: {0}")]
    BadRequest(String),

    /// 未授权
    #[error("Unauthorized: {0}")]
    Unauthorized(String),

    /// 禁止访问
    #[error("Forbidden: {0}")]
    Forbidden(String),

    /// 资源未找到
    #[error("Resource not found: {0}")]
    NotFound(String),

    /// 方法不允许
    #[error("Method not allowed")]
    MethodNotAllowed,

    /// 请求超时 (客户端)
    #[error("Request timeout")]
    RequestTimeout,

    /// 冲突 (资源已存在)
    #[error("Conflict: {0}")]
    Conflict(String),

    /// 验证错误 (字段级)
    #[error("Validation error")]
    ValidationError { fields: Vec<FieldError> },

    /// 不支持的媒体类型
    #[error("Unsupported media type")]
    UnsupportedMediaType,

    /// 请求体过大
    #[error("Payload too large")]
    PayloadTooLarge,

    // ===== 服务器错误 (5xx) =====
    /// 内部服务器错误
    #[error("Internal server error: {0}")]
    InternalError(String),

    /// 数据库错误
    #[error("Database error: {0}")]
    DatabaseError(String),

    /// 配置错误
    #[error("Configuration error: {0}")]
    ConfigError(String),

    /// 外部服务错误
    #[error("External service error: {0}")]
    ExternalServiceError(String),

    /// 服务不可用
    #[error("Service unavailable")]
    ServiceUnavailable,

    /// 网关超时
    #[error("Gateway timeout")]
    GatewayTimeout,

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
            // 4xx - 客户端错误
            AppError::BadRequest(_) => StatusCode::BAD_REQUEST,
            AppError::Unauthorized(_) => StatusCode::UNAUTHORIZED,
            AppError::Forbidden(_) => StatusCode::FORBIDDEN,
            AppError::NotFound(_) => StatusCode::NOT_FOUND,
            AppError::MethodNotAllowed => StatusCode::METHOD_NOT_ALLOWED,
            AppError::RequestTimeout => StatusCode::REQUEST_TIMEOUT,
            AppError::Conflict(_) => StatusCode::CONFLICT,
            AppError::ValidationError { .. } => StatusCode::UNPROCESSABLE_ENTITY,
            AppError::UnsupportedMediaType => StatusCode::UNSUPPORTED_MEDIA_TYPE,
            AppError::PayloadTooLarge => StatusCode::PAYLOAD_TOO_LARGE,
            AppError::CorsError(_) => StatusCode::FORBIDDEN,

            // 5xx - 服务器错误
            AppError::InternalError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::DatabaseError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::ConfigError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::ExternalServiceError(_) => StatusCode::BAD_GATEWAY,
            AppError::ServiceUnavailable => StatusCode::SERVICE_UNAVAILABLE,
            AppError::GatewayTimeout => StatusCode::GATEWAY_TIMEOUT,
        }
    }

    /// 获取错误码
    pub fn error_code(&self) -> u16 {
        self.status_code().as_u16()
    }

    /// 转换为API错误响应
    fn to_api_error_response(&self) -> ApiErrorResponse {
        ApiErrorResponse {
            code: self.status_code().as_u16(),
            message: self.to_string(),
            details: match self {
                AppError::ValidationError { fields } => Some(fields.clone()),
                _ => None,
            },
            timestamp: current_timestamp(),
        }
    }

    /// 创建字段验证错误
    pub fn validation_error(fields: Vec<FieldError>) -> Self {
        AppError::ValidationError { fields }
    }

    /// 创建单个字段验证错误
    pub fn validation_error_single(field: impl Into<String>, message: impl Into<String>) -> Self {
        AppError::ValidationError {
            fields: vec![FieldError::new(field, message)],
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let status = self.status_code();
        let body = Json(self.to_api_error_response());

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

impl From<JsonRejection> for AppError {
    fn from(rejection: JsonRejection) -> Self {
        match rejection {
            JsonRejection::JsonDataError(e) => {
                AppError::BadRequest(format!("JSON data error: {e}"))
            }
            JsonRejection::JsonSyntaxError(e) => {
                AppError::BadRequest(format!("JSON syntax error: {e}"))
            }
            JsonRejection::MissingJsonContentType(_) => {
                AppError::BadRequest("Missing JSON content type".to_string())
            }
            JsonRejection::BytesRejection(_) => {
                AppError::BadRequest("Failed to read request body".to_string())
            }
            _ => AppError::BadRequest("Invalid JSON".to_string()),
        }
    }
}

impl From<QueryRejection> for AppError {
    fn from(rejection: QueryRejection) -> Self {
        AppError::BadRequest(format!("Query parameter error: {rejection}"))
    }
}

impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        match err {
            sqlx::Error::RowNotFound => AppError::NotFound("Resource not found".to_string()),
            sqlx::Error::Database(db_err) => {
                if db_err.is_unique_violation() {
                    AppError::Conflict("Resource already exists".to_string())
                } else {
                    AppError::DatabaseError(db_err.to_string())
                }
            }
            sqlx::Error::PoolTimedOut => AppError::ServiceUnavailable,
            sqlx::Error::PoolClosed => AppError::ServiceUnavailable,
            _ => AppError::DatabaseError(err.to_string()),
        }
    }
}

/// 统一错误处理函数（用于 Tower 的 HandleErrorLayer）
pub async fn handle_error(err: tower::BoxError) -> impl IntoResponse {
    if err.is::<tower::timeout::error::Elapsed>() {
        AppError::RequestTimeout
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

#[cfg(test)]
mod tests {
    use super::*;
    use axum::response::IntoResponse;

    #[test]
    fn test_api_response_success() {
        let data = serde_json::json!({"id": 1, "name": "test"});
        let response = ApiResponse::success(data);

        assert_eq!(response.code, 200);
        assert_eq!(response.message, "success");
        assert!(response.timestamp.is_some());
    }

    #[test]
    fn test_api_response_created() {
        let data = serde_json::json!({"id": 1});
        let response = ApiResponse::created(data);

        assert_eq!(response.code, 201);
        assert_eq!(response.message, "created");
    }

    #[test]
    fn test_app_error_status_codes() {
        // 4xx errors
        assert_eq!(
            AppError::BadRequest("test".to_string()).status_code(),
            StatusCode::BAD_REQUEST
        );
        assert_eq!(
            AppError::Unauthorized("test".to_string()).status_code(),
            StatusCode::UNAUTHORIZED
        );
        assert_eq!(
            AppError::NotFound("test".to_string()).status_code(),
            StatusCode::NOT_FOUND
        );
        assert_eq!(
            AppError::Conflict("test".to_string()).status_code(),
            StatusCode::CONFLICT
        );

        // 5xx errors
        assert_eq!(
            AppError::InternalError("test".to_string()).status_code(),
            StatusCode::INTERNAL_SERVER_ERROR
        );
        assert_eq!(
            AppError::DatabaseError("test".to_string()).status_code(),
            StatusCode::INTERNAL_SERVER_ERROR
        );
    }

    #[test]
    fn test_validation_error() {
        let fields = vec![
            FieldError::new("email", "invalid format"),
            FieldError::new("password", "too short"),
        ];
        let error = AppError::validation_error(fields);

        assert_eq!(error.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
    }

    #[test]
    fn test_field_error() {
        let field_error = FieldError::new("username", "required");
        assert_eq!(field_error.field, "username");
        assert_eq!(field_error.message, "required");
    }

    #[test]
    fn test_error_into_response() {
        let error = AppError::NotFound("user not found".to_string());
        let response = error.into_response();

        assert_eq!(response.status(), StatusCode::NOT_FOUND);
    }

    #[test]
    fn test_io_error_conversion() {
        let io_err = std::io::Error::new(std::io::ErrorKind::NotFound, "file not found");
        let app_err: AppError = io_err.into();

        assert!(matches!(app_err, AppError::InternalError(_)));
    }
}
