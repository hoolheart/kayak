//! CORS配置
//!
//! 提供跨域资源共享中间件配置

use axum::http::{header, Method};
use tower_http::cors::{Any, CorsLayer};

/// CORS配置构建器
pub struct CorsConfigBuilder;

impl CorsConfigBuilder {
    /// 默认配置 - 允许本地开发
    pub fn default_config() -> CorsLayer {
        CorsLayer::new()
            .allow_origin([
                "http://localhost:3000".parse().unwrap(),
                "http://localhost:8080".parse().unwrap(),
                "http://127.0.0.1:3000".parse().unwrap(),
                "http://127.0.0.1:8080".parse().unwrap(),
            ])
            .allow_methods([
                Method::GET,
                Method::POST,
                Method::PUT,
                Method::DELETE,
                Method::OPTIONS,
            ])
            .allow_headers([header::CONTENT_TYPE, header::AUTHORIZATION, header::ACCEPT])
            .max_age(std::time::Duration::from_secs(3600))
    }

    /// 开发环境配置 - 允许所有来源
    pub fn development() -> CorsLayer {
        CorsLayer::new()
            .allow_origin(Any)
            .allow_methods(Any)
            .allow_headers(Any)
            .allow_credentials(false)
            .max_age(std::time::Duration::from_secs(3600))
    }

    /// 生产环境配置 - 严格限制
    pub fn production(allowed_origins: Vec<String>) -> CorsLayer {
        let origins: Vec<_> = allowed_origins
            .into_iter()
            .filter_map(|o| o.parse().ok())
            .collect();

        CorsLayer::new()
            .allow_origin(origins)
            .allow_methods([
                Method::GET,
                Method::POST,
                Method::PUT,
                Method::DELETE,
                Method::OPTIONS,
            ])
            .allow_headers([
                header::CONTENT_TYPE,
                header::AUTHORIZATION,
                header::ACCEPT,
                header::ORIGIN,
            ])
            .expose_headers([header::CONTENT_DISPOSITION])
            .allow_credentials(true)
            .max_age(std::time::Duration::from_secs(86400))
    }
}
