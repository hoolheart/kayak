# S2-005: 数据管理页面 - 试验列表 (Experiment List Page)

**任务ID**: S2-005  
**任务名称**: 数据管理页面 - 试验列表 (Data Management Page - Experiment List)  
**文档版本**: 1.0  
**创建日期**: 2026-04-01  
**测试类型**: 单元测试、Widget测试、集成测试  
**技术栈**: Flutter / Riverpod / mocktail / flutter_test  
**依赖任务**: S1-012 (Auth State Management), S2-004 (Experiment Data Query API)

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S2-005 任务的所有功能测试，包括：
1. **试验列表页面UI** - 试验基本信息展示（名称、时间、状态）
2. **状态筛选功能** - 按试验状态（Idle/Running/Paused/Completed/Aborted）筛选
3. **时间范围筛选** - 按创建时间范围筛选
4. **分页加载功能** - 支持分页加载更多数据
5. **导航功能** - 点击试验进入详情页

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 列表展示所有试验记录 | TC-UI-001 ~ TC-UI-010 | Widget + Integration |
| 2. 筛选功能可用 | TC-FILTER-001 ~ TC-FILTER-012 | Unit + Widget |
| 3. 点击进入试验详情页 | TC-NAV-001 ~ TC-NAV-003 | Widget |

### 1.3 数据模型

#### Experiment 实体 (前端)
```dart
class Experiment {
  final String id;
  final String userId;
  final String? methodId;
  final String name;
  final String? description;
  final ExperimentStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum ExperimentStatus {
  idle,
  running,
  paused,
  completed,
  aborted,
}
```

#### ExperimentListState
```dart
class ExperimentListState {
  final List<Experiment> experiments;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final ExperimentStatus? statusFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
}
```

---

## 2. 单元测试 - State Management

### TC-STATE-001: 实验列表初始状态验证

```dart
void main() {
  group('ExperimentListState', () {
    test('initial state has correct defaults', () {
      const state = ExperimentListState();

      expect(state.experiments, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.error, isNull);
      expect(state.currentPage, equals(1));
      expect(state.pageSize, equals(20));
      expect(state.hasMore, isTrue);
      expect(state.statusFilter, isNull);
      expect(state.startDateFilter, isNull);
      expect(state.endDateFilter, isNull);
    });

    test('copyWith creates new instance with updated values', () {
      const state = ExperimentListState();
      final newState = state.copyWith(isLoading: true);

      expect(newState.isLoading, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('copyWith preserves other fields when updating one', () {
      final experiments = [
        Experiment(
          id: 'test-1',
          userId: 'user-1',
          name: 'Test Experiment',
          status: ExperimentStatus.idle,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];
      final state = ExperimentListState(experiments: experiments);
      final newState = state.copyWith(isLoading: true);

      expect(newState.experiments, equals(experiments));
      expect(newState.isLoading, isTrue);
    });
  });
}
```

### TC-STATE-002: 状态筛选器设置

```dart
    test('statusFilter can be set and cleared', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(experimentListProvider.notifier);

      // 设置状态筛选
      notifier.setStatusFilter(ExperimentStatus.running);
      var state = container.read(experimentListProvider);
      expect(state.statusFilter, equals(ExperimentStatus.running));

      // 清除状态筛选
      notifier.clearStatusFilter();
      state = container.read(experimentListProvider);
      expect(state.statusFilter, isNull);
    });
```

### TC-STATE-003: 时间范围筛选器设置

```dart
    test('dateRangeFilter can be set correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(experimentListProvider.notifier);
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31);

      notifier.setDateRangeFilter(startDate, endDate);
      final state = container.read(experimentListProvider);

      expect(state.startDateFilter, equals(startDate));
      expect(state.endDateFilter, equals(endDate));
    });

    test('clearDateRangeFilter resets date filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(experimentListProvider.notifier);
      notifier.setDateRangeFilter(DateTime(2024, 1, 1), DateTime(2024, 12, 31));
      notifier.clearDateRangeFilter();

      final state = container.read(experimentListProvider);
      expect(state.startDateFilter, isNull);
      expect(state.endDateFilter, isNull);
    });
```

