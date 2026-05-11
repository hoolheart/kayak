/// Team-specific color tokens - adapts to current theme
library;

import 'package:flutter/material.dart';

/// Team color values
class TeamColors {
  const TeamColors({
    required this.ownerBadgeBg,
    required this.ownerBadgeText,
    required this.adminBadgeBg,
    required this.adminBadgeText,
    required this.memberBadgeBg,
    required this.memberBadgeText,
    required this.dangerZoneBg,
    required this.dangerZoneBorder,
    required this.dangerZoneTitle,
    required this.permissionHintBg,
    required this.permissionHintBorder,
    required this.permissionHintIcon,
    required this.selectorHoverBg,
    required this.optionSelectedBg,
    required this.optionSelectedText,
  });

  // Light theme colors
  static const light = TeamColors(
    ownerBadgeBg: Color(0xFFBBDEFB),
    ownerBadgeText: Color(0xFF1565C0),
    adminBadgeBg: Color(0xFFE0F7FA),
    adminBadgeText: Color(0xFF006064),
    memberBadgeBg: Color(0xFFEEEEEE),
    memberBadgeText: Color(0xFF757575),
    dangerZoneBg: Color(0xFFFFEBEE),
    dangerZoneBorder: Color(0xFFC62828),
    dangerZoneTitle: Color(0xFFC62828),
    permissionHintBg: Color(0xFFE3F2FD),
    permissionHintBorder: Color(0xFF1976D2),
    permissionHintIcon: Color(0xFF1976D2),
    selectorHoverBg: Color(0x1AFFFFFF),
    optionSelectedBg: Color(0xFFBBDEFB),
    optionSelectedText: Color(0xFF1565C0),
  );

  // Dark theme colors
  static const dark = TeamColors(
    ownerBadgeBg: Color(0xFF1565C0),
    ownerBadgeText: Color(0xFFE3F2FD),
    adminBadgeBg: Color(0xFF006064),
    adminBadgeText: Color(0xFFE0F7FA),
    memberBadgeBg: Color(0xFF2D2D2D),
    memberBadgeText: Color(0xFF9E9E9E),
    dangerZoneBg: Color(0xFFB71C1C),
    dangerZoneBorder: Color(0xFFEF5350),
    dangerZoneTitle: Color(0xFFEF5350),
    permissionHintBg: Color(0xFF0D47A1),
    permissionHintBorder: Color(0xFF90CAF9),
    permissionHintIcon: Color(0xFF90CAF9),
    selectorHoverBg: Color(0x14F5F5F5),
    optionSelectedBg: Color(0xFF1565C0),
    optionSelectedText: Color(0xFFE3F2FD),
  );

  final Color ownerBadgeBg;
  final Color ownerBadgeText;
  final Color adminBadgeBg;
  final Color adminBadgeText;
  final Color memberBadgeBg;
  final Color memberBadgeText;
  final Color dangerZoneBg;
  final Color dangerZoneBorder;
  final Color dangerZoneTitle;
  final Color permissionHintBg;
  final Color permissionHintBorder;
  final Color permissionHintIcon;
  final Color selectorHoverBg;
  final Color optionSelectedBg;
  final Color optionSelectedText;
}

/// Get team colors based on current theme brightness
class TeamColorTokens {
  const TeamColorTokens._();

  /// Get tokens based on current brightness
  static TeamColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? TeamColors.dark : TeamColors.light;
  }
}
