//! 请求追踪中间件
//!
//! 提供请求追踪和性能监控功能

use axum::{
    extract::{ConnectInfo, Request},
    middleware::Next,
    response::Response,
};
use std::net::SocketAddr;
use std::time::Instant;
use tracing::{info, info_span, Instrument};

/// 请求追踪中间件
///
/// 为每个请求：
/// 1. 生成唯一请求ID
/// 2. 记录请求开始日志
/// 3. 记录请求完成日志（包含延迟）
/// 4. 添加追踪上下文
pub async fn trace_requests(req: Request, next: Next) -> Response {
    let start = Instant::now();
    let request_id = uuid();

    let method = req.method().to_string();
    let uri = req.uri().to_string();
    let remote_addr = req.extensions()
        .get::<ConnectInfo<SocketAddr>>()
        .map(|info| info.0);

    // 创建追踪span
    let span = info_span!(
        "http_request",
        request_id = %request_id,
        method = %method,
        uri = %uri,
        remote_addr = ?remote_addr,
    );

    async move {
        // 记录请求开始
        info!(
            request_id = %request_id,
            method = %method,
            uri = %uri,
            "Request started"
        );

        // 处理请求
        let response = next.run(req).await;

        // 计算延迟
        let latency = start.elapsed();
        let status = response.status();

        // 记录请求完成
        info!(
            request_id = %request_id,
            method = %method,
            uri = %uri,
            status = %status,
            latency_ms = %latency.as_millis(),
            "Request completed"
        );

        response
    }
    .instrument(span)
    .await
}

/// 生成简单的UUID（不需要外部依赖）
fn uuid() -> String {
    use std::sync::atomic::{AtomicU64, Ordering};
    use std::time::{SystemTime, UNIX_EPOCH};

    static COUNTER: AtomicU64 = AtomicU64::new(0);

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();

    let counter = COUNTER.fetch_add(1, Ordering::Relaxed);

    format!("{:x}-{:x}", timestamp, counter)
}