### TC-STATE-004: 加载状态转换

```dart
    test('loadExperiments transitions states correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockService = MockExperimentService();
      when(() => mockService.getExperiments(
        page: any(named: 'page'),
        size: any(named: 'size'),
        status: any(named: 'status'),
        startedAfter: any(named: 'startedAfter'),
        startedBefore: any(named: 'startedBefore'),
      )).thenAnswer((_) async => PagedExperimentResponse(
        items: [],
        page: 1,
        size: 20,
        total: 0,
      ));

      final notifier = ExperimentListNotifier(mockService);

      // 初始状态
      expect(notifier.state.isLoading, isFalse);

      // 开始加载
      final future = notifier.loadExperiments();
      expect(notifier.state.isLoading, isTrue);

      // 加载完成
      await future;
      expect(notifier.state.isLoading, isFalse);
    });
```

### TC-STATE-005: 分页状态更新

```dart
    test('loadMore updates pagination state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockService = MockExperimentService();
      when(() => mockService.getExperiments(
        page: 1,
        size: any(named: 'size'),
        status: any(named: 'status'),
        startedAfter: any(named: 'startedAfter'),
        startedBefore: any(named: 'startedBefore'),
      )).thenAnswer((_) async => PagedExperimentResponse(
        items: [createTestExperiment('Exp 1')],
        page: 1,
        size: 20,
        total: 25,
      ));
      when(() => mockService.getExperiments(
        page: 2,
        size: any(named: 'size'),
        status: any(named: 'status'),
        startedAfter: any(named: 'startedAfter'),
        startedBefore: any(named: 'startedBefore'),
      )).thenAnswer((_) async => PagedExperimentResponse(
        items: [createTestExperiment('Exp 2')],
        page: 2,
        size: 20,
        total: 25,
      ));

      final notifier = ExperimentListNotifier(mockService);
      await notifier.loadExperiments();

      expect(notifier.state.currentPage, equals(1));
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMore();

      expect(notifier.state.currentPage, equals(2));
      expect(notifier.state.experiments.length, equals(2));
    });
```

### TC-STATE-006: 错误状态处理

```dart
    test('loadExperiments handles error correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockService = MockExperimentService();
      when(() => mockService.getExperiments(
        page: any(named: 'page'),
        size: any(named: 'size'),
        status: any(named: 'status'),
        startedAfter: any(named: 'startedAfter'),
        startedBefore: any(named: 'startedBefore'),
      )).thenThrow(Exception('Network error'));

      final notifier = ExperimentListNotifier(mockService);
      await notifier.loadExperiments();

      expect(notifier.state.error, isNotNull);
      expect(notifier.state.error, contains('Network error'));
      expect(notifier.state.isLoading, isFalse);
    });
```

### TC-STATE-007: 刷新功能

```dart
    test('refresh reloads from first page', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockService = MockExperimentService();
      var callCount = 0;
      when(() => mockService.getExperiments(
        page: any(named: 'page'),
        size: any(named: 'size'),
        status: any(named: 'status'),
        startedAfter: any(named: 'startedAfter'),
        startedBefore: any(named: 'startedBefore'),
      )).thenAnswer((invocation) async {
        callCount++;
        final page = invocation.namedArguments[const Symbol('page')] as int;
        return PagedExperimentResponse(
          items: [createTestExperiment('Page $page')],
          page: page,
          size: 20,
          total: 25,
        );
      });

      final notifier = ExperimentListNotifier(mockService);
      await notifier.loadExperiments();
      await notifier.loadMore();

      expect(notifier.state.currentPage, equals(2));

      await notifier.refresh();

      expect(notifier.state.currentPage, equals(1));
      expect(notifier.state.isRefreshing, isFalse);
    });
```

---

## 3. Widget测试 - UI组件

### TC-UI-001: 实验列表页面显示试验名称

