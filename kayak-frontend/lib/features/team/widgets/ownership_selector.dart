/// Ownership selector widget for resource creation dialogs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/team_context.dart';
import '../providers/team_providers.dart';
import '../theme/team_colors.dart';

/// Ownership selector for resource creation dialogs
class OwnershipSelector extends ConsumerStatefulWidget {
  const OwnershipSelector({
    super.key,
    this.onChanged,
  });
  final ValueChanged<TeamContext>? onChanged;

  @override
  ConsumerState<OwnershipSelector> createState() =>
      _OwnershipSelectorState();
}

class _OwnershipSelectorState extends ConsumerState<OwnershipSelector> {
  TeamContext? _selectedContext;

  @override
  Widget build(BuildContext context) {
    final currentContext = ref.watch(currentTeamContextProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final selected = _selectedContext ?? currentContext;

    return teamsAsync.when(
      data: (teams) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '归属',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            _buildOption(
              context: context,
              icon: Icons.account_circle,
              title: '个人空间',
              subtitle: '仅自己可见',
              value: const TeamContext.personal(),
              groupValue: selected,
            ),
            if (teams.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...teams.map(
              (team) => _buildOption(
                context: context,
                icon: Icons.groups,
                title: team.name,
                subtitle: '团队成员可访问',
                value: TeamContext.team(id: team.id, name: team.name),
                groupValue: selected,
              ),
            ),
            ],
            if (!selected.isPersonal) _buildPermissionHint(context, selected),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required TeamContext value,
    required TeamContext groupValue,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () {
        setState(() => _selectedContext = value);
        widget.onChanged?.call(value);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.04)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: isSelected
                    ? Icon(
                        Icons.radio_button_checked,
                        color: colorScheme.primary,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w500 : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionHint(BuildContext context, TeamContext contextValue) {
    final colors = TeamColorTokens.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.permissionHintBg,
        border: Border.all(color: colors.permissionHintBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info,
            size: 16,
            color: colors.permissionHintIcon,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '此资源将创建在 ${contextValue.displayName} 中，团队成员将可以访问。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.permissionHintIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
