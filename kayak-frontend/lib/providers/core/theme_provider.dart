/// 主题状态管理
///
/// 使用Riverpod管理应用主题状态
/// 支持浅色/深色/跟随系统三种模式
/// 主题设置持久化到SharedPreferences
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 主题模式枚举扩展
/// 应用主题模式枚举
enum AppThemeMode { light, dark, system }

/// SharedPreferences Provider（延迟初始化）
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

/// 主题状态Notifier
///
/// 管理主题模式的状态变更和持久化
class ThemeNotifier extends StateNotifier<ThemeMode> {
  /// 构造函数
  ///
  /// 初始化时加载保存的主题设置
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  /// SharedPreferences中存储主题设置的键
  static const String _themeKey = 'app_theme_mode';

  /// SharedPreferences实例
  SharedPreferences? _prefs;

  /// 从SharedPreferences加载主题设置
  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs?.getString(_themeKey);
    if (savedTheme != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => ThemeMode.light,
      );
    }
  }

  /// 设置主题模式
  ///
  /// [mode] 要设置的主题模式
  /// 同时保存到SharedPreferences
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs?.setString(_themeKey, mode.name);
  }

  /// 切换主题
  ///
  /// 在当前浅色/深色主题之间切换
  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(newMode);
  }
}

/// 主题Provider
///
/// 全局可访问的主题状态
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// 当前是否为深色模式（计算属性）
///
/// 考虑系统主题设置
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  if (themeMode == ThemeMode.system) {
    // 注意：实际应用中需要通过MediaQuery获取系统主题
    // 这里简化处理，默认为false
    return false;
  }
  return themeMode == ThemeMode.dark;
});
