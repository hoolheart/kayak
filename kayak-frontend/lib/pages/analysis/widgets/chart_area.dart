import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/analysis_provider.dart';
import '../../../widgets/async_value_widget.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/time_series_chart.dart';

/// ChartArea — 图表区域容器
///
/// 管理图表的三态切换：空/加载/数据/错误。
class ChartArea extends ConsumerWidget {
  const ChartArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final notifier = ref.read(analysisProvider.notifier);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final isEmpty =
        state.chartData.hasValue &&
        (state.chartData.value == null || state.chartData.value!.isEmpty);

    return Expanded(
      child: ColoredBox(
        color: colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图表区域
            Expanded(
              child: _buildChartContent(
                context,
                state.chartData,
                state.hiddenPointIds,
                notifier,
                textTheme,
                colorScheme,
                isEmpty,
              ),
            ),

            // 加载状态指示
            if (state.isLoadingData)
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent(
    BuildContext context,
    AsyncValue<ChartData?> chartData,
    Set<String> hiddenPointIds,
    AnalysisNotifier notifier,
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool isEmpty,
  ) {
    return AsyncValueWidget<ChartData?>(
      value: chartData,
      skipLoadingOnRefresh: false,
      loadingBuilder: const _ChartLoadingSkeleton(),
      emptyBuilder: const EmptyView(
        icon: Icons.show_chart,
        title: '请选择试验、设备和测点后加载数据',
        description: '从左侧面板选择试验、设备和测点，然后点击"加载数据"',
      ),
      emptyCondition: (data) => data == null || data.isEmpty,
      onRetry: () => notifier.loadChartData(),
      errorBuilder: (error, stack) => ErrorView(
        title: '加载数据失败',
        description: '$error',
        onRetry: () => notifier.loadChartData(),
      ),
      dataBuilder: (data) {
        if (data == null || data.isEmpty) {
          return const EmptyView(
            icon: Icons.inbox,
            title: '所选范围内无数据',
            description: '请尝试调整时间范围或选择其他测点',
          );
        }

        return TimeSeriesChart(
          data: data,
          hiddenPointIds: hiddenPointIds,
          onTogglePoint: (pointId) => notifier.togglePointVisibility(pointId),
        );
      },
    );
  }
}

/// 图表加载骨架屏
class _ChartLoadingSkeleton extends StatelessWidget {
  const _ChartLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skeletonColor = colorScheme.surfaceContainerHighest.withAlpha(128);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 图例占位
          Row(
            children: [
              _buildSkeletonBox(skeletonColor, 12, 12),
              const SizedBox(width: 4),
              _buildSkeletonBox(skeletonColor, 80, 12),
              const SizedBox(width: 16),
              _buildSkeletonBox(skeletonColor, 12, 12),
              const SizedBox(width: 4),
              _buildSkeletonBox(skeletonColor, 80, 12),
            ],
          ),
          const SizedBox(height: 24),
          // 图表占位
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox(Color color, double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
