//! Team management API handlers

use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::auth::{RequireAuth, RequireTeamAdmin, RequireTeamOwner, RequireTeamRole};
use crate::core::error::{ApiResponse, AppError};
use crate::models::dto::team_dto::*;
use crate::services::team::TeamService;

/// Team handler state type
type TeamHandlerState = Arc<dyn TeamService>;

/// POST /api/v1/teams - Create team
pub async fn create_team(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    Json(req): Json<CreateTeamRequest>,
) -> Result<Json<ApiResponse<TeamResponse>>, AppError> {
    let team = service
        .create_team(req, user_ctx.user_id)
        .await
        .map_err(AppError::from)?;

    Ok(Json(ApiResponse::created(team)))
}

/// GET /api/v1/teams - List my teams
pub async fn list_my_teams(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    Query(query): Query<ListTeamsQuery>,
) -> Result<Json<ApiResponse<TeamListResponse>>, AppError> {
    let result = service
        .list_my_teams(user_ctx.user_id, query.page, query.size)
        .await
        .map_err(AppError::from)?;

    Ok(Json(ApiResponse::success(result)))
}

/// GET /api/v1/teams/:id - Get team details
/// Requires: any team member
pub async fn get_team(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    RequireTeamRole(_team_ctx): RequireTeamRole,
    Path(team_id): Path<Uuid>,
) -> Result<Json<ApiResponse<TeamDetailResponse>>, AppError> {
    let team = service
        .get_team(team_id, user_ctx.user_id)
        .await
        .map_err(AppError::from)?;

    Ok(Json(ApiResponse::success(team)))
}

/// PUT /api/v1/teams/:id - Update team
/// Requires: Admin or Owner
pub async fn update_team(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    RequireTeamAdmin(_team_ctx): RequireTeamAdmin,
    Path(team_id): Path<Uuid>,
    Json(req): Json<UpdateTeamRequest>,
) -> Result<Json<ApiResponse<TeamResponse>>, AppError> {
    let team = service
        .update_team(team_id, req, user_ctx.user_id)
        .await
        .map_err(AppError::from)?;

    Ok(Json(ApiResponse::success(team)))
}

/// DELETE /api/v1/teams/:id - Delete team
/// Requires: Owner
pub async fn delete_team(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    RequireTeamOwner(_team_ctx): RequireTeamOwner,
    Path(team_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    service
        .delete_team(team_id, user_ctx.user_id)
        .await
        .map_err(AppError::from)?;

    Ok(StatusCode::NO_CONTENT)
}

/// GET /api/v1/teams/:id/members - List members
/// Requires: any team member
pub async fn list_members(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    RequireTeamRole(_team_ctx): RequireTeamRole,
    Path(team_id): Path<Uuid>,
    Query(query): Query<ListMembersQuery>,
) -> Result<Json<ApiResponse<MemberListResponse>>, AppError> {
    let result = service
        .list_members(team_id, user_ctx.user_id, query.page, query.size)
        .await
        .map_err(AppError::from)?;

    Ok(Json(ApiResponse::success(result)))
}

/// DELETE /api/v1/teams/:id/members/:user_id - Remove member
/// Requires: Admin or Owner
pub async fn remove_member(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    RequireTeamAdmin(_team_ctx): RequireTeamAdmin,
    Path((team_id, target_user_id)): Path<(Uuid, Uuid)>,
) -> Result<StatusCode, AppError> {
    service
        .remove_member(team_id, target_user_id, user_ctx.user_id)
        .await
        .map_err(AppError::from)?;

    Ok(StatusCode::NO_CONTENT)
}

/// POST /api/v1/teams/:id/invitations - Create invitation
/// Requires: Admin or Owner
pub async fn create_invitation(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    RequireTeamAdmin(_team_ctx): RequireTeamAdmin,
    Path(team_id): Path<Uuid>,
    Json(req): Json<CreateInvitationRequest>,
) -> Result<Json<ApiResponse<InvitationResponse>>, AppError> {
    let invitation = service
        .create_invitation(team_id, req, user_ctx.user_id)
        .await
        .map_err(AppError::from)?;

    Ok(Json(ApiResponse::created(invitation)))
}

/// POST /api/v1/invitations/:code/accept - Accept invitation
pub async fn accept_invitation(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(code): Path<String>,
) -> Result<Json<ApiResponse<AcceptInvitationResponse>>, AppError> {
    let result = service
        .accept_invitation(code, user_ctx.user_id)
        .await
        .map_err(AppError::from)?;

    Ok(Json(ApiResponse::success(result)))
}

/// POST /api/v1/teams/:id/leave - Leave team
/// Requires: any team member (service layer enforces Owner cannot leave)
pub async fn leave_team(
    State(service): State<TeamHandlerState>,
    RequireAuth(user_ctx): RequireAuth,
    RequireTeamRole(_team_ctx): RequireTeamRole,
    Path(team_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    service
        .leave_team(team_id, user_ctx.user_id)
        .await
        .map_err(AppError::from)?;

    Ok(StatusCode::NO_CONTENT)
}
