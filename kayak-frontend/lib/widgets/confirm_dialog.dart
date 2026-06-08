import 'package:flutter/material.dart';

import 'package:kayak_frontend/generated/app_localizations.dart';

/// 确认对话框组件。
///
/// 用于需要用户二次确认的操作，防止误操作导致不可逆后果。
/// 支持普通确认和危险操作确认，响应式适配移动端底部 Sheet。
///
/// 用法：
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context: context,
///   title: '删除工作台？',
///   description: '此操作将永久删除该工作台及其所有数据。',
///   onConfirm: () => _deleteWorkbench(id),
///   isDanger: true,
/// );
/// ```
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    this.description,
    required this.onConfirm,
    this.onCancel,
    this.confirmLabel,
    this.cancelLabel,
    this.isDanger = false,
    this.dismissible = true,
    this.isMobile = false,
  });

  /// 对话框标题。
  final String title;

  /// 描述文本，可选。
  final String? description;

  /// 确认回调。
  final VoidCallback onConfirm;

  /// 取消回调，可选。
  final VoidCallback? onCancel;

  /// 确认按钮标签，默认使用 l10n 的 confirm。
  final String? confirmLabel;

  /// 取消按钮标签，默认使用 l10n 的 cancel。
  final String? cancelLabel;

  /// 是否为危险操作（确认按钮显示为 Error 色）。
  final bool isDanger;

  /// 是否点击遮罩层可关闭，默认为 true。
  final bool dismissible;

  /// 是否为移动端布局。
  final bool isMobile;

  /// 显示确认对话框。
  ///
  /// 根据屏幕宽度自动选择样式：
  /// - < 600px：底部 Sheet
  /// - >= 600px：居中 Dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? description,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String? confirmLabel,
    String? cancelLabel,
    bool isDanger = false,
    bool dismissible = true,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return showModalBottomSheet(
        context: context,
        isDismissible: dismissible,
        enableDrag: dismissible,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (_) => ConfirmDialog(
          title: title,
          description: description,
          onConfirm: onConfirm,
          onCancel: onCancel,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          isDanger: isDanger,
          dismissible: dismissible,
          isMobile: true,
        ),
      );
    }

    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (_) => ConfirmDialog(
        title: title,
        description: description,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        dismissible: dismissible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localizations = AppLocalizations.of(context)!;
    final confirmText = confirmLabel ??
        (isDanger ? localizations.delete : localizations.confirm);
    final cancelText = cancelLabel ?? localizations.cancel;

    final horizontalPadding = isMobile ? 24.0 : 32.0;
    final dialogContent = Padding(
      padding: EdgeInsets.only(
        top: 32,
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDanger)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Align(
            alignment: isMobile ? Alignment.center : Alignment.centerRight,
            child: isMobile
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: () {
                          onConfirm();
                          Navigator.of(context).pop();
                        },
                        style: isDanger
                            ? FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                              )
                            : null,
                        child: Text(confirmText),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          onCancel?.call();
                          Navigator.of(context).pop();
                        },
                        child: Text(cancelText),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          onCancel?.call();
                          Navigator.of(context).pop();
                        },
                        child: Text(cancelText),
                      ),
                      FilledButton(
                        onPressed: () {
                          onConfirm();
                          Navigator.of(context).pop();
                        },
                        style: isDanger
                            ? FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                              )
                            : null,
                        child: Text(confirmText),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return dialogContent;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      content: SizedBox(
        width: 360,
        child: dialogContent,
      ),
    );
  }
}
