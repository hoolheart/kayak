//! Experiment query DTOs

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Pagination helper for deserialization
fn deserialize_pagination<'de, D>(deserializer: D) -> Result<Option<u32>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let opt = Option::<String>::deserialize(deserializer)?;
    match opt {
        Some(s) if s.is_empty() => Ok(None),
        Some(s) => Ok(Some(
            s.parse()
                .map_err(|_| serde::de::Error::custom("invalid number"))?,
        )),
        None => Ok(None),
    }
}

/// Default limit value
fn default_limit() -> usize {
    10000
}

/// List experiments request
#[derive(Debug, Deserialize, Default)]
#[serde(default)]
pub struct ListExperimentsRequest {
    #[serde(deserialize_with = "deserialize_pagination")]
    pub page: Option<u32>,
    #[serde(deserialize_with = "deserialize_pagination")]
    pub size: Option<u32>,
    pub status: Option<crate::models::entities::experiment::ExperimentStatus>,
    pub created_after: Option<DateTime<Utc>>,
    pub created_before: Option<DateTime<Utc>>,
}

/// Point history request
#[derive(Debug, Deserialize)]
pub struct PointHistoryRequest {
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    #[serde(default = "default_limit")]
    pub limit: usize,
}

/// Paged response
#[derive(Debug, Serialize)]
pub struct PagedResponse<T> {
    pub items: Vec<T>,
    pub page: u32,
    pub size: u32,
    pub total: u64,
    pub has_next: bool,
    pub has_prev: bool,
}

/// Time series data point
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimeSeriesDataPoint {
    pub timestamp: i64,
    pub value: f64,
}

/// Point history response
#[derive(Debug, Serialize)]
pub struct PointHistoryResponse {
    pub experiment_id: Uuid,
    pub channel: String,
    pub data: Vec<TimeSeriesDataPoint>,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub total_points: usize,
}
