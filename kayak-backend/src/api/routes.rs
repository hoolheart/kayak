//! 路由定义
//!
//! 定义应用的所有HTTP路由

use std::sync::Arc;

use axum::{
    routing::{delete, get, post, put},
    Router,
};

use crate::api::handlers::health;
use crate::api::handlers::user;
use crate::api::handlers::workbench;
use crate::api::middleware::error::not_found_handler;
use crate::auth::{
    handlers::{login, refresh_token, register},
    services::{AuthServiceImpl, BcryptPasswordHasher, JwtTokenService},
    user_repo_adapter::UserRepositoryAdapter,
};
use crate::db::connection::DbPool;
use crate::db::repository::user_repo::UserRepository;
use crate::db::repository::workbench_repo::SqlxWorkbenchRepository;
use crate::services::user::{UserService, UserServiceImpl};
use crate::services::user_repo_adapter::UserServiceRepositoryAdapter;
use crate::services::workbench::{WorkbenchService, WorkbenchServiceImpl};

/// 创建应用路由
pub fn create_router(pool: DbPool) -> Router {
    // 创建基础组件
    let user_repo = UserRepository::new(pool.clone());
    let user_service_repo_adapter = Arc::new(UserServiceRepositoryAdapter::new(user_repo));

    let token_service = Arc::new(JwtTokenService::new(
        std::env::var("JWT_ACCESS_SECRET")
            .unwrap_or_else(|_| "default_access_secret_change_in_production".to_string()),
        std::env::var("JWT_REFRESH_SECRET")
            .unwrap_or_else(|_| "default_refresh_secret_change_in_production".to_string()),
    ));

    let password_hasher = Arc::new(BcryptPasswordHasher);

    // 创建认证服务
    let user_repo_adapter = Arc::new(UserRepositoryAdapter::new(UserRepository::new(
        pool.clone(),
    )));
    let auth_service = Arc::new(AuthServiceImpl::new(
        user_repo_adapter,
        token_service,
        password_hasher.clone(),
    ));

    // 创建用户服务
    let user_service: Arc<dyn UserService> = Arc::new(UserServiceImpl::new(
        user_service_repo_adapter,
        password_hasher,
    ));

    // 创建工作台服务
    let workbench_repo = SqlxWorkbenchRepository::new(pool);
    let workbench_service: Arc<dyn WorkbenchService> =
        Arc::new(WorkbenchServiceImpl::new(Arc::new(workbench_repo)));

    Router::new()
        // 健康检查（最优先，无中间件限制）
        .route("/health", get(health::health_check))
        // API路由
        .merge(auth_routes(auth_service))
        .merge(user_routes(user_service))
        .merge(workbench_routes(workbench_service))
        // 404处理
        .fallback(not_found_handler)
}

/// 认证路由组
fn auth_routes<S>(auth_service: Arc<S>) -> Router
where
    S: crate::auth::traits::AuthService + 'static,
{
    Router::new().nest(
        "/api/v1/auth",
        Router::new()
            .route("/register", post(register::<S>))
            .route("/login", post(login::<S>))
            .route("/refresh", post(refresh_token::<S>))
            .with_state(auth_service),
    )
}

/// 用户路由组
fn user_routes(user_service: Arc<dyn UserService>) -> Router {
    Router::new().nest(
        "/api/v1/users",
        Router::new()
            .route("/me", get(get_current_user))
            .route("/me", put(update_current_user))
            .route("/me/password", post(change_password))
            .with_state(user_service),
    )
}

/// 工作台路由组
fn workbench_routes(workbench_service: Arc<dyn WorkbenchService>) -> Router {
    Router::new().nest(
        "/api/v1/workbenches",
        Router::new()
            .route("/", post(workbench::create_workbench))
            .route("/", get(workbench::list_workbenches))
            .route("/{id}", get(workbench::get_workbench))
            .route("/{id}", put(workbench::update_workbench))
            .route("/{id}", delete(workbench::delete_workbench))
            .with_state(workbench_service),
    )
}

// Re-export for use in tests or other modules
pub use user::{change_password, get_current_user, update_current_user};
pub use workbench::{
    create_workbench, delete_workbench, get_workbench, list_workbenches, update_workbench,
};

/// 获取健康检查路由（用于测试）
pub fn health_routes() -> Router {
    Router::new().route("/health", get(health::health_check))
}
