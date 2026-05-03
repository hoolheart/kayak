/// 应用主题配置 v2
///
/// 定义浅色主题和深色主题的完整配置
/// 包括颜色方案、组件主题、字体排版等
/// 符合设计规范 v2 (design_spec_v2.md)
///
/// 主要更新：
///   - 主色从 #6750A4 更新为 #1976D2（科技蓝）
///   - 完善所有组件主题以匹配设计规范
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_schemes.dart';
import 'app_typography.dart';

/// 应用主题配置 v2
class AppTheme {
  AppTheme._();

  /// 浅色主题
  static ThemeData get lightTheme => light;

  /// 深色主题
  static ThemeData get darkTheme => dark;

  /// 浅色主题
  static ThemeData get light {
    final colorScheme = AppColorSchemes.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // ==================== AppBar 主题 ====================
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ==================== 卡片主题 ====================
      // 设计规范 5.3: Standard Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surface,
        margin: const EdgeInsets.all(16),
      ),

      // ==================== 按钮主题 ====================
      // 设计规范 5.1: Primary Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // 设计规范 5.1: Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // 设计规范 5.1: Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // ==================== 输入框主题 ====================
      // 设计规范 5.2: Filled Text Field (Standard Input)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),

      // ==================== 列表瓦片主题 ====================
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ==================== 分隔线主题 ====================
      // 设计规范: Outline Variant 用于分割线
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ==================== 底部导航栏主题 ====================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ==================== MD3 NavigationBar 主题 ====================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // ==================== 对话框主题 ====================
      // 设计规范 5.5: Standard Dialog - 圆角 28px
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: colorScheme.surfaceContainerHigh,
        titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // ==================== 浮动操作按钮主题 ====================
      // 设计规范 5.1: FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      // ==================== Chip 主题 ====================
      // 设计规范 5.7: Status Chip / Protocol Chip
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: AppTypography.textTheme.labelSmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        side: BorderSide.none,
      ),

      // ==================== Snackbar / Toast 主题 ====================
      // 设计规范 5.9
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.primary,
      ),

      // ==================== 进度指示器主题 ====================
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // ==================== 图标按钮主题 ====================
      // 设计规范 5.1: Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
        ),
      ),

      // ==================== 下拉菜单主题 ====================
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // ==================== Tab 主题 ====================
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
      ),
    );
  }

  /// 深色主题
  ///
  /// 基于浅色主题，覆盖深色模式特定属性
  /// 设计规范 11.3 节
  static ThemeData get dark {
    final colorScheme = AppColorSchemes.dark;

    return light.copyWith(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar - 深色主题使用 Surface Container High
      appBarTheme: light.appBarTheme.copyWith(
        backgroundColor: AppColorSchemes.darkSurfaceContainerHigh,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card - 深色主题使用 Surface Container Low
      cardTheme: light.cardTheme.copyWith(
        color: AppColorSchemes.darkSurfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      // 输入框 - 深色主题适配
      inputDecorationTheme: light.inputDecorationTheme.copyWith(
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        focusedBorder: light.inputDecorationTheme.focusedBorder?.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),

      // 底部导航
      bottomNavigationBarTheme: light.bottomNavigationBarTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainer,
      ),

      // NavigationBar
      navigationBarTheme: light.navigationBarTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainer,
      ),

      // Dialog
      dialogTheme: light.dialogTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),

      // OutlinedButton - 深色主题边框
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // Chip
      chipTheme: light.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
      ),

      // Snackbar
      snackBarTheme: light.snackBarTheme.copyWith(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: light.snackBarTheme.contentTextStyle?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),

      // Divider
      dividerTheme: light.dividerTheme.copyWith(
        color: colorScheme.outlineVariant,
      ),

      // Progress Indicator
      progressIndicatorTheme: light.progressIndicatorTheme.copyWith(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
