/// 登录按钮组件
///
/// 提供登录按钮功能，支持加载状态显示

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/login_provider.dart';

/// 登录按钮组件
class LoginButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const LoginButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(loginProvider).status == LoginStatus.loading;
    final isEnabled = ref.watch(isLoginButtonEnabledProvider);

    return SizedBox(
      height: 56, // MD3 按钮高度
      child: FilledButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : const Text('登录'),
      ),
    );
  }
}
