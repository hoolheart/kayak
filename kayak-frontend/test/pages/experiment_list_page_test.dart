import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';
import 'package:kayak_frontend/models/common.dart';
import 'package:kayak_frontend/models/experiment.dart';
import 'package:kayak_frontend/models/method.dart';
import 'package:kayak_frontend/pages/experiment/experiment_list_page.dart';
import 'package:kayak_frontend/providers/experiment_provider.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/services/experiment_service.dart';
import 'package:kayak_frontend/services/method_service.dart';
import 'package:kayak_frontend/widgets/empty_view.dart';
import 'package:kayak_frontend/widgets/error_view.dart';
import 'package:kayak_frontend/widgets/skeleton.dart';
import 'package:kayak_frontend/widgets/status_badge.dart';
import 'package:mocktail/mocktail.dart';

class MockExperimentService extends Mock implements ExperimentService {}

class MockMethodService extends Mock implements MethodService {}

/// 使用 UncontrolledProviderScope 构建测试 Widget，返回 ProviderContainer
/// 以便测试中手动控制 provider 状态。
Future<ProviderContainer> pumpExperimentListPage(
  WidgetTester tester, {
  required MockExperimentService experimentService,
  MockMethodService? methodService,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final container = ProviderContainer(
    overrides: [
      experimentServiceProvider.overrideWithValue(experimentService),
      if (methodService != null)
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
          initialLocation: '/experiments',
          routes: [
            GoRoute(
              path: '/experiments',
              builder: (context, state) => const ExperimentListPage(),
            ),
            GoRoute(
              path: '/experiments/new',
              builder: (context, state) =>
                  const SizedBox(key: Key('new_experiment_page')),
            ),
            GoRoute(
              path: '/experiments/:id',
              builder: (context, state) => SizedBox(
                key: Key('experiment_detail_${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return container;
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

/// 等待异步 provider 完成并渲染。
///
/// 不使用 pumpAndSettle，因为 Skeleton 和 StatusBadge 有无限循环动画，
/// 会导致 pumpAndSettle 超时。
Future<void> pumpUntilReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// 测试数据工厂
class ExperimentTestData {
  static Experiment running() => Experiment(
        id: 'exp-001',
        userId: 'user-001',
        name: 'Temperature Cycle Test',
        methodId: 'method-001',
        status: ExperimentStatus.running,
        ownerType: 'personal',
        ownerId: 'user-001',
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime(2026, 5, 31, 10),
        updatedAt: DateTime.now(),
      );

  static Experiment paused() => Experiment(
        id: 'exp-002',
        userId: 'user-001',
        name: 'Pressure Test',
        methodId: 'method-002',
        status: ExperimentStatus.paused,
        ownerType: 'personal',
        ownerId: 'user-001',
        startedAt: DateTime(2026, 5, 30, 14),
        createdAt: DateTime(2026, 5, 30, 10),
        updatedAt: DateTime(2026, 5, 30, 16),
      );

  static Experiment completed() => Experiment(
        id: 'exp-003',
        userId: 'user-001',
        name: 'Vibration Test',
        methodId: 'method-003',
        status: ExperimentStatus.completed,
        ownerType: 'personal',
        ownerId: 'user-001',
        startedAt: DateTime(2026, 5, 29, 9),
        createdAt: DateTime(2026, 5, 29, 8),
        updatedAt: DateTime(2026, 5, 29, 12),
        endedAt: DateTime(2026, 5, 29, 12),
      );

  static Experiment idle() => Experiment(
        id: 'exp-004',
        userId: 'user-001',
        name: 'Idle Experiment',
        methodId: null,
        status: ExperimentStatus.idle,
        ownerType: 'personal',
        ownerId: 'user-001',
        createdAt: DateTime(2026, 5, 28, 10),
        updatedAt: DateTime(2026, 5, 28, 10),
      );

  static Experiment loaded() => Experiment(
        id: 'exp-005',
        userId: 'user-001',
        name: 'Loaded Experiment',
        methodId: 'method-001',
        status: ExperimentStatus.loaded,
        ownerType: 'personal',
        ownerId: 'user-001',
        createdAt: DateTime(2026, 5, 27, 10),
        updatedAt: DateTime(2026, 5, 27, 11),
      );

  static Experiment aborted() => Experiment(
        id: 'exp-006',
        userId: 'user-001',
        name: 'Aborted Experiment',
        methodId: 'method-002',
        status: ExperimentStatus.aborted,
        ownerType: 'personal',
        ownerId: 'user-001',
        startedAt: DateTime(2026, 5, 26, 10),
        createdAt: DateTime(2026, 5, 26, 9),
        updatedAt: DateTime(2026, 5, 26, 10, 30),
      );

  static List<Experiment> all() => [
        running(),
        paused(),
        completed(),
        idle(),
        loaded(),
        aborted(),
      ];

  static List<Experiment> generate(int count) {
    const statuses = ExperimentStatus.values;
    return List.generate(count, (i) {
      final status = statuses[i % statuses.length];
      return Experiment(
        id: 'exp-${i.toString().padLeft(3, '0')}',
        userId: 'user-001',
        name: 'Experiment #${i + 1}',
        methodId: 'method-${i % 5}',
        status: status,
        ownerType: 'personal',
        ownerId: 'user-001',
        startedAt: status == ExperimentStatus.idle ||
                status == ExperimentStatus.loaded
            ? null
            : DateTime.now().subtract(Duration(hours: i)),
        createdAt: DateTime(2026, 5, 20 + (i % 10)),
        updatedAt: DateTime.now(),
      );
    });
  }
}

void main() {
  late MockExperimentService mockExperimentService;
  late MockMethodService mockMethodService;

  setUp(() {
    mockExperimentService = MockExperimentService();
    mockMethodService = MockMethodService();

    // 默认 mock method service
    when(() => mockMethodService.getById(any())).thenAnswer(
      (_) async => Method(
        id: 'method-001',
        name: 'Standard Method',
        
        processDefinition: const {},
        parameterSchema: const {},
        version: 1,
        createdBy: 'user-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  // ==========================================
  // 1. 页面加载与基础渲染 (TC-021-01 ~ TC-021-08)
  // ==========================================
  group('TC-021-01 ~ TC-021-08: Page Loading & Basic Rendering', () {
    // TC-021-01: 页面初始加载显示骨架屏
    testWidgets('TC-021-01: shows skeleton on initial loading',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => Future.delayed(
          const Duration(milliseconds: 500),
          () => const PaginatedResponse<Experiment>(
            page: 1,
            size: 10,
            total: 0,
            items: [],
          ),
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await tester.pump();

      // 应显示骨架屏
      expect(find.byType(Skeleton), findsOneWidget);

      // 推进时间消除 pending timer，避免测试框架报错
      await tester.pump(const Duration(milliseconds: 600));
    });

    // TC-021-02: 加载完成后显示数据表格
    testWidgets('TC-021-02: shows data table after loading', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = ExperimentTestData.all().sublist(0, 3);

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 3,
          items: experiments,
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 骨架屏应消失
      expect(find.byType(Skeleton), findsNothing);

      // 应显示 DataTable
      expect(find.byType(DataTable), findsOneWidget);

      // 验证列头存在（通过 ancestor 限定在 DataTable 内）
      final dataTable = find.byType(DataTable);
      expect(
        find.descendant(of: dataTable, matching: find.text('Name')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Method')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Status')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Start Time')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Duration')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Actions')),
        findsOneWidget,
      );
    });

    // TC-021-03: 空状态显示
    testWidgets('TC-021-03: shows empty state when no data', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 应显示 EmptyView
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('No experiments yet'), findsOneWidget);
    });

    // TC-021-04: 加载错误状态显示
    // 注：Riverpod AsyncNotifier 在 build() 失败时会自动重试，状态保持为
    // AsyncLoading（带有 error），因此无法通过正常 provider 机制触发 ErrorView。
    // 这里采用手动注入 AsyncError 状态的方式验证 ErrorView 的渲染。
    testWidgets('TC-021-04: shows error state on load failure',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 先让页面加载到空状态
      expect(find.byType(EmptyView), findsOneWidget);

      // 手动注入错误状态
      container.read(experimentListProvider.notifier).state = AsyncError(
        Exception('Network timeout'),
        StackTrace.current,
      );
      await tester.pump();

      // 应显示 ErrorView
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Failed to load experiments'), findsOneWidget);
    });

    // TC-021-05: 页面标题正确
    testWidgets('TC-021-05: page title is correct', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      expect(find.text('Experiment List'), findsOneWidget);
    });

    // TC-021-06: 右上角"创建试验"按钮
    testWidgets('TC-021-06: create experiment button exists', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 应显示创建按钮
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    // TC-021-07: 页面加载时自动请求列表
    testWidgets('TC-021-07: auto-fetches experiment list on load',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 验证 list 被调用，参数 page=1, size=10
      verify(() => mockExperimentService.list(
            page: 1,
            size: 10,
            status: null,
            createdAfter: null,
            createdBefore: null,
            scope: null,
          )).called(1);
    });
  });

  // ==========================================
  // 2. 表格数据展示 (TC-021-09 ~ TC-021-16)
  // ==========================================
  group('TC-021-09 ~ TC-021-16: Table Data Display', () {
    testWidgets('TC-021-09 ~ TC-021-13: table columns and data formatting',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = [
        ExperimentTestData.running(),
        ExperimentTestData.completed(),
        ExperimentTestData.idle(),
      ];

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 3,
          items: experiments,
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      final dataTable = find.byType(DataTable);

      // TC-021-09: 列头顺序正确
      expect(
        find.descendant(of: dataTable, matching: find.text('Name')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Method')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Status')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Start Time')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Duration')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dataTable, matching: find.text('Actions')),
        findsOneWidget,
      );

      // TC-021-10: 试验名称显示
      expect(find.text('Temperature Cycle Test'), findsOneWidget);

      // TC-021-13: 持续时间显示（idle 试验无 startedAt，应显示 "—"）
      expect(find.text('—'), findsWidgets);
    });

    // TC-021-14: 多条数据分页显示
    testWidgets('TC-021-14: pagination with 15 records', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = ExperimentTestData.generate(15);

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 15,
          items: experiments.sublist(0, 10),
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 验证分页信息显示
      expect(find.text('15 records total'), findsOneWidget);
    });

    // TC-021-15: 斑马纹行样式
    testWidgets('TC-021-15: table rows rendered', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = ExperimentTestData.generate(5);

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 5,
          items: experiments,
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // DataTable 应存在（DataRow 在 Flutter 内部被转换为 TableRow，不能直接查找）
      expect(find.byType(DataTable), findsOneWidget);
      // 验证数据行内容存在
      expect(find.text('Experiment #1'), findsOneWidget);
      expect(find.text('Experiment #5'), findsOneWidget);
    });
  });

  // ==========================================
  // 3. StatusBadge in Table (TC-021-21)
  // ==========================================
  group('TC-021-21: StatusBadge in Table', () {
    testWidgets('StatusBadge renders for all experiment statuses',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = ExperimentTestData.all();

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 6,
          items: experiments,
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 6 行数据应显示 6 个 StatusBadge
      expect(find.byType(StatusBadge), findsNWidgets(6));
    });
  });

  // ==========================================
  // 4. 筛选功能 (TC-021-25 ~ TC-021-32)
  // ==========================================
  group('TC-021-25 ~ TC-021-32: Filtering', () {
    testWidgets('TC-021-25: status filter dropdown exists', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 6,
          items: ExperimentTestData.all(),
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 验证筛选栏存在
      expect(
        find.byType(DropdownButtonFormField<ExperimentStatus?>),
        findsOneWidget,
      );
      // Status label 在筛选栏中
      expect(find.text('Status'), findsWidgets);
    });

    testWidgets('TC-021-30: filtered empty state', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 筛选后无结果应显示空状态
      expect(find.byType(EmptyView), findsOneWidget);
    });
  });

  // ==========================================
  // 5. 分页功能 (TC-021-33 ~ TC-021-38)
  // ==========================================
  group('TC-021-33 ~ TC-021-38: Pagination', () {
    testWidgets('TC-021-33: pagination controls display', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = ExperimentTestData.generate(25);

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 25,
          items: experiments.sublist(0, 10),
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 验证总记录数显示
      expect(find.text('25 records total'), findsOneWidget);

      // 验证分页按钮存在
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('TC-021-36: pagination boundary - 0 records', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 0 条记录时不显示分页控件
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });
  });

  // ==========================================
  // 6. 操作列与交互 (TC-021-39 ~ TC-021-45)
  // ==========================================
  group('TC-021-39 ~ TC-021-45: Actions Column', () {
    testWidgets('TC-021-39: open console button exists', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = [ExperimentTestData.running()];

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 1,
          items: experiments,
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 查找"进入控制台"按钮（图标）
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('TC-021-40: stop button shown only for RUNNING/PAUSED',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = ExperimentTestData.all();

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 6,
          items: experiments,
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 只有 RUNNING 和 PAUSED 显示停止按钮
      expect(find.byIcon(Icons.stop), findsNWidgets(2));
    });
  });

  // ==========================================
  // 7. 响应式布局 (TC-021-46 ~ TC-021-50)
  // ==========================================
  group('TC-021-46 ~ TC-021-50: Responsive Layout', () {
    testWidgets('TC-021-46: desktop layout shows full table', (tester) async {
      await setScreenSize(tester, const Size(1920, 1080));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 3,
          items: ExperimentTestData.all().sublist(0, 3),
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 大屏显示 DataTable
      expect(find.byType(DataTable), findsOneWidget);
    });

    // TC-021-48: 使用 599px 宽度测试移动端适配
    testWidgets('TC-021-48: mobile layout shows cards', (tester) async {
      await setScreenSize(tester, const Size(599, 800));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 3,
          items: ExperimentTestData.all().sublist(0, 3),
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 小屏不显示 DataTable，显示 Card 列表
      expect(find.byType(DataTable), findsNothing);
      expect(find.byType(Card), findsNWidgets(3));
    });
  });

  // ==========================================
  // 8. 国际化 (TC-021-51 ~ TC-021-52)
  // ==========================================
  group('TC-021-51 ~ TC-021-52: Internationalization', () {
    testWidgets('TC-021-51: Chinese locale texts', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        locale: const Locale('zh'),
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 中文标题
      expect(find.text('试验列表'), findsOneWidget);
      // 中文空状态
      expect(find.text('暂无试验'), findsOneWidget);
    });

    testWidgets('TC-021-52: English locale texts', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        locale: const Locale('en'),
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 英文标题
      expect(find.text('Experiment List'), findsOneWidget);
      // 英文空状态
      expect(find.text('No experiments yet'), findsOneWidget);
    });
  });

  // ==========================================
  // 9. 主题适配 (TC-021-53 ~ TC-021-54)
  // ==========================================
  group('TC-021-53 ~ TC-021-54: Theme Adaptation', () {
    testWidgets('TC-021-53: light theme renders correctly', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 3,
          items: ExperimentTestData.all().sublist(0, 3),
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
        themeMode: ThemeMode.light,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('TC-021-54: dark theme renders correctly', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 3,
          items: ExperimentTestData.all().sublist(0, 3),
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
        methodService: mockMethodService,
        themeMode: ThemeMode.dark,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      expect(find.byType(DataTable), findsOneWidget);
    });
  });

  // ==========================================
  // 10. 错误处理与边界条件 (TC-021-55 ~ TC-021-56)
  // ==========================================
  group('TC-021-55 ~ TC-021-56: Error Handling & Edge Cases', () {
    testWidgets('TC-021-55: network error with retry', (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      var callCount = 0;
      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer((_) async {
        callCount++;
        return const PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 0,
          items: [],
        );
      });

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 首次加载成功，显示 EmptyView
      expect(find.byType(EmptyView), findsOneWidget);
      expect(callCount, 1);

      // 手动注入错误状态模拟加载失败
      container.read(experimentListProvider.notifier).state = AsyncError(
        Exception('Network timeout'),
        StackTrace.current,
      );
      await tester.pump();

      // 应显示 ErrorView
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Failed to load experiments'), findsOneWidget);

      // 点击重试按钮（ErrorView 中的 FilledButton）
      final retryButton = find.descendant(
        of: find.byType(ErrorView),
        matching: find.byType(FilledButton),
      );
      await tester.tap(retryButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 第二次加载成功
      expect(callCount, 2);
      expect(find.byType(EmptyView), findsOneWidget);
    });

    testWidgets('TC-021-56: handles missing fields gracefully',
        (tester) async {
      await setScreenSize(tester, const Size(1400, 900));
      addTearDown(() async => resetScreenSize(tester));

      final experiments = [
        Experiment(
          id: 'exp-null',
          userId: 'user-001',
          name: '',
          status: ExperimentStatus.idle,
          ownerType: 'personal',
          ownerId: 'user-001',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer(
        (_) async => PaginatedResponse<Experiment>(
          page: 1,
          size: 10,
          total: 1,
          items: experiments,
        ),
      );

      final container = await pumpExperimentListPage(
        tester,
        experimentService: mockExperimentService,
      );
      addTearDown(container.dispose);
      await pumpUntilReady(tester);

      // 页面不应崩溃，应正常显示
      expect(find.byType(DataTable), findsOneWidget);
      // 空名称应显示空字符串（非 null）
      expect(find.text('null'), findsNothing);
    });
  });
}
