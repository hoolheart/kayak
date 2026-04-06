//! Experiment query service

use async_trait::async_trait;
use chrono::{DateTime, TimeZone, Utc};
use std::path::PathBuf;
use std::sync::Arc;
use uuid::Uuid;

use super::error::{DataFileError, ExperimentQueryError, PointHistoryError};
use super::types::ExperimentFilter;
use crate::db::repository::ExperimentRepository;
use crate::models::dto::experiment_query::{PagedResponse, PointHistoryResponse};
use crate::models::entities::experiment::Experiment;
use crate::services::point_history::{
    Hdf5PointHistoryRepository, PointHistoryRepository, TimeRange,
};

/// Data file information
#[derive(Debug)]
pub struct DataFileInfo {
    pub experiment_id: Uuid,
    pub file_path: PathBuf,
    pub file_size: i64,
}

/// Experiment query service trait
#[async_trait]
pub trait ExperimentQueryService: Send + Sync {
    /// Get experiment details
    async fn get_experiment(
        &self,
        id: Uuid,
        user_id: Uuid,
    ) -> Result<Experiment, ExperimentQueryError>;

    /// List experiments with pagination
    async fn list_experiments(
        &self,
        filter: ExperimentFilter,
        page: u32,
        size: u32,
    ) -> Result<PagedResponse<Experiment>, ExperimentQueryError>;

    /// Get point history data
    async fn get_point_history(
        &self,
        experiment_id: Uuid,
        channel: String,
        time_range: Option<TimeRange>,
        limit: usize,
        user_id: Uuid,
    ) -> Result<PointHistoryResponse, PointHistoryError>;

    /// Get data file information
    async fn get_data_file_info(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<DataFileInfo, DataFileError>;
}

/// Experiment query service implementation
pub struct ExperimentQueryServiceImpl {
    experiment_repo: Arc<dyn ExperimentRepository>,
    data_root: PathBuf,
}

impl ExperimentQueryServiceImpl {
    pub fn new(experiment_repo: Arc<dyn ExperimentRepository>, data_root: PathBuf) -> Self {
        Self {
            experiment_repo,
            data_root,
        }
    }
}

#[async_trait]
impl ExperimentQueryService for ExperimentQueryServiceImpl {
    async fn get_experiment(
        &self,
        id: Uuid,
        user_id: Uuid,
    ) -> Result<Experiment, ExperimentQueryError> {
        let experiment = self
            .experiment_repo
            .find_by_id(id)
            .await
            .map_err(|e| ExperimentQueryError::Internal(e.to_string()))?
            .ok_or(ExperimentQueryError::NotFound(id))?;

        // Check ownership
        if experiment.user_id != user_id {
            return Err(ExperimentQueryError::AccessDenied(id));
        }

        Ok(experiment)
    }

    async fn list_experiments(
        &self,
        filter: ExperimentFilter,
        page: u32,
        size: u32,
    ) -> Result<PagedResponse<Experiment>, ExperimentQueryError> {
        let page = page.max(1);
        let size = size.clamp(1, 100);

        let (experiments, total) = self
            .experiment_repo
            .find_paged(filter.user_id, filter.status, page, size)
            .await
            .map_err(|e| ExperimentQueryError::Internal(e.to_string()))?;

        let total_pages = (total as f64 / size as f64).ceil() as u32;

        Ok(PagedResponse {
            items: experiments,
            page,
            size,
            total,
            has_next: page < total_pages,
            has_prev: page > 1,
        })
    }

    async fn get_point_history(
        &self,
        experiment_id: Uuid,
        channel: String,
        time_range: Option<TimeRange>,
        limit: usize,
        user_id: Uuid,
    ) -> Result<PointHistoryResponse, PointHistoryError> {
        // Verify experiment exists and user has access
        let experiment = self
            .experiment_repo
            .find_by_id(experiment_id)
            .await
            .map_err(|_| PointHistoryError::ExperimentNotFound(experiment_id))?
            .ok_or(PointHistoryError::ExperimentNotFound(experiment_id))?;

        if experiment.user_id != user_id {
            return Err(PointHistoryError::ExperimentNotFound(experiment_id));
        }

        let repo = Hdf5PointHistoryRepository::new(self.data_root.clone());
        let points = repo
            .get_channel_data(experiment_id, &channel, time_range, limit.min(100000))
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

        Ok(PointHistoryResponse {
            experiment_id,
            channel,
            data: points,
            start_time,
            end_time,
            total_points,
        })
    }

    async fn get_data_file_info(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<DataFileInfo, DataFileError> {
        // Verify experiment exists and user has access
        let experiment = self
            .experiment_repo
            .find_by_id(experiment_id)
            .await
            .map_err(|_e| DataFileError::ExperimentNotFound(experiment_id))?
            .ok_or(DataFileError::ExperimentNotFound(experiment_id))?;

        if experiment.user_id != user_id {
            return Err(DataFileError::AccessDenied(experiment_id));
        }

        let file_path = self
            .data_root
            .join("experiments")
            .join(format!("{}.h5", experiment_id));

        if !file_path.exists() {
            return Err(DataFileError::DataFileNotFound);
        }

        let metadata = std::fs::metadata(&file_path)
            .map_err(|e| DataFileError::FileReadError(e.to_string()))?;

        Ok(DataFileInfo {
            experiment_id,
            file_path,
            file_size: metadata.len() as i64,
        })
    }
}
