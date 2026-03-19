/// 登录状态管理
///
/// 使用Riverpod管理登录状态、错误处理和导航

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../validators/validators.dart' show isFormValidProvider;

/// 登录状态枚举
enum LoginStatus {
  /// 空闲状态 - 初始状态
  idle,

  /// 加载状态 - 登录请求中
  loading,

  /// 成功状态 - 登录成功
  success,

  /// 错误状态 - 登录失败
  error,
}

/// 错误类型枚举
enum LoginErrorType {
  invalidCredentials, // 无效凭证 (401)
  networkError, // 网络错误
  serverError, // 服务器错误 (500)
  sessionExpired, // 会话过期
  unknown, // 未知错误
}

/// 登录状态数据类
class LoginState {
  final LoginStatus status;
  final String? errorMessage;
  final LoginErrorType? errorType;

  const LoginState({
    this.status = LoginStatus.idle,
    this.errorMessage,
    this.errorType,
  });

  /// 错误消息映射
  static String getErrorMessage(LoginErrorType type) {
    switch (type) {
      case LoginErrorType.invalidCredentials:
        return '邮箱或密码错误';
      case LoginErrorType.networkError:
        return '网络错误，请检查网络连接';
      case LoginErrorType.serverError:
        return '服务器错误，请稍后重试';
      case LoginErrorType.sessionExpired:
        return '会话已过期，请重新登录';
      case LoginErrorType.unknown:
        return '发生未知错误，请稍后重试';
    }
  }

  /// 状态工厂方法
  factory LoginState.idle() => const LoginState(status: LoginStatus.idle);

  factory LoginState.loading() => const LoginState(status: LoginStatus.loading);

  factory LoginState.success() => const LoginState(status: LoginStatus.success);

  factory LoginState.error(LoginErrorType type) => LoginState(
        status: LoginStatus.error,
        errorMessage: getErrorMessage(type),
        errorType: type,
      );
}

/// 登录状态Notifier
class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier() : super(LoginState.idle());

  void setLoading() => state = LoginState.loading();

  void setSuccess() => state = LoginState.success();

  void setError(LoginErrorType type) {
    state = LoginState.error(type);
  }

  void reset() => state = LoginState.idle();
}

/// 登录状态Provider
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier();
});

/// 登录按钮是否启用Provider
final isLoginButtonEnabledProvider = Provider<bool>((ref) {
  final status = ref.watch(loginProvider);
  final isFormValid = ref.watch(isFormValidProvider);
  return status.status != LoginStatus.loading && isFormValid;
});
