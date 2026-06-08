import 'package:json_annotation/json_annotation.dart';

part 'workbench.g.dart';

// ============================================================
// Workbench — 工作台实体
// ============================================================
@JsonSerializable()
class Workbench {
  const Workbench({
    required this.id,
    required this.name,
    this.description,
    required this.ownerType,
    required this.ownerId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deviceCount,
  });

  factory Workbench.fromJson(Map<String, dynamic> json) =>
      _$WorkbenchFromJson(json);
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'owner_type')
  final String ownerType;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'device_count', defaultValue: 0)
  final int? deviceCount;
  Map<String, dynamic> toJson() => _$WorkbenchToJson(this);

  Workbench copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerType,
    String? ownerId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? deviceCount,
  }) {
    return Workbench(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceCount: deviceCount ?? this.deviceCount,
    );
  }
}

// ============================================================
// CreateWorkbenchRequest — 创建工作台请求
// ============================================================
@JsonSerializable()
class CreateWorkbenchRequest {
  const CreateWorkbenchRequest({
    required this.name,
    this.description,
    required this.ownerType,
    required this.ownerId,
  });

  factory CreateWorkbenchRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkbenchRequestFromJson(json);
  final String name;
  final String? description;
  @JsonKey(name: 'owner_type')
  final String ownerType;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  Map<String, dynamic> toJson() => _$CreateWorkbenchRequestToJson(this);

  CreateWorkbenchRequest copyWith({
    String? name,
    String? description,
    String? ownerType,
    String? ownerId,
  }) {
    return CreateWorkbenchRequest(
      name: name ?? this.name,
      description: description ?? this.description,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
