/// Dashboard 空状态组件
///
/// 当用户没有任何工作台时显示

library;

import 'package:flutter/material.dart';

/// Dashboard 空状态组件
class EmptyWorkbenchesState extends StatelessWidget {
  final VoidCallback onCreateWorkbench;

  const EmptyWorkbenchesState({
    super.key,
    required this.onCreateWorkbench,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有工作台',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建第一个工作台开始管理您的设备',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreateWorkbench,
            icon: const Icon(Icons.add),
            label: const Text('创建工作台'),
          ),
        ],
      ),
    );
  }
}
