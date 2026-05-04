/// 设备树节点组件
///
/// 显示单个设备节点，支持展开/折叠
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/device.dart';
import '../../models/device_tree_node.dart';
import '../../providers/device_tree_provider.dart';

/// 设备树节点组件
class DeviceTreeNodeWidget extends ConsumerWidget {
  const DeviceTreeNodeWidget({
    super.key,
    required this.node,
    this.depth = 0,
    this.onTap,
    this.onExpand,
    this.onEdit,
    this.onDelete,
  });
  final DeviceTreeNode node;
  final int depth;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final void Function(Device device)? onEdit;
  final void Function(Device device)? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = node.isExpanded;
    final hasChildren = node.children.isNotEmpty;
    final isSelected = ref.watch(selectedDeviceProvider)?.id == node.device.id;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: isSelected ? colorScheme.primaryContainer : null,
          child: InkWell(
            onTap: onTap,
            onSecondaryTap: () => _showContextMenu(context),
            child: Padding(
              padding: EdgeInsets.only(left: depth * 24.0),
              child: Row(
                children: [
                  // 展开/折叠箭头
                  if (hasChildren)
                    IconButton(
                      key: Key('expand-icon-${node.device.id}'),
                      icon: Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                      ),
                      onPressed: onExpand,
                      iconSize: 20,
                    )
                  else
                    const SizedBox(width: 48),

                  // 设备图标
                  Icon(
                    Icons.memory,
                    key: Key('device-icon-${node.device.id}'),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),

                  // 设备名称
                  Expanded(
                    child: Text(
                      node.device.name,
                      key: Key('device-name-${node.device.id}'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 状态指示器
                  _buildStatusIndicator(context, node.device.status),
                ],
              ),
            ),
          ),
        ),

        // 子节点
        if (hasChildren && isExpanded)
          ...node.children.map(
            (child) => DeviceTreeNodeWidget(
              key: Key('device-node-${child.device.id}'),
              node: child,
              depth: depth + 1,
              onTap: () => ref.read(selectedDeviceProvider.notifier).state =
                  child.device,
              onExpand: () => ref
                  .read(deviceTreeProvider(node.device.workbenchId).notifier)
                  .toggleExpanded(child.device.id),
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context, DeviceStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case DeviceStatus.online:
        color = Colors.green;
        icon = Icons.check_circle;
      case DeviceStatus.offline:
        color = Colors.grey;
        icon = Icons.circle_outlined;
      case DeviceStatus.error:
        color = Colors.red;
        icon = Icons.error;
    }

    return Icon(icon, color: color, size: 16);
  }

  void _showContextMenu(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];

    if (onEdit != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'edit',
          child: Text('编辑'),
        ),
      );
    }

    if (onDelete != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('删除'),
        ),
      );
    }

    if (items.isEmpty) return;

    showMenu<String>(
      context: context,
      items: items,
    ).then((value) {
      if (value == 'edit') {
        onEdit?.call(node.device);
      } else if (value == 'delete') {
        onDelete?.call(node.device);
      }
    });
  }
}
