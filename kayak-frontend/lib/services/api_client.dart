import 'package:dio/dio.dart';

import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// ApiClient — 基于 Dio 5.9.2 的 HTTP 客户端
///
/// 封装了 Dio 实例，统一配置 BaseOptions 和内建拦截器。
/// 拦截器注册顺序（重要）:
///   1. AuthInterceptor — 优先处理 Token 和 401 刷新
///   2. ErrorInterceptor — 在 Auth 之后处理错误映射
///   3. LogInterceptor — 最外层日志记录
class ApiClient {
  /// 创建 ApiClient 实例
  ///
  /// [baseUrl] API 基础地址，如 `http://localhost:8080`
  /// [authInterceptor] 认证拦截器
  /// [errorInterceptor] 错误处理拦截器
  ApiClient({
    required String baseUrl,
    required AuthInterceptor authInterceptor,
    required ErrorInterceptor errorInterceptor,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 将 Dio 实例注入 AuthInterceptor，用于复用连接池重试请求
    authInterceptor.dio = _dio;

    // 拦截器注册顺序：Auth → Error → Log
    _dio.interceptors.addAll([
      authInterceptor,
      errorInterceptor,
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  late final Dio _dio;

  /// 发起 GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  /// 发起 POST 请求
  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  /// 发起 PUT 请求
  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  /// 发起 DELETE 请求
  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }

  /// 发起 PATCH 请求
  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data);
  }
}
