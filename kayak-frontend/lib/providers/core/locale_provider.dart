/// 语言状态管理
///
/// 使用Riverpod管理应用语言状态
/// 支持多语言切换
/// 语言设置持久化到SharedPreferences
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言设置数据模型
class LocaleSettings {
  final Locale locale;
  final String displayName;
  final String nativeDisplayName;
  final bool isRightToLeft;

  const LocaleSettings({
    required this.locale,
    required this.displayName,
    required this.nativeDisplayName,
    this.isRightToLeft = false,
  });

  /// 预定义的语言环境配置
  static const List<LocaleSettings> supportedSettings = [
    LocaleSettings(
      locale: Locale('en', 'US'),
      displayName: 'English (US)',
      nativeDisplayName: 'English',
    ),
    LocaleSettings(
      locale: Locale('zh', 'CN'),
      displayName: 'Chinese (Simplified)',
      nativeDisplayName: '简体中文',
    ),
  ];

  /// 根据Locale获取配置
  static LocaleSettings? fromLocale(Locale locale) {
    try {
      return supportedSettings.firstWhere(
        (s) => s.locale.languageCode == locale.languageCode,
      );
    } catch (_) {
      return null;
    }
  }
}

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

  /// 支持的语言列表
  static List<Locale> get supportedLocales {
    return LocaleSettings.supportedSettings.map((s) => s.locale).toList();
  }

  /// 默认语言
  static Locale get defaultLocale => const Locale('zh', 'CN');

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

  /// 获取语言显示名称
  String getLocaleDisplayName(Locale locale) {
    final settings = LocaleSettings.fromLocale(locale);
    return settings?.nativeDisplayName ?? locale.languageCode;
  }

  /// 检查语言是否支持
  bool isLocaleSupported(Locale locale) {
    return LocaleSettings.supportedSettings.any(
      (s) => s.locale.languageCode == locale.languageCode,
    );
  }
}

/// 语言Provider
///
/// 全局可访问的语言状态
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
