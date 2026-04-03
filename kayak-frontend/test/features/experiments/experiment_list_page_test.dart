/// 试验列表页面组件测试

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kayak_frontend/features/experiments/models/experiment.dart';
import 'package:kayak_frontend/features/experiments/services/experiment_service.dart';
import 'package:kayak_frontend/features/experiments/screens/experiment_list_page.dart';

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
  group('ExperimentListPage Widget Tests', () {
    late MockExperimentService mockService;

    setUp(() {
      mockService = MockExperimentService();
    });

    testWidgets('页面加载时显示标题', (tester) async {
      when(() => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          )).thenAnswer((_) async => createPagedResponse(
            items: [],
            page: 1,
            total: 0,
          ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      // 等待异步加载完成
      await tester.pumpAndSettle();

      expect(find.text('试验记录'), findsOneWidget);
    });

    testWidgets('空状态时显示暂无试验记录', (tester) async {
      when(() => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          )).thenAnswer((_) async => createPagedResponse(
            items: [],
            page: 1,
            total: 0,
          ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('暂无试验记录'), findsOneWidget);
    });

    testWidgets('页面正确响应数据加载完成', (tester) async {
      // 这个测试验证页面在数据加载完成后正确显示
      when(() => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          )).thenAnswer((_) async => createPagedResponse(
            items: [createTestExperiment(name: '测试试验1')],
            page: 1,
            total: 1,
          ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证数据加载完成后显示正确内容
      expect(find.text('测试试验1'), findsOneWidget);
    });

    testWidgets('显示试验列表数据', (tester) async {
      when(() => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          )).thenAnswer((_) async => createPagedResponse(
            items: [
              createTestExperiment(id: 'test-1', name: '测试试验1'),
              createTestExperiment(id: 'test-2', name: '测试试验2'),
            ],
            page: 1,
            total: 2,
          ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('测试试验1'), findsOneWidget);
      expect(find.text('测试试验2'), findsOneWidget);
    });

    testWidgets('显示分页信息', (tester) async {
      when(() => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          )).thenAnswer((_) async => createPagedResponse(
            items: [createTestExperiment(name: '测试试验1')],
            page: 1,
            total: 25,
          ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证分页信息格式 - 验证存在分页相关组件
      // "加载更多"按钮显示表示有更多数据
      expect(find.text('加载更多'), findsAtLeast(1));
    });

    testWidgets('筛选工具栏显示状态筛选', (tester) async {
      when(() => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          )).thenAnswer((_) async => createPagedResponse(
            items: [],
            page: 1,
            total: 0,
          ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证筛选工具栏存在
      expect(find.text('状态:'), findsOneWidget);
      expect(find.text('时间:'), findsOneWidget);
      expect(find.text('重置'), findsOneWidget);
    });

    testWidgets('错误状态显示错误消息', (tester) async {
      when(() => mockService.getExperiments(
            page: any(named: 'page'),
            size: any(named: 'size'),
            status: any(named: 'status'),
            startedAfter: any(named: 'startedAfter'),
            startedBefore: any(named: 'startedBefore'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: ExperimentListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsOneWidget);
    });
  });
}
