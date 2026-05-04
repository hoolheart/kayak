/// 工作台详情Header组件
///
/// Figma规格：100%宽, SurfaceContainerLow 背景, 12px 圆角
/// 显示工作台 Icon(48×48) + 名称 + 描述 + 状态 Chip + 元数据

library;

import 'package:flutter/material.dart';

import '../../../../core/theme/color_schemes.dart';
import '../../models/workbench.dart';

/// 工作台详情Header组件
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.workbench,
    this.deviceCount = 0,
  });
  final Workbench workbench;
  final int deviceCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标 + 名称 + 状态
          Row(
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
                  Icons.workspace_premium,
                  size: 24,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              // 名称 + 描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workbench.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (workbench.description != null &&
                        workbench.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        workbench.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 状态 Chip
              _buildStatusChip(colorScheme, theme),
            ],
          ),
          const SizedBox(height: 12),
          // 元数据行：创建时间 + 设备数
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '创建于 ${_formatDate(workbench.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '·',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.memory,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$deviceCount 个设备',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (workbench.createdAt != workbench.updatedAt) ...[
                const SizedBox(width: 16),
                Text(
                  '·',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Text(
                  '最后修改 ${_formatDate(workbench.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
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
