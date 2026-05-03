//! 路由定义
//!
//! 定义应用的所有HTTP路由

use std::sync::Arc;

use axum::{
    routing::{delete, get, post, put},
    Router,
};
use tower_http::services::{ServeDir, ServeFile};

use crate::api::handlers::device;
use crate::api::handlers::experiment_control;
use crate::api::handlers::experiment_ws;
use crate::api::handlers::health;
use crate::api::handlers::method;
use crate::api::handlers::method::MethodServiceAdapter;
use crate::api::handlers::point;
use crate::api::handlers::user;
use crate::api::handlers::workbench;
use crate::api::middleware::error::not_found_handler;
use crate::auth::{
    handlers::{get_authenticated_user, login, refresh_token, register},
    services::{AuthServiceImpl, BcryptPasswordHasher, JwtTokenService},
    user_repo_adapter::UserRepositoryAdapter,
};
use crate::db::connection::DbPool;
use crate::db::repository::device_repo::SqlxDeviceRepository;
use crate::db::repository::experiment_repo::SqlxExperimentRepository;
use crate::db::repository::method_repo::SqlxMethodRepository;
use crate::db::repository::point_repo::SqlxPointRepository;
use crate::db::repository::state_change_log_repo::SqlxStateChangeLogRepository;
use crate::db::repository::user_repo::UserRepository;
use crate::db::repository::workbench_repo::SqlxWorkbenchRepository;
use crate::drivers::DeviceManager;
use crate::services::device::{DeviceService, DeviceServiceImpl};
use crate::services::experiment_control::ExperimentControlService;
use crate::services::method_service::{MethodService, MethodServiceTrait};
use crate::services::point::{PointService, PointServiceImpl};
use crate::services::user::{UserService, UserServiceImpl};
use crate::services::user_repo_adapter::UserServiceRepositoryAdapter;
use crate::services::workbench::{WorkbenchService, WorkbenchServiceImpl};

/// 创建设备管理器（全局单例）
fn create_device_manager() -> Arc<DeviceManager> {
    Arc::new(DeviceManager::new())
}

/// 创建应用路由
pub fn create_router(pool: DbPool) -> Router<()> {
    // 创建基础组件
    let user_repo = UserRepository::new(pool.clone());
    let user_service_repo_adapter = Arc::new(UserServiceRepositoryAdapter::new(user_repo));

    let token_service = Arc::new(JwtTokenService::new(
        std::env::var("JWT_ACCESS_SECRET")
            .unwrap_or_else(|_| "default_access_secret_change_in_production".to_string()),
        std::env::var("JWT_REFRESH_SECRET")
            .unwrap_or_else(|_| "default_refresh_secret_change_in_production".to_string()),
    ));

    let password_hasher = Arc::new(BcryptPasswordHasher);

    // 创建认证服务
    let user_repo_adapter = Arc::new(UserRepositoryAdapter::new(UserRepository::new(
        pool.clone(),
    )));
    let auth_service = Arc::new(AuthServiceImpl::new(
        user_repo_adapter,
        token_service,
        password_hasher.clone(),
    ));

    // 创建用户服务
    let user_service: Arc<dyn UserService> = Arc::new(UserServiceImpl::new(
        user_service_repo_adapter,
        password_hasher,
    ));

    // 创建工作台服务
    let workbench_repo = SqlxWorkbenchRepository::new(pool.clone());
    let workbench_repo_for_device = workbench_repo.clone();
    let workbench_repo_for_point = workbench_repo.clone();
    let workbench_service: Arc<dyn WorkbenchService> =
        Arc::new(WorkbenchServiceImpl::new(Arc::new(workbench_repo)));

    // 创建设备管理器
    let device_manager = create_device_manager();

    // 创建设备仓储
    let device_repo: Arc<dyn crate::db::repository::device_repo::DeviceRepository> =
        Arc::new(SqlxDeviceRepository::new(pool.clone()));
    let point_repo: Arc<dyn crate::db::repository::point_repo::PointRepository> =
        Arc::new(SqlxPointRepository::new(pool.clone()));

    // 创建设备服务
    let device_service: Arc<dyn DeviceService> = Arc::new(DeviceServiceImpl::new(
        device_repo.clone(),
        point_repo.clone(),
        Arc::new(workbench_repo_for_device),
        device_manager.clone(),
    ));

    // 创建测点服务
    let point_service: Arc<dyn PointService> = Arc::new(PointServiceImpl::new(
        device_repo.clone(),
        point_repo.clone(),
        Arc::new(workbench_repo_for_point),
        device_manager.clone(),
    ));

    // 创建WebSocket管理器（共享实例）
    let ws_manager =
        std::sync::Arc::new(crate::services::experiment_control::ExperimentWsManager::new());

    // 创建试验控制服务
    let experiment_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let state_change_log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let experiment_control_service: Arc<
        ExperimentControlService<
            SqlxExperimentRepository,
            SqlxMethodRepository,
            SqlxStateChangeLogRepository,
        >,
    > = Arc::new(ExperimentControlService::with_ws_manager(
        experiment_repo,
        method_repo,
        state_change_log_repo,
        ws_manager.clone(),
    ));

    // 创建WebSocket状态（使用同一个ws_manager）
    let ws_state = experiment_ws::AppState::with_ws_manager(ws_manager);

    // 创建方法服务
    let method_repo_for_service = SqlxMethodRepository::new(pool.clone());
    let method_service_impl = MethodService::new(method_repo_for_service);
    let method_service: Arc<dyn MethodServiceTrait> =
        Arc::new(MethodServiceAdapter::new(method_service_impl));

    // 静态文件服务目录 (Flutter Web build output)
    let static_dir = std::env::var("KAYAK_SERVE_STATIC")
        .unwrap_or_else(|_| "../kayak-frontend/build/web".to_string());

    let serve_dir =
        ServeDir::new(&static_dir).fallback(ServeFile::new(format!("{}/index.html", static_dir)));

    // API路由组（使用独立的404处理器）
    let api_router = Router::new()
        // 健康检查（最优先，无中间件限制）
        .merge(health_routes())
        // WebSocket路由（使用自己的状态）
        .merge(ws_routes(ws_state))
        // API路由
        .merge(auth_routes(auth_service))
        .merge(user_routes(user_service))
        .merge(workbench_routes(workbench_service))
        .merge(device_routes(device_service))
        .merge(point_routes(point_service))
        .merge(method_routes(method_service))
        .merge(experiment_control_routes(experiment_control_service))
        // API 404处理
        .fallback(not_found_handler);

    // 顶层路由：API优先，未匹配的由静态文件服务处理（SPA fallback）
    Router::new().merge(api_router).fallback_service(serve_dir)
}

