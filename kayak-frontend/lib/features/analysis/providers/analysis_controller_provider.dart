/// 分析页面控制状态管理
///
/// 管理控制面板的状态：试验选择、设备选择、测点选择、时间范围、降采样等。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/experiments/models/experiment.dart';
import '../../../features/workbench/models/device.dart';
import '../../../features/workbench/models/point.dart';
import '../models/chart_models.dart';
import '../services/mock_analysis_service.dart';

/// 分析服务 Provider
final analysisServiceProvider = Provider<AnalysisService>((ref) {
  return MockAnalysisService();
});

/// 试验列表 Provider
final experimentListForAnalysisProvider =
    FutureProvider.autoDispose<List<Experiment>>((ref) async {
  // Mock data for development
  return [
    Experiment(
      id: 'exp-001',
      userId: 'user-001',
      name: '温度压力联合测试',
      status: ExperimentStatus.completed,
      createdAt: DateTime.parse('2026-05-01T00:00:00Z'),
      updatedAt: DateTime.parse('2026-05-01T23:59:59Z'),
    ),
    Experiment(
      id: 'exp-002',
      userId: 'user-001',
      name: '流量稳定性试验',
      status: ExperimentStatus.running,
      createdAt: DateTime.parse('2026-05-02T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-02T10:30:00Z'),
    ),
    Experiment(
      id: 'exp-003',
      userId: 'user-001',
      name: '振动频谱分析',
      status: ExperimentStatus.completed,
      createdAt: DateTime.parse('2026-05-03T08:00:00Z'),
      updatedAt: DateTime.parse('2026-05-03T18:00:00Z'),
    ),
  ];
});

/// 设备列表 Provider（基于选择的试验）
final deviceListForAnalysisProvider =
    FutureProvider.autoDispose.family<List<Device>, String>((ref, experimentId) async {
  // Mock data for development
  return [
    Device(
      id: 'dev-001',
      workbenchId: 'wb-001',
      name: '虚拟传感器A',
      protocolType: ProtocolType.virtual,
      status: DeviceStatus.online,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Device(
      id: 'dev-002',
      workbenchId: 'wb-001',
      name: 'Modbus温控器',
      protocolType: ProtocolType.modbusTcp,
      status: DeviceStatus.online,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
});

/// 测点列表 Provider（基于选择的设备）
final pointListForAnalysisProvider =
    FutureProvider.autoDispose.family<List<Point>, String>((ref, deviceId) async {
  // Mock data for development
  return [
    Point(
      id: 'pt-001',
      deviceId: deviceId,
      name: 'Temperature',
      dataType: DataType.number,
      accessType: AccessType.ro,
      unit: '°C',
      minValue: -40.0,
      maxValue: 85.0,
      status: PointStatus.active,
    ),
    Point(
      id: 'pt-002',
      deviceId: deviceId,
      name: 'Pressure',
      dataType: DataType.number,
      accessType: AccessType.ro,
      unit: 'Pa',
      minValue: 0.0,
      maxValue: 100000.0,
      status: PointStatus.active,
    ),
    Point(
      id: 'pt-003',
      deviceId: deviceId,
      name: 'Flow Rate',
      dataType: DataType.number,
      accessType: AccessType.ro,
      unit: 'L/min',
      minValue: 0.0,
      maxValue: 100.0,
      status: PointStatus.active,
    ),
    Point(
      id: 'pt-004',
      deviceId: deviceId,
      name: 'Vibration',
      dataType: DataType.number,
      accessType: AccessType.ro,
      unit: 'mm/s',
      minValue: 0.0,
      maxValue: 10.0,
      status: PointStatus.active,
    ),
    Point(
      id: 'pt-005',
      deviceId: deviceId,
      name: 'Humidity',
      dataType: DataType.number,
      accessType: AccessType.ro,
      unit: '%RH',
      minValue: 0.0,
      maxValue: 100.0,
      status: PointStatus.active,
    ),
  ];
});

/// 控制状态 Notifier
class AnalysisControllerNotifier extends StateNotifier<AnalysisControlState> {
  AnalysisControllerNotifier() : super(const AnalysisControlState());

  /// 选择试验
  void selectExperiment(String? experimentId) {
    state = state.copyWith(
      selectedExperimentId: experimentId,
      selectedDeviceId: null,
      selectedPointIds: const <String>[],
    );
  }

  /// 选择设备
  void selectDevice(String? deviceId) {
    state = state.copyWith(
      selectedDeviceId: deviceId,
      selectedPointIds: const <String>[],
    );
  }

  /// 切换测点选择
  void togglePointSelection(String pointId) {
    final current = List<String>.from(state.selectedPointIds);
    if (current.contains(pointId)) {
      current.remove(pointId);
    } else {
      if (current.length >= 4) {
        // 最多4个测点
        return;
      }
      current.add(pointId);
    }
    state = state.copyWith(selectedPointIds: current);
  }

  /// 设置时间范围
  void setTimeRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startTime: start,
      endTime: end,
      activePreset: null,
    );
  }

  /// 设置降采样点数
  void setDownsample(int value) {
    state = state.copyWith(downsample: value.clamp(100, 10000));
  }

  /// 切换数据表格显示
  void toggleDataTable(bool show) {
    state = state.copyWith(showDataTable: show);
  }

  /// 切换自动刷新
  void toggleAutoRefresh(bool autoRefresh) {
    state = state.copyWith(autoRefresh: autoRefresh);
  }

  /// 应用预设时间范围
  void applyPresetTimeRange(String preset) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end = now;

    switch (preset) {
      case '1h':
        start = now.subtract(const Duration(hours: 1));
      case '24h':
        start = now.subtract(const Duration(hours: 24));
      case 'all':
        start = null;
        end = null;
    }

    state = state.copyWith(
      startTime: start,
      endTime: end,
      activePreset: preset,
    );
  }

  /// 重置所有选择
  void reset() {
    state = const AnalysisControlState();
  }
}

/// 控制状态 Provider
final analysisControllerProvider =
    StateNotifierProvider<AnalysisControllerNotifier, AnalysisControlState>(
  (ref) => AnalysisControllerNotifier(),
);
