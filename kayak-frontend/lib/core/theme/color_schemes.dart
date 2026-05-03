/// Material Design 3 颜色方案定义 v2
///
/// 使用科技蓝 #1976D2 作为主色
/// 浅色主题和深色主题分别定义
/// 符合设计规范 v2 (design_spec_v2.md)

library;

import 'package:flutter/material.dart';

/// Material Design 3 颜色方案定义 v2
class AppColorSchemes {
  AppColorSchemes._();

  /// 品牌种子颜色 - 科技蓝
  static const Color seedColor = Color(0xFF1976D2);

  /// 浅色主题颜色方案
  ///
  /// 严格按照设计规范 v2 第 2.6 节定义
  static ColorScheme get light {
    return const ColorScheme(
      brightness: Brightness.light,

      // 主色调 - 科技蓝
      primary: Color(0xFF1976D2),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFBBDEFB),
      onPrimaryContainer: Color(0xFF1565C0),

      // 辅色调 - 中性灰
      secondary: Color(0xFF546E7A),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFECEFF1),
      onSecondaryContainer: Color(0xFF37474F),

      // 第三色调 - 青色
      tertiary: Color(0xFF00838F),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE0F7FA),
      onTertiaryContainer: Color(0xFF006064),

      // 语义色 - 错误
      error: Color(0xFFC62828),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: Color(0xFFB71C1C),

      // 语义色 - 成功、警告、信息 (使用 tertiary/error slot 等映射)
      // 注意: Flutter内置ColorScheme不直接支持success/warning/info
      // 这些颜色通过扩展属性或单独常量访问

      // 中性色 - 表面
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF212121),
      onSurfaceVariant: Color(0xFF757575),
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFEEEEEE),

      // surfaceContainer系列
      surfaceContainerHighest: Color(0xFFBDBDBD),

      // 其他
      inverseSurface: Color(0xFF212121),
      onInverseSurface: Color(0xFFF5F5F5),
      inversePrimary: Color(0xFF90CAF9),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );
  }

  /// 深色主题颜色方案
  ///
  /// 严格按照设计规范 v2 第 2.6 节定义
  static ColorScheme get dark {
    return const ColorScheme(
      brightness: Brightness.dark,

      // 主色调 - 科技蓝
      primary: Color(0xFF90CAF9),
      onPrimary: Color(0xFF000000),
      primaryContainer: Color(0xFF1565C0),
      onPrimaryContainer: Color(0xFFE3F2FD),

      // 辅色调 - 中性灰
      secondary: Color(0xFF90A4AE),
      onSecondary: Color(0xFF000000),
      secondaryContainer: Color(0xFF37474F),
      onSecondaryContainer: Color(0xFFCFD8DC),

      // 第三色调 - 青色
      tertiary: Color(0xFF80DEEA),
      onTertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFF006064),
      onTertiaryContainer: Color(0xFFE0F7FA),

      // 语义色 - 错误
      error: Color(0xFFEF5350),
      onError: Color(0xFF000000),
      errorContainer: Color(0xFFB71C1C),
      onErrorContainer: Color(0xFFFFEBEE),

      // 中性色 - 表面
      surface: Color(0xFF121212),
      onSurface: Color(0xFFF5F5F5),
      onSurfaceVariant: Color(0xFF9E9E9E),
      outline: Color(0xFF424242),
      outlineVariant: Color(0xFF333333),

      // surfaceContainer系列
      surfaceContainerHighest: Color(0xFF4D4D4D),

      // 其他
      inverseSurface: Color(0xFFF5F5F5),
      onInverseSurface: Color(0xFF212121),
      inversePrimary: Color(0xFF1976D2),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );
  }

  // 扩展自定义颜色（ColorScheme 不直接支持的语义色）

  /// 成功状态色
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF66BB6A);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color successContainerDark = Color(0xFF1B5E20);

  /// 警告状态色
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color warningContainerDark = Color(0xFFE65100);

  /// 错误状态色（别名，保持兼容性）
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color errorContainerDark = Color(0xFFB71C1C);

  /// 信息状态色
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFF90CAF9);
  static const Color infoContainer = Color(0xFFE3F2FD);
  static const Color infoContainerDark = Color(0xFF0D47A1);

  /// Surface Container 层级颜色（浅色主题）
  static const Color surfaceContainerLowest = Color(0xFFFAFAFA);
  static const Color surfaceContainerLow = Color(0xFFF5F5F5);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE0E0E0);
  // surfaceContainerHighest 已在上方ColorScheme中定义

  /// Surface Container 层级颜色（深色主题）
  static const Color darkSurfaceContainerLowest = Color(0xFF0A0A0A);
  static const Color darkSurfaceContainerLow = Color(0xFF1E1E1E);
  static const Color darkSurfaceContainer = Color(0xFF2D2D2D);
  static const Color darkSurfaceContainerHigh = Color(0xFF3D3D3D);
  // darkSurfaceContainerHighest 已在上方ColorScheme中定义

  /// 主色变体（用于悬停/按下状态）
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color primaryVariantLight = Color(0xFF64B5F6);
}

/// 扩展 ColorScheme 以支持自定义语义色
///
/// Flutter 内置 ColorScheme 不直接支持 success/warning/info 等语义色。
/// 通过此扩展提供便捷访问，同时保持与 Material Design 3 的兼容性。
extension ColorSchemeSemantics on ColorScheme {
  /// 成功状态色
  Color get success => brightness == Brightness.light
      ? AppColorSchemes.success
      : AppColorSchemes.successLight;

  /// 成功状态容器背景色
  Color get successContainer => brightness == Brightness.light
      ? AppColorSchemes.successContainer
      : AppColorSchemes.successContainerDark;

  /// 警告状态色
  Color get warning => brightness == Brightness.light
      ? AppColorSchemes.warning
      : AppColorSchemes.warningLight;

  /// 警告状态容器背景色
  Color get warningContainer => brightness == Brightness.light
      ? AppColorSchemes.warningContainer
      : AppColorSchemes.warningContainerDark;

  /// 信息状态色
  Color get info => brightness == Brightness.light
      ? AppColorSchemes.info
      : AppColorSchemes.infoLight;

  /// 信息状态容器背景色
  Color get infoContainer => brightness == Brightness.light
      ? AppColorSchemes.infoContainer
      : AppColorSchemes.infoContainerDark;
}
