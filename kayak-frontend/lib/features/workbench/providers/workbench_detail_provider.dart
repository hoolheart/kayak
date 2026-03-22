/// 工作台详情Provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workbench.dart';
import '../models/workbench_detail_state.dart';
import '../services/workbench_service.dart';

/// 工作台详情Notifier
class WorkbenchDetailNotifier extends StateNotifier<WorkbenchDetailState> {
  final WorkbenchServiceInterface _service;

  WorkbenchDetailNotifier(this._service) : super(const WorkbenchDetailState());

  /// 加载工作台详情
  Future<void> loadWorkbench(String workbenchId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final workbench = await _service.getWorkbench(workbenchId);
      state = state.copyWith(
        workbench: workbench,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 刷新工作台详情
  Future<void> refresh() async {
    if (state.workbench == null) return;

    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final workbench = await _service.getWorkbench(state.workbench!.id);
      state = state.copyWith(
        workbench: workbench,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider for WorkbenchDetailNotifier
final workbenchDetailProvider = StateNotifierProvider.family<
    WorkbenchDetailNotifier, WorkbenchDetailState, String>((ref, workbenchId) {
  final service = ref.watch(workbenchServiceProvider);
  final notifier = WorkbenchDetailNotifier(service);
  notifier.loadWorkbench(workbenchId);
  return notifier;
});
