import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/widgets/app_shell.dart';

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

void main() {
  testWidgets('AppShell desktop layout screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    const localizationDelegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
    const supportedLocales = AppLocalizations.supportedLocales;

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(useMaterial3: true),
        localizationsDelegates: localizationDelegates,
        supportedLocales: supportedLocales,
        routerConfig: _createTestRouter(
          child: const Scaffold(
            body: Center(child: Text('Content Area')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppShell renders
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Content Area'), findsOneWidget);
  });

  testWidgets('AppShell mobile layout screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    const localizationDelegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
    const supportedLocales = AppLocalizations.supportedLocales;

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(useMaterial3: true),
        localizationsDelegates: localizationDelegates,
        supportedLocales: supportedLocales,
        routerConfig: _createTestRouter(
          child: const Scaffold(
            body: Center(child: Text('Content Area')),
          ),
        ),
      ),
    );
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
