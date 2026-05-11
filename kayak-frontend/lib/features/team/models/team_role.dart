/// Team role enum with permission levels
library;

/// Team role enumeration with hierarchy levels
enum TeamRole {
  owner(3),
  admin(2),
  member(1);

  const TeamRole(this.level);
  final int level;

  /// Check if this role satisfies the required role
  bool satisfies(TeamRole required) => level >= required.level;

  /// Display label for the role
  String get label => name[0].toUpperCase() + name.substring(1);

  /// Chinese display label
  String get displayName => switch (this) {
    TeamRole.owner => 'Owner',
    TeamRole.admin => 'Admin',
    TeamRole.member => 'Member',
  };
}

/// Extension for permission checks on TeamRole
extension TeamRolePermission on TeamRole {
  bool get canEditTeam => satisfies(TeamRole.admin);
  bool get canDeleteTeam => this == TeamRole.owner;
  bool get canInviteMembers => satisfies(TeamRole.admin);
  bool get canRemoveMembers => satisfies(TeamRole.admin);
  bool get canLeaveTeam => this != TeamRole.owner;
  bool get canManageMembers => satisfies(TeamRole.admin);
}
