//! 数据库连接管理
//!
//! 提供数据库连接池初始化和连接管理

use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{migrate::Migrator, SqlitePool};
use std::path::Path;
use tracing::{error, info, warn};

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

/// 初始化数据库表（用于不支持sqlx migrate的SQLite）
async fn init_sqlite_tables(pool: &SqlitePool) -> Result<(), sqlx::Error> {
    info!("Initializing SQLite tables...");

    // 创建 users 表
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            username TEXT,
            avatar_url TEXT,
            status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned')),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
        "#,
    )
    .execute(pool)
    .await?;

    // 创建 email 索引
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)")
        .execute(pool)
        .await?;

    info!("Users table created successfully");

    // 创建 workbenches 表
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS workbenches (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            owner_id TEXT NOT NULL,
            owner_type TEXT DEFAULT 'user' CHECK (owner_type IN ('user', 'team')),
            status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
        )
        "#,
    )
    .execute(pool)
    .await?;

    // 创建 workbenches 索引
    sqlx::query(
        "CREATE INDEX IF NOT EXISTS idx_workbenches_owner ON workbenches(owner_id, owner_type)",
    )
    .execute(pool)
    .await?;

    sqlx::query("CREATE INDEX IF NOT EXISTS idx_workbenches_status ON workbenches(status)")
        .execute(pool)
        .await?;

    info!("Workbenches table created successfully");

    // 创建 devices 表
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS devices (
            id TEXT PRIMARY KEY,
            workbench_id TEXT NOT NULL,
            parent_id TEXT,
            name TEXT NOT NULL,
            protocol_type TEXT NOT NULL,
            address TEXT,
            port INTEGER,
            virtual_parameters TEXT,
            status TEXT DEFAULT 'offline',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (workbench_id) REFERENCES workbenches(id) ON DELETE CASCADE,
            FOREIGN KEY (parent_id) REFERENCES devices(id) ON DELETE SET NULL
        )
        "#,
    )
    .execute(pool)
    .await?;

    info!("Devices table created successfully");

    // 创建 points 表
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS points (
            id TEXT PRIMARY KEY,
            device_id TEXT NOT NULL,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            access_type TEXT NOT NULL CHECK (access_type IN ('RO', 'WO', 'RW')),
            data_type TEXT NOT NULL CHECK (data_type IN ('BOOLEAN', 'INTEGER', 'NUMBER', 'STRING')),
            unit TEXT,
            min_value REAL,
            max_value REAL,
            description TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
        )
        "#,
    )
    .execute(pool)
    .await?;

    info!("Points table created successfully");

    // 创建 data_files 表
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS data_files (
            id TEXT PRIMARY KEY,
            experiment_id TEXT NOT NULL,
            channel TEXT NOT NULL,
            file_path TEXT NOT NULL,
            point_count INTEGER NOT NULL,
            start_time TEXT,
            end_time TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (experiment_id) REFERENCES experiments(id) ON DELETE CASCADE
        )
        "#,
    )
    .execute(pool)
    .await?;

    info!("Data files table created successfully");

    // 创建触发器（SQLite）
    sqlx::query(
        r#"
        CREATE TRIGGER IF NOT EXISTS update_users_timestamp 
        AFTER UPDATE ON users
        BEGIN
            UPDATE users SET updated_at = datetime('now') WHERE id = NEW.id;
        END
        "#,
    )
    .execute(pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TRIGGER IF NOT EXISTS update_workbenches_timestamp 
        AFTER UPDATE ON workbenches
        BEGIN
            UPDATE workbenches SET updated_at = datetime('now') WHERE id = NEW.id;
        END
        "#,
    )
    .execute(pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TRIGGER IF NOT EXISTS update_devices_timestamp 
        AFTER UPDATE ON devices
        BEGIN
            UPDATE devices SET updated_at = datetime('now') WHERE id = NEW.id;
        END
        "#,
    )
    .execute(pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TRIGGER IF NOT EXISTS update_points_timestamp 
        AFTER UPDATE ON points
        BEGIN
            UPDATE points SET updated_at = datetime('now') WHERE id = NEW.id;
        END
        "#,
    )
    .execute(pool)
    .await?;

    info!("Update triggers created successfully");

    Ok(())
}

/// 创建默认管理员用户
async fn create_default_admin(pool: &SqlitePool) -> Result<(), sqlx::Error> {
    info!("Creating default admin user if not exists...");

    // 检查是否已存在
    let exists: Option<(String,)> = sqlx::query_as("SELECT email FROM users WHERE email = ?")
        .bind("admin@kayak.local")
        .fetch_optional(pool)
        .await?;

    if exists.is_some() {
        info!("Admin user already exists");
        return Ok(());
    }

    // bcrypt hash for "Admin123" with cost 12
    let password_hash = "$2b$12$62qkfPu99ygDL9RkyKz.8.xBVGObeAzaZMTiJ0DV98MZREV4aA5Ae";

    sqlx::query(
        r#"
        INSERT INTO users (id, email, password_hash, username, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        "#,
    )
    .bind("00000000-0000-0000-0000-000000000001")
    .bind("admin@kayak.local")
    .bind(password_hash)
    .bind("Administrator")
    .bind("active")
    .execute(pool)
    .await?;

    info!("Default admin user created: admin@kayak.local / Admin123");

    Ok(())
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

    // 执行迁移
    if run_migrations {
        // 首先初始化表结构
        init_sqlite_tables(&pool).await?;

        // 创建默认管理员用户
        if let Err(e) = create_default_admin(&pool).await {
            warn!("Failed to create default admin user: {}. Continuing...", e);
        }
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
