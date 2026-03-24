/// 设备树状态模型
///
/// 管理设备树的状态
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'device_tree_node.dart';

part 'device_tree_state.freezed.dart';

/// 设备树状态
@freezed
class DeviceTreeState with _$DeviceTreeState {
  const factory DeviceTreeState({
    @Default([]) List<DeviceTreeNode> nodes,
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    String? error,
  }) = _DeviceTreeState;
}
