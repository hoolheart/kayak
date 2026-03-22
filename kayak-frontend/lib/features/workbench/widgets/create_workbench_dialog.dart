/// 创建/编辑工作台对话框
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workbench.dart';
import '../models/workbench_form_state.dart';
import '../providers/workbench_form_provider.dart';

/// 创建/编辑工作台对话框
class CreateWorkbenchDialog extends ConsumerStatefulWidget {
  final Workbench? workbench;

  const CreateWorkbenchDialog({
    super.key,
    this.workbench,
  });

  @override
  ConsumerState<CreateWorkbenchDialog> createState() =>
      _CreateWorkbenchDialogState();
}

class _CreateWorkbenchDialogState extends ConsumerState<CreateWorkbenchDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workbench?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.workbench?.description ?? '');

    // 初始化编辑模式
    if (widget.workbench != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(workbenchFormProvider.notifier).initForEdit(widget.workbench!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(workbenchFormProvider);
    final isEditing = widget.workbench != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑工作台' : '创建工作台'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '名称',
                hintText: '请输入工作台名称',
                errorText: formState.nameError,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (value) {
                ref.read(workbenchFormProvider.notifier).updateName(value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '描述（可选）',
                hintText: '请输入工作台描述',
                errorText: formState.descriptionError,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                ref
                    .read(workbenchFormProvider.notifier)
                    .updateDescription(value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              formState.isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: formState.isSubmitting
              ? null
              : () async {
                  final success =
                      await ref.read(workbenchFormProvider.notifier).submit();
                  if (success && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
          child: formState.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? '保存' : '创建'),
        ),
      ],
    );
  }
}

/// 显示创建工作台对话框
Future<bool?> showCreateWorkbenchDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const CreateWorkbenchDialog(),
  );
}

/// 显示编辑工作台对话框
Future<bool?> showEditWorkbenchDialog(
  BuildContext context,
  Workbench workbench,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => CreateWorkbenchDialog(workbench: workbench),
  );
}
