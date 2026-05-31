import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

// ============================================================
// User — 用户实体
// ============================================================
@JsonSerializable()
class User {

  const User({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  final String id;
  final String email;
  final String? username;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// LoginRequest — 登录请求
// ============================================================
@JsonSerializable()
class LoginRequest {

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  final String email;
  final String password;
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  LoginRequest copyWith({
    String? email,
    String? password,
  }) {
    return LoginRequest(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}

// ============================================================
// RegisterRequest — 注册请求
// ============================================================
@JsonSerializable()
class RegisterRequest {

  const RegisterRequest({
    required this.email,
    required this.password,
    this.username,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  final String email;
  final String password;
  final String? username;
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  RegisterRequest copyWith({
    String? email,
    String? password,
    String? username,
  }) {
    return RegisterRequest(
      email: email ?? this.email,
      password: password ?? this.password,
      username: username ?? this.username,
    );
  }
}
