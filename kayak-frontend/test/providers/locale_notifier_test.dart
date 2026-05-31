import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TC-007: Default locale is English (en)', () {
    test('default locale is English (en)', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale, equals(const Locale('en')));
    });
  });

  group('TC-008: setLocale(zh) updates state to Chinese', () {
    test('setLocale(zh) updates state to Chinese', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setLocale(const Locale('zh'));

      final locale = container.read(localeProvider);
      expect(locale.languageCode, equals('zh'));
    });
  });

  group('TC-009: setLocale(en) switches back to English', () {
    test('setLocale(en) switches back to English', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // switch to zh first
      container.read(localeProvider.notifier).setLocale(const Locale('zh'));
      expect(container.read(localeProvider).languageCode, equals('zh'));

      // switch back to en
      container.read(localeProvider.notifier).setLocale(const Locale('en'));
      expect(container.read(localeProvider).languageCode, equals('en'));
    });
  });

  group('TC-010: Locale preference persisted to SharedPreferences', () {
    test('setLocale persists language to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setLocale(const Locale('zh'));
      expect(prefs.getString('locale_language_code'), equals('zh'));

      container.read(localeProvider.notifier).setLocale(const Locale('en'));
      expect(prefs.getString('locale_language_code'), equals('en'));
    });
  });

  group('TC-011: build() reads persisted locale from SharedPreferences', () {
    test('build reads persisted locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'locale_language_code': 'zh'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale.languageCode, equals('zh'));
    });
  });

  group('TC-012: Falls back to en when no persisted value', () {
    test('build defaults to English when no persisted value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale.languageCode, equals('en'));
    });
  });

  group('TC-013: SharedPreferences unavailable still works', () {
    test('build falls back to en when SharedPreferences unavailable', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWith((ref) {
          throw Exception('SharedPreferences not available');
        }),
      ]);
      addTearDown(container.dispose);

      // 不应该抛出异常
      expect(
        () => container.read(localeProvider),
        returnsNormally,
      );

      // 回退到默认值
      final locale = container.read(localeProvider);
      expect(locale.languageCode, equals('en'));
    });

    test('setLocale works even when persistence fails', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWith((ref) {
          throw Exception('SharedPreferences not available');
        }),
      ]);
      addTearDown(container.dispose);

      // setLocale 不应抛出异常
      expect(
        () =>
            container.read(localeProvider.notifier).setLocale(const Locale('zh')),
        returnsNormally,
      );

      // 内存状态应正确更新
      expect(container.read(localeProvider).languageCode, equals('zh'));
    });
  });

  group('TC-027: LocaleNotifier uses correct Riverpod 3.x API', () {
    test('LocaleNotifier uses correct Riverpod 3.x API', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 验证 Notifier 类型
      final notifier = container.read(localeProvider.notifier);
      expect(notifier, isA<LocaleNotifier>());

      // 验证状态类型
      final state = container.read(localeProvider);
      expect(state, isA<Locale>());

      // 验证 setLocale 是同步方法
      expect(notifier.setLocale, isA<void Function(Locale)>());
    });
  });

  group('TC-028: LocaleNotifier and ThemeNotifier do not interfere', () {
    test('LocaleNotifier and ThemeNotifier do not interfere', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      // 同时设置两个状态
      container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
      container.read(localeProvider.notifier).setLocale(const Locale('zh'));

      // 验证互不干扰
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(container.read(localeProvider).languageCode, equals('zh'));

      // 验证持久化 key 不冲突
      expect(prefs.getString('theme_mode'), equals('dark'));
      expect(prefs.getString('locale_language_code'), equals('zh'));
    });
  });

  group('TC-029: Multiple reads return consistent state', () {
    test('multiple reads return consistent state', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setLocale(const Locale('zh'));

      // 多次读取返回一致状态
      expect(container.read(localeProvider).languageCode, equals('zh'));
      expect(container.read(localeProvider).languageCode, equals('zh'));
      expect(container.read(localeProvider).languageCode, equals('zh'));
    });

    test('different containers have independent state', () {
      SharedPreferences.setMockInitialValues({});
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      container1.read(localeProvider.notifier).setLocale(const Locale('zh'));

      expect(container1.read(localeProvider).languageCode, equals('zh'));
      expect(container2.read(localeProvider).languageCode, equals('en'));
    });
  });
}
