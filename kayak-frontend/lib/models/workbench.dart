import 'package:freezed_annotation/freezed_annotation.dart';

part 'workbench.freezed.dart';
part 'workbench.g.dart';

// ============================================================
// Workbench — 工作台实体
// ============================================================
@freezed
class Workbench with _$Workbench {
  const factory Workbench({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'owner_type') required String ownerType,
    @JsonKey(name: 'owner_id') required String ownerId,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Workbench;

  factory Workbench.fromJson(Map<String, dynamic> json) =>
      _$WorkbenchFromJson(json);
}

// ============================================================
// CreateWorkbenchRequest — 创建工作台请求
// ============================================================
@freezed
class CreateWorkbenchRequest with _$CreateWorkbenchRequest {
  const factory CreateWorkbenchRequest({
    required String name,
    String? description,
    @JsonKey(name: 'owner_type') required String ownerType,
  }) = _CreateWorkbenchRequest;

  factory CreateWorkbenchRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkbenchRequestFromJson(json);
}