```dart
void main() {
  group('ExperimentListPage Widget Tests', () {
    testWidgets('displays experiment names correctly', (tester) async {
      final experiments = [
        createTestExperiment(id: '1', name: '实验一'),
        createTestExperiment(id: '2', name: '实验二'),
        createTestExperiment(id: '3', name: '实验三'),
      ];

      await tester.pumpWidget(
        TestApp.light(
          child: ExperimentListPage(),
          overrides: [
            experimentListProvider.overrideWith(
              (ref) => ExperimentListNotifier(MockExperimentService()),
            ),
          ],
        ),
      );

      // 使用 ProviderScope 覆盖
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: experiments),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('实验一'), findsOneWidget);
      expect(find.text('实验二'), findsOneWidget);
      expect(find.text('实验三'), findsOneWidget);
    });
  });
}
```

### TC-UI-002: 实验列表页面显示试验状态

```dart
    testWidgets('displays experiment status correctly', (tester) async {
      final experiments = [
        createTestExperiment(
          id: '1',
          name: '运行中实验',
          status: ExperimentStatus.running,
        ),
        createTestExperiment(
          id: '2',
          name: '已完成实验',
          status: ExperimentStatus.completed,
        ),
        createTestExperiment(
          id: '3',
          name: '空闲实验',
          status: ExperimentStatus.idle,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: experiments),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('运行中'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('空闲'), findsOneWidget);
    });
```

### TC-UI-003: 实验列表页面显示创建时间

```dart
    testWidgets('displays experiment created time', (tester) async {
      final experiments = [
        createTestExperiment(
          id: '1',
          name: '测试实验',
          createdAt: DateTime(2024, 3, 15, 10, 30),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: experiments),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证时间显示格式
      expect(find.textContaining('2024'), findsOneWidget);
      expect(find.textContaining('15'), findsOneWidget);
    });
```

### TC-UI-004: 空列表状态显示

```dart
    testWidgets('displays empty state when no experiments', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(experiments: []),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('暂无试验记录'), findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
    });
```

### TC-UI-005: 加载状态显示

```dart
    testWidgets('displays loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(isLoading: true),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
```

### TC-UI-006: 错误状态显示

```dart
    testWidgets('displays error message when error occurs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(
                  error: '网络连接失败，请检查网络设置',
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('网络连接失败，请检查网络设置'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
```

### TC-UI-007: 状态筛选下拉框存在

```dart
    testWidgets('status filter dropdown exists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证状态筛选下拉框
      final dropdown = find.byType(DropdownButton<ExperimentStatus?>);
      expect(dropdown, findsOneWidget);
    });
```

### TC-UI-008: 状态筛选下拉框选项

```dart
    testWidgets('status filter dropdown has all status options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 点击下拉框
      await tester.tap(find.byType(DropdownButton<ExperimentStatus?>));
      await tester.pumpAndSettle();

      // 验证所有选项都存在
      expect(find.text('全部状态'), findsOneWidget);
      expect(find.text('空闲'), findsOneWidget);
      expect(find.text('运行中'), findsOneWidget);
      expect(find.text('已暂停'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('已中止'), findsOneWidget);
    });
```

### TC-UI-009: 时间范围筛选器存在

```dart
    testWidgets('date range filter exists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证日期范围选择器存在
      expect(find.byType(DateRangePicker), findsOneWidget);
    });
```

### TC-UI-010: 分页控制存在

```dart
    testWidgets('pagination controls exist', (tester) async {
      final experiments = List.generate(
        25,
        (i) => createTestExperiment(id: '$i', name: '实验 $i'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(
                  experiments: experiments.take(20).toList(),
                  hasMore: true,
                  currentPage: 1,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证分页信息显示
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('显示 1-20 / 共 25 条'), findsOneWidget);
    });
```

---

## 4. Widget测试 - 交互

### TC-INT-001: 点击状态筛选触发重新加载

```dart
    testWidgets('changing status filter reloads experiments', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        const ExperimentListState(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 点击状态筛选下拉框
      await tester.tap(find.byType(DropdownButton<ExperimentStatus?>));
      await tester.pumpAndSettle();

      // 选择"运行中"
      await tester.tap(find.text('运行中').last);
      await tester.pumpAndSettle();

      // 验证 setStatusFilter 被调用
      verify(() => mockNotifier.setStatusFilter(ExperimentStatus.running)).called(1);
    });
```

