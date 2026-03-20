/// API Client Interface
///
/// 定义HTTP请求的抽象，支持自动Token刷新

import 'dart:async';

import 'package:dio/dio.dart';
import 'api_exceptions.dart';
import 'auth_notifier_interface.dart';
import 'auth_api_service.dart';
import 'token_storage.dart';

abstract class ApiClientInterface {
  /// GET请求
  Future<dynamic> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  /// POST请求
  Future<dynamic> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  /// PUT请求
  Future<dynamic> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  /// DELETE请求
  Future<dynamic> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  /// 设置认证Token (用于直接API调用)
  void setAuthToken(String token);
}

/// Token刷新互斥锁
///
/// 确保并发请求时只刷新一次Token
class RefreshMutex {
  bool _isRefreshing = false;
  final List<Completer<void>> _waiters = [];

  /// 获取锁，如果正在刷新则等待
  Future<void> acquire() async {
    if (!_isRefreshing) {
      _isRefreshing = true;
      return;
    }

    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  /// 释放锁，唤醒下一个等待者
  void release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _isRefreshing = false;
    }
  }
}

/// 带Token自动刷新的API客户端
///
/// 实现ApiClientInterface接口，支持401自动刷新Token
class AuthenticatedApiClient implements ApiClientInterface {
  final Dio _dio;
  final AuthStateNotifierInterface _authNotifier;
  final TokenStorageInterface _tokenStorage;
  final AuthApiServiceInterface _authApiService;
  final RefreshMutex _refreshMutex = RefreshMutex();

  AuthenticatedApiClient({
    required Dio dio,
    required AuthStateNotifierInterface authNotifier,
    required TokenStorageInterface tokenStorage,
    required AuthApiServiceInterface authApiService,
  })  : _dio = dio,
        _authNotifier = authNotifier,
        _tokenStorage = tokenStorage,
        _authApiService = authApiService;

  @override
  Future<dynamic> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _request<T>(() => _dio.get(
          path,
          queryParameters: queryParameters,
          options: _applyAuth(options),
        ));
  }

  @override
  Future<dynamic> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _request<T>(() => _dio.post(
          path,
          data: data,
          queryParameters: queryParameters,
          options: _applyAuth(options),
        ));
  }

  @override
  Future<dynamic> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _request<T>(() => _dio.put(
          path,
          data: data,
          queryParameters: queryParameters,
          options: _applyAuth(options),
        ));
  }

  @override
  Future<dynamic> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _request<T>(() => _dio.delete(
          path,
          data: data,
          queryParameters: queryParameters,
          options: _applyAuth(options),
        ));
  }

  @override
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// 应用认证Token到请求选项
  Options _applyAuth(Options? options) {
    final accessToken = _authNotifier.accessToken;
    if (accessToken == null) return options ?? Options();

    return (options ?? Options()).copyWith(
      headers: {
        ...?options?.headers,
        'Authorization': 'Bearer $accessToken',
      },
    );
  }

  /// 执行请求，处理401错误
  Future<dynamic> _request<T>(
    Future<Response<dynamic>> Function() requestFn,
  ) async {
    try {
      return await requestFn();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return _handleUnauthorized(requestFn);
      }
      rethrow;
    }
  }

  /// 处理401未授权错误，尝试刷新Token
  Future<dynamic> _handleUnauthorized<T>(
    Future<Response<dynamic>> Function() requestFn,
  ) async {
    await _refreshMutex.acquire();

    try {
      // 再次检查是否已刷新（可能其他请求已经刷新过了）
      final currentToken = await _tokenStorage.getAccessToken();
      if (currentToken != null && !await _tokenStorage.isAccessTokenExpired()) {
        _refreshMutex.release();
        return _retryRequest<T>(requestFn);
      }

      // 尝试刷新Token
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        _refreshMutex.release();
        _authNotifier.clearAuthentication();
        throw const UnauthorizedException('No refresh token available');
      }

      final response = await _authApiService.refreshToken(refreshToken);

      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
      );

      _refreshMutex.release();

      // 更新auth状态
      final user = _authNotifier.user;
      if (user != null) {
        _authNotifier.setAuthenticated(user, response.accessToken);
      }

      // 重试原请求
      return _retryRequest<T>(requestFn);
    } catch (e) {
      _refreshMutex.release();
      _authNotifier.clearAuthentication();
      rethrow;
    }
  }

  /// 重试原请求
  Future<dynamic> _retryRequest<T>(
    Future<Response<dynamic>> Function() requestFn,
  ) async {
    return await requestFn();
  }
}
