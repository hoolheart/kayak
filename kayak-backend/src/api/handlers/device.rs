//! 设备请求处理器

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::models::entities::device::{CreateDeviceRequest, UpdateDeviceRequest};
use crate::services::device::{
    CreateDeviceEntity, DeviceDto, DeviceError, DeviceService, PagedDeviceDto, UpdateDeviceEntity,
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

#[derive(Debug, serde::Deserialize)]
pub struct ListDevicesQuery {
    pub page: Option<i64>,
    pub size: Option<i64>,
    pub parent_id: Option<Uuid>,
}
