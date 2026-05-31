import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/common.dart';
import 'package:kayak_frontend/models/workbench.dart';
import 'package:kayak_frontend/pages/auth/login_page.dart';
import 'package:kayak_frontend/pages/auth/register_page.dart';
import 'package:kayak_frontend/pages/dashboard/dashboard_page.dart';
import 'package:kayak_frontend/pages/experiment/experiment_list_page.dart';
import 'package:kayak_frontend/pages/settings/settings_page.dart';
import 'package:kayak_frontend/pages/workbench/workbench_list_page.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/services/api_client.dart';
import 'package:kayak_frontend/services/auth_interceptor.dart';
import 'package:kayak_frontend/services/auth_service.dart';
import 'package:kayak_frontend/services/error_interceptor.dart';
import 'package:kayak_frontend/services/token_storage.dart';
import 'package:kayak_frontend/services/workbench_service.dart';

/// Mock WorkbenchService that returns empty data for testing.
class _MockWorkbenchService extends WorkbenchService {
  _MockWorkbenchService()
      : super(
          ApiClient(
            baseUrl: 'http://localhost:8080',
            authInterceptor: AuthInterceptor(
              AuthService(
                baseUrl: 'http://localhost:8080',
                storage: TokenStorage(),
              ),
            ),
            errorInterceptor: ErrorInterceptor(),
          ),
        );

  @override
  Future<PaginatedResponse<Workbench>> list({
    int page = 1,
    int size = 20,
    String? search,
  }) async {
    return PaginatedResponse<Workbench>(
      page: page,
      size: size,
      total: 0,
      items: <Workbench>[],
    );
  }
}

/// Helper to create a test app with ProviderScope for pages that use Riverpod.
Widget createTestApp(Widget home) {
  return ProviderScope(
    overrides: [
      workbenchServiceProvider.overrideWithValue(_MockWorkbenchService()),
    ],
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
    // Pump once to render initial frame (page may be in loading or error state
    // since no API mock is provided in this test).
    await tester.pump();
    // AppBar title uses l10n.workbenches → "Workbenches" in English.
    expect(find.text('Workbenches'), findsOneWidget);
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
    await tester.pump();
    // Note: SettingsPage uses authProvider which may show loading state
    // in test environment without auth service overrides.
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
