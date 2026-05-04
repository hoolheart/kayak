/// 测点配置列表项组件
///
/// 显示单个已配置测点的摘要信息，支持编辑和删除操作。
library;

import 'package:flutter/material.dart';
import '../../models/modbus_point_config.dart';

/// 测点配置列表项组件
class PointConfigListItem extends StatelessWidget {
  const PointConfigListItem({
    super.key,
    required this.config,
    required this.index,
    this.onEdit,
    this.onDelete,
  });

  /// 配置数据
  final ModbusPointConfig config;

  /// 列表中的序号
  final int index;

  /// 编辑回调
  final VoidCallback? onEdit;

  /// 删除回调
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: Key('point-config-item-${config.address}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：序号 + 功能码 + 操作按钮
            Row(
              children: [
                // 序号
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 功能码标签
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getFunctionCodeColor(config.functionCode, theme),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FC${config.functionCode.code.toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 功能码描述
                Expanded(
                  child: Text(
                    config.functionCode.label,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 操作按钮
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: '编辑',
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon:
                        Icon(Icons.delete, size: 20, color: colorScheme.error),
                    tooltip: '删除',
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 第二行：地址、数量、数据类型、缩放/偏移
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildInfoChip(context, '地址', '${config.address}'),
                _buildInfoChip(context, '数量', '${config.quantity}'),
                _buildInfoChip(context, '类型', config.dataType.value),
                _buildInfoChip(
                  context,
                  '缩放/偏移',
                  '×${config.scale} + ${config.offset}',
                ),
                // 地址范围信息
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '寄存器 [${config.addressRange.$1}-${config.addressRange.$2}]',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 信息标签
  Widget _buildInfoChip(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 根据功能码获取颜色
  Color _getFunctionCodeColor(ModbusFunctionCode fc, ThemeData theme) {
    switch (fc) {
      case ModbusFunctionCode.fc01:
        return Colors.orange;
      case ModbusFunctionCode.fc02:
        return Colors.blue;
      case ModbusFunctionCode.fc03:
        return Colors.green;
      case ModbusFunctionCode.fc04:
        return Colors.purple;
    }
  }
}
