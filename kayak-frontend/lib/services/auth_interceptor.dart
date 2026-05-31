import 'package:dio/dio.dart';

import 'auth_service.dart';

/// _PendingRequest — 等待刷新完成后重试的请求
///
/// 当并发 401 发生时，后续请求被暂存于此。
/// 刷新成功后统一使用新 Token 重试。
class _PendingRequest {
  _PendingRequest(this.requestOptions, this.handler);

  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
}

/// AuthInterceptor — 认证拦截器
///
/// 职责:
///   1. onRequest: 自动附加 `Authorization: Bearer <token>`
///   2. onError: 检测 401 → 并发刷新锁 → 成功重试 / 失败登出
///
/// 并发锁说明:
///   - 第一个 401 触发 refresh，后续 401 加入等待队列
///   - 刷新成功后，所有等待请求使用新 Token 重试
///   - 刷新失败后，所有等待请求返回 401 错误
class AuthInterceptor extends Interceptor {
  /// 创建 AuthInterceptor 实例
  AuthInterceptor(this._authService);

  final AuthService _authService;

  Dio? _dio;

  /// 设置 Dio 实例引用（由 ApiClient 在构造时调用）
  ///
  /// 使用同一 Dio 实例重试请求，避免创建多个独立的连接池。
  set dio(Dio value) {
    _dio = value;
  }

  /// 是否正在刷新 Token（并发锁标志）
  bool _isRefreshing = false;

  /// 等待刷新完成后重试的请求队列
  final List<_PendingRequest> _pendingRequests = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authService.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 仅处理 401 错误
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // 不拦截 /auth/refresh 请求自身的 401 错误（防止无限循环）
    if (err.requestOptions.path.contains('/auth/refresh')) {
      handler.next(err);
      return;
    }

    // 如果正在刷新，将当前请求加入等待队列
    if (_isRefreshing) {
      _pendingRequests.add(_PendingRequest(err.requestOptions, handler));
      return;
    }

    // 开始刷新 Token
    _isRefreshing = true;

    try {
      final success = await _authService.tryRefresh();
      if (success) {
        await _retryWithNewToken(err, handler);
      } else {
        await _handleRefreshFailure(err, handler);
      }
    } catch (e) {
      // 刷新过程中抛出了意外异常
      await _authService.logout();
      final refreshErr = e is DioException ? e : DioException(
        requestOptions: err.requestOptions,
        message: '刷新 Token 时发生意外错误',
        error: e,
      );
      handler.next(refreshErr);
      _failAllPending(refreshErr);
    } finally {
      _isRefreshing = false;
      _pendingRequests.clear();
    }
  }

  /// 使用新 Token 重试原请求和所有等待中的请求
  Future<void> _retryWithNewToken(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final newToken = _authService.accessToken;

    // 重试原请求
    await _retrySingleRequest(err.requestOptions, handler, newToken);

    // 重试所有等待中的请求
    for (final pending in _pendingRequests) {
      await _retrySingleRequest(
        pending.requestOptions,
        pending.handler,
        newToken,
      );
    }
  }

  /// 使用新 Token 重试单个请求
  Future<void> _retrySingleRequest(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
    String? newToken,
  ) async {
    final dio = _dio;
    if (dio == null) {
      // 边界防御：_dio 未被设置（理论上不会发生）
      handler.next(
        DioException(
          requestOptions: requestOptions,
          message: '重试请求失败：客户端未正确初始化',
        ),
      );
      return;
    }

    requestOptions.headers['Authorization'] = 'Bearer $newToken';
    try {
      final response = await dio.fetch(requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      // 重试失败，传递真实的 DioException
      handler.next(e);
    } catch (e) {
      // 非 Dio 异常，包装为 DioException
      handler.next(
        DioException(
          requestOptions: requestOptions,
          message: '重试请求时发生意外错误',
          error: e,
        ),
      );
    }
  }

  /// 刷新失败：清除 Token，通知所有请求
  Future<void> _handleRefreshFailure(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await _authService.logout();

    // 原请求返回 401 错误
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        message: '登录已过期，请重新登录',
        type: err.type,
        response: err.response,
      ),
    );

    // 所有等待中的请求也返回 401 错误
    for (final pending in _pendingRequests) {
      pending.handler.next(
        DioException(
          requestOptions: pending.requestOptions,
          message: '登录已过期，请重新登录',
          type: err.type,
          response: err.response,
        ),
      );
    }
  }

  /// 所有等待中的请求都标记为失败
  void _failAllPending(DioException err) {
    for (final pending in _pendingRequests) {
      pending.handler.next(err);
    }
  }
}
