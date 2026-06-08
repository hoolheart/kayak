import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/device.dart';
import '../models/experiment.dart';
import '../models/point.dart';

part 'analysis_state.freezed.dart';

// ============================================================
// 颜色分配
// ============================================================

/// 测点曲线颜色（固定分配）
///
/// 6 种颜色，按选中顺序分配。修改此处影响曲线和图例颜色，
/// 请同时修改 [chartLineColorsDark]。
const List<Color> chartLineColorsLight = [
  Color(0xFFE53935), // 红
  Color(0xFF43A047), // 绿
  Color(0xFF1E88E5), // 蓝
  Color(0xFFFB8C00), // 橙
  Color(0xFF8E24AA), // 紫
  Color(0xFF00ACC1), // 青
];

/// 测点曲线颜色（深色主题 — 提亮版本）
const List<Color> chartLineColorsDark = [
  Color(0xFFEF5350), // 红
  Color(0xFF66BB6A), // 绿
  Color(0xFF42A5F5), // 蓝
  Color(0xFFFFA726), // 橙
  Color(0xFFAB47BC), // 紫
  Color(0xFF26C6DA), // 青
];

/// 获取测点曲线颜色（根据主题）
List<Color> chartLineColors(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  return brightness == Brightness.dark
      ? chartLineColorsDark
      : chartLineColorsLight;
}

// ============================================================
// 模型
// ============================================================

/// 单个测点的图表数据
class ChartPointData {
  const ChartPointData({
    required this.pointId,
    required this.pointName,
    required this.unit,
    required this.timestamps,
    required this.values,
    required this.colorIndex,
  });

  final String pointId;
  final String pointName;
  final String unit;
  final List<DateTime> timestamps;
  final List<double?> values;

  /// 在 [chartLineColorsLight]/[chartLineColorsDark] 中的索引
  final int colorIndex;

  /// 获取该点当前主题下的颜色（便捷方法，但建议在 widget 层调用
  /// [chartLineColors] 统一获取）
  Color color(BuildContext context) {
    return chartLineColors(context)[colorIndex];
  }
}

/// 图表渲染数据
class ChartData {
  const ChartData({
    required this.experimentId,
    required this.deviceId,
    required this.points,
    this.totalSamples = 0,
    this.returnedSamples = 0,
  });

  final String experimentId;
  final String deviceId;
  final List<ChartPointData> points;

  final int totalSamples;
  final int returnedSamples;

  bool get isEmpty => points.every((p) => p.values.every((v) => v == null));

  DateTime get minTimestamp {
    if (points.isEmpty) {
      throw StateError('Cannot get minTimestamp from empty ChartData');
    }
    return points
        .map((p) => p.timestamps.first)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime get maxTimestamp {
    if (points.isEmpty) {
      throw StateError('Cannot get maxTimestamp from empty ChartData');
    }
    return points
        .map((p) => p.timestamps.last)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}

/// 时间范围预设
enum TimeRangePreset {
  oneHour,
  twentyFourHours,
  all,
}

// ============================================================
// AnalysisState — 分析页面完整状态（freezed）
// ============================================================

/// 分析页面完整状态
///
/// 使用 freezed 自动生成 ==、hashCode、copyWith 和 toString。
@freezed
abstract class AnalysisState with _$AnalysisState {
  const factory AnalysisState({

    /// 试验列表状态
    @Default(AsyncLoading<List<Experiment>>())
    AsyncValue<List<Experiment>> experiments,

    /// 当前选中的试验 ID
    String? selectedExperimentId,

    /// 当前选中的试验关联的设备列表（null=未加载, [] = 空）
    List<Device>? devices,

    /// 当前选中的设备 ID
    String? selectedDeviceId,

    /// 当前设备下的测点列表
    List<Point>? points,

    /// 已选测点 ID 集合
    @Default({}) Set<String> selectedPointIds,

    /// 时间范围预设
    @Default(TimeRangePreset.oneHour) TimeRangePreset timePreset,

    /// 自定义开始时间
    DateTime? customStart,

    /// 自定义结束时间
    DateTime? customEnd,

    /// 降采样点数
    @Default(1000) int downsample,

    /// 图表数据状态
    @Default(AsyncData<ChartData?>(null)) AsyncValue<ChartData?> chartData,

    /// 是否显示数据表格
    @Default(false) bool showDataTable,

    /// 是否正在加载数据（防重复提交）
    @Default(false) bool isLoadingData,

    /// 被图例隐藏的测点 ID 集合
    @Default({}) Set<String> hiddenPointIds,
  }) = _AnalysisState;
}

// ============================================================
// AnalysisState 扩展方法
// ============================================================

/// AnalysisState 便捷属性扩展
extension AnalysisStateX on AnalysisState {
  /// 是否已选择试验
  bool get hasExperiment => selectedExperimentId != null;

  /// 是否已选择设备
  bool get hasDevice => selectedDeviceId != null;

  /// 是否已选择测点
  bool get hasPoints => selectedPointIds.isNotEmpty;

  /// "加载数据"按钮是否可启用
  bool get canLoadData => hasExperiment && hasDevice && hasPoints;

  /// 获取当前选中的试验对象
  Experiment? get selectedExperiment {
    return experiments.whenOrNull(
      data: (list) {
        if (selectedExperimentId == null) return null;
        return list.where((e) => e.id == selectedExperimentId).firstOrNull;
      },
    );
  }

  /// 获取当前选中的设备对象
  Device? get selectedDevice {
    if (devices == null || selectedDeviceId == null) return null;
    return devices!.where((d) => d.id == selectedDeviceId).firstOrNull;
  }

  /// 获取当前选中的测点信息（用于图表和图例）
  List<Point> get selectedPointDetails {
    if (points == null) return [];
    return points!
        .where((p) => selectedPointIds.contains(p.id))
        .toList(growable: false);
  }

  /// 获取时间范围验证错误（null = 无错误）
  ///
  /// TODO: 迁移到 l10n（已识别为 Low Issue 13）
  String? get timeRangeError {
    if (customStart != null && customEnd != null) {
      if (customStart!.isAfter(customEnd!)) {
        return '开始时间必须早于结束时间';
      }
      final diff = customEnd!.difference(customStart!);
      if (diff.inDays > 30) {
        return '查询时间范围不能超过30天';
      }
      if (customStart!.isAfter(DateTime.now())) {
        return '开始时间不能是未来时间';
      }
      if (customEnd!.isAfter(DateTime.now())) {
        return '结束时间不能是未来时间';
      }
    }
    return null;
  }
}
