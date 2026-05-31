import 'package:json_annotation/json_annotation.dart';

import 'user.dart';

part 'common.g.dart';

// ============================================================
// ApiResponse<T> — 统一 API 响应格式
// ============================================================
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {

  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
    this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
  final int code;
  final String message;
  final T data;
  final String? timestamp;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  ApiResponse<T> copyWith({
    int? code,
    String? message,
    T? data,
    String? timestamp,
  }) {
    return ApiResponse<T>(
      code: code ?? this.code,
      message: message ?? this.message,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// ============================================================
// PaginatedResponse<T> — 分页响应
// ============================================================
@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> {

  const PaginatedResponse({
    required this.page,
    required this.size,
    required this.total,
    required this.items,
    this.hasNext,
    this.hasPrev,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
  final int page;
  final int size;
  final int total;
  final List<T> items;
  @JsonKey(name: 'has_next')
  final bool? hasNext;
  @JsonKey(name: 'has_prev')
  final bool? hasPrev;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);

  PaginatedResponse<T> copyWith({
    int? page,
    int? size,
    int? total,
    List<T>? items,
    bool? hasNext,
    bool? hasPrev,
  }) {
    return PaginatedResponse<T>(
      page: page ?? this.page,
      size: size ?? this.size,
      total: total ?? this.total,
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }
}

// ============================================================
// AuthTokens — 认证令牌
// ============================================================
@JsonSerializable()
class AuthTokens {

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType,
    this.expiresIn,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'token_type')
  final String? tokenType;
  @JsonKey(name: 'expires_in')
  final int? expiresIn;
  final User user;
  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresIn,
    User? user,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      user: user ?? this.user,
    );
  }
}
