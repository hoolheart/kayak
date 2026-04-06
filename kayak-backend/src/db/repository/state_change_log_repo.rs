//! State change log repository
//!
//! Provides data access for experiment state change audit logs.

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

use crate::db::connection::DbPool;
use crate::models::entities::experiment::ExperimentStatus;
use crate::models::entities::StateChangeLog;

/// Repository error for state change logs
#[derive(Debug, thiserror::Error)]
pub enum StateChangeLogRepositoryError {
    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),
}

/// Row structure for state change log queries
#[derive(Debug, FromRow)]
struct StateChangeLogRow {
    id: String,
    experiment_id: String,
    previous_state: String,
    new_state: String,
    operation: String,
    user_id: String,
    timestamp: String,
    error_message: Option<String>,
}

impl StateChangeLogRow {
    fn to_log(&self) -> StateChangeLog {
        let previous_state = parse_status(&self.previous_state);
        let new_state = parse_status(&self.new_state);

        StateChangeLog {
            id: Uuid::parse_str(&self.id).unwrap_or_default(),
            experiment_id: Uuid::parse_str(&self.experiment_id).unwrap_or_default(),
            previous_state,
            new_state,
            operation: self.operation.clone(),
            user_id: Uuid::parse_str(&self.user_id).unwrap_or_default(),
            timestamp: DateTime::parse_from_rfc3339(&self.timestamp)
                .map(|dt| dt.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now()),
            error_message: self.error_message.clone(),
        }
    }
}

fn parse_status(s: &str) -> ExperimentStatus {
    match s {
        "IDLE" => ExperimentStatus::Idle,
        "LOADED" => ExperimentStatus::Loaded,
        "RUNNING" => ExperimentStatus::Running,
        "PAUSED" => ExperimentStatus::Paused,
        "COMPLETED" => ExperimentStatus::Completed,
        "ABORTED" => ExperimentStatus::Aborted,
        _ => ExperimentStatus::Idle,
    }
}

/// State change log repository trait
#[async_trait]
pub trait StateChangeLogRepository: Send + Sync {
    /// Record a state change
    async fn record(&self, log: &StateChangeLog) -> Result<(), StateChangeLogRepositoryError>;

    /// Get all state changes for an experiment (ordered by timestamp ascending)
    async fn find_by_experiment(
        &self,
        experiment_id: Uuid,
    ) -> Result<Vec<StateChangeLog>, StateChangeLogRepositoryError>;

    /// Get the latest state change for an experiment
    async fn find_latest(
        &self,
        experiment_id: Uuid,
    ) -> Result<Option<StateChangeLog>, StateChangeLogRepositoryError>;
}

/// Sqlx implementation of StateChangeLogRepository
pub struct SqlxStateChangeLogRepository {
    pool: DbPool,
}

impl SqlxStateChangeLogRepository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl StateChangeLogRepository for SqlxStateChangeLogRepository {
    async fn record(&self, log: &StateChangeLog) -> Result<(), StateChangeLogRepositoryError> {
        let prev_status = format!("{:?}", log.previous_state).to_uppercase();
        let new_status = format!("{:?}", log.new_state).to_uppercase();

        sqlx::query(
            r#"
            INSERT INTO state_change_logs 
                (id, experiment_id, previous_state, new_state, operation, user_id, timestamp, error_message)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(log.id.to_string())
        .bind(log.experiment_id.to_string())
        .bind(prev_status)
        .bind(new_status)
        .bind(&log.operation)
        .bind(log.user_id.to_string())
        .bind(log.timestamp)
        .bind(&log.error_message)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn find_by_experiment(
        &self,
        experiment_id: Uuid,
    ) -> Result<Vec<StateChangeLog>, StateChangeLogRepositoryError> {
        let rows: Vec<StateChangeLogRow> = sqlx::query_as(
            r#"
            SELECT id, experiment_id, previous_state, new_state, operation,
                   user_id, timestamp, error_message
            FROM state_change_logs
            WHERE experiment_id = ?
            ORDER BY timestamp ASC
            "#,
        )
        .bind(experiment_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|r| r.to_log()).collect())
    }

    async fn find_latest(
        &self,
        experiment_id: Uuid,
    ) -> Result<Option<StateChangeLog>, StateChangeLogRepositoryError> {
        let row: Option<StateChangeLogRow> = sqlx::query_as(
            r#"
            SELECT id, experiment_id, previous_state, new_state, operation,
                   user_id, timestamp, error_message
            FROM state_change_logs
            WHERE experiment_id = ?
            ORDER BY timestamp DESC
            LIMIT 1
            "#,
        )
        .bind(experiment_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| r.to_log()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::state_machine::StateMachineOperation;

    #[test]
    fn test_parse_status_all_variants() {
        assert_eq!(parse_status("IDLE"), ExperimentStatus::Idle);
        assert_eq!(parse_status("LOADED"), ExperimentStatus::Loaded);
        assert_eq!(parse_status("RUNNING"), ExperimentStatus::Running);
        assert_eq!(parse_status("PAUSED"), ExperimentStatus::Paused);
        assert_eq!(parse_status("COMPLETED"), ExperimentStatus::Completed);
        assert_eq!(parse_status("ABORTED"), ExperimentStatus::Aborted);
        assert_eq!(parse_status("UNKNOWN"), ExperimentStatus::Idle); // fallback
    }

    #[test]
    fn test_state_change_log_row_conversion() {
        let now = Utc::now().to_rfc3339();
        let row = StateChangeLogRow {
            id: Uuid::new_v4().to_string(),
            experiment_id: Uuid::new_v4().to_string(),
            previous_state: "IDLE".to_string(),
            new_state: "LOADED".to_string(),
            operation: "load".to_string(),
            user_id: Uuid::new_v4().to_string(),
            timestamp: now,
            error_message: None,
        };

        let log = row.to_log();
        assert_eq!(log.previous_state, ExperimentStatus::Idle);
        assert_eq!(log.new_state, ExperimentStatus::Loaded);
        assert_eq!(log.operation, "load");
        assert!(log.error_message.is_none());
    }

    #[test]
    fn test_state_change_log_new() {
        let exp_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();
        let log = StateChangeLog::new(
            exp_id,
            ExperimentStatus::Idle,
            ExperimentStatus::Loaded,
            StateMachineOperation::Load,
            user_id,
        );

        assert_eq!(log.experiment_id, exp_id);
        assert_eq!(log.user_id, user_id);
        assert_eq!(log.previous_state, ExperimentStatus::Idle);
        assert_eq!(log.new_state, ExperimentStatus::Loaded);
        assert_eq!(log.operation, "load");
    }
}
