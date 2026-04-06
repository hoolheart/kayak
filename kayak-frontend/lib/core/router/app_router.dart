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
import '../../features/auth/screens/register_screen.dart';
import '../../features/experiments/screens/experiment_list_page.dart';
import '../../features/experiments/screens/experiment_console_page.dart';
import '../../features/methods/screens/method_list_page.dart';
import '../../features/methods/screens/method_edit_page.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/settings/settings_page.dart';
import '../navigation/app_shell.dart';
import '../auth/providers.dart';

/// 启动页 - 负责初始化认证状态并导航
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _initialized = false;
  bool _navigated = false; // 防止重复导航

  @override
  void initState() {
    super.initState();
    // 使用addPostFrameCallback在第一帧渲染后初始化，避免在build期间修改状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    if (_initialized) return; // Prevent double initialization
    _initialized = true;

    try {
      debugPrint('SplashScreen: Starting auth initialization...');
      final authNotifier = ref.read(authStateNotifierProvider);
      debugPrint('SplashScreen: Got authNotifier, calling initialize...');
      await authNotifier.initialize();
      debugPrint('SplashScreen: Auth initialization complete');
    } catch (e, stack) {
      debugPrint('SplashScreen: Auth initialization failed: $e');
      debugPrint('Stack: $stack');
    }

    // 触发重建
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听 auth state 变化
    final authState = ref.watch(authStateProvider);

    // 初始化完成后只导航一次
    if (_initialized && !_navigated) {
      _navigated = true;
      final targetPath =
          authState.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login;

      debugPrint('SplashScreen: Navigating to $targetPath');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(targetPath);
        }
      });
    }

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing...'),
          ],
        ),
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

  /// 仪表盘（首页）
  static const String dashboard = '/dashboard';
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
      debugPrint('Router redirect: isLoggedIn=$isLoggedIn, path=$path');

      // 公共路由
      const publicRoutes = ['/login', '/register', '/'];
      final isPublicRoute = publicRoutes.contains(path);

      // 未登录访问受保护路由 -> 重定向到登录
      if (!isLoggedIn && !isPublicRoute) {
        final redirect = Uri.encodeComponent(path);
        debugPrint('Router redirect: -> /login (unauthenticated)');
        return '/login?redirect=$redirect';
      }

      // 已登录访问登录页 -> 重定向到首页
      if (isLoggedIn && path == '/login') {
        debugPrint('Router redirect: -> /dashboard (already logged in)');
        return AppRoutes.dashboard;
      }

      // /home 旧路由重定向到 /dashboard
      if (path == '/home') {
        return AppRoutes.dashboard;
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

      // 注册页
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 首页 - 使用 AppShell 包装
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            selectedRoute: state.uri.path,
            child: child,
          );
        },
        routes: [
          // 仪表盘
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          // 工作台
          GoRoute(
            path: '/workbenches',
            builder: (context, state) => const Scaffold(
              body: Center(
                child: Text('工作台页面 - 开发中'),
              ),
            ),
          ),
          // 试验
          GoRoute(
            path: '/experiments',
            builder: (context, state) => const ExperimentListPage(),
          ),
          GoRoute(
            path: '/experiments/console',
            builder: (context, state) => const ExperimentConsolePage(),
          ),
          GoRoute(
            path: '/experiments/:id/console',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ExperimentConsolePage(experimentId: id);
            },
          ),
          // 方法
          GoRoute(
            path: '/methods',
            builder: (context, state) => const MethodListPage(),
          ),
          GoRoute(
            path: '/methods/create',
            builder: (context, state) => const MethodEditPage(),
          ),
          GoRoute(
            path: '/methods/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MethodEditPage(methodId: id);
            },
          ),
          // 设置
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
});
