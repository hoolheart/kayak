import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/auth_interceptor.dart';
import '../services/auth_service.dart';
import '../services/error_interceptor.dart';
import '../services/token_storage.dart';
import '../services/workbench_service.dart';

/// AuthService 的 Riverpod Provider
///
/// 提供全局唯一的 [AuthService] 实例。
/// 在测试中通过 `overrideWithValue` 注入 [FakeAuthService]。
///
/// ```dart
/// // 生产环境
/// final service = ref.read(authServiceProvider);
///
/// // 测试环境
/// final container = ProviderContainer(overrides: [
///   authServiceProvider.overrideWithValue(mockAuthService),
/// ]);
/// ```
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    baseUrl: 'http://localhost:8080',
    storage: TokenStorage(),
  );
});

/// ApiClient 的 Riverpod Provider
///
/// 提供全局唯一的 [ApiClient] 实例，已配置 AuthInterceptor 和 ErrorInterceptor。
///
/// 依赖 [authServiceProvider] 用于创建 AuthInterceptor。
/// 注意：ApiClient 创建时会自动将 Dio 实例注入 AuthInterceptor，
/// 用于在 401 刷新 Token 后重试请求。
final apiClientProvider = Provider<ApiClient>((ref) {
  final authInterceptor = AuthInterceptor(ref.read(authServiceProvider));
  final errorInterceptor = ErrorInterceptor();

  return ApiClient(
    baseUrl: 'http://localhost:8080',
    authInterceptor: authInterceptor,
    errorInterceptor: errorInterceptor,
  );
});

/// WorkbenchService 的 Riverpod Provider
///
/// 提供全局唯一的 [WorkbenchService] 实例。
/// 依赖 [apiClientProvider] 用于 HTTP 请求。
///
/// 在测试中通过 `overrideWithValue` 注入 FakeWorkbenchService：
/// ```dart
/// final container = ProviderContainer(overrides: [
///   workbenchServiceProvider.overrideWithValue(fakeService),
/// ]);
/// ```
final workbenchServiceProvider = Provider<WorkbenchService>((ref) {
  return WorkbenchService(ref.read(apiClientProvider));
});
