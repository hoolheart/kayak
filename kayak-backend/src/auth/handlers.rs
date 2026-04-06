//! 认证HTTP处理器
//!
//! 处理认证相关的HTTP请求

use std::sync::Arc;

use axum::{extract::State, http::HeaderMap, Json};
use validator::Validate;

use crate::auth::dtos::{
    LoginRequest, RegisterRequest, RegisterResponse, TokenRefreshRequest, TokenResponse,
    UserAuthInfo,
};
use crate::auth::traits::AuthService;
use crate::core::error::{ApiResponse, AppError};

/// 处理用户注册
pub async fn register<S: AuthService>(
    State(auth_service): State<Arc<S>>,
    Json(req): Json<RegisterRequest>,
) -> Result<Json<ApiResponse<RegisterResponse>>, AppError> {
    // 验证请求
    req.validate()
        .map_err(|e| AppError::validation_error_single("validation", e.to_string()))?;

    // 注册用户
    let user = auth_service.register(req).await?;

    let response = RegisterResponse {
        id: user.id,
        email: user.email,
        username: user.username,
        created_at: user.created_at,
    };

    Ok(Json(ApiResponse::created(response)))
}

/// 处理用户登录
pub async fn login<S: AuthService>(
    State(auth_service): State<Arc<S>>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<ApiResponse<TokenResponse>>, AppError> {
    // 验证请求
    req.validate()
        .map_err(|e| AppError::validation_error_single("validation", e.to_string()))?;

    // 执行登录
    let login_response = auth_service.login(req).await?;

    let response = TokenResponse {
        access_token: login_response.access_token,
        refresh_token: login_response.refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: login_response.expires_in,
        user: UserAuthInfo {
            id: login_response.user_id,
            email: login_response.email,
            username: login_response.username,
        },
    };

    Ok(Json(ApiResponse::success(response)))
}

/// 处理Token刷新
pub async fn refresh_token<S: AuthService>(
    State(auth_service): State<Arc<S>>,
    Json(req): Json<TokenRefreshRequest>,
) -> Result<Json<ApiResponse<TokenResponse>>, AppError> {
    // 验证请求
    req.validate()
        .map_err(|e| AppError::validation_error_single("validation", e.to_string()))?;

    // 刷新Token
    let login_response = auth_service.refresh_token(req).await?;

    let response = TokenResponse {
        access_token: login_response.access_token,
        refresh_token: login_response.refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: login_response.expires_in,
        user: UserAuthInfo {
            id: login_response.user_id,
            email: login_response.email,
            username: login_response.username,
        },
    };

    Ok(Json(ApiResponse::success(response)))
}

/// 获取当前用户信息（通过token）
pub async fn get_authenticated_user<S: AuthService + 'static>(
    State(auth_service): State<Arc<S>>,
    headers: HeaderMap,
) -> Result<Json<ApiResponse<UserAuthInfo>>, AppError> {
    // 从请求头提取 Authorization
    let auth_header = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or_else(|| AppError::Unauthorized("Missing Authorization header".to_string()))?;

    // 提取 Bearer token
    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or_else(|| AppError::Unauthorized("Invalid Authorization header format".to_string()))?;

    // 验证 token
    let claims = auth_service.verify_access_token(token)?;

    // 获取用户信息
    let user = auth_service
        .get_user_by_id(claims.sub)
        .await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    let user_info = UserAuthInfo {
        id: user.id,
        email: user.email,
        username: user.username,
    };

    Ok(Json(ApiResponse::success(user_info)))
}
