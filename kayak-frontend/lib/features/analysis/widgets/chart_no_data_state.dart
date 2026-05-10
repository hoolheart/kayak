/// 图表无数据状态组件
///
/// 选定时间范围内无数据点时显示。
library;

import 'package:flutter/material.dart';

import '../theme/chart_colors.dart';

/// 图表无数据状态（时间范围内）
class ChartNoDataState extends StatelessWidget {
  const ChartNoDataState({
    super.key,
    this.onAdjustRange,
  });

  final VoidCallback? onAdjustRange;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: colorScheme.chartCanvasBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '所选时间范围内无数据',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请调整时间范围或选择其他试验',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            if (onAdjustRange != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onAdjustRange,
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text('调整时间范围'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
