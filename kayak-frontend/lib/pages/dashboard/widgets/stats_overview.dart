import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/dashboard_service.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/skeleton.dart' show ShimmerBlock;
import 'stat_card.dart';

/// 统计概览区域组件。
///
/// 显示工作台数/设备数/试验数三个统计卡片。
/// 数据来自 [dashboardStatsProvider]，独立容错。
class StatsOverview extends ConsumerWidget {
  const StatsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return statsAsync.when(
      loading: () => _buildSkeleton(isCompact, Theme.of(context).colorScheme),
      error: (error, stack) => ErrorView(
        title: loc.dashboardStatsError,
        description: loc.dashboardStatsErrorHint,
        onRetry: () => ref.invalidate(dashboardStatsProvider),
        compact: true,
      ),
      data: (data) => _buildContent(context, data, isCompact),
    );
  }

  Widget _buildContent(
      BuildContext context, DashboardData data, bool isCompact) {
    final gap = isCompact ? 8.0 : 16.0;

    if (isCompact) {
      return Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.build_outlined,
              value: data.workbenchCount,
              label: AppLocalizations.of(context)!.statsWorkbenchesLabel,
              compact: true,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: StatCard(
              icon: Icons.memory_outlined,
              value: data.deviceCount,
              label: AppLocalizations.of(context)!.statsDevicesLabel,
              compact: true,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: StatCard(
              icon: Icons.biotech_outlined,
              value: data.experimentCount,
              label: AppLocalizations.of(context)!.statsExperimentsLabel,
              compact: true,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.build_outlined,
            value: data.workbenchCount,
            label: AppLocalizations.of(context)!.statsWorkbenchesLabel,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: StatCard(
            icon: Icons.memory_outlined,
            value: data.deviceCount,
            label: AppLocalizations.of(context)!.statsDevicesLabel,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: StatCard(
            icon: Icons.biotech_outlined,
            value: data.experimentCount,
            label: AppLocalizations.of(context)!.statsExperimentsLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(bool isCompact, ColorScheme colorScheme) {
    final gap = isCompact ? 8.0 : 16.0;
    final containerPadding = isCompact ? 16.0 : 24.0;
    final minHeight = isCompact ? 100.0 : 120.0;

    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? gap : 0),
            child: _buildStatSkeleton(
              colorScheme,
              containerPadding,
              minHeight,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatSkeleton(
    ColorScheme colorScheme,
    double padding,
    double minHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(padding),
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBlock(width: 28, height: 28, borderRadius: 14),
          SizedBox(height: 8),
          ShimmerBlock(width: 48, height: 48),
          SizedBox(height: 4),
          ShimmerBlock(width: 60, height: 16),
        ],
      ),
    );
  }
}
