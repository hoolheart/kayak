//! Team management DTOs

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::models::entities::team::TeamRole;

// ==================== Request DTOs ====================

/// Create team request
#[derive(Debug, Deserialize, Validate)]
pub struct CreateTeamRequest {
    #[validate(length(min = 1, max = 255, message = "Name must be 1-255 characters"))]
    pub name: String,
    pub description: Option<String>,
}

/// Update team request
#[derive(Debug, Deserialize, Validate)]
pub struct UpdateTeamRequest {
    #[validate(length(min = 1, max = 255, message = "Name must be 1-255 characters"))]
    pub name: Option<String>,
    pub description: Option<String>,
}

/// Create invitation request
#[derive(Debug, Deserialize, Validate)]
pub struct CreateInvitationRequest {
    #[validate(email(message = "Invalid email format"))]
    pub email: String,
    pub role: TeamRole,
}

// ==================== Response DTOs ====================

/// Team response
#[derive(Debug, Serialize)]
pub struct TeamResponse {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub owner_id: Uuid,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Team with role response
#[derive(Debug, Serialize)]
pub struct TeamWithRoleResponse {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub owner_id: Uuid,
    pub role: TeamRole,
    pub member_count: u32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Team detail response
#[derive(Debug, Serialize)]
pub struct TeamDetailResponse {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub owner_id: Uuid,
    pub role: TeamRole,
    pub member_count: u32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Team list response
#[derive(Debug, Serialize)]
pub struct TeamListResponse {
    pub items: Vec<TeamWithRoleResponse>,
    pub total: u64,
    pub page: u32,
    pub size: u32,
}

/// Member response
#[derive(Debug, Serialize)]
pub struct MemberResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub role: TeamRole,
    pub joined_at: DateTime<Utc>,
}

/// Member list response
#[derive(Debug, Serialize)]
pub struct MemberListResponse {
    pub items: Vec<MemberResponse>,
    pub total: u64,
    pub page: u32,
    pub size: u32,
}

/// Invitation response
#[derive(Debug, Serialize)]
pub struct InvitationResponse {
    pub id: Uuid,
    pub team_id: Uuid,
    pub email: String,
    pub code: String,
    pub role: TeamRole,
    pub expires_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}

/// Accept invitation response
#[derive(Debug, Serialize)]
pub struct AcceptInvitationResponse {
    pub team_id: Uuid,
    pub team_name: String,
    pub role: TeamRole,
    pub joined_at: DateTime<Utc>,
}

/// List teams query parameters
#[derive(Debug, Deserialize)]
pub struct ListTeamsQuery {
    #[serde(default = "default_page")]
    pub page: u32,
    #[serde(default = "default_size")]
    pub size: u32,
}

/// List members query parameters
#[derive(Debug, Deserialize)]
pub struct ListMembersQuery {
    #[serde(default = "default_page")]
    pub page: u32,
    #[serde(default = "default_size")]
    pub size: u32,
}

fn default_page() -> u32 {
    1
}

fn default_size() -> u32 {
    20
}
