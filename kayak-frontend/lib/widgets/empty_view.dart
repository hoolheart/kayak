import 'package:flutter/material.dart';

/// 空状态视图组件。
///
/// 用于数据为空、列表无结果、首次使用无内容时的占位展示。
/// 通过友好的视觉和明确的引导，帮助用户理解当前状态并知晓下一步操作。
///
/// 用法：
/// ```dart
/// EmptyView(
///   title: '暂无工作台',
///   description: '点击下方的按钮创建您的第一个工作台',
///   actionButton: ElevatedButton(
///     onPressed: () => context.push('/workbenches/new'),
///     child: const Text('创建工作台'),
///   ),
/// )
/// ```
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.description,
    this.actionButton,
    this.icon,
    this.compact = false,
  });

  /// 空状态标题。
  final String title;

  /// 补充说明，可选。
  final String? description;

  /// 操作按钮，为 null 时不显示。
  final Widget? actionButton;

  /// 自定义图标，默认为 [Icons.folder_open_outlined]。
  final IconData? icon;

  /// 紧凑型模式，用于小区域。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final iconSize = compact
        ? 40.0
        : screenWidth < 600
            ? 40.0
            : 48.0;
    final padding = compact ? 16.0 : (screenWidth < 600 ? 24.0 : 32.0);
    final minHeight = compact ? 120.0 : (screenWidth < 600 ? 160.0 : 200.0);

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
              icon ?? Icons.folder_open_outlined,
              size: iconSize,
              color: colorScheme.onSurfaceVariant.withAlpha(153), // 60%
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
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}