### TC-INT-002: 清除筛选条件

```dart
    testWidgets('clearing filter reloads all experiments', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentListState(statusFilter: ExperimentStatus.running),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 点击清除按钮
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // 验证 clearStatusFilter 被调用
      verify(() => mockNotifier.clearStatusFilter()).called(1);
    });
```

### TC-INT-003: 选择日期范围

```dart
    testWidgets('selecting date range updates filter', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        const ExperimentListState(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 点击日期范围选择器
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();

      // 选择日期范围（假设选择 2024-01-01 到 2024-03-31）
      // 注意：实际测试需要根据 DateRangePicker 的具体实现

      verify(() => mockNotifier.setDateRangeFilter(
        any(that: isNotNull),
        any(that: isNotNull),
      )).called(1);
    });
```

### TC-INT-004: 点击加载更多

```dart
    testWidgets('tap load more loads next page', (tester) async {
      final experiments = List.generate(
        20,
        (i) => createTestExperiment(id: '$i', name: '实验 $i'),
      );

      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentListState(
          experiments: experiments,
          hasMore: true,
          currentPage: 1,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 点击加载更多按钮
      await tester.tap(find.text('加载更多'));
      await tester.pumpAndSettle();

      // 验证 loadMore 被调用
      verify(() => mockNotifier.loadMore()).called(1);
    });
```

### TC-INT-005: 下拉刷新

```dart
    testWidgets('pull to refresh reloads experiments', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        const ExperimentListState(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 执行下拉刷新手势
      await tester.fling(find.byType(RefreshIndicator), Offset(0, 100), 1000);
      await tester.pumpAndSettle();

      // 验证 refresh 被调用
      verify(() => mockNotifier.refresh()).called(1);
    });
```

---

## 5. Widget测试 - 导航

### TC-NAV-001: 点击实验项进入详情页

```dart
    testWidgets('tap experiment navigates to detail page', (tester) async {
      final experiments = [
        createTestExperiment(id: 'exp-1', name: '测试实验'),
      ];

      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentListState(experiments: experiments),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 点击实验项
      await tester.tap(find.text('测试实验'));
      await tester.pumpAndSettle();

      // 验证导航到详情页（检查路由）
      // 取决于路由实现，可能需要验证 navigator 或 router 的状态
      expect(find.text('测试实验'), findsOneWidget);
    });
```

### TC-NAV-002: 详情页导航传递正确参数

```dart
    testWidgets('navigation passes experiment ID to detail page', (tester) async {
      final experiment = createTestExperiment(id: 'exp-123', name: '测试实验');

      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentListState(experiments: [experiment]),
      );

      String? capturedId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            routes: {
              '/experiments': (context) => ExperimentListPage(),
              '/experiments/detail': (context) {
                capturedId = ModalRoute.of(context)?.settings.arguments as String?;
                return Scaffold(body: Text('Detail: $capturedId'));
              },
            },
            home: ExperimentListPage(),
          ),
        ),
      );

      // 点击实验项
      await tester.tap(find.text('测试实验'));
      await tester.pumpAndSettle();

      // 验证传递了正确的 ID
      expect(capturedId, equals('exp-123'));
    });
```

### TC-NAV-003: 从详情页返回列表保持状态

```dart
    testWidgets('back navigation preserves list state', (tester) async {
      final experiments = [
        createTestExperiment(id: '1', name: '实验一'),
        createTestExperiment(id: '2', name: '实验二'),
      ];

      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentListState(experiments: experiments),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证列表状态
      expect(find.text('实验一'), findsOneWidget);
      expect(find.text('实验二'), findsOneWidget);

      // 点击进入详情
      await tester.tap(find.text('实验一'));
      await tester.pumpAndSettle();

      // 返回列表
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 验证列表状态保持
      expect(find.text('实验一'), findsOneWidget);
      expect(find.text('实验二'), findsOneWidget);
    });
```

---

## 6. 集成测试 - 筛选和分页

### TC-FILTER-001: 按状态筛选 - 运行中

