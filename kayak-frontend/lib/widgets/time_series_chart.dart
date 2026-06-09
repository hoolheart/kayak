import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../providers/analysis_provider.dart';

/// TimeSeriesChart — 可复用时序折线图组件
///
/// 基于 fl_chart 1.2.0 实现，支持：
/// - 多曲线叠加（最多 6 条）
/// - 触摸悬停提示
/// - 滚轮缩放 + 拖拽平移
/// - 图例隐藏/显示
class TimeSeriesChart extends StatefulWidget {
  const TimeSeriesChart({
    super.key,
    required this.data,
    this.hiddenPointIds = const {},
    this.onTogglePoint,
  });

  final ChartData data;
  final Set<String> hiddenPointIds;
  final void Function(String pointId)? onTogglePoint;

  @override
  State<TimeSeriesChart> createState() => _TimeSeriesChartState();
}

class _TimeSeriesChartState extends State<TimeSeriesChart> {
  double _minX = 0;
  double _maxX = 1;
  bool _initialized = false;
  double? _lastDragX;

  @override
  void didUpdateWidget(TimeSeriesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.points.isEmpty) return;
    // 数据变化时重置范围，同时也处理首次挂载后数据就绪的情况（Issue 17）
    if (oldWidget.data != widget.data || !_initialized) {
      _initRange();
    }
  }

  void _initRange() {
    if (widget.data.points.isEmpty) return;
    final firstTs = widget.data.minTimestamp.millisecondsSinceEpoch.toDouble();
    final lastTs = widget.data.maxTimestamp.millisecondsSinceEpoch.toDouble();
    if (firstTs < lastTs) {
      _minX = firstTs;
      _maxX = lastTs;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.points.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 计算 Y 轴范围
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;
    for (final point in data.points) {
      if (widget.hiddenPointIds.contains(point.pointId)) continue;
      for (final v in point.values) {
        if (v != null) {
          yMin = math.min(yMin, v);
          yMax = math.max(yMax, v);
        }
      }
    }
    if (yMin == double.infinity) {
      yMin = 0;
      yMax = 100;
    }
    final yPadding = (yMax - yMin) * 0.1;
    if (yPadding == 0) {
      yMin -= 10;
      yMax += 10;
    } else {
      yMin -= yPadding;
      yMax += yPadding;
    }

    final isSameDay = data.minTimestamp.day == data.maxTimestamp.day &&
        data.minTimestamp.month == data.maxTimestamp.month;

    // 获取当前主题下的颜色（Issue 1）
    final lineColors = chartLineColors(context);

    return Column(
      children: [
        _buildLegend(context, data, lineColors),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: _buildChart(context, data, yMin, yMax, isSameDay,
                colorScheme, textTheme, lineColors),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, ChartData data, List<Color> lineColors) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: data.points.map((point) {
          final isHidden = widget.hiddenPointIds.contains(point.pointId);
          return GestureDetector(
            onTap: () => widget.onTogglePoint?.call(point.pointId),
            child: Opacity(
              opacity: isHidden ? 0.38 : 1.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isHidden
                          ? theme.colorScheme.onSurfaceVariant
                          : lineColors[point.colorIndex],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${point.pointName}${point.unit.isNotEmpty ? ' (${point.unit})' : ''}',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      decoration:
                          isHidden ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    ChartData data,
    double yMin,
    double yMax,
    bool isSameDay,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<Color> lineColors,
  ) {
    final totalPoints =
        data.points.fold<int>(0, (sum, p) => sum + p.values.length);
    final hideDots = totalPoints > 500;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _handleScroll(event);
            }
          },
          child: GestureDetector(
            onScaleStart: (details) {
              _lastDragX = details.localFocalPoint.dx;
            },
            onScaleUpdate: (details) {
              if (details.pointerCount == 1) {
                _handlePan(details.localFocalPoint.dx);
              } else if (details.pointerCount == 2) {
                _handlePinchZoom(details.scale);
              }
            },
            onScaleEnd: (_) {
              _lastDragX = null;
            },
            child: LineChart(
              LineChartData(
                minX: _initialized ? _minX : null,
                maxX: _initialized ? _maxX : null,
                minY: yMin,
                maxY: yMax,
                gridData: FlGridData(
                  horizontalInterval: _calcInterval(yMin, yMax),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withAlpha(128),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withAlpha(128),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(128),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return _buildBottomTitle(
                            value, meta, isSameDay, textTheme, colorScheme);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return _buildLeftTitle(
                            value, meta, textTheme, colorScheme);
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.surface,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    maxContentWidth: 280,
                    getTooltipItems: (touchedSpots) {
                      return _buildTooltipItems(
                          touchedSpots, data, isSameDay, textTheme, colorScheme, lineColors);
                    },
                  ),
                ),
                lineBarsData: _buildLineBars(data, hideDots, lineColors),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
        );
      },
    );
  }

  List<LineChartBarData> _buildLineBars(ChartData data, bool hideDots, List<Color> lineColors) {
    return data.points
        .where((p) => !widget.hiddenPointIds.contains(p.pointId))
        .map((point) {
      final spots = <FlSpot>[];
      for (var i = 0; i < point.timestamps.length; i++) {
        final x = point.timestamps[i].millisecondsSinceEpoch.toDouble();
        final y = point.values[i];
        if (y != null) {
          spots.add(FlSpot(x, y));
        }
      }

      final color = lineColors[point.colorIndex];

      final dotStrokeColor = color.withAlpha(180);

      return LineChartBarData(
        spots: spots,
        color: color,
        dotData: FlDotData(
          show: !hideDots && spots.length <= 100,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 3,
              color: color,
              strokeWidth: 1,
              strokeColor: dotStrokeColor,
            );
          },
        ),
        belowBarData: BarAreaData(),
      );
    }).toList();
  }

  /// 格式化时间戳为可读字符串
  ///
  /// 跨天显示 `MM-dd HH:mm`，同天显示 `HH:mm:ss`。
  /// 提取为公共方法避免在 _buildBottomTitle 和 _buildTooltipItems 间重复（Issue 14）。
  String _formatTimestamp(DateTime dateTime, bool isSameDay,
      {bool showSeconds = false}) {
    if (isSameDay) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}'
          '${showSeconds ? ':${dateTime.second.toString().padLeft(2, '0')}' : ''}';
    }
    return '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${showSeconds ? ':${dateTime.second.toString().padLeft(2, '0')}' : ''}';
  }

  Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    bool isSameDay,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    final label = _formatTimestamp(dateTime, isSameDay);

    return SideTitleWidget(
      meta: meta,
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(
    double value,
    TitleMeta meta,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    String label;
    if (value.abs() >= 10000) {
      label = value.toStringAsExponential(1);
    } else if (value == value.truncateToDouble()) {
      label = value.toInt().toString();
    } else {
      label = value.toStringAsFixed(1);
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  List<LineTooltipItem?> _buildTooltipItems(
    List<LineBarSpot> touchedSpots,
    ChartData data,
    bool isSameDay,
    TextTheme textTheme,
    ColorScheme colorScheme,
    List<Color> lineColors,
  ) {
    if (touchedSpots.isEmpty) return [];

    final items = <LineTooltipItem?>[];
    final firstSpot = touchedSpots.first;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
        firstSpot.x.toInt(), isUtc: true);
    final timeLabel = _formatTimestamp(dateTime, isSameDay, showSeconds: true);

    items.add(LineTooltipItem(
      timeLabel,
      TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
    ));

    // 分隔线
    items.add(LineTooltipItem(
      '\n${'─' * 20}',
      TextStyle(fontSize: 10, color: colorScheme.outlineVariant),
    ));

    for (final spot in touchedSpots) {
      final barIndex = spot.barIndex;
      if (barIndex < data.points.length) {
        final point = data.points[barIndex];
        final valueStr = spot.y == spot.y.truncateToDouble()
            ? spot.y.toInt().toString()
            : spot.y.toStringAsFixed(2);

        items.add(LineTooltipItem(
          '\n${point.pointName}: $valueStr ${point.unit}',
          TextStyle(
            fontSize: 12,
            color: lineColors[point.colorIndex],
            fontWeight: FontWeight.w600,
          ),
        ));
      }
    }

    return items;
  }

  void _handleScroll(PointerScrollEvent event) {
    if (!_initialized) return;

    final scale = event.scrollDelta.dy > 0 ? 1.15 : 0.87;
    final range = _maxX - _minX;
    if (range <= 0) return;
    final center = (_minX + _maxX) / 2;
    final newRange = range * scale;
    final newMin = center - newRange / 2;
    final newMax = center + newRange / 2;

    final firstTs = widget.data.minTimestamp.millisecondsSinceEpoch.toDouble();
    final lastTs = widget.data.maxTimestamp.millisecondsSinceEpoch.toDouble();

    setState(() {
      _minX = newMin.clamp(firstTs, lastTs - newRange * 0.01);
      _maxX = newMax.clamp(firstTs + newRange * 0.01, lastTs);
    });
  }

  void _handlePan(double currentX) {
    if (!_initialized || _lastDragX == null) return;

    final dx = currentX - _lastDragX!;
    final chartWidth = context.size?.width ?? 400;
    if (chartWidth <= 0) return;

    final dataRange = _maxX - _minX;
    final delta = -(dx / chartWidth) * dataRange;

    final firstTs = widget.data.minTimestamp.millisecondsSinceEpoch.toDouble();
    final lastTs = widget.data.maxTimestamp.millisecondsSinceEpoch.toDouble();

    final newMin =
        (_minX + delta).clamp(firstTs, lastTs - dataRange * 0.99);
    final newMax = newMin + dataRange;

    setState(() {
      _minX = newMin;
      _maxX = newMax;
    });

    _lastDragX = currentX;
  }

  void _handlePinchZoom(double scale) {
    if (!_initialized) return;

    final range = _maxX - _minX;
    if (range <= 0) return;
    final center = (_minX + _maxX) / 2;
    final newRange = range / scale;
    final newMin = center - newRange / 2;
    final newMax = center + newRange / 2;

    final firstTs = widget.data.minTimestamp.millisecondsSinceEpoch.toDouble();
    final lastTs = widget.data.maxTimestamp.millisecondsSinceEpoch.toDouble();

    setState(() {
      _minX = newMin.clamp(firstTs, lastTs - newRange * 0.01);
      _maxX = newMax.clamp(firstTs + newRange * 0.01, lastTs);
    });
  }

  double _calcInterval(double min, double max) {
    final raw = (max - min) / 5;
    if (raw == 0) return 1;
    final magnitude =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final residual = raw / magnitude;
    if (residual > 5) return magnitude * 10;
    if (residual > 2) return magnitude * 5;
    if (residual > 1) return magnitude * 2;
    return magnitude;
  }
}
