//! Team entity models
//!
//! Defines teams, team_members, and team_invitations table structures

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Team membership role
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub enum TeamRole {
    /// Team owner - full control
    Owner,
    /// Team admin - can manage members and settings
    Admin,
    /// Regular member - can view and use team resources
    Member,
}

impl TeamRole {
    /// Check if this role satisfies the required role
    /// Role hierarchy: Owner > Admin > Member
    pub fn satisfies(&self, required: TeamRole) -> bool {
        matches!(
            (self, required),
            (TeamRole::Owner, _)
                | (TeamRole::Admin, TeamRole::Admin)
                | (TeamRole::Admin, TeamRole::Member)
                | (TeamRole::Member, TeamRole::Member)
        )
    }
}

impl std::fmt::Display for TeamRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TeamRole::Owner => write!(f, "Owner"),
            TeamRole::Admin => write!(f, "Admin"),
            TeamRole::Member => write!(f, "Member"),
        }
    }
}

impl std::str::FromStr for TeamRole {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "Owner" => Ok(TeamRole::Owner),
            "Admin" => Ok(TeamRole::Admin),
            "Member" => Ok(TeamRole::Member),
            _ => Err(format!("Invalid team role: {}", s)),
        }
    }
}

/// Team entity
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Team {
    /// Team ID (UUID)
    pub id: Uuid,
    /// Team name
    pub name: String,
    /// Team description
    pub description: Option<String>,
    /// Owner user ID
    pub owner_id: Uuid,
    /// Creation time
    pub created_at: DateTime<Utc>,
    /// Update time
    pub updated_at: DateTime<Utc>,
}

impl Team {
    /// Create a new team
    pub fn new(name: String, description: Option<String>, owner_id: Uuid) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            name,
            description,
            owner_id,
            created_at: now,
            updated_at: now,
        }
    }
}

/// Team member entity
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TeamMember {
    /// Membership ID (UUID)
    pub id: Uuid,
    /// Team ID
    pub team_id: Uuid,
    /// User ID
    pub user_id: Uuid,
    /// Member role
    pub role: TeamRole,
    /// Join time
    pub joined_at: DateTime<Utc>,
}

impl TeamMember {
    /// Create a new team member
    pub fn new(team_id: Uuid, user_id: Uuid, role: TeamRole) -> Self {
        Self {
            id: Uuid::new_v4(),
            team_id,
            user_id,
            role,
            joined_at: Utc::now(),
        }
    }
}

/// Team invitation entity
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TeamInvitation {
    /// Invitation ID (UUID)
    pub id: Uuid,
    /// Team ID
    pub team_id: Uuid,
    /// Invitee email
    pub email: String,
    /// Invitation code (32-char Base64URL)
    pub code: String,
    /// Role to assign when accepted
    pub role: TeamRole,
    /// Expiration time
    pub expires_at: DateTime<Utc>,
    /// When the invitation was used (None = unused)
    pub used_at: Option<DateTime<Utc>>,
    /// Creation time
    pub created_at: DateTime<Utc>,
}

impl TeamInvitation {
    /// Create a new invitation
    pub fn new(
        team_id: Uuid,
        email: String,
        code: String,
        role: TeamRole,
        expires_at: DateTime<Utc>,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            team_id,
            email,
            code,
            role,
            expires_at,
            used_at: None,
            created_at: Utc::now(),
        }
    }

    /// Check if the invitation has expired
    pub fn is_expired(&self) -> bool {
        Utc::now() > self.expires_at
    }

    /// Check if the invitation has been used
    pub fn is_used(&self) -> bool {
        self.used_at.is_some()
    }
}

/// Owner type for resource isolation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OwnerType {
    /// Personal (user-owned)
    Personal,
    /// Team-owned
    Team,
}

impl std::fmt::Display for OwnerType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OwnerType::Personal => write!(f, "personal"),
            OwnerType::Team => write!(f, "team"),
        }
    }
}

impl std::str::FromStr for OwnerType {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "personal" => Ok(OwnerType::Personal),
            "team" => Ok(OwnerType::Team),
            _ => Err(format!("Invalid owner type: {}", s)),
        }
    }
}
