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
          tooltip: _obscureText
              ? localizations.showPassword
              : localizations.hidePassword,
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

/// 密码强度指示器。
///
/// 用于注册页面，展示密码强度等级（4段颜色条）和要求检查列表。
/// [strength] 范围 0.0 ~ 1.0，[password] 用于检查列表的实时更新。
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    required this.password,
  });

  /// 密码强度值，范围 0.0 ~ 1.0。
  final double strength;

  /// 当前密码文本，用于要求检查列表。
  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    if (strength <= 0) {
      return const SizedBox.shrink();
    }

    final (levelLabel, levelColor, filledSegments) = _getStrengthLevel(
      localizations: localizations,
      colorScheme: colorScheme,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 4 段颜色条 ──
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < filledSegments;
              final segmentColor = isFilled ? levelColor : colorScheme.surfaceContainerHighest;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index > 0 ? 4 : 0,
                    right: index < 3 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: segmentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),

          // ── 强度文字标签 ──
          Text(
            '${localizations.passwordStrength}: $levelLabel',
            style: theme.textTheme.labelMedium?.copyWith(
              color: levelColor,
            ),
          ),
          const SizedBox(height: 8),

          // ── 要求检查列表 ──
          _RequirementItem(
            met: password.length >= 8,
            label: localizations.passwordMinLength,
          ),
          const SizedBox(height: 4),
          _RequirementItem(
            met: _hasUppercase && _hasLowercase,
            label: localizations.passwordUppercaseLowercase,
          ),
          const SizedBox(height: 4),
          _RequirementItem(
            met: _hasDigit,
            label: localizations.passwordNumber,
          ),
          const SizedBox(height: 4),
          _RequirementItem(
            met: _hasSpecial,
            label: localizations.passwordSpecial,
          ),
        ],
      ),
    );
  }

  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  /// 根据强度值返回对应的等级标签、颜色和填充段数。
  (String, Color, int) _getStrengthLevel({
    required AppLocalizations localizations,
    required ColorScheme colorScheme,
  }) {
    if (strength > 0.80) {
      return (localizations.passwordStrengthStrong, colorScheme.primary, 4);
    } else if (strength > 0.60) {
      return (localizations.passwordStrengthGood, colorScheme.primary, 3);
    } else if (strength > 0.25) {
      return (localizations.passwordStrengthMedium, Colors.orange, 2);
    } else {
      return (localizations.passwordStrengthWeak, colorScheme.error, 1);
    }
  }
}

/// 密码要求检查项。
class _RequirementItem extends StatelessWidget {
  const _RequirementItem({
    required this.met,
    required this.label,
  });

  /// 是否满足要求。
  final bool met;

  /// 要求描述文本。
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: met ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
