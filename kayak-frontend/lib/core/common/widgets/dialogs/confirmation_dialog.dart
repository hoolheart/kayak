/// Confirmation dialog components
library;

import 'package:flutter/material.dart';

/// Confirmation dialog with customizable buttons
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = '确认',
    this.cancelLabel = '取消',
    this.isDangerous = false,
    this.icon,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;
  final IconData? icon;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    bool isDangerous = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: icon != null
          ? Icon(
              icon,
              size: 48,
              color: isDangerous ? colorScheme.error : colorScheme.primary,
            )
          : isDangerous
              ? Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: colorScheme.error,
                )
              : null,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDangerous
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Delete confirmation dialog (convenience method)
class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.itemName,
  });
  final String itemName;

  static Future<bool?> show(
    BuildContext context, {
    required String itemName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(itemName: itemName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: '确认删除',
      message: '确定要删除 "$itemName" 吗？此操作无法撤销。',
      confirmLabel: '删除',
      isDangerous: true,
      icon: Icons.delete_outline,
    );
  }
}
