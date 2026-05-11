/// Team context model for current workspace selection
library;

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_context.freezed.dart';
part 'team_context.g.dart';

/// Represents the current workspace context: personal or a specific team
@freezed
class TeamContext with _$TeamContext {
  const factory TeamContext.personal() = _Personal;
  const factory TeamContext.team({
    required String id,
    required String name,
  }) = _Team;

  const TeamContext._();

  factory TeamContext.fromJson(Map<String, dynamic> json) =>
      _$TeamContextFromJson(json);

  /// Whether the context is personal workspace
  bool get isPersonal => this is _Personal;

  /// Get the team ID if in team context, null otherwise
  String? get teamId => map(
        personal: (_) => null,
        team: (t) => t.id,
      );

  /// Get the display name for the current context
  String get displayName => map(
        personal: (_) => '个人空间',
        team: (t) => t.name,
      );

  /// Serialize to JSON string for storage
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string
  static TeamContext fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TeamContext.fromJson(json);
    } catch (_) {
      return const TeamContext.personal();
    }
  }
}
