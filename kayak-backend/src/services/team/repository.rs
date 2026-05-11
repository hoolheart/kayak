//! Team repository traits and implementations
//!
//! Provides repository interfaces for team-related data access.
//! This enables dependency injection and testability.

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

use crate::db::connection::DbPool;
use crate::models::entities::team::{Team, TeamInvitation, TeamMember, TeamRole};
use crate::services::team::error::TeamServiceError;

// ==================== Repository Traits ====================

/// Team repository trait
#[async_trait]
pub trait TeamRepository: Send + Sync {
    /// Create a new team within a transaction
    async fn create(
        &self,
        team: &Team,
        tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<Team, TeamServiceError>;

    /// Find team by ID
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Team>, TeamServiceError>;

    /// Check if a team with this name exists for a user
    async fn exists_by_name_for_user(
        &self,
        name: &str,
        user_id: Uuid,
    ) -> Result<bool, TeamServiceError>;

    /// Update team
    async fn update(
        &self,
        team_id: Uuid,
        name: Option<&str>,
        description: Option<&str>,
    ) -> Result<u64, TeamServiceError>;

    /// Delete team by ID
    async fn delete(&self, id: Uuid) -> Result<u64, TeamServiceError>;
}

/// Team member repository trait
#[async_trait]
pub trait TeamMemberRepository: Send + Sync {
    /// Add a member to a team within a transaction
    async fn add_member(
        &self,
        team_id: Uuid,
        user_id: Uuid,
        role: TeamRole,
        tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<TeamMember, TeamServiceError>;

    /// Find membership by team and user
    async fn find_by_team_user(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<Option<TeamMember>, TeamServiceError>;

    /// Get user's role in a team
    async fn get_role(&self, team_id: Uuid, user_id: Uuid) -> Result<Option<TeamRole>, TeamServiceError>;

    /// Remove a member from a team
    async fn remove_member(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<u64, TeamServiceError>;

    /// Count members in a team
    async fn count_members(&self, team_id: Uuid) -> Result<u32, TeamServiceError>;

    /// Find members by team with pagination
    async fn find_by_team(
        &self,
        team_id: Uuid,
        page: u32,
        size: u32,
    ) -> Result<(Vec<MemberDetail>, u64), TeamServiceError>;

    /// Find teams with role for a user
    async fn find_teams_with_role(
        &self,
        user_id: Uuid,
        page: u32,
        size: u32,
    ) -> Result<(Vec<TeamWithRole>, u64), TeamServiceError>;

    /// Get team details with role and member count in one query
    async fn get_team_with_role(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<Option<TeamWithRole>, TeamServiceError>;
}

/// Invitation repository trait
#[async_trait]
pub trait InvitationRepository: Send + Sync {
    /// Create a new invitation
    async fn create(
        &self,
        invitation: &TeamInvitation,
    ) -> Result<TeamInvitation, TeamServiceError>;

    /// Find invitation by code
    async fn find_by_code(
        &self, code: &str) -> Result<Option<TeamInvitation>, TeamServiceError>;

    /// Mark invitation as used within a transaction
    async fn mark_used(
        &self,
        id: Uuid,
        tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<(), TeamServiceError>;
}

/// Resource repository trait
#[async_trait]
pub trait ResourceRepository: Send + Sync {
    /// Check if team has any resources
    async fn has_team_resources(&self, team_id: Uuid) -> Result<bool, TeamServiceError>;
}

// ==================== Data Transfer Structures ====================

/// Member detail with user info
#[derive(Debug, FromRow)]
pub struct MemberDetail {
    pub id: String,
    pub user_id: String,
    pub email: String,
    pub username: Option<String>,
    pub role: String,
    pub joined_at: String,
}

/// Team with user's role and member count
#[derive(Debug, FromRow)]
pub struct TeamWithRole {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub owner_id: String,
    pub created_at: String,
    pub updated_at: String,
    pub role: String,
    pub member_count: i64,
}

// ==================== Sqlx Implementations ====================

/// Sqlx-based team repository
pub struct SqlxTeamRepository {
    pool: DbPool,
}

impl SqlxTeamRepository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl TeamRepository for SqlxTeamRepository {
    async fn create(
        &self,
        team: &Team,
        tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<Team, TeamServiceError> {
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
        .execute(&mut **tx)
        .await?;

        Ok(team.clone())
    }

    async fn find_by_id(
        &self, id: Uuid) -> Result<Option<Team>, TeamServiceError> {
        let row: Option<TeamRow> = sqlx::query_as("SELECT * FROM teams WHERE id = ?")
            .bind(id.to_string())
            .fetch_optional(&self.pool)
            .await?;

        Ok(row.map(|r| r.into_team()))
    }

    async fn exists_by_name_for_user(
        &self,
        name: &str,
        user_id: Uuid,
    ) -> Result<bool, TeamServiceError> {
        let exists: Option<(String,)> = sqlx::query_as(
            r#"
            SELECT t.name FROM teams t
            JOIN team_members tm ON t.id = tm.team_id
            WHERE tm.user_id = ? AND t.name = ?
            "#,
        )
        .bind(user_id.to_string())
        .bind(name)
        .fetch_optional(&self.pool)
        .await?;

        Ok(exists.is_some())
    }

    async fn update(
        &self,
        team_id: Uuid,
        name: Option<&str>,
        description: Option<&str>,
    ) -> Result<u64, TeamServiceError> {
        let now = Utc::now().to_rfc3339();

        let rows_affected = match (name, description) {
            (Some(n), Some(d)) => {
                sqlx::query(
                    "UPDATE teams SET name = ?, description = ?, updated_at = ? WHERE id = ?",
                )
                .bind(n)
                .bind(d)
                .bind(&now)
                .bind(team_id.to_string())
                .execute(&self.pool)
                .await?
                .rows_affected()
            }
            (Some(n), None) => {
                sqlx::query("UPDATE teams SET name = ?, updated_at = ? WHERE id = ?")
                    .bind(n)
                    .bind(&now)
                    .bind(team_id.to_string())
                    .execute(&self.pool)
                    .await?
                    .rows_affected()
            }
            (None, Some(d)) => {
                sqlx::query("UPDATE teams SET description = ?, updated_at = ? WHERE id = ?")
                    .bind(d)
                    .bind(&now)
                    .bind(team_id.to_string())
                    .execute(&self.pool)
                    .await?
                    .rows_affected()
            }
            (None, None) => 0,
        };

        Ok(rows_affected)
    }

    async fn delete(&self, id: Uuid) -> Result<u64, TeamServiceError> {
        let result = sqlx::query("DELETE FROM teams WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(result.rows_affected())
    }
}

/// Sqlx-based team member repository
pub struct SqlxTeamMemberRepository {
    pool: DbPool,
}

impl SqlxTeamMemberRepository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl TeamMemberRepository for SqlxTeamMemberRepository {
    async fn add_member(
        &self,
        team_id: Uuid,
        user_id: Uuid,
        role: TeamRole,
        tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<TeamMember, TeamServiceError> {
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
        .execute(&mut **tx)
        .await?;

        Ok(member)
    }

    async fn find_by_team_user(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<Option<TeamMember>, TeamServiceError> {
        let row: Option<(String, String, String, String, String)> = sqlx::query_as(
            "SELECT id, team_id, user_id, role, joined_at FROM team_members WHERE team_id = ? AND user_id = ?",
        )
        .bind(team_id.to_string())
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        match row {
            Some((id, team_id_str, user_id_str, role, joined_at)) => Ok(Some(TeamMember {
                id: parse_uuid(&id)?,
                team_id: parse_uuid(&team_id_str)?,
                user_id: parse_uuid(&user_id_str)?,
                role: parse_role(&role),
                joined_at: parse_datetime(&joined_at),
            })),
            None => Ok(None),
        }
    }

    async fn get_role(&self, team_id: Uuid, user_id: Uuid) -> Result<Option<TeamRole>, TeamServiceError> {
        let row: Option<(String,)> = sqlx::query_as(
            "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
        )
        .bind(team_id.to_string())
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(role_str,)| parse_role(&role_str)))
    }

    async fn remove_member(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<u64, TeamServiceError> {
        let result = sqlx::query(
            "DELETE FROM team_members WHERE team_id = ? AND user_id = ?",
        )
        .bind(team_id.to_string())
        .bind(user_id.to_string())
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected())
    }

    async fn count_members(&self, team_id: Uuid) -> Result<u32, TeamServiceError> {
        let row: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM team_members WHERE team_id = ?")
            .bind(team_id.to_string())
            .fetch_one(&self.pool)
            .await?;

        Ok(row.0 as u32)
    }

    async fn find_by_team(
        &self,
        team_id: Uuid,
        page: u32,
        size: u32,
    ) -> Result<(Vec<MemberDetail>, u64), TeamServiceError> {
        let offset = (page - 1) * size;

        let count_row: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM team_members WHERE team_id = ?")
                .bind(team_id.to_string())
                .fetch_one(&self.pool)
                .await?;

        let total = count_row.0 as u64;

        let rows: Vec<MemberDetail> = sqlx::query_as(
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

        Ok((rows, total))
    }

    async fn find_teams_with_role(
        &self,
        user_id: Uuid,
        page: u32,
        size: u32,
    ) -> Result<(Vec<TeamWithRole>, u64), TeamServiceError> {
        let offset = (page - 1) * size;

        let count_row: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM team_members WHERE user_id = ?",
        )
        .bind(user_id.to_string())
        .fetch_one(&self.pool)
        .await?;

        let total = count_row.0 as u64;

        let rows: Vec<TeamWithRole> = sqlx::query_as(
            r#"
            SELECT 
                t.id, t.name, t.description, t.owner_id, 
                t.created_at, t.updated_at,
                tm.role as role,
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

        Ok((rows, total))
    }

    async fn get_team_with_role(
        &self,
        team_id: Uuid,
        user_id: Uuid,
    ) -> Result<Option<TeamWithRole>, TeamServiceError> {
        let row: Option<TeamWithRole> = sqlx::query_as(
            r#"
            SELECT 
                t.id, t.name, t.description, t.owner_id, 
                t.created_at, t.updated_at,
                tm.role as role,
                (SELECT COUNT(*) FROM team_members WHERE team_id = t.id) as member_count
            FROM teams t
            JOIN team_members tm ON t.id = tm.team_id
            WHERE t.id = ? AND tm.user_id = ?
            "#,
        )
        .bind(team_id.to_string())
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row)
    }
}

/// Sqlx-based invitation repository
pub struct SqlxInvitationRepository {
    pool: DbPool,
}

impl SqlxInvitationRepository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }
}

#[derive(Debug, FromRow)]
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
impl InvitationRepository for SqlxInvitationRepository {
    async fn create(
        &self,
        invitation: &TeamInvitation,
    ) -> Result<TeamInvitation, TeamServiceError> {
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

        Ok(invitation.clone())
    }

    async fn find_by_code(
        &self, code: &str) -> Result<Option<TeamInvitation>, TeamServiceError> {
        let row: Option<InvitationRow> = sqlx::query_as(
            "SELECT * FROM team_invitations WHERE code = ?",
        )
        .bind(code)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| TeamInvitation {
            id: parse_uuid(&r.id).unwrap_or_else(|_| Uuid::nil()),
            team_id: parse_uuid(&r.team_id).unwrap_or_else(|_| Uuid::nil()),
            email: r.email,
            code: r.code,
            role: parse_role(&r.role),
            expires_at: parse_datetime(&r.expires_at),
            used_at: r.used_at.as_ref().map(|s| parse_datetime(s)),
            created_at: parse_datetime(&r.created_at),
        }))
    }

    async fn mark_used(
        &self,
        id: Uuid,
        tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<(), TeamServiceError> {
        sqlx::query("UPDATE team_invitations SET used_at = ? WHERE id = ?")
            .bind(Utc::now().to_rfc3339())
            .bind(id.to_string())
            .execute(&mut **tx)
            .await?;

        Ok(())
    }
}

/// Sqlx-based resource repository
pub struct SqlxResourceRepository {
    pool: DbPool,
}

impl SqlxResourceRepository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ResourceRepository for SqlxResourceRepository {
    async fn has_team_resources(
        &self, team_id: Uuid) -> Result<bool, TeamServiceError> {
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

// ==================== Helper Types and Functions ====================

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
            id: parse_uuid(&self.id).unwrap_or_else(|_| Uuid::nil()),
            name: self.name,
            description: self.description,
            owner_id: parse_uuid(&self.owner_id).unwrap_or_else(|_| Uuid::nil()),
            created_at: parse_datetime(&self.created_at),
            updated_at: parse_datetime(&self.updated_at),
        }
    }
}

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
