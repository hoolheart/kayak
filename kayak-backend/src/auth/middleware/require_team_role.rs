//! Team role authorization middleware
//!
//! Provides extractors that verify team membership and minimum role requirements.
//! These extractors query the database to validate membership and role hierarchy.
//!
//! # Usage
//!
//! ```rust,ignore
//! async fn handler(
//!     RequireTeamRole(team_ctx): RequireTeamRole,
//! ) -> impl IntoResponse {
//!     // team_ctx.role satisfies the required role
//! }
//! ```

use axum::async_trait;
use axum::extract::FromRequestParts;
use axum::http::request::Parts;
use std::ops::Deref;
use uuid::Uuid;

use crate::auth::UserContext;
use crate::core::error::AppError;
use crate::db::connection::DbPool;
use crate::models::entities::team::TeamRole;

/// Team context injected by RequireTeamRole extractors
#[derive(Debug, Clone)]
pub struct TeamContext {
    pub team_id: Uuid,
    pub user_id: Uuid,
    pub role: TeamRole,
}

/// Extract team ID from URI path
///
/// Supports paths like:
/// - `/api/v1/teams/{team_id}`
/// - `/api/v1/teams/{team_id}/members`
/// - `/api/v1/teams/{team_id}/invitations`
fn extract_team_id_from_path(parts: &Parts) -> Result<Uuid, AppError> {
    let path = parts.uri.path();
    let segments: Vec<&str> = path.split('/').filter(|s| !s.is_empty()).collect();

    // Look for pattern: .../teams/{id}/... or .../teams/{id}
    if let Some(pos) = segments.iter().position(|&s| s == "teams") {
        if let Some(team_id_str) = segments.get(pos + 1) {
            return Uuid::parse_str(team_id_str)
                .map_err(|_| AppError::BadRequest("Invalid team ID format".to_string()));
        }
    }

    Err(AppError::BadRequest("Team ID not found in path".to_string()))
}

/// Query team membership from database
async fn query_team_membership(
    pool: &DbPool,
    team_id: Uuid,
    user_id: Uuid,
) -> Result<TeamContext, AppError> {
    let row = sqlx::query_as::<_, (String,)>(
        "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
    )
    .bind(team_id.to_string())
    .bind(user_id.to_string())
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    match row {
        Some((role_str,)) => {
            let role = match role_str.as_str() {
                "Owner" => TeamRole::Owner,
                "Admin" => TeamRole::Admin,
                "Member" => TeamRole::Member,
                _ => {
                    return Err(AppError::InternalError(
                        "Invalid role in database".to_string(),
                    ))
                }
            };
            Ok(TeamContext {
                team_id,
                user_id,
                role,
            })
        }
        None => Err(AppError::Forbidden("Not a team member".to_string())),
    }
}

// ==================== RequireTeamRole ====================

/// Require any team membership (Member, Admin, or Owner)
///
/// Validates that the authenticated user is a member of the specified team.
/// Returns 403 if not a member.
pub struct RequireTeamRole(pub TeamContext);

#[async_trait]
impl<S> FromRequestParts<S> for RequireTeamRole
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        // 1. Extract UserContext from extensions (set by JwtAuthMiddleware)
        let user_ctx = parts
            .extensions
            .get::<UserContext>()
            .cloned()
            .ok_or_else(|| AppError::Unauthorized("Authentication required".to_string()))?;

        // 2. Extract team_id from path parameters
        let team_id = extract_team_id_from_path(parts)?;

        // 3. Extract DbPool from extensions
        let pool = parts
            .extensions
            .get::<DbPool>()
            .cloned()
            .ok_or_else(|| {
                AppError::InternalError("Database pool not available".to_string())
            })?;

        // 4. Query database for membership
        let team_ctx = query_team_membership(&pool, team_id, user_ctx.user_id).await?;

        Ok(RequireTeamRole(team_ctx))
    }
}

impl Deref for RequireTeamRole {
    type Target = TeamContext;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

// ==================== RequireTeamAdmin ====================

/// Require Admin or Owner role in team
///
/// Validates that the authenticated user is a member with Admin or Owner role.
/// Returns 403 if the user's role is insufficient.
pub struct RequireTeamAdmin(pub TeamContext);

#[async_trait]
impl<S> FromRequestParts<S> for RequireTeamAdmin
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let base = RequireTeamRole::from_request_parts(parts, state).await?;
        if !base.role.satisfies(TeamRole::Admin) {
            return Err(AppError::Forbidden("Admin role required".to_string()));
        }
        Ok(RequireTeamAdmin(base.0))
    }
}

