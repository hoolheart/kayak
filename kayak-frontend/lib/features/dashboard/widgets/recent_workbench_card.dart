/// 最近工作台卡片
///
/// Figma规格：自适应宽(≥260px)×140px, 12px 圆角, Surface 背景
/// 显示工作台图标、名称、设备数和状态 Chip

library;

import 'package:flutter/material.dart';

import '../../../core/theme/color_schemes.dart';
import '../../workbench/models/workbench.dart';

/// 最近工作台卡片组件
class RecentWorkbenchCard extends StatefulWidget {
  const RecentWorkbenchCard({
    super.key,
    required this.workbench,
    this.deviceCount = 0,
    required this.onTap,
  });
  final Workbench workbench;
  final int deviceCount;
  final VoidCallback onTap;

  @override
  State<RecentWorkbenchCard> createState() => _RecentWorkbenchCardState();
}

class _RecentWorkbenchCardState extends State<RecentWorkbenchCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          height: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
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
              Row(
                children: [
                  // 图标容器
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 名称和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workbench.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.deviceCount} 个设备',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 底部状态 Chip
              _StatusChip(status: widget.workbench.status),
            ],
          ),
        ),
      ),
    );
  }
}

/// 状态 Chip 组件
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color chipBg;
    Color chipFg;

    switch (status.toLowerCase()) {
      case 'active':
        chipBg = colorScheme.successContainer;
        chipFg = colorScheme.success;
        break;
      case 'archived':
        chipBg = colorScheme.surfaceContainerHighest;
        chipFg = colorScheme.onSurfaceVariant;
        break;
      default:
        chipBg = colorScheme.surfaceContainerHighest;
        chipFg = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status == 'active' ? '活跃' : status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipFg,
            ),
      ),
    );
  }
}
