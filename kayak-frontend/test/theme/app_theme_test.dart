import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/theme/app_theme.dart';

void main() {
  group('TC-001: lightTheme uses Material 3 and has light brightness', () {
    test('lightTheme uses Material 3 and has light brightness', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.brightness, equals(Brightness.light));
    });

    test('lightTheme has all key component themes', () {
      final theme = AppTheme.lightTheme;
      expect(theme.appBarTheme, isNotNull);
      expect(theme.cardTheme, isNotNull);
      expect(theme.elevatedButtonTheme, isNotNull);
      expect(theme.inputDecorationTheme, isNotNull);
      expect(theme.navigationRailTheme, isNotNull);
      expect(theme.bottomNavigationBarTheme, isNotNull);
    });
  });

  group('TC-002: darkTheme uses Material 3 and has dark brightness', () {
    test('darkTheme uses Material 3 and has dark brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
    });

    test('darkTheme has all key component themes', () {
      final theme = AppTheme.darkTheme;
      expect(theme.appBarTheme, isNotNull);
      expect(theme.cardTheme, isNotNull);
      expect(theme.elevatedButtonTheme, isNotNull);
      expect(theme.inputDecorationTheme, isNotNull);
      expect(theme.navigationRailTheme, isNotNull);
      expect(theme.bottomNavigationBarTheme, isNotNull);
    });
  });

  group('TC-003: Seed color is #1976D2', () {
    test('both themes use same seed color #1976D2', () {
      const seedColor = Color(0xFF1976D2);

      final lightScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
      );
      final darkScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      );

      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      // primary from same seed should match
      expect(lightTheme.colorScheme.primary, equals(lightScheme.primary));
      expect(darkTheme.colorScheme.primary, equals(darkScheme.primary));
    });
  });

  group('TC-004: ColorScheme has complete palette', () {
    test('light ColorScheme has all required properties', () {
      final scheme = AppTheme.lightTheme.colorScheme;

      expect(scheme.primary, isNotNull);
      expect(scheme.onPrimary, isNotNull);
      expect(scheme.primaryContainer, isNotNull);
      expect(scheme.onPrimaryContainer, isNotNull);
      expect(scheme.secondary, isNotNull);
      expect(scheme.onSecondary, isNotNull);
      expect(scheme.surface, isNotNull);
      expect(scheme.onSurface, isNotNull);
      expect(scheme.error, isNotNull);
      expect(scheme.outline, isNotNull);
      expect(scheme.surfaceContainerHighest, isNotNull);
    });

    test('dark ColorScheme has all required properties', () {
      final scheme = AppTheme.darkTheme.colorScheme;

      expect(scheme.primary, isNotNull);
      expect(scheme.onPrimary, isNotNull);
      expect(scheme.primaryContainer, isNotNull);
      expect(scheme.onPrimaryContainer, isNotNull);
      expect(scheme.secondary, isNotNull);
      expect(scheme.onSecondary, isNotNull);
      expect(scheme.surface, isNotNull);
      expect(scheme.onSurface, isNotNull);
      expect(scheme.error, isNotNull);
      expect(scheme.outline, isNotNull);
      expect(scheme.surfaceContainerHighest, isNotNull);
    });

    test('light surface is light and dark surface is dark', () {
      final lightScheme = AppTheme.lightTheme.colorScheme;
      final darkScheme = AppTheme.darkTheme.colorScheme;

      // light surface should be light-toned
      expect(
        ThemeData.estimateBrightnessForColor(lightScheme.surface),
        equals(Brightness.light),
      );

      // dark surface should be dark-toned
      expect(
        ThemeData.estimateBrightnessForColor(darkScheme.surface),
        equals(Brightness.dark),
      );
    });

    test('onSurface has sufficient contrast on surface', () {
      final lightScheme = AppTheme.lightTheme.colorScheme;
      final darkScheme = AppTheme.darkTheme.colorScheme;

      // light: onSurface should be dark on light surface (readable text)
      expect(
        ThemeData.estimateBrightnessForColor(lightScheme.onSurface),
        equals(Brightness.dark),
      );

      // dark: onSurface should be light on dark surface (readable text)
      expect(
        ThemeData.estimateBrightnessForColor(darkScheme.onSurface),
        equals(Brightness.light),
      );
    });

    test('error color is a red tone', () {
      final lightScheme = AppTheme.lightTheme.colorScheme;
      final darkScheme = AppTheme.darkTheme.colorScheme;

      // error color should be reddish (high red component)
      final lightRed = (lightScheme.error.r * 255).round().clamp(0, 255);
      final darkRed = (darkScheme.error.r * 255).round().clamp(0, 255);
      expect(lightRed, greaterThan(100));
      expect(darkRed, greaterThan(100));
    });
  });
}
