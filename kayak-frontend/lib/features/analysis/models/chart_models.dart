/// 图表数据模型
///
/// 定义时序图表相关的数据模型，包括数据查询请求、响应、测点序列等。
library;

import 'package:flutter/material.dart';

/// 图表数据查询请求
class DataQueryRequest {
  const DataQueryRequest({
    required this.experimentId,
    required this.deviceId,
    required this.pointIds,
    this.startTime,
    this.endTime,
    this.downsample = 1000,
  });

  final String experimentId;
  final String deviceId;
  final List<String> pointIds;
  final DateTime? startTime;
  final DateTime? endTime;
  final int downsample;

  Map<String, dynamic> toJson() {
    return {
      'experiment_id': experimentId,
      'device_id': deviceId,
      'point_ids': pointIds,
      if (startTime != null)
        'start_time': startTime!.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toUtc().toIso8601String(),
      'downsample': downsample,
    };
  }
}

/// 测点时序数据序列
class ChartPointSeries {
  const ChartPointSeries({
    required this.pointId,
    required this.pointName,
    required this.unit,
    required this.dataType,
    required this.timestamps,
    required this.values,
  });

  factory ChartPointSeries.fromJson(Map<String, dynamic> json) {
    return ChartPointSeries(
      pointId: json['point_id'] as String,
      pointName: json['point_name'] as String,
      unit: json['unit'] as String,
      dataType: json['data_type'] as String,
      timestamps: (json['timestamps'] as List).cast<int>(),
      values: (json['values'] as List).cast<double>(),
    );
  }

  final String pointId;
  final String pointName;
  final String unit;
  final String dataType;
  final List<int> timestamps; // Unix timestamps in milliseconds
  final List<double> values;

  /// 获取数据点数量
  int get length => timestamps.length;

  /// 将时间戳转换为 DateTime
  List<DateTime> get dateTimes =>
      timestamps.map(DateTime.fromMillisecondsSinceEpoch).toList();

  /// 获取最小值
  double get minValue => values.reduce((a, b) => a < b ? a : b);

  /// 获取最大值
  double get maxValue => values.reduce((a, b) => a > b ? a : b);

  ChartPointSeries copyWith({
    String? pointId,
    String? pointName,
    String? unit,
    String? dataType,
    List<int>? timestamps,
    List<double>? values,
  }) {
    return ChartPointSeries(
      pointId: pointId ?? this.pointId,
      pointName: pointName ?? this.pointName,
      unit: unit ?? this.unit,
      dataType: dataType ?? this.dataType,
      timestamps: timestamps ?? this.timestamps,
      values: values ?? this.values,
    );
  }
}

/// 图表数据响应
class ChartDataResponse {
  const ChartDataResponse({
    required this.experimentId,
    required this.deviceId,
    required this.points,
    required this.totalSamples,
    required this.returnedSamples,
  });

  factory ChartDataResponse.fromJson(Map<String, dynamic> json) {
    return ChartDataResponse(
      experimentId: json['experiment_id'] as String,
      deviceId: json['device_id'] as String,
      points: (json['points'] as List)
          .map((e) => ChartPointSeries.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSamples: json['total_samples'] as int,
      returnedSamples: json['returned_samples'] as int,
    );
  }

  final String experimentId;
  final String deviceId;
  final List<ChartPointSeries> points;
  final int totalSamples;
  final int returnedSamples;

  /// 获取所有时间戳的并集
  List<int> get allTimestamps {
    final set = <int>{};
    for (final point in points) {
      set.addAll(point.timestamps);
    }
    return set.toList()..sort();
  }
}

/// 图表状态枚举
enum ChartState {
  empty,
  loading,
  loaded,
  error,
  noDataInRange,
}

/// 图表视图状态
class ChartViewState {
  const ChartViewState({
    this.state = ChartState.empty,
    this.data,
    this.errorMessage,
    this.visibleSeries = const {},
    this.hoveredSeriesIndex,
  });

  final ChartState state;
  final ChartDataResponse? data;
  final String? errorMessage;
  final Set<String> visibleSeries; // pointId set
  final int? hoveredSeriesIndex;

