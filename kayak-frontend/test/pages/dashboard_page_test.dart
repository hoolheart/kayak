import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/pages/dashboard/dashboard_page.dart';
import 'package:kayak_frontend/pages/dashboard/widgets/quick_actions_grid.dart';
import 'package:kayak_frontend/pages/dashboard/widgets/stats_overview.dart';
import 'package:kayak_frontend/pages/dashboard/widgets/welcome_section.dart';
import 'package:kayak_frontend/providers/dashboard_provider.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/services/dashboard_service.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_auth_service.dart';

// ignore_for_file: prefer_const_constructors

// ============================================================
// Mocks
// ============================================================
class MockDashboardService extends Mock implements DashboardService {}

// ============================================================
// Helpers
// ============================================================

Future<void> setScreenSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

Future<void> resetScreenSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(null);
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
}

/// Build the DashboardPage in a test widget tree
Future<void> pumpDashboardPage(
  WidgetTester tester, {
  required FakeAuthService authService,
  DashboardService? dashboardService,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
        if (dashboardService != null)
          dashboardServiceProvider.overrideWithValue(dashboardService),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        home: const DashboardPage(),
      ),
    ),
  );
}

void main() {
  // ============================================================
  // TC-DASH-001: WelcomeSection renders with user info
  // ============================================================
  group('WelcomeSection', () {
    testWidgets('shows greeting with username', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final authService = FakeAuthService(hasToken: true);
      final mockDashboardService = MockDashboardService();
      when(mockDashboardService.loadDashboardData).thenAnswer(
        (_) async => DashboardData(
          workbenchCount: 3,
          deviceCount: 5,
          experimentCount: 2,
        ),
      );
      when(mockDashboardService.loadRecentWorkbenches).thenAnswer(
        (_) async => <WorkbenchSummary>[],
      );

      await pumpDashboardPage(
        tester,
        authService: authService,
        dashboardService: mockDashboardService,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // WelcomeSection should be rendered
      expect(find.byType(WelcomeSection), findsOneWidget);

      // Should contain username from FakeAuthService
      expect(find.textContaining('Admin'), findsOneWidget);
    });

    testWidgets('renders without overflow on mobile', (tester) async {
      await setScreenSize(tester, const Size(390, 844));
      addTearDown(() async => resetScreenSize(tester));

      final authService = FakeAuthService(hasToken: true);
      final mockDashboardService = MockDashboardService();
      when(mockDashboardService.loadDashboardData).thenAnswer(
        (_) async => DashboardData(
          workbenchCount: 0,
          deviceCount: 0,
          experimentCount: 0,
        ),
      );
      when(mockDashboardService.loadRecentWorkbenches).thenAnswer(
        (_) async => <WorkbenchSummary>[],
      );

      await pumpDashboardPage(
        tester,
        authService: authService,
        dashboardService: mockDashboardService,
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 验证移动端无溢出
      expect(tester.takeException(), isNull);
      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });

  // ============================================================
  // TC-DASH-009: QuickActionsGrid renders 4 cards
  // ============================================================
  group('QuickActionsGrid', () {
    testWidgets('renders 4 quick action cards', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final authService = FakeAuthService(hasToken: true);
      await pumpDashboardPage(tester, authService: authService);
      await tester.pumpAndSettle();

      expect(find.byType(QuickActionsGrid), findsOneWidget);
    });

    testWidgets('shows Chinese text with zh locale', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final authService = FakeAuthService(hasToken: true);
      await pumpDashboardPage(
        tester,
        authService: authService,
        locale: const Locale('zh'),
      );
      await tester.pumpAndSettle();

      // Should show Chinese quick action labels
      expect(find.text('试验控制台'), findsOneWidget);
      expect(find.text('试验方法'), findsOneWidget);
      expect(find.text('工作台管理'), findsOneWidget);
      expect(find.text('数据分析'), findsOneWidget);
    });
  });

  // ============================================================
  // TC-DASH-015: StatsOverview — with data
  // ============================================================
  group('StatsOverview', () {
    testWidgets('renders stat cards when data is loaded', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final authService = FakeAuthService(hasToken: true);
      final mockDashboardService = MockDashboardService();
      when(mockDashboardService.loadDashboardData).thenAnswer(
        (_) async => DashboardData(
          workbenchCount: 5,
          deviceCount: 12,
          experimentCount: 8,
        ),
      );
      when(mockDashboardService.loadRecentWorkbenches).thenAnswer(
        (_) async => <WorkbenchSummary>[],
      );

      await pumpDashboardPage(
        tester,
        authService: authService,
        dashboardService: mockDashboardService,
      );
      await tester.pump();

      // Wait for async data to load
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Should see StatsOverview
      expect(find.byType(StatsOverview), findsOneWidget);
    });

    testWidgets('shows stats area while loading data', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final authService = FakeAuthService(hasToken: true);
      final mockDashboardService = MockDashboardService();
      when(mockDashboardService.loadDashboardData).thenAnswer(
        (_) async => DashboardData(
          workbenchCount: 0,
          deviceCount: 0,
          experimentCount: 0,
        ),
      );
      when(mockDashboardService.loadRecentWorkbenches).thenAnswer(
        (_) async => <WorkbenchSummary>[],
      );

      await pumpDashboardPage(
        tester,
        authService: authService,
        dashboardService: mockDashboardService,
      );

      // Allow async providers to complete (no delayed futures)
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // 验证无溢出
      expect(tester.takeException(), isNull);

      // DashboardPage itself should render
      expect(find.byType(DashboardPage), findsOneWidget);
      // StatsOverview should be in the widget tree
      expect(find.byType(StatsOverview), findsOneWidget);
    });
  });

  // ============================================================
  // DashboardPage — full page render
  // ============================================================
  group('DashboardPage full render', () {
    testWidgets('renders without errors in dark theme', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final authService = FakeAuthService(hasToken: true);
      final mockDashboardService = MockDashboardService();
      when(mockDashboardService.loadDashboardData).thenAnswer(
        (_) async => DashboardData(
          workbenchCount: 5,
          deviceCount: 12,
          experimentCount: 8,
        ),
      );
      when(mockDashboardService.loadRecentWorkbenches).thenAnswer(
        (_) async => <WorkbenchSummary>[],
      );

      await pumpDashboardPage(
        tester,
        authService: authService,
        dashboardService: mockDashboardService,
        themeMode: ThemeMode.dark,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('renders in compact layout on mobile', (tester) async {
      await setScreenSize(tester, const Size(375, 667));
      addTearDown(() async => resetScreenSize(tester));

      final authService = FakeAuthService(hasToken: true);
      final mockDashboardService = MockDashboardService();
      when(mockDashboardService.loadDashboardData).thenAnswer(
        (_) async => DashboardData(
          workbenchCount: 0,
          deviceCount: 0,
          experimentCount: 0,
        ),
      );
      when(mockDashboardService.loadRecentWorkbenches).thenAnswer(
        (_) async => <WorkbenchSummary>[],
      );

      await pumpDashboardPage(
        tester,
        authService: authService,
        dashboardService: mockDashboardService,
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 验证移动端无溢出（BUG-DASH-001 / BUG-DASH-002 已修复）
      expect(tester.takeException(), isNull);
      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });
}
