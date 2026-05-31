import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_view.dart';
import 'auth_widgets.dart';

/// 登录页面。
///
/// 提供邮箱 + 密码认证登录，使用 Material 3 设计。
/// 响应式布局：桌面居中卡片（maxWidth: 420），移动端全屏。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 处理登录提交。
  ///
  /// 1. 表单验证（非空检查）
  /// 2. 调用 AuthNotifier.login
  /// 3. 成功则重定向由路由守卫处理
  /// 4. 失败则 ErrorView 显示错误消息
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref.read(authProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo + 标题 ──
                  Icon(
                    Icons.science_outlined,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.appTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── 错误提示 ──
                  if (authState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ErrorView(
                        title: authState.error.toString(),
                        showRetry: false,
                        compact: true,
                      ),
                    ),

                  // ── 邮箱输入 ──
                  EmailField(
                    controller: _emailController,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.emailRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── 密码输入 ──
                  PasswordField(
                    controller: _passwordController,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.passwordRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── 登录按钮 ──
                  AuthSubmitButton(
                    isLoading: isLoading,
                    onPressed: _handleLogin,
                    label: localizations.signIn,
                  ),
                  const SizedBox(height: 16),

                  // ── 注册链接 ──
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go('/register'),
                    child: Text(localizations.noAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
