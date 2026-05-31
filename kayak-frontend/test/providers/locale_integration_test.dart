import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kayak_frontend/app.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TC-014: MaterialApp.router has supportedLocales set', () {
    testWidgets('MaterialApp.router has supportedLocales set', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: KayakApp()),
      );
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.supportedLocales, isNotNull);
      expect(materialApp.supportedLocales, contains(const Locale('en')));
      expect(materialApp.supportedLocales, contains(const Locale('zh')));
    });
  });

  group('TC-015: MaterialApp.router has all required localization delegates', () {
    testWidgets('MaterialApp.router has all required localization delegates',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: KayakApp()),
      );
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.localizationsDelegates, isNotNull);
      expect(materialApp.localizationsDelegates,
          contains(AppLocalizations.delegate));
      expect(materialApp.localizationsDelegates,
          contains(GlobalMaterialLocalizations.delegate));
      expect(materialApp.localizationsDelegates,
          contains(GlobalWidgetsLocalizations.delegate));
      expect(materialApp.localizationsDelegates,
          contains(GlobalCupertinoLocalizations.delegate));
    });
  });

  group('TC-016: MaterialApp.router locale binds to LocaleNotifier', () {
    testWidgets('MaterialApp.router locale binds to LocaleNotifier',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ]);
      addTearDown(container.dispose);

      // Create a simple test router without auth redirect guard
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Home')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeProvider);
              return MaterialApp.router(
                title: 'Kayak',
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Verify English locale is default
      var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale?.languageCode, equals('en'));

      // Switch to Chinese
      container
          .read(localeProvider.notifier)
          .setLocale(const Locale('zh'));
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale?.languageCode, equals('zh'));
    });
  });
}
