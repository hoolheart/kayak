/// Team data models
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'team_role.dart';

part 'team_models.freezed.dart';
part 'team_models.g.dart';

/// Team list item model
@freezed
class Team with _$Team {
  const factory Team({
    required String id,
    required String name,
    String? description,
    required int memberCount,
    required TeamRole role,
    required DateTime createdAt,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
}

/// Team detail model
@freezed
class TeamDetail with _$TeamDetail {
  const factory TeamDetail({
    required String id,
    required String name,
    String? description,
    required String ownerId,
    required TeamRole currentUserRole,
    required int memberCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TeamDetail;

  factory TeamDetail.fromJson(Map<String, dynamic> json) =>
      _$TeamDetailFromJson(json);
}

/// Team member model
@freezed
class TeamMember with _$TeamMember {
  const factory TeamMember({
    required String id,
    required String userId,
    required String name,
    required String email,
    String? avatarUrl,
    required TeamRole role,
    required DateTime joinedAt,
  }) = _TeamMember;

  factory TeamMember.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberFromJson(json);
}

/// Invitation model
@freezed
class Invitation with _$Invitation {
  const factory Invitation({
    required String id,
    required String teamId,
    required String email,
    required String code,
    required TeamRole role,
    required DateTime expiresAt,
    required DateTime createdAt,
  }) = _Invitation;

  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);
}

/// Team API exception for error handling
class TeamApiException implements Exception {
  TeamApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;

  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 422;

  @override
  String toString() => 'TeamApiException: $message (status: $statusCode)';
}

/// User model for team context
@freezed
class TeamUser with _$TeamUser {
  const factory TeamUser({
    required String id,
    required String name,
    required String email,
  }) = _TeamUser;

  factory TeamUser.fromJson(Map<String, dynamic> json) =>
      _$TeamUserFromJson(json);
}
