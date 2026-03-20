/// Auth State Notifier Interface
///
/// 定义全局认证状态的抽象接口，遵循依赖倒置原则
/// 不继承任何具体实现类（如StateNotifier）
import 'auth_state.dart';

abstract class AuthStateNotifierInterface {
  /// 是否已认证
  bool get isAuthenticated;

  /// 当前用户信息
  User? get user;

  /// Access Token
  String? get accessToken;

  /// 是否正在初始化
  bool get isLoading;

  /// 错误信息
  String? get error;

  /// 初始化认证状态 (从存储恢复)
  Future<void> initialize();

  /// 登录
  Future<bool> login(String email, String password);

  /// 登出
  Future<void> logout();

  /// 设置认证状态 (内部使用)
  void setAuthenticated(User user, String accessToken);

  /// 清除认证状态 (内部使用)
  void clearAuthentication();
}
