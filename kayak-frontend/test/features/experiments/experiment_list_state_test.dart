/// 试验列表状态测试
///
/// 测试 ExperimentListState 类的行为
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/experiments/models/experiment.dart';
import 'package:kayak_frontend/features/experiments/models/experiment_list_state.dart';

void main() {
  group('ExperimentListState', () {
    test('初始状态具有正确的默认值', () {
      const state = ExperimentListState();

      expect(state.experiments, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.error, isNull);
      expect(state.currentPage, equals(1));
      expect(state.pageSize, equals(20));
      expect(state.total, equals(0));
      expect(state.hasMore, isTrue);
      expect(state.statusFilter, isNull);
      expect(state.startDateFilter, isNull);
      expect(state.endDateFilter, isNull);
    });

    test('copyWith创建具有更新值的新实例', () {
      const state = ExperimentListState();
      final newState = state.copyWith(isLoading: true);

      expect(newState.isLoading, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('copyWith更新一个字段时保留其他字段', () {
      final experiments = [
        Experiment(
          id: 'test-1',
          userId: 'user-1',
          name: 'Test Experiment',
          status: ExperimentStatus.idle,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];
      final state = ExperimentListState(experiments: experiments);
      final newState = state.copyWith(isLoading: true);

      expect(newState.experiments, equals(experiments));
      expect(newState.isLoading, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('copyWith可以清除statusFilter', () {
      const state = ExperimentListState(
        statusFilter: ExperimentStatus.running,
      );
      final newState = state.copyWith(clearStatusFilter: true);

      expect(newState.statusFilter, isNull);
      expect(state.statusFilter, equals(ExperimentStatus.running));
    });

    test('copyWith可以清除日期筛选器', () {
      final state = ExperimentListState(
        startDateFilter: DateTime(2024),
        endDateFilter: DateTime(2024, 12, 31),
      );
      final newState = state.copyWith(
        clearStartDate: true,
        clearEndDate: true,
      );

      expect(newState.startDateFilter, isNull);
      expect(newState.endDateFilter, isNull);
    });

    test('copyWith可以清除错误', () {
      const state = ExperimentListState(error: 'Some error');
      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
      expect(state.error, equals('Some error'));
    });

    test('copyWith可以更新分页信息', () {
      const state = ExperimentListState(total: 100);
      final newState = state.copyWith(
        currentPage: 2,
        total: 50,
        hasMore: false,
      );

      expect(newState.currentPage, equals(2));
      expect(newState.total, equals(50));
      expect(newState.hasMore, isFalse);
    });

    test('copyWith可以更新实验列表', () {
      final oldExperiments = [
        Experiment(
          id: 'test-1',
          userId: 'user-1',
          name: 'Old Experiment',
          status: ExperimentStatus.idle,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];
      final newExperiments = [
        Experiment(
          id: 'test-2',
          userId: 'user-1',
          name: 'New Experiment',
          status: ExperimentStatus.running,
          createdAt: DateTime(2024, 2),
          updatedAt: DateTime(2024, 2),
        ),
      ];

      final state = ExperimentListState(experiments: oldExperiments);
      final newState = state.copyWith(experiments: newExperiments);

      expect(newState.experiments, equals(newExperiments));
      expect(newState.experiments.length, equals(1));
      expect(newState.experiments.first.name, equals('New Experiment'));
    });

    test('分页信息默认值正确', () {
      const state = ExperimentListState();

      expect(state.currentPage, equals(1));
      expect(state.pageSize, equals(20));
      expect(state.total, equals(0));
      expect(state.hasMore, isTrue);
    });

    test('筛选状态默认值正确', () {
      const state = ExperimentListState();

      expect(state.statusFilter, isNull);
      expect(state.startDateFilter, isNull);
      expect(state.endDateFilter, isNull);
    });

    test('loading状态默认值正确', () {
      const state = ExperimentListState();

      expect(state.isLoading, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.error, isNull);
    });
  });
}
