/// 工作台详情状态
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/workbench.dart';

part 'workbench_detail_state.freezed.dart';

/// 工作台详情状态
@freezed
class WorkbenchDetailState with _$WorkbenchDetailState {
  const factory WorkbenchDetailState({
    Workbench? workbench,
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    String? error,
  }) = _WorkbenchDetailState;
}
