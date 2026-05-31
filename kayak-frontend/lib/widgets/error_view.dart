import 'package:flutter/material.dart';

import 'package:kayak_frontend/generated/app_localizations.dart';

/// 错误视图组件。
///
/// 用于数据加载失败、网络请求失败、操作异常时的占位展示。
/// 统一所有错误状态的视觉表现，提供明确的恢复路径。
///
/// 用法：
/// ```dart
/// ErrorView(
///   title: '无法加载数据',
///   description: '网络连接异常，请检查网络后点击重试',
///   onRetry: () => ref.invalidate(workspacesProvider),
/// )
/// ```
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    this.description,
    this.onRetry,
    this.isLoading = false,
    this.showRetry = true,
    this.compact = false,
  });

  /// 错误标题。
  final String title;

  /// 错误描述，可选。
  final String? description;

  /// 重试回调，为 null 时不显示重试按钮。
  final VoidCallback? onRetry;

  /// 是否处于加载状态（按钮显示 loading 指示器）。
  final bool isLoading;

  /// 是否显示重试按钮，默认为 true。
  final bool showRetry;

  /// 紧凑型模式，用于卡片内部或小区域。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final localizations = AppLocalizations.of(context)!;

    final iconSize = compact
        ? 32.0
        : screenWidth < 600
            ? 40.0
            : 48.0;
    final padding = compact ? 16.0 : (screenWidth < 600 ? 24.0 : 32.0);
    final minHeight = compact ? 120.0 : (screenWidth < 600 ? 160.0 : 240.0);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight,
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_outlined,
              size: iconSize,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 24),
              _RetryButton(
                isLoading: isLoading,
                onRetry: onRetry!,
                label: localizations.retry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 重试按钮组件。
class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.isLoading,
    required this.onRetry,
    required this.label,
  });

  final bool isLoading;
  final VoidCallback onRetry;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 120,
      height: 40,
      child: FilledButton(
        onPressed: isLoading ? null : onRetry,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                label,
                style: textTheme.labelLarge,
              ),
      ),
    );
  }
}
