/// Team management providers
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/team_context.dart';
import '../models/team_models.dart';
import '../models/team_role.dart';
import '../services/team_service.dart';
import '../services/team_service_interface.dart';

// ==================== SharedPreferences Provider ====================

/// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized at app startup');
});

// ==================== Current Team Context Provider ====================

/// StateNotifier for team context with persistence
class CurrentTeamContextNotifier extends StateNotifier<TeamContext> {
  CurrentTeamContextNotifier(this._storage)
      : super(const TeamContext.personal());
  final SharedPreferences _storage;

  static const _key = 'current_team_context';

  /// Initialize from storage
  Future<void> initialize() async {
    final saved = _storage.getString(_key);
    if (saved != null) {
      try {
        state = TeamContext.fromJsonString(saved);
      } catch (_) {
        state = const TeamContext.personal();
      }
    }
  }

  /// Switch to personal workspace
  Future<void> switchToPersonal() async {
    state = const TeamContext.personal();
    await _storage.remove(_key);
  }

  /// Switch to a team workspace
  Future<void> switchToTeam({required String id, required String name}) async {
    state = TeamContext.team(id: id, name: name);
    await _storage.setString(_key, state.toJsonString());
  }
}

/// Global provider for current team context
final currentTeamContextProvider =
    StateNotifierProvider<CurrentTeamContextNotifier, TeamContext>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrentTeamContextNotifier(prefs);
});

// ==================== Team List Provider ====================

/// Team list provider - auto-refreshes when context changes
final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final service = ref.watch(teamServiceProvider);
  return service.getMyTeams();
});

// ==================== Team Detail Provider ====================

/// Team detail provider - family keyed by team ID
final teamDetailProvider =
    FutureProvider.family<TeamDetail, String>((ref, teamId) async {
  final service = ref.watch(teamServiceProvider);
  return service.getTeamDetail(teamId);
});

// ==================== Members Provider ====================

/// Team members provider - family keyed by team ID
final membersProvider =
    FutureProvider.family<List<TeamMember>, String>((ref, teamId) async {
  final service = ref.watch(teamServiceProvider);
  return service.getTeamMembers(teamId);
});

// ==================== Invitations Provider ====================

/// Pending invitations provider - family keyed by team ID
final invitationsProvider =
    FutureProvider.family<List<Invitation>, String>((ref, teamId) async {
  final service = ref.watch(teamServiceProvider);
  return service.getPendingInvitations(teamId);
});

// ==================== Current User Role Provider ====================

/// Computed provider for current user's role in a team
final currentUserRoleProvider =
    Provider.family<TeamRole?, String>((ref, teamId) {
  final detailAsync = ref.watch(teamDetailProvider(teamId));
  return detailAsync.whenOrNull(
    data: (detail) => detail.currentUserRole,
  );
});

// ==================== Team Actions Notifier ====================

/// Notifier for team mutations (create, update, delete)
class TeamActionsNotifier extends StateNotifier<AsyncValue<void>> {
  TeamActionsNotifier(this._service) : super(const AsyncValue.data(null));
  final TeamServiceInterface _service;

  /// Create a new team
  Future<Team?> createTeam({
    required String name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final team = await _service.createTeam(
        name: name,
        description: description,
      );
      state = const AsyncValue.data(null);
      return team;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Update a team
  Future<TeamDetail?> updateTeam(
    String teamId, {
    required String name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final detail = await _service.updateTeam(
        teamId,
        name: name,
        description: description,
      );
      state = const AsyncValue.data(null);
      return detail;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Delete a team
  Future<bool> deleteTeam(String teamId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteTeam(teamId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Invite a member
  Future<Invitation?> inviteMember(
    String teamId, {
    required String email,
    required TeamRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await _service.inviteMember(
        teamId,
        email: email,
        role: role,
      );
      state = const AsyncValue.data(null);
      return invitation;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Remove a member
  Future<bool> removeMember(String teamId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _service.removeMember(teamId, userId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Leave a team
  Future<bool> leaveTeam(String teamId) async {
    state = const AsyncValue.loading();
    try {
      await _service.leaveTeam(teamId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// Provider for team actions
final teamActionsProvider =
    StateNotifierProvider<TeamActionsNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(teamServiceProvider);
  return TeamActionsNotifier(service);
});
