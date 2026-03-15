//! 应用配置管理
//!
//! 负责从环境变量和配置文件加载应用配置

use config::{Config as ConfigLoader, ConfigError, Environment, File};
use serde::{Deserialize, Serialize};

/// 应用配置根结构
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct AppConfig {
    /// 服务器配置
    pub server: ServerConfig,
    /// 日志配置
    pub log: LogConfig,
    /// CORS配置
    pub cors: CorsConfig,
}

impl AppConfig {
    /// 从环境变量和配置文件加载配置
    pub fn load() -> Result<Self, ConfigError> {
        let config = ConfigLoader::builder()
            // 从默认配置开始
            .set_default("server.host", "0.0.0.0")?
            .set_default("server.port", 8080)?
            .set_default("server.timeout_seconds", 30)?
            .set_default("log.level", "info")?
            .set_default("log.json_format", false)?
            .set_default("cors.allow_any_origin", true)?
            .set_default("cors.max_age", 3600)?
            .set_default("cors.allow_credentials", false)?
            // 从配置文件加载（可选）
            .add_source(File::with_name("config/kayak").required(false))
            // 从环境变量加载（前缀 KAYAK_）
            .add_source(Environment::with_prefix("KAYAK").separator("__"))
            .build()?;

        config.try_deserialize()
    }

    /// 获取绑定地址
    pub fn bind_address(&self) -> String {
        format!("{}:{}", self.server.host, self.server.port)
    }
}

/// 服务器配置
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ServerConfig {
    /// 监听主机
    pub host: String,
    /// 监听端口
    pub port: u16,
    /// 请求超时（秒）
    pub timeout_seconds: Option<u64>,
}

/// 日志配置
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LogConfig {
    /// 日志级别: trace, debug, info, warn, error
    pub level: String,
    /// 是否启用JSON格式
    pub json_format: Option<bool>,
    /// 是否包含位置信息
    pub include_location: Option<bool>,
}

/// CORS配置
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CorsConfig {
    /// 允许的来源列表
    #[serde(default)]
    pub allowed_origins: Vec<String>,
    /// 允许的方法
    #[serde(default)]
    pub allowed_methods: Vec<String>,
    /// 允许的请求头
    #[serde(default)]
    pub allowed_headers: Vec<String>,
    /// 允许暴露的响应头
    #[serde(default)]
    pub exposed_headers: Vec<String>,
    /// 是否允许携带凭证
    pub allow_credentials: bool,
    /// 预检请求缓存时间（秒）
    pub max_age: u64,
    /// 允许任意来源（开发环境）
    pub allow_any_origin: bool,
}
