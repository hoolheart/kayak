import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/core/locale_provider.dart';
import '../../../providers/core/theme_provider.dart';

/// Settings page - application settings
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),

            // Appearance section
            Text(
              '外观',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('主题'),
                    subtitle: Text(_getThemeModeText(themeMode)),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (selected) {
                        ref
                            .read(themeProvider.notifier)
                            .setThemeMode(selected.first);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('语言'),
                    subtitle: Text(_getLocaleText(locale)),
                    trailing: SegmentedButton<Locale>(
                      segments: const [
                        ButtonSegment(
                          value: Locale('en'),
                          label: Text('EN'),
                        ),
                        ButtonSegment(
                          value: Locale('zh'),
                          label: Text('中文'),
                        ),
                      ],
                      selected: {locale},
                      onSelectionChanged: (selected) {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(selected.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // About section
            Text(
              '关于',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Kayak'),
                    subtitle: Text('科学研究支持平台'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.code),
                    title: Text('版本'),
                    subtitle: Text('1.0.0'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  String _getLocaleText(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
}