impl Deref for RequireTeamAdmin {
    type Target = TeamContext;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

// ==================== RequireTeamOwner ====================

/// Require Owner role in team
///
/// Validates that the authenticated user is the team Owner.
/// Returns 403 if the user's role is not Owner.
pub struct RequireTeamOwner(pub TeamContext);

#[async_trait]
impl<S> FromRequestParts<S> for RequireTeamOwner
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let base = RequireTeamRole::from_request_parts(parts, state).await?;
        if base.role != TeamRole::Owner {
            return Err(AppError::Forbidden("Owner role required".to_string()));
        }
        Ok(RequireTeamOwner(base.0))
    }
}

impl Deref for RequireTeamOwner {
    type Target = TeamContext;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

// ==================== TeamPath (backward compatible path parser) ====================

/// Extract team ID from path and verify user is authenticated.
///
/// This extractor parses the team_id from the URL path and ensures
/// the request is authenticated. The service layer performs
/// the actual membership and role checks.
///
/// DEPRECATED: Use `RequireTeamRole`, `RequireTeamAdmin`, or `RequireTeamOwner`
/// for defense-in-depth authorization.
pub struct TeamPath(pub TeamContext);

#[async_trait]
impl<S> FromRequestParts<S> for TeamPath
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let user_ctx = parts
            .extensions
            .get::<UserContext>()
            .cloned()
            .ok_or_else(|| AppError::Unauthorized("Authentication required".to_string()))?;

        let team_id = extract_team_id_from_path(parts)?;

        Ok(TeamPath(TeamContext {
            team_id,
            user_id: user_ctx.user_id,
            role: TeamRole::Member, // Default; service layer validates actual role
        }))
    }
}

impl Deref for TeamPath {
    type Target = TeamContext;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::Request;

    fn make_parts(uri: &str) -> Parts {
        Request::builder().uri(uri).body(()).unwrap().into_parts().0
    }

    #[test]
    fn test_extract_team_id_simple() {
        let parts = make_parts("/api/v1/teams/550e8400-e29b-41d4-a716-446655440000");
        let id = extract_team_id_from_path(&parts).unwrap();
        assert_eq!(id.to_string(), "550e8400-e29b-41d4-a716-446655440000");
    }

    #[test]
    fn test_extract_team_id_nested() {
        let parts = make_parts("/api/v1/teams/550e8400-e29b-41d4-a716-446655440000/members");
        let id = extract_team_id_from_path(&parts).unwrap();
        assert_eq!(id.to_string(), "550e8400-e29b-41d4-a716-446655440000");
    }

    #[test]
    fn test_extract_team_id_invitations() {
        let parts = make_parts("/api/v1/teams/550e8400-e29b-41d4-a716-446655440000/invitations");
        let id = extract_team_id_from_path(&parts).unwrap();
        assert_eq!(id.to_string(), "550e8400-e29b-41d4-a716-446655440000");
    }

    #[test]
    fn test_extract_team_id_invalid_uuid() {
        let parts = make_parts("/api/v1/teams/not-a-uuid");
        let result = extract_team_id_from_path(&parts);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::BadRequest(_)));
    }

    #[test]
    fn test_extract_team_id_no_team_segment() {
        let parts = make_parts("/api/v1/users/550e8400-e29b-41d4-a716-446655440000");
        let result = extract_team_id_from_path(&parts);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::BadRequest(_)));
    }

    #[test]
    fn test_team_role_satisfies() {
        assert!(TeamRole::Owner.satisfies(TeamRole::Owner));
        assert!(TeamRole::Owner.satisfies(TeamRole::Admin));
        assert!(TeamRole::Owner.satisfies(TeamRole::Member));
        assert!(TeamRole::Admin.satisfies(TeamRole::Admin));
        assert!(TeamRole::Admin.satisfies(TeamRole::Member));
        assert!(TeamRole::Member.satisfies(TeamRole::Member));
        assert!(!TeamRole::Admin.satisfies(TeamRole::Owner));
        assert!(!TeamRole::Member.satisfies(TeamRole::Admin));
        assert!(!TeamRole::Member.satisfies(TeamRole::Owner));
    }
}
