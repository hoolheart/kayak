//! Kayak Backend 主入口
//!
//! 应用启动入口，负责初始化配置并启动服务器

use kayak_backend::{
    api::routes::create_router,
    api::middleware::MiddlewareStack,
    core::config::AppConfig,
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

    // 4. 创建路由
    let app = create_router();

    // 5. 应用中间件
    let app = MiddlewareStack::apply(app, &config);

    // 6. 绑定地址
    let bind_addr = config.bind_address();
    info!("Binding to {}", bind_addr);

    let listener = TcpListener::bind(&bind_addr).await?;
    let actual_addr = listener.local_addr()?;

    info!("Server listening on http://{}", actual_addr);

    // 7. 启动服务
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await?;

    Ok(())
}
