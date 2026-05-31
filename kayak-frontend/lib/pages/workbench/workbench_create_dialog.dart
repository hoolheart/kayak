import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/app_localizations.dart';
import '../../models/workbench.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services.dart';
import '../../providers/workbench_provider.dart';
import '../../widgets/toast.dart';

// ============================================================
// WorkbenchFormDialog — 创建工作台/编辑工作台 对话框
//
// 支持创建和编辑两种模式。响应式适配：
// - 桌面：居中 Dialog，宽度 480px
// - 移动端：BottomSheet，宽度 100%
// ============================================================

class WorkbenchFormDialog extends StatefulWidget {
  const WorkbenchFormDialog({
    super.key,
    required this.ref,
    required this.title,
    required this.submitLabel,
    required this.isEdit,
    this.workbench,
  });

  /// 父组件的 ref（用于读取 provider）
  final WidgetRef ref;

  /// 对话框标题
  final String title;

  /// 提交按钮标签（"创建" 或 "保存"）
  final String submitLabel;

  /// 是否为编辑模式
  final bool isEdit;

  /// 编辑模式时的工作台数据
  final Workbench? workbench;

  /// 显示对话框
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String submitLabel,
    required bool isEdit,
    Workbench? workbench,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // 移动端：BottomSheet
      return showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (_) => WorkbenchFormDialog(
          ref: ref,
          title: title,
          submitLabel: submitLabel,
          isEdit: isEdit,
          workbench: workbench,
        ),
      );
    }

    // 桌面端：居中 Dialog
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 480,
          child: WorkbenchFormDialog(
            ref: ref,
            title: title,
            submitLabel: submitLabel,
            isEdit: isEdit,
            workbench: workbench,
          ),
        ),
      ),
    );
  }

  @override
  State<WorkbenchFormDialog> createState() => _WorkbenchFormDialogState();
}

class _WorkbenchFormDialogState extends State<WorkbenchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 编辑模式：预填现有值
    if (widget.isEdit && widget.workbench != null) {
      _nameController.text = widget.workbench!.name;
      _descriptionController.text = widget.workbench!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 提交表单
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context)!;
    final authState = widget.ref.read(authProvider);

    try {
      if (widget.isEdit) {
        // 编辑模式
        final workbench = widget.workbench!;
        final service = widget.ref.read(workbenchServiceProvider);
        await service.update(workbench.id, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        });

        if (!mounted) return;
        // 刷新详情页数据（确保编辑后详情页显示最新数据）
        widget.ref.invalidate(workbenchDetailProvider(workbench.id));
        // 刷新列表
        widget.ref.read(workbenchListProvider.notifier).refresh();
        Toast.show(
          context: context,
          message: l10n.updateWorkbenchSuccess,
          type: ToastType.success,
        );
        Navigator.of(context).pop();
      } else {
        // 创建模式
        final user = authState.asData?.value;
        await widget.ref
            .read(workbenchListProvider.notifier)
            .createWorkbench(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              ownerType: 'user',
              ownerId: user?.id ?? 'unknown',
            );

        if (!mounted) return;

        // 检查创建结果
        final currentState = widget.ref.read(workbenchListProvider);
        if (currentState is AsyncData) {
          Toast.show(
            context: context,
            message: l10n.createWorkbenchSuccess,
            type: ToastType.success,
          );
          Navigator.of(context).pop();
        } else {
          // 创建失败（状态为 AsyncError）
          setState(() => _isSubmitting = false);
          final error =
              currentState is AsyncError ? currentState.error : null;
          Toast.show(
            context: context,
            message: error?.toString() ?? l10n.networkError,
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Toast.show(
        context: context,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final horizontalPadding = isMobile ? 24.0 : 32.0;

    return Padding(
      padding: EdgeInsets.only(
        top: 32,
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (!isMobile)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    tooltip: l10n.cancel,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // 名称字段
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.workbenchName,
                hintText: l10n.workbenchNameHint,
              ),
              maxLength: 255,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.workbenchNameRequired;
                }
                if (value.length > 255) {
                  return l10n.workbenchNameMaxLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 描述字段
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.workbenchDescription,
                hintText: l10n.workbenchDescriptionHint,
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 1000,
              buildCounter: (context,
                  {required currentLength,
                  required isFocused,
                  maxLength}) {
                return null; // 不显示字数统计
              },
            ),
            const SizedBox(height: 32),
            // 操作按钮
            Align(
              alignment:
                  isMobile ? Alignment.center : Alignment.centerRight,
              child: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(widget.submitLabel),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(widget.submitLabel),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
