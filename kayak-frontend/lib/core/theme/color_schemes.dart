/// Material Design 3 颜色方案定义
///
/// 使用种子颜色生成完整的ColorScheme
/// 浅色主题和深色主题分别定义

library;

import 'package:flutter/material.dart';

/// Material Design 3 颜色方案定义
class AppColorSchemes {
  AppColorSchemes._();

  // 品牌种子颜色
  static const Color seedColor = Color(0xFF6750A4);

  /// 浅色主题颜色方案
  static ColorScheme get light {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
    );
  }

  /// 深色主题颜色方案
  static ColorScheme get dark {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
  }

  /// 自定义扩展颜色（可选）
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
}
