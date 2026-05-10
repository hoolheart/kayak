//! Team service error types

use thiserror::Error;

/// Team service error type
#[derive(Debug, Error)]
pub enum TeamServiceError {
    #[error("Team not found")]
    NotFound,

    #[error("Not a team member")]
    NotMember,

    #[error("Insufficient permissions: {0}")]
    Forbidden(String),

    #[error("Team name already exists")]
    DuplicateName,

    #[error("User is already a member")]
    AlreadyMember,

    #[error("Invitation expired")]
    InvitationExpired,

    #[error("Invitation already used")]
    InvitationUsed,

    #[error("Owner cannot leave team")]
    OwnerCannotLeave,

    #[error("Cannot delete team with existing resources")]
    TeamHasResources,

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Internal error: {0}")]
    Internal(String),
}

impl From<sqlx::Error> for TeamServiceError {
    fn from(err: sqlx::Error) -> Self {
        TeamServiceError::Internal(err.to_string())
    }
}

impl From<TeamServiceError> for crate::core::error::AppError {
    fn from(err: TeamServiceError) -> Self {
        use crate::core::error::AppError;
        match err {
            TeamServiceError::NotFound => AppError::NotFound("Team not found".to_string()),
            TeamServiceError::NotMember => {
                AppError::Forbidden("Not a team member".to_string())
            }
            TeamServiceError::Forbidden(msg) => AppError::Forbidden(msg),
            TeamServiceError::DuplicateName => {
                AppError::Conflict("Team name already exists".to_string())
            }
            TeamServiceError::AlreadyMember => {
                AppError::Conflict("User is already a member".to_string())
            }
            TeamServiceError::InvitationExpired => {
                AppError::BadRequest("Invitation has expired".to_string())
            }
            TeamServiceError::InvitationUsed => {
                AppError::Conflict("Invitation has already been used".to_string())
            }
            TeamServiceError::OwnerCannotLeave => AppError::Forbidden(
                "Owner cannot leave team. Transfer ownership first.".to_string(),
            ),
            TeamServiceError::TeamHasResources => {
                AppError::Conflict("Cannot delete team with existing resources.".to_string())
            }
            TeamServiceError::ValidationError(msg) => AppError::BadRequest(msg),
            TeamServiceError::Internal(msg) => AppError::InternalError(msg),
        }
    }
}
