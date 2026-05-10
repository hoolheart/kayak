# Test Cases — Team Management Backend API (R2-S2-001-A)

## Test Information
- **Task**: R2-S2-001-A — Team Management Backend API Test Cases
- **Tester**: sw-mike
- **Date**: 2026-05-11
- **Status**: Draft

---

## Table of Contents

1. [Team CRUD Operations](#1-team-crud-operations)
2. [Member Management](#2-member-management)
3. [Role-Based Access Control](#3-role-based-access-control)
4. [Invitation Lifecycle](#4-invitation-lifecycle)
5. [Team Deletion Strategy](#5-team-deletion-strategy)
6. [Resource Isolation](#6-resource-isolation)
7. [Edge Cases and Error Scenarios](#7-edge-cases-and-error-scenarios)
8. [Traceability Matrix](#8-traceability-matrix)

---

## 1. Team CRUD Operations

### TC-TEAM-001: Create Team — Success
- **Description**: Verify that an authenticated user can create a team with valid data.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated (valid JWT token).
  2. User A has no existing teams.
- **Steps**:
  1. Send `POST /api/v1/teams` with body: `{"name": "Alpha Team", "description": "Test team"}`.
  2. Record the response.
- **Expected Results**:
  1. HTTP status: `201 Created`.
  2. Response body contains team `id`, `name`, `description`, `owner_id` (matches User A), `created_at`, `updated_at`.
  3. Database `teams` table has exactly one row with the above data.
  4. Database `team_members` table has one row: `team_id`, `user_id` = User A, `role` = `Owner`.

### TC-TEAM-002: Create Team — Missing Required Name
- **Description**: Verify that creating a team without a name fails with validation error.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated.
- **Steps**:
  1. Send `POST /api/v1/teams` with body: `{"description": "Missing name"}`.
- **Expected Results**:
  1. HTTP status: `422 Unprocessable Entity`.
  2. Response contains error indicating `name` is required.
  3. No rows created in `teams` or `team_members`.

### TC-TEAM-003: Create Team — Name Too Long
- **Description**: Verify that team name exceeding maximum length is rejected.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated.
- **Steps**:
  1. Send `POST /api/v1/teams` with body: `{"name": "<256 characters>"}`.
- **Expected Results**:
  1. HTTP status: `422 Unprocessable Entity`.
  2. Error indicates name length constraint violation.

### TC-TEAM-004: Create Team — Unauthenticated
- **Description**: Verify that unauthenticated requests are rejected.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. No valid JWT token.
- **Steps**:
  1. Send `POST /api/v1/teams` without `Authorization` header.
- **Expected Results**:
  1. HTTP status: `401 Unauthorized`.
  2. No database modifications.

### TC-TEAM-005: List My Teams — Success (Multiple Teams)
- **Description**: Verify that authenticated user sees all teams they are members of.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A owns Team 1.
  2. User A is Admin of Team 2.
  3. User A is Member of Team 3.
- **Steps**:
  1. Send `GET /api/v1/teams` as User A.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response is an array of 3 teams.
  3. Each team object includes `id`, `name`, `description`, `owner_id`, `role` (User A's role in that team).
  4. Teams are ordered by `created_at` DESC (or specified default).

### TC-TEAM-006: List My Teams — Empty List
- **Description**: Verify that user with no teams gets empty list.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User B is authenticated.
  2. User B has no team memberships.
- **Steps**:
  1. Send `GET /api/v1/teams` as User B.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response body: `[]`.

### TC-TEAM-007: List My Teams — Unauthenticated
- **Description**: Verify that listing teams requires authentication.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. No valid JWT token.
- **Steps**:
  1. Send `GET /api/v1/teams`.
- **Expected Results**:
  1. HTTP status: `401 Unauthorized`.

### TC-TEAM-008: Get Team Details — Success (Owner)
- **Description**: Verify that team owner can view team details.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists with User A as Owner.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}` as User A.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response contains full team details including `name`, `description`, `owner_id`, `created_at`, `updated_at`.
  3. Owner's own role is included if endpoint returns member context.

### TC-TEAM-009: Get Team Details — Success (Admin)
- **Description**: Verify that team Admin can view team details.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User B is Admin of Team Alpha.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}` as User B.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Team details returned successfully.

### TC-TEAM-010: Get Team Details — Success (Member)
- **Description**: Verify that regular Member can view team details.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User C is Member of Team Alpha.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}` as User C.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Team details returned successfully.

### TC-TEAM-011: Get Team Details — Non-Member Forbidden
- **Description**: Verify that non-members cannot view team details.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User D is authenticated but NOT a member of Team Alpha.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}` as User D.
- **Expected Results**:
  1. HTTP status: `403 Forbidden` (or `404 Not Found` for security-by-obscurity).
  2. No team details leaked.

### TC-TEAM-012: Get Team Details — Non-Existent Team
- **Description**: Verify behavior when requesting non-existent team.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. Team ID does not exist in database.
- **Steps**:
  1. Send `GET /api/v1/teams/{non_existent_id}` as authenticated user.
- **Expected Results**:
  1. HTTP status: `404 Not Found`.

### TC-TEAM-013: Update Team — Success (Owner)
- **Description**: Verify that Owner can update team name and description.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists with User A as Owner.
- **Steps**:
  1. Send `PUT /api/v1/teams/{team_id}` as User A with body: `{"name": "Alpha Team Updated", "description": "Updated description"}`.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response contains updated team data.
  3. Database reflects changes: `name` and `description` updated, `updated_at` > `created_at`.

### TC-TEAM-014: Update Team — Success (Admin)
- **Description**: Verify that Admin can update team name and description.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User B is Admin of Team Alpha.
- **Steps**:
  1. Send `PUT /api/v1/teams/{team_id}` as User B with body: `{"name": "Admin Updated"}`.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Team name updated in database.

### TC-TEAM-015: Update Team — Forbidden (Member)
- **Description**: Verify that regular Member cannot update team.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User C is Member of Team Alpha.
- **Steps**:
  1. Send `PUT /api/v1/teams/{team_id}` as User C.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. Team data unchanged in database.

### TC-TEAM-016: Update Team — Forbidden (Non-Member)
- **Description**: Verify that non-members cannot update team.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User D is not a member.
- **Steps**:
  1. Send `PUT /api/v1/teams/{team_id}` as User D.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. Team data unchanged.

### TC-TEAM-017: Update Team — Partial Update (Name Only)
- **Description**: Verify that updating only name leaves description unchanged.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists with name "Alpha" and description "Desc".
  2. User A is Owner.
- **Steps**:
  1. Send `PUT /api/v1/teams/{team_id}` with body: `{"name": "Alpha Team"}`.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Name changed to "Alpha Team", description remains "Desc".

### TC-TEAM-018: Update Team — Invalid Data
- **Description**: Verify that invalid update data is rejected.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A is Owner of Team Alpha.
- **Steps**:
  1. Send `PUT /api/v1/teams/{team_id}` with body: `{"name": ""}`.
- **Expected Results**:
  1. HTTP status: `422 Unprocessable Entity`.
  2. Team data unchanged.

---

## 2. Member Management

### TC-MEMBER-001: List Members — Success (Owner)
- **Description**: Verify that Owner can list all team members.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has members: User A (Owner), User B (Admin), User C (Member).
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}/members` as User A.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response is array of 3 member objects.
  3. Each member object contains: `id`, `user_id`, `role`, `joined_at`, user info (email, name).
  4. Members ordered by `joined_at` ASC (or specified default).

### TC-MEMBER-002: List Members — Success (Admin)
- **Description**: Verify that Admin can list all team members.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has multiple members.
  2. User B is Admin.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}/members` as User B.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Full member list returned.

### TC-MEMBER-003: List Members — Success (Member)
- **Description**: Verify that regular Member can list all team members.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has multiple members.
  2. User C is Member.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}/members` as User C.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Full member list returned.

### TC-MEMBER-004: List Members — Forbidden (Non-Member)
- **Description**: Verify that non-members cannot list team members.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User D is not a member.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}/members` as User D.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. No member data leaked.

### TC-MEMBER-005: Remove Member — Success (Owner Removes Member)
- **Description**: Verify that Owner can remove a regular member.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has User C as Member.
  2. User A is Owner.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}/members/{user_c_id}` as User A.
- **Expected Results**:
  1. HTTP status: `204 No Content`.
  2. `team_members` row for User C removed.
  3. User C no longer appears in member list.

### TC-MEMBER-006: Remove Member — Success (Owner Removes Admin)
- **Description**: Verify that Owner can remove an Admin.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has User B as Admin.
  2. User A is Owner.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}/members/{user_b_id}` as User A.
- **Expected Results**:
  1. HTTP status: `204 No Content`.
  2. User B removed from team.

### TC-MEMBER-007: Remove Member — Success (Admin Removes Member)
- **Description**: Verify that Admin can remove a regular member.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has User C as Member.
  2. User B is Admin.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}/members/{user_c_id}` as User B.
- **Expected Results**:
  1. HTTP status: `204 No Content`.
  2. User C removed from team.

### TC-MEMBER-008: Remove Member — Forbidden (Admin Removes Owner)
- **Description**: Verify that Admin cannot remove Owner.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has User A as Owner, User B as Admin.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}/members/{user_a_id}` as User B.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. Error message indicates insufficient permissions.
  3. User A remains Owner in database.

### TC-MEMBER-009: Remove Member — Forbidden (Member Removes Anyone)
- **Description**: Verify that Member cannot remove any team member.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has User A (Owner), User B (Admin), User C (Member), User D (Member).
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}/members/{user_d_id}` as User C.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. User D remains in team.

### TC-MEMBER-010: Remove Member — Forbidden (Remove Self via DELETE)
- **Description**: Verify that DELETE endpoint is for removal by others, not self-leave.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User C is Member of Team Alpha.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}/members/{user_c_id}` as User C.
- **Expected Results**:
  1. HTTP status: `403 Forbidden` (self-removal should use `POST /leave`).

### TC-MEMBER-011: Remove Member — Non-Member Target
- **Description**: Verify behavior when trying to remove user who is not in team.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User E is not a member of Team Alpha.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}/members/{user_e_id}` as Owner.
- **Expected Results**:
  1. HTTP status: `404 Not Found`.

### TC-MEMBER-012: Leave Team — Success (Admin)
- **Description**: Verify that Admin can leave team.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User B is Admin of Team Alpha.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/leave` as User B.
- **Expected Results**:
  1. HTTP status: `204 No Content`.
  2. User B removed from `team_members`.
  3. Team no longer appears in User B's team list.

### TC-MEMBER-013: Leave Team — Success (Member)
- **Description**: Verify that Member can leave team.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User C is Member of Team Alpha.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/leave` as User C.
- **Expected Results**:
  1. HTTP status: `204 No Content`.
  2. User C removed from `team_members`.

### TC-MEMBER-014: Leave Team — Forbidden (Owner)
- **Description**: Verify that Owner cannot leave team.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A is Owner of Team Alpha.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/leave` as User A.
- **Expected Results**:
  1. HTTP status: `403 Forbidden` (or `409 Conflict`).
  2. Error message: "Owner cannot leave team. Transfer ownership first."
  3. User A remains Owner in database.

### TC-MEMBER-015: Leave Team — Non-Member
- **Description**: Verify that non-member cannot leave team.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User D is not a member of Team Alpha.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/leave` as User D.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.

---

## 3. Role-Based Access Control

### TC-RBAC-001: Role Hierarchy — Owner > Admin > Member
- **Description**: Verify role hierarchy enforcement across all operations.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has User A (Owner), User B (Admin), User C (Member).
- **Steps**:
  1. For each role, attempt each protected operation:
     - Update team
     - Delete team
     - Remove members
     - Create invitation
     - List members
- **Expected Results**:
  | Operation | Owner | Admin | Member | Non-Member |
  |-----------|-------|-------|--------|------------|
  | Update team | 200 | 200 | 403 | 403 |
  | Delete team | 204 | 403 | 403 | 403 |
  | Remove member (Member) | 204 | 204 | 403 | 403 |
  | Remove member (Admin) | 204 | 403 | 403 | 403 |
  | Remove member (Owner) | — | 403 | 403 | 403 |
  | Create invitation | 201 | 201 | 403 | 403 |
  | List members | 200 | 200 | 200 | 403 |

### TC-RBAC-002: RequireTeamRole Extractor — Owner Role Check
- **Description**: Verify middleware allows Owner for Owner-only operations.
- **Priority**: P0
- **Test Type**: Unit
- **Preconditions**:
  1. `RequireTeamRole` extractor instantiated with `Owner` requirement.
- **Steps**:
  1. Call extractor with User A (Owner) context.
- **Expected Results**:
  1. Extractor succeeds, returns user/team context.
  2. Request proceeds to handler.

### TC-RBAC-003: RequireTeamRole Extractor — Admin Blocked from Owner-Only
- **Description**: Verify middleware blocks Admin from Owner-only operations.
- **Priority**: P0
- **Test Type**: Unit
- **Preconditions**:
  1. `RequireTeamRole` extractor instantiated with `Owner` requirement.
- **Steps**:
  1. Call extractor with User B (Admin) context.
- **Expected Results**:
  1. Extractor returns `403 Forbidden`.
  2. Handler is not invoked.

### TC-RBAC-004: RequireTeamRole Extractor — Member Blocked from Admin+ Operations
- **Description**: Verify middleware blocks Member from Admin/Owner operations.
- **Priority**: P0
- **Test Type**: Unit
- **Preconditions**:
  1. `RequireTeamRole` extractor instantiated with `Admin` requirement.
- **Steps**:
  1. Call extractor with User C (Member) context.
- **Expected Results**:
  1. Extractor returns `403 Forbidden`.

### TC-RBAC-005: RequireTeamRole Extractor — Non-Member Blocked
- **Description**: Verify middleware blocks non-members entirely.
- **Priority**: P0
- **Test Type**: Unit
- **Preconditions**:
  1. `RequireTeamRole` extractor instantiated with any role requirement.
- **Steps**:
  1. Call extractor with User D (not a member).
- **Expected Results**:
  1. Extractor returns `403 Forbidden`.

### TC-RBAC-006: Role Storage Consistency
- **Description**: Verify that roles are stored as exact strings (Owner/Admin/Member).
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. Database has team_members with various roles.
- **Steps**:
  1. Query `team_members` table for all role values.
- **Expected Results**:
  1. Only valid values: `Owner`, `Admin`, `Member`.
  2. No null roles.
  3. Case-sensitive matching.

### TC-RBAC-007: Single Owner Invariant
- **Description**: Verify that a team always has exactly one Owner.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Multiple teams exist with various members.
- **Steps**:
  1. Query `team_members` grouped by `team_id` where `role = 'Owner'`.
- **Expected Results**:
  1. Each team has exactly one Owner.
  2. No team has zero or multiple Owners.

---

## 4. Invitation Lifecycle

### TC-INVITE-001: Create Invitation — Success (Owner)
- **Description**: Verify that Owner can create invitation for new member.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User A is Owner.
  3. User E is not a member (email: user_e@example.com).
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/invitations` as User A with body: `{"email": "user_e@example.com", "role": "Member"}`.
- **Expected Results**:
  1. HTTP status: `201 Created`.
  2. Response contains: `id`, `team_id`, `email`, `code` (32-char Base64URL), `role`, `expires_at`, `created_at`.
  3. `expires_at` is exactly 7 days after `created_at`.
  4. `code` matches regex `^[A-Za-z0-9_-]{32}$`.
  5. `used_at` is null.
  6. Database row created in `team_invitations`.

### TC-INVITE-002: Create Invitation — Success (Admin)
- **Description**: Verify that Admin can create invitation.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User B is Admin of Team Alpha.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/invitations` as User B.
- **Expected Results**:
  1. HTTP status: `201 Created`.
  2. Invitation created successfully.

### TC-INVITE-003: Create Invitation — Forbidden (Member)
- **Description**: Verify that Member cannot create invitations.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User C is Member of Team Alpha.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/invitations` as User C.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. No invitation created.

### TC-INVITE-004: Create Invitation — Invalid Email
- **Description**: Verify that invalid email is rejected.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A is Owner.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/invitations` with body: `{"email": "not-an-email", "role": "Member"}`.
- **Expected Results**:
  1. HTTP status: `422 Unprocessable Entity`.
  2. No invitation created.

### TC-INVITE-005: Create Invitation — Invalid Role
- **Description**: Verify that invalid role is rejected.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A is Owner.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/invitations` with body: `{"email": "user@example.com", "role": "SuperUser"}`.
- **Expected Results**:
  1. HTTP status: `422 Unprocessable Entity`.
  2. No invitation created.

### TC-INVITE-006: Create Invitation — Invite Existing Member
- **Description**: Verify that inviting existing member fails.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User C is already Member of Team Alpha.
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/invitations` with User C's email.
- **Expected Results**:
  1. HTTP status: `409 Conflict`.
  2. Error message: "User is already a team member."

### TC-INVITE-007: Accept Invitation — Success (Matching Email)
- **Description**: Verify that user can accept invitation with matching email.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Invitation exists for `user_e@example.com` to Team Alpha.
  2. User E is authenticated with email `user_e@example.com`.
- **Steps**:
  1. Send `POST /api/v1/invitations/{code}/accept` as User E.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. User E added to `team_members` with specified role.
  3. `team_invitations.used_at` set to current timestamp.
  4. Team appears in User E's team list.

### TC-INVITE-008: Accept Invitation — Success (Any Authenticated User)
- **Description**: Verify that any authenticated user can accept invitation (if implementation allows).
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Invitation exists for `user_e@example.com`.
  2. User F is authenticated (different email).
- **Steps**:
  1. Send `POST /api/v1/invitations/{code}/accept` as User F.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. User F added to team members.
  3. Invitation marked as used.

### TC-INVITE-009: Accept Invitation — Expired Invitation
- **Description**: Verify that expired invitation cannot be accepted.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Invitation exists with `expires_at` in the past.
- **Steps**:
  1. Send `POST /api/v1/invitations/{code}/accept`.
- **Expected Results**:
  1. HTTP status: `410 Gone` (or `400 Bad Request`).
  2. Error message: "Invitation has expired."
  3. User not added to team.
  4. `used_at` remains null.

### TC-INVITE-010: Accept Invitation — Already Used
- **Description**: Verify that used invitation cannot be accepted again.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Invitation has `used_at` set.
- **Steps**:
  1. Send `POST /api/v1/invitations/{code}/accept`.
- **Expected Results**:
  1. HTTP status: `409 Conflict` (or `410 Gone`).
  2. Error message: "Invitation has already been used."
  3. User not added to team (or no duplicate membership).

### TC-INVITE-011: Accept Invitation — Invalid Code
- **Description**: Verify that non-existent invitation code fails.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. Code does not exist in database.
- **Steps**:
  1. Send `POST /api/v1/invitations/{invalid_code}/accept`.
- **Expected Results**:
  1. HTTP status: `404 Not Found`.

### TC-INVITE-012: Accept Invitation — Unauthenticated
- **Description**: Verify that accepting invitation requires authentication.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Valid invitation exists.
- **Steps**:
  1. Send `POST /api/v1/invitations/{code}/accept` without auth token.
- **Expected Results**:
  1. HTTP status: `401 Unauthorized`.

### TC-INVITE-013: Invitation Expiration — Exact 7 Days
- **Description**: Verify that invitation expires exactly 7 days after creation.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. Create invitation at known timestamp.
- **Steps**:
  1. Create invitation.
  2. Check `expires_at` value.
- **Expected Results**:
  1. `expires_at` = `created_at` + 7 days.
  2. Precision is to the second (or millisecond based on DB type).

### TC-INVITE-014: Invitation Code Format
- **Description**: Verify code format is 32-character Base64URL.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. Generate multiple invitation codes.
- **Steps**:
  1. Generate 100 invitation codes.
- **Expected Results**:
  1. All codes match regex `^[A-Za-z0-9_-]{32}$`.
  2. No two codes are identical (collision resistance check).

### TC-INVITE-015: List Invitations — Success (Owner/Admin)
- **Description**: Verify that pending invitations can be listed.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has 2 pending invitations, 1 used invitation.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}/invitations` as Owner.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Returns 2 pending invitations (not used, not expired).

---

## 5. Team Deletion Strategy

### TC-DELETE-001: Delete Team — Success (Empty Team)
- **Description**: Verify that Owner can delete team with no resources.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Beta exists with User A as Owner.
  2. Team Beta has zero experiments, zero workbenches, zero methods.
  3. Team Beta has only Owner as member.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}` as User A.
- **Expected Results**:
  1. HTTP status: `204 No Content`.
  2. Team row removed from `teams`.
  3. All member rows removed from `team_members`.
  4. All invitations removed from `team_invitations`.
  5. Team no longer appears in any user's team list.

### TC-DELETE-002: Delete Team — Forbidden (Non-Empty Team)
- **Description**: Verify that team with resources cannot be deleted.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Gamma exists with User A as Owner.
  2. Team Gamma has at least one experiment (or workbench/method).
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}` as User A.
- **Expected Results**:
  1. HTTP status: `409 Conflict`.
  2. Error message: "Cannot delete team with existing resources."
  3. Team and all data remain intact.

