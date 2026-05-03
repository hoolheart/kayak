/// 登录视图层
///
/// 处理登录页面的UI展示
/// 使用 LoginCard 容器，品牌 Logo 区域，表单区域，注册链接

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/login_provider.dart';
import '../../auth/widgets/login_card.dart';
import '../../auth/widgets/login_form.dart';
import '../../auth/widgets/error_banner.dart';

/// 登录视图层组件
class LoginView extends ConsumerWidget {
  const LoginView({
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
    final loginState = ref.watch(loginProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 会话过期横幅（在卡片上方）
            if (sessionExpired)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ErrorBanner(
                  message: '会话已过期，请重新登录',
                  type: BannerType.warning,
                  onDismiss: () {},
                ),
              ),

            // 登录卡片
            LoginCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 品牌 Logo 区域
                  _buildLogoArea(context, colorScheme),
                  const SizedBox(height: 32),

                  // 登录表单
                  const LoginForm(),
                  const SizedBox(height: 20),

                  // 注册链接
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '还没有账号？',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('立即注册'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 错误横幅（在卡片下方）
            if (loginState.status == LoginStatus.error &&
                loginState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ErrorBanner(
                  message: loginState.errorMessage!,
                  onDismiss: () {
                    ref.read(loginProvider.notifier).reset();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 品牌 Logo 区域
  Widget _buildLogoArea(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo 图标容器
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.science,
            size: 48,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),

        // 品牌名称
        Text(
          'KAYAK',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                letterSpacing: 4,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // 副标题
        Text(
          '科学研究支持平台',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
