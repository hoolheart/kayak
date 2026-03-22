/// 工作台表单Provider
///
/// 管理工作台创建/编辑表单的状态
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workbench.dart';
import '../models/workbench_form_state.dart';
import '../services/workbench_service.dart';
import '../utils/workbench_validators.dart';
import 'workbench_list_provider.dart';

/// 工作台表单Notifier
class WorkbenchFormNotifier extends StateNotifier<WorkbenchFormState> {
  final WorkbenchServiceInterface _service;
  final Ref _ref;
  Workbench? _editingWorkbench;

  WorkbenchFormNotifier(this._service, this._ref)
      : super(const WorkbenchFormState());

  /// 初始化编辑模式
  void initForEdit(Workbench workbench) {
    _editingWorkbench = workbench;
    state = WorkbenchFormState(
      name: workbench.name,
      description: workbench.description ?? '',
    );
  }

  /// 重置表单
  void reset() {
    _editingWorkbench = null;
    state = const WorkbenchFormState();
  }

  /// 更新名称
  void updateName(String value) {
    state = state.copyWith(
      name: value,
      nameError: WorkbenchValidators.validateName(value),
    );
  }

  /// 更新描述
  void updateDescription(String value) {
    state = state.copyWith(
      description: value,
      descriptionError: WorkbenchValidators.validateDescription(value),
    );
  }

  /// 提交表单
  Future<bool> submit() async {
    // 验证
    final nameError = WorkbenchValidators.validateName(state.name);
    final descError =
        WorkbenchValidators.validateDescription(state.description);

    if (nameError != null || descError != null) {
      state = state.copyWith(
        nameError: nameError,
        descriptionError: descError,
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      if (_editingWorkbench != null) {
        // 更新
        final updated = await _service.updateWorkbench(
          _editingWorkbench!.id,
          state.name.trim(),
          state.description.trim().isEmpty ? null : state.description.trim(),
        );
        _ref.read(workbenchListProvider.notifier).updateWorkbench(updated);
      } else {
        // 创建
        final created = await _service.createWorkbench(
          state.name.trim(),
          state.description.trim().isEmpty ? null : state.description.trim(),
        );
        _ref.read(workbenchListProvider.notifier).addWorkbench(created);
      }

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

/// Provider for WorkbenchFormNotifier
final workbenchFormProvider = StateNotifierProvider.autoDispose<
    WorkbenchFormNotifier, WorkbenchFormState>((ref) {
  final service = ref.watch(workbenchServiceProvider);
  return WorkbenchFormNotifier(service, ref);
});
