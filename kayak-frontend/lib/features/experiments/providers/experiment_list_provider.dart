/// 试验列表Provider
///
/// 管理试验列表的状态
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experiment.dart';
import '../models/experiment_list_state.dart';
import '../services/experiment_service.dart';

/// 试验列表Notifier
class ExperimentListNotifier extends StateNotifier<ExperimentListState> {
  final ExperimentServiceInterface _service;

  ExperimentListNotifier(this._service) : super(const ExperimentListState());

  /// 加载试验列表
  Future<void> loadExperiments({bool reset = false}) async {
    if (state.isLoading) return;

    final targetPage = reset ? 1 : state.currentPage;

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: reset ? 1 : null,
    );

    try {
      final response = await _service.getExperiments(
        page: targetPage,
        size: state.pageSize,
        status: state.statusFilter,
        startedAfter: state.startDateFilter,
        startedBefore: state.endDateFilter,
      );

      state = state.copyWith(
        experiments:
            reset ? response.items : [...state.experiments, ...response.items],
        currentPage: response.page,
        total: response.total,
        hasMore: response.hasNext,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 刷新试验列表
  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final response = await _service.getExperiments(
        page: 1,
        size: state.pageSize,
        status: state.statusFilter,
        startedAfter: state.startDateFilter,
        startedBefore: state.endDateFilter,
      );

      state = state.copyWith(
        experiments: response.items,
        currentPage: response.page,
        total: response.total,
        hasMore: response.hasNext,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(currentPage: state.currentPage + 1);
    await loadExperiments();
  }

  /// 设置状态筛选
  void setStatusFilter(ExperimentStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
  }

  /// 清除状态筛选
  void clearStatusFilter() {
    state = state.copyWith(clearStatusFilter: true);
  }

  /// 设置日期范围筛选 (别名: setDateRangeFilter)
  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDateFilter: start,
      endDateFilter: end,
      clearStartDate: start == null,
      clearEndDate: end == null,
    );
  }

  /// 设置日期范围筛选 (API兼容名称)
  void setDateRangeFilter(DateTime? start, DateTime? end) {
    setDateRange(start, end);
  }

  /// 清除日期范围筛选
  void clearDateRangeFilter() {
    setDateRange(null, null);
  }

  /// 清除所有筛选
  void clearFilters() {
    state = state.copyWith(
      clearStatusFilter: true,
      clearStartDate: true,
      clearEndDate: true,
    );
  }

  /// 清除所有筛选 (别名)
  void clearAllFilters() {
    clearFilters();
  }

  /// 重置分页
  void resetPagination() {
    state = state.copyWith(currentPage: 1);
  }
}

/// Provider for ExperimentListNotifier
final experimentListProvider =
    StateNotifierProvider<ExperimentListNotifier, ExperimentListState>((ref) {
  final service = ref.watch(experimentServiceProvider);
  return ExperimentListNotifier(service);
});
