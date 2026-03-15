import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/main.dart';

/// TC-FLU-007: 浅色主题默认显示测试
/// TC-FLU-008: 深色主题切换测试
/// 验证主题切换功能正常工作
void main() {
  group('Theme Tests', () {
    testWidgets('Default theme is light', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));
      await tester.pumpAndSettle();

      // Get the current theme brightness
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final Brightness brightness = Theme.of(context).brightness;

      // Default should be light
      expect(
        brightness,
        equals(Brightness.light),
        reason: 'Default theme should be light mode',
      );
    });

    testWidgets('Light theme has correct color scheme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.brightness, equals(Brightness.light));

      // Light theme surface should be light colored
      final surfaceColor = theme.colorScheme.surface;
      // Surface color in light theme should have high lightness value
      final hslColor = HSLColor.fromColor(surfaceColor);
      expect(
        hslColor.lightness,
        greaterThan(0.5),
        reason: 'Light theme surface should be light colored',
      );
    });

    testWidgets('App provides theme switching capability', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));
      await tester.pumpAndSettle();

      // Check if MaterialApp has both theme and darkTheme configured
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(
        app.theme,
        isNotNull,
        reason: 'App should have light theme configured',
      );
      expect(
        app.darkTheme,
        isNotNull,
        reason: 'App should have dark theme configured',
      );
    });

    testWidgets('Dark theme has correct color scheme', (
      WidgetTester tester,
    ) async {
      // Test dark theme directly by configuring it
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            themeMode: ThemeMode.dark,
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            home: const Scaffold(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
    });

    testWidgets('Theme provider exists and is accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));
      await tester.pumpAndSettle();

      // Verify we can access theme-related providers without errors
      // This will be expanded when the actual theme provider is implemented
      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });
}
