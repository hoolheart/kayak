/// 设备树Provider
///
/// 处理设备列表的树形结构状态
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../models/device_tree_node.dart';
import '../models/device_tree_state.dart';
import '../services/device_service.dart';

/// 设备树Notifier
class DeviceTreeNotifier extends StateNotifier<DeviceTreeState> {
  final DeviceServiceInterface _service;
  final String workbenchId;

  DeviceTreeNotifier(this._service, this.workbenchId)
      : super(const DeviceTreeState());

  /// 加载设备树
  Future<void> loadDevices() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final devices = await _service.listDevices(workbenchId);
      final nodes = _buildTree(devices);

      state = state.copyWith(
        nodes: nodes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 刷新设备树
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final devices = await _service.listDevices(workbenchId);
      final nodes = _buildTree(devices);

      state = state.copyWith(
        nodes: nodes,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  /// 切换节点展开/折叠状态
  void toggleExpanded(String deviceId) {
    state = state.copyWith(
      nodes: _toggleNodeExpansion(state.nodes, deviceId),
    );
  }

  List<DeviceTreeNode> _buildTree(List<Device> devices) {
    // 构建树形结构
    final Map<String?, List<Device>> grouped = {};
    for (final device in devices) {
      grouped.putIfAbsent(device.parentId, () => []).add(device);
    }

    List<DeviceTreeNode> buildNodes(String? parentId) {
      return grouped[parentId]?.map((device) {
            return DeviceTreeNode(
              device: device,
              children: buildNodes(device.id),
            );
          }).toList() ??
          [];
    }

    return buildNodes(null);
  }

  List<DeviceTreeNode> _toggleNodeExpansion(
    List<DeviceTreeNode> nodes,
    String deviceId,
  ) {
    return nodes.map((node) {
      if (node.device.id == deviceId) {
        return node.copyWith(isExpanded: !node.isExpanded);
      }
      if (node.children.isNotEmpty) {
        return node.copyWith(
          children: _toggleNodeExpansion(node.children, deviceId),
        );
      }
      return node;
    }).toList();
  }
}

/// Provider for DeviceTreeNotifier
final deviceTreeProvider =
    StateNotifierProvider.family<DeviceTreeNotifier, DeviceTreeState, String>(
        (ref, workbenchId) {
  final service = ref.watch(deviceServiceProvider);
  return DeviceTreeNotifier(service, workbenchId);
});

/// 选中的设备Provider
final selectedDeviceProvider = StateProvider<Device?>((ref) => null);
