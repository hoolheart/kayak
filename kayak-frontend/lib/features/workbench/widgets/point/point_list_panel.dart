/// 测点列表面板组件
///
/// 显示选中设备的所有测点
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/point.dart';
import '../../providers/device_tree_provider.dart';
import '../../providers/point_list_provider.dart';
import 'point_list_item.dart';

/// 测点列表面板组件
class PointListPanel extends ConsumerWidget {
  const PointListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDevice = ref.watch(selectedDeviceProvider);

    if (selectedDevice == null) {
      return const Center(
        child: Text('请选择设备以查看测点'),
      );
    }

    final pointListAsync = ref.watch(pointListProvider(selectedDevice.id));

    return pointListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorView(context, ref, error),
      data: (points) {
        if (points.isEmpty) {
          return _buildEmptyView(context);
        }

        return ListView.builder(
          itemCount: points.length,
          itemBuilder: (context, index) {
            final point = points[index];
            return PointListItem(
              key: Key('point-item-${point.id}'),
              point: point,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无测点'),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('加载失败: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final device = ref.read(selectedDeviceProvider);
              if (device != null) {
                ref.refresh(pointListProvider(device.id));
              }
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
