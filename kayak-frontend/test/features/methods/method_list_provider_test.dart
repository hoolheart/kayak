/// 方法列表Provider测试
///
/// 测试 MethodListNotifier 类的行为
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kayak_frontend/features/methods/models/method.dart';
import 'package:kayak_frontend/features/methods/providers/method_list_provider.dart';
import 'package:kayak_frontend/features/methods/services/method_service.dart';

/// Mock方法服务
class MockMethodService extends Mock implements MethodServiceInterface {}

/// 创建测试用方法数据
Method createTestMethod({
  String id = 'test-id',
  String name = 'Test Method',
  String? description,
  Map<String, dynamic>? processDefinition,
  Map<String, dynamic>? parameterSchema,
}) {
  final now = DateTime.now();
  return Method(
    id: id,
    name: name,
    description: description,
    processDefinition: processDefinition ??
        {
          'nodes': [
            {'id': 'start', 'type': 'Start'},
            {'id': 'end', 'type': 'End'}
          ]
        },
    parameterSchema: parameterSchema ?? {},
    version: 1,
    createdBy: 'test-user',
    createdAt: now,
    updatedAt: now,
  );
}

/// 创建分页响应
MethodListResponse createPagedResponse({
  required List<Method> items,
  required int page,
  required int total,
  int size = 10,
}) {
  return MethodListResponse(
    items: items,
    page: page,
    size: size,
    total: total,
  );
}

void main() {
  group('MethodListNotifier', () {
    late MockMethodService mockService;

    setUp(() {
      mockService = MockMethodService();
    });

    group('加载方法列表', () {
      test('loadMethods加载第一页方法', () async {
        final methods = [
          createTestMethod(name: 'Method 1'),
          createTestMethod(name: 'Method 2'),
        ];
        when(() => mockService.getMethods())
            .thenAnswer((_) async => createPagedResponse(
                  items: methods,
                  page: 1,
                  total: 2,
                ));

        final notifier = MethodListNotifier(mockService);
        await notifier.loadMethods();

        expect(notifier.state.methods.length, equals(2));
        expect(notifier.state.methods[0].name, equals('Method 1'));
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.currentPage, equals(1));
        expect(notifier.state.totalItems, equals(2));
      });

      test('loadMethods显示加载状态', () async {
        when(() => mockService.getMethods()).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return createPagedResponse(items: [], page: 1, total: 0);
          },
        );

        final notifier = MethodListNotifier(mockService);
        final future = notifier.loadMethods();

        expect(notifier.state.isLoading, isTrue);

        await future;

        expect(notifier.state.isLoading, isFalse);
      });

      test('loadMethods处理错误', () async {
        when(() => mockService.getMethods())
            .thenThrow(Exception('Network error'));

        final notifier = MethodListNotifier(mockService);
        await notifier.loadMethods();

        expect(notifier.state.error, isNotNull);
        expect(notifier.state.methods, isEmpty);
      });
    });

    group('分页加载', () {
      test('loadMore加载下一页', () async {
        when(() => mockService.getMethods())
            .thenAnswer((_) async => createPagedResponse(
                  items: List.generate(
                      10, (i) => createTestMethod(name: 'Page 1 Item $i')),
                  page: 1,
                  total: 25,
                ));
        when(() => mockService.getMethods(page: 2))
            .thenAnswer((_) async => createPagedResponse(
                  items: [createTestMethod(name: 'Page 2 Item')],
                  page: 2,
                  total: 25,
                ));

        final notifier = MethodListNotifier(mockService);
        await notifier.loadMethods();
        await notifier.loadMore();

        expect(notifier.state.methods.length,
            equals(11)); // 10 from page 1 + 1 from page 2
        expect(notifier.state.currentPage, equals(2));
        // hasMore is false because page 2 returned only 1 item which is < page size (10)
        expect(notifier.state.hasMore, isFalse);
      });

      test('loadMore不会在加载中时重复请求', () async {
        when(() => mockService.getMethods())
            .thenAnswer((_) async => createPagedResponse(
                  items: List.generate(
                      10, (i) => createTestMethod(name: 'Item $i')),
                  page: 1,
                  total: 25,
                ));

        final notifier = MethodListNotifier(mockService);
        await notifier.loadMethods();

        // hasMore should be true since 10 items >= page size
        expect(notifier.state.hasMore, isTrue);

        // Start loadMore twice rapidly
        final future1 = notifier.loadMore();
        final future2 = notifier.loadMore();

        await future1;
        await future2;

        // Should only have called getMethods twice (page 1 and page 2)
        verify(() => mockService.getMethods()).called(1);
      });
    });

    group('删除方法', () {
      test('deleteMethod删除指定方法', () async {
        when(() => mockService.deleteMethod('test-id'))
            .thenAnswer((_) async {});
        when(() => mockService.getMethods())
            .thenAnswer((_) async => createPagedResponse(
                  items: [],
                  page: 1,
                  total: 0,
                ));

        final notifier = MethodListNotifier(mockService);
        await notifier.deleteMethod('test-id');

        verify(() => mockService.deleteMethod('test-id')).called(1);
      });

      test('deleteMethod处理错误', () async {
        when(() => mockService.deleteMethod('test-id'))
            .thenThrow(Exception('Delete failed'));

        final notifier = MethodListNotifier(mockService);
        await notifier.deleteMethod('test-id');

        expect(notifier.state.error, isNotNull);
      });
    });

    group('错误处理', () {
      test('clearError清除错误消息', () async {
        when(() => mockService.getMethods())
            .thenThrow(Exception('Network error'));

        final notifier = MethodListNotifier(mockService);
        await notifier.loadMethods();

        expect(notifier.state.error, isNotNull);

        notifier.clearError();
        expect(notifier.state.error, isNull);
      });
    });
  });

  group('MethodListState', () {
    test('copyWith创建新实例', () {
      final state = MethodListState(
        methods: [createTestMethod()],
        isLoading: true,
        totalItems: 10,
        hasMore: true,
      );

      final newState = state.copyWith(isLoading: false);

      expect(newState.isLoading, isFalse);
      expect(newState.methods, equals(state.methods));
      expect(newState.currentPage, equals(state.currentPage));
    });

    test('默认状态为空列表', () {
      const state = MethodListState();
      expect(state.methods, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.currentPage, equals(1));
      expect(state.totalItems, equals(0));
      expect(state.hasMore, isFalse);
    });
  });
}
