/// 试验列表状态模型
///
/// 管理试验列表页面的状态
library;

import '../models/experiment.dart';

/// 试验列表状态
class ExperimentListState {
  final List<Experiment> experiments;
  final int page;
  final int size;
  final int total;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasNext;
  final bool hasPrev;
  final ExperimentStatus? statusFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final String? error;

  const ExperimentListState({
    this.experiments = const [],
    this.page = 1,
    this.size = 10,
    this.total = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasNext = false,
    this.hasPrev = false,
    this.statusFilter,
    this.startDateFilter,
    this.endDateFilter,
    this.error,
  });

  ExperimentListState copyWith({
    List<Experiment>? experiments,
    int? page,
    int? size,
    int? total,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasNext,
    bool? hasPrev,
    ExperimentStatus? statusFilter,
    DateTime? startDateFilter,
    DateTime? endDateFilter,
    String? error,
    bool clearStatusFilter = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearError = false,
  }) {
    return ExperimentListState(
      experiments: experiments ?? this.experiments,
      page: page ?? this.page,
      size: size ?? this.size,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      startDateFilter:
          clearStartDate ? null : (startDateFilter ?? this.startDateFilter),
      endDateFilter:
          clearEndDate ? null : (endDateFilter ?? this.endDateFilter),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
