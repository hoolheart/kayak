//! 路由定义
//!
//! 定义应用的所有HTTP路由

use std::sync::Arc;

use axum::{
    routing::{get, post},
    Router,
};

use crate::api::handlers::health;
use crate::api::middleware::error::not_found_handler;
use crate::auth::{
    handlers::{login, refresh_token, register},
    services::{AuthServiceImpl, BcryptPasswordHasher, JwtTokenService},
    user_repo_adapter::UserRepositoryAdapter,
};
use crate::db::connection::DbPool;
use crate::db::repository::user_repo::UserRepository;

/// 创建应用路由
pub fn create_router(pool: DbPool) -> Router {
    // 创建认证服务
    let user_repo = UserRepository::new(pool.clone());
    let user_repo_adapter = Arc::new(UserRepositoryAdapter::new(user_repo));

    let token_service = Arc::new(JwtTokenService::new(
        std::env::var("JWT_ACCESS_SECRET")
            .unwrap_or_else(|_| "default_access_secret_change_in_production".to_string()),
        std::env::var("JWT_REFRESH_SECRET")
            .unwrap_or_else(|_| "default_refresh_secret_change_in_production".to_string()),
    ));

    let password_hasher = Arc::new(BcryptPasswordHasher);

    let auth_service = Arc::new(AuthServiceImpl::new(
        user_repo_adapter,
        token_service,
        password_hasher,
    ));

    Router::new()
        // 健康检查（最优先，无中间件限制）
        .route("/health", get(health::health_check))
        // API路由
        .merge(api_routes(auth_service))
        // 404处理
        .fallback(not_found_handler)
}

/// API路由组
fn api_routes<S>(auth_service: Arc<S>) -> Router
where
    S: crate::auth::traits::AuthService + 'static,
{
    Router::new().nest(
        "/api/v1",
        Router::new()
            // 认证相关
            .route("/auth/register", post(register::<S>))
            .route("/auth/login", post(login::<S>))
            .route("/auth/refresh", post(refresh_token::<S>))
            // 工作台相关
            // .route("/workbenches", get(workbench::list))
            .with_state(auth_service),
    )
}

/// 获取健康检查路由（用于测试）
pub fn health_routes() -> Router {
    Router::new().route("/health", get(health::health_check))
}
