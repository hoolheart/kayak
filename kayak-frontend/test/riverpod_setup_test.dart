import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/app.dart';
import 'package:kayak_frontend/providers/core/locale_provider.dart';
import 'package:kayak_frontend/providers/core/theme_provider.dart';

void main() {
  group('Riverpod Setup Tests', () {
    testWidgets('ProviderScope wraps KayakApp', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KayakApp(),
        ),
      );

      // 验证ProviderScope存在
      expect(find.byType(ProviderScope), findsOneWidget);
    });

    test('ThemeProvider provides initial state', () {
      final container = ProviderContainer();

      // 获取初始主题模式
      final themeMode = container.read(themeProvider);

      // 默认应为浅色主题
      expect(themeMode, ThemeMode.light);

      container.dispose();
    });

    test('ThemeProvider can be toggled', () {
      final container = ProviderContainer();

      // 获取notifier
      final notifier = container.read(themeProvider.notifier);

      // 切换主题
      notifier.toggleTheme();

      // 验证状态变化
      expect(container.read(themeProvider), ThemeMode.dark);

      // 再次切换
      notifier.toggleTheme();

      // 验证状态变化
      expect(container.read(themeProvider), ThemeMode.light);

      container.dispose();
    });

    test('LocaleProvider provides initial state', () {
      final container = ProviderContainer();

      // 获取初始语言
      final locale = container.read(localeProvider);

      // 默认应为系统语言
      expect(locale, isNotNull);

      container.dispose();
    });
  });
}
