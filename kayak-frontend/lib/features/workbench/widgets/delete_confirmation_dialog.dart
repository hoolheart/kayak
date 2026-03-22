/// 删除确认对话框
library;

import 'package:flutter/material.dart';

/// 删除确认对话框
class DeleteConfirmationDialog extends StatelessWidget {
  final String itemName;
  final String itemType;

  const DeleteConfirmationDialog({
    super.key,
    required this.itemName,
    this.itemType = '工作台',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.error,
        size: 48,
      ),
      title: Text('删除 $itemType'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '确定要删除 "$itemName" 吗？',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '此操作不可恢复，所有关联的设备和数据都将被删除。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    );
  }
}

/// 显示删除确认对话框
Future<bool?> showDeleteConfirmationDialog(
  BuildContext context, {
  required String itemName,
  String itemType = '工作台',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DeleteConfirmationDialog(
      itemName: itemName,
      itemType: itemType,
    ),
  );
}
