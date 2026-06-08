import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/experiment.dart';
import '../services/analysis_service.dart';
import '../services/device_service.dart';
import '../services/experiment_service.dart';
import '../services/point_service.dart';
import 'analysis_state.dart';
import 'services.dart';

// 重新导出 analysis_state.dart 中的类型以兼容现有 imports
export 'analysis_state.dart';

// ============================================================
// AnalysisNotifier
// ============================================================

/// AnalysisNotifier — 分析页面状态管理器
///
/// 职责：
/// 1. 管理试验/设备/测点级联选择
/// 2. 管理时间范围和降采样配置
/// 3. 加载图表数据
/// 4. 管理数据表格显示/隐藏
/// 5. 管理图例切换
class AnalysisNotifier extends Notifier<AnalysisState> {
  @override
  AnalysisState build() {
    // 使用微任务延迟加载，避免在 build() 中同步设置 state
    // 导致 Riverpod 未初始化错误
    Future.microtask(_loadExperiments);
    return const AnalysisState();
  }

  ExperimentService get _experimentService =>
      ref.read(experimentServiceProvider);

  DeviceService get _deviceService => ref.read(deviceServiceProvider);

  PointService get _pointService => ref.read(pointServiceProvider);

  AnalysisService get _analysisService => ref.read(analysisServiceProvider);

  // ============================================================
  // 试验加载
  // ============================================================

  /// 加载已完成/中止的试验列表
  Future<void> _loadExperiments() async {
    state = state.copyWith(
      experiments: const AsyncLoading(),
    );

    state = state.copyWith(
      experiments: await AsyncValue.guard(_fetchExperiments),
    );
  }

  Future<List<Experiment>> _fetchExperiments() async {
    // size: 500 避免分页限制；后续迭代可加入懒加载（Issue 5）
    final response = await _experimentService.list(size: 500);
    return response.items
        .where(
          (e) =>
              e.status == ExperimentStatus.completed ||
              e.status == ExperimentStatus.aborted,
        )
        .toList(growable: false);
  }

  /// 刷新试验列表
  Future<void> refreshExperiments() async {
    await _loadExperiments();
  }

  // ============================================================
  // 试验选择
  // ============================================================

  /// 选择试验
  ///
  /// 级联重置设备/测点选择，触发设备列表加载。
  Future<void> selectExperiment(String? experimentId) async {
    if (experimentId == null || experimentId == state.selectedExperimentId) {
      return;
    }

    state = state.copyWith(
      selectedExperimentId: experimentId,
      selectedDeviceId: null,
      devices: null,
      points: null,
      selectedPointIds: <String>{},
      chartData: const AsyncData(null),
      hiddenPointIds: <String>{},
    );

    // 加载设备列表
    final experiment = state.selectedExperiment;
    if (experiment == null) return;

    try {
      final devices = await _deviceService.listByWorkbench(experiment.ownerId);
      state = state.copyWith(devices: devices);
    } catch (e) {
      // 加载失败时设置空列表 + 记录错误（Issue 11）
      state = state.copyWith(devices: []);
      debugPrint('Failed to load devices for experiment $experimentId: $e');
    }
  }

  // ============================================================
  // 设备选择
  // ============================================================

  /// 选择设备
  ///
  /// 级联重置测点选择，触发测点列表加载。
  Future<void> selectDevice(String? deviceId) async {
    if (deviceId == null || deviceId == state.selectedDeviceId) {
      return;
    }

    state = state.copyWith(
      selectedDeviceId: deviceId,
      points: null,
      selectedPointIds: const {},
      chartData: const AsyncData(null),
      hiddenPointIds: const {},
    );

    // 加载测点列表
    try {
      final points = await _pointService.listByDevice(deviceId);
      state = state.copyWith(points: points);
    } catch (e) {
      // 加载失败时设置空列表 + 记录错误（Issue 11）
      state = state.copyWith(points: []);
      debugPrint('Failed to load points for device $deviceId: $e');
    }
  }

  // ============================================================
  // 测点选择
  // ============================================================

  /// 切换测点选中状态
  ///
  /// 最多选中 4 个，超过限制时返回 false。
  bool togglePoint(String pointId) {
    final selected = Set<String>.from(state.selectedPointIds);

    if (selected.contains(pointId)) {
      selected.remove(pointId);
      state = state.copyWith(selectedPointIds: selected);
      return true;
    }

    if (selected.length >= 4) {
      return false;
    }

    selected.add(pointId);
    state = state.copyWith(selectedPointIds: selected);
    return true;
  }

  // ============================================================
  // 时间范围
  // ============================================================

  /// 选择预设时间
  void selectTimePreset(TimeRangePreset preset) {
    state = state.copyWith(
      timePreset: preset,
      customStart: null,
      customEnd: null,
    );
  }

  /// 设置自定义开始时间
  void setCustomStart(DateTime? time) {
    state = state.copyWith(customStart: time);
  }

