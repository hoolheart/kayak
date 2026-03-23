/// 测点列表项组件
///
/// 显示单个测点的信息和值
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/point.dart';
import '../../providers/point_value_provider.dart';
import 'point_value_display.dart';

/// 测点列表项组件
class PointListItem extends ConsumerWidget {
  final Point point;

  const PointListItem({
    super.key,
    required this.point,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointValueState = ref.watch(pointValueProvider(point.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 测点名称
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    key: Key('point-name-${point.id}'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTypeBadge(context, point.dataType),
                      const SizedBox(width: 4),
                      _buildAccessBadge(context, point.accessType),
                    ],
                  ),
                ],
              ),
            ),

            // 单位
            if (point.unit != null)
              Expanded(
                child: Text(
                  point.unit!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            // 测点值
            Expanded(
              flex: 2,
              child: _buildValueDisplay(context, pointValueState),
            ),

            // 刷新按钮
            IconButton(
              key: const Key('refresh-points-button'),
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(pointValueProvider(point.id).notifier).refresh(),
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueDisplay(BuildContext context, PointValueState state) {
    if (state.isLoading && state.value == null) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (state.error != null && state.value == null) {
      return const Text(
        '--',
        style: TextStyle(color: Colors.red),
      );
    }

    if (state.value == null) {
      return const Text('--');
    }

    return PointValueDisplay(
      key: Key('point-value-${point.id}'),
      value: state.value!,
      dataType: point.dataType,
    );
  }

  Widget _buildTypeBadge(BuildContext context, DataType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.name,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  Widget _buildAccessBadge(BuildContext context, AccessType access) {
    String label;
    switch (access) {
      case AccessType.ro:
        label = 'RO';
      case AccessType.wo:
        label = 'WO';
      case AccessType.rw:
        label = 'RW';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
