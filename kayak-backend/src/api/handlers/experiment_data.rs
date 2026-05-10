//! Experiment data API handlers
//!
//! Provides REST API endpoints for querying experiment time-series data from HDF5 files.

use std::sync::Arc;

use axum::{
    extract::{Path, State},
    Json,
};
use uuid::Uuid;
use validator::Validate;

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError, FieldError};
use crate::models::dto::experiment_data_query::{
    ExperimentDataQueryRequest, ExperimentDataResponse,
};
use crate::services::experiment_data::ExperimentDataService;

/// POST /api/v1/experiments/{id}/data/query
///
/// Query experiment time-series data from HDF5 storage.
///
/// Only experiments with status `completed` or `aborted` can be queried.
/// Running or paused experiments will return HTTP 409 Conflict.
///
/// # Request Body
/// ```json
/// {
///   "device_id": "550e8400-e29b-41d4-a716-446655440000",
///   "point_ids": ["550e8400-e29b-41d4-a716-446655440001", "550e8400-e29b-41d4-a716-446655440002"],
///   "start_time": "2024-05-01T00:00:00Z",
///   "end_time": "2024-05-02T00:00:00Z",
///   "downsample": 1000
/// }
/// ```
pub async fn query_experiment_data(
    Path(experiment_id): Path<String>,
    State(service): State<Arc<dyn ExperimentDataService>>,
    RequireAuth(user_ctx): RequireAuth,
    Json(body): Json<ExperimentDataQueryRequest>,
) -> Result<Json<ApiResponse<ExperimentDataResponse>>, AppError> {
    // Parse experiment ID
    let exp_id = Uuid::parse_str(&experiment_id)
        .map_err(|_| AppError::BadRequest("Invalid experiment ID format".to_string()))?;

    // Validate request body using validator
    body.validate().map_err(|e: validator::ValidationErrors| {
        let mut fields: Vec<FieldError> = Vec::new();
        for (field, kind) in e.errors() {
            if let validator::ValidationErrorsKind::Field(errors) = kind {
                for err in errors {
                    fields.push(FieldError::new(
                        *field,
                        err.message
                            .as_ref()
                            .map(|m| m.to_string())
                            .unwrap_or_else(|| "validation failed".to_string()),
                    ));
                }
            }
        }
        AppError::validation_error(fields)
    })?;

    // Validate time range
    match (body.start_time, body.end_time) {
        (Some(start), Some(end)) => {
            if start > end {
                return Err(AppError::BadRequest(
                    "start_time must be before end_time".to_string(),
                ));
            }
            let time_window = end.timestamp_millis() - start.timestamp_millis();
            let max_window = 30_i64 * 24 * 3600 * 1000; // 30 days in milliseconds
            if time_window > max_window {
                return Err(AppError::BadRequest(
                    "Query time range must not exceed 30 days".to_string(),
                ));
            }
        }
        (Some(start), None) => {
            if start > Utc::now() {
                return Err(AppError::BadRequest(
                    "start_time must not be in the future".to_string(),
                ));
            }
        }
        (None, Some(end)) => {
            if end > Utc::now() {
                return Err(AppError::BadRequest(
                    "end_time must not be in the future".to_string(),
                ));
            }
        }
        (None, None) => {}
    }

    // Call service
    let response = service
        .query_experiment_data(exp_id, body, user_ctx.user_id)
        .await?;

    Ok(Json(ApiResponse::success(response)))
}
