/// Auth API Service Interface
///
/// 定义认证相关API的抽象，遵循依赖倒置原则
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_state.dart';

abstract class AuthApiServiceInterface {
  /// 登录
  Future<LoginResponse> login(String email, String password);

  /// 注册
  Future<void> register(String email, String password, [String? username]);

  /// 刷新Token
  Future<TokenPair> refreshToken(String refreshToken);

  /// 获取当前用户信息
  Future<User> getCurrentUser(String accessToken);
}

/// 认证API服务实现
///
/// 实现AuthApiServiceInterface接口
class AuthApiService implements AuthApiServiceInterface {
  final Dio _dio;
  final String _baseUrl;

  AuthApiService({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  @override
  Future<LoginResponse> login(String email, String password) async {
    final url = '$_baseUrl/api/v1/auth/login';
    debugPrint('AuthApiService: Attempting login to $url with email: $email');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: {'email': email, 'password': password},
      );
      debugPrint(
          'AuthApiService: Login successful, response: ${response.data}');
      final responseData = response.data as Map<String, dynamic>;
      return LoginResponse.fromJson(
          responseData['data'] as Map<String, dynamic>);
    } catch (e, st) {
      debugPrint('AuthApiService: Login failed with error: $e');
      debugPrint('AuthApiService: Stack trace: $st');
      rethrow;
    }
  }

  @override
  Future<void> register(String email, String password,
      [String? username]) async {
    final url = '$_baseUrl/api/v1/auth/register';
    debugPrint(
        'AuthApiService: Attempting register to $url with email: $email');
    try {
      final response = await _dio.post(
        url,
        data: {
          'email': email,
          'password': password,
          if (username != null) 'username': username,
        },
      );
      debugPrint(
          'AuthApiService: Register successful, response: ${response.data}');
    } catch (e, st) {
      debugPrint('AuthApiService: Register failed with error: $e');
      debugPrint('AuthApiService: Stack trace: $st');
      rethrow;
    }
  }

  @override
  Future<TokenPair> refreshToken(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/api/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    final responseData = response.data as Map<String, dynamic>;
    return TokenPair.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  @override
  Future<User> getCurrentUser(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/api/v1/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );

    final responseData = response.data as Map<String, dynamic>;
    return User.fromJson(responseData['data'] as Map<String, dynamic>);
  }
}
