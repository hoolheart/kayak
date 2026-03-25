/// Auth State Notifier
///
/// 全局认证状态管理，使用Riverpod StateNotifier
/// 实现AuthStateNotifierInterface接口，依赖抽象而非具体实现
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'auth_notifier_interface.dart';
import 'auth_api_service.dart';
import 'token_storage.dart';

class AuthStateNotifier extends StateNotifier<AuthState>
    implements AuthStateNotifierInterface {
  final TokenStorageInterface _tokenStorage;
  final AuthApiServiceInterface _authApiService;

  AuthStateNotifier({
    required TokenStorageInterface tokenStorage,
    required AuthApiServiceInterface authApiService,
  })  : _tokenStorage = tokenStorage,
        _authApiService = authApiService,
        super(AuthState.initial());

  @override
  bool get isAuthenticated => state.isAuthenticated;

  @override
  User? get user => state.user;

  @override
  String? get accessToken => state.accessToken;

  @override
  bool get isLoading => state.isLoading;

  @override
  String? get error => state.error;

  /// 初始化认证状态
  ///
  /// 从安全存储恢复会话
  @override
  Future<void> initialize() async {
    if (state.isLoading) return;

    debugPrint('AuthStateNotifier.initialize: Starting');
    state = AuthState.loading();

    try {
      debugPrint('AuthStateNotifier.initialize: Getting tokens');
      final accessToken = await _tokenStorage.getAccessToken();
      final refreshToken = await _tokenStorage.getRefreshToken();
      debugPrint(
          'AuthStateNotifier.initialize: accessToken=${accessToken != null}, refreshToken=${refreshToken != null}');

      if (accessToken == null || refreshToken == null) {
        debugPrint('AuthStateNotifier.initialize: No tokens, going to initial');
        state = AuthState.initial();
        return;
      }

      // 检查Token是否需要刷新
      if (await _tokenStorage.shouldRefreshToken()) {
        debugPrint('AuthStateNotifier.initialize: Refreshing tokens');
        final success = await _refreshTokens();
        if (!success) {
          debugPrint('AuthStateNotifier.initialize: Refresh failed');
          await _tokenStorage.clearTokens();
          state = AuthState.initial();
          return;
        }
      }

      // 获取新的access token
      final currentAccessToken = await _tokenStorage.getAccessToken();
      if (currentAccessToken == null) {
        debugPrint('AuthStateNotifier.initialize: No current access token');
        state = AuthState.initial();
        return;
      }

      // 获取用户信息
      debugPrint('AuthStateNotifier.initialize: Fetching user with token');
      final user = await _fetchCurrentUser(currentAccessToken);
      debugPrint('AuthStateNotifier.initialize: User fetched: ${user != null}');

      if (user != null) {
        state = AuthState.authenticated(user, currentAccessToken);
        debugPrint('AuthStateNotifier.initialize: SUCCESS');
      } else {
        debugPrint('AuthStateNotifier.initialize: No user, going to initial');
        await _tokenStorage.clearTokens();
        state = AuthState.initial();
      }
    } catch (e, st) {
      debugPrint('AuthStateNotifier.initialize: EXCEPTION: $e');
      debugPrint('AuthStateNotifier.initialize: Stack: $st');
      await _tokenStorage.clearTokens();
      state = AuthState.initial();
    }
  }

  /// 登录
  @override
  Future<bool> login(String email, String password) async {
    state = AuthState.loading();

    try {
      final response = await _authApiService.login(email, password);

      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
      );

      final user = User(
        id: response.userId,
        email: email,
        username: response.username,
      );

      state = AuthState.authenticated(user, response.accessToken);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// 注册
  @override
  Future<bool> register(String email, String password,
      [String? username]) async {
    state = AuthState.loading();

    try {
      await _authApiService.register(email, password, username);
      state = AuthState.initial();
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// 登出
  @override
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    state = AuthState.initial();
  }

  /// 设置认证状态
  @override
  void setAuthenticated(User user, String accessToken) {
    state = AuthState.authenticated(user, accessToken);
  }

  /// 清除认证状态
  @override
  void clearAuthentication() {
    _tokenStorage.clearTokens();
    state = AuthState.initial();
  }

  /// 刷新Token
  Future<bool> _refreshTokens() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _authApiService.refreshToken(refreshToken);

      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取当前用户信息
  Future<User?> _fetchCurrentUser(String accessToken) async {
    try {
      return await _authApiService.getCurrentUser(accessToken);
    } catch (e) {
      return null;
    }
  }
}
