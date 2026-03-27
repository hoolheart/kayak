import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core/locale_provider.dart';

/// Language selector widget
///
/// A ListTile-based language picker that shows a modal bottom sheet
/// when tapped to allow users to select their preferred language.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: Text(localeNotifier.getLocaleDisplayName(currentLocale)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguagePicker(context, ref),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _LanguagePickerSheet(),
    );
  }
}

class _LanguagePickerSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ...LocaleNotifier.supportedLocales.map((locale) {
            final isSelected =
                locale.languageCode == currentLocale.languageCode;
            return ListTile(
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(localeNotifier.getLocaleDisplayName(locale)),
              onTap: () {
                localeNotifier.setLocale(locale);
                Navigator.of(context).pop();
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
