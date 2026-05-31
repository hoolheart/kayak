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
import '../providers/auth_provider.dart';
import '../widgets/app_shell.dart';

/// GoRouter 实例提供者
///
/// 路由守卫监听 [authProvider] 状态，根据认证状态决定页面跳转。
/// - 未认证访问受保护页面 → 重定向到 `/login`
/// - 已认证访问 `/login` 或 `/register` → 重定向到 `/dashboard`
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.asData?.value != null;
      final onLogin = state.matchedLocation == '/login';
      final onRegister = state.matchedLocation == '/register';

      // 未登录 + 非公共页面 → 跳转登录页，保存原始 URL
      if (!loggedIn && !onLogin && !onRegister) {
        final redirect = Uri.encodeComponent(state.uri.toString());
        return '/login?redirect=$redirect';
      }

      // 已登录 + 在登录/注册页 → 跳转回原始 URL 或首页
      if (loggedIn && (onLogin || onRegister)) {
        final redirectParam = state.uri.queryParameters['redirect'];
        if (redirectParam != null && redirectParam.isNotEmpty) {
          final decoded = Uri.decodeComponent(redirectParam);
          if (decoded.isNotEmpty && decoded != '/login' && decoded != '/register') {
            return decoded;
          }
        }
        return '/dashboard';
      }

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
