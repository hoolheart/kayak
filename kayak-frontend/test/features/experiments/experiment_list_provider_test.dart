/// 试验列表Provider测试
///
/// 测试 ExperimentListNotifier 类的行为
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/experiments/models/experiment.dart';
import 'package:kayak_frontend/features/experiments/providers/experiment_list_provider.dart';
import 'package:kayak_frontend/features/experiments/services/experiment_service.dart';
import 'package:mocktail/mocktail.dart';

/// Mock试验服务
class MockExperimentService extends Mock
    implements ExperimentServiceInterface {}

/// 创建测试用实验数据
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

/// 创建分页响应
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
    hasNext: page * size < total,
    hasPrev: page > 1,
  );
}

void main() {
  group('ExperimentListNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('状态筛选', () {
      test('statusFilter可以被设置', () {
        final notifier = container.read(experimentListProvider.notifier);

        notifier.setStatusFilter(ExperimentStatus.running);
        final state = container.read(experimentListProvider);

        expect(state.statusFilter, equals(ExperimentStatus.running));
      });

      test('statusFilter可以被清除', () {
        final notifier = container.read(experimentListProvider.notifier);

        // 先设置
        notifier.setStatusFilter(ExperimentStatus.running);
        expect(
          container.read(experimentListProvider).statusFilter,
          equals(ExperimentStatus.running),
        );

        // 再清除
        notifier.clearStatusFilter();
        final state = container.read(experimentListProvider);
        expect(state.statusFilter, isNull);
      });

      test('设置null状态的statusFilter会清除筛选', () {
        final notifier = container.read(experimentListProvider.notifier);

        notifier.setStatusFilter(ExperimentStatus.completed);
        notifier.setStatusFilter(null);
        final state = container.read(experimentListProvider);

        expect(state.statusFilter, isNull);
      });
    });

    group('日期范围筛选', () {
      test('dateRangeFilter可以正确设置', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(experimentListProvider.notifier);
        final startDate = DateTime(2024);
        final endDate = DateTime(2024, 12, 31);

        notifier.setDateRangeFilter(startDate, endDate);
        final state = container.read(experimentListProvider);

        expect(state.startDateFilter, equals(startDate));
        expect(state.endDateFilter, equals(endDate));
      });

      test('setDateRange可以正确设置', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(experimentListProvider.notifier);
        final startDate = DateTime(2024, 3);
        final endDate = DateTime(2024, 6, 30);

        notifier.setDateRange(startDate, endDate);
        final state = container.read(experimentListProvider);

        expect(state.startDateFilter, equals(startDate));
        expect(state.endDateFilter, equals(endDate));
      });

      test('clearDateRangeFilter重置日期筛选', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(experimentListProvider.notifier);
        notifier.setDateRangeFilter(DateTime(2024), DateTime(2024, 12, 31));
        notifier.clearDateRangeFilter();

        final state = container.read(experimentListProvider);
        expect(state.startDateFilter, isNull);
        expect(state.endDateFilter, isNull);
      });

      test('设置null日期会清除筛选', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(experimentListProvider.notifier);
        notifier.setDateRange(null, null);

        final state = container.read(experimentListProvider);
        expect(state.startDateFilter, isNull);
        expect(state.endDateFilter, isNull);
      });
    });

    group('加载状态转换', () {
      test('loadExperiments正确转换状态', () async {
        final mockService = MockExperimentService();
        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer(
          (_) async => createPagedResponse(
            items: [],
            page: 1,
          ),
        );

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

      test('loadExperiments重置时从第一页开始', () async {
        final mockService = MockExperimentService();
        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer(
          (_) async => createPagedResponse(
            items: [createTestExperiment(id: '1', name: 'Exp 1')],
            page: 1,
            total: 1,
          ),
        );

        final notifier = ExperimentListNotifier(mockService);

        // 先加载一次
        await notifier.loadExperiments();
        expect(notifier.state.currentPage, equals(1));

        // 再重置加载
        await notifier.loadExperiments(reset: true);
        expect(notifier.state.currentPage, equals(1));
      });
    });

    group('分页状态更新', () {
      test('loadMore更新分页状态正确', () async {
        final mockService = MockExperimentService();
        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer(
          (_) async => createPagedResponse(
            items: [createTestExperiment(name: 'Exp 1')],
            page: 1,
            total: 25,
          ),
        );

        final notifier = ExperimentListNotifier(mockService);
        await notifier.loadExperiments();

        expect(notifier.state.currentPage, equals(1));
        expect(notifier.state.hasMore, isTrue);

        // 设置第二页的mock
        when(
          () => mockService.getExperiments(
            page: 2,
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer(
          (_) async => createPagedResponse(
            items: [createTestExperiment(name: 'Exp 2')],
            page: 2,
            total: 25,
          ),
        );

        await notifier.loadMore();

        expect(notifier.state.currentPage, equals(2));
        expect(notifier.state.experiments.length, equals(2));
      });

      test('hasMore根据响应正确设置', () async {
        final mockService = MockExperimentService();
        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer(
          (_) async => createPagedResponse(
            items: [],
            page: 1,
          ),
        );

        final notifier = ExperimentListNotifier(mockService);
        await notifier.loadExperiments();

        // 总数为0，没有更多数据
        expect(notifier.state.hasMore, isFalse);
      });
    });

    group('错误状态处理', () {
      test('loadExperiments正确处理错误', () async {
        final mockService = MockExperimentService();
        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenThrow(Exception('Network error'));

        final notifier = ExperimentListNotifier(mockService);
        await notifier.loadExperiments();

        expect(notifier.state.error, isNotNull);
        expect(notifier.state.error, contains('Network error'));
        expect(notifier.state.isLoading, isFalse);
      });

      test('refresh正确处理错误', () async {
        final mockService = MockExperimentService();
        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenThrow(Exception('Refresh failed'));

        final notifier = ExperimentListNotifier(mockService);
        await notifier.refresh();

        expect(notifier.state.error, isNotNull);
        expect(notifier.state.isRefreshing, isFalse);
      });
    });

    group('刷新功能', () {
      test('refresh重新加载第一页', () async {
        final mockService = MockExperimentService();
        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer((invocation) async {
          final page = invocation.namedArguments[const Symbol('page')] as int;
          return createPagedResponse(
            items: [createTestExperiment(name: 'Page $page')],
            page: page,
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

      test('refresh时isRefreshing状态正确', () async {
        final mockService = MockExperimentService();
        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer(
          (_) async => createPagedResponse(
            items: [],
            page: 1,
          ),
        );

        final notifier = ExperimentListNotifier(mockService);

        expect(notifier.state.isRefreshing, isFalse);

        final future = notifier.refresh();
        expect(notifier.state.isRefreshing, isTrue);

        await future;
        expect(notifier.state.isRefreshing, isFalse);
      });
    });

    group('清除筛选', () {
      test('clearFilters清除所有筛选条件', () {
        final notifier = container.read(experimentListProvider.notifier);

        notifier.setStatusFilter(ExperimentStatus.running);
        notifier.setDateRange(DateTime(2024), DateTime(2024, 12, 31));

        notifier.clearFilters();

        final state = container.read(experimentListProvider);
        expect(state.statusFilter, isNull);
        expect(state.startDateFilter, isNull);
        expect(state.endDateFilter, isNull);
      });

      test('clearAllFilters是clearFilters的别名', () {
        final notifier = container.read(experimentListProvider.notifier);

        notifier.setStatusFilter(ExperimentStatus.completed);
        notifier.clearAllFilters();

        final state = container.read(experimentListProvider);
        expect(state.statusFilter, isNull);
      });
    });

    group('重置分页', () {
      test('resetPagination将分页重置到第一页', () {
        final notifier = container.read(experimentListProvider.notifier);

        // 模拟分页状态
        notifier.state = notifier.state.copyWith(currentPage: 5);
        expect(container.read(experimentListProvider).currentPage, equals(5));

        notifier.resetPagination();

        expect(container.read(experimentListProvider).currentPage, equals(1));
      });
    });

    group('防止重复加载', () {
      test('loadExperiments在loading时不重复加载', () async {
        final mockService = MockExperimentService();
        var callCount = 0;

        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          return createPagedResponse(
            items: [],
            page: 1,
          );
        });

        final notifier = ExperimentListNotifier(mockService);

        // 同时调用两次
        final future1 = notifier.loadExperiments();
        final future2 = notifier.loadExperiments();

        await future1;
        await future2;

        // 由于有保护机制，第二次调用会直接返回，只会有一次实际调用
        expect(callCount, equals(1));
      });

      test('refresh在refreshing时不重复刷新', () async {
        final mockService = MockExperimentService();
        var callCount = 0;

        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          return createPagedResponse(
            items: [],
            page: 1,
          );
        });

        final notifier = ExperimentListNotifier(mockService);

        // 同时调用两次
        final future1 = notifier.refresh();
        final future2 = notifier.refresh();

        await future1;
        await future2;

        // 由于有保护机制，第二次调用会直接返回
        expect(callCount, equals(1));
      });
    });

    group('loadMore保护', () {
      test('loadMore在没有更多数据时不加载', () async {
        final mockService = MockExperimentService();
        var callCount = 0;

        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return createPagedResponse(
            items: [],
            page: 1,
          );
        });

        final notifier = ExperimentListNotifier(mockService);
        await notifier.loadExperiments();

        // hasMore为false时不应该调用loadMore
        expect(notifier.state.hasMore, isFalse);
        await notifier.loadMore();

        // 只会有一次调用（loadExperiments）
        expect(callCount, equals(1));
      });

      test('loadMore在loading时不加载', () async {
        final mockService = MockExperimentService();
        var callCount = 0;

        when(
          () => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          return createPagedResponse(
            items: [],
            page: 1,
          );
        });

        final notifier = ExperimentListNotifier(mockService);

        // 开始加载但不等待
        notifier.loadExperiments();

        // 在loading时调用loadMore
        await notifier.loadMore();

        // 只会有一次调用
        expect(callCount, equals(1));
      });
    });
  });
}
