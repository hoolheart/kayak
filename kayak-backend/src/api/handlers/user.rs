//! 用户处理器
//!
//! 处理用户个人信息管理的HTTP请求

use std::sync::Arc;

use axum::{extract::State, Json};
use validator::Validate;

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::services::user::{ChangePasswordRequest, UpdateUserRequest, UserDto, UserService};

/// GET /api/v1/users/me - 获取当前用户信息
pub async fn get_current_user(
    State(user_service): State<Arc<dyn UserService>>,
    RequireAuth(user_ctx): RequireAuth,
) -> Result<Json<ApiResponse<UserDto>>, AppError> {
    let user = user_service.get_current_user(user_ctx.user_id).await?;
    Ok(Json(ApiResponse::success(user)))
}

/// PUT /api/v1/users/me - 更新当前用户信息
pub async fn update_current_user(
    State(user_service): State<Arc<dyn UserService>>,
    RequireAuth(user_ctx): RequireAuth,
    Json(payload): Json<UpdateUserRequest>,
) -> Result<Json<ApiResponse<UserDto>>, AppError> {
    // Validate the request
    payload
        .validate()
        .map_err(|e| AppError::validation_error_single("validation", e.to_string()))?;

    let user = user_service.update_user(user_ctx.user_id, payload).await?;
    Ok(Json(ApiResponse::success_with_message(
        user,
        "User updated successfully",
    )))
}

/// POST /api/v1/users/me/password - 修改密码
pub async fn change_password(
    State(user_service): State<Arc<dyn UserService>>,
    RequireAuth(user_ctx): RequireAuth,
    Json(payload): Json<ChangePasswordRequest>,
) -> Result<Json<ApiResponse<()>>, AppError> {
    // Validate the request
    payload
        .validate()
        .map_err(|e| AppError::validation_error_single("validation", e.to_string()))?;

    user_service
        .change_password(user_ctx.user_id, payload)
        .await?;
    Ok(Json(ApiResponse::success_with_message(
        (),
        "Password updated successfully",
    )))
}
