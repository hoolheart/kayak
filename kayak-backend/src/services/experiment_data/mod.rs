//! Experiment data query service
//!
//! Provides HDF5 time-series data reading with LTTB downsampling.

use async_trait::async_trait;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use uuid::Uuid;

use crate::core::error::AppError;
use crate::db::repository::experiment_repo::ExperimentRepository;
use crate::models::dto::experiment_data_query::{
    ExperimentDataPointResponse, ExperimentDataQueryRequest, ExperimentDataResponse,
};
use crate::models::entities::experiment::ExperimentStatus;
use crate::services::lttb::lttb_downsample;

/// Service for querying experiment time-series data from HDF5 files
#[async_trait]
pub trait ExperimentDataService: Send + Sync {
    /// Query experiment data by device and point IDs with optional time range and downsampling
    async fn query_experiment_data(
        &self,
        experiment_id: Uuid,
        request: ExperimentDataQueryRequest,
        user_id: Uuid,
    ) -> Result<ExperimentDataResponse, AppError>;
}

/// Implementation of experiment data service
pub struct ExperimentDataServiceImpl {
    experiment_repo: Arc<dyn ExperimentRepository>,
    data_root: PathBuf,
}

impl ExperimentDataServiceImpl {
    /// Create a new experiment data service
    pub fn new(experiment_repo: Arc<dyn ExperimentRepository>, data_root: PathBuf) -> Self {
        Self {
            experiment_repo,
            data_root,
        }
    }

    fn get_hdf5_path(&self, experiment_id: Uuid) -> PathBuf {
        self.data_root
            .join("experiments")
            .join(format!("{}.h5", experiment_id))
    }

    /// Convert optional DateTime to Unix millis
    fn datetime_to_millis(dt: Option<chrono::DateTime<chrono::Utc>>) -> i64 {
        dt.map(|d| d.timestamp_millis()).unwrap_or(0)
    }

    /// Read point data from HDF5 file within the specified time range
    #[allow(clippy::type_complexity)]
    fn read_point_data(
        &self,
        file_path: &Path,
        device_id: Uuid,
        point_id: Uuid,
        start_time: i64,
        end_time: i64,
    ) -> Result<(Vec<i64>, Vec<f64>, String, String, String), AppError> {
        let file = hdf5::File::open(file_path).map_err(|e| {
            AppError::InternalError(format!("Failed to open HDF5 file: {}", e))
        })?;

        let group_path = format!("/{}/{}", device_id, point_id);
        let group = file.group(&group_path).map_err(|_| {
            AppError::NotFound(format!(
                "Point '{}' not found in device '{}'",
                point_id, device_id
            ))
        })?;

        // Read timestamps dataset
        let timestamps_ds = group.dataset("timestamps").map_err(|_| {
            AppError::InternalError("timestamps dataset not found".to_string())
        })?;

        // Read values dataset
        let values_ds = group.dataset("values").map_err(|_| {
            AppError::InternalError("values dataset not found".to_string())
        })?;

        let all_timestamps: Vec<i64> = timestamps_ds.read_raw().map_err(|e| {
            AppError::InternalError(format!("Failed to read timestamps: {}", e))
        })?;

        let all_values: Vec<f64> = values_ds.read_raw().map_err(|e| {
            AppError::InternalError(format!("Failed to read values: {}", e))
        })?;

        if all_timestamps.len() != all_values.len() {
            return Err(AppError::InternalError(
                "Dataset format error: timestamps and values length mismatch".to_string(),
            ));
        }

        // Find time range indices
        let start_idx = all_timestamps
            .iter()
            .position(|&t| t >= start_time)
            .unwrap_or(all_timestamps.len());

        let end_idx = all_timestamps
            .iter()
            .rposition(|&t| t <= end_time)
            .map(|i| i + 1)
            .unwrap_or(0);

        if start_idx >= end_idx {
            return Ok((vec![], vec![], String::new(), String::new(), String::new()));
        }

        let timestamps = all_timestamps[start_idx..end_idx].to_vec();
        let values = all_values[start_idx..end_idx].to_vec();

        // Try to read optional attributes, default to empty string
        let point_name = Self::read_string_attr(&group, "name");
        let unit = Self::read_string_attr(&group, "unit");
        let data_type = Self::read_string_attr(&group, "data_type");

        Ok((timestamps, values, point_name, unit, data_type))
    }

