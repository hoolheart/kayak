import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';

/// 快捷操作卡片组件。
///
/// 每张卡片包含图标 + 标题 + 副标题，整张卡片可点击导航。
/// 交互状态：
/// - Hover: elevation 提升, 边框色变为 Primary at 30%
/// - Pressed: Scale 0.98
/// - Focus: 2px Primary outline
class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.compact = false,
  });

  /// 卡片图标（Icons 类型）
  final IconData icon;

  /// 卡片标题
  final String title;

  /// 卡片副标题
  final String subtitle;

  /// 点击回调
  final VoidCallback onTap;

  /// 紧凑模式（移动端使用）
  final bool compact;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 根据 compact 决定尺寸
    final double iconSize;
    final double iconContainerSize;
    final double padding;
    if (widget.compact) {
      iconSize = 24.0;
      iconContainerSize = 40.0;
      padding = 16.0;
    } else {
      iconSize = 28.0;
      iconContainerSize = 48.0;
      padding = 24.0;
    }

    final transformMatrix = _isHovered
        ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
        : Matrix4.identity();

    return Semantics(
      label:
          '${widget.title}, ${widget.subtitle}, ${AppLocalizations.of(context)!.viewAll}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Focus(
            onFocusChange: (focused) {
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              transform: transformMatrix,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered
                      ? colorScheme.primary.withAlpha(77)
                      : colorScheme.outlineVariant,
                ),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container
                        Container(
                          width: iconContainerSize,
                          height: iconContainerSize,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.icon,
                            size: iconSize,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Expanded(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Subtitle
                        Expanded(
                          child: Text(
                            widget.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
