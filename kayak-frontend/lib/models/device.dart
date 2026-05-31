import 'package:json_annotation/json_annotation.dart';

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
@JsonSerializable()
class Device {

  const Device({
    required this.id,
    required this.workbenchId,
    this.parentId,
    required this.name,
    required this.protocolType,
    this.protocolParams,
    this.manufacturer,
    this.model,
    this.sn,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  final String id;
  @JsonKey(name: 'workbench_id')
  final String workbenchId;
  @JsonKey(name: 'parent_id')
  final String? parentId;
  final String name;
  @JsonKey(name: 'protocol_type')
  final ProtocolType protocolType;
  @JsonKey(name: 'protocol_params')
  final Map<String, dynamic>? protocolParams;
  final String? manufacturer;
  final String? model;
  final String? sn;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  Map<String, dynamic> toJson() => _$DeviceToJson(this);

  Device copyWith({
    String? id,
    String? workbenchId,
    String? parentId,
    String? name,
    ProtocolType? protocolType,
    Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      workbenchId: workbenchId ?? this.workbenchId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      protocolType: protocolType ?? this.protocolType,
      protocolParams: protocolParams ?? this.protocolParams,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      sn: sn ?? this.sn,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// DeviceTreeNode — 设备树节点（递归结构）
// ============================================================
@JsonSerializable()
class DeviceTreeNode {

  const DeviceTreeNode({
    required this.id,
    required this.workbenchId,
    this.parentId,
    required this.name,
    required this.protocolType,
    this.protocolParams,
    this.manufacturer,
    this.model,
    this.sn,
    required this.status,
    this.children = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceTreeNode.fromJson(Map<String, dynamic> json) =>
      _$DeviceTreeNodeFromJson(json);
  final String id;
  @JsonKey(name: 'workbench_id')
  final String workbenchId;
  @JsonKey(name: 'parent_id')
  final String? parentId;
  final String name;
  @JsonKey(name: 'protocol_type')
  final ProtocolType protocolType;
  @JsonKey(name: 'protocol_params')
  final Map<String, dynamic>? protocolParams;
  final String? manufacturer;
  final String? model;
  final String? sn;
  final String status;
  @JsonKey(defaultValue: [])
  final List<DeviceTreeNode> children;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  Map<String, dynamic> toJson() => _$DeviceTreeNodeToJson(this);

  DeviceTreeNode copyWith({
    String? id,
    String? workbenchId,
    String? parentId,
    String? name,
    ProtocolType? protocolType,
    Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
    String? status,
    List<DeviceTreeNode>? children,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceTreeNode(
      id: id ?? this.id,
      workbenchId: workbenchId ?? this.workbenchId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      protocolType: protocolType ?? this.protocolType,
      protocolParams: protocolParams ?? this.protocolParams,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      sn: sn ?? this.sn,
      status: status ?? this.status,
      children: children ?? this.children,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
