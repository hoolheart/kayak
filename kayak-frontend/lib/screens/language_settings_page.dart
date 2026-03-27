import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/app_localizations.dart';
import '../providers/core/locale_provider.dart';

/// Language settings page
///
/// A settings page that allows users to change the application language.
class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.languageSettings ??
            'Language Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Current language display
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)?.currentLanguage ??
                'Current Language'),
            subtitle: Text(localeNotifier.getLocaleDisplayName(currentLocale)),
          ),
          const Divider(),
          // Language selection list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizations.of(context)?.availableLanguages ??
                  'Available Languages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...LocaleNotifier.supportedLocales.map((locale) {
            final isSelected =
                locale.languageCode == currentLocale.languageCode;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(localeNotifier.getLocaleDisplayName(locale)),
              subtitle: Text(_getLocaleSubtitle(locale)),
              onTap: isSelected
                  ? null
                  : () {
                      localeNotifier.setLocale(locale);
                    },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getLocaleSubtitle(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return locale.languageCode;
    }
  }
}
