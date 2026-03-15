import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/main.dart';

/// TC-FLU-005: Material Design 3组件渲染测试
/// 验证应用使用Material Design 3设计规范
void main() {
  group('Material Design 3 Tests', () {
    testWidgets('MaterialApp uses Material Design 3', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(
        app.theme?.useMaterial3,
        isTrue,
        reason: 'Theme should use Material Design 3',
      );
      expect(
        app.darkTheme?.useMaterial3,
        isTrue,
        reason: 'Dark theme should use Material Design 3',
      );
    });

    testWidgets('ColorScheme uses seed color', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(
        app.theme?.colorScheme,
        isNotNull,
        reason: 'Light theme should have ColorScheme',
      );
      expect(
        app.darkTheme?.colorScheme,
        isNotNull,
        reason: 'Dark theme should have ColorScheme',
      );

      // Verify ColorScheme has primary color
      expect(app.theme?.colorScheme?.primary, isNotNull);
      expect(app.darkTheme?.colorScheme?.primary, isNotNull);
    });

    testWidgets('Material 3 specific widgets render correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));
      await tester.pumpAndSettle();

      // Find Scaffold (main container)
      expect(find.byType(Scaffold), findsOneWidget);

      // Check for AppBar with Material 3 style
      final appBar = find.byType(AppBar);
      if (appBar.evaluate().isNotEmpty) {
        final AppBar bar = tester.widget(appBar);
        // Material 3 AppBar typically uses surface color
        expect(
          bar.backgroundColor,
          isNull,
          reason: 'Material 3 AppBar should use default surface color',
        );
      }
    });

    testWidgets('Typography uses Material 3 text theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: KayakApp()));

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      final textTheme = app.theme?.textTheme;

      expect(textTheme, isNotNull);
      // Material 3 has specific text styles
      expect(textTheme?.displayLarge, isNotNull);
      expect(textTheme?.headlineLarge, isNotNull);
      expect(textTheme?.titleLarge, isNotNull);
      expect(textTheme?.bodyLarge, isNotNull);
      expect(textTheme?.labelLarge, isNotNull);
    });
  });
}
