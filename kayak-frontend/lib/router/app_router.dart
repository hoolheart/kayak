import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/analysis/analysis_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/experiment/experiment_console_page.dart';
import '../pages/experiment/experiment_create_page.dart';
import '../pages/experiment/experiment_list_page.dart';
import '../pages/method/method_edit_page.dart';
import '../pages/method/method_list_page.dart';
import '../pages/not_found_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/workbench/workbench_detail_page.dart';
import '../pages/workbench/workbench_list_page.dart';
import '../widgets/app_shell.dart';

/// GoRouter 实例提供者
///
/// 路由守卫需要从 authProvider 获取认证状态（TASK-008 实现）。
/// 当前使用 TODO 占位，待 TASK-008 完成后整合。
final routerProvider = Provider<GoRouter>((ref) {
  // TODO: 从 authProvider 获取认证状态
  // final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // TODO: 根据认证状态重定向。
      // 待 TASK-008 authProvider 就绪后，使用:
      //   final loggedIn = authState.isLoggedIn;
      //   if (loggedIn && (onLogin || onRegister)) return '/dashboard';
      final onLogin = state.matchedLocation == '/login';
      final onRegister = state.matchedLocation == '/register';

      // 未登录 + 非公开页面 → 去登录
      if (!onLogin && !onRegister) return '/login';

      // 其他情况 → 不重定向
      return null;
    },
    errorBuilder: (context, state) {
      return const NotFoundPage();
    },
    routes: [
      // ---- 公开路由（无需认证） ----
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // ---- 受保护路由（ShellRoute 包裹，共享 AppShell） ----
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/workbenches',
            name: 'workbenches',
            builder: (context, state) => const WorkbenchListPage(),
          ),
          GoRoute(
            path: '/workbenches/:id',
            name: 'workbench-detail',
            builder: (context, state) => WorkbenchDetailPage(
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/methods',
            name: 'methods',
            builder: (context, state) => const MethodListPage(),
          ),
          GoRoute(
            path: '/methods/:id/edit',
            name: 'method-edit',
            builder: (context, state) => MethodEditPage(
              id: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/experiments',
            name: 'experiments',
            builder: (context, state) => const ExperimentListPage(),
          ),
          // experiments/new 必须在 experiments/:id 之前注册
          // 确保静态路径优先匹配，避免 new 被 :id 参数捕获
          GoRoute(
            path: '/experiments/new',
            name: 'experiment-create',
            builder: (context, state) => const ExperimentCreatePage(),
          ),
          GoRoute(
            path: '/experiments/:id',
            name: 'experiment-console',
            builder: (context, state) => ExperimentConsolePage(
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/analysis',
            name: 'analysis',
            builder: (context, state) => const AnalysisPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
