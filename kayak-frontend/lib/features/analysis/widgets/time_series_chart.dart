/// 时序图表组件
///
/// 使用 fl_chart 的 LineChart 实现时序数据可视化。
/// 支持单/多曲线显示、主题适配、空/加载/错误状态。
library;

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/chart_models.dart';
import '../providers/chart_data_provider.dart';
import '../theme/chart_colors.dart';
import 'chart_empty_state.dart';
import 'chart_error_state.dart';
import 'chart_legend_bar.dart';
import 'chart_loading_state.dart';
import 'chart_no_data_state.dart';
import 'chart_toolbar.dart';

/// 时序图表组件
class TimeSeriesChart extends ConsumerWidget {
  const TimeSeriesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final chartState = ref.watch(chartDataProvider);
    final chartNotifier = ref.read(chartDataProvider.notifier);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.chartCanvasBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Toolbar
          const ChartToolbar(),
          // Chart area
          Expanded(
            child: _buildChartContent(context, chartState, chartNotifier),
          ),
          // Legend bar
          const ChartLegendBar(),
        ],
      ),
    );
  }

  Widget _buildChartContent(
    BuildContext context,
    ChartViewState chartState,
    ChartDataNotifier chartNotifier,
  ) {
    switch (chartState.state) {
      case ChartState.empty:
        return const ChartEmptyState();
      case ChartState.loading:
        return const ChartLoadingState();
      case ChartState.error:
        return ChartErrorState(
          errorMessage: chartState.errorMessage,
          onRetry: () {
            // TODO(R2-S1-002): implement retry logic
          },
        );
      case ChartState.noDataInRange:
        return ChartNoDataState(
          onAdjustRange: () {
            // TODO(R2-S1-002): implement adjust range logic
          },
        );
      case ChartState.loaded:
        if (chartState.data == null || chartState.data!.points.isEmpty) {
          return const ChartEmptyState();
        }
        return _ChartContent(
          data: chartState.data!,
          visibleSeries: chartState.visibleSeries,
          hoveredSeriesIndex: chartState.hoveredSeriesIndex,
        );
    }
  }
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({
    required this.data,
    required this.visibleSeries,
    this.hoveredSeriesIndex,
  });

  final ChartDataResponse data;
  final Set<String> visibleSeries;
  final int? hoveredSeriesIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final curveColors = ChartColors.getCurves(brightness);

    // Build line bars data
    final lineBarsData = <LineChartBarData>[];
    for (int i = 0; i < data.points.length; i++) {
      final series = data.points[i];
      final isVisible = visibleSeries.contains(series.pointId);

      if (!isVisible) continue;

      final spots = _createSpots(series);
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          color: curveColors[i % curveColors.length],
          barWidth: hoveredSeriesIndex == i ? 3.0 : 2.0,
          dotData: FlDotData(
            show: spots.length < 50,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: bar.color ?? Colors.transparent,
                strokeWidth: 1,
                strokeColor: colorScheme.chartCanvasBackground,
              );
            },
          ),
          belowBarData: BarAreaData(),
        ),
      );
    }

    if (lineBarsData.isEmpty) {
      return const ChartEmptyState();
    }

    // Calculate total points for animation optimization
    final totalPoints = lineBarsData.fold<int>(
      0,
      (sum, bar) => sum + bar.spots.length,
    );

    // Calculate min/max for X and Y
    final allTimestamps = <double>[];
    final allValues = <double>[];
    for (int i = 0; i < data.points.length; i++) {
      final series = data.points[i];
      if (!visibleSeries.contains(series.pointId)) continue;
      for (final ts in series.timestamps) {
        allTimestamps.add(ts.toDouble());
      }
      for (final v in series.values) {
        allValues.add(v);
      }
    }

    final minX = allTimestamps.reduce((a, b) => a < b ? a : b);
    final maxX = allTimestamps.reduce((a, b) => a > b ? a : b);
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY) * 0.1;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            horizontalInterval: _calculateNiceInterval(minY, maxY),
            verticalInterval: _calculateNiceInterval(minX, maxX),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.chartGridLine,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: colorScheme.chartGridLine,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatYValue(value),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatXValue(value),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: colorScheme.outlineVariant),
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          minX: minX,
          maxX: maxX,
          minY: minY - yPadding,
          maxY: maxY + yPadding,
          lineBarsData: lineBarsData,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: colorScheme.chartTooltipBackground,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final seriesIndex = spot.barIndex;
                  if (seriesIndex >= data.points.length) return null;
                  final series = data.points[seriesIndex];
                  final color = curveColors[seriesIndex % curveColors.length];
                  final dt = DateTime.fromMillisecondsSinceEpoch(
                    spot.x.toInt(),
                  );
                  return LineTooltipItem(
                    '${series.pointName}\n',
                    TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: '${DateFormat('HH:mm:ss').format(dt)}\n',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: '${spot.y.toStringAsFixed(2)} ${series.unit}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: totalPoints > 500
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  List<FlSpot> _createSpots(ChartPointSeries series) {
    final spots = <FlSpot>[];
    for (int i = 0; i < series.timestamps.length; i++) {
      spots.add(
        FlSpot(
          series.timestamps[i].toDouble(),
          series.values[i],
        ),
      );
    }
    return spots;
  }

  double _calculateNiceInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1.0;

    final roughInterval = range / 5;
    final magnitude = (log(roughInterval) / log(10)).floor();
    final power = pow(10, magnitude).toDouble();
    final normalized = roughInterval / power;

    final step =
        normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10;
    return (step * power).toDouble();
  }

  String _formatYValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value.abs() >= 1) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(3);
    }
  }

  String _formatXValue(double value) {
    final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
