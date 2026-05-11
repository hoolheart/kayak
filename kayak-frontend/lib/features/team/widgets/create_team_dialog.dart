/// Create team dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/team_providers.dart';

/// Create team dialog
class CreateTeamDialog extends ConsumerStatefulWidget {
  const CreateTeamDialog({super.key});

  @override
  ConsumerState<CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends ConsumerState<CreateTeamDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建团队'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '团队名称',
                  hintText: '请输入团队名称',
                  prefixIcon: Icon(Icons.groups),
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '团队名称不能为空';
                  }
                  if (value.length > 255) {
                    return '团队名称不能超过 255 个字符';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  hintText: '请输入团队描述',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                enabled: !_isSubmitting,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final team = await ref.read(teamActionsProvider.notifier).createTeam(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

    if (mounted) {
      if (team != null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSubmitting = false);
        final error = ref.read(teamActionsProvider).error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $error')),
          );
        }
      }
    }
  }
}

/// Show create team dialog
Future<bool?> showCreateTeamDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const CreateTeamDialog(),
  );
}
