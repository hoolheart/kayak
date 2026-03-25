//! 中间件模块
//!
//! 包含所有HTTP中间件（CORS、追踪、错误处理等）

pub mod cors;
pub mod error;
pub mod trace;

use crate::core::config::AppConfig;
use axum::Router;
use std::time::Duration;
use tower_http::{
    compression::CompressionLayer, cors::CorsLayer, timeout::TimeoutLayer, trace::TraceLayer,
};

/// 应用中间件栈
pub struct MiddlewareStack;

impl MiddlewareStack {
    /// 为路由应用所有中间件
    ///
    /// 中间件执行顺序（从外到内）：
    /// 1. Compression - 响应压缩
    /// 2. Timeout - 请求超时
    /// 3. CORS - 跨域处理
    /// 4. Trace - 请求追踪和日志
    pub fn apply(router: Router, config: &AppConfig) -> Router {
        router
            .layer(Self::create_compression_layer())
            .layer(Self::create_timeout_layer(config))
            .layer(Self::create_cors_layer(config))
            .layer(Self::create_trace_layer())
    }

    /// 创建追踪中间件
    ///
    /// 功能：
    /// - 记录请求开始和结束
    /// - 记录请求方法和URI
    /// - 记录响应状态和延迟
    fn create_trace_layer() -> TraceLayer<
        tower_http::classify::SharedClassifier<tower_http::classify::ServerErrorsAsFailures>,
    > {
        TraceLayer::new_for_http()
            .make_span_with(tower_http::trace::DefaultMakeSpan::new().include_headers(false))
            .on_request(tower_http::trace::DefaultOnRequest::new().level(tracing::Level::INFO))
            .on_response(tower_http::trace::DefaultOnResponse::new().level(tracing::Level::INFO))
    }

    /// 创建CORS中间件
    fn create_cors_layer(config: &AppConfig) -> CorsLayer {
        let mut cors = CorsLayer::new()
            .allow_methods([
                axum::http::Method::GET,
                axum::http::Method::POST,
                axum::http::Method::PUT,
                axum::http::Method::DELETE,
                axum::http::Method::OPTIONS,
            ])
            .allow_headers([
                axum::http::header::CONTENT_TYPE,
                axum::http::header::AUTHORIZATION,
                axum::http::header::ACCEPT,
            ]);

        // 开发环境允许任意来源
        if config.cors.allow_any_origin {
            cors = cors.allow_origin(tower_http::cors::Any);
        } else {
            // 生产环境使用配置的允许来源
            let origins: Vec<_> = config
                .cors
                .allowed_origins
                .iter()
                .filter_map(|o| o.parse().ok())
                .collect();
            if !origins.is_empty() {
                cors = cors.allow_origin(origins);
            }
        }

        cors.max_age(Duration::from_secs(config.cors.max_age))
    }

    /// 创建超时中间件
    fn create_timeout_layer(config: &AppConfig) -> TimeoutLayer {
        let timeout = config.server.timeout_seconds.unwrap_or(30);
        TimeoutLayer::new(Duration::from_secs(timeout))
    }

    /// 创建压缩中间件
    fn create_compression_layer() -> CompressionLayer {
        CompressionLayer::new()
    }
}
