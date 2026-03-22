/// Auth Providers
///
/// 认证相关的Riverpod Providers
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exceptions.dart';
import 'auth_api_service.dart';
import 'auth_notifier.dart';
import 'auth_notifier_interface.dart';
import 'auth_route_guard.dart';
import 'auth_state.dart';
import 'authenticated_api_client.dart';
import 'token_storage.dart';

/// API Base URL配置
const apiBaseUrl = 'http://localhost:8080';

/// Dio Provider
///
/// 提供配置好的Dio实例
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 添加日志拦截器（仅在debug模式）
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[Dio] $obj'),
    ),
  );

  return dio;
});

/// Token Storage Provider
///
/// 提供Token安全存储实例
final tokenStorageProvider = Provider<TokenStorageInterface>((ref) {
  return SecureTokenStorage();
});

/// Auth API Service Provider
///
/// 提供认证API服务实例
final authApiServiceProvider = Provider<AuthApiServiceInterface>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApiService(
    dio: dio,
    baseUrl: apiBaseUrl,
  );
});

/// Internal Auth State Notifier Provider
///
/// 内部使用StateNotifierProvider管理状态
final _authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final authApiService = ref.watch(authApiServiceProvider);

  return AuthStateNotifier(
    tokenStorage: tokenStorage,
    authApiService: authApiService,
  );
});

/// Auth State Notifier Provider (Interface)
///
/// 对外暴露的接口Provider，用于依赖注入
final authStateNotifierProvider = Provider<AuthStateNotifierInterface>((ref) {
  return ref.watch(_authStateNotifierProvider.notifier);
});

/// Auth State Provider (for convenience access to auth state)
///
/// 便捷访问认证状态的Provider
final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(_authStateNotifierProvider);
});

/// API Client Provider
///
/// 提供带Token自动刷新的API客户端
/// 注意：返回的是接口类型，遵循依赖倒置原则
final apiClientProvider = Provider<ApiClientInterface>((ref) {
  final authNotifier = ref.watch(authStateNotifierProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final authApiService = ref.watch(authApiServiceProvider);
  final dio = ref.watch(dioProvider);

  return AuthenticatedApiClient(
    dio: dio,
    authNotifier: authNotifier,
    tokenStorage: tokenStorage,
    authApiService: authApiService,
  );
});

/// Auth Route Guard Provider
///
/// 提供路由守卫实例
final authRouteGuard = Provider<AuthRouteGuard>((ref) {
  return AuthRouteGuard(ref);
});

/// App Initializer Provider
///
/// 应用初始化Provider，确保认证状态在应用启动时恢复
/// 不再使用延迟初始化，而是由调用方在build后主动触发
final appInitializerProvider = FutureProvider<bool>((ref) async {
  // 直接初始化，不再延迟
  // 初始化逻辑应该由使用方在build后调用
  return true;
});
