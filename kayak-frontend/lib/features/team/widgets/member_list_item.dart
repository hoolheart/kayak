/// Member list item widget
library;

import 'package:flutter/material.dart';

import '../models/team_models.dart';
import '../models/team_role.dart';
import 'role_badge.dart';

/// Member list item component
class MemberListItem extends StatelessWidget {
  const MemberListItem({
    super.key,
    required this.member,
    this.showActions = false,
    this.onRemove,
  });
  final TeamMember member;
  final bool showActions;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.primaryContainer,
        child: member.avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  member.avatarUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildInitials(theme, colorScheme),
                ),
              )
            : _buildInitials(theme, colorScheme),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(width: 8),
          RoleBadge(role: member.role, size: BadgeSize.small),
        ],
      ),
      subtitle: Text(
        member.email,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: showActions && member.role != TeamRole.owner
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_remove,
                        size: 20,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '移除成员',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove?.call();
                }
              },
            )
          : null,
    );
  }

  Widget _buildInitials(ThemeData theme, ColorScheme colorScheme) {
    final initials = member.name.isNotEmpty
        ? member.name.substring(0, 1).toUpperCase()
        : '?';
    return Text(
      initials,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
