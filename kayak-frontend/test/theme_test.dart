import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/app.dart';
import 'package:kayak_frontend/core/theme/app_theme.dart';
import 'package:kayak_frontend/providers/core/theme_provider.dart';

void main() {
  group('Theme Tests', () {
    testWidgets('Default theme is light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KayakApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
    });

    test('Light theme has correct brightness', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
    });

    test('Dark theme has correct brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
    });

    test('ThemeProvider provides ThemeMode', () {
      final container = ProviderContainer();

      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.light);

      container.dispose();
    });

    test('ThemeProvider can toggle theme', () {
      final container = ProviderContainer();

      final notifier = container.read(themeProvider.notifier);

      // 初始状态应为浅色
      expect(container.read(themeProvider), ThemeMode.light);

      // 切换主题
      notifier.toggleTheme();
      expect(container.read(themeProvider), ThemeMode.dark);

      // 再次切换
      notifier.toggleTheme();
      expect(container.read(themeProvider), ThemeMode.light);

      container.dispose();
    });
  });
}
