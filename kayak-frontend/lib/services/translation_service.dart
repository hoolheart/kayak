/// Translation service for i18n support
///
/// Provides translation functionality with dot-notation key mapping
library;

import 'package:flutter/material.dart';

import '../generated/app_localizations.dart';
import '../providers/core/locale_provider.dart';

/// Translation key mapping from dot-notation to ARB camelCase keys
const Map<String, String> _keyMapping = {
  // Login module
  'login.title': 'loginTitle',
  'login.subtitle': 'loginSubtitle',
  'login.username': 'emailLabel', // Maps to emailLabel
  'login.email': 'emailLabel',
  'login.password': 'passwordLabel',
  'login.rememberMe': 'rememberMe',
  'login.forgotPassword': 'forgotPassword',
  'login.button': 'loginButton',
  'login.buttonLoading': 'loginButtonLoading',
  'login.noAccount': 'noAccount',
  'login.signUp': 'signUp',
  'login.invalidEmail': 'invalidEmail',
  'login.passwordTooShort': 'passwordTooShort',
  'login.failed': 'loginFailed',

  // Nav module
  'nav.home': 'navHome',
  'nav.workbench': 'navWorkbench',
  'nav.experiments': 'navExperiments',
  'nav.methods': 'navMethods',
  'nav.devices': 'navDevices',
  'nav.settings': 'navSettings',
  'nav.profile': 'navProfile',
  'nav.about': 'navAbout',
  'nav.logout': 'navLogout',
  'nav.search': 'navSearch',
  'nav.notifications': 'navNotifications',

  // Common module
  'common.save': 'commonSave',
  'common.cancel': 'commonCancel',
  'common.confirm': 'commonConfirm',
  'common.delete': 'commonDelete',
  'common.edit': 'commonEdit',
  'common.add': 'commonAdd',
  'common.search': 'commonSearch',
  'common.noData': 'commonNoData',
  'common.retry': 'commonRetry',
  'common.refresh': 'commonRefresh',
  'common.submit': 'commonSubmit',
  'common.required': 'commonRequired',
};

/// Translation service implementation
///
/// Provides translation functionality based on AppLocalizations.
/// Supports dot-notation keys through internal mapping to ARB camelCase keys.
class TranslationService {
  /// Creates a translation service instance
  TranslationService();

  /// Gets the current language code
  String get currentLanguageCode {
    final locale = localeProvider;
    return locale.languageCode;
  }

  /// Gets the current locale
  Locale get currentLocale {
    return localeProvider;
  }

  /// Gets supported locales
  List<Locale> get supportedLocales => LocaleNotifier.supportedLocales;

  /// Translates a key to the corresponding localized string
  ///
  /// [context] BuildContext for accessing AppLocalizations
  /// [key] Translation key (supports dot-notation like 'login.title' or ARB keys like 'loginTitle')
  /// [args] Optional arguments for string formatting
  ///
  /// Returns the translated string, or the original key if not found (fallback)
  String translate(
    BuildContext context,
    String key, {
    Map<String, String>? args,
  }) {
    // Convert dot-notation key to ARB key
    final arbKey = _convertToArbKey(key);

    // Get localizations from context
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return key; // Fallback to key if localizations not available
    }

    // Lookup translation by key
    final value = _lookupTranslation(l10n, arbKey);

