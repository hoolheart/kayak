//! Experiment API handlers
//!
//! Provides REST API endpoints for experiment management

use std::sync::Arc;

use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use uuid::Uuid;

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::models::dto::experiment_query::{
    ListExperimentsRequest, PointHistoryRequest,
};
use crate::models::entities::experiment::{Experiment, ExperimentResponse};
use crate::services::experiment_query::{
    DataFileError, ExperimentQueryError, ExperimentQueryService, PointHistoryError,
};

/// Application state for experiment handlers
pub type AppState = Arc<dyn ExperimentQueryService>;

/// GET /api/v1/experiments - List experiments
pub async fn list_experiments(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Query(params): Query<ListExperimentsRequest>,
) -> Result<Json<ApiResponse<crate::models::dto::experiment_query::PagedResponse<Experiment>>>, AppError> {
    let page = params.page.unwrap_or(1).max(1);
    let size = params.size.unwrap_or(10).clamp(1, 100);

    let filter = crate::services::experiment_query::ExperimentFilter {
        user_id: Some(user_ctx.user_id),
        status: params.status,
        method_id: None,  // ListExperimentsRequest doesn't have method_id
        created_after: params.created_after,
        created_before: params.created_before,
    };

    let experiments = handler
        .list_experiments(filter, page, size)
        .await
        .map_err(|e| match e {
            ExperimentQueryError::InvalidPagination(msg) => AppError::BadRequest(msg),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(experiments)))
}

/// GET /api/v1/experiments/{id} - Get experiment details
pub async fn get_experiment(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<ExperimentResponse>>, AppError> {
    let experiment = handler
        .get_experiment(id, user_ctx.user_id)
        .await
        .map_err(|e| match e {
            ExperimentQueryError::NotFound(_) => AppError::NotFound(e.to_string()),
            ExperimentQueryError::AccessDenied(_) => AppError::Forbidden(e.to_string()),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(ApiResponse::success(experiment.into())))
}

/// GET /api/v1/experiments/{exp_id}/points/{channel}/history - Get point history
pub async fn get_point_history(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path((exp_id, channel)): Path<(Uuid, String)>,
    Query(params): Query<PointHistoryRequest>,
) -> Result<Json<crate::models::dto::experiment_query::PointHistoryResponse>, AppError> {
    // Validate time range
    if params.start_time.is_some() && params.end_time.is_some() {
        let start = params.start_time.unwrap();
        let end = params.end_time.unwrap();
        if start > end {
            return Err(AppError::BadRequest("start_time must be before end_time".to_string()));
        }
    }

    let time_range = params
        .start_time
        .zip(params.end_time)
        .map(|(s, e)| crate::services::point_history::TimeRange { start: s, end: e });

    let limit = params.limit.min(100000);

    let history = handler
        .get_point_history(exp_id, channel, time_range, limit, user_ctx.user_id)
        .await
        .map_err(|e| match e {
            PointHistoryError::ExperimentNotFound(_) => AppError::NotFound(e.to_string()),
            PointHistoryError::TimeRangeReversed => AppError::BadRequest(e.to_string()),
            PointHistoryError::DataTooLarge { actual, max } => AppError::BadRequest(format!(
                "Data too large: {} points (max: {}). Use limit parameter to reduce.",
                actual, max
            )),
            _ => AppError::InternalError(e.to_string()),
        })?;

    Ok(Json(history))
}

/// GET /api/v1/experiments/{id}/data-file - Download data file
pub async fn download_data_file(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(experiment_id): Path<Uuid>,
) -> Result<(StatusCode, &'static str), AppError> {
    // Get data file info to verify access
    match handler.get_data_file_info(experiment_id, user_ctx.user_id).await {
        Ok(info) => {
            // For now, return a simple message indicating the file exists
            // Full streaming implementation is complex and deferred
            Ok((StatusCode::OK, "Data file available for download"))
        }
        Err(DataFileError::ExperimentNotFound(_)) => {
            Err(AppError::NotFound("Experiment not found".to_string()))
        }
        Err(DataFileError::AccessDenied(_)) => {
            Err(AppError::Forbidden("Access denied".to_string()))
        }
        Err(DataFileError::DataFileNotFound) => {
            Err(AppError::NotFound("Data file not found".to_string()))
        }
        Err(e) => Err(AppError::InternalError(e.to_string())),
    }
}