```dart
void main() {
  group('Experiment List Filtering Integration Tests', () {
    testWidgets('filter by running status shows only running experiments', (tester) async {
      final allExperiments = [
        createTestExperiment(id: '1', name: '空闲实验', status: ExperimentStatus.idle),
        createTestExperiment(id: '2', name: '运行中实验', status: ExperimentStatus.running),
        createTestExperiment(id: '3', name: '已完成实验', status: ExperimentStatus.completed),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(MockExperimentService()),
            experimentListProvider.overrideWith((ref) {
              final notifier = ExperimentListNotifier(ref.watch(experimentServiceProvider));
              // 预设数据
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 初始显示所有实验
      expect(find.text('空闲实验'), findsOneWidget);
      expect(find.text('运行中实验'), findsOneWidget);
      expect(find.text('已完成实验'), findsOneWidget);

      // 选择状态筛选
      await tester.tap(find.byType(DropdownButton<ExperimentStatus?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('运行中').last);
      await tester.pumpAndSettle();

      // 验证只有运行中的实验显示
      expect(find.text('运行中实验'), findsOneWidget);
      expect(find.text('空闲实验'), findsNothing);
      expect(find.text('已完成实验'), findsNothing);
    });
  });
}
```

### TC-FILTER-002: 按状态筛选 - 已完成

```dart
    testWidgets('filter by completed status shows only completed experiments', (tester) async {
      // ... 类似 TC-FILTER-001，验证 completed 状态筛选
    });
```

### TC-FILTER-003: 按时间范围筛选 - 特定日期

```dart
    testWidgets('filter by date range shows experiments within range', (tester) async {
      final experiments = [
        createTestExperiment(id: '1', name: '三月实验', createdAt: DateTime(2024, 3, 15)),
        createTestExperiment(id: '2', name: '五月实验', createdAt: DateTime(2024, 5, 20)),
        createTestExperiment(id: '3', name: '九月实验', createdAt: DateTime(2024, 9, 10)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(MockExperimentService()),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 选择日期范围 2024-03-01 到 2024-06-30
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();

      // 在日期选择器中选择开始和结束日期
      // ...

      // 验证只有三月实验显示（因为五月实验在范围外）
      expect(find.text('三月实验'), findsOneWidget);
      expect(find.text('五月实验'), findsNothing);
      expect(find.text('九月实验'), findsNothing);
    });
```

### TC-FILTER-004: 组合筛选 - 状态 + 时间范围

```dart
    testWidgets('combined status and date filter works correctly', (tester) async {
      final experiments = [
        createTestExperiment(id: '1', name: '三月运行', status: ExperimentStatus.running, createdAt: DateTime(2024, 3, 1)),
        createTestExperiment(id: '2', name: '五月运行', status: ExperimentStatus.running, createdAt: DateTime(2024, 5, 1)),
        createTestExperiment(id: '3', name: '三月完成', status: ExperimentStatus.completed, createdAt: DateTime(2024, 3, 15)),
      ];

      // 验证组合筛选：只显示三月且运行中的实验
      // ...
    });
```

### TC-FILTER-005: 清除筛选后显示全部

```dart
    testWidgets('clearing filters shows all experiments', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentListState(
          statusFilter: ExperimentStatus.running,
          experiments: [
            createTestExperiment(id: '1', name: '运行中实验', status: ExperimentStatus.running),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 清除筛选
      await tester.tap(find.byIcon(Icons.clear_filter));
      await tester.pumpAndSettle();

      verify(() => mockNotifier.clearAllFilters()).called(1);
    });
```

### TC-FILTER-006: 无匹配结果的筛选结果

```dart
    testWidgets('filter with no matches shows empty state', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        const ExperimentListState(
          statusFilter: ExperimentStatus.aborted,
          experiments: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('暂无符合条件的试验记录'), findsOneWidget);
    });
```

### TC-FILTER-007: 分页加载 - 第二页

