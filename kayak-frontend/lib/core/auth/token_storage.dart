/// Token Storage Interface
///
/// 遵循依赖倒置原则，抽象Token存储实现
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// 工厂方法创建合适的存储实现
  static TokenStorageInterface create() {
    // 桌面平台(Linux/Windows/Mac)使用SharedPreferences，因为libsecret不可靠
    // 移动平台和Web使用flutter_secure_storage
    if (!kIsWeb) {
      if (Platform.isLinux) {
        debugPrint(
            'TokenStorage: Using SharedPrefsTokenStorage for Linux desktop');
        return SharedPrefsTokenStorage();
      } else if (Platform.isWindows) {
        debugPrint(
            'TokenStorage: Using SharedPrefsTokenStorage for Windows desktop');
        return SharedPrefsTokenStorage();
      } else if (Platform.isMacOS) {
        debugPrint(
            'TokenStorage: Using SharedPrefsTokenStorage for macOS desktop');
        return SharedPrefsTokenStorage();
      }
    }

    debugPrint('TokenStorage: Using SecureTokenStorage for mobile/Web');
    return SecureTokenStorage();
  }
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
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _expiryKey),
      ]);
    } catch (e) {
      // Ignore clear errors - tokens might not exist
    }
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

    // 如果 token 在5分钟内过期，就需要刷新
    final refreshThreshold = DateTime.now().add(const Duration(minutes: 5));
    return expiry.isBefore(refreshThreshold);
  }
}

/// SharedPreferences降级存储实现
///
/// 当flutter_secure_storage不可用时使用
/// 注意: 这个实现安全性较低，仅用于桌面平台降级
class SharedPrefsTokenStorage implements TokenStorageInterface {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiryKey = 'access_token_expiry';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final prefs = await _preferences;
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
      prefs.setString(_expiryKey, expiryTime.toIso8601String()),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await _preferences;
    return prefs.getString(_accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await _preferences;
    return prefs.getString(_refreshTokenKey);
  }

  @override
  Future<DateTime?> getAccessTokenExpiry() async {
    final prefs = await _preferences;
    final expiryStr = prefs.getString(_expiryKey);
    if (expiryStr == null) return null;
    return DateTime.tryParse(expiryStr);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await _preferences;
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_expiryKey),
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

    // 如果 token 在5分钟内过期，就需要刷新
    final refreshThreshold = DateTime.now().add(const Duration(minutes: 5));
    return expiry.isBefore(refreshThreshold);
  }
}
