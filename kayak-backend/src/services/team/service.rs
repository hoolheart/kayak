//! Team service implementation
//!
//! Uses repository traits for data access (Interface-Driven Development).
//! All multi-step operations use transactions for consistency.

use async_trait::async_trait;
use chrono::{DateTime, Duration, Utc};
use std::sync::Arc;
use uuid::Uuid;

use crate::db::connection::DbPool;
use crate::models::dto::team_dto::*;
use crate::models::entities::team::{Team, TeamInvitation, TeamRole};

use super::error::TeamServiceError;
use super::repository::{
    InvitationRepository, ResourceRepository, SqlxInvitationRepository, SqlxResourceRepository,
    SqlxTeamMemberRepository, SqlxTeamRepository, TeamMemberRepository, TeamRepository,
    TeamWithRole,
};

/// Team service trait
#[async_trait]
pub trait TeamService: Send + Sync {
    /// Create a new team. Creator becomes Owner.
    async fn create_team(
        &self,
        req: CreateTeamRequest,
        user_id: Uuid,
    ) -> Result<TeamResponse, TeamServiceError>;

    /// List teams where user is a member, with user's role in each.
    async fn list_my_teams(
        &self,
        user_id: Uuid,
        page: u32,
        size: u32,
    ) -> Result<TeamListResponse, TeamServiceError>;

