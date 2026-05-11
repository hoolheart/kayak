/// Team service interface
library;

import '../models/team_models.dart';
import '../models/team_role.dart';

/// Team service interface - follows Interface-Driven Development
abstract class TeamServiceInterface {
  /// GET /api/v1/teams
  Future<List<Team>> getMyTeams();

  /// POST /api/v1/teams
  Future<Team> createTeam({required String name, String? description});

  /// GET /api/v1/teams/:id
  Future<TeamDetail> getTeamDetail(String teamId);

  /// PUT /api/v1/teams/:id
  Future<TeamDetail> updateTeam(
    String teamId, {
    required String name,
    String? description,
  });

  /// DELETE /api/v1/teams/:id
  Future<void> deleteTeam(String teamId);

  /// GET /api/v1/teams/:id/members
  Future<List<TeamMember>> getTeamMembers(String teamId);

  /// DELETE /api/v1/teams/:id/members/:userId
  Future<void> removeMember(String teamId, String userId);

  /// POST /api/v1/teams/:id/invitations
  Future<Invitation> inviteMember(
    String teamId, {
    required String email,
    required TeamRole role,
  });

  /// GET /api/v1/teams/:id/invitations (pending)
  Future<List<Invitation>> getPendingInvitations(String teamId);

  /// POST /api/v1/teams/:id/leave
  Future<void> leaveTeam(String teamId);
}
