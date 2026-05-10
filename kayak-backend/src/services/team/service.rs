//! Team service implementation

use async_trait::async_trait;
use chrono::{DateTime, Duration, Utc};
use sqlx::FromRow;
use uuid::Uuid;

use crate::db::connection::DbPool;
use crate::models::dto::team_dto::*;
use crate::models::entities::team::{Team, TeamInvitation, TeamMember, TeamRole};

use super::error::TeamServiceError;

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
}

impl TeamServiceImpl {
    /// Create a new team service instance
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }

    /// Generate a 32-char Base64URL-safe invitation code
    fn generate_invitation_code() -> String {
        use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine};
        use rand::RngCore;

        let mut bytes = [0u8; 24]; // 24 bytes -> 32 Base64URL chars
        rand::thread_rng().fill_bytes(&mut bytes);
        URL_SAFE_NO_PAD.encode(bytes)
    }

    /// Get user's role in a team
    async fn get_user_role(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<Option<TeamRole>, TeamServiceError> {
        let row: Option<( String,)> = sqlx::query_as(
            "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
        )
        .bind(team_id.to_string())
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(role_str,)| match role_str.as_str() {
            "Owner" => TeamRole::Owner,
            "Admin" => TeamRole::Admin,
            _ => TeamRole::Member,
        }))
    }

    /// Count members in a team
    async fn count_members(&self, team_id: Uuid) -> Result<u32, TeamServiceError> {
        let row: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM team_members WHERE team_id = ?")
            .bind(team_id.to_string())
            .fetch_one(&self.pool)
            .await?;

        Ok(row.0 as u32)
    }

    /// Check if team has resources (experiments, workbenches, methods)
    async fn has_team_resources(
        &self,
        team_id: Uuid,
    ) -> Result<bool, TeamServiceError> {
        let result: Option<(i64,)> = sqlx::query_as(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM experiments WHERE owner_type = 'team' AND owner_id = ?
                UNION ALL
                SELECT 1 FROM workbenches WHERE owner_type = 'team' AND owner_id = ?
                UNION ALL
                SELECT 1 FROM methods WHERE owner_type = 'team' AND owner_id = ?
            ) AS has_resources
            "#,
        )
        .bind(team_id.to_string())
        .bind(team_id.to_string())
        .bind(team_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(result.map(|r| r.0 > 0).unwrap_or(false))
    }
}

#[derive(Debug, FromRow)]
struct TeamRow {
    id: String,
    name: String,
    description: Option<String>,
    owner_id: String,
    created_at: String,
    updated_at: String,
}

impl TeamRow {
    fn into_team(self) -> Team {
        Team {
            id: Uuid::parse_str(&self.id).unwrap_or_default(),
            name: self.name,
            description: self.description,
            owner_id: Uuid::parse_str(&self.owner_id).unwrap_or_default(),
            created_at: DateTime::parse_from_rfc3339(&self.created_at)
                .map(|dt| dt.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now()),
            updated_at: DateTime::parse_from_rfc3339(&self.updated_at)
                .map(|dt| dt.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now()),
        }
    }
}

#[derive(Debug, FromRow)]
struct MemberRow {
    id: String,
    user_id: String,
    email: String,
    username: Option<String>,
    role: String,
    joined_at: String,
}

#[derive(Debug, FromRow)]
#[allow(dead_code)]
struct InvitationRow {
    id: String,
    team_id: String,
    email: String,
    code: String,
    role: String,
    expires_at: String,
    used_at: Option<String>,
    created_at: String,
}

