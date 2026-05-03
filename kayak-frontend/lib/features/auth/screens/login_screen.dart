/// 登录页面
///
/// 登录功能的主入口页面
/// 全屏品牌布局，不使用侧边栏包装

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_view.dart';

/// 登录页面主入口
///
/// 全屏独立页面，不包含 AppShell 侧边栏
class LoginScreen extends ConsumerWidget {
  const LoginScreen({
    super.key,
    this.redirectPath,
    this.sessionExpired = false,
  });

  /// 登录成功后重定向的路径
  final String? redirectPath;

  /// 会话是否已过期
  final bool sessionExpired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LoginView(
          redirectPath: redirectPath,
          sessionExpired: sessionExpired,
        ),
      ),
    );
  }
}
