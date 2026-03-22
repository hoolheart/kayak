/// 工作台表单状态模型
///
/// 管理工作台创建/编辑表单的状态
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'workbench_form_state.freezed.dart';

/// 工作台表单状态
@freezed
class WorkbenchFormState with _$WorkbenchFormState {
  const factory WorkbenchFormState({
    @Default('') String name,
    @Default('') String description,
    String? nameError,
    String? descriptionError,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _WorkbenchFormState;

  const WorkbenchFormState._();

  /// 表单是否有效
  bool get isValid =>
      nameError == null && descriptionError == null && name.trim().isNotEmpty;
}

/// 视图模式枚举
enum ViewMode {
  card,
  list,
}
