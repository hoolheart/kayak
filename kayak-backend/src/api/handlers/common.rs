//! 通用响应工具
//!
//! 提供统一的响应构建函数

use axum::{
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;

/// 成功响应包装
#[derive(Debug, Serialize)]
pub struct SuccessResponse<T> {
    pub code: u16,
    pub message: String,
    pub data: T,
    pub timestamp: String,
}

impl<T: Serialize> SuccessResponse<T> {
    /// 创建成功响应
    pub fn new(data: T) -> Self {
        Self {
            code: 200,
            message: "success".to_string(),
            data,
            timestamp: current_timestamp(),
        }
    }

    /// 转换为JSON响应
    pub fn into_response(self) -> Response {
        Json(self).into_response()
    }
}

/// 空响应数据
#[derive(Debug, Serialize)]
pub struct EmptyResponse;

impl EmptyResponse {
    /// 创建空成功响应
    pub fn success() -> Response {
        let response = SuccessResponse::new(EmptyResponse);
        response.into_response()
    }
}

/// 获取当前时间戳
fn current_timestamp() -> String {
    use time::OffsetDateTime;
    OffsetDateTime::now_utc()
        .format(&time::format_description::well_known::Rfc3339)
        .unwrap_or_else(|_| "1970-01-01T00:00:00Z".to_string())
}
