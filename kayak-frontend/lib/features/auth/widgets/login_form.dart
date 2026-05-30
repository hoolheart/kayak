/// 登录表单组件
///
/// 组合邮箱、密码输入框和登录按钮

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers.dart';
import '../../../validators/validators.dart';
import '../providers/login_provider.dart';
import 'email_field.dart';
import 'login_button.dart';
import 'password_field.dart';

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
            onSubmitted: (_) => _submitForm(),
          ),
          const SizedBox(height: 24),
          LoginButton(
            onPressed: isLoading ? null : _submitForm,
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    // 验证表单
    final emailError = Validators.validateEmail(_emailController.text.trim());
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

    // 提交登录 — 调用真实认证 API
    ref.read(loginProvider.notifier).setLoading();
    try {
      final authNotifier = ref.read(authStateNotifierProvider);
      final success = await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        ref.read(loginProvider.notifier).setSuccess();
      } else if (!success && mounted) {
        final authState = ref.read(authStateProvider);
        final errorType = _mapErrorToLoginErrorType(authState.error);
        ref.read(loginProvider.notifier).setError(errorType);
      }
    } catch (e) {
      if (mounted) {
        final errorType = _mapErrorToLoginErrorType(e.toString());
        ref.read(loginProvider.notifier).setError(errorType);
      }
    }
  }

  /// 将登录错误映射为用户可读的错误类型
  LoginErrorType _mapErrorToLoginErrorType(String? errorMessage) {
    if (errorMessage == null) return LoginErrorType.unknown;

    final message = errorMessage.toLowerCase();
    if (message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('invalid credential') ||
        message.contains('邮箱或密码错误')) {
      return LoginErrorType.invalidCredentials;
    }
    if (message.contains('connection refused') ||
        message.contains('socketerror') ||
        message.contains('sockettimeout') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('连接被拒绝') ||
        message.contains('网络')) {
      return LoginErrorType.networkError;
    }
    if (message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('bad gateway') ||
        message.contains('service unavailable') ||
        message.contains('server error') ||
        message.contains('internal server')) {
      return LoginErrorType.serverError;
    }
    return LoginErrorType.unknown;
  }
}
