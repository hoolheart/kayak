/// 设备树节点模型
///
/// 定义设备树形结构的节点
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'device.dart';

part 'device_tree_node.freezed.dart';
part 'device_tree_node.g.dart';

/// 设备树节点
@freezed
class DeviceTreeNode with _$DeviceTreeNode {
  const factory DeviceTreeNode({
    required Device device,
    required List<DeviceTreeNode> children,
    @Default(false) bool isExpanded,
  }) = _DeviceTreeNode;

  factory DeviceTreeNode.fromDevice(Device device) => DeviceTreeNode(
        device: device,
        children: [],
      );

  factory DeviceTreeNode.fromJson(Map<String, dynamic> json) =>
      _$DeviceTreeNodeFromJson(json);
}
