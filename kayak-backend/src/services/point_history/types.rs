//! Point history repository types

use chrono::{DateTime, Utc};

/// Time range for time-series queries
#[derive(Debug, Clone)]
pub struct TimeRange {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
}
