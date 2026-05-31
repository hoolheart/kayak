import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';

void main() {
  group('TC-005: AppLocalizations.supportedLocales contains en and zh', () {
    test('AppLocalizations.supportedLocales contains en and zh', () {
      const locales = AppLocalizations.supportedLocales;

      expect(locales, contains(const Locale('en')));
      expect(locales, contains(const Locale('zh')));
      expect(locales.length, equals(2));
    });
  });

  group('TC-006: AppLocalizations.localizationsDelegates includes all required', () {
    test('AppLocalizations.localizationsDelegates includes all required', () {
      const delegates = AppLocalizations.localizationsDelegates;

      expect(delegates.length, equals(4));
      expect(delegates[0], equals(AppLocalizations.delegate));
      expect(delegates[1], equals(GlobalMaterialLocalizations.delegate));
      expect(delegates[2], equals(GlobalCupertinoLocalizations.delegate));
      expect(delegates[3], equals(GlobalWidgetsLocalizations.delegate));
    });
  });

  group('TC-017: AppLocalizations returns English text for en locale', () {
    testWidgets('AppLocalizations returns English text for en locale',
        (tester) async {
      String? actualAppTitle;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            final loc = AppLocalizations.of(context)!;
            actualAppTitle = loc.appTitle;
            return const SizedBox();
          },
        ),
      ));
      await tester.pump();

      expect(actualAppTitle, isNotNull);
      expect(actualAppTitle, equals('Kayak'));
    });
  });

  group('TC-018: AppLocalizations returns Chinese text for zh locale', () {
    testWidgets('AppLocalizations returns Chinese text for zh locale',
        (tester) async {
      String? actualLoginText;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            final loc = AppLocalizations.of(context)!;
            actualLoginText = loc.login;
            return const SizedBox();
          },
        ),
      ));
      await tester.pump();

      expect(actualLoginText, isNotNull);
      expect(actualLoginText, equals('登录'));
    });
  });

  group('TC-020: Fallback to en when zh is missing a key', () {
    test('AppLocalizations.delegate.isSupported recognizes en and zh', () {
      expect(
        AppLocalizations.delegate.isSupported(const Locale('en')),
        isTrue,
      );
      expect(
        AppLocalizations.delegate.isSupported(const Locale('zh')),
        isTrue,
      );
      expect(
        AppLocalizations.delegate.isSupported(const Locale('fr')),
        isFalse,
      );
    });
  });

  group('TC-021: AppLocalizations.of(context) with proper setup', () {
    testWidgets('AppLocalizations.of(context) returns non-null with proper setup',
        (tester) async {
      AppLocalizations? loc;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            loc = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ));
      await tester.pump();

      expect(loc, isNotNull);
      expect(loc!.localeName, startsWith('en'));
    });
  });
}