    /// Attempt to read a string attribute from an HDF5 group
    fn read_string_attr(group: &hdf5::Group, name: &str) -> String {
        group.attr(name).ok().and_then(|attr| {
            attr.read_scalar::<hdf5::types::VarLenUnicode>()
                .ok()
                .map(|s| s.to_string())
        }).unwrap_or_default()
    }
}

#[async_trait]
impl ExperimentDataService for ExperimentDataServiceImpl {
    async fn query_experiment_data(
        &self,
        experiment_id: Uuid,
        request: ExperimentDataQueryRequest,
        user_id: Uuid,
    ) -> Result<ExperimentDataResponse, AppError> {
        let start_time = Self::datetime_to_millis(request.start_time);
        let end_time = Self::datetime_to_millis(request.end_time);
        // If end_time is not provided, use max i64
        let end_time = if request.end_time.is_some() {
            end_time
        } else {
            i64::MAX
        };
        let downsample_threshold = request.downsample.unwrap_or(1000);

        // Step 1: Find experiment
        let experiment = self
            .experiment_repo
            .find_by_id(experiment_id)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?
            .ok_or_else(|| AppError::NotFound(format!("Experiment '{}' not found", experiment_id)))?;

        // Step 2: Verify ownership
        if experiment.user_id != user_id {
            return Err(AppError::Forbidden(
                "Access denied to this experiment".to_string(),
            ));
        }

        // Step 3: Check experiment status
        // Only allow query for non-running/non-paused experiments
        if matches!(
            experiment.status,
            ExperimentStatus::Running | ExperimentStatus::Paused
        ) {
            return Err(AppError::Conflict(format!(
                "Experiment is still running (status: {:?})",
                experiment.status
            )));
        }

        // Step 4: Check HDF5 file exists
        let hdf5_path = self.get_hdf5_path(experiment_id);
        if !hdf5_path.exists() {
            return Err(AppError::NotFound(
                "Experiment data file not found".to_string(),
            ));
        }

        // Step 5: Verify device exists by trying to open its group
        let file = hdf5::File::open(&hdf5_path).map_err(|e| {
            AppError::InternalError(format!("Failed to open HDF5 file: {}", e))
        })?;

        let device_group_path = format!("/{}", request.device_id);
        if file.group(&device_group_path).is_err() {
            return Err(AppError::NotFound(format!(
                "Device '{}' not found in experiment",
                request.device_id
            )));
        }

        // Step 6: Read data for each point
        let mut points = Vec::with_capacity(request.point_ids.len());
        let mut total_raw_points: usize = 0;
        let mut total_returned_points: usize = 0;

        for point_id in &request.point_ids {
            let (timestamps, values, point_name, unit, data_type) = self.read_point_data(
                &hdf5_path,
                request.device_id,
                *point_id,
                start_time,
                end_time,
            )?;

            let raw_count = timestamps.len();
            total_raw_points += raw_count;

            let (final_ts, final_vals) = if raw_count > downsample_threshold {
                lttb_downsample(&timestamps,
                    &values,
                    downsample_threshold,
                )
            } else {
                (timestamps, values)
            };

            let returned_count = final_ts.len();
            total_returned_points += returned_count;

            points.push(ExperimentDataPointResponse {
                point_id: *point_id,
                point_name,
                unit,
                data_type,
                timestamps: final_ts,
                values: final_vals,
            });
        }

        Ok(ExperimentDataResponse {
            experiment_id,
            device_id: request.device_id,
            points,
            total_samples: total_raw_points,
            returned_samples: total_returned_points,
        })
    }
}
