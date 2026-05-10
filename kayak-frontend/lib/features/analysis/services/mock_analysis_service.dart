/// Mock 分析数据服务
///
/// 用于独立开发测试，生成正弦波和随机数据模拟后端 API 响应。
library;

import 'dart:math';

import '../models/chart_models.dart';

/// Mock 分析服务接口
abstract class AnalysisService {
  /// 查询时序数据
  Future<ChartDataResponse> queryData(DataQueryRequest request);
}

/// Mock 分析服务实现
class MockAnalysisService implements AnalysisService {
  MockAnalysisService({this.delay = const Duration(milliseconds: 800)});

  final Duration delay;
  final Random _random = Random(42);

  @override
  Future<ChartDataResponse> queryData(DataQueryRequest request) async {
    // 模拟网络延迟
    await Future.delayed(delay);

    final now = DateTime.now();
    final startTime = request.startTime ?? now.subtract(const Duration(hours: 1));
    final endTime = request.endTime ?? now;
    final pointCount = request.downsample.clamp(100, 10000);

    final points = <ChartPointSeries>[];

    for (int i = 0; i < request.pointIds.length; i++) {
      final pointId = request.pointIds[i];
      final series = _generateMockSeries(
        pointId: pointId,
        index: i,
        startTime: startTime,
        endTime: endTime,
        pointCount: pointCount,
      );
      points.add(series);
    }

    return ChartDataResponse(
      experimentId: request.experimentId,
      deviceId: request.deviceId,
      points: points,
      totalSamples: pointCount * request.pointIds.length,
      returnedSamples: pointCount * request.pointIds.length,
    );
  }

  ChartPointSeries _generateMockSeries({
    required String pointId,
    required int index,
    required DateTime startTime,
    required DateTime endTime,
    required int pointCount,
  }) {
    final timestamps = <int>[];
    final values = <double>[];
    final duration = endTime.difference(startTime);
    final intervalMs = duration.inMilliseconds ~/ pointCount;

    for (int i = 0; i < pointCount; i++) {
      final t = startTime.millisecondsSinceEpoch + i * intervalMs;
      timestamps.add(t);

      // 不同测点使用不同的波形
      double value;
      switch (index % 4) {
        case 0: // 正弦波
          value = 25.0 + 5.0 * sin(2 * pi * i / pointCount);
        case 1: // 余弦波
          value = 101325.0 + 1000.0 * cos(2 * pi * i / pointCount);
        case 2: // 高频正弦
          value = 50.0 + 20.0 * sin(2 * pi * i / (pointCount ~/ 2));
        case 3: // 随机噪声
          value = 2.0 + 1.5 * cos(2 * pi * i / (pointCount ~/ 4)) +
              (_random.nextDouble() - 0.5) * 0.5;
        default:
          value = 0.0;
      }
      values.add(value);
    }

    final names = ['Temperature', 'Pressure', 'Flow Rate', 'Vibration'];
    final units = ['°C', 'Pa', 'L/min', 'mm/s'];

    return ChartPointSeries(
      pointId: pointId,
      pointName: names[index % names.length],
      unit: units[index % units.length],
      dataType: 'float32',
      timestamps: timestamps,
      values: values,
    );
  }
}
