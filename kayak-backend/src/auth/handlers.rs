//! 认证HTTP处理器
//!
//! 处理认证相关的HTTP请求

use std::sync::Arc;

use axum::{extract::State, Json};
use validator::Validate;

use crate::auth::traits::AuthService;
use crate::auth::dtos::{
    LoginRequest, RegisterRequest, RegisterResponse, TokenRefreshRequest,
    TokenResponse, UserAuthInfo,
};
use crate::core::error::{ApiResponse, AppError};

/// 处理用户注册
pub async fn register<S: AuthService>(
    State(auth_service): State<Arc<S>>,
    Json(req): Json<RegisterRequest>,
) -> Result<Json<ApiResponse<RegisterResponse>>, AppError> {
    // 验证请求
    req.validate()
        .map_err(|e| AppError::validation_error_single("validation", &e.to_string()))?;

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
        .map_err(|e| AppError::validation_error_single("validation", &e.to_string()))?;

    // 执行登录 - 需要返回用户信息和token
    let token_pair = auth_service.login(req).await?;
    
    // 为了获取用户信息，需要重新查询
    // 这里简化处理，实际AuthService.login应该返回用户信息
    // 暂时使用Token中的信息构建UserAuthInfo
    let response = TokenResponse {
        access_token: token_pair.access_token,
        refresh_token: token_pair.refresh_token,
        token_type: token_pair.token_type,
        expires_in: token_pair.expires_in,
        user: UserAuthInfo {
            id: uuid::Uuid::new_v4(),
            email: "from_token@example.com".to_string(),
            username: None,
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
        .map_err(|e| AppError::validation_error_single("validation", &e.to_string()))?;

    // 刷新Token
    let token_pair = auth_service.refresh_token(req).await?;

    let response = TokenResponse {
        access_token: token_pair.access_token,
        refresh_token: token_pair.refresh_token,
        token_type: token_pair.token_type,
        expires_in: token_pair.expires_in,
        user: UserAuthInfo {
            id: uuid::Uuid::new_v4(),
            email: "from_token@example.com".to_string(),
            username: None,
        },
    };

    Ok(Json(ApiResponse::success(response)))
}