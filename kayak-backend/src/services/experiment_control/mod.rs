//! Experiment Control Service
//!
//! Provides experiment lifecycle control operations:
//! load, start, pause, resume, stop, reset, complete, abort.
//!
//! Uses the StateMachine for transition validation and persists
//! state changes with audit logging.

use chrono::Utc;
use serde::Serialize;
use std::sync::Arc;
use uuid::Uuid;

use crate::db::repository::experiment_repo::{
    ExperimentRepository, ExperimentRepositoryError, MethodIdUpdate,
};
use crate::db::repository::method_repo::MethodRepository;
use crate::db::repository::state_change_log_repo::StateChangeLogRepository;
use crate::state_machine::{StateMachine, StateMachineError, StateMachineOperation};

pub mod ws_manager;

pub use ws_manager::{broadcast_error, broadcast_status_change, ExperimentWsManager, WsMessage};

/// Experiment control service error
#[derive(Debug, thiserror::Error)]
pub enum ExperimentControlError {
    #[error("Experiment not found: {0}")]
    NotFound(Uuid),

    #[error("Method not found: {0}")]
    MethodNotFound(Uuid),

    #[error("Invalid state transition: {0}")]
    InvalidTransition(String),

    #[error("Operation not allowed: {0}")]
    OperationNotAllowed(String),

    #[error("Repository error: {0}")]
    Repository(String),

    #[error("Concurrent modification conflict")]
    ConcurrentConflict,

    #[error("Forbidden: {0}")]
    Forbidden(String),
}

impl From<ExperimentRepositoryError> for ExperimentControlError {
    fn from(err: ExperimentRepositoryError) -> Self {
        match err {
            ExperimentRepositoryError::NotFound(id) => ExperimentControlError::NotFound(id),
            ExperimentRepositoryError::DatabaseError(e) => {
                ExperimentControlError::Repository(e.to_string())
            }
        }
    }
}

impl From<StateMachineError> for ExperimentControlError {
    fn from(err: StateMachineError) -> Self {
        match err {
            StateMachineError::InvalidTransition { from, operation } => {
                ExperimentControlError::InvalidTransition(format!(
                    "Cannot perform {:?} from {:?}",
                    operation, from
                ))
            }
            StateMachineError::OperationNotAllowed {
                operation,
                current_state,
            } => ExperimentControlError::OperationNotAllowed(format!(
                "Operation {:?} not allowed in state {:?}",
                operation, current_state
            )),
        }
    }
}

/// Experiment status response DTO
#[derive(Debug, Serialize)]
pub struct ExperimentStatusDto {
    pub id: String,
    pub name: String,
    pub status: String,
    pub method_id: Option<String>,
    pub started_at: Option<String>,
    pub ended_at: Option<String>,
    pub updated_at: String,
}

/// State change log DTO
#[derive(Debug, Serialize)]
pub struct StateChangeLogDto {
    pub id: String,
    pub experiment_id: String,
    pub previous_state: String,
    pub new_state: String,
    pub operation: String,
    pub user_id: String,
    pub timestamp: String,
    pub error_message: Option<String>,
}