    // Return value or fallback to original key
    if (value != null) {
      return _formatString(value, args);
    }
    return key;
  }

  /// Module-specific translation
  ///
  /// [context] BuildContext for accessing AppLocalizations
  /// [module] Module name (e.g., 'login', 'nav', 'common')
  /// [key] Translation key within the module
  /// [args] Optional arguments for string formatting
  String moduleTranslate(
    BuildContext context,
    String module,
    String key, {
    Map<String, String>? args,
  }) {
    final fullKey = '$module.$key';
    return translate(context, fullKey, args: args);
  }

  /// Converts dot-notation key to ARB camelCase key
  String _convertToArbKey(String key) {
    // Check if key is in mapping table
    if (_keyMapping.containsKey(key)) {
      return _keyMapping[key]!;
    }

    // Try automatic conversion: "module.key" -> "moduleKey"
    if (key.contains('.')) {
      final parts = key.split('.');
      if (parts.length == 2) {
        return '${parts[0]}${_capitalize(parts[1])}';
      }
    }

    return key;
  }

  /// Capitalizes the first letter of a string
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  /// Looks up translation by ARB key using AppLocalizations
  String? _lookupTranslation(AppLocalizations l10n, String key) {
    switch (key) {
      // App-level translations
      case 'appTitle':
        return l10n.appTitle;
      case 'welcomeMessage':
        return l10n.welcomeMessage;
      case 'subtitle':
        return l10n.subtitle;
      case 'enterWorkbench':
        return l10n.enterWorkbench;
      case 'settings':
        return l10n.settings;
      case 'toggleTheme':
        return l10n.toggleTheme;
      case 'language':
        return l10n.language;
      case 'languageSettings':
        return l10n.languageSettings;
      case 'currentLanguage':
        return l10n.currentLanguage;
      case 'availableLanguages':
        return l10n.availableLanguages;
      case 'selectLanguage':
        return l10n.selectLanguage;
      case 'ok':
        return l10n.ok;
      case 'cancel':
        return l10n.cancel;
      case 'save':
        return l10n.save;
      case 'delete':
        return l10n.delete;
      case 'edit':
        return l10n.edit;
      case 'close':
        return l10n.close;
      case 'confirm':
        return l10n.confirm;
      case 'back':
        return l10n.back;
      case 'next':
        return l10n.next;
      case 'done':
        return l10n.done;
      case 'loading':
        return l10n.loading;
      case 'error':
        return l10n.error;
      case 'success':
        return l10n.success;
      case 'warning':
        return l10n.warning;
      case 'info':
        return l10n.info;

      // Login module translations
      case 'loginTitle':
        return l10n.loginTitle;
      case 'loginSubtitle':
        return l10n.loginSubtitle;
      case 'emailLabel':
        return l10n.emailLabel;
      case 'emailPlaceholder':
        return l10n.emailPlaceholder;
      case 'passwordLabel':
        return l10n.passwordLabel;
      case 'passwordPlaceholder':
        return l10n.passwordPlaceholder;
      case 'rememberMe':
        return l10n.rememberMe;
      case 'forgotPassword':
        return l10n.forgotPassword;
      case 'loginButton':
        return l10n.loginButton;
      case 'loginButtonLoading':
        return l10n.loginButtonLoading;
      case 'noAccount':
        return l10n.noAccount;
      case 'signUp':
        return l10n.signUp;
      case 'invalidEmail':
        return l10n.invalidEmail;
      case 'passwordTooShort':
        return l10n.passwordTooShort;
      case 'loginFailed':
        return l10n.loginFailed;

      // Nav module translations
      case 'navHome':
        return l10n.navHome;
      case 'navWorkbench':
        return l10n.navWorkbench;
      case 'navExperiments':
        return l10n.navExperiments;
      case 'navMethods':
        return l10n.navMethods;
      case 'navDevices':
        return l10n.navDevices;
      case 'navSettings':
        return l10n.navSettings;
      case 'navProfile':
        return l10n.navProfile;
      case 'navAbout':
        return l10n.navAbout;
      case 'navLogout':
        return l10n.navLogout;
      case 'navSearch':
        return l10n.navSearch;
      case 'navNotifications':
        return l10n.navNotifications;

      // Common module translations
      case 'commonSave':
        return l10n.commonSave;
      case 'commonCancel':
        return l10n.commonCancel;
      case 'commonConfirm':
        return l10n.commonConfirm;
      case 'commonDelete':
        return l10n.commonDelete;
      case 'commonEdit':
        return l10n.commonEdit;
      case 'commonAdd':
        return l10n.commonAdd;
      case 'commonSearch':
        return l10n.commonSearch;
      case 'commonNoData':
        return l10n.commonNoData;
      case 'commonRetry':
        return l10n.commonRetry;
      case 'commonRefresh':
        return l10n.commonRefresh;
      case 'commonSubmit':
        return l10n.commonSubmit;
      case 'commonRequired':
        return l10n.commonRequired;

      default:
        return null;
    }
  }

  /// Formats a template string with provided arguments
  String _formatString(String template, Map<String, String>? args) {
    if (args == null || args.isEmpty) {
      return template;
    }

    String result = template;
    args.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// Gets plural form of a translation key
  String plural(BuildContext context, String key, int count) {
    final arbKey = _convertToArbKey(key);
    return count == 1 ? '${arbKey}_one' : '${arbKey}_other';
  }

  /// Updates the current locale
  void updateLocale(Locale locale) {
    // State is managed by localeProvider, this is a no-op for backward compatibility
  }
}

/// Provider for translation service
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});
