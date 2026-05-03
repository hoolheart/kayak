//! 设备请求处理器

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::models::entities::device::{CreateDeviceRequest, UpdateDeviceRequest};
use crate::services::device::{
    CreateDeviceEntity, DeviceConnectionStatus, DeviceDto, DeviceError, DeviceService,
    PagedDeviceDto, TestConnectionResult, UpdateDeviceEntity,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

/// 应用状态类型
type AppState = Arc<dyn DeviceService>;

/// GET /api/v1/workbenches/{workbench_id}/devices - 列表查询
pub async fn list_devices(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(workbench_id): Path<Uuid>,
    Query(query): Query<ListDevicesQuery>,
) -> Result<Json<ApiResponse<PagedDeviceDto>>, AppError> {
    let page = query.page.unwrap_or(1);
    let size = query.size.unwrap_or(10);

    let result = handler
        .list_devices(user_ctx.user_id, workbench_id, query.parent_id, page, size)
        .await
        .map_err(|e| match e {
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            DeviceError::WorkbenchNotFound => AppError::NotFound("Workbench not found".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(result)))
}

/// POST /api/v1/workbenches/{workbench_id}/devices - 创建设备
pub async fn create_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(workbench_id): Path<Uuid>,
    Json(req): Json<CreateDeviceRequest>,
) -> Result<Json<ApiResponse<DeviceDto>>, AppError> {
    let entity = CreateDeviceEntity {
        workbench_id,
        name: req.name,
        protocol_type: req.protocol_type,
        parent_id: req.parent_id,
        protocol_params: req.protocol_params,
        manufacturer: req.manufacturer,
        model: req.model,
        sn: req.sn,
    };

    let device = handler
        .create_device(user_ctx.user_id, entity)
        .await
        .map_err(|e| match e {
            DeviceError::WorkbenchNotFound => AppError::NotFound("Workbench not found".to_string()),
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            DeviceError::ValidationError(msg) => AppError::BadRequest(msg),
            DeviceError::CircularReference => {
                AppError::BadRequest("Circular reference detected".to_string())
            }
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::created(device)))
}

/// GET /api/v1/devices/{id} - 获取设备详情
pub async fn get_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<DeviceDto>>, AppError> {
    let device = handler
        .get_device(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            DeviceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(device)))
}

/// PUT /api/v1/devices/{id} - 更新设备
pub async fn update_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdateDeviceRequest>,
) -> Result<Json<ApiResponse<DeviceDto>>, AppError> {
    let entity = UpdateDeviceEntity {
        name: req.name,
        protocol_params: req.protocol_params,
        manufacturer: req.manufacturer,
        model: req.model,
        sn: req.sn,
        status: req.status,
    };

    let device = handler
        .update_device(user_ctx.user_id, id, entity)
        .await
        .map_err(|e| match e {
            DeviceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            DeviceError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(device)))
}

/// DELETE /api/v1/devices/{id} - 删除设备
pub async fn delete_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    handler
        .delete_device(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            DeviceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(StatusCode::NO_CONTENT)
}

// ============================================================
// R1-S2-005: 设备连接测试
// ============================================================

/// POST /api/v1/devices/{id}/test-connection — 测试设备连接
///
/// 创建一个临时驱动实例，尝试连接设备，测量延迟，然后断开。
/// 此操作不修改数据库设备状态，也不将驱动注册到 DeviceManager。
///
/// # Request Body (可选)
/// ```json
/// { "host": "192.168.1.100", "port": 502, "timeout_ms": 5000 }
/// ```
/// 若提供，临时覆盖设备存储的 protocol_params 用于本次测试。
/// 若未提供，使用设备数据库中已存储的 protocol_params。
pub async fn test_connection(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    // Use Option<Json> so the body is optional
    body: Option<Json<serde_json::Value>>,
) -> Result<Json<ApiResponse<TestConnectionResult>>, AppError> {
    let config_override = body.map(|Json(v)| v);

    let result = handler
        .test_device_connection(user_ctx.user_id, id, config_override)
        .await
        .map_err(|e| match e {
            DeviceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            DeviceError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(result)))
}

// ============================================================
// R1-S2-011: 设备连接/断开管理
// ============================================================

/// POST /api/v1/devices/{id}/connect — 连接设备
///
/// 将设备注册到 DeviceManager（若尚未注册），然后建立持久连接。
/// 成功时设备状态变为 Online。
pub async fn connect_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<DeviceConnectionStatus>>, AppError> {
    let result = handler
        .connect_device(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            DeviceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            DeviceError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(result)))
}

/// POST /api/v1/devices/{id}/disconnect — 断开设备连接
///
/// 断开设备持久连接。驱动实例保留在 DeviceManager 中（后续可重连）。
/// 幂等操作：对已断开的设备调用也返回成功。
pub async fn disconnect_device(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<DeviceConnectionStatus>>, AppError> {
    let result = handler
        .disconnect_device(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            DeviceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(result)))
}

/// GET /api/v1/devices/{id}/status — 查询设备连接状态
///
/// 返回设备当前的连接状态（"connected" / "disconnected" / "error"）。
/// 优先从 DeviceManager 中查询实时驱动状态；
/// 若驱动未注册，回退到数据库中的 status 字段。
pub async fn get_device_status(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<DeviceConnectionStatus>>, AppError> {
    let result = handler
        .get_device_connection_status(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            DeviceError::NotFound => AppError::NotFound("Device not found".to_string()),
            DeviceError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(result)))
}

#[derive(Debug, serde::Deserialize)]
pub struct ListDevicesQuery {
    pub page: Option<i64>,
    pub size: Option<i64>,
    pub parent_id: Option<Uuid>,
}
