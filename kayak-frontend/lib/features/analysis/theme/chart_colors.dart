/// 图表专用颜色定义
///
/// 定义时序图表组件专用的颜色，包括曲线颜色、背景色、网格线颜色等。
/// 这些颜色不在标准 ColorScheme 中，需单独定义。
library;

import 'package:flutter/material.dart';

/// 图表曲线颜色定义
class ChartColors {
  ChartColors._();

  /// 浅色主题曲线颜色
  static const List<Color> lightCurves = [
    Color(0xFF1976D2), // Primary - Curve 1
    Color(0xFF00838F), // Tertiary - Curve 2
    Color(0xFFC62828), // Error - Curve 3
    Color(0xFF2E7D32), // Success - Curve 4
  ];

  /// 深色主题曲线颜色
  static const List<Color> darkCurves = [
    Color(0xFF90CAF9), // Primary (dark) - Curve 1
    Color(0xFF80DEEA), // Tertiary (dark) - Curve 2
    Color(0xFFEF5350), // Error Light - Curve 3
    Color(0xFF66BB6A), // Success Light - Curve 4
  ];

  /// 根据主题亮度获取曲线颜色列表
  static List<Color> getCurves(Brightness brightness) =>
      brightness == Brightness.light ? lightCurves : darkCurves;

  /// 获取指定索引的曲线颜色
  static Color getCurveColor(Brightness brightness, int index) {
    final colors = getCurves(brightness);
    return colors[index % colors.length];
  }
}

/// 图表背景色扩展
extension ChartBackgroundColors on ColorScheme {
  /// 图表画布背景色
  Color get chartCanvasBackground => brightness == Brightness.light
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF0A0A0A);

  /// 图表工具栏背景色
  Color get chartToolbarBackground => brightness == Brightness.light
      ? const Color(0xFFFAFAFA)
      : const Color(0xFF1A1A1A);

  /// 图例栏背景色
  Color get chartLegendBarBackground => brightness == Brightness.light
      ? const Color(0xFFFAFAFA)
      : const Color(0xFF1A1A1A);

  /// 网格线颜色
  Color get chartGridLine => brightness == Brightness.light
      ? const Color(0xFFEEEEEE)
      : const Color(0xFF1E1E1E);

  /// 主网格线颜色（每5条线）
  Color get chartGridLineMajor => brightness == Brightness.light
      ? const Color(0xFFE0E0E0)
      : const Color(0xFF2D2D2D);

  /// 提示框背景色
  Color get chartTooltipBackground => brightness == Brightness.light
      ? const Color(0xFFE0E0E0)
      : const Color(0xFF3D3D3D);

  /// 控制卡片背景色
  Color get controlCardBackground => brightness == Brightness.light
      ? const Color(0xFFFAFAFA)
      : const Color(0xFF0A0A0A);

  /// 数据表格偶数行背景色
  Color get tableRowEvenBackground => brightness == Brightness.light
      ? const Color(0xFFFAFAFA)
      : const Color(0xFF1A1A1A);

  /// 数据表格悬停行背景色
  Color get tableRowHoverBackground => brightness == Brightness.light
      ? const Color(0xFFEEEEEE)
      : const Color(0xFF2D2D2D);
}
