/// User Model
class User {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'avatar_url': avatarUrl,
      };
}

/// Token响应模型
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}

/// 登录响应模型
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String userId;
  final String? username;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.userId,
    this.username,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Backend sends nested user object: { user: { id, email, username } }
    // Frontend expects flat structure with user_id at top level
    final userJson = json['user'] as Map<String, dynamic>?;

    // Extract user_id from nested user object or top-level field
    String userId;
    if (userJson != null && userJson['id'] != null) {
      userId = userJson['id'].toString();
    } else if (json['user_id'] != null) {
      userId = json['user_id'].toString();
    } else {
      throw FormatException('Login response missing user_id field: $json');
    }

    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      userId: userId,
      username: userJson?['username'] as String? ?? json['username'] as String?,
    );
  }
}

/// 认证状态
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? accessToken;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.accessToken,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? accessToken,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      error: error,
    );
  }

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(isLoading: true);

  factory AuthState.authenticated(User user, String accessToken) => AuthState(
        isAuthenticated: true,
        user: user,
        accessToken: accessToken,
      );

  factory AuthState.error(String message) => AuthState(error: message);
}
