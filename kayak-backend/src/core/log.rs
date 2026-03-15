//! 日志系统初始化
//!
//! 配置 tracing-subscriber 以提供结构化日志输出

use crate::core::config::LogConfig;
use tracing_subscriber::{
    fmt::{self},
    layer::{Layer, SubscriberExt},
    util::SubscriberInitExt,
    EnvFilter,
};

/// 初始化日志系统
pub fn init_logging(config: &LogConfig) -> Result<(), Box<dyn std::error::Error>> {
    // 从配置或环境变量获取日志级别
    let filter =
        EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(&config.level));

    // 配置格式化层
    let fmt_layer = fmt::layer()
        .with_target(true)
        .with_level(true)
        .with_thread_ids(false)
        .with_thread_names(false)
        .with_file(false)
        .with_line_number(false)
        // ISO 8601 / RFC 3339 格式时间戳
        .with_timer(fmt::time::UtcTime::rfc_3339())
        // 美化输出（开发环境）
        .with_ansi(true)
        .compact();

    // JSON格式（可选，生产环境）
    let fmt_layer = if config.json_format.unwrap_or(false) {
        fmt::layer()
            .json()
            .with_timer(fmt::time::UtcTime::rfc_3339())
            .boxed()
    } else {
        fmt_layer.boxed()
    };

    // 初始化订阅者
    tracing_subscriber::registry()
        .with(filter)
        .with(fmt_layer)
        .init();

    Ok(())
}
