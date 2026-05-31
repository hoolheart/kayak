import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/pages/settings/settings_page.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/providers/settings_provider.dart';

import '../helpers/fake_auth_service.dart';

/// Creates a test app with a logged-in user via [FakeAuthService].
///
/// Overrides [authServiceProvider] so [AuthNotifier.build] resolves to a
/// user, and [sharedPreferencesProvider] for locale/theme providers.
Future<Widget> _createTestApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(FakeAuthService(hasToken: true)),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsPage(),
    ),
  );
}

void main() {
  // -----------------------------------------------------------------
  // 1. 用户信息卡片 — 展示个人信息 + 编辑用户名表单 + 折叠的密码区域
  // -----------------------------------------------------------------
  testWidgets('Profile page info card screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _createTestApp());
    await tester.pumpAndSettle();

    // Verify basic content is present
    expect(find.text('Profile Information'), findsOneWidget);
    expect(find.text('admin@kayak.local'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);

    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('golden_files/profile_page_info.png'),
    );
  });

  // -----------------------------------------------------------------
  // 2. 编辑用户名状态 — 用户正在修改用户名
  // -----------------------------------------------------------------
  testWidgets('Profile page edit username screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _createTestApp());
    await tester.pumpAndSettle();

    // Clear the username field and enter a new value
    final usernameField = find.widgetWithText(TextFormField, 'Admin');
    await tester.enterText(usernameField, 'NewAdminName');
    await tester.pumpAndSettle();

    // Verify the new text appears
    expect(find.text('NewAdminName'), findsOneWidget);

    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('golden_files/profile_page_edit_username.png'),
    );
  });

  // -----------------------------------------------------------------
  // 3. 修改密码状态 — 密码表单已展开
  // -----------------------------------------------------------------
  testWidgets('Profile page change password screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _createTestApp());
    await tester.pumpAndSettle();

    // Tap the Change Password header to expand the password form
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    // Verify password fields are now visible
    expect(find.text('Current Password'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('golden_files/profile_page_change_password.png'),
    );
  });
}
