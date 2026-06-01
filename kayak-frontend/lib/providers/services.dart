import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/auth_interceptor.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/error_interceptor.dart';
import '../services/experiment_service.dart';
import '../services/method_service.dart';
import '../services/point_service.dart';
import '../services/token_storage.dart';
import '../services/workbench_service.dart';
import '../services/ws_service.dart';

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

/// DeviceService 的 Riverpod Provider
///
/// 提供全局唯一的 [DeviceService] 实例。
/// 依赖 [apiClientProvider] 用于 HTTP 请求。
///
/// 在测试中通过 `overrideWithValue` 注入 FakeDeviceService：
/// ```dart
/// final container = ProviderContainer(overrides: [
///   deviceServiceProvider.overrideWithValue(fakeService),
/// ]);
/// ```
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.read(apiClientProvider));
});

/// PointService 的 Riverpod Provider
///
/// 提供全局唯一的 [PointService] 实例。
/// 依赖 [apiClientProvider] 用于 HTTP 请求。
///
/// 在测试中通过 `overrideWithValue` 注入 FakePointService：
/// ```dart
/// final container = ProviderContainer(overrides: [
///   pointServiceProvider.overrideWithValue(fakeService),
/// ]);
/// ```
final pointServiceProvider = Provider<PointService>((ref) {
  return PointService(ref.read(apiClientProvider));
});

/// ExperimentService 的 Riverpod Provider
///
/// 提供全局唯一的 [ExperimentService] 实例。
/// 依赖 [apiClientProvider] 用于 HTTP 请求。
///
/// 在测试中通过 `overrideWithValue` 注入 FakeExperimentService：
/// ```dart
/// final container = ProviderContainer(overrides: [
///   experimentServiceProvider.overrideWithValue(fakeService),
/// ]);
/// ```
final experimentServiceProvider = Provider<ExperimentService>((ref) {
  return ExperimentService(ref.read(apiClientProvider));
});

/// MethodService 的 Riverpod Provider
///
/// 提供全局唯一的 [MethodService] 实例。
/// 依赖 [apiClientProvider] 用于 HTTP 请求。
///
/// 在测试中通过 `overrideWithValue` 注入 FakeMethodService：
/// ```dart
/// final container = ProviderContainer(overrides: [
///   methodServiceProvider.overrideWithValue(fakeService),
/// ]);
/// ```
final methodServiceProvider = Provider<MethodService>((ref) {
  return MethodService(ref.read(apiClientProvider));
});

/// WsService 的 Riverpod Provider
///
/// 提供全局唯一的 [WsService] 实例。
/// WsService 内部管理 WebSocket 连接状态，本身是无状态的单例。
///
/// 在测试中通过 `overrideWithValue` 注入 MockWsService：
/// ```dart
/// final container = ProviderContainer(overrides: [
///   wsServiceProvider.overrideWithValue(mockWsService),
/// ]);
/// ```
final wsServiceProvider = Provider<WsService>((ref) {
  return WsService();
});
