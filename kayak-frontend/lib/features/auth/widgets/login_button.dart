/// 登录按钮组件
///
/// 提供登录按钮功能，支持加载状态显示
/// Figma规格：48px 高度，全宽 Primary 填充
/// 状态: Default / Loading / Disabled

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/login_provider.dart';

/// 登录按钮组件
class LoginButton extends ConsumerWidget {
  const LoginButton({
    super.key,
    this.onPressed,
  });
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.status == LoginStatus.loading;
    final isEnabled = ref.watch(isLoginButtonEnabledProvider);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : const Text(
                  '登录',
                  key: ValueKey('label'),
                ),
        ),
      ),
    );
  }
}
