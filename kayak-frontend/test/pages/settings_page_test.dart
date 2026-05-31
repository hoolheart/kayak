import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/pages/settings/settings_page.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_service.dart';

// ignore_for_file: prefer_const_constructors

// ============================================================
// Helpers
// ============================================================

/// Creates a test ProviderScope wrapping the SettingsPage with a controlled
/// FakeAuthService. Uses [FakeAuthService] with `hasToken: true` so the auth
/// provider resolves to a logged-in state during tests.
Future<Widget> createTestApp({
  FakeAuthService? fakeAuthService,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final authService = fakeAuthService ?? FakeAuthService(hasToken: true);

  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(authService),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SettingsPage(),
      ),
    ),
  );
}

AppLocalizations l10n(WidgetTester tester) {
  return AppLocalizations.of(
    tester.element(find.byType(SettingsPage)),
  )!;
}

// ============================================================
// Tests
// ============================================================

void main() {
  group('SettingsPage - Profile Page', () {
    testWidgets('displays user email and username from auth state',
        (tester) async {
      await tester.pumpWidget(await createTestApp());
      await tester.pumpAndSettle();

      // User info from FakeAuthService.getMe() should be displayed
      expect(find.text('admin@kayak.local'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('displays profile info section title', (tester) async {
      await tester.pumpWidget(await createTestApp());
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).profileInfo), findsOneWidget);
    });

    testWidgets('displays change password section title', (tester) async {
      await tester.pumpWidget(await createTestApp());
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).changePassword), findsOneWidget);
    });

    testWidgets('validates username length before save', (tester) async {
      await tester.pumpWidget(await createTestApp());
      await tester.pumpAndSettle();

      // Find the username text field and enter a short value
      final usernameField = find.byType(TextFormField).first;
      await tester.enterText(usernameField, 'ab'); // Too short (3-30)
      await tester.pumpAndSettle();

      // Press save
      await tester.tap(find.text(l10n(tester).save).last);
      await tester.pumpAndSettle();

      // Validation error should be shown
      expect(find.text(l10n(tester).usernameLengthError), findsOneWidget);
    });

    testWidgets('validates current password is required', (tester) async {
      await tester.pumpWidget(await createTestApp());
      await tester.pumpAndSettle();

      // Tap change password section to expand it
      await tester.tap(find.text(l10n(tester).changePassword));
      await tester.pumpAndSettle();

      // Scroll to make submit button visible
      final submitFinder = find.text(l10n(tester).submit).last;
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();

      // Tap submit without filling fields
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text(l10n(tester).currentPasswordRequired), findsOneWidget);
    });

    testWidgets('validates new password minimum length', (tester) async {
      await tester.pumpWidget(await createTestApp());
      await tester.pumpAndSettle();

      // Expand change password section
      await tester.tap(find.text(l10n(tester).changePassword));
      await tester.pumpAndSettle();

      // Fill fields with short new password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(1), 'OldP@ss123');
      await tester.enterText(textFields.at(2), 'Short');
      await tester.enterText(textFields.at(3), 'Short');
      await tester.pumpAndSettle();

      // Scroll to make submit button visible
      final submitFinder = find.text(l10n(tester).submit).last;
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();

      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).newPasswordMinLength), findsOneWidget);
    });

    testWidgets('validates confirm password matches new password',
        (tester) async {
      await tester.pumpWidget(await createTestApp());
      await tester.pumpAndSettle();

      // Expand change password section
      await tester.tap(find.text(l10n(tester).changePassword));
      await tester.pumpAndSettle();

      // Fill fields with mismatched passwords
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(1), 'OldP@ss123');
      await tester.enterText(textFields.at(2), 'NewP@ss123456');
      await tester.enterText(textFields.at(3), 'DifferentP@ss');
      await tester.pumpAndSettle();

      // Scroll to make submit button visible
      final submitFinder = find.text(l10n(tester).submit).last;
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();

      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).passwordsDoNotMatch), findsOneWidget);
    });

    testWidgets('responsively renders without overflow on mobile',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(await createTestApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });
}
