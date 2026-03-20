/// Auth Route Guard
///
/// 路由守卫实现，保护需要认证的路由
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_state.dart';
import 'providers.dart';

/// 路由名称常量
class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String home = 'home';
  static const String workbench = 'workbench';
  static const String workbenchDetail = 'workbench-detail';
  static const String device = 'device';
}

/// 公共路由 - 无需认证即可访问
final publicRoutes = <String>{
  '/login',
  '/splash',
};

/// 受保护路由 - 需要认证才能访问
final protectedRoutes = <String>{
  '/home',
  '/workbench',
  '/workbench/:id',
  '/device',
  '/device/:id',
};

/// 检查路由是否需要认证
bool isProtectedRoute(String path) {
  // 精确匹配
  if (protectedRoutes.contains(path)) return true;

  // 路径前缀匹配 (例如 /workbench/123 匹配 /workbench/:id)
  for (final route in protectedRoutes) {
    if (route.contains(':')) {
      final baseRoute = route.split('/:').first;
      if (path.startsWith('$baseRoute/') && path != baseRoute) {
        return true;
      }
    }
  }
  return false;
}

/// 检查用户是否已认证
bool isAuthenticated(AuthState authState) => authState.isAuthenticated;

/// 会话过期消息参数键
const sessionExpiredKey = 'session_expired';

/// Auth Route Guard Provider
///
/// 用于在路由变化时检查认证状态
final authRouteGuardProvider = Provider<AuthRouteGuard>((ref) {
  return AuthRouteGuard(ref);
});

/// Auth Route Guard
///
/// 实现路由守卫逻辑
class AuthRouteGuard {
  final Ref _ref;

  AuthRouteGuard(this._ref);

  /// 路由重定向回调
  ///
  /// 在 go_router 的 redirect 回调中使用
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final path = state.uri.path;

    // 公共路由直接放行
    if (!isProtectedRoute(path)) {
      // 如果已登录且访问登录页，重定向到首页
      if (path == '/login' && isAuthenticated(authState)) {
        return '/home';
      }
      return null;
    }

    // 受保护路由检查认证状态
    if (!isAuthenticated(authState)) {
      // 未登录，重定向到登录页，传递原始路径
      final redirectPath = Uri.encodeComponent(path);
      return '/login?redirect=$redirectPath';
    }

    return null;
  }

  /// 获取登录后的重定向路径
  String? getRedirectPath(GoRouterState state) {
    return state.uri.queryParameters['redirect'];
  }
}

/// 响应式认证状态监听器
///
/// 用于让 go_router 响应认证状态变化
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
