//! Experiment query types

use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::models::entities::experiment::ExperimentStatus;

/// Experiment query filter
#[derive(Debug, Clone, Default)]
pub struct ExperimentFilter {
    pub user_id: Option<Uuid>,
    pub status: Option<ExperimentStatus>,
    pub method_id: Option<Uuid>,
    pub created_after: Option<DateTime<Utc>>,
    pub created_before: Option<DateTime<Utc>>,
}
