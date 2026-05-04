/// 错误横幅组件
///
/// 显示错误/警告消息，支持 type 参数区分错误和警告类型

library;

import 'package:flutter/material.dart';
import '../../../core/theme/color_schemes.dart';

/// 横幅类型枚举
enum BannerType {
  /// 错误类型 - ErrorContainer 背景
  error,

  /// 警告类型 - WarningContainer 背景
  warning,
}

/// 错误横幅组件
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.type = BannerType.error,
    this.onDismiss,
    this.onRetry,
  });
  final String message;
  final BannerType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color backgroundColor;
    final Color foregroundColor;
    final IconData icon;

    switch (type) {
      case BannerType.warning:
        backgroundColor = colorScheme.warningContainer;
        foregroundColor = colorScheme.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case BannerType.error:
        backgroundColor = colorScheme.errorContainer;
        foregroundColor = colorScheme.onErrorContainer;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foregroundColor, fontSize: 14),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text('重试', style: TextStyle(color: foregroundColor)),
            ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: foregroundColor),
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
