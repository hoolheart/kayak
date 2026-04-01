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

    final targetPage = reset ? 1 : state.page;

    state = state.copyWith(
      isLoading: true,
      error: null,
      page: reset ? 1 : null,
    );

    try {
      final response = await _service.getExperiments(
        page: targetPage,
        size: state.size,
        status: state.statusFilter,
        startedAfter: state.startDateFilter,
        startedBefore: state.endDateFilter,
      );

      state = state.copyWith(
        experiments:
            reset ? response.items : [...state.experiments, ...response.items],
        page: response.page,
        total: response.total,
        hasNext: response.hasNext,
        hasPrev: response.hasPrev,
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
        size: state.size,
        status: state.statusFilter,
        startedAfter: state.startDateFilter,
        startedBefore: state.endDateFilter,
      );

      state = state.copyWith(
        experiments: response.items,
        page: response.page,
        total: response.total,
        hasNext: response.hasNext,
        hasPrev: response.hasPrev,
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
    if (state.isLoading || !state.hasNext) return;

    state = state.copyWith(page: state.page + 1);
    await loadExperiments();
  }

  /// 设置状态筛选
  void setStatusFilter(ExperimentStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
  }

  /// 设置日期范围筛选
  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDateFilter: start,
      endDateFilter: end,
      clearStartDate: start == null,
      clearEndDate: end == null,
    );
  }

  /// 清除所有筛选
  void clearFilters() {
    state = state.copyWith(
      clearStatusFilter: true,
      clearStartDate: true,
      clearEndDate: true,
    );
  }

  /// 重置分页
  void resetPagination() {
    state = state.copyWith(page: 1);
  }
}

/// Provider for ExperimentListNotifier
final experimentListProvider =
    StateNotifierProvider<ExperimentListNotifier, ExperimentListState>((ref) {
  final service = ref.watch(experimentServiceProvider);
  return ExperimentListNotifier(service);
});
