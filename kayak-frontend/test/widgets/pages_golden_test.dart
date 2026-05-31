import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kayak_frontend/pages/auth/login_page.dart';
import 'package:kayak_frontend/pages/auth/register_page.dart';
import 'package:kayak_frontend/pages/dashboard/dashboard_page.dart';
import 'package:kayak_frontend/pages/settings/settings_page.dart';
import 'package:kayak_frontend/pages/workbench/workbench_list_page.dart';
import 'package:kayak_frontend/pages/experiment/experiment_list_page.dart';
import 'package:kayak_frontend/pages/method/method_list_page.dart';
import 'package:kayak_frontend/pages/analysis/analysis_page.dart';

void main() {
  testWidgets('LoginPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const LoginPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden_files/pages_login.png'),
    );
  });

  testWidgets('RegisterPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const RegisterPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Register'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden_files/pages_register.png'),
    );
  });

  testWidgets('DashboardPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const DashboardPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden_files/pages_dashboard.png'),
    );
  });

  testWidgets('WorkbenchListPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const WorkbenchListPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Workbench List'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden_files/pages_workbench_list.png'),
    );
  });

  testWidgets('ExperimentListPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const ExperimentListPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Experiment List'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden_files/pages_experiment_list.png'),
    );
  });

  testWidgets('SettingsPage screenshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden_files/pages_settings.png'),
    );
  });
}
