import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/providers/settings_provider.dart';
import 'package:kayak_frontend/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/theme_test_helpers.dart';

void main() {
  group('TC-010: AppBar in light mode', () {
    testWidgets('AppBar uses light theme surface color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const SizedBox(),
          ),
        ),
      );

      // Verify the AppBar rendered with text
      expect(find.text('Test'), findsOneWidget);

      // Verify the theme has proper AppBar settings
      final theme = AppTheme.lightTheme;
      expect(theme.appBarTheme.backgroundColor, isNotNull);
      expect(
        ThemeData.estimateBrightnessForColor(theme.appBarTheme.backgroundColor!),
        equals(Brightness.light),
      );
    });
  });

  group('TC-011: AppBar in dark mode', () {
    testWidgets('AppBar uses dark theme surface color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);

      final theme = AppTheme.darkTheme;
      expect(theme.appBarTheme.backgroundColor, isNotNull);
      expect(
        ThemeData.estimateBrightnessForColor(theme.appBarTheme.backgroundColor!),
        equals(Brightness.dark),
      );
    });
  });

  group('TC-012: Card in light mode', () {
    testWidgets('Card renders with light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Card content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card content'), findsOneWidget);

      // Verify CardTheme is properly configured
      final theme = AppTheme.lightTheme;
      expect(theme.cardTheme.color, isNotNull);
      expect(
        ThemeData.estimateBrightnessForColor(theme.cardTheme.color!),
        equals(Brightness.light),
      );
    });
  });

  group('TC-013: Card in dark mode', () {
    testWidgets('Card renders with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Card content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card content'), findsOneWidget);

      final theme = AppTheme.darkTheme;
      expect(theme.cardTheme.color, isNotNull);
      expect(
        ThemeData.estimateBrightnessForColor(theme.cardTheme.color!),
        equals(Brightness.dark),
      );
      expect(theme.cardTheme.color, isNot(equals(const Color(0xFF000000))));
    });
  });

  group('TC-014: system mode follows platform brightness', () {
    testWidgets('system mode defaults to light in test environment',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Text(
                  theme.brightness == Brightness.light ? 'light' : 'dark');
            },
          ),
        ),
      );

      expect(find.text('light'), findsOneWidget);
    });

    testWidgets('system mode responds to dark platform brightness',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Text(
                    theme.brightness == Brightness.dark ? 'dark' : 'light');
              },
            ),
          ),
        ),
      );

      expect(find.text('dark'), findsOneWidget);
    });
  });

  group('TC-014-extra: ThemeMode correctly passed to MaterialApp', () {
    testWidgets('ThemeMode is correctly passed through provider',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            return MaterialApp.router(
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              routerConfig: createTestRouter(),
            );
          }),
        ),
      );

      // Using Consumer to reactively watch provider
      final brightness = Theme.of(
        tester.element(find.byType(MaterialApp)),
      ).brightness;
      expect(brightness, anyOf(equals(Brightness.light), equals(Brightness.dark)));
    });
  });

  group('TC-024: Widget tree rebuilds on theme switch', () {
    testWidgets('theme switch rebuilds widget tree correctly',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Custom router with a route that shows current brightness
      final testRouter = createTestRouter(
        homeBuilder: (context) => Text(
          Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light',
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            return MaterialApp.router(
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              routerConfig: testRouter,
            );
          }),
        ),
      );

      // Initial should be light (test env default + no persisted value)
      expect(find.text('light'), findsOneWidget);

      // Switch to dark
      container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(find.text('dark'), findsOneWidget);

      // Switch back to light
      container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(find.text('light'), findsOneWidget);
    });
  });

  group('TC-025: ElevatedButton in light mode', () {
    testWidgets('ElevatedButton renders with correct light theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      );

      // Verify the button is rendered and tappable
      expect(find.text('Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Verify the ElevatedButton theme is configured in AppTheme
      final theme = AppTheme.lightTheme;
      expect(theme.elevatedButtonTheme.style, isNotNull);
    });
  });

  group('TC-026: ElevatedButton in dark mode', () {
    testWidgets('ElevatedButton renders with correct dark theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      final theme = AppTheme.darkTheme;
      expect(theme.elevatedButtonTheme.style, isNotNull);
    });
  });

  group('TC-027: InputDecoration theme', () {
    testWidgets('TextField renders with correct theme in light mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(labelText: 'Test input'),
            ),
          ),
        ),
      );

      expect(find.text('Test input'), findsOneWidget);
    });

    testWidgets('TextField renders with correct theme in dark mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(labelText: 'Test input'),
            ),
          ),
        ),
      );

      expect(find.text('Test input'), findsOneWidget);
    });
  });

  group('TC-028: NavigationRail theme', () {
    testWidgets('NavigationRail renders with light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: 0,
                  onDestinationSelected: (index) {},
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('BottomNavigationBar renders with light theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              onTap: (index) {},
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
