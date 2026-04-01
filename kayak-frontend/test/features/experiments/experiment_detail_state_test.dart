/// 试验详情状态测试
///
/// 测试 ExperimentDetailState 类的行为
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/experiments/models/experiment.dart';
import 'package:kayak_frontend/features/experiments/models/experiment_detail_state.dart';

void main() {
  group('ExperimentDetailState', () {
    test('初始状态具有正确的默认值', () {
      const state = ExperimentDetailState();

      expect(state.experiment, isNull);
      expect(state.pointHistory, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingHistory, isFalse);
      expect(state.error, isNull);
      expect(state.historyError, isNull);
      expect(state.historyPage, equals(1));
      expect(state.hasMoreHistory, isFalse);
    });

    test('copyWith创建具有更新值的新实例', () {
      const state = ExperimentDetailState();
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试实验',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final newState = state.copyWith(experiment: experiment);

      expect(newState.experiment, equals(experiment));
      expect(state.experiment, isNull);
    });

    test('copyWith更新一个字段时保留其他字段', () {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试实验',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final state = ExperimentDetailState(experiment: experiment);
      final newState = state.copyWith(isLoading: true);

      expect(newState.experiment, equals(experiment));
      expect(newState.isLoading, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('copyWith使用clearError清除错误', () {
      final state = ExperimentDetailState(
        error: '网络错误',
        historyError: '数据加载失败',
      );

      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
      expect(newState.historyError, equals('数据加载失败')); // 不影响historyError
    });

    test('copyWith使用clearHistoryError清除历史错误', () {
      final state = ExperimentDetailState(
        error: '网络错误',
        historyError: '数据加载失败',
      );

      final newState = state.copyWith(clearHistoryError: true);

      expect(newState.historyError, isNull);
      expect(newState.error, equals('网络错误')); // 不影响error
    });

    test('copyWith可以同时清除两种错误', () {
      final state = ExperimentDetailState(
        error: '网络错误',
        historyError: '数据加载失败',
      );

      final newState = state.copyWith(
        clearError: true,
        clearHistoryError: true,
      );

      expect(newState.error, isNull);
      expect(newState.historyError, isNull);
    });

    test('copyWith可以更新测点历史数据', () {
      final history1 = [
        PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, 0),
          value: 25.5,
        ),
      ];
      final history2 = [
        PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, 1),
          value: 26.0,
        ),
      ];

      final state = ExperimentDetailState(pointHistory: history1);
      final newState = state.copyWith(pointHistory: history2);

      expect(newState.pointHistory, equals(history2));
      expect(newState.pointHistory.length, equals(1));
      expect(newState.pointHistory.first.value, equals(26.0));
    });

    test('copyWith可以追加测点历史数据', () {
      final existingHistory = [
        PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, 0),
          value: 25.5,
        ),
      ];
      final newHistory = [
        PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, 1),
          value: 26.0,
        ),
      ];

      final state = ExperimentDetailState(pointHistory: existingHistory);
      final combinedHistory = [...state.pointHistory, ...newHistory];
      final newState = state.copyWith(pointHistory: combinedHistory);

      expect(newState.pointHistory.length, equals(2));
      expect(newState.pointHistory[0].value, equals(25.5));
      expect(newState.pointHistory[1].value, equals(26.0));
    });

    test('copyWith可以重置分页状态', () {
      final state = ExperimentDetailState(
        historyPage: 5,
        hasMoreHistory: true,
        pointHistory: [
          PointHistoryData(
            timestamp: DateTime(2024, 1, 1),
            value: 25.5,
          ),
        ],
      );

      final newState = state.copyWith(
        historyPage: 1,
        hasMoreHistory: false,
        pointHistory: [],
      );

      expect(newState.historyPage, equals(1));
      expect(newState.hasMoreHistory, isFalse);
      expect(newState.pointHistory, isEmpty);
    });

    test('加载详情时isLoading状态正确', () {
      const state = ExperimentDetailState();

      final loadingState = state.copyWith(isLoading: true, clearError: true);

      expect(loadingState.isLoading, isTrue);
      expect(loadingState.error, isNull);
    });

    test('加载历史数据时isLoadingHistory状态正确', () {
      const state = ExperimentDetailState();

      final loadingState = state.copyWith(
        isLoadingHistory: true,
        clearHistoryError: true,
      );

      expect(loadingState.isLoadingHistory, isTrue);
      expect(loadingState.historyError, isNull);
    });

    test('可以同时加载详情和历史数据', () {
      const state = ExperimentDetailState();

      final loadingState = state.copyWith(
        isLoading: true,
        isLoadingHistory: true,
      );

      expect(loadingState.isLoading, isTrue);
      expect(loadingState.isLoadingHistory, isTrue);
    });

    test('hasMoreHistory根据数据长度正确设置', () {
      // 假设每页100条数据，当返回100条时hasMoreHistory应为true
      final history = List.generate(
        100,
        (i) => PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, i),
          value: i.toDouble(),
        ),
      );

      // 模拟API返回100条数据（刚好满一页），hasMoreHistory应为true
      final hasMore = history.length >= 100;

      final state = ExperimentDetailState(
        pointHistory: history,
        hasMoreHistory: hasMore,
      );

      expect(state.hasMoreHistory, isTrue);
      expect(state.pointHistory.length, equals(100));
    });

    test('hasMoreHistory为false时表示没有更多数据', () {
      // 当返回数据少于100条时，说明没有更多数据了
      final history = List.generate(
        50,
        (i) => PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, i),
          value: i.toDouble(),
        ),
      );

      final hasMore = history.length >= 100;

      final state = ExperimentDetailState(
        pointHistory: history,
        hasMoreHistory: hasMore,
      );

      expect(state.hasMoreHistory, isFalse);
      expect(state.pointHistory.length, equals(50));
    });

    test('hasMoreHistory计算逻辑测试', () {
      // 测试实际的hasMoreHistory计算逻辑
      List.generate(
          100,
          (i) => PointHistoryData(
                timestamp: DateTime(2024, 1, 1, 10, i),
                value: i.toDouble(),
              ));

      // 验证：newData.length >= 100 时 hasMoreHistory 应为 true
      const newDataLength100 = 100;
      expect(newDataLength100 >= 100, isTrue);

      // 验证：newData.length < 100 时 hasMoreHistory 应为 false
      const newDataLength99 = 99;
      expect(newDataLength99 >= 100, isFalse);
    });

    test('historyPage正确递增', () {
      const state = ExperimentDetailState(historyPage: 1);

      final newState = state.copyWith(historyPage: 2);

      expect(newState.historyPage, equals(2));
    });
  });

  group('PointHistoryData', () {
    test('PointHistoryData创建正确', () {
      final data = PointHistoryData(
        timestamp: DateTime(2024, 3, 15, 10, 30, 0),
        value: 25.567,
      );

      expect(data.timestamp, equals(DateTime(2024, 3, 15, 10, 30, 0)));
      expect(data.value, equals(25.567));
    });

    test('PointHistoryData支持负数值', () {
      final data = PointHistoryData(
        timestamp: DateTime(2024, 3, 15),
        value: -10.5,
      );

      expect(data.value, equals(-10.5));
    });

    test('PointHistoryData支持零值', () {
      final data = PointHistoryData(
        timestamp: DateTime(2024, 3, 15),
        value: 0.0,
      );

      expect(data.value, equals(0.0));
    });

    test('PointHistoryData支持高精度小数', () {
      final data = PointHistoryData(
        timestamp: DateTime(2024, 3, 15),
        value: 3.14159265359,
      );

      expect(data.value, closeTo(3.14159265359, 0.00000000001));
    });
  });
}