  /// 设置自定义结束时间
  void setCustomEnd(DateTime? time) {
    state = state.copyWith(customEnd: time);
  }

  // ============================================================
  // 降采样
  // ============================================================

  /// 设置降采样点数
  void setDownsample(int value) {
    state = state.copyWith(downsample: value);
  }

  // ============================================================
  // 数据加载
  // ============================================================

  /// 加载图表数据
  ///
  /// 前置条件：已选择试验、设备、至少一个测点。
  Future<void> loadChartData() async {
    if (!state.canLoadData) return;
    if (state.isLoadingData) return;
    if (state.timeRangeError != null) return;

    state = state.copyWith(
      isLoadingData: true,
      chartData: const AsyncLoading(),
    );

    final experimentId = state.selectedExperimentId!;
    final deviceId = state.selectedDeviceId!;

    // 按 points 列表中的顺序而不是 selectedPointIds 的集合迭代顺序，
    // 保证颜色分配稳定（Issue 10）
    final pointIds = state.points!
        .where((p) => state.selectedPointIds.contains(p.id))
        .map((p) => p.id)
        .toList(growable: false);

    final downsample = state.downsample;

    // 计算时间范围
    DateTime? startTime;
    DateTime? endTime;

    switch (state.timePreset) {
      case TimeRangePreset.oneHour:
        endTime = DateTime.now();
        startTime = endTime.subtract(const Duration(hours: 1));
      case TimeRangePreset.twentyFourHours:
        endTime = DateTime.now();
        startTime = endTime.subtract(const Duration(hours: 24));
      case TimeRangePreset.all:
        // 不传时间范围参数
        break;
    }

    // 自定义时间覆盖预设
    if (state.customStart != null) {
      startTime = state.customStart;
    }
    if (state.customEnd != null) {
      endTime = state.customEnd;
    }

    try {
      final timeSeriesData = await _analysisService.loadChartData(
        experimentId: experimentId,
        deviceId: deviceId,
        pointIds: pointIds,
        startTime: startTime,
        endTime: endTime,
        downsample: downsample,
      );

      // 将 TimeSeriesData 转换为 ChartData
      final chartData = _buildChartData(
        experimentId: experimentId,
        deviceId: deviceId,
        timeSeriesData: timeSeriesData,
        pointIds: pointIds,
      );

      state = state.copyWith(
        chartData: AsyncData(chartData),
        isLoadingData: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        chartData: AsyncError(e, st),
        isLoadingData: false,
      );
    }
  }

  /// 将 TimeSeriesData 转换为 ChartData
  ///
  /// 颜色索引在 state 层存储，实际颜色在 widget 层通过
  /// [chartLineColors] + 当前主题解析（Issue 1 修复）。
  ChartData _buildChartData({
    required String experimentId,
    required String deviceId,
    required TimeSeriesData timeSeriesData,
    required List<String> pointIds,
  }) {
    final pointDetails = state.selectedPointDetails;

    final chartPoints = <ChartPointData>[];

    for (var i = 0; i < pointIds.length; i++) {
      final pointId = pointIds[i];
      final values = timeSeriesData.values[pointId] ?? [];
      final detail = pointDetails.where((p) => p.id == pointId).firstOrNull;

      chartPoints.add(
        ChartPointData(
          pointId: pointId,
          pointName: detail?.name ?? pointId,
          unit: detail?.unit ?? '',
          timestamps: timeSeriesData.timestamps,
          values: values,
          colorIndex: i % chartLineColorsLight.length,
        ),
      );
    }

    // 计算总样本数
    final totalSamples = timeSeriesData.values.values.fold<int>(
      0,
      (sum, v) => sum + v.length,
    );

    return ChartData(
      experimentId: experimentId,
      deviceId: deviceId,
      points: chartPoints,
      totalSamples: totalSamples,
      returnedSamples: totalSamples,
    );
  }

  // ============================================================
  // 图表交互
  // ============================================================

  /// 重置图表视图（恢复默认缩放/平移）
  void resetChart() {
    final current = state.chartData;
    if (current.hasValue && current.value != null) {
      state = state.copyWith(chartData: AsyncData(current.value));
    }
  }

  /// 切换数据表格显示
  void toggleDataTable() {
    state = state.copyWith(showDataTable: !state.showDataTable);
  }

  /// 切换图例中测点的显示/隐藏
  void togglePointVisibility(String pointId) {
    final hidden = Set<String>.from(state.hiddenPointIds);
    if (hidden.contains(pointId)) {
      hidden.remove(pointId);
    } else {
      hidden.add(pointId);
    }
    state = state.copyWith(hiddenPointIds: hidden);
  }
}

// ============================================================
// Provider
// ============================================================

/// 分析页面状态 Provider
final analysisProvider =
    NotifierProvider<AnalysisNotifier, AnalysisState>(
  AnalysisNotifier.new,
);
