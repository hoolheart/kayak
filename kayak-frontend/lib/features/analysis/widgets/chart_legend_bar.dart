/// 图表图例栏组件
///
/// 显示曲线图例，支持点击隐藏/显示。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chart_models.dart';
import '../providers/chart_data_provider.dart';
import '../theme/chart_colors.dart';

/// 图表图例栏
class ChartLegendBar extends ConsumerWidget {
  const ChartLegendBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chartState = ref.watch(chartDataProvider);
    final chartNotifier = ref.read(chartDataProvider.notifier);

    if (chartState.data == null || chartState.data!.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final curveColors = ChartColors.getCurves(brightness);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.chartLegendBarBackground,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Legend items
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chartState.data!.points.asMap().entries.map((entry) {
                  final index = entry.key;
                  final series = entry.value;
                  final isVisible = chartState.isSeriesVisible(series.pointId);
                  final color = curveColors[index % curveColors.length];

                  return _LegendItem(
                    series: series,
                    color: color,
                    isVisible: isVisible,
                    onToggle: () => chartNotifier.toggleSeriesVisibility(series.pointId),
                    onSolo: () => chartNotifier.soloSeries(series.pointId),
                  );
                }).toList(),
              ),
            ),
          ),
          // Stats
          Text(
            '数据点数: ${_formatNumber(chartState.data!.returnedSamples)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(0)}k';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.series,
    required this.color,
    required this.isVisible,
    required this.onToggle,
    required this.onSolo,
  });

  final ChartPointSeries series;
  final Color color;
  final bool isVisible;
  final VoidCallback onToggle;
  final VoidCallback onSolo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: onToggle,
        onDoubleTap: onSolo,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color line
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: isVisible ? color : color.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              // Point name
              Text(
                series.pointName,
                style: textTheme.bodySmall?.copyWith(
                  color: isVisible
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                  decoration: isVisible ? null : TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 4),
              // Unit
              Text(
                series.unit,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(
                    alpha: isVisible ? 1.0 : 0.38,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Current value
              Text(
                series.values.isNotEmpty
                    ? series.values.last.toStringAsFixed(2)
                    : '--',
                style: textTheme.labelMedium?.copyWith(
                  color: isVisible ? color : color.withValues(alpha: 0.38),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