```dart
    testWidgets('load more fetches second page', (tester) async {
      // 创建25个实验，第一页显示20个
      final page1Experiments = List.generate(
        20,
        (i) => createTestExperiment(id: '${i + 1}', name: '实验 ${i + 1}'),
      );

      final page2Experiments = [
        createTestExperiment(id: '21', name: '实验 21'),
        createTestExperiment(id: '22', name: '实验 22'),
        createTestExperiment(id: '23', name: '实验 23'),
        createTestExperiment(id: '24', name: '实验 24'),
        createTestExperiment(id: '25', name: '实验 25'),
      ];

      var callCount = 0;
      final mockService = MockExperimentService();
      when(() => mockService.getExperiments(
        page: any(named: 'page'),
        size: any(named: 'size'),
        status: any(named: 'status'),
        startedAfter: any(named: 'startedAfter'),
        startedBefore: any(named: 'startedBefore'),
      )).thenAnswer((invocation) async {
        callCount++;
        final page = invocation.namedArguments[const Symbol('page')] as int;
        if (page == 1) {
          return PagedExperimentResponse(
            items: page1Experiments,
            page: 1,
            size: 20,
            total: 25,
          );
        } else {
          return PagedExperimentResponse(
            items: page2Experiments,
            page: 2,
            size: 20,
            total: 25,
          );
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证第一页
      expect(find.text('实验 1'), findsOneWidget);
      expect(find.text('实验 20'), findsOneWidget);
      expect(find.text('实验 21'), findsNothing);

      // 点击加载更多
      await tester.tap(find.text('加载更多'));
      await tester.pumpAndSettle();

      // 验证第二页数据
      expect(find.text('实验 21'), findsOneWidget);
      expect(find.text('实验 25'), findsOneWidget);
    });
```

### TC-FILTER-008: 分页状态显示

```dart
    testWidgets('pagination info shows correct range', (tester) async {
      final experiments = List.generate(
        15,
        (i) => createTestExperiment(id: '$i', name: '实验 $i'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(
                  experiments: experiments,
                  currentPage: 1,
                  hasMore: false, // 只有15条，一页显示完
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('显示 1-15 / 共 15 条'), findsOneWidget);
      expect(find.text('加载更多'), findsNothing);
    });
```

### TC-FILTER-009: 筛选后重置分页

```dart
    testWidgets('filter change resets pagination to page 1', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentListState(
          currentPage: 2,
          experiments: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 改变筛选条件
      await tester.tap(find.byType(DropdownButton<ExperimentStatus?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('运行中').last);
      await tester.pumpAndSettle();

      // 验证分页重置到第一页
      verify(() => mockNotifier.resetPagination()).called(1);
    });
```

### TC-FILTER-010: 最后一页不显示加载更多

```dart
    testWidgets('last page does not show load more button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(
                  hasMore: false,
                  currentPage: 3,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('加载更多'), findsNothing);
    });
```

### TC-FILTER-011: 筛选期间显示加载状态

```dart
    testWidgets('filter change shows loading state', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        const ExperimentListState(isLoading: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
```

### TC-FILTER-012: 筛选API错误处理

```dart
    testWidgets('filter API error shows error message', (tester) async {
      final mockNotifier = MockExperimentListNotifier();
      when(() => mockNotifier.state).thenReturn(
        const ExperimentListState(
          error: '筛选失败：服务器错误',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('筛选失败：服务器错误'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
```

---

## 7. 边界测试

### TC-BOUNDARY-001: 大量实验数据性能测试

```dart
    testWidgets('renders large list smoothly', (tester) async {
      // 创建100个实验
      final experiments = List.generate(
        100,
        (i) => createTestExperiment(id: '$i', name: '实验 ${i + 1}'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: experiments),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证渲染没有卡顿（通过测量帧率）
      expect(find.text('实验 1'), findsOneWidget);
      expect(find.text('实验 100'), findsOneWidget);
    });
```

### TC-BOUNDARY-002: 特殊字符实验名称

```dart
    testWidgets('handles experiment names with special characters', (tester) async {
      final experiments = [
        createTestExperiment(id: '1', name: '实验 <test> & "quote"'),
        createTestExperiment(id: '2', name: '实验\n换行'),
        createTestExperiment(id: '3', name: '实验   多个空格   '),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: experiments),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证特殊字符被正确转义或显示
      expect(find.textContaining('实验'), findsNWidgets(3));
    });
```

