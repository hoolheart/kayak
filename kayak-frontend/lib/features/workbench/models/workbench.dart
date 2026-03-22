/// 工作台数据模型
///
/// 定义工作台的核心属性和序列化逻辑
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'workbench.freezed.dart';
part 'workbench.g.dart';

/// 工作台模型
@freezed
class Workbench with _$Workbench {
  const factory Workbench({
    required String id,
    required String name,
    String? description,
    required String ownerId,
    @JsonKey(name: 'ownerType') required String ownerType,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Workbench;

  factory Workbench.fromJson(Map<String, dynamic> json) =>
      _$WorkbenchFromJson(json);
}

/// 所有者类型枚举
enum OwnerType {
  user,
  team,
}

/// 工作台状态枚举
enum WorkbenchStatus {
  active,
  archived,
  deleted,
}

/// 分页响应模型
@freezed
class PagedWorkbenchResponse with _$PagedWorkbenchResponse {
  const factory PagedWorkbenchResponse({
    required List<Workbench> items,
    required int total,
    required int page,
    required int size,
  }) = _PagedWorkbenchResponse;

  factory PagedWorkbenchResponse.fromJson(Map<String, dynamic> json) =>
      _$PagedWorkbenchResponseFromJson(json);
}

/// 创建工作台请求
@freezed
class CreateWorkbenchRequest with _$CreateWorkbenchRequest {
  const factory CreateWorkbenchRequest({
    required String name,
    String? description,
    @JsonKey(name: 'ownerType') String? ownerType,
  }) = _CreateWorkbenchRequest;

  factory CreateWorkbenchRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkbenchRequestFromJson(json);
}

/// 更新工作台请求
@freezed
class UpdateWorkbenchRequest with _$UpdateWorkbenchRequest {
  const factory UpdateWorkbenchRequest({
    String? name,
    String? description,
  }) = _UpdateWorkbenchRequest;

  factory UpdateWorkbenchRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateWorkbenchRequestFromJson(json);
}
