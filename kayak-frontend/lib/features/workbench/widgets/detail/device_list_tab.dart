/// 设备列表Tab内容
///
/// 显示设备树和测点列表
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/device_tree_provider.dart';
import '../device_tree/device_tree.dart';
import '../point/point_list_panel.dart';

/// 设备列表Tab内容组件
class DeviceListTab extends ConsumerStatefulWidget {
  final String workbenchId;

  const DeviceListTab({
    super.key,
    required this.workbenchId,
  });

  @override
  ConsumerState<DeviceListTab> createState() => _DeviceListTabState();
}

class _DeviceListTabState extends ConsumerState<DeviceListTab> {
  @override
  void initState() {
    super.initState();
    // 加载设备树数据
    Future.microtask(() {
      ref.read(deviceTreeProvider(widget.workbenchId).notifier).loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 操作栏
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              FilledButton.icon(
                key: const Key('add-device-button'),
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('添加设备'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref
                    .read(deviceTreeProvider(widget.workbenchId).notifier)
                    .refresh(),
                tooltip: '刷新',
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // 设备树
        Expanded(
          flex: 2,
          child: DeviceTree(workbenchId: widget.workbenchId),
        ),

        const Divider(height: 1),

        // 测点列表
        const Expanded(
          child: PointListPanel(),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    // TODO: 实现创建设备对话框
  }
}
