import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/app_localizations.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/dashboard_service.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/skeleton.dart' show ShimmerBlock;
import 'recent_workbench_card.dart';

/// 最近工作台区域组件。
///
/// 包含区域标题 + "查看全部"链接 + 水平滚动卡片列表。
/// 数据来自 [dashboardRecentProvider]，独立容错。
/// 空状态时显示 EmptyView + 创建引导按钮。
class RecentWorkbenchesSection extends ConsumerWidget {
  const RecentWorkbenchesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(dashboardRecentProvider);
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final cardWidth = isCompact ? 180.0 : (screenWidth < 1200 ? 200.0 : 240.0);
    final gap = isCompact ? 8.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域标题
        _buildHeader(context, loc),
        const SizedBox(height: 16),
        // 内容区域
        recentAsync.when(
          loading: () => _buildSkeleton(cardWidth, gap),
          error: (error, stack) => ErrorView(
            title: loc.dashboardRecentError,
            description: loc.dashboardRecentErrorHint,
            onRetry: () => ref.invalidate(dashboardRecentProvider),
            compact: true,
          ),
          data: (workbenches) {
            if (workbenches.isEmpty) {
              return _buildEmptyState(context, loc);
            }
            return _buildCardList(
              context,
              workbenches,
              cardWidth,
              gap,
              isCompact,
            );
          },
        ),
      ],
    );
  }

  /// 区域标题 + "查看全部"链接
  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loc.recentWorkbenches,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: () => context.go('/workbenches'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.viewAll,
                style: theme.textTheme.bodyMedium?.copyWith(
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
      ],
    );
  }

  /// 水平滚动卡片列表
  Widget _buildCardList(
    BuildContext context,
    List<WorkbenchSummary> workbenches,
    double cardWidth,
    double gap,
    bool isCompact,
  ) {
    return SizedBox(
      height: isCompact ? 140 : 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: workbenches.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final wb = workbenches[index];
          return RecentWorkbenchCard(
            workbench: wb,
            width: cardWidth,
            compact: isCompact,
            onTap: () => context.go('/workbenches/${wb.id}'),
          );
        },
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return EmptyView(
      icon: Icons.build_outlined,
      title: loc.dashboardRecentEmpty,
      description: loc.dashboardRecentEmptyHint,
      compact: true,
      actionButton: FilledButton(
        onPressed: () => context.go('/workbenches'),
        child: Text(loc.dashboardRecentEmptyAction),
      ),
    );
  }

  /// 加载骨架屏
  Widget _buildSkeleton(double cardWidth, double gap) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return Container(
            width: cardWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: 24, height: 24, borderRadius: 12),
                SizedBox(height: 8),
                ShimmerBlock(width: 120, height: 16),
                SizedBox(height: 8),
                ShimmerBlock(width: 80, height: 14),
                SizedBox(height: 4),
                ShimmerBlock(width: 60, height: 14),
              ],
            ),
          );
        },
      ),
    );
  }
}
