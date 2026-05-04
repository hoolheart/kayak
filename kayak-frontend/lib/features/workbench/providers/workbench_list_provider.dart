/// 工作台列表Provider
///
/// 管理工作台列表的状态
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workbench.dart';
import '../models/workbench_list_state.dart';
import '../services/workbench_service.dart';

/// 工作台列表Notifier
class WorkbenchListNotifier extends StateNotifier<WorkbenchListState> {
  WorkbenchListNotifier(this._service) : super(const WorkbenchListState());
  final WorkbenchServiceInterface _service;

  /// 加载工作台列表
  Future<void> loadWorkbenches() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getWorkbenches(
        size: state.pageSize,
      );

      state = state.copyWith(
        workbenches: response.items,
        isLoading: false,
        currentPage: response.page,
        hasMore: response.items.length < response.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 刷新工作台列表
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final response = await _service.getWorkbenches(
        size: state.pageSize,
      );

      state = state.copyWith(
        workbenches: response.items,
        isRefreshing: false,
        currentPage: response.page,
        hasMore: response.items.length < response.total,
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

    try {
      final response = await _service.getWorkbenches(
        page: state.currentPage + 1,
        size: state.pageSize,
      );

      state = state.copyWith(
        workbenches: [...state.workbenches, ...response.items],
        currentPage: response.page,
        hasMore: state.workbenches.length < response.total,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 添加工作台到列表
  void addWorkbench(Workbench workbench) {
    state = state.copyWith(
      workbenches: [workbench, ...state.workbenches],
    );
  }

  /// 更新列表中的工作台
  void updateWorkbench(Workbench workbench) {
    final updatedList = state.workbenches.map((w) {
      return w.id == workbench.id ? workbench : w;
    }).toList();

    state = state.copyWith(workbenches: updatedList);
  }

  /// 从列表中移除工作台
  void removeWorkbench(String id) {
    state = state.copyWith(
      workbenches: state.workbenches.where((w) => w.id != id).toList(),
    );
  }
}

/// Provider for WorkbenchListNotifier
final workbenchListProvider =
    StateNotifierProvider<WorkbenchListNotifier, WorkbenchListState>((ref) {
  final service = ref.watch(workbenchServiceProvider);
  return WorkbenchListNotifier(service);
});
