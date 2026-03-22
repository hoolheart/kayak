/// 设备列表Tab内容
///
/// 这里是占位符内容，S1-019将实现完整的设备树功能
library;

import 'package:flutter/material.dart';

/// 设备列表Tab内容组件
///
/// 显示占位符内容，提示用户此功能即将到来
class DeviceListTab extends StatelessWidget {
  const DeviceListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '设备管理功能开发中',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '设备列表将在S1-019中实现',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
