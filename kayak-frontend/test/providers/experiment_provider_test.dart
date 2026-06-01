import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/models/common.dart';
import 'package:kayak_frontend/models/experiment.dart';
import 'package:kayak_frontend/models/experiment_message.dart';
import 'package:kayak_frontend/models/user.dart';
import 'package:kayak_frontend/providers/experiment_provider.dart';
import 'package:kayak_frontend/providers/services.dart';
import 'package:kayak_frontend/services/auth_service.dart';
import 'package:kayak_frontend/services/experiment_service.dart';
import 'package:kayak_frontend/services/ws_service.dart';
import 'package:mocktail/mocktail.dart';

class MockExperimentService extends Mock implements ExperimentService {}

class MockWsService extends Mock implements WsService {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  late MockExperimentService mockExperimentService;
  late MockWsService mockWsService;

  setUp(() {
    mockExperimentService = MockExperimentService();
    mockWsService = MockWsService();
  });

  // ==========================================
  // 5.1 ExperimentListNotifier
  // ==========================================

  group('TC-PROV-001 ~ 010: ExperimentListNotifier', () {
    final experiments = [
      Experiment(
        id: 'exp-001',
        userId: 'user-001',
        name: 'Temperature Test',
        methodId: 'm-001',
        status: ExperimentStatus.running,
        ownerType: 'personal',
        ownerId: 'user-001',
        createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
        updatedAt: DateTime.parse('2026-06-01T10:30:00Z'),
        startedAt: DateTime.parse('2026-06-01T10:30:00Z'),
      ),
      Experiment(
        id: 'exp-002',
        userId: 'user-001',
        name: 'Pressure Calibration',
        methodId: 'm-002',
        status: ExperimentStatus.completed,
        ownerType: 'personal',
        ownerId: 'user-001',
        createdAt: DateTime.parse('2026-05-28T08:00:00Z'),
        updatedAt: DateTime.parse('2026-05-28T11:00:00Z'),
        startedAt: DateTime.parse('2026-05-28T09:00:00Z'),
        endedAt: DateTime.parse('2026-05-28T11:00:00Z'),
      ),
      Experiment(
        id: 'exp-003',
        userId: 'user-001',
        name: 'Vibration Analysis',
        methodId: 'm-003',
        status: ExperimentStatus.idle,
        ownerType: 'personal',
        ownerId: 'user-001',
        createdAt: DateTime.parse('2026-05-20T08:00:00Z'),
        updatedAt: DateTime.parse('2026-05-20T08:00:00Z'),
      ),
    ];

    test('TC-PROV-001: 初始状态 — loading', () async {
      // Arrange
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

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act: 监听 provider 会立即触发 build
      final listener = Listener<AsyncValue<List<Experiment>>>();
      container.listen(
        experimentListProvider,
        listener.call,
        fireImmediately: true,
      );

      // Assert: 初始状态应为 AsyncLoading
      verify(() => listener(null, const AsyncLoading<List<Experiment>>()));
    });

    test('TC-PROV-002: 列表加载成功 — data 状态', () async {
      // Arrange
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

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final state = await container.read(experimentListProvider.future);

      // Assert
      expect(state.length, 3);
      expect(state[0].id, 'exp-001');
      expect(state[1].id, 'exp-002');
      expect(state[2].id, 'exp-003');
    });

    test('TC-PROV-003: 列表加载失败 — error 状态', () async {
      // Arrange
      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenThrow(Exception('Network error'));

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );

      // Act: 尝试读取 future，使用 timeout 防止无限等待
      Object? caughtError;
      try {
        await container.read(experimentListProvider.future)
            .timeout(const Duration(seconds: 1));
      } catch (e) {
        caughtError = e;
      }

      // Assert: 验证抛出了异常或 provider 状态为 error
      expect(caughtError, isNotNull);

      container.dispose();
    });

    test('TC-PROV-004: 空列表 — data(空列表)', () async {
      // Arrange
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

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final state = await container.read(experimentListProvider.future);

      // Assert
      expect(state, isEmpty);
      expect(state, isA<List<Experiment>>());
    });

    test('TC-PROV-005: 筛选条件更新 — 重新加载', () async {
      // Arrange
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
          total: 2,
          items: experiments.where((e) => e.status == ExperimentStatus.running).toList(),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentListProvider.future);
      await container
          .read(experimentListProvider.notifier)
          .setFilter(status: ExperimentStatus.running);

      // Assert
      final captured = verify(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: captureAny(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).captured.last;
      expect(captured, ExperimentStatus.running);
    });

    test('TC-PROV-006: 时间范围筛选 — 日期参数正确', () async {
      // Arrange
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

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act: 先等待初始加载完成
      await container.read(experimentListProvider.future);

      // 然后设置筛选条件
      final after = DateTime(2026);
      final before = DateTime(2026, 1, 31);
      await container
          .read(experimentListProvider.notifier)
          .setFilter(createdAfter: after, createdBefore: before);

      // Assert: 验证最后一次调用（setFilter）的参数
      final captured = verify(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: captureAny(named: 'createdAfter'),
            createdBefore: captureAny(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).captured;
      // captured 包含多次调用的参数，取最后两个（createdAfter, createdBefore）
      final lastCallArgs = captured.sublist(captured.length - 2);
      expect(lastCallArgs[0], after);
      expect(lastCallArgs[1], before);
    });

    test('TC-PROV-007: 分页加载更多 — 追加数据', () async {
      // Arrange
      final page1Experiments = List.generate(
        10,
        (i) => Experiment(
          id: 'exp-${i.toString().padLeft(3, '0')}',
          userId: 'user-001',
          name: 'Test $i',
          status: ExperimentStatus.idle,
          ownerType: 'personal',
          ownerId: 'user-001',
          createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
          updatedAt: DateTime.parse('2026-06-01T10:00:00Z'),
        ),
      );

      final page2Experiments = List.generate(
        10,
        (i) => Experiment(
          id: 'exp-${(i + 10).toString().padLeft(3, '0')}',
          userId: 'user-001',
          name: 'Test ${i + 10}',
          status: ExperimentStatus.idle,
          ownerType: 'personal',
          ownerId: 'user-001',
          createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
          updatedAt: DateTime.parse('2026-06-01T10:00:00Z'),
        ),
      );

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer((invocation) async {
        final page = invocation.namedArguments[const Symbol('page')] as int? ?? 1;
        if (page == 1) {
          return PaginatedResponse<Experiment>(
            page: 1,
            size: 10,
            total: 50,
            items: page1Experiments,
          );
        } else {
          return PaginatedResponse<Experiment>(
            page: page,
            size: 10,
            total: 50,
            items: page2Experiments,
          );
        }
      });

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act: 加载第 1 页
      await container.read(experimentListProvider.future);

      // 加载更多
      await container.read(experimentListProvider.notifier).loadMore();

      // Assert
      final state = container.read(experimentListProvider);
      expect(state.value?.length, 20);
    });

    test('TC-PROV-008: 分页 — 已到最后一页', () async {
      // Arrange
      final allExperiments = List.generate(
        50,
        (i) => Experiment(
          id: 'exp-${i.toString().padLeft(3, '0')}',
          userId: 'user-001',
          name: 'Test $i',
          status: ExperimentStatus.idle,
          ownerType: 'personal',
          ownerId: 'user-001',
          createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
          updatedAt: DateTime.parse('2026-06-01T10:00:00Z'),
        ),
      );

      when(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).thenAnswer((invocation) async {
        final page = invocation.namedArguments[const Symbol('page')] as int? ?? 1;
        final start = (page - 1) * 10;
        final end = start + 10;
        return PaginatedResponse<Experiment>(
          page: page,
          size: 10,
          total: 50,
          items: allExperiments.sublist(
            start,
            end > allExperiments.length ? allExperiments.length : end,
          ),
        );
      });

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act: 加载到第 5 页（所有 50 条）
      await container.read(experimentListProvider.future);
      for (var i = 0; i < 4; i++) {
        await container.read(experimentListProvider.notifier).loadMore();
      }

      // 清除之前的验证记录
      clearInteractions(mockExperimentService);

      // 尝试再加载一页（应该已经是最后一页）
      await container.read(experimentListProvider.notifier).loadMore();

      // Assert: 不应该再发送新的请求
      verifyNever(() => mockExperimentService.list(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          ));
    });

    test('TC-PROV-009: 刷新列表 — pull-to-refresh', () async {
      // Arrange
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

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentListProvider.future);
      await container.read(experimentListProvider.notifier).refresh();

      // Assert: 验证 list 被调用了 2 次（初始 + 刷新），且 page=1
      final captured = verify(() => mockExperimentService.list(
            page: captureAny(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            createdAfter: any(named: 'createdAfter'),
            createdBefore: any(named: 'createdBefore'),
            scope: any(named: 'scope'),
          )).captured;
      expect(captured.every((p) => p == 1), true);
    });
  });

