import '../models/common.dart';
import '../models/method.dart';
import 'api_client.dart';

/// MethodService — 试验方法服务
///
/// 封装方法相关的 HTTP API 调用，提供类型安全的接口。
/// 使用 [ApiClient] 发起请求，利用 [ErrorInterceptor] 统一处理错误。
///
/// 所有方法不捕获异常 —— 异常由 ErrorInterceptor 和 Provider 层处理。
class MethodService {
  /// 创建 MethodService 实例
  ///
  /// [client] ApiClient 实例，提供 HTTP GET/POST/PUT/DELETE 方法
  MethodService(this._client);

  final ApiClient _client;

  /// 获取方法列表
  ///
  /// 调用 `GET /api/v1/methods`。
  ///
  /// 返回 [List]<[Method]> 方法列表。
  /// 如果请求失败，抛出 [DioException]。
  Future<List<Method>> list() async {
    final response = await _client.get(
      '/api/v1/methods',
    );

    final apiResponse = ApiResponse<List<Method>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((e) => Method.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// 根据 ID 获取方法详情
  ///
  /// 调用 `GET /api/v1/methods/{id}`。
  ///
  /// [id] 方法 ID（UUID）
  /// 返回 [Method] 对象
  /// 如果资源不存在，抛出 404 [DioException]
  Future<Method> getById(String id) async {
    final response = await _client.get(
      '/api/v1/methods/$id',
    );

    final apiResponse = ApiResponse<Method>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Method.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 创建方法
  ///
  /// 调用 `POST /api/v1/methods`。
  ///
  /// [data] 包含 name, description, processDefinition, parameterSchema 的请求体
  /// 返回创建的 [Method] 对象
  Future<Method> create(Map<String, dynamic> data) async {
    final response = await _client.post(
      '/api/v1/methods',
      data: data,
    );

    final apiResponse = ApiResponse<Method>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Method.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 更新方法
  ///
  /// 调用 `PUT /api/v1/methods/{id}`。
  /// 支持部分更新：只传递需要变更的字段。
  ///
  /// [id] 方法 ID
  /// [data] 需要更新的字段
  /// 返回更新后的 [Method] 对象
  Future<Method> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '/api/v1/methods/$id',
      data: data,
    );

    final apiResponse = ApiResponse<Method>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Method.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 删除方法
  ///
  /// 调用 `DELETE /api/v1/methods/{id}`。
  ///
  /// [id] 方法 ID
  Future<void> delete(String id) async {
    await _client.delete(
      '/api/v1/methods/$id',
    );
  }

  /// 验证方法定义
  ///
  /// 调用 `POST /api/v1/methods/validate`。
  ///
  /// [processDefinition] 方法过程定义 JSON
  /// 返回 [ValidationResult] 包含验证结果
  Future<ValidationResult> validate(
    Map<String, dynamic> processDefinition,
  ) async {
    final response = await _client.post(
      '/api/v1/methods/validate',
      data: {'process_definition': processDefinition},
    );

    final apiResponse = ApiResponse<ValidationResult>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          ValidationResult.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }
}

/// 验证结果模型
///
/// 简单的 2 字段响应对象。注意：如果未来增加更多字段，
/// 建议迁移到 freezed + json_serializable 以保持与项目中其他模型一致。
class ValidationResult {
  const ValidationResult({
    required this.valid,
    this.errors = const [],
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      valid: json['valid'] as bool? ?? false,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  final bool valid;
  final List<String> errors;

  Map<String, dynamic> toJson() => {
        'valid': valid,
        'errors': errors,
      };
}
