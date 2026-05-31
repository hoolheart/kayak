import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_view.dart';
import 'auth_widgets.dart';

/// 注册页面。
///
/// 提供邮箱 + 密码 + 用户名（选填）注册，使用 Material 3 设计。
/// 包含实时密码强度指示器和要求检查列表。
/// 响应式布局：桌面居中卡片（maxWidth: 420），移动端全屏。
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 邮箱格式验证。
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.emailRequired;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.emailFormatError;
    }
    return null;
  }

  /// 密码验证。
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.passwordRequired;
    }
    if (value.length < 6) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.passwordMinLengthError;
    }
    return null;
  }

  /// 确认密码验证。
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.passwordRequired;
    }
    if (value != _passwordController.text) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.passwordsDoNotMatch;
    }
    return null;
  }

  /// 用户名验证（选填）。
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // 选填
    }
    final localizations = AppLocalizations.of(context)!;
    if (value.length < 3 || value.length > 30) {
      return localizations.usernameLengthError;
    }
    final validChars = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validChars.hasMatch(value)) {
      return localizations.usernameInvalidChars;
    }
    return null;
  }

  /// 处理注册提交。
  ///
  /// 1. 表单验证
  /// 2. 确认密码一致
  /// 3. 调用 AuthNotifier.register
  /// 4. 成功则自动登录并跳转仪表盘
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.passwordsDoNotMatch),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(authProvider.notifier).register(
      _emailController.text.trim(),
      _passwordController.text,
      _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
    );
  }

  /// 密码强度计算。
  double _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    double score = 0;
    if (password.length >= 6) score += 0.25;
    if (password.length >= 10) score += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) score += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) score += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.2;
    return score.clamp(0.0, 1.0);
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
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // ── 密码输入 ──
                  PasswordField(
                    controller: _passwordController,
                    enabled: !isLoading,
                    validator: _validatePassword,
                  ),

                  // ── 密码强度指示器 ──
                  PasswordStrengthIndicator(
                    strength: _calculateStrength(_passwordController.text),
                    password: _passwordController.text,
                  ),
                  const SizedBox(height: 16),

                  // ── 确认密码输入 ──
                  _buildConfirmPasswordField(localizations, colorScheme, isLoading),
                  const SizedBox(height: 16),

                  // ── 用户名输入（选填） ──
                  _buildUsernameField(localizations, colorScheme, isLoading),
                  const SizedBox(height: 24),

                  // ── 注册按钮 ──
                  AuthSubmitButton(
                    isLoading: isLoading,
                    onPressed: _handleRegister,
                    label: localizations.register,
                  ),
                  const SizedBox(height: 16),

                  // ── 登录链接 ──
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go('/login'),
                    child: Text(localizations.hasAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 确认密码输入框。
  Widget _buildConfirmPasswordField(
    AppLocalizations localizations,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return TextFormField(
      controller: _confirmPasswordController,
      enabled: !isLoading,
      obscureText: _obscureConfirm,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: localizations.confirmPassword,
        hintText: localizations.confirmPasswordHint,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () => setState(
            () => _obscureConfirm = !_obscureConfirm,
          ),
          tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
        ),
      ),
      validator: _validateConfirmPassword,
    );
  }

  /// 用户名字段（选填）。
  Widget _buildUsernameField(
    AppLocalizations localizations,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return TextFormField(
      controller: _usernameController,
      enabled: !isLoading,
      keyboardType: TextInputType.text,
      autofillHints: const [AutofillHints.username],
      decoration: InputDecoration(
        labelText: localizations.usernameOptional,
        hintText: localizations.usernameHint,
        helperText: localizations.usernameHelper,
        prefixIcon: const Icon(Icons.person_outlined),
      ),
      validator: _validateUsername,
    );
  }
}