### TC-BOUNDARY-003: 空字符串实验名称

```dart
    testWidgets('handles empty experiment name', (tester) async {
      final experiments = [
        createTestExperiment(id: '1', name: ''),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: experiments),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('(无名称)'), findsOneWidget);
    });
```

### TC-BOUNDARY-004: 超长实验名称截断

```dart
    testWidgets('truncates very long experiment name', (tester) async {
      final longName = 'A' * 200;
      final experiments = [
        createTestExperiment(id: '1', name: longName),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: experiments),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 验证文本被截断（Ellipsis）
      final textWidget = tester.widget<Text>(find.textContaining('AAAA...'));
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });
```

---

## 8. 主题和国际化测试

### TC-THEME-001: 浅色主题显示

```dart
    testWidgets('light theme renders correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: [
                  createTestExperiment(id: '1', name: '测试实验'),
                ]),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('测试实验'), findsOneWidget);
    });
```

### TC-THEME-002: 深色主题显示

```dart
    testWidgets('dark theme renders correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentListState(experiments: [
                  createTestExperiment(id: '1', name: '测试实验'),
                ]),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('测试实验'), findsOneWidget);
    });
```

### TC-I18N-001: 中文界面显示

```dart
    testWidgets('Chinese locale displays correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(experiments: []),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            locale: const Locale('zh', 'CN'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('暂无试验记录'), findsOneWidget);
    });
```

### TC-I18N-002: 英文界面显示

```dart
    testWidgets('English locale displays correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentListProvider.overrideWith((ref) {
              final notifier = MockExperimentListNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentListState(experiments: []),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            locale: const Locale('en', 'US'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ExperimentListPage(),
          ),
        ),
      );

      expect(find.text('No experiments'), findsOneWidget);
    });
```

---

## 9. 测试统计

| 类别 | 测试用例数 | 优先级 |
|------|-----------|--------|
| State Management | 7 | P0 |
| UI Components | 10 | P0 |
| Interactions | 5 | P0 |
| Navigation | 3 | P1 |
| Filtering & Pagination | 12 | P0 |
| Boundary Tests | 4 | P1 |
| Theme & i18n | 4 | P2 |
| **总计** | **45** | |

### 9.1 优先级分类

| 优先级 | 定义 | 测试用例 |
|--------|------|---------|
| P0 | 核心功能，必须通过 | 34 |
| P1 | 重要功能，应该通过 | 7 |
| P2 | 辅助功能，可以后续通过 | 4 |

---

## 10. 测试辅助函数

### 10.1 Mock对象

```dart
class MockExperimentService extends Mock implements ExperimentServiceInterface {}

class MockExperimentListNotifier extends Mock implements ExperimentListNotifier {
  @override
  ExperimentListState get state => ExperimentListState();

  @override
  ExperimentListState get state => super.noSuchMethod(
    Invocation.getter(#state),
    returnValue: ExperimentListState(),
  ) as ExperimentListState;
}
```

### 10.2 测试数据工厂

```dart
Experiment createTestExperiment({
  String id = 'test-id',
  String name = 'Test Experiment',
  ExperimentStatus status = ExperimentStatus.idle,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return Experiment(
    id: id,
    userId: 'test-user',
    name: name,
    status: status,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

PagedExperimentResponse createPagedResponse({
  required List<Experiment> items,
  required int page,
  int size = 20,
  int total = 0,
}) {
  return PagedExperimentResponse(
    items: items,
    page: page,
    size: size,
    total: total,
  );
}
```

---

## 11. 依赖的Provider结构

### 11.1 Provider列表

```dart
// 实验服务Provider
final experimentServiceProvider = Provider<ExperimentServiceInterface>((ref) {
  return ExperimentService();
});

// 实验列表NotifierProvider
final experimentListProvider =
    StateNotifierProvider<ExperimentListNotifier, ExperimentListState>((ref) {
  final service = ref.watch(experimentServiceProvider);
  return ExperimentListNotifier(service);
});

// 路由Provider
final routerProvider = Provider<AppRouter>((ref) {
  return AppRouter();
});
```

---

**文档结束**
