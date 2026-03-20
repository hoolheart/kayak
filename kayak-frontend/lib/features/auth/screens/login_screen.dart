/// 登录页面
///
/// 登录功能的主入口页面

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_view.dart';

/// 登录页面主入口
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
    return Scaffold(
      body: SafeArea(
        child: LoginView(
          redirectPath: redirectPath,
          sessionExpired: sessionExpired,
        ),
      ),
    );
  }
}
