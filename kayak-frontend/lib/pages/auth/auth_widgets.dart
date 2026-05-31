import 'package:flutter/material.dart';

import 'package:kayak_frontend/generated/app_localizations.dart';

/// 认证模块共享 Email 输入框。
///
/// 带前缀图标和键盘类型配置的 Outlined TextField。
class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.validator,
    this.labelText,
    this.hintText,
  });

  /// 文本控制器。
  final TextEditingController controller;

  /// 是否启用输入。
  final bool enabled;

  /// 验证器。
  final String? Function(String?)? validator;

  /// 标签文本，默认使用 AppLocalizations 的 email。
  final String? labelText;

  /// 提示文本，默认使用 AppLocalizations 的 emailHint。
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: labelText ?? localizations.email,
        hintText: hintText ?? localizations.emailHint,
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: validator,
    );
  }
}

/// 认证模块共享密码输入框。
///
/// 带前缀图标、显示/隐藏切换按钮的 Outlined TextField。
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.validator,
    this.labelText,
    this.hintText,
  });

  /// 文本控制器。
  final TextEditingController controller;

  /// 是否启用输入。
  final bool enabled;

  /// 验证器。
  final String? Function(String?)? validator;

  /// 标签文本，默认使用 AppLocalizations 的 password。
  final String? labelText;

  /// 提示文本，默认使用 AppLocalizations 的 passwordHint。
  final String? hintText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscureText,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.labelText ?? localizations.password,
        hintText: widget.hintText ?? localizations.passwordHint,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
          tooltip: _obscureText ? 'Show password' : 'Hide password',
        ),
      ),
      validator: widget.validator,
    );
  }
}

/// 认证模块共享提交按钮。
///
/// 支持加载状态的 FilledButton，加载时显示 CircularProgressIndicator。
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    this.isLoading = false,
    this.onPressed,
    this.label,
  });

  /// 是否处于加载状态。
  final bool isLoading;

  /// 点击回调，加载状态时不可点击。
  final VoidCallback? onPressed;

  /// 按钮文本，默认使用 AppLocalizations 的 login。
  final String? label;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                label ?? localizations.login,
                style: Theme.of(context).textTheme.labelLarge,
              ),
      ),
    );
  }
}
