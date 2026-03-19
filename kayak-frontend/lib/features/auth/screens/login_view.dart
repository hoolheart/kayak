/// 登录视图层
///
/// 处理登录页面的UI展示

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../providers/login_provider.dart';
import '../widgets/login_form.dart';
import '../widgets/error_banner.dart';

/// 登录视图层组件
class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 监听登录成功状态，跳转到首页
    ref.listen<LoginState>(loginProvider, (previous, next) {
      if (next.status == LoginStatus.success) {
        context.go(AppRoutes.home);
      }
    });

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Icon(
                Icons.science,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // 标题
              Text(
                '欢迎使用 Kayak',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 登录表单
              const LoginForm(),

              // 错误横幅 (当有错误时显示)
              if (loginState.status == LoginStatus.error)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ErrorBanner(
                    message: loginState.errorMessage ?? '发生错误',
                    onRetry: () {
                      ref.read(loginProvider.notifier).reset();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
