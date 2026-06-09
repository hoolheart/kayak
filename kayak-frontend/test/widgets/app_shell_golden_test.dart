import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/providers/settings_provider.dart';
import 'package:kayak_frontend/widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _createTestRouter({required Widget child}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => child,
          ),
        ],
      ),
    ],
  );
}

Future<ProviderScope> _createApp({required Widget child}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp.router(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _createTestRouter(
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('AppShell desktop layout screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    final app = await _createApp(
      child: const Scaffold(
        body: Center(child: Text('Content Area')),
      ),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Verify AppShell renders
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Content Area'), findsOneWidget);
  });

  testWidgets('AppShell mobile layout screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    final app = await _createApp(
      child: const Scaffold(
        body: Center(child: Text('Content Area')),
      ),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Mobile should show BottomNavigationBar
    expect(find.byType(NavigationBar), findsWidgets);
  });

  testWidgets('LoginPage placeholder screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: Center(child: Text('Login')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden_files/test_login_placeholder.png'),
    );
  });
}
