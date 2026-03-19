/// 密码输入框组件
///
/// 提供密码输入功能，支持密码可见性切换和实时验证

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../validators/validators.dart';

/// 密码输入框组件
class PasswordField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  ConsumerState<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends ConsumerState<PasswordField> {
  bool _obscureText = true; // 密码遮蔽状态，默认开启

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
      final error = Validators.validatePassword(widget.controller.text);
      ref.read(passwordValidationProvider.notifier).state = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorText = ref.watch(passwordValidationProvider);

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscureText, // 使用状态变量控制密码可见性
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: '密码',
        hintText: '请输入密码',
        prefixIcon: const Icon(Icons.lock_outlined),
        errorText: errorText,
        // 密码可见性切换按钮
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            semanticLabel: _obscureText ? '显示密码' : '隐藏密码',
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      onChanged: (_) {
        if (errorText != null) {
          ref.read(passwordValidationProvider.notifier).state = null;
        }
      },
      onFieldSubmitted: (_) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!('');
        }
      },
    );
  }
}
