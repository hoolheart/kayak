//! Kayak Backend 主入口
//!
//! 应用启动入口，负责初始化配置并启动服务器

use kayak_backend::{
    api::middleware::MiddlewareStack, api::routes::create_router, core::config::AppConfig,
    db::connection::init_db_without_migrations,
};
use std::net::SocketAddr;
use tokio::net::TcpListener;
use tracing::info;

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

    // 4.5. Run sqlx migrations
    info!("Running database migrations...");
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
