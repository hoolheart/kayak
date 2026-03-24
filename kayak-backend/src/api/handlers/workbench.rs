//! 工作台请求处理器

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::models::entities::workbench::{CreateWorkbenchRequest, UpdateWorkbenchRequest};
use crate::services::workbench::{
    CreateWorkbenchEntity, ListWorkbenchesQuery, PagedWorkbenchDto, UpdateWorkbenchEntity,
    WorkbenchDto, WorkbenchError, WorkbenchService,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

/// 应用状态类型
type AppState = Arc<dyn WorkbenchService>;

/// POST /api/v1/workbenches - 创建工作台
pub async fn create_workbench(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Json(req): Json<CreateWorkbenchRequest>,
) -> Result<Json<ApiResponse<WorkbenchDto>>, AppError> {
    let entity = CreateWorkbenchEntity {
        name: req.name,
        description: req.description,
        owner_type: req.owner_type,
        owner_id: user_ctx.user_id,
    };

    let workbench = handler
        .create_workbench(user_ctx.user_id, entity)
        .await
        .map_err(|e| match e {
            WorkbenchError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::created(workbench)))
}

/// GET /api/v1/workbenches - 列表查询
pub async fn list_workbenches(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Query(query): Query<ListWorkbenchesQuery>,
) -> Result<Json<ApiResponse<PagedWorkbenchDto>>, AppError> {
    let page = query.page;
    let size = query.size;

    let result = handler
        .list_workbenches(user_ctx.user_id, page, size)
        .await
        .map_err(|e| match e {
            WorkbenchError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(result)))
}

/// GET /api/v1/workbenches/{id} - 详情查询
pub async fn get_workbench(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<WorkbenchDto>>, AppError> {
    let workbench = handler
        .get_workbench(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            WorkbenchError::NotFound => AppError::NotFound("Workbench not found".to_string()),
            WorkbenchError::AccessDenied => {
                AppError::Forbidden("Access denied: you do not own this workbench".to_string())
            }
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(workbench)))
}

/// PUT /api/v1/workbenches/{id} - 更新工作台
pub async fn update_workbench(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdateWorkbenchRequest>,
) -> Result<Json<ApiResponse<WorkbenchDto>>, AppError> {
    let entity = UpdateWorkbenchEntity {
        name: req.name,
        description: req.description,
        status: req.status,
    };

    let workbench = handler
        .update_workbench(user_ctx.user_id, id, entity)
        .await
        .map_err(|e| match e {
            WorkbenchError::NotFound => AppError::NotFound("Workbench not found".to_string()),
            WorkbenchError::AccessDenied => {
                AppError::Forbidden("Access denied: you do not own this workbench".to_string())
            }
            WorkbenchError::ValidationError(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(workbench)))
}

/// DELETE /api/v1/workbenches/{id} - 删除工作台
pub async fn delete_workbench(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    handler
        .delete_workbench(user_ctx.user_id, id)
        .await
        .map_err(|e| match e {
            WorkbenchError::NotFound => AppError::NotFound("Workbench not found".to_string()),
            WorkbenchError::AccessDenied => {
                AppError::Forbidden("Access denied: you do not own this workbench".to_string())
            }
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(StatusCode::NO_CONTENT)
}
