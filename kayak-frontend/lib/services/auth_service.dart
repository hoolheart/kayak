import 'package:dio/dio.dart';

import '../models/common.dart';
import '../models/user.dart';
import 'token_storage.dart';

/// AuthService — 认证服务
///
/// 管理认证 Token 的生命周期，提供认证相关的 API 调用。
///
/// 设计说明:
///   AuthService 持有独立的 Dio 实例（_authDio），该实例不包含
///   AuthInterceptor，用于认证端点（login/register/refresh/getMe）。
///   这样可以避免 ApiClient → AuthInterceptor → AuthService
///   → ApiClient 的循环依赖，同时确保 refresh 请求不会再次被
///   AuthInterceptor 拦截导致无限循环。
class AuthService {
  /// 创建 AuthService 实例
  ///
  /// [baseUrl] API 基础地址
  /// [storage] Token 持久化存储
  AuthService({required String baseUrl, required TokenStorage storage})
    : _authDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ),
      _storage = storage;

  final Dio _authDio;
  final TokenStorage _storage;

  /// 内存中的 Access Token
  String? _accessToken;

  /// 内存中的 Refresh Token
  String? _refreshToken;

  /// 当前有效的 Access Token（从内存读取，非持久化）
  String? get accessToken => _accessToken;

  /// 从 TokenStorage 加载 Token 到内存
  ///
  /// 应在应用启动时调用，用于恢复之前的登录状态。
  Future<void> initialize() async {
    _accessToken = await _storage.getAccessToken();
    _refreshToken = await _storage.getRefreshToken();
  }

  /// 用户登录
  ///
  /// 调用 `POST /api/v1/auth/login`，成功后自动保存 Token。
  ///
  /// [email] 用户邮箱
  /// [password] 用户密码
  /// 返回 [AuthTokens] 包含 Access Token、Refresh Token 和用户信息
  Future<AuthTokens> login(String email, String password) async {
    final response = await _authDio.post(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );

    final apiResponse = ApiResponse<AuthTokens>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AuthTokens.fromJson(json as Map<String, dynamic>),
    );

    final tokens = apiResponse.data;
    await _saveTokens(tokens);
    return tokens;
  }

  /// 用户注册
  ///
  /// 调用 `POST /api/v1/auth/register`，成功后自动保存 Token。
  ///
  /// [email] 用户邮箱
  /// [password] 用户密码
  /// [username] 用户名（可选）
  /// 返回 [AuthTokens]
  Future<AuthTokens> register(
    String email,
    String password, [
    String? username,
  ]) async {
    final data = <String, dynamic>{'email': email, 'password': password};
    if (username != null && username.isNotEmpty) {
      data['username'] = username;
    }

    final response = await _authDio.post('/api/v1/auth/register', data: data);

    final apiResponse = ApiResponse<AuthTokens>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AuthTokens.fromJson(json as Map<String, dynamic>),
    );

    final tokens = apiResponse.data;
    await _saveTokens(tokens);
    return tokens;
  }

  /// 尝试刷新 Token
  ///
  /// 调用 `POST /api/v1/auth/refresh`，使用当前 Refresh Token。
  /// 如果刷新过程中发生任何异常，返回 false。
  ///
  /// 返回 true 表示刷新成功，false 表示失败。
  Future<bool> tryRefresh() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _authDio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': _refreshToken},
      );

      final apiResponse = ApiResponse<AuthTokens>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AuthTokens.fromJson(json as Map<String, dynamic>),
      );

      final tokens = apiResponse.data;
      await _saveTokens(tokens);
      return true;
    } catch (e) {
      // 刷新失败（网络错误、Refresh Token 过期等）
      // 记录日志以便调试
      // ignore: avoid_print
      print('AuthService.tryRefresh failed: $e');
      return false;
    }
  }

  /// 获取当前用户信息
  ///
  /// 调用 `GET /api/v1/auth/me`，需要有效的 Access Token。
  Future<User> getMe() async {
    final response = await _authDio.get(
      '/api/v1/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
    );

    final apiResponse = ApiResponse<User>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => User.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 登出
  ///
  /// 清除内存中的 Token 和持久化存储中的 Token。
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.clearTokens();
  }

  /// 保存 Token 到内存和持久化存储
  Future<void> _saveTokens(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }
}
