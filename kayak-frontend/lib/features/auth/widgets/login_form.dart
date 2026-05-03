/// 登录表单组件
///
/// 组合邮箱、密码输入框和登录按钮

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../validators/validators.dart';
import '../../../core/auth/providers.dart';
import '../providers/login_provider.dart';
import 'email_field.dart';
import 'password_field.dart';
import 'login_button.dart';

/// 登录表单组件
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loginProvider).status == LoginStatus.loading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmailField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            enabled: !isLoading,
            onSubmitted: (_) {
              _submitForm();
            },
          ),
          const SizedBox(height: 24),
          LoginButton(
            onPressed: isLoading
                ? null
                : () {
                    _submitForm();
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    // 验证表单
    final emailError = Validators.validateEmail(_emailController.text);
    final passwordError = Validators.validatePassword(_passwordController.text);

    if (emailError != null) {
      ref.read(emailValidationProvider.notifier).state = emailError;
      return;
    }
    if (passwordError != null) {
      ref.read(passwordValidationProvider.notifier).state = passwordError;
      return;
    }

    // 清除错误
    ref.read(emailValidationProvider.notifier).state = null;
    ref.read(passwordValidationProvider.notifier).state = null;

    // 提交登录
    ref.read(loginProvider.notifier).setLoading();

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      await ref.read(authStateNotifierProvider).login(email, password);
      // 登录成功后，AuthStateNotifier 会设置认证状态为已登录，
      // 路由器通过 AuthStateChangeNotifier 检测到状态变化后自动跳转到仪表盘
      if (mounted) {
        ref.read(loginProvider.notifier).setSuccess();
      }
    } catch (e) {
      if (mounted) {
        ref.read(loginProvider.notifier).setErrorMessage(e.toString());
      }
    }
  }
}
