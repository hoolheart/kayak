/// 应用路由配置
///
/// 定义所有应用路由和导航配置
/// 使用go_router实现声明式路由
/// 集成认证路由守卫

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../auth/auth_state.dart';
import '../auth/providers.dart';

/// 简单的启动页，后续可以替换为真正的SplashScreen
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化时恢复认证状态
    ref.watch(appInitializerProvider);

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// 应用路由路径常量
class AppRoutes {
  AppRoutes._();

  /// 启动页
  static const String splash = '/';

  /// 登录页
  static const String login = '/login';

  /// 首页
  static const String home = '/home';
}

/// Auth State Change Notifier
///
/// 用于通知路由刷新认证状态变化
class AuthStateChangeNotifier extends ChangeNotifier {
  AuthStateChangeNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// 路由Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true, // 开发环境启用路由日志
    refreshListenable: AuthStateChangeNotifier(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final path = state.uri.path;

      // 公共路由
      const publicRoutes = ['/login', '/'];
      final isPublicRoute = publicRoutes.contains(path);

      // 未登录访问受保护路由 -> 重定向到登录
      if (!isLoggedIn && !isPublicRoute) {
        final redirect = Uri.encodeComponent(path);
        return '/login?redirect=$redirect';
      }

      // 已登录访问登录页 -> 重定向到首页
      if (isLoggedIn && path == '/login') {
        return '/home';
      }

      return null;
    },
    routes: [
      // 启动页
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // 登录页
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final sessionExpired = state.uri.queryParameters['session_expired'];
          return LoginScreen(
            redirectPath: redirect,
            sessionExpired: sessionExpired == 'true',
          );
        },
      ),

      // 首页
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
});
