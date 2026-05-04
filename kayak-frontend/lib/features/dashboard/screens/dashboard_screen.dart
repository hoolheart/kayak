/// Dashboard screen - main entry point after login
///
/// Figma设计：欢迎区域 → 快捷操作 → 最近工作台 → 统计概览
/// 四层信息结构，从上到下按重要程度递减

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../workbench/models/workbench.dart';
import '../../workbench/providers/workbench_list_provider.dart';
import '../widgets/empty_workbenches.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_workbench_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/welcome_section.dart';

/// Dashboard screen
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workbenchListProvider.notifier).loadWorkbenches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final workbenchState = ref.watch(workbenchListProvider);

    final workbenches = workbenchState.workbenches;
    final isLoading = workbenchState.isLoading;
    final error = workbenchState.error;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(workbenchListProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 1. 欢迎区域 =====
              const WelcomeSection(),
              const SizedBox(height: 24),

              // ===== 2. 快捷操作 =====
              Text(
                '快捷操作',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  QuickActionCard(
                    icon: Icons.workspace_premium,
                    title: '工作台',
                    description: '管理工作台和设备',
                    onTap: () => context.go('/workbenches'),
                  ),
                  QuickActionCard(
                    icon: Icons.science,
                    title: '试验',
                    description: '查看和管理试验',
                    onTap: () => context.go('/experiments'),
                  ),
                  QuickActionCard(
                    icon: Icons.description,
                    title: '方法',
                    description: '编辑试验方法',
                    onTap: () => context.go('/methods'),
                  ),
                  QuickActionCard(
                    icon: Icons.folder,
                    title: '数据文件',
                    description: '管理数据文件',
                    onTap: () => context.go('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ===== 3. 最近工作台 =====
              _SectionHeader(
                title: '最近工作台',
                actionLabel: '查看全部',
                onAction: () => context.go('/workbenches'),
              ),
              const SizedBox(height: 16),
              _buildRecentWorkbenches(workbenches, isLoading, error),
              const SizedBox(height: 32),

              // ===== 4. 统计概览 =====
              Text(
                '概览',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 800
                      ? 4
                      : constraints.maxWidth >= 600
                          ? 2
                          : 1;
                  return _buildStatsGrid(
                    crossAxisCount,
                    workbenches.length,
                    isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build recent workbenches section with loading/error/empty states
  Widget _buildRecentWorkbenches(
    List<Workbench> workbenches,
    bool isLoading,
    String? error,
  ) {
    // Loading state
    if (isLoading && workbenches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error state
    if (error != null && workbenches.isEmpty) {
      return _buildErrorState(error);
    }

    // Empty state
    if (workbenches.isEmpty) {
      return EmptyWorkbenchesState(
        onCreateWorkbench: () => context.go('/workbenches'),
      );
    }

    // Has data - take up to 4
    final recentWorkbenches = workbenches.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 600
                    ? 2
                    : 1;

        final count = crossAxisCount.clamp(1, recentWorkbenches.length);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisExtent: 140,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: recentWorkbenches.length,
          itemBuilder: (context, index) {
            final wb = recentWorkbenches[index];
            return RecentWorkbenchCard(
              workbench: wb,
              onTap: () => context.go('/workbenches/${wb.id}'),
            );
          },
        );
      },
    );
  }

  /// Error state widget
  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () {
              ref.read(workbenchListProvider.notifier).loadWorkbenches();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// Stats grid
  Widget _buildStatsGrid(
    int crossAxisCount,
    int workbenchCount,
    bool isLoading,
  ) {
    final stats = [
      StatCard(
        label: '工作台总数',
        value: isLoading ? '...' : '$workbenchCount',
        icon: Icons.workspace_premium,
      ),
      const StatCard(
        label: '设备总数',
        value: '-',
        icon: Icons.memory,
      ),
      const StatCard(
        label: '试验总数',
        value: '-',
        icon: Icons.science,
      ),
      const StatCard(
        label: '数据文件',
        value: '-',
        icon: Icons.folder,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: 88,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => stats[index],
    );
  }
}

/// Section header with title and action
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text('$actionLabel →'),
        ),
      ],
    );
  }
}
