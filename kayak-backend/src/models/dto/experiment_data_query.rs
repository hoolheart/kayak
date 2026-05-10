//! Experiment data query DTOs
//!
//! Defines request and response types for the HDF5 time-series data query API.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

/// Experiment data query request
#[derive(Debug, Deserialize, Validate)]
pub struct ExperimentDataQueryRequest {
    /// Target device ID
    pub device_id: Uuid,
    /// Target point IDs (at least one)
    #[validate(length(min = 1, max = 50))]
    pub point_ids: Vec<Uuid>,
    /// Start time (optional, inclusive)
    pub start_time: Option<DateTime<Utc>>,
    /// End time (optional, inclusive)
    pub end_time: Option<DateTime<Utc>>,
    /// Downsample target point count (optional, default 1000, range 1-10000)
    #[validate(range(min = 2, max = 10000))]
    pub downsample: Option<usize>,
}

/// Experiment data query response
#[derive(Debug, Serialize)]
pub struct ExperimentDataResponse {
    /// Experiment ID
    pub experiment_id: Uuid,
    /// Device ID
    pub device_id: Uuid,
    /// Data series for each point
    pub points: Vec<ExperimentDataPointResponse>,
    /// Total raw data points before downsampling
    pub total_samples: usize,
    /// Returned data points after downsampling
    pub returned_samples: usize,
}

/// Data series for a single point
#[derive(Debug, Serialize)]
pub struct ExperimentDataPointResponse {
    /// Point ID
    pub point_id: Uuid,
    /// Point name (from HDF5 attribute if available, else empty)
    pub point_name: String,
    /// Unit (from HDF5 attribute if available, else empty)
    pub unit: String,
    /// Data type (from HDF5 attribute if available, else empty)
    pub data_type: String,
    /// Timestamps (Unix millis)
    pub timestamps: Vec<i64>,
    /// Values
    pub values: Vec<f64>,
}
