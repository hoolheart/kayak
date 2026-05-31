import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';
part 'device.g.dart';

// ============================================================
// ProtocolType — 协议类型枚举
// ============================================================
enum ProtocolType {
  @JsonValue('virtual')
  virtual,
  @JsonValue('modbus_tcp')
  modbusTcp,
  @JsonValue('modbus_rtu')
  modbusRtu,
  @JsonValue('can')
  can,
  @JsonValue('visa')
  visa,
  @JsonValue('mqtt')
  mqtt,
}

// ============================================================
// Device — 设备实体
// ============================================================
@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    @JsonKey(name: 'workbench_id') required String workbenchId,
    @JsonKey(name: 'parent_id') String? parentId,
    required String name,
    @JsonKey(name: 'protocol_type') required String protocolType,
    @JsonKey(name: 'protocol_params') Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}

// ============================================================
// DeviceTreeNode — 设备树节点（递归结构）
// ============================================================
@freezed
class DeviceTreeNode with _$DeviceTreeNode {
  const factory DeviceTreeNode({
    required String id,
    @JsonKey(name: 'workbench_id') required String workbenchId,
    @JsonKey(name: 'parent_id') String? parentId,
    required String name,
    @JsonKey(name: 'protocol_type') required String protocolType,
    @JsonKey(name: 'protocol_params') Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
    required String status,
    @Default([]) List<DeviceTreeNode> children,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _DeviceTreeNode;

  factory DeviceTreeNode.fromJson(Map<String, dynamic> json) =>
      _$DeviceTreeNodeFromJson(json);
}
