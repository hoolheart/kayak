import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/token_storage.dart';

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
