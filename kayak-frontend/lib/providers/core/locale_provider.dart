/// 语言状态管理
///
/// 使用Riverpod管理应用语言状态
/// 支持多语言切换
/// 语言设置持久化到SharedPreferences

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 支持的语言列表
final supportedLocalesProvider = Provider<List<Locale>>((ref) {
  return const [
    Locale('en'), // 英语
    Locale('zh'), // 中文
  ];
});

/// 语言状态Notifier
///
/// 管理语言设置的状态变更和持久化
class LocaleNotifier extends StateNotifier<Locale> {
  /// SharedPreferences中存储语言设置的键
  static const String _localeKey = 'app_locale';

  /// SharedPreferences实例
  SharedPreferences? _prefs;

  /// 构造函数
  ///
  /// 初始化时加载保存的语言设置，默认为中文
  LocaleNotifier() : super(const Locale('zh')) {
    _loadLocale();
  }

  /// 从SharedPreferences加载语言设置
  Future<void> _loadLocale() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLocale = _prefs?.getString(_localeKey);
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  /// 设置语言
  ///
  /// [locale] 要设置的语言
  /// 同时保存到SharedPreferences
  void setLocale(Locale locale) {
    state = locale;
    _prefs?.setString(_localeKey, locale.languageCode);
  }

  /// 根据语言代码设置语言
  ///
  /// [languageCode] 语言代码（如 'en', 'zh'）
  void setLocaleByCode(String languageCode) {
    setLocale(Locale(languageCode));
  }
}

/// 语言Provider
///
/// 全局可访问的语言状态
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
