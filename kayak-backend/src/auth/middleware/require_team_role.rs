//! Team role authorization middleware
//!
//! Provides extractors that parse team_id from the request path.
//! Actual authorization checks are performed by the service layer.

use axum::async_trait;
use axum::extract::FromRequestParts;
use axum::http::request::Parts;
use std::ops::Deref;
use uuid::Uuid;

use crate::auth::UserContext;
use crate::core::error::AppError;

/// Team context
#[derive(Debug, Clone)]
pub struct TeamContext {
    pub team_id: Uuid,
    pub user_id: Uuid,
}

/// Extract team ID from path and verify user is authenticated.
///
/// This extractor parses the team_id from the URL path (e.g., `/api/v1/teams/{id}`)
/// and ensures the request is authenticated. The service layer performs
/// the actual membership and role checks.
///
/// # Usage
/// ```rust,ignore
/// async fn handler(
///     TeamPath(team_ctx): TeamPath,
/// ) -> impl IntoResponse {
///     // team_ctx.team_id is the parsed UUID
///     // team_ctx.user_id is the authenticated user's ID
/// }
/// ```
pub struct TeamPath(pub TeamContext);

#[async_trait]
impl<S> FromRequestParts<S> for TeamPath
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(
        parts: &mut Parts,
        _state: &S,
    ) -> Result<Self, Self::Rejection> {
        let user_ctx = parts
            .extensions
            .get::<UserContext>()
            .cloned()
            .ok_or_else(|| AppError::Unauthorized("Authentication required".to_string()))?;

        let team_id = extract_team_id_from_path(parts)?;

        Ok(TeamPath(TeamContext {
            team_id,
            user_id: user_ctx.user_id,
        }))
    }
}

impl Deref for TeamPath {
    type Target = TeamContext;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_team_id_simple() {
        let mut parts = Parts::default();
        parts.uri = "/api/v1/teams/550e8400-e29b-41d4-a716-446655440000"
            .parse()
            .unwrap();
        let id = extract_team_id_from_path(&parts).unwrap();
        assert_eq!(id.to_string(), "550e8400-e29b-41d4-a716-446655440000");
    }

    #[test]
    fn test_extract_team_id_nested() {
        let mut parts = Parts::default();
        parts.uri = "/api/v1/teams/550e8400-e29b-41d4-a716-446655440000/members"
            .parse()
            .unwrap();
        let id = extract_team_id_from_path(&parts).unwrap();
        assert_eq!(id.to_string(), "550e8400-e29b-41d4-a716-446655440000");
    }

    #[test]
    fn test_extract_team_id_invitations() {
        let mut parts = Parts::default();
        parts.uri = "/api/v1/teams/550e8400-e29b-41d4-a716-446655440000/invitations"
            .parse()
            .unwrap();
        let id = extract_team_id_from_path(&parts).unwrap();
        assert_eq!(id.to_string(), "550e8400-e29b-41d4-a716-446655440000");
    }

    #[test]
    fn test_extract_team_id_invalid_uuid() {
        let mut parts = Parts::default();
        parts.uri = "/api/v1/teams/not-a-uuid".parse().unwrap();
        let result = extract_team_id_from_path(&parts);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::BadRequest(_)));
    }

    #[test]
    fn test_extract_team_id_no_team_segment() {
        let mut parts = Parts::default();
        parts.uri = "/api/v1/users/550e8400-e29b-41d4-a716-446655440000"
            .parse()
            .unwrap();
        let result = extract_team_id_from_path(&parts);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::BadRequest(_)));
    }
}
