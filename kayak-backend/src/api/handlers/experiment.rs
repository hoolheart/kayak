//! Experiment API handlers
//!
//! NOTE: This is a partial implementation. The list_experiments and get_experiment
//! handlers require integration with the actual experiment repository/service.
//! The get_point_history handler is functional.

use std::path::PathBuf;
use std::sync::Arc;

use axum::{
    extract::{Path, Query, State},
    Json,
};
use chrono::{DateTime, TimeZone, Utc};
use uuid::Uuid;

use crate::models::dto::experiment_query::{
    ListExperimentsRequest, PagedResponse, PointHistoryRequest, PointHistoryResponse,
};
use crate::models::entities::experiment::Experiment;
use crate::services::experiment_query::PointHistoryError;
use crate::services::point_history::{Hdf5PointHistoryRepository, PointHistoryRepository, TimeRange};

/// Application state for experiment handlers
pub type AppState = Arc<ExperimentState>;

/// State container for experiment handlers
#[derive(Clone)]
pub struct ExperimentState {
    pub data_root: PathBuf,
}

/// GET /api/v1/experiments - List experiments
pub async fn list_experiments(
    State(_state): State<Arc<AppState>>,
    Query(params): Query<ListExperimentsRequest>,
) -> Result<Json<PagedResponse<Experiment>>, axum::http::StatusCode> {
    // TODO: Implement with actual experiment repository
    // For now, return empty list
    let page = params.page.unwrap_or(1).max(1);
    let size = params.size.unwrap_or(10).clamp(1, 100);

    Ok(Json(PagedResponse {
        items: vec![],
        page,
        size,
        total: 0,
        has_next: false,
        has_prev: false,
    }))
}

/// GET /api/v1/experiments/{id} - Get experiment details
pub async fn get_experiment(
    Path(_id): Path<Uuid>,
) -> Result<Json<Experiment>, axum::http::StatusCode> {
    // TODO: Implement with actual experiment repository
    Err(axum::http::StatusCode::NOT_IMPLEMENTED)
}

/// GET /api/v1/experiments/{exp_id}/points/{channel}/history - Get point history
pub async fn get_point_history(
    State(state): State<Arc<AppState>>,
    Path((exp_id, channel)): Path<(Uuid, String)>,
    Query(params): Query<PointHistoryRequest>,
) -> Result<Json<PointHistoryResponse>, PointHistoryError> {
    // Validate time range
    if params.start_time.is_some() && params.end_time.is_some() {
        let start = params.start_time.unwrap();
        let end = params.end_time.unwrap();
        if start > end {
            return Err(PointHistoryError::TimeRangeReversed);
        }
    }

    let time_range = params
        .start_time
        .zip(params.end_time)
        .map(|(s, e)| TimeRange { start: s, end: e });

    let limit = params.limit.min(100000);

    // Create point history repository
    let repo = Hdf5PointHistoryRepository::new(state.data_root.clone());

    // Get channel data
    let points = repo
        .get_channel_data(exp_id, &channel, time_range.clone(), limit)
        .await?;

    let total_points = points.len();
    let (start_time, end_time) = if points.is_empty() {
        (None, None)
    } else {
        let first_ts = points.first().map(|p| p.timestamp).unwrap_or(0);
        let last_ts = points.last().map(|p| p.timestamp).unwrap_or(0);
        let to_datetime = |ts: i64| -> DateTime<Utc> {
            Utc.timestamp_opt(ts / 1_000_000_000, (ts % 1_000_000_000) as u32)
                .single()
                .unwrap_or_else(Utc::now)
        };
        (Some(to_datetime(first_ts)), Some(to_datetime(last_ts)))
    };

    Ok(Json(PointHistoryResponse {
        experiment_id: exp_id,
        channel,
        data: points,
        start_time,
        end_time,
        total_points,
    }))
}

/// GET /api/v1/experiments/{id}/data-file - Download data file
pub async fn download_data_file(
    State(state): State<Arc<AppState>>,
    Path(experiment_id): Path<Uuid>,
) -> Result<axum::response::Response, PointHistoryError> {
    // Build HDF5 file path
    let file_path = state
        .data_root
        .join("experiments")
        .join(format!("{}.h5", experiment_id));

    if !file_path.exists() {
        return Err(PointHistoryError::Hdf5FileNotFound(
            file_path.to_string_lossy().to_string(),
        ));
    }

    let metadata = std::fs::metadata(&file_path)
        .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;
    let file_size = metadata.len() as i64;

    // For simplicity, return 404 - full streaming implementation requires more setup
    Err(PointHistoryError::Hdf5FileNotFound(
        "Streaming download not implemented".to_string(),
    ))
}