/// 登录页面
///
/// 登录功能的主入口页面

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_view.dart';

/// 登录页面主入口
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SafeArea(
        child: LoginView(),
      ),
    );
  }
}
