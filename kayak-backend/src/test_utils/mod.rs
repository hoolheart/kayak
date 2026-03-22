//! 测试工具模块
//!
//! 提供测试辅助函数、mock工具和数据工厂

pub mod fixtures;
pub mod mocks;

use crate::db::connection::DbPool;
use sqlx::SqlitePool;
use uuid::Uuid;

/// 测试数据库上下文
///
/// 为每个测试提供独立的数据库连接池
pub struct TestDbContext {
    pub pool: DbPool,
    #[allow(dead_code)]
    db_name: String,
}

impl TestDbContext {
    /// 创建新的测试数据库上下文
    ///
    /// 使用唯一的内存数据库URL，确保测试隔离
    pub async fn new() -> Self {
        let db_id = Uuid::new_v4().to_string();
        let db_url = format!(
            "sqlite:file:{}?mode=memory&cache=shared",
            db_id
        );

        let pool = SqlitePool::connect(&db_url)
            .await
            .expect("Failed to create test database pool");

        // 运行迁移
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .expect("Failed to run migrations");

        Self { pool, db_name: db_id }
    }

    /// 获取数据库连接池
    pub fn pool(&self) -> DbPool {
        self.pool.clone()
    }
}

impl Drop for TestDbContext {
    fn drop(&mut self) {
        // 数据库会在 context 被 drop 时自动清理
        // SQLite 内存数据库在最后一个连接关闭时自动删除
    }
}

/// 测试配置
pub struct TestConfig {
    /// 是否启用日志
    pub enable_logging: bool,
    /// 测试超时时间（秒）
    pub timeout_secs: u64,
}

impl Default for TestConfig {
    fn default() -> Self {
        Self {
            enable_logging: false,
            timeout_secs: 30,
        }
    }
}

impl TestConfig {
    /// 初始化测试环境
    pub fn init() -> Self {
        let config = Self::default();

        if config.enable_logging {
            // 初始化日志（如果需要）
            let _ = tracing_subscriber::fmt::try_init();
        }

        config
    }
}

/// 异步测试运行时
///
/// 使用 tokio::test 属性，但提供统一配置
#[cfg(test)]
pub mod async_runtime {
    pub use tokio::test;
}
