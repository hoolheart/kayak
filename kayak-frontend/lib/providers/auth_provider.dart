import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import 'services.dart';

/// AuthNotifier — 认证状态管理器
///
/// 使用 Riverpod 3.x [AsyncNotifier] API。
/// 状态通过 [AsyncValue]<[User]?> 表达认证生命周期：
/// - [AsyncLoading] — 正在检查会话/登录中/注册中
/// - [AsyncData](null) — 未认证
/// - [AsyncData](user) — 已认证（user 非 null）
/// - [AsyncError] — 错误状态（网络错误、凭据错误等）
///
/// 职责：
/// 1. 启动时检查本地 Token 并恢复会话
/// 2. 管理登录/注册/登出操作
/// 3. Token 自动刷新（Timer.periodic）
/// 4. 错误映射为用户可读消息
class AuthNotifier extends AsyncNotifier<User?> {
  /// Token 自动刷新定时器
  ///
  /// 认证成功后启动，在 Access Token 过期前约 5 分钟触发刷新。
  Timer? _refreshTimer;

  /// Token 刷新定时器是否处于激活状态
  ///
  /// 用于测试验证定时器生命周期。
  bool get isTimerActive => _refreshTimer != null && _refreshTimer!.isActive;

  @override
  Future<User?> build() async {
    // 注册 dispose 回调，确保定时器在 Provider 销毁时被取消
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    });

    final authService = ref.read(authServiceProvider);

    // Step 1: Initialize — load tokens from storage
    try {
      await authService.initialize();
    } catch (_) {
      // initialize() failed (e.g., TokenStorage unavailable)
      // Gracefully fall back to unauthenticated state
      return null;
    }

    // Step 2: Check if token exists
    if (authService.accessToken == null) {
      // No token — user is not authenticated
      return null;
    }

    // Step 3: Try to refresh the token
    final refreshed = await authService.tryRefresh();
    if (!refreshed) {
      // Refresh failed — session is expired or invalid
      // Clear invalid tokens so stale tokens don't persist
      await authService.logout();
      // Throw so Riverpod sets state to AsyncError.
      throw const AuthException('Session expired. Please login again.');
    }

    // Step 4: Fetch current user info
    try {
      final user = await authService.getMe();
      // Start the periodic token refresh timer
      _startRefreshTimer(authService);
      return user;
    } catch (_) {
      // getMe() failed (e.g., network error, server error)
      // Token might still be valid, but we can't get user info.
      // Fall back to unauthenticated so the user can retry login.
      return null;
    }
  }

  /// 用户登录
  ///
  /// 调用 [AuthService.login] 进行登录认证。
  /// 成功后将状态更新为已认证用户，并启动 Token 刷新定时器。
  /// 失败时将状态更新为错误，包含可读的错误消息。
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    try {
      final authService = ref.read(authServiceProvider);
      final tokens = await authService.login(email, password);
      _startRefreshTimer(authService, expiresIn: tokens.expiresIn);
      state = AsyncData(tokens.user);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 用户注册
  ///
  /// 调用 [AuthService.register] 进行注册。
  /// 注册成功后自动处于已认证状态（无需额外登录）。
  /// 失败后将状态更新为错误。
  Future<void> register(
    String email,
    String password, [
    String? username,
  ]) async {
    state = const AsyncLoading();

    try {
      final authService = ref.read(authServiceProvider);
      final tokens = await authService.register(
        email,
        password,
        username,
      );
      _startRefreshTimer(authService, expiresIn: tokens.expiresIn);
      state = AsyncData(tokens.user);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 登出
  ///
  /// 清除所有认证状态：
  /// 1. 取消 Token 刷新定时器
  /// 2. 调用 [AuthService.logout] 清除 Token
  /// 3. 将状态重置为未认证
  Future<void> logout() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(null);
  }

  // ==========================================================
  // Private: Token 刷新定时器
  // ==========================================================

  /// 启动 Token 自动刷新定时器
  ///
  /// 使用 [Timer.periodic] 在 Access Token 过期前约 5 分钟
  /// 触发一次刷新。如果 [expiresIn] 未提供或为 null，默认
  /// 使用 60 秒间隔（保守值）。
  ///
  /// [expiresIn] Access Token 的有效期（秒），来自登录/注册响应。
  void _startRefreshTimer(AuthService authService, {int? expiresIn}) {
    _refreshTimer?.cancel();

    // 过期前 5 分钟刷新；如果 expiresIn <= 300 或为 null，使用 60 秒
    const safetyMargin = 300; // 5 分钟
    final intervalSeconds =
        (expiresIn != null && expiresIn > safetyMargin)
            ? expiresIn - safetyMargin
            : 60;

    _refreshTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) async {
        try {
          final refreshed = await authService.tryRefresh();
          if (!refreshed) {
            // Refresh Token 也已过期 — 清除会话
            await logout();
          }
        } catch (_) {
          // 网络错误等 — 下次定时器触发时重试
          // 不登出，避免因临时网络问题导致用户被登出
        }
      },
    );
  }

  // ==========================================================
  // Private: 错误映射
  // ==========================================================

  /// 将各种异常映射为用户可读的错误消息
  String _mapError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络后重试';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return _mapStatusCode(statusCode);

        default:
          return '网络异常，请稍后重试';
      }
    }

    // 处理注册相关错误
    final message = error.toString();
    if (message.contains('already registered') ||
        message.contains('已被注册')) {
      return '该邮箱已被注册';
    }

    return error.toString();
  }

  /// 将 HTTP 状态码映射为用户可读的消息
  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求格式不正确，请检查输入';
      case 401:
        return '邮箱或密码错误';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 409:
        return '该邮箱已被注册';
      case 422:
        return '输入数据格式不正确';
      case 429:
        return '请求过于频繁，请稍后重试';
      case 500:
      case 502:
      case 503:
        return '服务暂时不可用，请稍后再试';
      default:
        return '操作失败，请重试（错误码: $statusCode）';
    }
  }
}

/// 认证 Provider
///
/// 通过 [AsyncNotifierProvider] 暴露 [AuthNotifier]，
/// 提供 [AsyncValue]<[User]?> 类型的认证状态。
///
/// 读取方式：
/// ```dart
/// // 读取状态
/// final authState = ref.watch(authProvider);
///
/// // 调用方法
/// ref.read(authProvider.notifier).login(email, password);
/// ```
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

/// 认证异常
///
/// 用于在状态机中表示认证失败。
class AuthException implements Exception {
  /// 创建认证异常
  const AuthException(this.message);

  /// 异常描述消息
  final String message;

  @override
  String toString() => message;
}
