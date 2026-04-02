//! State change log entity
//!
//! Records all state transitions for audit trail purposes.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models::entities::experiment::ExperimentStatus;
use crate::state_machine::StateMachineOperation;

/// State change log entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateChangeLog {
    /// Log entry ID (UUID)
    pub id: Uuid,
    /// Experiment ID
    pub experiment_id: Uuid,
    /// State before the transition
    pub previous_state: ExperimentStatus,
    /// State after the transition
    pub new_state: ExperimentStatus,
    /// Operation that triggered the change (lowercase string)
    pub operation: String,
    /// User ID who triggered the change
    pub user_id: Uuid,
    /// Timestamp of the change
    pub timestamp: DateTime<Utc>,
    /// Optional error message if the transition failed
    pub error_message: Option<String>,
}

impl StateChangeLog {
    /// Create a new state change log entry
    pub fn new(
        experiment_id: Uuid,
        previous_state: ExperimentStatus,
        new_state: ExperimentStatus,
        operation: StateMachineOperation,
        user_id: Uuid,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            experiment_id,
            previous_state,
            new_state,
            operation: operation.as_str().to_string(),
            user_id,
            timestamp: Utc::now(),
            error_message: None,
        }
    }

    /// Create a failed state change log entry with an error message
    pub fn failed(
        experiment_id: Uuid,
        previous_state: ExperimentStatus,
        operation: StateMachineOperation,
        user_id: Uuid,
        error_message: String,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            experiment_id,
            previous_state,
            new_state: previous_state, // No change on failure
            operation: operation.as_str().to_string(),
            user_id,
            timestamp: Utc::now(),
            error_message: Some(error_message),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_state_change_log_new() {
        let log = StateChangeLog::new(
            Uuid::new_v4(),
            ExperimentStatus::Idle,
            ExperimentStatus::Loaded,
            StateMachineOperation::Load,
            Uuid::new_v4(),
        );

        assert_eq!(log.previous_state, ExperimentStatus::Idle);
        assert_eq!(log.new_state, ExperimentStatus::Loaded);
        assert_eq!(log.operation, "load");
        assert!(log.error_message.is_none());
    }

    #[test]
    fn test_state_change_log_failed() {
        let log = StateChangeLog::failed(
            Uuid::new_v4(),
            ExperimentStatus::Running,
            StateMachineOperation::Pause,
            Uuid::new_v4(),
            "Database error".to_string(),
        );

        assert_eq!(log.previous_state, ExperimentStatus::Running);
        assert_eq!(log.new_state, ExperimentStatus::Running); // No change
        assert_eq!(log.operation, "pause");
        assert_eq!(log.error_message, Some("Database error".to_string()));
    }

    #[test]
    fn test_state_change_log_serialization() {
        let log = StateChangeLog::new(
            Uuid::new_v4(),
            ExperimentStatus::Running,
            ExperimentStatus::Paused,
            StateMachineOperation::Pause,
            Uuid::new_v4(),
        );

        let json = serde_json::to_string(&log).unwrap();
        let deserialized: StateChangeLog = serde_json::from_str(&json).unwrap();

        assert_eq!(deserialized.previous_state, log.previous_state);
        assert_eq!(deserialized.new_state, log.new_state);
        assert_eq!(deserialized.operation, log.operation);
    }
}
