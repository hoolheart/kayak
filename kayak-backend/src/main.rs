//! Kayak Backend 主入口
//!
//! 应用启动入口，负责初始化配置并启动服务器

use kayak_backend::{
    api::middleware::MiddlewareStack, api::routes::create_router, core::config::AppConfig,
    db::connection::init_db_without_migrations,
};
use sqlx::SqlitePool;
use std::net::SocketAddr;
use tokio::net::TcpListener;
use tracing::info;

/// Bootstrap the `_sqlx_migrations` table for databases that were created
/// before sqlx migrations were introduced (or have an empty `_sqlx_migrations`
/// table). We inspect which tables/triggers already exist and mark the
/// corresponding migrations as applied so that sqlx only runs the missing ones.
async fn bootstrap_legacy_migrations(pool: &SqlitePool) -> Result<(), sqlx::Error> {
    // 1. Check if `_sqlx_migrations` already exists.
    let sqlx_meta_exists: bool = sqlx::query_scalar::<_, i64>(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='_sqlx_migrations'",
    )
    .fetch_optional(pool)
    .await?
    .is_some();

    // 2. Check if the legacy `users` table exists (created by old init_db()).
    let users_exists: bool = sqlx::query_scalar::<_, i64>(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='users'",
    )
    .fetch_optional(pool)
    .await?
    .is_some();

    if !users_exists {
        // Fresh database – sqlx will create all tables from scratch.
        return Ok(());
    }

    let needs_bootstrap = if !sqlx_meta_exists {
        // Case A: _sqlx_migrations table does not exist – create it.
        sqlx::query(
            "CREATE TABLE _sqlx_migrations (
                version BIGINT PRIMARY KEY,
                description TEXT NOT NULL,
                installed_on TIMESTAMPTEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f', 'now')),
                success BOOLEAN NOT NULL,
                checksum BLOB NOT NULL,
                execution_time BIGINT NOT NULL
            )",
        )
        .execute(pool)
        .await?;
        info!("Created _sqlx_migrations table for legacy database");
        true
    } else {
        // Case B: _sqlx_migrations exists – check if it is empty.
        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM _sqlx_migrations")
            .fetch_one(pool)
            .await?;
        if count > 0 {
            // Table already populated – nothing to do.
            return Ok(());
        }
        info!("Bootstrapping empty _sqlx_migrations table");
        true
    };

    if !needs_bootstrap {
        return Ok(());
    }

    // Helper to check whether a table exists.
    async fn table_exists(pool: &SqlitePool, name: &str) -> Result<bool, sqlx::Error> {
        Ok(sqlx::query_scalar::<_, i64>(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        )
        .bind(name)
        .fetch_optional(pool)
        .await?
        .is_some())
    }

    // Helper to check whether a trigger exists.
    async fn trigger_exists(pool: &SqlitePool, name: &str) -> Result<bool, sqlx::Error> {
        Ok(sqlx::query_scalar::<_, i64>(
            "SELECT 1 FROM sqlite_master WHERE type='trigger' AND name=?",
        )
        .bind(name)
        .fetch_optional(pool)
        .await?
        .is_some())
    }

    // Collect the migrations that appear to be already applied.
    let mut migrations: Vec<(i64, &str)> = Vec::new();

    if table_exists(pool, "users").await? {
        migrations.push((20250315000001, "create_users_table"));
    }
    if table_exists(pool, "workbenches").await? {
        migrations.push((20250315000002, "create_workbenches_table"));
    }
    if table_exists(pool, "devices").await? {
        migrations.push((20250315000003, "create_devices_table"));
    }
    if table_exists(pool, "points").await? {
        migrations.push((20250315000004, "create_points_table"));
    }
    if table_exists(pool, "data_files").await? {
        migrations.push((20250315000005, "create_data_files_table"));
    }
    if trigger_exists(pool, "update_users_timestamp").await? {
        migrations.push((20250315000006, "create_updated_at_triggers"));
    }
    if table_exists(pool, "experiments").await? {
        migrations.push((20250315000007, "create_experiments_table"));
    }
    if table_exists(pool, "methods").await? {
        migrations.push((20250401000001, "create_methods_table"));
    }
    if table_exists(pool, "state_change_logs").await? {
        migrations.push((20260402000001, "add_state_change_logs"));
    }

    // Seed migration: check if the default admin user exists.
    let admin_exists: bool = sqlx::query_scalar::<_, i64>(
        "SELECT 1 FROM users WHERE email = 'admin@kayak.local' LIMIT 1",
    )
    .fetch_optional(pool)
    .await?
    .is_some();
    if admin_exists {
        migrations.push((20260406000001, "seed_admin_user"));
    }

    // Release 2 migrations – only mark them applied if their tables exist.
    if table_exists(pool, "teams").await? {
        migrations.push((20260510233248, "create_teams_table"));
    }
    if table_exists(pool, "team_members").await? {
        migrations.push((20260510233249, "create_team_members_table"));
    }
    if table_exists(pool, "team_invitations").await? {
        migrations.push((20260510233250, "create_team_invitations_table"));
    }
    if table_exists(pool, "experiments").await? {
        migrations.push((20260510233251, "add_experiment_ownership"));
    }
    if table_exists(pool, "methods").await? {
        migrations.push((20260511000005, "add_methods_ownership"));
    }
    // The normalization migration updates data; if workbenches exists and
    // no legacy 'user' owner_type remains, assume it was applied.
    if table_exists(pool, "workbenches").await? {
        let has_legacy_owner: bool = sqlx::query_scalar::<_, i64>(
            "SELECT 1 FROM workbenches WHERE owner_type = 'user' LIMIT 1",
        )
        .fetch_optional(pool)
        .await?
        .is_some();
        if !has_legacy_owner {
            migrations.push((20260511000006, "normalize_workbench_owner_type"));
        }
    }
    if table_exists(pool, "team_invitations").await? {
        migrations.push((20260511000007, "add_invitations_partial_index"));
    }

    // Build a lookup from version to checksum using the embedded migrator.
    let migrator = sqlx::migrate!("./migrations");
    let checksums: std::collections::HashMap<i64, &[u8]> = migrator
        .migrations
        .iter()
        .map(|m| (m.version, m.checksum.as_ref()))
        .collect();

    for (version, description) in &migrations {
        let checksum = checksums
            .get(version)
            .copied()
            .unwrap_or(b"\x00");
        sqlx::query(
            "INSERT INTO _sqlx_migrations
             (version, description, installed_on, success, checksum, execution_time)
             VALUES (?, ?, strftime('%Y-%m-%d %H:%M:%f', 'now'), 1, ?, 0)",
        )
        .bind(version)
        .bind(description)
        .bind(checksum)
        .execute(pool)
        .await?;
    }

    info!(
        "Marked {} legacy/partial migrations as applied",
        migrations.len()
    );
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 1. 加载环境变量
    dotenvy::dotenv().ok();

    // 2. 加载配置
    let config = AppConfig::load()?;

    // 3. 初始化日志系统
    kayak_backend::core::log::init_logging(&config.log)?;

    info!("Starting Kayak Backend v{}", env!("CARGO_PKG_VERSION"));

    // 4. 初始化数据库连接池（不运行表初始化，完全依赖 sqlx 迁移）
    let database_url =
        std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://./data/kayak.db".to_string());
    let pool = init_db_without_migrations(&database_url).await?;

    // 4.5. Bootstrap legacy migrations (if needed) then run sqlx migrations
    info!("Running database migrations...");
    bootstrap_legacy_migrations(&pool).await.map_err(|e| {
        tracing::error!("Failed to bootstrap legacy migrations: {}", e);
        e
    })?;
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to run database migrations: {}", e);
            e
        })?;
    info!("Database migrations completed successfully");

    // 5. 创建路由
    let app = create_router(pool);

    // 6. 应用中间件
    let app = MiddlewareStack::apply(app, &config);

    // 7. 绑定地址
    let bind_addr = config.bind_address();
    info!("Binding to {}", bind_addr);

    let listener = TcpListener::bind(&bind_addr).await?;
    let actual_addr = listener.local_addr()?;

    info!("Server listening on http://{}", actual_addr);

    // 8. 启动服务
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await?;

    Ok(())
}
