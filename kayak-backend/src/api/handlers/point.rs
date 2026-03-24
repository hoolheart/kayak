//! 测点请求处理器

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::drivers::PointValue;
use crate::models::entities::point::{
    CreatePointRequest, UpdatePointRequest, WritePointValueRequest,
};
use crate::services::point::{
    CreatePointEntity, PagedPointDto, PointDto, PointError, PointService, PointValueDto,
    UpdatePointEntity,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

/// 应用状态类型
type AppState = Arc<dyn PointService>;

/// POST /api/v1/devices/{device_id}/points - 创建测点
pub async fn create_point(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(device_id): Path<Uuid>,
    Json(req): Json<CreatePointRequest>,
) -> Result<Json<ApiResponse<PointDto>>, AppError> {
    let entity = CreatePointEntity {
        device_id,
        name: req.name,
        data_type: req.data_type,
        access_type: req.access_type,
        unit: req.unit,
        description: None,
        min_value: req.min_value,
        max_value: req.max_value,
        default_value: req.default_value,
    };

    let point = handler
        .create_point(user_ctx.user_id, entity)
        .await
        .map_err(|e| match e {
            PointError::DeviceNotFound => AppError::NotFound("Device not found".to_string()),
            PointError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            PointError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::created(point)))
}

/// GET /api/v1/devices/{device_id}/points - 查询测点列表
pub async fn list_points(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(device_id): Path<Uuid>,
    Query(query): Query<ListPointsQuery>,
) -> Result<Json<ApiResponse<PagedPointDto>>, AppError> {
    let page = query.page.unwrap_or(1);
    let size = query.size.unwrap_or(10);

    let result = handler
        .list_points(user_ctx.user_id, device_id, page, size)
        .await
        .map_err(|e| match e {
            PointError::DeviceNotFound => AppError::NotFound("Device not found".to_string()),
            PointError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(result)))
}

/// GET /api/v1/points/{id} - 获取测点详情
pub async fn get_point(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<PointDto>>, AppError> {
    let point = handler
        .get_point(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            PointError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(point)))
}

/// PUT /api/v1/points/{id} - 更新测点
pub async fn update_point(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdatePointRequest>,
) -> Result<Json<ApiResponse<PointDto>>, AppError> {
    let entity = UpdatePointEntity {
        name: req.name,
        unit: req.unit,
        description: None,
        min_value: req.min_value,
        max_value: req.max_value,
        default_value: req.default_value,
        status: req.status,
    };

    let point = handler
        .update_point(user_ctx.user_id, id, entity)
        .await
        .map_err(|e| match e {
            PointError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            PointError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(point)))
}

/// DELETE /api/v1/points/{id} - 删除测点
pub async fn delete_point(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    handler
        .delete_point(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            PointError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(StatusCode::NO_CONTENT)
}

/// GET /api/v1/points/{id}/value - 读取测点值
pub async fn read_point_value(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<PointValueDto>>, AppError> {
    let value = handler
        .read_point_value(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            PointError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            PointError::DeviceNotConnected => {
                AppError::BadRequest("Device not connected".to_string())
            }
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(value)))
}

/// PUT /api/v1/points/{id}/value - 写入测点值
pub async fn write_point_value(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    Json(req): Json<WritePointValueRequest>,
) -> Result<Json<ApiResponse<()>>, AppError> {
    // 将请求中的值转换为PointValue
    let value = PointValue::Number(req.value);

    handler
        .write_point_value(user_ctx.user_id, id, value)
        .await
        .map_err(|e| match e {
            PointError::NotFound => AppError::NotFound("Point not found".to_string()),
            PointError::AccessDenied => AppError::Forbidden("Access denied".to_string()),
            PointError::ReadOnlyPoint => AppError::BadRequest("Point is read-only".to_string()),
            PointError::DeviceNotConnected => {
                AppError::BadRequest("Device not connected".to_string())
            }
            PointError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(())))
}

#[derive(Debug, serde::Deserialize)]
pub struct ListPointsQuery {
    pub page: Option<i64>,
    pub size: Option<i64>,
}
