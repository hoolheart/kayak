import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// TokenStorage — 封装 flutter_secure_storage 10.3.1
///
/// 提供 Access Token / Refresh Token 的安全读写。
/// Web 平台自动降级为 LocalStorage。
class TokenStorage {
  /// 创建 TokenStorage 实例
  ///
  /// [storage] 可选的 FlutterSecureStorage 实例（默认使用 `const`）
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// 保存 Access Token 和 Refresh Token
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// 读取 Access Token
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// 读取 Refresh Token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// 清除所有 Token
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}
