/// 邮箱输入框组件
///
/// 提供邮箱输入功能，支持实时验证和错误提示

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../validators/validators.dart';

/// 邮箱输入框组件
class EmailField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  const EmailField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.enabled = true,
  });

  @override
  ConsumerState<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends ConsumerState<EmailField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) {
      final error = Validators.validateEmail(widget.controller.text);
      ref.read(emailValidationProvider.notifier).state = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorText = ref.watch(emailValidationProvider);

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: '邮箱',
        hintText: '请输入邮箱地址',
        prefixIcon: const Icon(Icons.email_outlined),
        errorText: errorText,
      ),
      onChanged: (_) {
        // 清除错误当用户开始输入
        if (errorText != null) {
          ref.read(emailValidationProvider.notifier).state = null;
        }
      },
    );
  }
}
