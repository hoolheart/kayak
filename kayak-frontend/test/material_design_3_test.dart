import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/app.dart';
import 'package:kayak_frontend/core/theme/app_theme.dart';

void main() {
  group('Material Design 3 Tests', () {
    testWidgets('KayakApp renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KayakApp(),
        ),
      );

      // 验证MaterialApp存在
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Material Design 3 is enabled in themes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KayakApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));

      // 验证useMaterial3为true
      expect(app.theme?.useMaterial3, isTrue);
      expect(app.darkTheme?.useMaterial3, isTrue);
    });

    test('Light theme has correct color scheme', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, isNotNull);
      expect(theme.brightness, Brightness.light);
    });

    test('Dark theme has correct color scheme', () {
      final theme = AppTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, isNotNull);
      expect(theme.brightness, Brightness.dark);
    });
  });
}
