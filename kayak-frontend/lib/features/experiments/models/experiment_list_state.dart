/// 试验列表状态模型
///
/// 管理试验列表页面的状态
library;

import '../models/experiment.dart';

/// 试验列表状态
class ExperimentListState {
  const ExperimentListState({
    this.experiments = const [],
    this.currentPage = 1,
    this.pageSize = 20,
    this.total = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.statusFilter,
    this.startDateFilter,
    this.endDateFilter,
    this.error,
  });
  final List<Experiment> experiments;
  final int currentPage;
  final int pageSize;
  final int total;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final ExperimentStatus? statusFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final String? error;

  ExperimentListState copyWith({
    List<Experiment>? experiments,
    int? currentPage,
    int? pageSize,
    int? total,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
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
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
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
