/// Team service implementation
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/authenticated_api_client.dart';
import '../../../core/auth/providers.dart';
import '../models/team_models.dart';
import '../models/team_role.dart';
import 'team_service_interface.dart';

/// Team service implementation using Dio
class TeamService implements TeamServiceInterface {
  TeamService(this._apiClient);
  final ApiClientInterface _apiClient;

  @override
  Future<List<Team>> getMyTeams() async {
    final response = await _apiClient.get('/api/v1/teams');
    final data = (response as Map)['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => Team.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Team> createTeam({
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/teams',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return Team.fromJson((response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<TeamDetail> getTeamDetail(String teamId) async {
    final response = await _apiClient.get('/api/v1/teams/$teamId');
    return TeamDetail.fromJson(
      (response as Map)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<TeamDetail> updateTeam(
    String teamId, {
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.put(
      '/api/v1/teams/$teamId',
      data: {
        'name': name,
        if (description != null) 'description': description,
      },
    );
    return TeamDetail.fromJson(
      (response as Map)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await _apiClient.delete('/api/v1/teams/$teamId');
  }

  @override
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final response = await _apiClient.get('/api/v1/teams/$teamId/members');
    final data = (response as Map)['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> removeMember(String teamId, String userId) async {
    await _apiClient.delete('/api/v1/teams/$teamId/members/$userId');
  }

  @override
  Future<Invitation> inviteMember(
    String teamId, {
    required String email,
    required TeamRole role,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/teams/$teamId/invitations',
      data: {
        'email': email,
        'role': role.name,
      },
    );
    return Invitation.fromJson(
      (response as Map)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<Invitation>> getPendingInvitations(String teamId) async {
    final response = await _apiClient.get('/api/v1/teams/$teamId/invitations');
    final data = (response as Map)['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => Invitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> leaveTeam(String teamId) async {
    await _apiClient.post('/api/v1/teams/$teamId/leave');
  }
}

/// Provider for team service
final teamServiceProvider = Provider<TeamServiceInterface>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TeamService(apiClient);
});
