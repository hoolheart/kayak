/// 试验详情状态模型
///
/// 管理试验详情页面的状态
library;

import '../models/experiment.dart';

/// 试验详情状态
class ExperimentDetailState {
  final Experiment? experiment;
  final List<PointHistoryData> pointHistory;
  final bool isLoading;
  final bool isLoadingHistory;
  final String? error;
  final String? historyError;
  final int historyPage;
  final bool hasMoreHistory;

  const ExperimentDetailState({
    this.experiment,
    this.pointHistory = const [],
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.error,
    this.historyError,
    this.historyPage = 1,
    this.hasMoreHistory = false,
  });

  ExperimentDetailState copyWith({
    Experiment? experiment,
    List<PointHistoryData>? pointHistory,
    bool? isLoading,
    bool? isLoadingHistory,
    String? error,
    String? historyError,
    int? historyPage,
    bool? hasMoreHistory,
    bool clearError = false,
    bool clearHistoryError = false,
  }) {
    return ExperimentDetailState(
      experiment: experiment ?? this.experiment,
      pointHistory: pointHistory ?? this.pointHistory,
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: clearError ? null : (error ?? this.error),
      historyError:
          clearHistoryError ? null : (historyError ?? this.historyError),
      historyPage: historyPage ?? this.historyPage,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
    );
  }
}

/// 时序数据点
class PointHistoryData {
  final DateTime timestamp;
  final double value;

  const PointHistoryData({
    required this.timestamp,
    required this.value,
  });
}
