//! Point history repository - reads from HDF5 files

use async_trait::async_trait;
use chrono::{DateTime, TimeZone, Utc};
use std::path::PathBuf;
use uuid::Uuid;

use super::types::TimeRange;
use crate::models::dto::experiment_query::TimeSeriesDataPoint;
use crate::services::experiment_query::PointHistoryError;

/// Point history repository trait
#[async_trait]
pub trait PointHistoryRepository: Send + Sync {
    /// Get channel data from HDF5
    async fn get_channel_data(
        &self,
        experiment_id: Uuid,
        channel: &str,
        time_range: Option<TimeRange>,
        limit: usize,
    ) -> Result<Vec<TimeSeriesDataPoint>, PointHistoryError>;

    /// Check if channel exists
    async fn channel_exists(
        &self,
        experiment_id: Uuid,
        channel: &str,
    ) -> Result<bool, PointHistoryError>;

    /// Get time range for channel
    async fn get_time_range(
        &self,
        experiment_id: Uuid,
        channel: &str,
    ) -> Result<Option<TimeRange>, PointHistoryError>;

    /// Get point count
    async fn get_point_count(
        &self,
        experiment_id: Uuid,
        channel: &str,
    ) -> Result<usize, PointHistoryError>;
}

/// HDF5 implementation of point history repository
pub struct Hdf5PointHistoryRepository {
    data_root: PathBuf,
}

impl Hdf5PointHistoryRepository {
    pub fn new(data_root: PathBuf) -> Self {
        Self { data_root }
    }

    fn get_hdf5_path(&self, experiment_id: Uuid) -> Result<PathBuf, PointHistoryError> {
        let path = self
            .data_root
            .join("experiments")
            .join(format!("{}.h5", experiment_id));
        Ok(path)
    }
}

#[async_trait]
impl PointHistoryRepository for Hdf5PointHistoryRepository {
    async fn get_channel_data(
        &self,
        experiment_id: Uuid,
        channel: &str,
        time_range: Option<TimeRange>,
        limit: usize,
    ) -> Result<Vec<TimeSeriesDataPoint>, PointHistoryError> {
        let file_path = self.get_hdf5_path(experiment_id)?;

        if !file_path.exists() {
            return Err(PointHistoryError::Hdf5FileNotFound(
                file_path.to_string_lossy().to_string(),
            ));
        }

        let file = hdf5::File::open(&file_path)
            .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        let group_path = format!("/{}", channel);
        let group = match file.group(&group_path) {
            Ok(g) => g,
            Err(_) => {
                return Err(PointHistoryError::ChannelNotFound(channel.to_string()));
            }
        };

        let timestamps_ds = group
            .dataset("timestamps")
            .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;
        let values_ds = group
            .dataset("values")
            .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        let timestamps: Vec<i64> = timestamps_ds
            .read_raw()
            .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;
        let values: Vec<f64> = values_ds
            .read_raw()
            .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        // Convert timestamps and filter
        let mut points: Vec<TimeSeriesDataPoint> = timestamps
            .into_iter()
            .zip(values.into_iter())
            .filter(|(ts, _)| {
                let nanos = *ts;
                let dt = Utc.timestamp_opt(nanos / 1_000_000_000, (nanos % 1_000_000_000) as u32)
                    .single();
                match (dt, &time_range) {
                    (Some(dt), Some(range)) => dt >= range.start && dt <= range.end,
                    _ => true,
                }
            })
            .take(limit)
            .map(|(ts, val)| TimeSeriesDataPoint {
                timestamp: ts,
                value: val,
            })
            .collect();

        // Sort by timestamp
        points.sort_by_key(|p| p.timestamp);

        Ok(points)
    }

    async fn channel_exists(
        &self,
        experiment_id: Uuid,
        channel: &str,
    ) -> Result<bool, PointHistoryError> {
        let file_path = self.get_hdf5_path(experiment_id)?;

        if !file_path.exists() {
            return Ok(false);
        }

        let file =
            hdf5::File::open(&file_path).map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        let group_path = format!("/{}", channel);
        match file.group(&group_path) {
            Ok(_) => Ok(true),
            Err(_) => Ok(false),
        }
    }

    async fn get_time_range(
        &self,
        experiment_id: Uuid,
        channel: &str,
    ) -> Result<Option<TimeRange>, PointHistoryError> {
        let file_path = self.get_hdf5_path(experiment_id)?;

        if !file_path.exists() {
            return Ok(None);
        }

        let file =
            hdf5::File::open(&file_path).map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        let group_path = format!("/{}", channel);
        let group = match file.group(&group_path) {
            Ok(g) => g,
            Err(_) => return Ok(None),
        };

        let timestamps_ds = group
            .dataset("timestamps")
            .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        let timestamps: Vec<i64> = timestamps_ds
            .read_raw()
            .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        if timestamps.is_empty() {
            return Ok(None);
        }

        let min_ts = *timestamps.iter().min().unwrap();
        let max_ts = *timestamps.iter().max().unwrap();

        let start = Utc
            .timestamp_opt(min_ts / 1_000_000_000, (min_ts % 1_000_000_000) as u32)
            .single();
        let end = Utc
            .timestamp_opt(max_ts / 1_000_000_000, (max_ts % 1_000_000_000) as u32)
            .single();

        match (start, end) {
            (Some(start), Some(end)) => Ok(Some(TimeRange { start, end })),
            _ => Ok(None),
        }
    }

    async fn get_point_count(
        &self,
        experiment_id: Uuid,
        channel: &str,
    ) -> Result<usize, PointHistoryError> {
        let file_path = self.get_hdf5_path(experiment_id)?;

        if !file_path.exists() {
            return Ok(0);
        }

        let file =
            hdf5::File::open(&file_path).map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        let group_path = format!("/{}", channel);
        let group = match file.group(&group_path) {
            Ok(g) => g,
            Err(_) => return Ok(0),
        };

        let timestamps_ds = group
            .dataset("timestamps")
            .map_err(|e| PointHistoryError::Hdf5ReadError(e.to_string()))?;

        let shape = timestamps_ds.shape();
        Ok(shape.first().copied().unwrap_or(0))
    }
}