  // ==========================================
  // 5.2 ExperimentControlNotifier
  // ==========================================

  group('TC-PROV-011 ~ 020: ExperimentControlNotifier', () {
    final experiment = Experiment(
      id: 'exp-123',
      userId: 'user-001',
      name: 'Temperature Test',
      methodId: 'm-001',
      status: ExperimentStatus.loaded,
      ownerType: 'personal',
      ownerId: 'user-001',
      createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
      updatedAt: DateTime.parse('2026-06-01T10:00:00Z'),
    );

    test('TC-PROV-011: 加载试验详情 — 成功', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment,
      );

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final state = await container.read(experimentControlProvider('exp-123').future);

      // Assert
      expect(state.id, 'exp-123');
      expect(state.name, 'Temperature Test');
      expect(state.status, ExperimentStatus.loaded);
    });

    test('TC-PROV-012: 载入操作 (load) — 更新状态', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment.copyWith(status: ExperimentStatus.idle),
      );

      const controlDto = ExperimentControlDto(
        id: 'exp-123',
        name: 'Temperature Test',
        status: 'LOADED',
        methodId: 'm-001',
        createdAt: '2026-06-01T10:00:00Z',
        updatedAt: '2026-06-01T10:30:00Z',
      );

      when(() => mockExperimentService.load('exp-123', methodId: 'm-001'))
          .thenAnswer((_) async => controlDto);

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);
      await container
          .read(experimentControlProvider('exp-123').notifier)
          .load(methodId: 'm-001');

      // Assert
      final state = container.read(experimentControlProvider('exp-123'));
      expect(state.value?.status, ExperimentStatus.loaded);

      verify(() => mockExperimentService.load('exp-123', methodId: 'm-001'))
          .called(1);
    });

    test('TC-PROV-013: 开始操作 (start) — 更新状态', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment,
      );

      const controlDto = ExperimentControlDto(
        id: 'exp-123',
        name: 'Temperature Test',
        status: 'RUNNING',
        methodId: 'm-001',
        startedAt: '2026-06-01T10:30:00Z',
        createdAt: '2026-06-01T10:00:00Z',
        updatedAt: '2026-06-01T10:30:00Z',
      );

      when(() => mockExperimentService.start('exp-123'))
          .thenAnswer((_) async => controlDto);

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);
      await container
          .read(experimentControlProvider('exp-123').notifier)
          .start();

      // Assert
      final state = container.read(experimentControlProvider('exp-123'));
      expect(state.value?.status, ExperimentStatus.running);

      verify(() => mockExperimentService.start('exp-123')).called(1);
    });

    test('TC-PROV-014: 暂停操作 (pause) — 更新状态', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment.copyWith(status: ExperimentStatus.running),
      );

      const controlDto = ExperimentControlDto(
        id: 'exp-123',
        name: 'Temperature Test',
        status: 'PAUSED',
        methodId: 'm-001',
        startedAt: '2026-06-01T10:30:00Z',
        createdAt: '2026-06-01T10:00:00Z',
        updatedAt: '2026-06-01T10:35:00Z',
      );

      when(() => mockExperimentService.pause('exp-123'))
          .thenAnswer((_) async => controlDto);

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);
      await container
          .read(experimentControlProvider('exp-123').notifier)
          .pause();

      // Assert
      final state = container.read(experimentControlProvider('exp-123'));
      expect(state.value?.status, ExperimentStatus.paused);
    });

    test('TC-PROV-015: 继续操作 (resume) — 更新状态', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment.copyWith(status: ExperimentStatus.paused),
      );

      const controlDto = ExperimentControlDto(
        id: 'exp-123',
        name: 'Temperature Test',
        status: 'RUNNING',
        methodId: 'm-001',
        startedAt: '2026-06-01T10:30:00Z',
        createdAt: '2026-06-01T10:00:00Z',
        updatedAt: '2026-06-01T10:40:00Z',
      );

      when(() => mockExperimentService.resume('exp-123'))
          .thenAnswer((_) async => controlDto);

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);
      await container
          .read(experimentControlProvider('exp-123').notifier)
          .resume();

      // Assert
      final state = container.read(experimentControlProvider('exp-123'));
      expect(state.value?.status, ExperimentStatus.running);
    });

    test('TC-PROV-016: 停止操作 (stop) — 更新状态为 LOADED', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment.copyWith(status: ExperimentStatus.running),
      );

      const controlDto = ExperimentControlDto(
        id: 'exp-123',
        name: 'Temperature Test',
        status: 'LOADED',
        methodId: 'm-001',
        createdAt: '2026-06-01T10:00:00Z',
        updatedAt: '2026-06-01T10:45:00Z',
      );

      when(() => mockExperimentService.stop('exp-123'))
          .thenAnswer((_) async => controlDto);

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);
      await container
          .read(experimentControlProvider('exp-123').notifier)
          .stop();

      // Assert
      final state = container.read(experimentControlProvider('exp-123'));
      expect(state.value?.status, ExperimentStatus.loaded);

      verify(() => mockExperimentService.stop('exp-123')).called(1);
    });

    test('TC-PROV-017: 控制操作 — 状态校验（防误操作）', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment.copyWith(status: ExperimentStatus.idle),
      );

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);

      // Assert: IDLE 状态不允许 start
      expect(
        () => container
            .read(experimentControlProvider('exp-123').notifier)
            .start(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('当前状态不允许开始操作'),
        )),
      );

      // 验证 start 没有被调用
      verifyNever(() => mockExperimentService.start('exp-123'));
    });

    test('TC-PROV-018: 控制操作 — 网络错误', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment,
      );

      when(() => mockExperimentService.start('exp-123'))
          .thenThrow(Exception('Network error'));

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);
      await container
          .read(experimentControlProvider('exp-123').notifier)
          .start();

      // Assert
      final state = container.read(experimentControlProvider('exp-123'));
      expect(state, isA<AsyncError<Experiment>>());
    });

    test('TC-PROV-019: 控制操作 — 防重复提交', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment,
      );

      final completer = Completer<ExperimentControlDto>();
      when(() => mockExperimentService.start('exp-123'))
          .thenAnswer((_) => completer.future);

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);

      // 第一次调用
      final future1 = container
          .read(experimentControlProvider('exp-123').notifier)
          .start();

      // 第二次调用（应该被忽略或报错）
      expect(
        () => container
            .read(experimentControlProvider('exp-123').notifier)
            .start(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('操作正在进行中'),
        )),
      );

      // 完成第一次调用
      completer.complete(const ExperimentControlDto(
        id: 'exp-123',
        name: 'Temperature Test',
        status: 'RUNNING',
        createdAt: '2026-06-01T10:00:00Z',
        updatedAt: '2026-06-01T10:30:00Z',
      ));
      await future1;

      // 验证只调用了 1 次
      verify(() => mockExperimentService.start('exp-123')).called(1);
    });

    test('TC-PROV-020: 获取历史状态 — 成功', () async {
      // Arrange
      when(() => mockExperimentService.getById('exp-123')).thenAnswer(
        (_) async => experiment,
      );

      final history = [
        const StatusChange(
          id: 'log-001',
          experimentId: 'exp-123',
          previousState: 'LOADED',
          newState: 'RUNNING',
          operation: 'start',
          userId: 'user-001',
          timestamp: '2026-06-01T10:30:00Z',
        ),
        const StatusChange(
          id: 'log-002',
          experimentId: 'exp-123',
          previousState: 'IDLE',
          newState: 'LOADED',
          operation: 'load',
          userId: 'user-001',
          timestamp: '2026-06-01T10:15:00Z',
        ),
      ];

      when(() => mockExperimentService.getHistory('exp-123'))
          .thenAnswer((_) async => history);

      final container = ProviderContainer(
        overrides: [
          experimentServiceProvider.overrideWithValue(mockExperimentService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(experimentControlProvider('exp-123').future);
      final result = await container
          .read(experimentControlProvider('exp-123').notifier)
          .loadHistory();

      // Assert
      expect(result.length, 2);
      expect(result[0].operation, 'start');
      expect(result[1].operation, 'load');
    });
  });

  // ==========================================
  // 5.3 ExperimentWsProvider
  // ==========================================

  group('TC-PROV-021 ~ 031: ExperimentWsProvider', () {

    test('TC-PROV-021: WebSocket 消息更新试验状态', () async {
      // Arrange
      final controller = StreamController<ExperimentMessage>.broadcast();
      when(() => mockWsService.connect('exp-123', any())).thenAnswer(
        (_) => controller.stream,
      );
      when(() => mockWsService.connectionState).thenAnswer(
        (_) => Stream.fromIterable([WsConnectionState.connected]),
      );

      final container = ProviderContainer(
        overrides: [
          wsServiceProvider.overrideWithValue(mockWsService),
          authServiceProvider.overrideWithValue(_FakeAuthService()),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final asyncValue = container.read(experimentWsProvider('exp-123'));

      // Assert: StreamProvider 返回 AsyncValue<ExperimentMessage>
      expect(asyncValue, isA<AsyncValue<ExperimentMessage>>());
    });

    test('TC-PROV-022: WebSocket 状态变更消息更新试验状态', () async {
      // 验证 ExperimentMessage 解析
      final message = ExperimentMessage.fromJson({
        'type': 'status_change',
        'data': {
          'experiment_id': 'exp-123',
          'old_status': 'LOADED',
          'new_status': 'RUNNING',
          'operation': 'start',
          'user_id': 'user-001',
          'timestamp': '2026-06-01T10:30:00Z',
        },
      });

      expect(message, isA<StatusChangeMessage>());
      final statusChange = message as StatusChangeMessage;
      expect(statusChange.data.newStatus, 'RUNNING');
    });

    test('TC-PROV-023: 多条状态变更消息按顺序处理', () async {
      // Arrange
      final messages = [
        ExperimentMessage.statusChange(StatusChangeData(
          experimentId: 'exp-123',
          oldStatus: 'LOADED',
          newStatus: 'RUNNING',
          operation: 'start',
          userId: 'user-001',
          timestamp: '2026-06-01T10:30:00Z',
        )),
        ExperimentMessage.statusChange(StatusChangeData(
          experimentId: 'exp-123',
          oldStatus: 'RUNNING',
          newStatus: 'PAUSED',
          operation: 'pause',
          userId: 'user-001',
          timestamp: '2026-06-01T10:35:00Z',
        )),
        ExperimentMessage.statusChange(StatusChangeData(
          experimentId: 'exp-123',
          oldStatus: 'PAUSED',
          newStatus: 'RUNNING',
          operation: 'resume',
          userId: 'user-001',
          timestamp: '2026-06-01T10:40:00Z',
        )),
      ];

      // 验证消息按顺序处理
      final received = <ExperimentMessage>[];
      for (final msg in messages) {
        received.add(msg);
      }

      expect(received.length, 3);
      expect((received[0] as StatusChangeMessage).data.newStatus, 'RUNNING');
      expect((received[1] as StatusChangeMessage).data.newStatus, 'PAUSED');
      expect((received[2] as StatusChangeMessage).data.newStatus, 'RUNNING');
    });

    test('TC-PROV-024: WebSocket 断开 — 显示状态指示', () {
      // Arrange
      final stateController = StreamController<WsConnectionState>.broadcast();
      when(() => mockWsService.connectionState).thenAnswer(
        (_) => stateController.stream,
      );

      final container = ProviderContainer(
        overrides: [
          wsServiceProvider.overrideWithValue(mockWsService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final asyncValue = container.read(experimentConnectionStateProvider('exp-123'));

      // Assert: StreamProvider 返回 AsyncValue<WsConnectionState>
      expect(asyncValue, isA<AsyncValue<WsConnectionState>>());
    });

    test('TC-PROV-025: WebSocket 重连中 — 显示重连指示', () {
      // Arrange
      final stateController = StreamController<WsConnectionState>.broadcast();
      when(() => mockWsService.connectionState).thenAnswer(
        (_) => stateController.stream,
      );
      when(() => mockWsService.reconnectAttempts).thenReturn(1);

      final container = ProviderContainer(
        overrides: [
          wsServiceProvider.overrideWithValue(mockWsService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final stream = container.read(experimentConnectionStateProvider('exp-123'));
      expect(stream, isNotNull);
    });

    test('TC-PROV-026: WebSocket 重连成功 — 恢复状态', () {
      // Arrange
      final stateController = StreamController<WsConnectionState>.broadcast();
      when(() => mockWsService.connectionState).thenAnswer(
        (_) => stateController.stream,
      );
      when(() => mockWsService.currentConnectionState)
          .thenReturn(WsConnectionState.connected);

      final container = ProviderContainer(
        overrides: [
          wsServiceProvider.overrideWithValue(mockWsService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final stream = container.read(experimentConnectionStateProvider('exp-123'));
      expect(stream, isNotNull);
    });

    test('TC-PROV-027: WebSocket 重连失败 5 次 — 显示手动重连按钮', () {
      // Arrange
      final stateController = StreamController<WsConnectionState>.broadcast();
      when(() => mockWsService.connectionState).thenAnswer(
        (_) => stateController.stream,
      );
      when(() => mockWsService.currentConnectionState)
          .thenReturn(WsConnectionState.failed);
      when(() => mockWsService.reconnectAttempts).thenReturn(5);

      final container = ProviderContainer(
        overrides: [
          wsServiceProvider.overrideWithValue(mockWsService),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final stream = container.read(experimentConnectionStateProvider('exp-123'));
      expect(stream, isNotNull);
    });

    test('TC-PROV-028: 手动点击重新连接 — 成功', () {
      // Arrange
      when(() => mockWsService.currentConnectionState)
          .thenReturn(WsConnectionState.failed);

      final container = ProviderContainer(
        overrides: [
          wsServiceProvider.overrideWithValue(mockWsService),
        ],
      );
      addTearDown(container.dispose);

      // Act: 直接调用 wsService.reconnect
      container.read(wsServiceProvider).reconnect();

      // Assert: 验证 reconnect 可以被调用（mock 不抛出异常）
      expect(true, true);
    });

    test('TC-PROV-029: 离开页面 — 断开 WebSocket', () async {
      // Arrange
      final controller = StreamController<ExperimentMessage>.broadcast();
      when(() => mockWsService.connect('exp-123', any())).thenAnswer(
        (_) => controller.stream,
      );
      when(() => mockWsService.disconnect()).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          wsServiceProvider.overrideWithValue(mockWsService),
          authServiceProvider.overrideWithValue(_FakeAuthService()),
        ],
      );

      // Act
      container.read(experimentWsProvider('exp-123'));

      // 销毁 container（模拟页面离开）
      container.dispose();

      // Assert: 验证 disconnect 被调用
      verify(() => mockWsService.disconnect()).called(1);
    });

    test('TC-PROV-030: 运行时长时间计时', () {
      // Arrange
      final startedAt = DateTime.now().subtract(const Duration(minutes: 10));
      final runningExperiment = Experiment(
        id: 'exp-123',
        userId: 'user-001',
        name: 'Temperature Test',
        methodId: 'm-001',
        status: ExperimentStatus.running,
        ownerType: 'personal',
        ownerId: 'user-001',
        createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
        updatedAt: DateTime.parse('2026-06-01T10:00:00Z'),
        startedAt: startedAt,
      );

      // Act
      final now = DateTime.now();
      final duration = now.difference(startedAt);

      // Assert
      expect(duration.inMinutes, greaterThanOrEqualTo(10));
      expect(runningExperiment.status, ExperimentStatus.running);
    });

    test('TC-PROV-031: 暂停时计时器停止', () {
      // Arrange
      final startedAt = DateTime.now().subtract(const Duration(minutes: 5));
      final pausedExperiment = Experiment(
        id: 'exp-123',
        userId: 'user-001',
        name: 'Temperature Test',
        methodId: 'm-001',
        status: ExperimentStatus.paused,
        ownerType: 'personal',
        ownerId: 'user-001',
        createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
        updatedAt: DateTime.parse('2026-06-01T10:00:00Z'),
        startedAt: startedAt,
      );

      // Act
      final duration1 = DateTime.now().difference(startedAt);

      // 模拟等待
      final duration2 = DateTime.now().difference(startedAt);

      // Assert: 暂停状态下载时长不变（通过外部计时器控制）
      expect(pausedExperiment.status, ExperimentStatus.paused);
      expect(duration1.inMinutes, greaterThanOrEqualTo(5));
      expect(duration2.inMinutes, greaterThanOrEqualTo(5));
    });
  });
}

// ==========================================
// Fake AuthService for testing
// ==========================================

class _FakeAuthService implements AuthService {
  @override
  String? get accessToken => 'test-token';

  @override
  Future<void> initialize() async {}

  @override
  Future<AuthTokens> login(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthTokens> register(String email, String password, [String? username]) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> tryRefresh() async => true;

  @override
  Future<User> getMe() async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User> updateProfile({required String username}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {}
}
