import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TC-005: Default theme is ThemeMode.system', () {
    test('default theme is ThemeMode.system', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, equals(ThemeMode.system));
    });
  });

  group('TC-006: setTheme(light) updates state', () {
    test('setTheme(light) updates state to light', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);

      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });
  });

  group('TC-007: setTheme(dark) updates state', () {
    test('setTheme(dark) updates state to dark and can switch back', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      // switch back
      container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });
  });

  group('TC-008: setTheme(system) updates state', () {
    test('full cycle: system -> light -> dark -> system', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), equals(ThemeMode.system));

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
      expect(container.read(themeModeProvider), equals(ThemeMode.system));
    });
  });

  group('TC-009: Theme state persisted to shared_preferences', () {
    test('setTheme persists choice to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
      expect(prefs.getString('theme_mode'), equals('light'));

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
      expect(prefs.getString('theme_mode'), equals('dark'));
    });

    test('build reads persisted theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });

    test('build defaults to system when no persisted value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), equals(ThemeMode.system));
    });
  });

  group('TC-019: SharedPreferences unavailable falls back to system', () {
    test('build falls back to system when SharedPreferences unavailable', () {
      // 模拟 SharedPreferences provider 不可用
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWith((ref) {
          throw Exception('SharedPreferences not available');
        }),
      ]);
      addTearDown(container.dispose);

      // 不应该抛出异常
      expect(
        () => container.read(themeModeProvider),
        returnsNormally,
      );

      // 回退到默认值
      final mode = container.read(themeModeProvider);
      expect(mode, equals(ThemeMode.system));
    });
  });

  group('TC-020: Rapid sequential setTheme calls', () {
    test('rapid sequential calls produce no race conditions', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      // Rapid sequential calls
      container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
      container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
      container.read(themeModeProvider.notifier).setTheme(ThemeMode.system);

      // Final state is the last call value
      expect(container.read(themeModeProvider), equals(ThemeMode.system));
      expect(prefs.getString('theme_mode'), equals('system'));
    });
  });

  group('TC-021: Invalid theme mode values handled gracefully', () {
    test('build handles invalid stored theme value gracefully', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      // Should fall back to system
      expect(container.read(themeModeProvider), equals(ThemeMode.system));
    });
  });

  group('TC-022: Correct Riverpod 3.x API types', () {
    test('ThemeNotifier uses correct Riverpod 3.x API', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify provider returns correct types
      final notifier = container.read(themeModeProvider.notifier);
      expect(notifier, isA<ThemeModeNotifier>());

      // Verify state type
      final state = container.read(themeModeProvider);
      expect(state, isA<ThemeMode>());
    });
  });

  group('TC-023: Consistent reads from themeModeProvider', () {
    test('multiple reads return the same state', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);

      // Multiple reads return same state
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('different containers have independent state', () {
      SharedPreferences.setMockInitialValues({});
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      container1.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);

      expect(container1.read(themeModeProvider), equals(ThemeMode.dark));
      expect(container2.read(themeModeProvider), equals(ThemeMode.system));
    });
  });
}
