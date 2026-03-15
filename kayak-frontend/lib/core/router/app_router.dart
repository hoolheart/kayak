/// 应用路由配置
///
/// 定义所有应用路由和导航配置
/// 使用go_router实现声明式路由

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home_screen.dart';
import '../../screens/splash_screen.dart';

/// 应用路由路径常量
class AppRoutes {
  AppRoutes._();

  /// 启动页
  static const String splash = '/';

  /// 首页
  static const String home = '/home';
}

/// 路由Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true, // 开发环境启用路由日志
    routes: [
      // 启动页
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
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
