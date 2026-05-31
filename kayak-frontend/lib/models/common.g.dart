// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiResponse<T> _$ApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _ApiResponse<T>(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  data: fromJsonT(json['data']),
  timestamp: json['timestamp'] as String?,
);

Map<String, dynamic> _$ApiResponseToJson<T>(
  _ApiResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': toJsonT(instance.data),
  'timestamp': instance.timestamp,
};

_PaginatedResponse<T> _$PaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _PaginatedResponse<T>(
  page: (json['page'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  items: (json['items'] as List<dynamic>).map(fromJsonT).toList(),
  hasNext: json['has_next'] as bool?,
  hasPrev: json['has_prev'] as bool?,
);

Map<String, dynamic> _$PaginatedResponseToJson<T>(
  _PaginatedResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'page': instance.page,
  'size': instance.size,
  'total': instance.total,
  'items': instance.items.map(toJsonT).toList(),
  'has_next': instance.hasNext,
  'has_prev': instance.hasPrev,
};

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  tokenType: json['token_type'] as String?,
  expiresIn: (json['expires_in'] as num?)?.toInt(),
  user: User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'user': instance.user,
    };
