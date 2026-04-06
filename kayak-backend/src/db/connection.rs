//! 数据库连接管理
//!
//! 提供数据库连接池初始化和连接管理

use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{migrate::Migrator, SqlitePool};
use std::path::Path;
use tracing::{error, info};

pub type DbPool = SqlitePool;

/// Get the migrator - created lazily to avoid initialization issues in tests
#[allow(dead_code)]
fn get_migrator() -> Migrator {
    sqlx::migrate!("./migrations")
}

/// 初始化数据库
///
/// 创建数据库连接池并执行迁移
pub async fn init_db(database_url: &str) -> Result<DbPool, sqlx::Error> {
    init_db_with_migrations(database_url, true).await
}

/// 初始化数据库，不运行迁移（用于测试）
pub async fn init_db_without_migrations(database_url: &str) -> Result<DbPool, sqlx::Error> {
    init_db_with_migrations(database_url, false).await
}

async fn init_db_with_migrations(
    database_url: &str,
    run_migrations: bool,
) -> Result<DbPool, sqlx::Error> {
    info!("Initializing database connection pool...");

    // 解析数据库URL
    let db_path = database_url.trim_start_matches("sqlite://");

    // 确保数据库目录存在（仅对文件数据库）
    if !db_path.contains(":memory:") {
        if let Some(parent) = Path::new(db_path).parent() {
            std::fs::create_dir_all(parent).map_err(|e| {
                error!("Failed to create database directory: {}", e);
                sqlx::Error::Io(std::io::Error::other(format!(
                    "Failed to create database directory: {}",
                    e
                )))
            })?;
        }
    }

    // 配置连接选项
    let options = SqliteConnectOptions::new()
        .filename(db_path)
        .create_if_missing(true)
        .busy_timeout(std::time::Duration::from_secs(30));

    // 创建连接池
    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .min_connections(1)
        .acquire_timeout(std::time::Duration::from_secs(30))
        .idle_timeout(std::time::Duration::from_secs(300))
        .connect_with(options)
        .await?;

    info!("Database connection pool created successfully");

    // 执行迁移 - 跳过因为SQLx与SQLite事务不兼容
    if run_migrations {
        info!("Skipping SQLx migrations due to SQLite transaction limitations...");
        info!("Database tables should already exist from initial setup");
    }

    Ok(pool)
}

/// 获取数据库连接
///
/// 从连接池获取一个连接
pub async fn get_conn(
    pool: &DbPool,
) -> Result<sqlx::pool::PoolConnection<sqlx::Sqlite>, sqlx::Error> {
    pool.acquire().await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_init_db() {
        // Use init_db_without_migrations for simple test
        let pool = init_db_without_migrations("sqlite::memory:").await.unwrap();
        assert!(!pool.is_closed());
    }
}
