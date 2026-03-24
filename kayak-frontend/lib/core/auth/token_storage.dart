/// Token Storage Interface
///
/// 遵循依赖倒置原则，抽象Token存储实现
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorageInterface {
  /// 保存Token对
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  });

  /// 获取Access Token
  Future<String?> getAccessToken();

  /// 获取Refresh Token
  Future<String?> getRefreshToken();

  /// 获取Token过期时间戳
  Future<DateTime?> getAccessTokenExpiry();

  /// 清除所有Token
  Future<void> clearTokens();

  /// 检查Access Token是否已过期
  Future<bool> isAccessTokenExpired();

  /// 检查是否需要刷新Token (过期前5分钟)
  Future<bool> shouldRefreshToken();
}

/// 安全Token存储实现
///
/// 使用 flutter_secure_storage 存储Token
class SecureTokenStorage implements TokenStorageInterface {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiryKey = 'access_token_expiry';

  final FlutterSecureStorage _secureStorage;

  SecureTokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    // 计算过期时间
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      _secureStorage.write(
        key: _expiryKey,
        value: expiryTime.toIso8601String(),
      ),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  @override
  Future<DateTime?> getAccessTokenExpiry() async {
    final expiryStr = await _secureStorage.read(key: _expiryKey);
    if (expiryStr == null) return null;
    return DateTime.tryParse(expiryStr);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _expiryKey),
    ]);
  }

  @override
  Future<bool> isAccessTokenExpired() async {
    final expiry = await getAccessTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  @override
  Future<bool> shouldRefreshToken() async {
    final expiry = await getAccessTokenExpiry();
    if (expiry == null) return true;

    // 提前5分钟刷新
    final refreshThreshold = DateTime.now().add(const Duration(minutes: 5));
    return refreshThreshold.isAfter(expiry);
  }
}
