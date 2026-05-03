/// 快捷操作卡片组件
///
/// Figma规格：200×120px, 16px 圆角, Surface 背景, 1px OutlineVariant 边框
/// 悬停效果：边框变 Primary, 阴影提升, 上移 -2px

library;

import 'package:flutter/material.dart';

/// 快捷操作卡片数据
class QuickActionData {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const QuickActionData({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });
}

/// 快捷操作卡片组件
class QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          offset: _isHovering ? const Offset(0, -0.015) : Offset.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            width: 200,
            height: 120,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovering
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              boxShadow: _isHovering
                  ? [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标容器
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                // 标题
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // 描述
                Text(
                  widget.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
