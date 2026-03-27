//! Experiment query service

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use std::path::PathBuf;
use uuid::Uuid;

use super::error::{DataFileError, ExperimentQueryError, PointHistoryError};
use super::types::ExperimentFilter;
use crate::models::dto::experiment_query::{PointHistoryResponse, TimeSeriesDataPoint};
use crate::models::entities::experiment::Experiment;

/// Time range for queries
#[derive(Debug, Clone)]
pub struct TimeRange {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
}

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
    ) -> Result<crate::models::dto::experiment_query::PagedResponse<Experiment>, ExperimentQueryError>;

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