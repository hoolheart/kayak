/// Team detail page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/team_models.dart';
import '../models/team_role.dart';
import '../providers/team_providers.dart';
import '../widgets/confirmation_dialogs.dart';
import '../widgets/danger_zone_card.dart';
import '../widgets/edit_team_dialog.dart';
import '../widgets/invite_member_dialog.dart';
import '../widgets/member_list_item.dart';
import '../widgets/team_error_state.dart';

/// Team detail page
class TeamDetailPage extends ConsumerWidget {
  const TeamDetailPage({
    super.key,
    required this.teamId,
  });
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(teamDetailProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.when(
          data: (detail) => Text(detail.name),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        actions: [
          if (ref.watch(currentUserRoleProvider(teamId))?.canEditTeam ??
              false)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _handleEdit(context, ref, detailAsync),
            ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => _TeamDetailContent(
          teamId: teamId,
          detail: detail,
          onEdit: () => _handleEdit(context, ref, detailAsync),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          if (error is TeamApiException && error.isForbidden) {
            return TeamAccessDenied(
              onBack: () => context.go('/teams'),
            );
          }
          if (error is TeamApiException && error.isNotFound) {
            return TeamNotFound(
              onBack: () => context.go('/teams'),
            );
          }
          return TeamErrorState(
            error: error,
            onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
          );
        },
      ),
    );
  }

  Future<void> _handleEdit(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<TeamDetail> detailAsync,
  ) async {
    final detail = detailAsync.valueOrNull;
    if (detail == null) return;

    final result = await showEditTeamDialog(context, detail);
    if (result == true && context.mounted) {
      ref.invalidate(teamDetailProvider(teamId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('团队信息更新成功')),
      );
    }
  }
}

class _TeamDetailContent extends ConsumerWidget {
  const _TeamDetailContent({
    required this.teamId,
    required this.detail,
    required this.onEdit,
  });
  final String teamId;
  final TeamDetail detail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider(teamId));
    final membersAsync = ref.watch(membersProvider(teamId));

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width >= 1280 ? 24 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team header card
          _buildHeaderCard(context, ref, role),
          const SizedBox(height: 24),
          // Members section
          _buildMembersSection(context, ref, role, membersAsync),
          const SizedBox(height: 24),
          // Danger zone
          if (role != null)
            DangerZoneCard(
              showDeleteTeam: role.canDeleteTeam,
              showLeaveTeam: role.canLeaveTeam,
              onDeleteTeam: () => _showDeleteDialog(context, ref),
              onLeaveTeam: () => _showLeaveDialog(context, ref),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, WidgetRef ref, TeamRole? role) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.groups,
                    size: 32,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                // Team info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (detail.description != null &&
                          detail.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            detail.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Edit button
                if (role?.canEditTeam ?? false)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            // Stats row
            Builder(
              builder: (context) => Wrap(
                spacing: 24,
                children: [
                  _buildStatItem(context, '成员', '${detail.memberCount}'),
                  _buildStatItem(
                    context,
                    '创建于',
                    '${detail.createdAt.year}-${detail.createdAt.month.toString().padLeft(2, '0')}-${detail.createdAt.day.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    WidgetRef ref,
    TeamRole? role,
    AsyncValue<List<TeamMember>> membersAsync,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '团队成员',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            membersAsync.when(
              data: (members) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${members.length} 人',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Spacer(),
            if (role?.canInviteMembers ?? false)
              FilledButton.icon(
                onPressed: () => _showInviteDialog(context, ref),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('邀请成员'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: membersAsync.when(
            data: (members) => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colorScheme.outlineVariant),
              itemBuilder: (context, index) {
                final member = members[index];
                return MemberListItem(
                  member: member,
                  showActions: role?.canManageMembers ?? false,
                  onRemove: () => _showRemoveDialog(context, ref, member),
                );
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('加载成员失败: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final result = await showInviteMemberDialog(context, teamId);
    if (result == true && context.mounted) {
      ref.invalidate(membersProvider(teamId));
      ref.invalidate(invitationsProvider(teamId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邀请发送成功')),
      );
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDeleteTeamDialog(context, detail.name);
    if (confirmed == true) {
      final success =
          await ref.read(teamActionsProvider.notifier).deleteTeam(teamId);
      if (success && context.mounted) {
        context.go('/teams');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('团队已删除')),
        );
      } else if (context.mounted) {
        final error = ref.read(teamActionsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $error')),
        );
      }
    }
  }

  Future<void> _showLeaveDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showLeaveTeamDialog(context, detail.name);
    if (confirmed == true) {
      final success =
          await ref.read(teamActionsProvider.notifier).leaveTeam(teamId);
      if (success && context.mounted) {
        context.go('/teams');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已离开团队')),
        );
      } else if (context.mounted) {
        final error = ref.read(teamActionsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('离开失败: $error')),
        );
      }
    }
  }

  Future<void> _showRemoveDialog(
    BuildContext context,
    WidgetRef ref,
    TeamMember member,
  ) async {
    final confirmed = await showRemoveMemberDialog(context, member.name);
    if (confirmed == true) {
      final success = await ref
          .read(teamActionsProvider.notifier)
          .removeMember(teamId, member.userId);
      if (success) {
        ref.invalidate(membersProvider(teamId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('成员已移除')),
          );
        }
      } else if (context.mounted) {
        final error = ref.read(teamActionsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $error')),
        );
      }
    }
  }
}
