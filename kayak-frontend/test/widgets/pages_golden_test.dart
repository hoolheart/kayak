import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/pages/auth/login_page.dart';
import 'package:kayak_frontend/pages/auth/register_page.dart';
import 'package:kayak_frontend/pages/dashboard/dashboard_page.dart';
import 'package:kayak_frontend/pages/experiment/experiment_list_page.dart';
import 'package:kayak_frontend/pages/settings/settings_page.dart';
import 'package:kayak_frontend/pages/workbench/workbench_list_page.dart';

/// Helper to create a test app with ProviderScope for pages that use Riverpod.
Widget createTestApp(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  testWidgets('LoginPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      createTestApp(const LoginPage()),
    );
    await tester.pump();

    // Verify the page renders with the app title
    expect(find.text('Kayak'), findsOneWidget);
  });

  testWidgets('RegisterPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      createTestApp(const RegisterPage()),
    );
    await tester.pump();
    expect(find.text('Kayak'), findsOneWidget);
  });

  testWidgets('DashboardPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      createTestApp(const DashboardPage()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('WorkbenchListPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      createTestApp(const WorkbenchListPage()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Workbench List'), findsOneWidget);
  });

  testWidgets('ExperimentListPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      createTestApp(const ExperimentListPage()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Experiment List'), findsOneWidget);
  });

  testWidgets('SettingsPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      createTestApp(const SettingsPage()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
