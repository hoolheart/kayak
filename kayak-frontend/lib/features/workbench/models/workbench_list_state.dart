/// 工作台列表状态模型
///
/// 管理工作台列表页面的状态
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'workbench.dart';

part 'workbench_list_state.freezed.dart';

/// 工作台列表状态
@freezed
class WorkbenchListState with _$WorkbenchListState {
  const factory WorkbenchListState({
    @Default([]) List<Workbench> workbenches,
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    String? error,
    @Default(1) int currentPage,
    @Default(20) int pageSize,
    @Default(true) bool hasMore,
  }) = _WorkbenchListState;
}
