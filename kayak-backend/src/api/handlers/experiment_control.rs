//! Experiment Control API Handlers
//!
//! Provides REST API endpoints for experiment lifecycle control:
//! load, start, pause, resume, stop, get_status, get_history.

use std::sync::Arc;

use axum::{
    extract::{Path, State},
    Json,
};
use uuid::Uuid;

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::db::repository::experiment_repo::SqlxExperimentRepository;
use crate::db::repository::method_repo::SqlxMethodRepository;
use crate::db::repository::state_change_log_repo::SqlxStateChangeLogRepository;
use crate::services::experiment_control::{
    ExperimentControlDto, ExperimentControlError, ExperimentControlService, ExperimentStatusDto,
    StateChangeLogDto,
};

/// Application state for experiment control handlers
pub type AppState = Arc<
    ExperimentControlService<
        SqlxExperimentRepository,
        SqlxMethodRepository,
        SqlxStateChangeLogRepository,
    >,
>;

/// Request DTO for loading an experiment with a method
#[derive(Debug, serde::Deserialize)]
pub struct LoadExperimentRequest {
    pub method_id: Uuid,
}

/// Load experiment handler
///
/// POST /api/v1/experiments/{id}/load
///
/// Loads a method into the experiment, transitioning it from Idle to Loaded state.
pub async fn load_experiment(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(experiment_id): Path<Uuid>,
    Json(payload): Json<LoadExperimentRequest>,
) -> Result<Json<ApiResponse<ExperimentControlDto>>, AppError> {
    let result = handler
        .load(experiment_id, payload.method_id, user_ctx.user_id)
        .await
        .map_err(map_experiment_control_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Start experiment handler
///
/// POST /api/v1/experiments/{id}/start
///
/// Starts the experiment, transitioning it from Loaded to Running state.
pub async fn start_experiment(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(experiment_id): Path<Uuid>,
) -> Result<Json<ApiResponse<ExperimentControlDto>>, AppError> {
    let result = handler
        .start(experiment_id, user_ctx.user_id)
        .await
        .map_err(map_experiment_control_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Pause experiment handler
///
/// POST /api/v1/experiments/{id}/pause
///
/// Pauses the experiment, transitioning it from Running to Paused state.
pub async fn pause_experiment(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(experiment_id): Path<Uuid>,
) -> Result<Json<ApiResponse<ExperimentControlDto>>, AppError> {
    let result = handler
        .pause(experiment_id, user_ctx.user_id)
        .await
        .map_err(map_experiment_control_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Resume experiment handler
///
/// POST /api/v1/experiments/{id}/resume
///
/// Resumes the experiment, transitioning it from Paused to Running state.
pub async fn resume_experiment(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(experiment_id): Path<Uuid>,
) -> Result<Json<ApiResponse<ExperimentControlDto>>, AppError> {
    let result = handler
        .resume(experiment_id, user_ctx.user_id)
        .await
        .map_err(map_experiment_control_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Stop experiment handler
///
/// POST /api/v1/experiments/{id}/stop
///
/// Stops the experiment, transitioning it from Running or Paused to Loaded state.
pub async fn stop_experiment(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(experiment_id): Path<Uuid>,
) -> Result<Json<ApiResponse<ExperimentControlDto>>, AppError> {
    let result = handler
        .stop(experiment_id, user_ctx.user_id)
        .await
        .map_err(map_experiment_control_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Get experiment status handler
///
/// GET /api/v1/experiments/{id}/status
///
/// Returns the current status of the experiment.
pub async fn get_experiment_status(
    State(handler): State<AppState>,
    RequireAuth(_user_ctx): RequireAuth,
    Path(experiment_id): Path<Uuid>,
) -> Result<Json<ApiResponse<ExperimentStatusDto>>, AppError> {
    let result = handler
        .get_status(experiment_id)
        .await
        .map_err(map_experiment_control_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Get experiment history handler
///
/// GET /api/v1/experiments/{id}/history
///
/// Returns the state change history for the experiment.
pub async fn get_experiment_history(
    State(handler): State<AppState>,
    RequireAuth(_user_ctx): RequireAuth,
    Path(experiment_id): Path<Uuid>,
) -> Result<Json<ApiResponse<Vec<StateChangeLogDto>>>, AppError> {
    let result = handler
        .get_history(experiment_id)
        .await
        .map_err(map_experiment_control_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Maps ExperimentControlError to AppError
fn map_experiment_control_error(error: ExperimentControlError) -> AppError {
    match error {
        ExperimentControlError::NotFound(id) => {
            AppError::NotFound(format!("Experiment not found: {}", id))
        }
        ExperimentControlError::MethodNotFound(id) => {
            AppError::NotFound(format!("Method not found: {}", id))
        }
        ExperimentControlError::InvalidTransition(msg) => AppError::BadRequest(msg),
        ExperimentControlError::OperationNotAllowed(msg) => AppError::BadRequest(msg),
        ExperimentControlError::Repository(msg) => AppError::DatabaseError(msg),
        ExperimentControlError::ConcurrentConflict => {
            AppError::Conflict("Concurrent modification conflict".to_string())
        }
        ExperimentControlError::Forbidden(msg) => AppError::Forbidden(msg),
    }
}
