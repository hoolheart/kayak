//! 数据库连接管理
//!
//! 提供数据库连接池初始化和连接管理

use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{migrate::Migrator, SqlitePool};
use std::path::Path;
use tracing::{error, info};

pub type DbPool = SqlitePool;

static MIGRATOR: Migrator = sqlx::migrate!("./migrations");

/// 初始化数据库
///
/// 创建数据库连接池并执行迁移
pub async fn init_db(database_url: &str) -> Result<DbPool, sqlx::Error> {
    info!("Initializing database connection pool...");

    // 确保数据库目录存在
    if let Some(parent) = Path::new(database_url.trim_start_matches("sqlite://")).parent() {
        std::fs::create_dir_all(parent).map_err(|e| {
            error!("Failed to create database directory: {}", e);
            sqlx::Error::Io(std::io::Error::other(
                format!("Failed to create database directory: {}", e),
            ))
        })?;
    }

    // 配置连接选项
    let options = SqliteConnectOptions::new()
        .filename(database_url.trim_start_matches("sqlite://"))
        .create_if_missing(true)
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal)
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

    // 执行迁移
    info!("Running database migrations...");
    match MIGRATOR.run(&pool).await {
        Ok(_) => {
            info!("Database migrations completed successfully");
        }
        Err(e) => {
            error!("Failed to run migrations: {}", e);
            return Err(sqlx::Error::Migrate(Box::new(e)));
        }
    }

    Ok(pool)
}

/// 获取数据库连接
///
/// 从连接池获取一个连接
pub async fn get_conn(pool: &DbPool) -> Result<sqlx::pool::PoolConnection<sqlx::Sqlite>, sqlx::Error> {
    pool.acquire().await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_init_db() {
        let pool = init_db("sqlite::memory:").await.unwrap();
        assert!(!pool.is_closed());
    }
}
