import 'package:flutter/material.dart';

/// Kayak 应用文字样式配置。
class AppTypography {
  AppTypography._();

  /// 等宽字体样式，用于代码/测点值/日志显示。
  ///
  /// 使用 RobotoMono 字体，如果设备不支持则回退到通用 monospace。
  static const TextStyle monospace = TextStyle(
    fontFamily: 'RobotoMono',
    fontFamilyFallback: ['monospace'],
  );
}
