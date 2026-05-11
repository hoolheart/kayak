/// Empty team list state widget
library;

import 'package:flutter/material.dart';

/// Empty team list state component
class EmptyTeamListState extends StatelessWidget {
  const EmptyTeamListState({
    super.key,
    this.onCreateTeam,
  });
  final VoidCallback? onCreateTeam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无团队',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '您还没有加入任何团队，创建一个新团队开始协作',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTeam,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('创建团队'),
          ),
        ],
      ),
    );
  }
}
