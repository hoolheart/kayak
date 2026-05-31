import 'package:dio/dio.dart';

import '../models/common.dart';
import '../models/workbench.dart';
import 'api_client.dart';

/// WorkbenchService — 工作台服务
///
/// 封装工作台相关的 HTTP API 调用，提供类型安全的接口。
/// 使用 [ApiClient] 发起请求，利用 [ErrorInterceptor] 统一处理错误。
///
/// 所有方法不捕获异常 —— 异常由 ErrorInterceptor 和 Provider 层处理。
class WorkbenchService {
  /// 创建 WorkbenchService 实例
  ///
  /// [client] ApiClient 实例，提供 HTTP GET/POST/PUT/DELETE 方法
  WorkbenchService(this._client);

  final ApiClient _client;

  /// 获取工作台列表（分页）
  ///
  /// 调用 `GET /api/v1/workbenches`。
  ///
  /// [page] 页码，从 1 开始，默认 1
  /// [size] 每页条数，默认 20
  /// [search] 搜索关键字（可选），按名称/描述模糊匹配
  /// 返回 [PaginatedResponse]<[Workbench]> 包含分页元数据和记录列表
  Future<PaginatedResponse<Workbench>> list({
    int page = 1,
    int size = 20,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
    };

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final response = await _client.get(
      '/api/v1/workbenches',
      queryParameters: queryParameters,
    );

    final apiResponse = ApiResponse<PaginatedResponse<Workbench>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => PaginatedResponse<Workbench>.fromJson(
        json as Map<String, dynamic>,
        (item) => Workbench.fromJson(item as Map<String, dynamic>),
      ),
    );

    return apiResponse.data;
  }

  /// 创建工作台
  ///
  /// 调用 `POST /api/v1/workbenches`。
  ///
  /// [request] 创建工作台请求，包含 name, description, ownerType, ownerId
  /// 返回创建的 [Workbench] 对象
  Future<Workbench> create(CreateWorkbenchRequest request) async {
    final response = await _client.post(
      '/api/v1/workbenches',
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<Workbench>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Workbench.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 获取工作台详情
  ///
  /// 调用 `GET /api/v1/workbenches/{id}`。
  ///
  /// [id] 工作台 ID
  /// 返回 [Workbench] 对象
  /// 如果资源不存在，抛出 404 [DioException]
  Future<Workbench> getById(String id) async {
    final response = await _client.get(
      '/api/v1/workbenches/$id',
    );

    final apiResponse = ApiResponse<Workbench>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Workbench.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 更新工作台
  ///
  /// 调用 `PUT /api/v1/workbenches/{id}`。
  /// 支持部分更新：只传递需要变更的字段即可。
  ///
  /// [id] 工作台 ID
  /// [data] 需要更新的字段，如 `{'name': 'New Name'}`
  /// 返回更新后的 [Workbench] 对象
  Future<Workbench> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '/api/v1/workbenches/$id',
      data: data,
    );

    final apiResponse = ApiResponse<Workbench>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Workbench.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 删除工作台
  ///
  /// 调用 `DELETE /api/v1/workbenches/{id}`。
  ///
  /// [id] 工作台 ID
  /// 正常返回 void；如果资源不存在，抛出 404 [DioException]
  Future<void> delete(String id) async {
    await _client.delete(
      '/api/v1/workbenches/$id',
    );
  }
}
