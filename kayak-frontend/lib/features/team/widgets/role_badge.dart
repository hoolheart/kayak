/// Role badge widget with theme-aware colors
library;

import 'package:flutter/material.dart';

import '../models/team_role.dart';
import '../theme/team_colors.dart';

/// Badge size enum
enum BadgeSize { small, normal }

/// Role badge widget with theme-aware colors
class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.role,
    this.size = BadgeSize.normal,
  });
  final TeamRole role;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = TeamColorTokens.of(context);
    final (bg, fg) = switch (role) {
      TeamRole.owner => (colors.ownerBadgeBg, colors.ownerBadgeText),
      TeamRole.admin => (colors.adminBadgeBg, colors.adminBadgeText),
      TeamRole.member => (colors.memberBadgeBg, colors.memberBadgeText),
    };

    return Container(
      padding: size == BadgeSize.small
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size == BadgeSize.small ? 6 : 8),
      ),
      child: Text(
        role.label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
