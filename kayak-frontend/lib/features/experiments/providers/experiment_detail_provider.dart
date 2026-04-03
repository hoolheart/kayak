/// 试验详情Provider
///
/// 管理试验详情页面的状态
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experiment_detail_state.dart';
import '../services/experiment_service.dart';

/// 试验详情Notifier
class ExperimentDetailNotifier extends StateNotifier<ExperimentDetailState> {
  final ExperimentServiceInterface _service;

  ExperimentDetailNotifier(this._service)
      : super(const ExperimentDetailState());

  /// 加载试验详情
  Future<void> loadExperiment(String id) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final experiment = await _service.getExperiment(id);
      state = state.copyWith(
        experiment: experiment,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 加载测点历史数据
  Future<void> loadPointHistory(
    String experimentId,
    String channel, {
    bool reset = false,
  }) async {
    if (state.isLoadingHistory && !reset) return;

    final targetPage = reset ? 1 : state.historyPage;

    state = state.copyWith(
      isLoadingHistory: true,
      historyPage: reset ? 1 : null,
      clearHistoryError: true,
    );

    try {
      // Call the API to get point history
      // The API returns timestamps as nanoseconds since epoch
      // We need to handle this properly
      final queryParams = <String, dynamic>{
        'limit': 100, // Get 100 points at a time
      };

      if (targetPage > 1) {
        // For pagination, we use time-based approach
        if (state.pointHistory.isNotEmpty) {
          final lastPoint = state.pointHistory.last;
          queryParams['end_time'] = lastPoint.timestamp.toIso8601String();
        }
      }

      final response = await _service.getPointHistory(
        experimentId,
        channel,
        limit: 100,
        endTime: queryParams['end_time'] != null
            ? DateTime.parse(queryParams['end_time'] as String)
            : null,
      );

      final newData = response.data.map((point) {
        return PointHistoryData(
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(point.timestamp ~/ 1000000),
          value: point.value,
        );
      }).toList();

      state = state.copyWith(
        pointHistory: reset ? newData : [...state.pointHistory, ...newData],
        historyPage: targetPage + 1,
        hasMoreHistory: newData.length >= 100,
        isLoadingHistory: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        historyError: e.toString(),
      );
    }
  }

  /// 导出CSV
  Future<String> exportToCsv() async {
    if (state.experiment == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Value');

    for (final point in state.pointHistory) {
      buffer.writeln('${point.timestamp.toIso8601String()},${point.value}');
    }

    return buffer.toString();
  }
}

/// Provider for ExperimentDetailNotifier
final experimentDetailProvider =
    StateNotifierProvider<ExperimentDetailNotifier, ExperimentDetailState>(
        (ref) {
  final service = ref.watch(experimentServiceProvider);
  return ExperimentDetailNotifier(service);
});

/// Point history item (for API response)
class PointHistoryItem {
  final int timestamp; // nanoseconds since epoch
  final double value;

  const PointHistoryItem({
    required this.timestamp,
    required this.value,
  });

  factory PointHistoryItem.fromJson(Map<String, dynamic> json) {
    return PointHistoryItem(
      timestamp: json['timestamp'] as int,
      value: (json['value'] as num).toDouble(),
    );
  }
}

/// Point history response
class PointHistoryResponse {
  final String experimentId;
  final String channel;
  final List<PointHistoryItem> data;
  final DateTime? startTime;
  final DateTime? endTime;
  final int totalPoints;

  const PointHistoryResponse({
    required this.experimentId,
    required this.channel,
    required this.data,
    this.startTime,
    this.endTime,
    required this.totalPoints,
  });

  factory PointHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PointHistoryResponse(
      experimentId: json['experiment_id'] as String,
      channel: json['channel'] as String,
      data: (json['data'] as List)
          .map((e) => PointHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      totalPoints: json['total_points'] as int,
    );
  }
}
