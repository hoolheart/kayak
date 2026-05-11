/// Team selector widget for AppBar
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../experiments/providers/experiment_list_provider.dart';
import '../../methods/providers/method_list_provider.dart';
import '../../workbench/providers/workbench_list_provider.dart';
import '../models/team_context.dart';
import '../models/team_models.dart';
import '../providers/team_providers.dart';

/// Team selector button for AppBar
class TeamSelector extends ConsumerWidget {
  const TeamSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextState = ref.watch(currentTeamContextProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final isPersonal = contextState.isPersonal;

    return teamsAsync.when(
      data: (teams) {
        if (teams.isEmpty && isPersonal) {
          return const SizedBox.shrink();
        }

        return _TeamSelectorButton(
          label: contextState.displayName,
          isPersonal: isPersonal,
          teams: teams,
          selectedContext: contextState,
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TeamSelectorButton extends ConsumerStatefulWidget {
  const _TeamSelectorButton({
    required this.label,
    required this.isPersonal,
    required this.teams,
    required this.selectedContext,
  });
  final String label;
  final bool isPersonal;
  final List<Team> teams;
  final TeamContext selectedContext;

  @override
  ConsumerState<_TeamSelectorButton> createState() =>
      _TeamSelectorButtonState();
}

class _TeamSelectorButtonState extends ConsumerState<_TeamSelectorButton> {
  final _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  '当前工作空间',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              // Personal option
              _buildMenuItem(
                icon: Icons.account_circle,
                title: '个人空间',
                subtitle: '仅自己可见',
                isSelected: widget.isPersonal,
                onTap: () => _switchContext(const TeamContext.personal()),
              ),
              const Divider(height: 1),
              // Teams header
              if (widget.teams.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '我的团队',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              // Team options
              ...widget.teams.take(5).map(
                    (team) => _buildMenuItem(
                      icon: Icons.groups,
                      title: team.name,
                      subtitle: team.role.displayName,
                      isSelected: !widget.isPersonal &&
                          widget.selectedContext.teamId == team.id,
                      onTap: () => _switchContext(
                        TeamContext.team(id: team.id, name: team.name),
                      ),
                    ),
                  ),
              // View all teams link
              if (widget.teams.length > 5)
                InkWell(
                  onTap: () {
                    _menuController.close();
                    context.go('/teams');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '查看全部团队',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 1),
              // Create new team link
              InkWell(
                onTap: () {
                  _menuController.close();
                  context.go('/teams');
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '创建新团队',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark
                  ? colorScheme.onSurface.withValues(alpha: 0.08)
                  : colorScheme.onPrimary.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isPersonal ? Icons.account_circle : Icons.groups,
                  size: 20,
                  color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? colorScheme.onSurface
                            : colorScheme.onPrimary,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        onTap();
        _menuController.close();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchContext(TeamContext newContext) async {
    final notifier = ref.read(currentTeamContextProvider.notifier);

    if (newContext.isPersonal) {
      await notifier.switchToPersonal();
    } else {
      await notifier.switchToTeam(
        id: newContext.teamId!,
        name: newContext.displayName,
      );
    }

    // Invalidate resource providers to reload with new context
    ref.invalidate(teamsProvider);
    ref.invalidate(workbenchListProvider);
    ref.invalidate(methodListProvider);
    ref.invalidate(experimentListProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到 ${newContext.displayName}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
