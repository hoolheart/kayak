/// 表单验证器
///
/// 提供邮箱、密码等表单字段的验证逻辑

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 表单验证器
class Validators {
  Validators._();

  /// 邮箱正则表达式
  static final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// 验证邮箱
  ///
  /// [value] 邮箱字符串
  /// [required] 是否必填，默认true
  /// 返回错误消息或null
  static String? validateEmail(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? '邮箱不能为空' : null;
    }
    if (!emailRegex.hasMatch(value)) {
      return '邮箱格式无效';
    }
    return null;
  }

  /// 验证密码
  ///
  /// [value] 密码字符串
  /// [required] 是否必填，默认true
  /// 返回错误消息或null
  static String? validatePassword(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? '密码不能为空' : null;
    }
    if (value.length < 6) {
      return '密码至少6个字符';
    }
    return null;
  }
}

/// 邮箱验证状态Provider
final emailValidationProvider = StateProvider<String?>((ref) => null);

/// 密码验证状态Provider
final passwordValidationProvider = StateProvider<String?>((ref) => null);

/// 表单是否有效Provider
final isFormValidProvider = Provider<bool>((ref) {
  final emailError = ref.watch(emailValidationProvider);
  final passwordError = ref.watch(passwordValidationProvider);
  return emailError == null && passwordError == null;
});
