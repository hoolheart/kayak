import 'package:flutter/material.dart';

/// Kayak 应用自定义颜色常量。
///
/// 这些颜色是 [ColorScheme] 的补充，服务于特定用途：
/// - 状态指示器颜色（成功/警告/错误）
/// - 日志级别颜色
/// - 其他需要固定颜色的场景
///
/// 大多数 UI 组件应使用 [ColorScheme] 中的颜色而非这些常量。
/// 仅在 [ColorScheme] 不能覆盖的特定语义场景使用。
class AppColors {
  AppColors._();

  /// 品牌主色 — 科技蓝
  static const Color primary = Color(0xFF1976D2);

  /// 信息提示蓝
  static const Color infoBlue = Color(0xFF2196F3);

  /// 成功状态绿
  static const Color successGreen = Color(0xFF4CAF50);

  /// 警告状态橙
  static const Color warningOrange = Color(0xFFFF9800);

  /// 错误状态红
  static const Color errorRed = Color(0xFFE53935);
}
