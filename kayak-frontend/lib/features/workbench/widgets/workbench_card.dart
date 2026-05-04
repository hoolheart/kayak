/// 工作台卡片组件（网格视图）
///
/// Figma规格：280×200px, 16px 圆角, Surface 背景, 1px OutlineVariant 边框
/// 悬停：边框变 Primary, 阴影 Elevation 2, translateY -2px

library;

import 'package:flutter/material.dart';

import '../../../core/theme/color_schemes.dart';
import '../models/workbench.dart';

/// 工作台卡片组件
class WorkbenchCard extends StatefulWidget {
  const WorkbenchCard({
    super.key,
    required this.workbench,
    this.deviceCount = 0,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  final Workbench workbench;
  final int deviceCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<WorkbenchCard> createState() => _WorkbenchCardState();
}

class _WorkbenchCardState extends State<WorkbenchCard> {
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
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          offset: _isHovering ? const Offset(0, -0.01) : Offset.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
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
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRow(colorScheme, theme),
                    const SizedBox(height: 12),
                    _buildDescription(colorScheme, theme),
                    _buildBottomRow(colorScheme, theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(ColorScheme colorScheme, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.workspace_premium,
            size: 28,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                widget.workbench.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          iconSize: 20,
          onSelected: (value) {
            if (value == 'edit') widget.onEdit();
            if (value == 'delete') widget.onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outlined,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(ColorScheme colorScheme, ThemeData theme) {
    return Expanded(
      child: Text(
        widget.workbench.description ?? '暂无描述',
        style: theme.textTheme.bodySmall?.copyWith(
          color: widget.workbench.description != null
              ? colorScheme.onSurfaceVariant
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontStyle: widget.workbench.description == null
              ? FontStyle.italic
              : FontStyle.normal,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBottomRow(ColorScheme colorScheme, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.memory,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.deviceCount} 设备',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        _buildStatusChip(colorScheme, theme),
      ],
    );
  }

  Widget _buildStatusChip(ColorScheme colorScheme, ThemeData theme) {
    String statusText;
    Color bgColor;
    Color fgColor;

    switch (widget.workbench.status.toLowerCase()) {
      case 'active':
        statusText = '活跃';
        bgColor = colorScheme.successContainer;
        fgColor = colorScheme.success;
        break;
      case 'archived':
        statusText = '归档';
        bgColor = colorScheme.surfaceContainerHighest;
        fgColor = colorScheme.onSurfaceVariant;
        break;
      default:
        statusText = widget.workbench.status;
        bgColor = colorScheme.surfaceContainerHighest;
        fgColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.labelSmall?.copyWith(color: fgColor),
      ),
    );
  }
}