  ChartViewState copyWith({
    ChartState? state,
    ChartDataResponse? data,
    String? errorMessage,
    Set<String>? visibleSeries,
    Object? hoveredSeriesIndex = const Object(),
  }) {
    return ChartViewState(
      state: state ?? this.state,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      visibleSeries: visibleSeries ?? this.visibleSeries,
      hoveredSeriesIndex: hoveredSeriesIndex != const Object()
          ? hoveredSeriesIndex as int?
          : this.hoveredSeriesIndex,
    );
  }

  /// 检查测点是否可见
  bool isSeriesVisible(String pointId) => visibleSeries.contains(pointId);
}

/// 控制面板状态
class AnalysisControlState {
  const AnalysisControlState({
    this.selectedExperimentId,
    this.selectedDeviceId,
    this.selectedPointIds = const <String>[],
    this.startTime,
    this.endTime,
    this.downsample = 1000,
    this.showDataTable = false,
    this.autoRefresh = false,
    this.isLoadingExperiments = false,
    this.isLoadingDevices = false,
    this.isLoadingPoints = false,
    this.activePreset,
  });

  final String? selectedExperimentId;
  final String? selectedDeviceId;
  final List<String> selectedPointIds;
  final DateTime? startTime;
  final DateTime? endTime;
  final int downsample;
  final bool showDataTable;
  final bool autoRefresh;
  final bool isLoadingExperiments;
  final bool isLoadingDevices;
  final bool isLoadingPoints;

  /// 当前激活的预设时间范围（如 '1h', '24h', 'all'）
  final String? activePreset;

  AnalysisControlState copyWith({
    Object? selectedExperimentId = const Object(),
    Object? selectedDeviceId = const Object(),
    Object? selectedPointIds = const Object(),
    Object? startTime = const Object(),
    Object? endTime = const Object(),
    Object? downsample = const Object(),
    Object? showDataTable = const Object(),
    Object? autoRefresh = const Object(),
    Object? isLoadingExperiments = const Object(),
    Object? isLoadingDevices = const Object(),
    Object? isLoadingPoints = const Object(),
    Object? activePreset = const Object(),
  }) {
    return AnalysisControlState(
      selectedExperimentId: selectedExperimentId != const Object()
          ? selectedExperimentId as String?
          : this.selectedExperimentId,
      selectedDeviceId: selectedDeviceId != const Object()
          ? selectedDeviceId as String?
          : this.selectedDeviceId,
      selectedPointIds: selectedPointIds != const Object()
          ? selectedPointIds as List<String>
          : this.selectedPointIds,
      startTime: startTime != const Object()
          ? startTime as DateTime?
          : this.startTime,
      endTime: endTime != const Object()
          ? endTime as DateTime?
          : this.endTime,
      downsample: downsample != const Object()
          ? downsample as int
          : this.downsample,
      showDataTable: showDataTable != const Object()
          ? showDataTable as bool
          : this.showDataTable,
      autoRefresh: autoRefresh != const Object()
          ? autoRefresh as bool
          : this.autoRefresh,
      isLoadingExperiments: isLoadingExperiments != const Object()
          ? isLoadingExperiments as bool
          : this.isLoadingExperiments,
      isLoadingDevices: isLoadingDevices != const Object()
          ? isLoadingDevices as bool
          : this.isLoadingDevices,
      isLoadingPoints: isLoadingPoints != const Object()
          ? isLoadingPoints as bool
          : this.isLoadingPoints,
      activePreset: activePreset != const Object()
          ? activePreset as String?
          : this.activePreset,
    );
  }

  /// 检查是否可以加载数据
  bool get canLoadData =>
      selectedExperimentId != null &&
      selectedDeviceId != null &&
      selectedPointIds.isNotEmpty;
}

/// 图表光标数据（用于 Tooltip）
class ChartCursorData {
  const ChartCursorData({
    required this.timestamp,
    required this.values,
  });

  final DateTime timestamp;
  final List<CursorValue> values;
}

/// 光标处的单个数值
class CursorValue {
  const CursorValue({
    required this.pointId,
    required this.pointName,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String pointId;
  final String pointName;
  final double value;
  final String unit;
  final Color color;
}
