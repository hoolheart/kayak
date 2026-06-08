import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/common.dart';
import 'package:kayak_frontend/models/device.dart';
import 'package:kayak_frontend/models/experiment.dart';
import 'package:kayak_frontend/models/workbench.dart';
import 'package:kayak_frontend/pages/auth/login_page.dart';
import 'package:kayak_frontend/pages/auth/register_page.dart';
import 'package:kayak_frontend/pages/dashboard/dashboard_page.dart';
import 'package:kayak_frontend/pages/experiment/experiment_list_page.dart';
import 'package:kayak_frontend/pages/settings/settings_page.dart';
import 'package:kayak_frontend/pages/workbench/workbench_list_page.dart';
import 'package:kayak_frontend/providers/dashboard_provider.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/services/api_client.dart';
import 'package:kayak_frontend/services/auth_interceptor.dart';
import 'package:kayak_frontend/services/auth_service.dart';
import 'package:kayak_frontend/services/dashboard_service.dart';
import 'package:kayak_frontend/services/device_service.dart';
import 'package:kayak_frontend/services/error_interceptor.dart';
import 'package:kayak_frontend/services/experiment_service.dart';
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

/// Mock ExperimentService that returns empty data for testing.
class _MockExperimentService extends ExperimentService {
  _MockExperimentService()
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
  Future<PaginatedResponse<Experiment>> list({
    int page = 1,
    int size = 10,
    ExperimentStatus? status,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? scope,
  }) async {
    return PaginatedResponse<Experiment>(
      page: page,
      size: size,
      total: 0,
      items: <Experiment>[],
    );
  }
}

/// Mock DeviceService that returns empty data for testing.
class _MockDeviceService extends DeviceService {
  _MockDeviceService()
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
  Future<List<Device>> listByWorkbench(String workbenchId) async {
    return <Device>[];
  }
}

/// Mock DashboardService that returns empty dashboard data.
class _MockDashboardService extends DashboardService {
  _MockDashboardService()
      : super(
          workbenchService: _MockWorkbenchService(),
          experimentService: _MockExperimentService(),
          deviceService: _MockDeviceService(),
        );

  @override
  Future<DashboardData> loadDashboardData() async {
    return const DashboardData(
      workbenchCount: 0,
      deviceCount: 0,
      experimentCount: 0,
    );
  }

  @override
  Future<List<WorkbenchSummary>> loadRecentWorkbenches() async {
    return <WorkbenchSummary>[];
  }
}

/// Helper to create a test app with ProviderScope for pages that use Riverpod.
Widget createTestApp(Widget home) {
  return ProviderScope(
    overrides: [
      workbenchServiceProvider.overrideWithValue(_MockWorkbenchService()),
      dashboardServiceProvider.overrideWithValue(_MockDashboardService()),
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
    // Pump enough to advance past the 300ms skeleton delay
    await tester.pump(const Duration(milliseconds: 500));
    // Pump again to let the UI settle (providers will attempt to load)
    await tester.pump();
    await tester.pump();
    // Verify the dashboard page rendered
    expect(find.byType(DashboardPage), findsOneWidget);
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
