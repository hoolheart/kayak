import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/method.dart';
import 'package:kayak_frontend/pages/method/method_list_page.dart';
import 'package:kayak_frontend/providers/method_provider.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/services/method_service.dart';
import 'package:kayak_frontend/widgets/empty_view.dart';
import 'package:kayak_frontend/widgets/skeleton.dart' show ShimmerBlock;
import 'package:mocktail/mocktail.dart';

class MockMethodService extends Mock implements MethodService {}

/// 测试数据工厂
class MethodTestData {
  static Method standard() => Method(
        id: 'method-001',
        name: 'Tensile Test Standard',
        description: 'ASTM D638 standard tensile testing procedure',
        processDefinition: const {'nodes': <Map<String, dynamic>>[
          {'id': 'start', 'type': 'start'},
        ]},
        parameterSchema: const {
          'type': 'object',
          'properties': {
            'temperature': {'type': 'number'},
          },
        },
        version: 1,
        createdBy: 'user-001',
        createdAt: DateTime(2026, 6, 1, 10, 30),
        updatedAt: DateTime(2026, 6, 1, 10, 30),
        parameters: [
          const MethodParameter(
            key: 'temperature',
            type: 'number',
            label: 'Temperature',
            unit: '°C',
            isRequired: true,
          ),
        ],
      );

  static Method compress() => Method(
        id: 'method-002',
        name: 'Compression Test',
        description: 'Standard compression test procedure',
        processDefinition: const {'nodes': <Map<String, dynamic>>[
          {'id': 'start', 'type': 'start'},
        ]},
        parameterSchema: const {'type': 'object', 'properties': {}},
        version: 1,
        createdBy: 'user-001',
        createdAt: DateTime(2026, 6, 2, 14),
        updatedAt: DateTime(2026, 6, 2, 14),
      );

  static Method fatigueA() => Method(
        id: 'method-003',
        name: 'Fatigue Test A',
        description: 'High-cycle fatigue testing',
        processDefinition: const {'nodes': <Map<String, dynamic>>[
          {'id': 'start', 'type': 'start'},
        ]},
        parameterSchema: const {'type': 'object', 'properties': {}},
        version: 1,
        createdBy: 'user-001',
        createdAt: DateTime(2026, 6, 3, 9),
        updatedAt: DateTime(2026, 6, 3, 9),
      );

  static Method fatigueB() => Method(
        id: 'method-004',
        name: 'Fatigue Test B',
        description: 'Low-cycle fatigue testing',
        processDefinition: const {'nodes': <Map<String, dynamic>>[
          {'id': 'start', 'type': 'start'},
        ]},
        parameterSchema: const {'type': 'object', 'properties': {}},
        version: 1,
        createdBy: 'user-001',
        createdAt: DateTime(2026, 6, 4, 11),
        updatedAt: DateTime(2026, 6, 4, 11),
      );

  static Method thermal() => Method(
        id: 'method-005',
        name: 'Thermal Analysis',
        description: 'Thermal analysis procedure',
        processDefinition: const {'nodes': <Map<String, dynamic>>[
          {'id': 'start', 'type': 'start'},
        ]},
        parameterSchema: const {'type': 'object', 'properties': {}},
        version: 1,
        createdBy: 'user-001',
        createdAt: DateTime(2026, 6, 5, 16, 30),
        updatedAt: DateTime(2026, 6, 5, 16, 30),
      );

  static List<Method> all() => [
        standard(),
        compress(),
        fatigueA(),
        fatigueB(),
        thermal(),
      ];
}

/// 设置屏幕尺寸
Future<void> setScreenSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

/// 恢复默认屏幕尺寸
Future<void> resetScreenSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(null);
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
}

/// 等待异步 provider 完成并渲染
Future<void> pumpUntilReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

