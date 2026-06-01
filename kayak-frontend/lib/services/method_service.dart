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
}
