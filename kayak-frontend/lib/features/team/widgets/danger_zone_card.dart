/// Danger zone card widget
library;

import 'package:flutter/material.dart';

import '../theme/team_colors.dart';

/// Danger zone card component
class DangerZoneCard extends StatelessWidget {
  const DangerZoneCard({
    super.key,
    this.showDeleteTeam = false,
    this.showLeaveTeam = false,
    this.onDeleteTeam,
    this.onLeaveTeam,
  });
  final bool showDeleteTeam;
  final bool showLeaveTeam;
  final VoidCallback? onDeleteTeam;
  final VoidCallback? onLeaveTeam;

  @override
  Widget build(BuildContext context) {
    final colors = TeamColorTokens.of(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.dangerZoneBg,
        border: Border.all(color: colors.dangerZoneBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: colors.dangerZoneTitle, size: 20),
              const SizedBox(width: 8),
              Text(
                '危险操作',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.dangerZoneTitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Divider(color: colors.dangerZoneBorder),
          if (showDeleteTeam) _buildDangerAction(
            context,
            title: '删除团队',
            description: '删除后，团队中的所有数据和资源将被永久删除，此操作不可撤销。',
            buttonText: '删除团队',
            onPressed: onDeleteTeam,
          ),
          if (showDeleteTeam && showLeaveTeam)
            const SizedBox(height: 16),
          if (showLeaveTeam) _buildDangerAction(
            context,
            title: '离开团队',
            description: '离开团队后，您将失去对该团队资源的访问权限。',
            buttonText: '离开团队',
            onPressed: onLeaveTeam,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerAction(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback? onPressed,
  }) {
    final colors = TeamColorTokens.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.dangerZoneTitle,
            side: BorderSide(color: colors.dangerZoneBorder),
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}
