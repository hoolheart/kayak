/// 设备树组件
///
/// 显示设备列表的树形结构
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/device.dart';
import '../../providers/device_tree_provider.dart';
import '../../services/device_service.dart';
import '../device/device_form_dialog.dart';
import 'device_tree_node.dart';

/// 设备树组件
class DeviceTree extends ConsumerWidget {
  final String workbenchId;

  const DeviceTree({
    super.key,
    required this.workbenchId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceTreeProvider(workbenchId));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorView(context, ref, state.error!);
    }

    if (state.nodes.isEmpty) {
      return _buildEmptyView(context);
    }

    return ListView.builder(
      key: const Key('device-tree'),
      itemCount: state.nodes.length,
      itemBuilder: (context, index) {
        final node = state.nodes[index];
        return DeviceTreeNodeWidget(
          key: Key('device-node-${node.device.id}'),
          node: node,
          onTap: () =>
              ref.read(selectedDeviceProvider.notifier).state = node.device,
          onExpand: () => ref
              .read(deviceTreeProvider(workbenchId).notifier)
              .toggleExpanded(node.device.id),
          onEdit: (device) => _showEditDialog(context, ref, device),
          onDelete: (device) => _showDeleteConfirmation(context, ref, device),
        );
      },
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无设备',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '点击"添加设备"创建第一个设备',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('retry-button'),
            onPressed: () =>
                ref.read(deviceTreeProvider(workbenchId).notifier).refresh(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Device device) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeviceFormDialog(
        device: device,
        workbenchId: workbenchId,
      ),
    );

    if (result == true && context.mounted) {
      ref.read(deviceTreeProvider(workbenchId).notifier).refresh();
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除设备 "${device.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deviceService = ref.read(deviceServiceProvider);
        await deviceService.deleteDevice(device.id);
        ref.read(deviceTreeProvider(workbenchId).notifier).refresh();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
}
