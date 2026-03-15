//! 路由定义
//!
//! 定义应用的所有HTTP路由

use crate::api::handlers::health;
use crate::api::middleware::error::not_found_handler;
use axum::{routing::get, Router};

/// 创建应用路由
pub fn create_router() -> Router {
    Router::new()
        // 健康检查（最优先，无中间件限制）
        .route("/health", get(health::health_check))
        // API路由
        .merge(api_routes())
        // 404处理
        .fallback(not_found_handler)
}

/// API路由组
fn api_routes() -> Router {
    Router::new().nest(
        "/api/v1",
        Router::new(), // 认证相关
                       // .route("/auth/login", post(auth::login))
                       // 工作台相关
                       // .route("/workbenches", get(workbench::list))
    )
}

/// 获取健康检查路由（用于测试）
pub fn health_routes() -> Router {
    Router::new().route("/health", get(health::health_check))
}
