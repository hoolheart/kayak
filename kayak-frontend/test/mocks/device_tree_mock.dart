/// 设备树Mock数据
///
/// 提供设备树测试所需的Mock数据
library;

import 'package:kayak_frontend/features/workbench/models/device.dart';
import 'package:kayak_frontend/features/workbench/models/device_tree_node.dart';
import 'package:kayak_frontend/features/workbench/models/device_tree_state.dart';

/// 创建Mock设备
Device createMockDevice({
  String id = 'device-1',
  String workbenchId = 'workbench-1',
  String? parentId,
  String name = 'Test Device',
  ProtocolType protocolType = ProtocolType.virtual,
  Map<String, dynamic>? protocolParams,
  DeviceStatus status = DeviceStatus.online,
}) {
  return Device(
    id: id,
    workbenchId: workbenchId,
    parentId: parentId,
    name: name,
    protocolType: protocolType,
    protocolParams: protocolParams ??
        {
          'sampleInterval': 1000,
          'minValue': 0.0,
          'maxValue': 100.0,
        },
    manufacturer: 'Test Manufacturer',
    model: 'Test Model',
    sn: 'SN123456',
    status: status,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

/// 创建根设备列表
List<Device> createMockRootDevices() {
  return [
    createMockDevice(
      id: 'device-root-1',
      name: 'Root Device 1',
    ),
    createMockDevice(
      id: 'device-root-2',
      name: 'Root Device 2',
      status: DeviceStatus.offline,
    ),
  ];
}

/// 创建嵌套设备列表（带子设备）
List<Device> createMockNestedDevices() {
  return [
    createMockDevice(
      id: 'device-parent-1',
      name: 'Parent Device',
    ),
    createMockDevice(
      id: 'device-child-1',
      parentId: 'device-parent-1',
      name: 'Child Device 1',
    ),
    createMockDevice(
      id: 'device-child-2',
      parentId: 'device-parent-1',
      name: 'Child Device 2',
      status: DeviceStatus.offline,
    ),
  ];
}

/// 创建多层级嵌套设备
List<Device> createMockMultiLevelDevices() {
  return [
    createMockDevice(
      id: 'device-level-1',
      name: 'Level 1 Device',
    ),
    createMockDevice(
      id: 'device-level-2',
      parentId: 'device-level-1',
      name: 'Level 2 Device',
    ),
    createMockDevice(
      id: 'device-level-3',
      parentId: 'device-level-2',
      name: 'Level 3 Device',
    ),
  ];
}

/// 创建设备树节点
DeviceTreeNode createDeviceTreeNode({
  required Device device,
  List<DeviceTreeNode> children = const [],
  bool isExpanded = false,
}) {
  return DeviceTreeNode(
    device: device,
    children: children,
    isExpanded: isExpanded,
  );
}

/// 创建设备树状态
DeviceTreeState createMockDeviceTreeState({
  List<DeviceTreeNode> nodes = const [],
  bool isLoading = false,
  String? error,
}) {
  return DeviceTreeState(
    nodes: nodes,
    isLoading: isLoading,
    error: error,
  );
}