#[async_trait]
impl TeamService for TeamServiceImpl {
    async fn create_team(
        &self,
        req: CreateTeamRequest,
        user_id: Uuid,
    ) -> Result<TeamResponse, TeamServiceError> {
        // Validation
        if req.name.is_empty() || req.name.len() > 255 {
            return Err(TeamServiceError::ValidationError(
                "Name must be 1-255 characters".to_string(),
            ));
        }

        // Check if team name already exists for this user
        let exists: Option<(String,)> = sqlx::query_as(
            r#"
            SELECT t.name FROM teams t
            JOIN team_members tm ON t.id = tm.team_id
            WHERE tm.user_id = ? AND t.name = ?
            "#,
        )
        .bind(user_id.to_string())
        .bind(&req.name)
        .fetch_optional(&self.pool)
        .await?;

        if exists.is_some() {
            return Err(TeamServiceError::DuplicateName);
        }

        let team = Team::new(req.name, req.description, user_id);
        let member = TeamMember::new(team.id, user_id, TeamRole::Owner);

        // Insert team
        sqlx::query(
            r#"
            INSERT INTO teams (id, name, description, owner_id, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(team.id.to_string())
        .bind(&team.name)
        .bind(&team.description)
        .bind(team.owner_id.to_string())
        .bind(team.created_at.to_rfc3339())
        .bind(team.updated_at.to_rfc3339())
        .execute(&self.pool)
        .await?;

        // Insert owner membership
        sqlx::query(
            r#"
            INSERT INTO team_members (id, team_id, user_id, role, joined_at)
            VALUES (?, ?, ?, ?, ?)
            "#,
        )
        .bind(member.id.to_string())
        .bind(member.team_id.to_string())
        .bind(member.user_id.to_string())
        .bind("Owner")
        .bind(member.joined_at.to_rfc3339())
        .execute(&self.pool)
        .await?;

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

        let offset = (page - 1) * size;

        // Get total count of teams the user is a member of
        let count_row: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM team_members WHERE user_id = ?",
        )
        .bind(user_id.to_string())
        .fetch_one(&self.pool)
        .await?;

        let total = count_row.0 as u64;

        // Get teams with role and member count
        let rows = sqlx::query_as::<_, (String, String, Option<String>, String, String, String, String, i64)>(
            r#"
            SELECT 
                t.id, t.name, t.description, t.owner_id, 
                t.created_at, t.updated_at,
                tm.role as member_role,
                (SELECT COUNT(*) FROM team_members WHERE team_id = t.id) as member_count
            FROM teams t
            JOIN team_members tm ON t.id = tm.team_id
            WHERE tm.user_id = ?
            ORDER BY t.created_at DESC
            LIMIT ? OFFSET ?
            "#,
        )
        .bind(user_id.to_string())
        .bind(size as i64)
        .bind(offset as i64)
        .fetch_all(&self.pool)
        .await?;

        let items: Vec<TeamWithRoleResponse> = rows
            .into_iter()
            .map(|(id, name, description, owner_id, created_at, updated_at, role, member_count)| {
                let role = match role.as_str() {
                    "Owner" => TeamRole::Owner,
                    "Admin" => TeamRole::Admin,
                    _ => TeamRole::Member,
                };

                TeamWithRoleResponse {
                    id: Uuid::parse_str(&id).unwrap_or_default(),
                    name,
                    description,
                    owner_id: Uuid::parse_str(&owner_id).unwrap_or_default(),
                    role,
                    member_count: member_count as u32,
                    created_at: DateTime::parse_from_rfc3339(&created_at)
                        .map(|dt| dt.with_timezone(&Utc))
                        .unwrap_or_else(|_| Utc::now()),
                    updated_at: DateTime::parse_from_rfc3339(&updated_at)
                        .map(|dt| dt.with_timezone(&Utc))
                        .unwrap_or_else(|_| Utc::now()),
                }
            })
            .collect();

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
        // Verify membership
        let role = self
            .get_user_role(team_id, user_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        let row: Option<TeamRow> = sqlx::query_as("SELECT * FROM teams WHERE id = ?")
            .bind(team_id.to_string())
            .fetch_optional(&self.pool)
            .await?;

        let team = match row {
            Some(r) => r.into_team(),
            None => return Err(TeamServiceError::NotFound),
        };

        let member_count = self.count_members(team_id).await?;

        Ok(TeamDetailResponse {
            id: team.id,
            name: team.name,
            description: team.description,
            owner_id: team.owner_id,
            role,
            member_count,
            created_at: team.created_at,
            updated_at: team.updated_at,
        })
    }

    async fn update_team(
        &self,
        team_id: Uuid,
        req: UpdateTeamRequest,
        user_id: Uuid,
    ) -> Result<TeamResponse, TeamServiceError> {
        // Verify actor is Admin+
        let role = self
            .get_user_role(team_id, user_id)
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

        // Build dynamic update
        let mut updates = Vec::new();
        let mut values: Vec<String> = Vec::new();

        if let Some(ref name) = req.name {
            updates.push("name = ?");
            values.push(name.clone());
        }
        if req.description.is_some() {
            updates.push("description = ?");
            values.push(req.description.clone().unwrap_or_default());
        }

        if updates.is_empty() {
            // No updates, return current team
            return self
                .get_team(team_id, user_id)
                .await
                .map(|t| TeamResponse {
                    id: t.id,
                    name: t.name,
                    description: t.description,
                    owner_id: t.owner_id,
                    created_at: t.created_at,
                    updated_at: t.updated_at,
                });
        }

        updates.push("updated_at = ?");
        values.push(Utc::now().to_rfc3339());

        let query = format!("UPDATE teams SET {} WHERE id = ?", updates.join(", "));

        let mut q = sqlx::query(&query);
        for v in &values {
            q = q.bind(v);
        }
        q = q.bind(team_id.to_string());

        let result = q.execute(&self.pool).await?;
        if result.rows_affected() == 0 {
            return Err(TeamServiceError::NotFound);
        }

        let row: TeamRow = sqlx::query_as("SELECT * FROM teams WHERE id = ?")
            .bind(team_id.to_string())
            .fetch_one(&self.pool)
            .await?;

        let team = row.into_team();
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
            .get_user_role(team_id, user_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        if role != TeamRole::Owner {
            return Err(TeamServiceError::Forbidden(
                "Only Owner can delete team".to_string(),
            ));
        }

        // Check for resources
        let has_resources = self.has_team_resources(team_id).await?;
        if has_resources {
            return Err(TeamServiceError::TeamHasResources);
        }

        // Delete team (cascades to members and invitations via FK)
        let result = sqlx::query("DELETE FROM teams WHERE id = ?")
            .bind(team_id.to_string())
            .execute(&self.pool)
            .await?;

        if result.rows_affected() == 0 {
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
        self.get_user_role(team_id, user_id)
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

        let offset = (page - 1) * size;

        let count_row: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM team_members WHERE team_id = ?")
                .bind(team_id.to_string())
                .fetch_one(&self.pool)
                .await?;

        let total = count_row.0 as u64;

        let rows: Vec<MemberRow> = sqlx::query_as(
            r#"
            SELECT 
                tm.id, tm.user_id, u.email, u.username,
                tm.role, tm.joined_at
            FROM team_members tm
            JOIN users u ON tm.user_id = u.id
            WHERE tm.team_id = ?
            ORDER BY tm.joined_at ASC
            LIMIT ? OFFSET ?
            "#,
        )
        .bind(team_id.to_string())
        .bind(size as i64)
        .bind(offset as i64)
        .fetch_all(&self.pool)
        .await?;

        let items: Vec<MemberResponse> = rows
            .into_iter()
            .map(|row| MemberResponse {
                id: Uuid::parse_str(&row.id).unwrap_or_default(),
                user_id: Uuid::parse_str(&row.user_id).unwrap_or_default(),
                email: row.email,
                username: row.username,
                role: match row.role.as_str() {
                    "Owner" => TeamRole::Owner,
                    "Admin" => TeamRole::Admin,
                    _ => TeamRole::Member,
                },
                joined_at: DateTime::parse_from_rfc3339(&row.joined_at)
                    .map(|dt| dt.with_timezone(&Utc))
                    .unwrap_or_else(|_| Utc::now()),
            })
            .collect();

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
            .get_user_role(team_id, actor_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        // Get target's role
        let target_role = self
            .get_user_role(team_id, target_user_id)
            .await?
            .ok_or(TeamServiceError::NotFound)?;

        // Authorization matrix
        let can_remove = match (actor_role, target_role) {
            (TeamRole::Owner, _) => true,                 // Owner can remove anyone
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

        let result = sqlx::query(
            "DELETE FROM team_members WHERE team_id = ? AND user_id = ?",
        )
        .bind(team_id.to_string())
        .bind(target_user_id.to_string())
        .execute(&self.pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(TeamServiceError::NotFound);
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
            .get_user_role(team_id, actor_id)
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

        sqlx::query(
            r#"
            INSERT INTO team_invitations (id, team_id, email, code, role, expires_at, used_at, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(invitation.id.to_string())
        .bind(invitation.team_id.to_string())
        .bind(&invitation.email)
        .bind(&invitation.code)
        .bind(invitation.role.to_string())
        .bind(invitation.expires_at.to_rfc3339())
        .bind(invitation.used_at.map(|dt| dt.to_rfc3339()))
        .bind(invitation.created_at.to_rfc3339())
        .execute(&self.pool)
        .await?;

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
        let row: Option<InvitationRow> = sqlx::query_as(
            "SELECT * FROM team_invitations WHERE code = ?",
        )
        .bind(&code)
        .fetch_optional(&self.pool)
        .await?;

        let invitation = match row {
            Some(r) => r,
            None => return Err(TeamServiceError::NotFound),
        };

        // Check if already used
        if invitation.used_at.is_some() {
            return Err(TeamServiceError::InvitationUsed);
        }

        // Check expiration
        let expires_at = DateTime::parse_from_rfc3339(&invitation.expires_at)
            .map(|dt| dt.with_timezone(&Utc))
            .unwrap_or_else(|_| Utc::now());
        if Utc::now() > expires_at {
            return Err(TeamServiceError::InvitationExpired);
        }

        let team_id = Uuid::parse_str(&invitation.team_id).unwrap_or_default();
        let role = match invitation.role.as_str() {
            "Owner" => TeamRole::Owner,
            "Admin" => TeamRole::Admin,
            _ => TeamRole::Member,
        };

        // Check if user is already a member
        let existing = self.get_user_role(team_id, user_id).await?;
        if existing.is_some() {
            return Err(TeamServiceError::AlreadyMember);
        }

        // Add member
        let member = TeamMember::new(team_id, user_id, role);
        sqlx::query(
            r#"
            INSERT INTO team_members (id, team_id, user_id, role, joined_at)
            VALUES (?, ?, ?, ?, ?)
            "#,
        )
        .bind(member.id.to_string())
        .bind(member.team_id.to_string())
        .bind(member.user_id.to_string())
        .bind(member.role.to_string())
        .bind(member.joined_at.to_rfc3339())
        .execute(&self.pool)
        .await?;

        // Mark invitation as used
        sqlx::query("UPDATE team_invitations SET used_at = ? WHERE id = ?")
            .bind(Utc::now().to_rfc3339())
            .bind(invitation.id)
            .execute(&self.pool)
            .await?;

        // Get team name
        let team_row: Option<(String,)> =
            sqlx::query_as("SELECT name FROM teams WHERE id = ?")
                .bind(team_id.to_string())
                .fetch_optional(&self.pool)
                .await?;

        let team_name = team_row.map(|r| r.0).unwrap_or_default();

        Ok(AcceptInvitationResponse {
            team_id,
            team_name,
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
            .get_user_role(team_id, user_id)
            .await?
            .ok_or(TeamServiceError::NotMember)?;

        // Owner cannot leave
        if role == TeamRole::Owner {
            return Err(TeamServiceError::OwnerCannotLeave);
        }

        let result = sqlx::query(
            "DELETE FROM team_members WHERE team_id = ? AND user_id = ?",
        )
        .bind(team_id.to_string())
        .bind(user_id.to_string())
        .execute(&self.pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(TeamServiceError::NotFound);
        }

        Ok(())
    }
}