/// 认证路由组
fn auth_routes<S>(auth_service: Arc<S>) -> Router<()>
where
    S: crate::auth::traits::AuthService + 'static,
{
    Router::new().nest(
        "/api/v1/auth",
        Router::new()
            .route("/register", post(register::<S>))
            .route("/login", post(login::<S>))
            .route("/refresh", post(refresh_token::<S>))
            .route("/me", get(get_authenticated_user::<S>))
            .with_state(auth_service),
    )
}

/// 用户路由组
fn user_routes(user_service: Arc<dyn UserService>) -> Router<()> {
    Router::new().nest(
        "/api/v1/users",
        Router::new()
            .route("/me", get(get_current_user))
            .route("/me", put(update_current_user))
            .route("/me/password", post(change_password))
            .with_state(user_service),
    )
}

/// 工作台路由组
fn workbench_routes(workbench_service: Arc<dyn WorkbenchService>) -> Router<()> {
    Router::new().nest(
        "/api/v1/workbenches",
        Router::new()
            .route("/", post(workbench::create_workbench))
            .route("/", get(workbench::list_workbenches))
            .route("/{id}", get(workbench::get_workbench))
            .route("/{id}", put(workbench::update_workbench))
            .route("/{id}", delete(workbench::delete_workbench))
            .with_state(workbench_service),
    )
}

/// 设备路由组
fn device_routes(device_service: Arc<dyn DeviceService>) -> Router<()> {
    Router::new().nest(
        "/api/v1",
        Router::new()
            // 设备路由（嵌套在工作台下）
            .route(
                "/workbenches/{workbench_id}/devices",
                post(device::create_device),
            )
            .route(
                "/workbenches/{workbench_id}/devices",
                get(device::list_devices),
            )
            // 独立设备路由
            .route("/devices/{id}", get(device::get_device))
            .route("/devices/{id}", put(device::update_device))
            .route("/devices/{id}", delete(device::delete_device))
            .with_state(device_service),
    )
}

/// 测点路由组
fn point_routes(point_service: Arc<dyn PointService>) -> Router<()> {
    Router::new().nest(
        "/api/v1",
        Router::new()
            // 测点路由（嵌套在设备下）
            .route("/devices/{device_id}/points", post(point::create_point))
            .route("/devices/{device_id}/points", get(point::list_points))
            // 独立测点路由
            .route("/points/{id}", get(point::get_point))
            .route("/points/{id}", put(point::update_point))
            .route("/points/{id}", delete(point::delete_point))
            // 测点值路由
            .route("/points/{id}/value", get(point::read_point_value))
            .route("/points/{id}/value", put(point::write_point_value))
            .with_state(point_service),
    )
}

// Re-export for use in tests or other modules
pub use experiment_control::{
    get_experiment_history, get_experiment_status, load_experiment, pause_experiment,
    resume_experiment, start_experiment, stop_experiment,
};
pub use user::{change_password, get_current_user, update_current_user};
pub use workbench::{
    create_workbench, delete_workbench, get_workbench, list_workbenches, update_workbench,
};

/// 方法路由组 (C2 fix: /validate路由放在/{id}路由之前，避免路径匹配冲突)
fn method_routes(method_service: Arc<dyn MethodServiceTrait>) -> Router<()> {
    Router::new().nest(
        "/api/v1/methods",
        Router::new()
            .route("/", post(method::create_method))
            .route("/", get(method::list_methods))
            .route("/validate", post(method::validate_method))
            .route("/{id}", get(method::get_method))
            .route("/{id}", put(method::update_method))
            .route("/{id}", delete(method::delete_method))
            .with_state(method_service),
    )
}

/// 试验控制路由组
fn experiment_control_routes(
    experiment_control_service: Arc<
        ExperimentControlService<
            SqlxExperimentRepository,
            SqlxMethodRepository,
            SqlxStateChangeLogRepository,
        >,
    >,
) -> Router<()> {
    Router::new().nest(
        "/api/v1/experiments",
        Router::new()
            .route("/{id}/load", post(load_experiment))
            .route("/{id}/start", post(start_experiment))
            .route("/{id}/pause", post(pause_experiment))
            .route("/{id}/resume", post(resume_experiment))
            .route("/{id}/stop", post(stop_experiment))
            .route("/{id}/status", get(get_experiment_status))
            .route("/{id}/history", get(get_experiment_history))
            .with_state(experiment_control_service),
    )
}

/// WebSocket路由组
fn ws_routes(ws_state: experiment_ws::AppState) -> Router<()> {
    Router::new()
        .route("/ws/experiments/{id}", get(experiment_ws::ws_handler))
        .with_state(ws_state)
}

/// 获取健康检查路由（用于测试）
pub fn health_routes() -> Router<()> {
    Router::new().route("/health", get(health::health_check))
}
