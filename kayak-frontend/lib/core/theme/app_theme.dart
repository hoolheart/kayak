/// 应用主题配置
///
/// 定义浅色主题和深色主题的完整配置
/// 包括颜色方案、组件主题、字体排版等

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_schemes.dart';
import 'app_typography.dart';

/// 应用主题配置
class AppTheme {
  AppTheme._();

  /// 浅色主题
  static ThemeData get light {
    final colorScheme = AppColorSchemes.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      textTheme: AppTypography.textTheme,

      // 应用栏主题
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // 卡片主题
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
        ),
        color: colorScheme.surface,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // 列表瓦片主题
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // 分隔线主题
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // 导航栏主题（MD3 NavigationBar）
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

      // 对话框主题
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),

      // 浮动操作按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Chip主题
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: AppTypography.textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Snackbar主题
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
    );
  }

  /// 深色主题
  static ThemeData get dark {
    final colorScheme = AppColorSchemes.dark;

    // 深色主题基于浅色主题，覆盖必要的属性
    return light.copyWith(
      brightness: Brightness.dark,
      colorScheme: colorScheme,

      appBarTheme: light.appBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      scaffoldBackgroundColor: colorScheme.surface,

      cardTheme: light.cardTheme.copyWith(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.24),
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: light.inputDecorationTheme.copyWith(
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
      ),

      bottomNavigationBarTheme: light.bottomNavigationBarTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainer,
      ),
    );
  }
}