/// 构建 MethodListPage 测试环境
Future<ProviderContainer> pumpMethodListPage(
  WidgetTester tester, {
  required MockMethodService methodService,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final container = ProviderContainer(
    overrides: [
      methodServiceProvider.overrideWithValue(methodService),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: ThemeData(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: '/methods',
          routes: [
            GoRoute(
              path: '/methods',
              builder: (context, state) => const MethodListPage(),
            ),
            GoRoute(
              path: '/methods/new/edit',
              builder: (context, state) =>
                  const SizedBox(key: Key('method_edit_page_new')),
            ),
            GoRoute(
              path: '/methods/:id/edit',
              builder: (context, state) => SizedBox(
                key: Key('method_edit_page_${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return container;
}

void main() {
  late MockMethodService mockMethodService;

  setUp(() {
    mockMethodService = MockMethodService();
  });

  // ==========================================
  // 1. Loading 状态 (TC-001)
  // ==========================================
  group('TC-001: Loading skeleton screen', () {
    testWidgets('shows skeleton on initial loading', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => Future.delayed(
          const Duration(seconds: 1),
          () => <Method>[],
        ),
      );

      final container = await pumpMethodListPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await tester.pump();

      // Should show skeleton shimmer blocks
      expect(find.byType(ShimmerBlock), findsWidgets);
      // Should show appbar
      expect(find.text('Method List'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    });
  });

  // ==========================================
  // 2. Data state with card list (TC-002)
  // ==========================================
  group('TC-002: Data state with card list', () {
    testWidgets('shows method cards when data loaded', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => MethodTestData.all(),
      );

      final container = await pumpMethodListPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Each method name should be visible
      expect(find.text('Tensile Test Standard'), findsOneWidget);
      expect(find.text('Compression Test'), findsOneWidget);
      expect(find.text('Fatigue Test A'), findsOneWidget);
      expect(find.text('Fatigue Test B'), findsOneWidget);
      expect(find.text('Thermal Analysis'), findsOneWidget);

      // Parameter count should be shown for the one with parameters
      expect(find.text('1 parameters'), findsOneWidget);
      // Others should have 0 parameters
      expect(find.text('0 parameters'), findsWidgets);
    });
  });

  // ==========================================
  // 3. Empty state (TC-005)
  // ==========================================
  group('TC-005: Empty state guidance', () {
    testWidgets('shows empty view when no methods', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodListPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Should show empty view
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('No methods yet'), findsOneWidget);
      expect(find.text('Create First Method'), findsOneWidget);
    });
  });

  // ==========================================
  // 4. Error state (TC-006)
  // ==========================================
  group('TC-006: Error state + retry', () {
    testWidgets('shows error view on load failure', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => MethodTestData.all(),
      );

      final container = await pumpMethodListPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Manually set error state
      container.read(methodListProvider.notifier).state = AsyncError(
        Exception('Network error'),
        StackTrace.current,
      );
      await tester.pump();

      // Should show error text
      expect(find.text('Failed to load experiments'), findsOneWidget);
    });

    testWidgets('retry button works after error', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => MethodTestData.all().sublist(0, 1),
      );

      final container = await pumpMethodListPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Start with data loaded
      expect(find.text('Tensile Test Standard'), findsOneWidget);

      // Manually set error state
      container.read(methodListProvider.notifier).state = AsyncError(
        Exception('Network error'),
        StackTrace.current,
      );
      await tester.pump();

      // Should show error text
      expect(find.text('Failed to load experiments'), findsOneWidget);

      // Tap retry button
      final retryButton = find.text('Retry');
      await tester.tap(retryButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should reload and show data again
      expect(find.text('Tensile Test Standard'), findsOneWidget);
    });
  });

  // ==========================================
  // 5. Search filtering (TC-007)
  // ==========================================
  group('TC-007: Search filtering', () {
    testWidgets('search filters method list', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => MethodTestData.all(),
      );

      final container = await pumpMethodListPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // All 5 methods should be visible
      expect(find.text('Tensile Test Standard'), findsOneWidget);

      // Type in search box
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Fatigue');
      await tester.pump(const Duration(milliseconds: 500));

      // Should show only Fatigue A and Fatigue B
      expect(find.text('Fatigue Test A'), findsOneWidget);
      expect(find.text('Fatigue Test B'), findsOneWidget);
      expect(find.text('Tensile Test Standard'), findsNothing);
    });
  });

  // ==========================================
  // 6. Create button navigation (TC-012)
  // ==========================================
  group('TC-012: Create button navigation', () {
    testWidgets('create button navigates to new method page',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodListPage(
        tester,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Click the create button
      final createButton = find.byKey(const Key('method-create'));
      expect(createButton, findsOneWidget);

      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Should navigate to create page
      expect(find.byKey(const Key('method_edit_page_new')), findsOneWidget);
    });
  });

  // ==========================================
  // 7. l10n — Chinese locale (TC-005 locale variant)
  // ==========================================
  group('TC-005: l10n Chinese locale', () {
    testWidgets('shows Chinese text with zh locale', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockMethodService.list()).thenAnswer(
        (_) async => <Method>[],
      );

      final container = await pumpMethodListPage(
        tester,
        methodService: mockMethodService,
        locale: const Locale('zh'),
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // Chinese empty state
      expect(find.text('暂无方法'), findsOneWidget);
      expect(find.text('创建第一个方法'), findsOneWidget);
      // Chinese app bar title
      expect(find.text('方法列表'), findsOneWidget);
    });
  });
}