    /// Get team details including user's role.
    async fn get_team(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<TeamDetailResponse, TeamServiceError>;

    /// Update team name/description. Requires Admin+.
    async fn update_team(
        &self,
        team_id: Uuid,
        req: UpdateTeamRequest,
        user_id: Uuid,
    ) -> Result<TeamResponse, TeamServiceError>;

    /// Delete team. Requires Owner. Fails if team has resources.
    async fn delete_team(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<(), TeamServiceError>;

    /// List team members. Any member can access.
    async fn list_members(
        &self,
        team_id: Uuid,
        user_id: Uuid,
        page: u32,
        size: u32,
    ) -> Result<MemberListResponse, TeamServiceError>;

    /// Remove a member. Owner can remove anyone; Admin can remove Member only.
    async fn remove_member(
        &self,
        team_id: Uuid,
        target_user_id: Uuid,
        actor_id: Uuid,
    ) -> Result<(), TeamServiceError>;

    /// Create an invitation. Requires Admin+.
    async fn create_invitation(
        &self,
        team_id: Uuid,
        req: CreateInvitationRequest,
        actor_id: Uuid,
    ) -> Result<InvitationResponse, TeamServiceError>;

    /// Accept an invitation by code.
    async fn accept_invitation(
        &self,
        code: String,
        user_id: Uuid,
    ) -> Result<AcceptInvitationResponse, TeamServiceError>;

    /// Leave a team. Owner cannot leave.
    async fn leave_team(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<(), TeamServiceError>;
}

/// Team service implementation
pub struct TeamServiceImpl {
    pool: DbPool,
    team_repo: Arc<dyn TeamRepository>,
    member_repo: Arc<dyn TeamMemberRepository>,
    invitation_repo: Arc<dyn InvitationRepository>,
    resource_repo: Arc<dyn ResourceRepository>,
}

impl TeamServiceImpl {
    /// Create a new team service instance with repository dependencies
    pub fn new(
        pool: DbPool,
        team_repo: Arc<dyn TeamRepository>,
        member_repo: Arc<dyn TeamMemberRepository>,
        invitation_repo: Arc<dyn InvitationRepository>,
        resource_repo: Arc<dyn ResourceRepository>,
    ) -> Self {
        Self {
            pool,
            team_repo,
            member_repo,
            invitation_repo,
            resource_repo,
        }
    }

    /// Convenience constructor from DbPool
    pub fn from_pool(pool: DbPool) -> Self {
        Self::new(
            pool.clone(),
            Arc::new(SqlxTeamRepository::new(pool.clone())),
            Arc::new(SqlxTeamMemberRepository::new(pool.clone())),
            Arc::new(SqlxInvitationRepository::new(pool.clone())),
            Arc::new(SqlxResourceRepository::new(pool)),
        )
    }

    /// Generate a 32-char Base64URL-safe invitation code
    fn generate_invitation_code() -> String {
        use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine};
        use rand::RngCore;

        let mut bytes = [0u8; 24]; // 24 bytes -> 32 Base64URL chars
        rand::thread_rng().fill_bytes(&mut bytes);
        URL_SAFE_NO_PAD.encode(bytes)
    }

    /// Convert TeamWithRole to TeamDetailResponse
    fn team_with_role_to_detail(twr: &TeamWithRole) -> Result<TeamDetailResponse, TeamServiceError> {
        Ok(TeamDetailResponse {
            id: parse_uuid(&twr.id)?,
            name: twr.name.clone(),
            description: twr.description.clone(),
            owner_id: parse_uuid(&twr.owner_id)?,
            role: parse_role(&twr.role),
            member_count: twr.member_count as u32,
            created_at: parse_datetime(&twr.created_at),
            updated_at: parse_datetime(&twr.updated_at),
        })
    }

    /// Convert TeamWithRole to TeamWithRoleResponse
    fn team_with_role_to_response(
        twr: &TeamWithRole,
    ) -> Result<TeamWithRoleResponse, TeamServiceError> {
        Ok(TeamWithRoleResponse {
            id: parse_uuid(&twr.id)?,
            name: twr.name.clone(),
            description: twr.description.clone(),
            owner_id: parse_uuid(&twr.owner_id)?,
            role: parse_role(&twr.role),
            member_count: twr.member_count as u32,
            created_at: parse_datetime(&twr.created_at),
            updated_at: parse_datetime(&twr.updated_at),
        })
    }
}

#[async_trait]
impl TeamService for TeamServiceImpl {
    async fn create_team(
        &self,
        req: CreateTeamRequest,
        user_id: Uuid,
    ) -> Result<TeamResponse, TeamServiceError> {
        // Validation is handled by #[derive(Validate)] in DTO,
        // but service layer also validates as defense in depth.
        if req.name.is_empty() || req.name.len() > 255 {
            return Err(TeamServiceError::ValidationError(
                "Name must be 1-255 characters".to_string(),
            ));
        }

        // Check if team name already exists for this user
        let exists = self
            .team_repo
            .exists_by_name_for_user(&req.name, user_id)
            .await?;

        if exists {
            return Err(TeamServiceError::DuplicateName);
        }

        let team = Team::new(req.name, req.description, user_id);

        // CR-002: Wrap in transaction
        let mut tx = self.pool.begin().await.map_err(|e| {
            TeamServiceError::Internal(format!("Failed to begin transaction: {e}"))
        })?;

        self.team_repo.create(&team, &mut tx).await?;
        self.member_repo
            .add_member(team.id, user_id, TeamRole::Owner, &mut tx)
            .await?;

        tx.commit().await.map_err(|e| {
            TeamServiceError::Internal(format!("Failed to commit transaction: {e}"))
        })?;

        Ok(TeamResponse {
            id: team.id,
            name: team.name,
            description: team.description,
            owner_id: team.owner_id,
            created_at: team.created_at,
            updated_at: team.updated_at,
        })
    }

    async fn list_my_teams(
        &self,
        user_id: Uuid,
        page: u32,
        size: u32,
    ) -> Result<TeamListResponse, TeamServiceError> {
        if page < 1 {
            return Err(TeamServiceError::ValidationError(
                "page must be >= 1".to_string(),
            ));
        }
        if !(1..=100).contains(&size) {
            return Err(TeamServiceError::ValidationError(
                "size must be 1-100".to_string(),
            ));
        }

        let (rows, total) = self
            .member_repo
            .find_teams_with_role(user_id, page, size)
            .await?;

        let items: Vec<TeamWithRoleResponse> = rows
            .iter()
            .map(Self::team_with_role_to_response)
            .collect::<Result<_, _>>()?;

        Ok(TeamListResponse {
            items,
            total,
            page,
            size,
        })
    }

    async fn get_team(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<TeamDetailResponse, TeamServiceError> {
        // ME-003: Single query instead of 3
        let row = self
            .member_repo
            .get_team_with_role(team_id, user_id)
            .await?;

        match row {
            Some(twr) => Ok(Self::team_with_role_to_detail(&twr)?),
            None => Err(TeamServiceError::NotMember),
        }
    }

    async fn update_team(
        &self,
        team_id: Uuid,
        req: UpdateTeamRequest,
        user_id: Uuid,
    ) -> Result<TeamResponse, TeamServiceError> {
        // Verify actor is Admin+
        let role = self
            .member_repo
            .get_role(team_id, user_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        if !role.satisfies(TeamRole::Admin) {
            return Err(TeamServiceError::Forbidden(
                "Admin role required".to_string(),
            ));
        }

        // Validate
        if let Some(ref name) = req.name {
            if name.is_empty() || name.len() > 255 {
                return Err(TeamServiceError::ValidationError(
                    "Name must be 1-255 characters".to_string(),
                ));
            }
        }

        // ME-001: Static query with conditional binding (no dynamic SQL)
        let name_opt = req.name.as_deref();
        let desc_opt = req.description.as_deref();

        let rows_affected = self
            .team_repo
            .update(team_id, name_opt, desc_opt)
            .await?;

        if rows_affected == 0 {
            return Err(TeamServiceError::NotFound);
        }

        let team = self
            .team_repo
            .find_by_id(team_id)
            .await?
            .ok_or(TeamServiceError::NotFound)?;

        Ok(TeamResponse {
            id: team.id,
            name: team.name,
            description: team.description,
            owner_id: team.owner_id,
            created_at: team.created_at,
            updated_at: team.updated_at,
        })
    }

    async fn delete_team(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<(), TeamServiceError> {
        // Verify actor is Owner
        let role = self
            .member_repo
            .get_role(team_id, user_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        if role != TeamRole::Owner {
            return Err(TeamServiceError::Forbidden(
                "Only Owner can delete team".to_string(),
            ));
        }

        // Check for resources
        let has_resources = self.resource_repo.has_team_resources(team_id).await?;
        if has_resources {
            return Err(TeamServiceError::TeamHasResources);
        }

        // Delete team (cascades to members and invitations via FK)
        let rows_affected = self.team_repo.delete(team_id).await?;

        if rows_affected == 0 {
            return Err(TeamServiceError::NotFound);
        }

        Ok(())
    }

    async fn list_members(
        &self,
        team_id: Uuid,
        user_id: Uuid,
        page: u32,
        size: u32,
    ) -> Result<MemberListResponse, TeamServiceError> {
        // Verify membership
        self.member_repo
            .get_role(team_id, user_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        if page < 1 {
            return Err(TeamServiceError::ValidationError(
                "page must be >= 1".to_string(),
            ));
        }
        if !(1..=100).contains(&size) {
            return Err(TeamServiceError::ValidationError(
                "size must be 1-100".to_string(),
            ));
        }

        let (rows, total) = self.member_repo.find_by_team(team_id, page, size).await?;

        let items: Vec<MemberResponse> = rows
            .into_iter()
            .map(|row| {
                Ok(MemberResponse {
                    id: parse_uuid(&row.id)?,
                    user_id: parse_uuid(&row.user_id)?,
                    email: row.email,
                    username: row.username,
                    role: parse_role(&row.role),
                    joined_at: parse_datetime(&row.joined_at),
                })
            })
            .collect::<Result<_, TeamServiceError>>()?;

        Ok(MemberListResponse {
            items,
            total,
            page,
            size,
        })
    }

    async fn remove_member(
        &self,
        team_id: Uuid,
        target_user_id: Uuid,
        actor_id: Uuid,
    ) -> Result<(), TeamServiceError> {
        // Cannot remove self via this endpoint
        if target_user_id == actor_id {
            return Err(TeamServiceError::Forbidden(
                "Use POST /teams/:id/leave to leave team".to_string(),
            ));
        }

        // Get actor's role
        let actor_role = self
            .member_repo
            .get_role(team_id, actor_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        // Get target's role
        let target_role = self
            .member_repo
            .get_role(team_id, target_user_id)
            .await?
            .ok_or(TeamServiceError::MemberNotFound)?;

        // Authorization matrix
        let can_remove = match (actor_role, target_role) {
            (TeamRole::Owner, _) => true,                // Owner can remove anyone
            (TeamRole::Admin, TeamRole::Member) => true, // Admin can remove Member
            (TeamRole::Admin, TeamRole::Admin) => false, // Admin cannot remove Admin
            (TeamRole::Admin, TeamRole::Owner) => false, // Admin cannot remove Owner
            (TeamRole::Member, _) => false,              // Member cannot remove anyone
        };

        if !can_remove {
            return Err(TeamServiceError::Forbidden(
                "Insufficient permissions to remove this member".to_string(),
            ));
        }

        let rows_affected = self
            .member_repo
            .remove_member(team_id, target_user_id)
            .await?;

        if rows_affected == 0 {
            return Err(TeamServiceError::MemberNotFound);
        }

        Ok(())
    }

    async fn create_invitation(
        &self,
        team_id: Uuid,
        req: CreateInvitationRequest,
        actor_id: Uuid,
    ) -> Result<InvitationResponse, TeamServiceError> {
        // Validate role (cannot invite as Owner)
        if req.role == TeamRole::Owner {
            return Err(TeamServiceError::ValidationError(
                "Cannot invite as Owner".to_string(),
            ));
        }

        // Validate email
        if req.email.is_empty() || !req.email.contains('@') {
            return Err(TeamServiceError::ValidationError(
                "Invalid email format".to_string(),
            ));
        }

        // Verify actor is Admin+
        let role = self
            .member_repo
            .get_role(team_id, actor_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        if !role.satisfies(TeamRole::Admin) {
            return Err(TeamServiceError::Forbidden(
                "Admin role required".to_string(),
            ));
        }

        // Check if email is already a member
        let existing_member: Option<(String,)> = sqlx::query_as(
            r#"
            SELECT tm.id FROM team_members tm
            JOIN users u ON tm.user_id = u.id
            WHERE tm.team_id = ? AND u.email = ?
            "#,
        )
        .bind(team_id.to_string())
        .bind(&req.email)
        .fetch_optional(&self.pool)
        .await?;

        if existing_member.is_some() {
            return Err(TeamServiceError::AlreadyMember);
        }

        // Generate code
        let code = Self::generate_invitation_code();

        // Create invitation (expires in 7 days)
        let invitation = TeamInvitation::new(
            team_id,
            req.email,
            code,
            req.role,
            Utc::now() + Duration::days(7),
        );

        self.invitation_repo.create(&invitation).await?;

        Ok(InvitationResponse {
            id: invitation.id,
            team_id: invitation.team_id,
            email: invitation.email,
            code: invitation.code,
            role: invitation.role,
            expires_at: invitation.expires_at,
            created_at: invitation.created_at,
        })
    }

    async fn accept_invitation(
        &self,
        code: String,
        user_id: Uuid,
    ) -> Result<AcceptInvitationResponse, TeamServiceError> {
        // Find invitation
        let invitation = self
            .invitation_repo
            .find_by_code(&code)
            .await?
            .ok_or(TeamServiceError::InvitationNotFound)?;

        // HI-001: Single uniform error for ALL invalid invitation states
        // Only differentiate after invitation is confirmed valid
        if invitation.used_at.is_some() {
            return Err(TeamServiceError::InvitationNotFound);
        }

        if invitation.is_expired() {
            return Err(TeamServiceError::InvitationNotFound);
        }

        let team_id = invitation.team_id;
        let role = invitation.role;

        // Check if user is already a member
        let existing = self.member_repo.get_role(team_id, user_id).await?;
        if existing.is_some() {
            return Err(TeamServiceError::AlreadyMember);
        }

        // CR-002: Wrap in transaction
        let mut tx = self.pool.begin().await.map_err(|e| {
            TeamServiceError::Internal(format!("Failed to begin transaction: {e}"))
        })?;

        self.member_repo
            .add_member(team_id, user_id, role, &mut tx)
            .await?;
        self.invitation_repo
            .mark_used(invitation.id, &mut tx)
            .await?;

        tx.commit().await.map_err(|e| {
            TeamServiceError::Internal(format!("Failed to commit transaction: {e}"))
        })?;

        // Get team name
        let team = self
            .team_repo
            .find_by_id(team_id)
            .await?
            .ok_or(TeamServiceError::NotFound)?;

        Ok(AcceptInvitationResponse {
            team_id,
            team_name: team.name,
            role,
            joined_at: Utc::now(),
        })
    }

    async fn leave_team(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<(), TeamServiceError> {
        // Get user's role
        let role = self
            .member_repo
            .get_role(team_id, user_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        // Owner cannot leave
        if role == TeamRole::Owner {
            return Err(TeamServiceError::OwnerCannotLeave);
        }

        let rows_affected = self.member_repo.remove_member(team_id, user_id).await?;

        if rows_affected == 0 {
            return Err(TeamServiceError::MemberNotFound);
        }

        Ok(())
    }
}

// ==================== Helper Functions ====================

fn parse_uuid(s: &str) -> Result<Uuid, TeamServiceError> {
    Uuid::parse_str(s).map_err(|e| TeamServiceError::Internal(format!("Invalid UUID in DB: {e}")))
}

fn parse_role(role_str: &str) -> TeamRole {
    match role_str {
        "Owner" => TeamRole::Owner,
        "Admin" => TeamRole::Admin,
        _ => TeamRole::Member,
    }
}

fn parse_datetime(s: &str) -> DateTime<Utc> {
    DateTime::parse_from_rfc3339(s)
        .map(|dt| dt.with_timezone(&Utc))
        .unwrap_or_else(|_| Utc::now())
}
