//! Team service error types

use thiserror::Error;

/// Team service error type
#[derive(Debug, Error)]
pub enum TeamServiceError {
    #[error("Team not found")]
    NotFound,

    #[error("Team member not found")]
    MemberNotFound,

    #[error("Invitation not found")]
    InvitationNotFound,

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
            TeamServiceError::MemberNotFound => {
                AppError::NotFound("Team member not found".to_string())
            }
            TeamServiceError::InvitationNotFound => {
                AppError::NotFound("Invitation not found".to_string())
            }
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::error::AppError;

    #[test]
    fn test_error_display() {
        assert_eq!(
            format!("{}", TeamServiceError::NotFound),
            "Team not found"
        );
        assert_eq!(
            format!("{}", TeamServiceError::Forbidden("test".to_string())),
            "Insufficient permissions: test"
        );
        assert_eq!(
            format!("{}", TeamServiceError::ValidationError("bad".to_string())),
            "Validation error: bad"
        );
    }

    #[test]
    fn test_from_sqlx_error() {
        let sqlx_err = sqlx::Error::RowNotFound;
        let team_err: TeamServiceError = sqlx_err.into();
        assert!(matches!(team_err, TeamServiceError::Internal(_)));
    }

    #[test]
    fn test_into_app_error_not_found() {
        let app_err: AppError = TeamServiceError::NotFound.into();
        assert!(matches!(app_err, AppError::NotFound(_)));
    }

    #[test]
    fn test_into_app_error_forbidden() {
        let app_err: AppError = TeamServiceError::Forbidden("no access".to_string()).into();
        assert!(matches!(app_err, AppError::Forbidden(_)));
    }

    #[test]
    fn test_into_app_error_conflict() {
        let app_err: AppError = TeamServiceError::DuplicateName.into();
        assert!(matches!(app_err, AppError::Conflict(_)));

        let app_err: AppError = TeamServiceError::AlreadyMember.into();
        assert!(matches!(app_err, AppError::Conflict(_)));
    }

    #[test]
    fn test_into_app_error_bad_request() {
        let app_err: AppError = TeamServiceError::ValidationError("invalid".to_string()).into();
        assert!(matches!(app_err, AppError::BadRequest(_)));
    }

    #[test]
    fn test_into_app_error_owner_cannot_leave() {
        let app_err: AppError = TeamServiceError::OwnerCannotLeave.into();
        assert!(matches!(app_err, AppError::Forbidden(_)));
    }

    #[test]
    fn test_into_app_error_team_has_resources() {
        let app_err: AppError = TeamServiceError::TeamHasResources.into();
        assert!(matches!(app_err, AppError::Conflict(_)));
    }

    #[test]
    fn test_into_app_error_invitation_not_found() {
        let app_err: AppError = TeamServiceError::InvitationNotFound.into();
        assert!(matches!(app_err, AppError::NotFound(_)));
    }

    #[test]
    fn test_into_app_error_member_not_found() {
        let app_err: AppError = TeamServiceError::MemberNotFound.into();
        assert!(matches!(app_err, AppError::NotFound(_)));
    }

    #[test]
    fn test_into_app_error_not_member() {
        let app_err: AppError = TeamServiceError::NotMember.into();
        assert!(matches!(app_err, AppError::Forbidden(_)));
    }

    #[test]
    fn test_into_app_error_invitation_expired() {
        let app_err: AppError = TeamServiceError::InvitationExpired.into();
        assert!(matches!(app_err, AppError::BadRequest(_)));
    }

    #[test]
    fn test_into_app_error_invitation_used() {
        let app_err: AppError = TeamServiceError::InvitationUsed.into();
        assert!(matches!(app_err, AppError::Conflict(_)));
    }

    #[test]
    fn test_into_app_error_internal() {
        let app_err: AppError = TeamServiceError::Internal("db error".to_string()).into();
        assert!(matches!(app_err, AppError::InternalError(_)));
    }
}
