import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'common.freezed.dart';
part 'common.g.dart';

// ============================================================
// ApiResponse<T> — 统一 API 响应格式
// ============================================================
@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required int code,
    required String message,
    required T data,
    String? timestamp,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
}

// ============================================================
// PaginatedResponse<T> — 分页响应
// ============================================================
@Freezed(genericArgumentFactories: true)
class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required int page,
    required int size,
    required int total,
    required List<T> items,
    @JsonKey(name: 'has_next') bool? hasNext,
    @JsonKey(name: 'has_prev') bool? hasPrev,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
}

// ============================================================
// AuthTokens — 认证令牌
// ============================================================
@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type') String? tokenType,
    @JsonKey(name: 'expires_in') int? expiresIn,
    required User user,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}