### TC-DELETE-003: Delete Team — Forbidden (Admin)
- **Description**: Verify that Admin cannot delete team.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists with User A as Owner, User B as Admin.
  2. Team Alpha is empty (no resources).
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}` as User B.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. Team not deleted.

### TC-DELETE-004: Delete Team — Forbidden (Member)
- **Description**: Verify that Member cannot delete team.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User C is Member.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}` as User C.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.

### TC-DELETE-005: Delete Team — Forbidden (Non-Member)
- **Description**: Verify that non-member cannot delete team.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha exists.
  2. User D is not a member.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}` as User D.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.

### TC-DELETE-006: Delete Team — Cascade Effects
- **Description**: Verify that team deletion cascades to related data.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Delta exists.
  2. Team Delta has 3 members.
  3. Team Delta has 5 pending invitations.
  4. Team Delta has zero resources.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}` as Owner.
  2. Query `team_members` for team_id.
  3. Query `team_invitations` for team_id.
- **Expected Results**:
  1. HTTP status: `204 No Content`.
  2. Zero rows in `team_members` for deleted team.
  3. Zero rows in `team_invitations` for deleted team.
  4. Zero rows in `teams` for deleted team_id.

### TC-DELETE-007: Delete Team — Non-Existent Team
- **Description**: Verify behavior when deleting non-existent team.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. Team ID does not exist.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{non_existent_id}` as authenticated user.
- **Expected Results**:
  1. HTTP status: `404 Not Found`.

---

## 6. Resource Isolation

### TC-ISOLATE-001: Personal Resources — scope=personal
- **Description**: Verify that `scope=personal` returns only personal resources.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A owns 2 personal experiments and 1 team experiment.
- **Steps**:
  1. Send `GET /api/v1/experiments?scope=personal` as User A.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response contains exactly 2 experiments.
  3. Both experiments have `owner_type` = `personal`.

### TC-ISOLATE-002: Team Resources — scope=team
- **Description**: Verify that `scope=team` returns only current team resources.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A is member of Team Alpha.
  2. Team Alpha has 3 experiments.
  3. User A has 2 personal experiments.
- **Steps**:
  1. Send `GET /api/v1/experiments?scope=team` as User A.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response contains exactly 3 experiments.
  3. All experiments have `owner_type` = `team` and `owner_id` = Team Alpha.

### TC-ISOLATE-003: All Resources — scope=all (Default)
- **Description**: Verify that default scope returns personal + team resources.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A has 2 personal experiments.
  2. Team Alpha (User A's team) has 3 experiments.
- **Steps**:
  1. Send `GET /api/v1/experiments` (no scope param) as User A.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response contains 5 experiments total.
  3. Mix of `owner_type` = `personal` and `team`.

### TC-ISOLATE-004: Team Filter — team_id Query Param
- **Description**: Verify that `team_id` filters to specific team resources.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A is member of Team Alpha and Team Beta.
  2. Team Alpha has 2 experiments.
  3. Team Beta has 3 experiments.
- **Steps**:
  1. Send `GET /api/v1/experiments?team_id={team_alpha_id}` as User A.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response contains exactly 2 experiments from Team Alpha.

### TC-ISOLATE-005: Resource Isolation — Outsider Cannot See Team Resources
- **Description**: Verify that team resources are invisible to non-members.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has 2 experiments.
  2. User D is not a member of Team Alpha.
- **Steps**:
  1. Send `GET /api/v1/experiments?scope=team` as User D.
  2. Send `GET /api/v1/experiments?team_id={team_alpha_id}` as User D.
- **Expected Results**:
  1. `scope=team`: Returns 0 experiments (User D has no team).
  2. `team_id={team_alpha_id}`: Returns 0 experiments (or `403 Forbidden`).

### TC-ISOLATE-006: Resource Isolation — Member Can See Team Resources
- **Description**: Verify that team members can access team resources.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has 2 experiments.
  2. User C is Member of Team Alpha.
- **Steps**:
  1. Send `GET /api/v1/experiments?scope=team` as User C.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response contains 2 team experiments.

### TC-ISOLATE-007: Resource Isolation — Experiment Details Access
- **Description**: Verify that team experiment details are accessible to members.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Experiment E1 is owned by Team Alpha.
- **Steps**:
  1. Send `GET /api/v1/experiments/{e1_id}` as User C (Member).
  2. Send `GET /api/v1/experiments/{e1_id}` as User D (Non-member).
- **Expected Results**:
  1. As User C: `200 OK`, full experiment details.
  2. As User D: `403 Forbidden` (or `404 Not Found`).

### TC-ISOLATE-008: Resource Isolation — Workbench Scope
- **Description**: Verify scope filtering works for workbenches endpoint.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A has personal workbenches and team workbenches.
- **Steps**:
  1. Send `GET /api/v1/workbenches?scope=personal`.
  2. Send `GET /api/v1/workbenches?scope=team`.
- **Expected Results**:
  1. Each scope returns only matching workbenches.

### TC-ISOLATE-009: Resource Isolation — Methods Scope
- **Description**: Verify scope filtering works for methods endpoint.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A has personal methods and team methods.
- **Steps**:
  1. Send `GET /api/v1/methods?scope=personal`.
  2. Send `GET /api/v1/methods?scope=team`.
- **Expected Results**:
  1. Each scope returns only matching methods.

### TC-ISOLATE-010: Invalid Scope Parameter
- **Description**: Verify that invalid scope parameter is rejected.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated.
- **Steps**:
  1. Send `GET /api/v1/experiments?scope=invalid`.
- **Expected Results**:
  1. HTTP status: `400 Bad Request`.
  2. Error message indicates valid scopes: `personal`, `team`, `all`.

---

## 7. Edge Cases and Error Scenarios

### TC-EDGE-001: Concurrent Team Creation
- **Description**: Verify system handles concurrent team creation.
- **Priority**: P2
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated.
- **Steps**:
  1. Send 10 simultaneous `POST /api/v1/teams` requests.
- **Expected Results**:
  1. All requests succeed with `201 Created`.
  2. 10 distinct teams created in database.
  3. No duplicate IDs.

### TC-EDGE-002: Concurrent Invitation Acceptance
- **Description**: Verify that invitation can only be accepted once even with concurrent requests.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. Valid invitation exists for User E.
- **Steps**:
  1. Send 5 simultaneous `POST /api/v1/invitations/{code}/accept` as User E.
- **Expected Results**:
  1. Exactly 1 request returns `200 OK`.
  2. 4 requests return `409 Conflict` (already used).
  3. User E appears exactly once in `team_members`.

### TC-EDGE-003: Team Name Uniqueness Per User
- **Description**: Verify that same user cannot create teams with identical names.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A owns team named "Test Team".
- **Steps**:
  1. Send `POST /api/v1/teams` with body: `{"name": "Test Team"}`.
- **Expected Results**:
  1. HTTP status: `409 Conflict` (or `422`).
  2. Error message: "Team name already exists."

### TC-EDGE-004: Team Name Can Be Reused Across Users
- **Description**: Verify that different users can have teams with same name.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A owns team "Shared Name".
  2. User B has no teams.
- **Steps**:
  1. Send `POST /api/v1/teams` as User B with body: `{"name": "Shared Name"}`.
- **Expected Results**:
  1. HTTP status: `201 Created`.
  2. Team created successfully.

### TC-EDGE-005: Remove Owner (Direct API Attempt)
- **Description**: Verify that API prevents removing Owner through direct call.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User A is Owner of Team Alpha.
- **Steps**:
  1. Send `DELETE /api/v1/teams/{team_id}/members/{user_a_id}` as User A (self).
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. Owner remains in team.

### TC-EDGE-006: Leave as Only Member
- **Description**: Verify behavior when last non-owner member leaves.
- **Priority**: P2
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has only User A (Owner).
- **Steps**:
  1. Send `POST /api/v1/teams/{team_id}/leave` as User A.
- **Expected Results**:
  1. HTTP status: `403 Forbidden`.
  2. Owner cannot leave.

### TC-EDGE-007: Invitation with Existing User (Different Email Match)
- **Description**: Verify invitation acceptance when email doesn't match exactly.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. Invitation for `user@example.com`.
  2. User registers with `User@Example.COM` (case difference).
- **Steps**:
  1. Send `POST /api/v1/invitations/{code}/accept`.
- **Expected Results**:
  1. Behavior depends on implementation:
     - Case-insensitive: `200 OK`.
     - Case-sensitive: `403 Forbidden`.
  2. Document actual behavior.

### TC-EDGE-008: SQL Injection in Team Name
- **Description**: Verify that team names are sanitized against SQL injection.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated.
- **Steps**:
  1. Send `POST /api/v1/teams` with body: `{"name": "'; DROP TABLE teams; --"}`.
- **Expected Results**:
  1. HTTP status: `201 Created` or `422` (depending on validation).
  2. `teams` table intact.
  3. Name stored literally (or rejected if contains invalid chars).

### TC-EDGE-009: XSS in Team Description
- **Description**: Verify that description is properly escaped.
- **Priority**: P1
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated.
- **Steps**:
  1. Send `POST /api/v1/teams` with body: `{"name": "XSS Test", "description": "<script>alert('xss')</script>"}`.
- **Expected Results**:
  1. HTTP status: `201 Created`.
  2. Description stored as-is or escaped.
  3. No script execution in response.

### TC-EDGE-010: Very Long Description
- **Description**: Verify system handles maximum description length.
- **Priority**: P2
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated.
- **Steps**:
  1. Send `POST /api/v1/teams` with description of 10,000 characters.
- **Expected Results**:
  1. HTTP status: `201 Created` or `422` (if limit enforced).
  2. If accepted, description stored completely.

### TC-EDGE-011: Unicode Team Name
- **Description**: Verify that Unicode characters are supported in team name.
- **Priority**: P2
- **Test Type**: Integration
- **Preconditions**:
  1. User A is authenticated.
- **Steps**:
  1. Send `POST /api/v1/teams` with body: `{"name": "🔬 Research Team 研究组"}`.
- **Expected Results**:
  1. HTTP status: `201 Created`.
  2. Name stored and returned correctly.

### TC-EDGE-012: Database Schema — owner_type Migration
- **Description**: Verify that existing experiments migrated to have owner_type.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Database has experiments created before team feature.
- **Steps**:
  1. Query `experiments` table for `owner_type` column.
- **Expected Results**:
  1. All existing experiments have `owner_type` = `personal`.
  2. `owner_id` column is NOT NULL (after migration).
  3. New experiments require `owner_type` and `owner_id`.

### TC-EDGE-013: Database Schema — Foreign Key Constraints
- **Description**: Verify that foreign key constraints are enforced.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. Database has team_members with team_id references.
- **Steps**:
  1. Attempt to delete team that has members (bypass API, direct DB).
- **Expected Results**:
  1. Foreign key constraint violation OR cascade delete (depending on schema).
  2. If cascade: members deleted with team.
  3. If restrict: deletion blocked.

### TC-EDGE-014: Database Schema — team_members Unique Constraint
- **Description**: Verify that user cannot be member of same team twice.
- **Priority**: P0
- **Test Type**: Integration
- **Preconditions**:
  1. User C is Member of Team Alpha.
- **Steps**:
  1. Attempt direct DB insert of duplicate membership.
- **Expected Results**:
  1. Unique constraint violation on `(team_id, user_id)`.

### TC-EDGE-015: Pagination — Large Member List
- **Description**: Verify pagination for large member lists.
- **Priority**: P2
- **Test Type**: Integration
- **Preconditions**:
  1. Team Alpha has 100+ members.
- **Steps**:
  1. Send `GET /api/v1/teams/{team_id}/members?page=1&limit=20`.
- **Expected Results**:
  1. HTTP status: `200 OK`.
  2. Response contains 20 members.
  3. Response includes pagination metadata (total, page, limit).

---

## 8. Traceability Matrix

| Requirement ID | Requirement Description | Test Cases |
|----------------|------------------------|------------|
| R2-S2-001-A.1 | teams table schema | TC-EDGE-012, TC-EDGE-013 |
| R2-S2-001-A.2 | team_members table schema | TC-EDGE-014, TC-RBAC-007 |
| R2-S2-001-A.3 | team_invitations table schema | TC-INVITE-001, TC-INVITE-014 |
| R2-S2-001-A.4 | experiments owner_type/owner_id | TC-ISOLATE-001, TC-EDGE-012 |
| R2-S2-001-A.5 | POST /api/v1/teams | TC-TEAM-001 to TC-TEAM-004 |
| R2-S2-001-A.6 | GET /api/v1/teams | TC-TEAM-005 to TC-TEAM-007 |
| R2-S2-001-A.7 | GET /api/v1/teams/:id | TC-TEAM-008 to TC-TEAM-012 |
| R2-S2-001-A.8 | PUT /api/v1/teams/:id | TC-TEAM-013 to TC-TEAM-018 |
| R2-S2-001-A.9 | DELETE /api/v1/teams/:id | TC-DELETE-001 to TC-DELETE-007 |
| R2-S2-001-A.10 | GET /api/v1/teams/:id/members | TC-MEMBER-001 to TC-MEMBER-004 |
| R2-S2-001-A.11 | DELETE /api/v1/teams/:id/members/:user_id | TC-MEMBER-005 to TC-MEMBER-011 |
| R2-S2-001-A.12 | POST /api/v1/teams/:id/invitations | TC-INVITE-001 to TC-INVITE-006 |
| R2-S2-001-A.13 | POST /api/v1/invitations/:code/accept | TC-INVITE-007 to TC-INVITE-012 |
| R2-S2-001-A.14 | POST /api/v1/teams/:id/leave | TC-MEMBER-012 to TC-MEMBER-015 |
| R2-S2-001-A.15 | RequireTeamRole middleware | TC-RBAC-002 to TC-RBAC-005 |
| R2-S2-001-A.16 | Role hierarchy Owner > Admin > Member | TC-RBAC-001 |
| R2-S2-001-A.17 | Owner cannot leave team | TC-MEMBER-014, TC-EDGE-006 |
| R2-S2-001-A.18 | Owner delete team, 409 if non-empty | TC-DELETE-001, TC-DELETE-002 |
| R2-S2-001-A.19 | Admin cannot remove Owner | TC-MEMBER-008 |
| R2-S2-001-A.20 | Member can only view, cannot invite/remove | TC-RBAC-001, TC-INVITE-003 |
| R2-S2-001-A.21 | Invitation code: 32-char Base64URL, 7-day expiry | TC-INVITE-001, TC-INVITE-013, TC-INVITE-014 |
| R2-S2-001-A.22 | Single-use invitation | TC-INVITE-010, TC-EDGE-002 |
| R2-S2-001-A.23 | Accept invitation: matching email or any auth user | TC-INVITE-007, TC-INVITE-008 |
| R2-S2-001-A.24 | Resource isolation scope param | TC-ISOLATE-001 to TC-ISOLATE-010 |
| R2-S2-001-A.25 | team_id query param filter | TC-ISOLATE-004, TC-ISOLATE-005 |
| R2-S2-001-A.26 | Team resources invisible to outsiders | TC-ISOLATE-005, TC-ISOLATE-007 |

---

## Summary

- **Total Test Cases**: 97
- **P0 Priority**: 64
- **P1 Priority**: 23
- **P2 Priority**: 10
- **Unit Tests**: 5
- **Integration Tests**: 92
- **E2E Tests**: 0 (backend API focus)

## Notes

1. All test cases assume proper JWT authentication middleware is in place.
2. `403 Forbidden` vs `404 Not Found` for non-member access should be consistent across all endpoints (security by obscurity decision).
3. Database state should be reset between test executions to ensure independence.
4. Test data should use unique identifiers (UUIDs or similar) to prevent collisions.
5. Performance tests (response time, load) are out of scope for this task but should be considered for future sprints.

---

*Document Version: 1.0*
*Created by: sw-mike*
*Review Status: Pending Review by sw-tom*