/// Experiment DTO for control responses
#[derive(Debug, Serialize)]
pub struct ExperimentControlDto {
    pub id: String,
    pub name: String,
    pub status: String,
    pub method_id: Option<String>,
    pub description: Option<String>,
    pub started_at: Option<String>,
    pub ended_at: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

impl ExperimentControlDto {
    fn from_experiment(exp: &crate::models::entities::Experiment) -> Self {
        Self {
            id: exp.id.to_string(),
            name: exp.name.clone(),
            status: format!("{:?}", exp.status).to_uppercase(),
            method_id: exp.method_id.map(|u| u.to_string()),
            description: exp.description.clone(),
            started_at: exp.started_at.map(|dt| dt.to_rfc3339()),
            ended_at: exp.ended_at.map(|dt| dt.to_rfc3339()),
            created_at: exp.created_at.to_rfc3339(),
            updated_at: exp.updated_at.to_rfc3339(),
        }
    }
}

impl StateChangeLogDto {
    fn from_log(log: &crate::models::entities::StateChangeLog) -> Self {
        Self {
            id: log.id.to_string(),
            experiment_id: log.experiment_id.to_string(),
            previous_state: format!("{:?}", log.previous_state).to_uppercase(),
            new_state: format!("{:?}", log.new_state).to_uppercase(),
            operation: log.operation.clone(),
            user_id: log.user_id.to_string(),
            timestamp: log.timestamp.to_rfc3339(),
            error_message: log.error_message.clone(),
        }
    }
}

/// Experiment control service
pub struct ExperimentControlService<ER, MR, LR>
where
    ER: ExperimentRepository,
    MR: MethodRepository,
    LR: StateChangeLogRepository,
{
    experiment_repo: ER,
    method_repo: MR,
    log_repo: LR,
    ws_manager: Option<std::sync::Arc<ExperimentWsManager>>,
}

impl<ER, MR, LR> ExperimentControlService<ER, MR, LR>
where
    ER: ExperimentRepository,
    MR: MethodRepository,
    LR: StateChangeLogRepository,
{
    pub fn new(experiment_repo: ER, method_repo: MR, log_repo: LR) -> Self {
        Self {
            experiment_repo,
            method_repo,
            log_repo,
            ws_manager: None,
        }
    }

    /// Create a new service with WebSocket manager
    pub fn with_ws_manager(
        experiment_repo: ER,
        method_repo: MR,
        log_repo: LR,
        ws_manager: std::sync::Arc<ExperimentWsManager>,
    ) -> Self {
        Self {
            experiment_repo,
            method_repo,
            log_repo,
            ws_manager: Some(ws_manager),
        }
    }

    /// Verify that the user owns the experiment or is an admin.
    /// Returns the experiment if authorized, error otherwise.
    async fn verify_ownership(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<crate::models::entities::experiment::Experiment, ExperimentControlError> {
        let exp = self
            .experiment_repo
            .find_by_id(experiment_id)
            .await?
            .ok_or(ExperimentControlError::NotFound(experiment_id))?;

        // TODO: Add admin role check when user roles are implemented
        if exp.user_id != user_id {
            return Err(ExperimentControlError::Forbidden(
                "You do not have permission to control this experiment".to_string(),
            ));
        }

        Ok(exp)
    }

    /// Broadcast status change if WebSocket manager is configured
    fn broadcast_status_change(
        &self,
        experiment_id: Uuid,
        old_status: &str,
        new_status: &str,
        operation: &str,
        user_id: Uuid,
    ) {
        if let Some(ref manager) = self.ws_manager {
            broadcast_status_change(
                Arc::clone(manager),
                experiment_id,
                old_status,
                new_status,
                operation,
                user_id,
            );
        }
    }

    /// Broadcast error if WebSocket manager is configured
    #[allow(dead_code)]
    fn broadcast_error(&self, experiment_id: Uuid, error: &str, code: u16) {
        if let Some(ref manager) = self.ws_manager {
            broadcast_error(Arc::clone(manager), experiment_id, error, code);
        }
    }

    /// Load a method into the experiment (Idle -> Loaded)
    pub async fn load(
        &self,
        experiment_id: Uuid,
        method_id: Uuid,
        user_id: Uuid,
    ) -> Result<ExperimentControlDto, ExperimentControlError> {
        // Verify ownership
        let exp = self.verify_ownership(experiment_id, user_id).await?;

        // Validate transition
        let new_status = StateMachine::transition(exp.status, StateMachineOperation::Load)?;

        // Validate method exists
        self.method_repo
            .get_by_id(method_id)
            .await
            .map_err(|_| ExperimentControlError::MethodNotFound(method_id))?;

        // Update state
        let updated = self
            .experiment_repo
            .update_state(
                experiment_id,
                new_status,
                MethodIdUpdate::Set(method_id),
                None,
                None,
            )
            .await?;

        // Record log
        let log = crate::models::entities::StateChangeLog::new(
            experiment_id,
            exp.status,
            new_status,
            StateMachineOperation::Load,
            user_id,
        );
        self.log_repo
            .record(&log)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        // Broadcast status change via WebSocket
        self.broadcast_status_change(
            experiment_id,
            &format!("{:?}", exp.status),
            &format!("{:?}", new_status),
            "load",
            user_id,
        );

        Ok(ExperimentControlDto::from_experiment(&updated))
    }

    /// Start the experiment (Loaded -> Running, Paused -> Running)
    pub async fn start(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<ExperimentControlDto, ExperimentControlError> {
        let exp = self.verify_ownership(experiment_id, user_id).await?;

        let new_status = StateMachine::transition(exp.status, StateMachineOperation::Start)?;

        // Set started_at only if it wasn't already set (first start)
        let started_at = if exp.started_at.is_none() {
            Some(Utc::now())
        } else {
            None // Preserve existing
        };

        let updated = self
            .experiment_repo
            .update_state(
                experiment_id,
                new_status,
                MethodIdUpdate::Preserve,
                started_at,
                None,
            )
            .await?;

        let log = crate::models::entities::StateChangeLog::new(
            experiment_id,
            exp.status,
            new_status,
            StateMachineOperation::Start,
            user_id,
        );
        self.log_repo
            .record(&log)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        // Broadcast status change via WebSocket
        self.broadcast_status_change(
            experiment_id,
            &format!("{:?}", exp.status),
            &format!("{:?}", new_status),
            "start",
            user_id,
        );

        Ok(ExperimentControlDto::from_experiment(&updated))
    }

    /// Pause the experiment (Running -> Paused)
    pub async fn pause(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<ExperimentControlDto, ExperimentControlError> {
        let exp = self.verify_ownership(experiment_id, user_id).await?;

        let new_status = StateMachine::transition(exp.status, StateMachineOperation::Pause)?;

        let updated = self
            .experiment_repo
            .update_state(
                experiment_id,
                new_status,
                MethodIdUpdate::Preserve,
                None,
                None,
            )
            .await?;

        let log = crate::models::entities::StateChangeLog::new(
            experiment_id,
            exp.status,
            new_status,
            StateMachineOperation::Pause,
            user_id,
        );
        self.log_repo
            .record(&log)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        // Broadcast status change via WebSocket
        self.broadcast_status_change(
            experiment_id,
            &format!("{:?}", exp.status),
            &format!("{:?}", new_status),
            "pause",
            user_id,
        );

        Ok(ExperimentControlDto::from_experiment(&updated))
    }

    /// Resume the experiment (Paused -> Running)
    pub async fn resume(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<ExperimentControlDto, ExperimentControlError> {
        let exp = self.verify_ownership(experiment_id, user_id).await?;

        let new_status = StateMachine::transition(exp.status, StateMachineOperation::Resume)?;

        let updated = self
            .experiment_repo
            .update_state(
                experiment_id,
                new_status,
                MethodIdUpdate::Preserve,
                None,
                None,
            )
            .await?;

        let log = crate::models::entities::StateChangeLog::new(
            experiment_id,
            exp.status,
            new_status,
            StateMachineOperation::Resume,
            user_id,
        );
        self.log_repo
            .record(&log)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        // Broadcast status change via WebSocket
        self.broadcast_status_change(
            experiment_id,
            &format!("{:?}", exp.status),
            &format!("{:?}", new_status),
            "resume",
            user_id,
        );

        Ok(ExperimentControlDto::from_experiment(&updated))
    }

    /// Stop the experiment (Running -> Loaded, Paused -> Loaded)
    pub async fn stop(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<ExperimentControlDto, ExperimentControlError> {
        let exp = self.verify_ownership(experiment_id, user_id).await?;

        let new_status = StateMachine::transition(exp.status, StateMachineOperation::Stop)?;

        let updated = self
            .experiment_repo
            .update_state(
                experiment_id,
                new_status,
                MethodIdUpdate::Preserve,
                None,
                None,
            )
            .await?;

        let log = crate::models::entities::StateChangeLog::new(
            experiment_id,
            exp.status,
            new_status,
            StateMachineOperation::Stop,
            user_id,
        );
        self.log_repo
            .record(&log)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        // Broadcast status change via WebSocket
        self.broadcast_status_change(
            experiment_id,
            &format!("{:?}", exp.status),
            &format!("{:?}", new_status),
            "stop",
            user_id,
        );

        Ok(ExperimentControlDto::from_experiment(&updated))
    }

    /// Reset the experiment (Idle/Loaded/Running/Paused -> Idle)
    pub async fn reset(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<ExperimentControlDto, ExperimentControlError> {
        let exp = self
            .experiment_repo
            .find_by_id(experiment_id)
            .await?
            .ok_or(ExperimentControlError::NotFound(experiment_id))?;

        let new_status = StateMachine::transition(exp.status, StateMachineOperation::Reset)?;

        let updated = self
            .experiment_repo
            .update_state(experiment_id, new_status, MethodIdUpdate::Clear, None, None)
            .await?;

        let log = crate::models::entities::StateChangeLog::new(
            experiment_id,
            exp.status,
            new_status,
            StateMachineOperation::Reset,
            user_id,
        );
        self.log_repo
            .record(&log)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        // Broadcast status change via WebSocket
        self.broadcast_status_change(
            experiment_id,
            &format!("{:?}", exp.status),
            &format!("{:?}", new_status),
            "reset",
            user_id,
        );

        Ok(ExperimentControlDto::from_experiment(&updated))
    }

    /// Complete the experiment (Running -> Completed)
    pub async fn complete(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<ExperimentControlDto, ExperimentControlError> {
        let exp = self
            .experiment_repo
            .find_by_id(experiment_id)
            .await?
            .ok_or(ExperimentControlError::NotFound(experiment_id))?;

        let new_status = StateMachine::transition(exp.status, StateMachineOperation::Complete)?;

        let updated = self
            .experiment_repo
            .update_state(
                experiment_id,
                new_status,
                MethodIdUpdate::Preserve,
                None,
                Some(Utc::now()),
            )
            .await?;

        let log = crate::models::entities::StateChangeLog::new(
            experiment_id,
            exp.status,
            new_status,
            StateMachineOperation::Complete,
            user_id,
        );
        self.log_repo
            .record(&log)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        // Broadcast status change via WebSocket
        self.broadcast_status_change(
            experiment_id,
            &format!("{:?}", exp.status),
            &format!("{:?}", new_status),
            "complete",
            user_id,
        );

        Ok(ExperimentControlDto::from_experiment(&updated))
    }

    /// Abort the experiment (Running -> Aborted, Paused -> Aborted)
    pub async fn abort(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<ExperimentControlDto, ExperimentControlError> {
        let exp = self
            .experiment_repo
            .find_by_id(experiment_id)
            .await?
            .ok_or(ExperimentControlError::NotFound(experiment_id))?;

        let new_status = StateMachine::transition(exp.status, StateMachineOperation::Abort)?;

        let updated = self
            .experiment_repo
            .update_state(
                experiment_id,
                new_status,
                MethodIdUpdate::Preserve,
                None,
                Some(Utc::now()),
            )
            .await?;

        let log = crate::models::entities::StateChangeLog::new(
            experiment_id,
            exp.status,
            new_status,
            StateMachineOperation::Abort,
            user_id,
        );
        self.log_repo
            .record(&log)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        // Broadcast status change via WebSocket
        self.broadcast_status_change(
            experiment_id,
            &format!("{:?}", exp.status),
            &format!("{:?}", new_status),
            "abort",
            user_id,
        );

        Ok(ExperimentControlDto::from_experiment(&updated))
    }

    /// Get current experiment status
    pub async fn get_status(
        &self,
        experiment_id: Uuid,
    ) -> Result<ExperimentStatusDto, ExperimentControlError> {
        let exp = self
            .experiment_repo
            .find_by_id(experiment_id)
            .await?
            .ok_or(ExperimentControlError::NotFound(experiment_id))?;

        Ok(ExperimentStatusDto {
            id: exp.id.to_string(),
            name: exp.name,
            status: format!("{:?}", exp.status).to_uppercase(),
            method_id: exp.method_id.map(|u| u.to_string()),
            started_at: exp.started_at.map(|dt| dt.to_rfc3339()),
            ended_at: exp.ended_at.map(|dt| dt.to_rfc3339()),
            updated_at: exp.updated_at.to_rfc3339(),
        })
    }

    /// Get state change history for an experiment
    pub async fn get_history(
        &self,
        experiment_id: Uuid,
    ) -> Result<Vec<StateChangeLogDto>, ExperimentControlError> {
        let logs = self
            .log_repo
            .find_by_experiment(experiment_id)
            .await
            .map_err(|e| ExperimentControlError::Repository(e.to_string()))?;

        Ok(logs.iter().map(StateChangeLogDto::from_log).collect())
    }
}
