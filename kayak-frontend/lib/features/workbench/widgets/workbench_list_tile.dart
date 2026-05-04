/// 工作台列表项组件（列表视图）
///
/// Figma规格：56px 高度, 交替背景, 1px OutlineVariant 底边框
/// 列：图标(48) | 名称(200) | 描述(240) | 设备数(80) | 状态(100) | 时间(100) | 操作(80)

library;

import 'package:flutter/material.dart';

import '../../../core/theme/color_schemes.dart';
import '../models/workbench.dart';

/// 工作台列表项组件
class WorkbenchListTile extends StatelessWidget {
  const WorkbenchListTile({
    super.key,
    required this.workbench,
    this.deviceCount = 0,
    this.index = 0,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  final Workbench workbench;
  final int deviceCount;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isEven = index.isEven;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:
              isEven ? colorScheme.surface : colorScheme.surfaceContainerLowest,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            // 图标 (48px)
            SizedBox(
              width: 48,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.workspace_premium,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            // 名称 (200px)
            SizedBox(
              width: 200,
              child: Text(
                workbench.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 描述 (240px)
            SizedBox(
              width: 240,
              child: Text(
                workbench.description ?? '无描述',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: workbench.description != null
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: workbench.description == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 设备数 (80px)
            SizedBox(
              width: 80,
              child: Text(
                '$deviceCount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // 状态 (100px)
            SizedBox(
              width: 100,
              child: _buildStatusChip(colorScheme, theme),
            ),
            // 创建时间 (100px)
            SizedBox(
              width: 100,
              child: Text(
                _formatDate(workbench.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // 操作 (80px)
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outlined,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ColorScheme colorScheme, ThemeData theme) {
    String statusText;
    Color bgColor;
    Color fgColor;

    switch (workbench.status.toLowerCase()) {
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
        statusText = workbench.status;
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
