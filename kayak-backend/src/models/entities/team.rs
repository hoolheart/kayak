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

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Duration;

    #[test]
    fn test_team_role_satisfies() {
        // Owner satisfies everything
        assert!(TeamRole::Owner.satisfies(TeamRole::Owner));
        assert!(TeamRole::Owner.satisfies(TeamRole::Admin));
        assert!(TeamRole::Owner.satisfies(TeamRole::Member));

        // Admin satisfies Admin and Member
        assert!(TeamRole::Admin.satisfies(TeamRole::Admin));
        assert!(TeamRole::Admin.satisfies(TeamRole::Member));
        assert!(!TeamRole::Admin.satisfies(TeamRole::Owner));

        // Member satisfies only Member
        assert!(TeamRole::Member.satisfies(TeamRole::Member));
        assert!(!TeamRole::Member.satisfies(TeamRole::Admin));
        assert!(!TeamRole::Member.satisfies(TeamRole::Owner));
    }

    #[test]
    fn test_team_role_display() {
        assert_eq!(format!("{}", TeamRole::Owner), "Owner");
        assert_eq!(format!("{}", TeamRole::Admin), "Admin");
        assert_eq!(format!("{}", TeamRole::Member), "Member");
    }

    #[test]
    fn test_team_role_from_str() {
        assert_eq!("Owner".parse::<TeamRole>().unwrap(), TeamRole::Owner);
        assert_eq!("Admin".parse::<TeamRole>().unwrap(), TeamRole::Admin);
        assert_eq!("Member".parse::<TeamRole>().unwrap(), TeamRole::Member);
        assert!("Invalid".parse::<TeamRole>().is_err());
    }

    #[test]
    fn test_team_new() {
        let owner_id = Uuid::new_v4();
        let team = Team::new("Test Team".to_string(), Some("Description".to_string()), owner_id);

        assert_eq!(team.name, "Test Team");
        assert_eq!(team.description, Some("Description".to_string()));
        assert_eq!(team.owner_id, owner_id);
    }

    #[test]
    fn test_team_member_new() {
        let team_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();
        let member = TeamMember::new(team_id, user_id, TeamRole::Admin);

        assert_eq!(member.team_id, team_id);
        assert_eq!(member.user_id, user_id);
        assert_eq!(member.role, TeamRole::Admin);
    }

    #[test]
    fn test_team_invitation_new() {
        let team_id = Uuid::new_v4();
        let expires_at = Utc::now() + Duration::days(7);
        let invitation = TeamInvitation::new(
            team_id,
            "test@example.com".to_string(),
            "code123".to_string(),
            TeamRole::Member,
            expires_at,
        );

        assert_eq!(invitation.team_id, team_id);
        assert_eq!(invitation.email, "test@example.com");
        assert_eq!(invitation.code, "code123");
        assert_eq!(invitation.role, TeamRole::Member);
        assert_eq!(invitation.used_at, None);
    }

    #[test]
    fn test_team_invitation_is_expired() {
        let team_id = Uuid::new_v4();
        let past = Utc::now() - Duration::days(1);
        let future = Utc::now() + Duration::days(1);

        let expired = TeamInvitation::new(
            team_id, "a@b.com".to_string(), "code1".to_string(),
            TeamRole::Member, past,
        );
        assert!(expired.is_expired());

        let valid = TeamInvitation::new(
            team_id, "a@b.com".to_string(), "code2".to_string(),
            TeamRole::Member, future,
        );
        assert!(!valid.is_expired());
    }

    #[test]
    fn test_team_invitation_is_used() {
        let team_id = Uuid::new_v4();
        let invitation = TeamInvitation::new(
            team_id, "a@b.com".to_string(), "code".to_string(),
            TeamRole::Member, Utc::now() + Duration::days(7),
        );
        assert!(!invitation.is_used());

        let mut used = invitation.clone();
        used.used_at = Some(Utc::now());
        assert!(used.is_used());
    }

    #[test]
    fn test_owner_type_display() {
        assert_eq!(format!("{}", OwnerType::Personal), "personal");
        assert_eq!(format!("{}", OwnerType::Team), "team");
    }

    #[test]
    fn test_owner_type_from_str() {
        assert_eq!("personal".parse::<OwnerType>().unwrap(), OwnerType::Personal);
        assert_eq!("team".parse::<OwnerType>().unwrap(), OwnerType::Team);
        assert!("invalid".parse::<OwnerType>().is_err());
    }
}
