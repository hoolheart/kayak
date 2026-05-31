import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 测试用的 MaterialApp 包装器
Widget wrapWithTheme({
  required Widget child,
  required ThemeData theme,
  ThemeData? darkTheme,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    theme: theme,
    darkTheme: darkTheme ?? theme,
    themeMode: themeMode,
    home: Scaffold(body: child),
  );
}

/// 创建测试用 GoRouter
///
/// [homeBuilder] 可选，用于自定义首页内容。默认为 SizedBox。
GoRouter createTestRouter({WidgetBuilder? homeBuilder}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            homeBuilder != null ? homeBuilder(context) : const SizedBox(),
      ),
    ],
  );
}
