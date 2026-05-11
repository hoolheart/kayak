/// Team list page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/team_models.dart';
import '../providers/team_providers.dart';
import '../widgets/create_team_dialog.dart';
import '../widgets/empty_team_list_state.dart';
import '../widgets/team_card.dart';
import '../widgets/team_error_state.dart';
import 'team_routes.dart';

/// Team list page
class TeamListPage extends ConsumerStatefulWidget {
  const TeamListPage({super.key});

  @override
  ConsumerState<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends ConsumerState<TeamListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(teamsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('团队管理'),
        actions: [
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('创建团队'),
              ),
            ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return EmptyTeamListState(onCreateTeam: _showCreateDialog);
          }
          return _buildTeamGrid(teams);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => TeamErrorState(
          error: error,
          onRetry: () => ref.invalidate(teamsProvider),
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTeamGrid(List<Team> teams) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 1280) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 768) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(teamsProvider),
          child: GridView.builder(
            padding: EdgeInsets.all(
              constraints.maxWidth >= 1280 ? 24 : constraints.maxWidth >= 768 ? 16 : 12,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 160,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return TeamCard(
                team: team,
                onTap: () => _onTeamTap(team.id),
              );
            },
          ),
        );
      },
    );
  }

  void _onTeamTap(String teamId) {
    context.go(TeamRoutes.detailPath(teamId));
  }

  Future<void> _showCreateDialog() async {
    final result = await showCreateTeamDialog(context);
    if (result == true && mounted) {
      ref.invalidate(teamsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('团队创建成功')),
      );
    }
  }
}
