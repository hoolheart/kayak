import 'package:flutter/material.dart';

import '../providers/core/locale_provider.dart';

/// Language settings service interface
///
/// Defines standard operations for language settings.
///
/// This interface provides a singleton pattern access via [AppLocaleSettings.singleton]
/// as required by test case TC-S2-018-02.
abstract class AppLocaleSettings {
  /// Private constructor for preventing direct instantiation
  AppLocaleSettings._();

  /// Singleton instance - TC-S2-018-02 requires using AppLocaleSettings.singleton access
  /// Note: This is provided by the concrete implementation in LocaleNotifier
  static AppLocaleSettings? _instance;

  /// Gets the singleton instance
  ///
  /// Test case TC-S2-018-02 uses AppLocaleSettings.singleton to access
  static AppLocaleSettings get singleton {
    _instance ??= _LocaleSettingsImpl();
    return _instance!;
  }

  /// Current language locale
  Locale get currentLocale;

  /// List of supported language locales
  List<Locale> get supportedLocales;

  /// Default language locale
  Locale get defaultLocale;

  /// Persists the language setting
  Future<void> persistLocale(Locale locale);

  /// Loads the saved language setting
  Future<Locale> loadSavedLocale();

  /// Checks if a locale is supported
  bool isLocaleSupported(Locale locale);

  /// Gets the display name for a locale
  String getLocaleDisplayName(Locale locale);
}

/// Private concrete implementation of AppLocaleSettings
///
/// This is used internally to provide the singleton instance.
class _LocaleSettingsImpl extends AppLocaleSettings {
  _LocaleSettingsImpl() : super._();

  @override
  Locale get currentLocale => LocaleSettings.defaultLocale;

  @override
  List<Locale> get supportedLocales => LocaleNotifier.supportedLocales;

  @override
  Locale get defaultLocale => LocaleSettings.defaultLocale;

  @override
  Future<void> persistLocale(Locale locale) async {
    // This is handled by LocaleNotifier directly
  }

  @override
  Future<Locale> loadSavedLocale() async {
    return LocaleSettings.defaultLocale;
  }

  @override
  bool isLocaleSupported(Locale locale) {
    return supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  @override
  String getLocaleDisplayName(Locale locale) {
    final settings = LocaleSettings.fromLocale(locale);
    return settings?.nativeDisplayName ?? locale.languageCode;
  }
}
