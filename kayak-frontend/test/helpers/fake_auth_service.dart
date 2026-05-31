import 'package:dio/dio.dart';

import 'package:kayak_frontend/models/common.dart';
import 'package:kayak_frontend/models/user.dart';
import 'package:kayak_frontend/services/auth_service.dart';

/// FakeAuthService — 用于 AuthNotifier 单元测试的 Fake AuthService
///
/// 提供完全可控的行为：成功/失败、延迟、调用计数、参数记录。
/// 实现了 [AuthService] 的所有公有接口。
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.hasToken = false,
    this.storedAccessToken,
    this.storedRefreshToken,
    this.loginFails = false,
    this.loginFailsOnFirstAttempt = false,
    this.loginDelay,
    this.registerFails = false,
    this.registerDelay,
    this.registerError,
    this.refreshFails = false,
    this.refreshSucceeds = true,
    this.networkError = false,
    this.serverError = false,
    this.serverStatusCode,
    this.tokenExpiresIn,
    this.initializeFails = false,
    this.initializeDelay,
    this.getMeFails = false,
    this.getMeReturnsValid = true,
  });

  // ========== 配置参数 ==========
  final bool hasToken;
  final String? storedAccessToken;
  final String? storedRefreshToken;
  final bool loginFails;
  final bool loginFailsOnFirstAttempt;
  final Duration? loginDelay;
  final bool registerFails;
  final Duration? registerDelay;
  final String? registerError;
  final bool refreshFails;
  final bool refreshSucceeds;
  final bool networkError;
  final bool serverError;
  final int? serverStatusCode;
  final int? tokenExpiresIn;
  final bool initializeFails;
  final Duration? initializeDelay;
  final bool getMeFails;
  final bool getMeReturnsValid;

  // ========== 可观测状态 ==========
  String? _accessToken;
  String? _refreshToken;
  int initializeCallCount = 0;
  int loginCallCount = 0;
  int registerCallCount = 0;
  int tryRefreshCallCount = 0;
  int getMeCallCount = 0;
  int logoutCallCount = 0;
  bool saveTokensCalled = false;
  bool tokensCleared = false;
  bool tokensUpdated = false;
  bool logoutCalled = false;
  bool refreshTimerActive = false;
  int loginFailCount = 0;

  String? lastLoginEmail;
  String? lastLoginPassword;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastRegisterUsername;

  @override
  String? get accessToken => _accessToken;

  /// 重置可观测状态（用于多轮测试场景）
  void reset() {
    loginCallCount = 0;
    registerCallCount = 0;
    tryRefreshCallCount = 0;
    logoutCallCount = 0;
    lastLoginEmail = null;
    lastLoginPassword = null;
    lastRegisterEmail = null;
    lastRegisterPassword = null;
    lastRegisterUsername = null;
    saveTokensCalled = false;
    tokensCleared = false;
    tokensUpdated = false;
    logoutCalled = false;
  }

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (initializeFails) {
      throw Exception('TokenStorage unavailable');
    }
    if (initializeDelay != null) {
      await Future.delayed(initializeDelay!);
    }
    if (hasToken) {
      _accessToken = storedAccessToken ?? 'stored-access-token';
      _refreshToken = storedRefreshToken ?? 'stored-refresh-token';
    }
  }

  @override
  Future<AuthTokens> login(String email, String password) async {
    loginCallCount++;
    lastLoginEmail = email;
    lastLoginPassword = password;

    if (loginDelay != null) await Future.delayed(loginDelay!);

    if (loginFailsOnFirstAttempt && loginFailCount == 0) {
      loginFailCount++;
      throw Exception('Invalid credentials');
    }
    if (loginFails) {
      throw Exception('Login failed');
    }
    if (networkError) {
      throw DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
    }
    if (serverError) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: serverStatusCode ?? 500,
        ),
      );
    }

    _accessToken = 'new-access-token';
    _refreshToken = 'new-refresh-token';
    saveTokensCalled = true;
    return AuthTokens(
      accessToken: _accessToken!,
      refreshToken: _refreshToken!,
      tokenType: 'Bearer',
      expiresIn: tokenExpiresIn ?? 3600,
      user: User(
        id: 'test-user-id',
        email: email,
        username: email.split('@').first,
        status: 'active',
        createdAt: DateTime(2026, 5, 31),
        updatedAt: DateTime(2026, 5, 31),
      ),
    );
  }

  @override
  Future<AuthTokens> register(
    String email,
    String password, [
    String? username,
  ]) async {
    registerCallCount++;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    lastRegisterUsername = username;

    if (registerDelay != null) await Future.delayed(registerDelay!);
    if (registerFails) throw Exception(registerError ?? 'Registration failed');

    _accessToken = 'access-token-after-register';
    _refreshToken = 'refresh-token-after-register';
    saveTokensCalled = true;
    return AuthTokens(
      accessToken: _accessToken!,
      refreshToken: _refreshToken!,
      tokenType: 'Bearer',
      expiresIn: tokenExpiresIn ?? 3600,
      user: User(
        id: 'new-user-id',
        email: email,
        username: username ?? email.split('@').first,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> tryRefresh() async {
    tryRefreshCallCount++;
    if (refreshFails) return false;
    if (!refreshSucceeds) return false;
    _accessToken = 'refreshed-access-token';
    _refreshToken = 'refreshed-refresh-token';
    tokensUpdated = true;
    return true;
  }

  @override
  Future<User> getMe() async {
    getMeCallCount++;
    if (getMeFails) throw Exception('Failed to fetch user');
    if (!getMeReturnsValid) throw Exception('User not found');
    return User(
      id: 'test-user-id',
      email: 'admin@kayak.local',
      username: 'Admin',
      status: 'active',
      createdAt: DateTime(2026, 5, 31),
      updatedAt: DateTime(2026, 5, 31),
    );
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    logoutCalled = true;
    _accessToken = null;
    _refreshToken = null;
    tokensCleared = true;
    refreshTimerActive = false;
  }
}
