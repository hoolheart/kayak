/// 试验详情Provider测试
///
/// 测试 ExperimentDetailNotifier 类的行为
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kayak_frontend/features/experiments/models/experiment.dart';
import 'package:kayak_frontend/features/experiments/models/experiment_detail_state.dart';
import 'package:kayak_frontend/features/experiments/providers/experiment_detail_provider.dart';
import 'package:kayak_frontend/features/experiments/services/experiment_service.dart';

/// Mock试验服务
class MockExperimentService extends Mock
    implements ExperimentServiceInterface {}

/// 创建测试用实验数据
Experiment createTestExperiment({
  String id = 'test-id',
  String name = 'Test Experiment',
  ExperimentStatus status = ExperimentStatus.idle,
  String? description,
  DateTime? startedAt,
  DateTime? endedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return Experiment(
    id: id,
    userId: 'test-user',
    name: name,
    description: description,
    status: status,
    startedAt: startedAt,
    endedAt: endedAt,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

/// 创建测试用PointHistoryItem
PointHistoryItem createTestPointHistoryItem({
  DateTime? timestamp,
  double value = 25.5,
}) {
  // 使用 millisecondsSinceEpoch * 1000000 表示纳秒
  return PointHistoryItem(
    timestamp: (timestamp ?? DateTime(2024, 3, 15, 10)).millisecondsSinceEpoch *
        1000000,
    value: value,
  );
}

/// 创建测试用PointHistoryResponse
PointHistoryResponse createTestPointHistoryResponse({
  String experimentId = 'test-exp',
  String channel = 'test-channel',
  required List<PointHistoryItem> data,
  int? totalPoints,
}) {
  return PointHistoryResponse(
    experimentId: experimentId,
    channel: channel,
    data: data,
    totalPoints: totalPoints ?? data.length,
  );
}

void main() {
  group('ExperimentDetailNotifier', () {
    late MockExperimentService mockService;

    setUp(() {
      mockService = MockExperimentService();
    });

    group('加载试验详情', () {
      test('loadExperiment加载试验详情成功', () async {
        final experiment = Experiment(
          id: 'exp-1',
          userId: 'user-1',
          name: '测试实验',
          description: '这是一个测试实验',
          status: ExperimentStatus.running,
          startedAt: DateTime(2024, 3, 15, 9),
          createdAt: DateTime(2024, 3, 15, 8),
          updatedAt: DateTime(2024, 3, 15, 9),
        );

        when(() => mockService.getExperiment('exp-1'))
            .thenAnswer((_) async => experiment);

        final notifier = ExperimentDetailNotifier(mockService);

        // 初始状态
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.experiment, isNull);

        // 开始加载
        final future = notifier.loadExperiment('exp-1');
        expect(notifier.state.isLoading, isTrue);

        // 加载完成
        await future;
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.experiment, equals(experiment));
        expect(notifier.state.error, isNull);
      });

      test('loadExperiment处理加载错误', () async {
        when(() => mockService.getExperiment('exp-1'))
            .thenThrow(Exception('试验不存在'));

        final notifier = ExperimentDetailNotifier(mockService);
        await notifier.loadExperiment('exp-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.experiment, isNull);
        expect(notifier.state.error, contains('试验不存在'));
      });

      test('loadExperiment防止重复加载', () async {
        when(() => mockService.getExperiment('exp-1')).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Experiment(
            id: 'exp-1',
            userId: 'user-1',
            name: '测试实验',
            status: ExperimentStatus.idle,
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          );
        });

        final notifier = ExperimentDetailNotifier(mockService);

        // 第一次调用
        final future1 = notifier.loadExperiment('exp-1');
        // 第二次调用（应该直接返回，不执行加载）
        final future2 = notifier.loadExperiment('exp-1');

        await future1;
        await future2;

        // 只调用一次API
        verify(() => mockService.getExperiment('exp-1')).called(1);
      });
    });

    group('加载测点历史数据', () {
      test('loadPointHistory加载测点历史数据成功', () async {
        final response = PointHistoryResponse(
          experimentId: 'exp-1',
          channel: 'temp_sensor_1',
          data: [
            PointHistoryItem(
              // 使用 millisecondsSinceEpoch * 1000000 表示纳秒
              timestamp:
                  DateTime(2024, 3, 15, 10).millisecondsSinceEpoch * 1000000,
              value: 25.5,
            ),
            PointHistoryItem(
              timestamp:
                  DateTime(2024, 3, 15, 10, 1).millisecondsSinceEpoch * 1000000,
              value: 26.0,
            ),
          ],
          totalPoints: 2,
        );

        when(() => mockService.getPointHistory(
              'exp-1',
              'temp_sensor_1',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => response);

        final notifier = ExperimentDetailNotifier(mockService);

        await notifier.loadPointHistory('exp-1', 'temp_sensor_1');

        expect(notifier.state.isLoadingHistory, isFalse);
        expect(notifier.state.pointHistory.length, equals(2));
        expect(notifier.state.pointHistory[0].value, equals(25.5));
        expect(notifier.state.pointHistory[1].value, equals(26.0));
        expect(notifier.state.hasMoreHistory, isFalse); // 只有2条数据
        expect(notifier.state.historyError, isNull);
      });

      test('loadPointHistory处理时间戳转换', () async {
        // API返回的是纳秒时间戳
        final timestampNs =
            DateTime(2024, 3, 15, 10, 30).millisecondsSinceEpoch * 1000000;

        final response = PointHistoryResponse(
          experimentId: 'exp-1',
          channel: 'sensor_1',
          data: [
            PointHistoryItem(
              timestamp: timestampNs,
              value: 100.0,
            ),
          ],
          totalPoints: 1,
        );

        when(() => mockService.getPointHistory(any(), any(),
            limit: any(named: 'limit'))).thenAnswer((_) async => response);

        final notifier = ExperimentDetailNotifier(mockService);
        await notifier.loadPointHistory('exp-1', 'sensor_1');

        // 验证时间戳正确转换为DateTime
        expect(notifier.state.pointHistory[0].timestamp,
            equals(DateTime(2024, 3, 15, 10, 30)));
      });

      test('loadPointHistory处理加载错误', () async {
        when(() => mockService.getPointHistory(any(), any(),
            limit: any(named: 'limit'))).thenThrow(Exception('测点不存在'));

        final notifier = ExperimentDetailNotifier(mockService);
        await notifier.loadPointHistory('exp-1', 'invalid_channel');

        expect(notifier.state.isLoadingHistory, isFalse);
        expect(notifier.state.pointHistory, isEmpty);
        expect(notifier.state.historyError, contains('测点不存在'));
      });

      test('loadPointHistory支持分页加载', () async {
        // 第一页数据
        final page1Response = PointHistoryResponse(
          experimentId: 'exp-1',
          channel: 'sensor_1',
          data: List.generate(
            100,
            (i) => PointHistoryItem(
              // 使用正确的纳秒时间戳
              timestamp:
                  DateTime(2024, 3, 15, 10, i).millisecondsSinceEpoch * 1000000,
              value: i.toDouble(),
            ),
          ),
          totalPoints: 150,
        );

        when(() => mockService.getPointHistory(
              'exp-1',
              'sensor_1',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => page1Response);

        final notifier = ExperimentDetailNotifier(mockService);
        await notifier.loadPointHistory('exp-1', 'sensor_1');

        expect(notifier.state.pointHistory.length, equals(100));
        expect(notifier.state.hasMoreHistory, isTrue);
        expect(notifier.state.historyPage, equals(2));
      });

      test('loadPointHistory重置时清除已有数据', () async {
        // 先加载第一页
        final page1Response = PointHistoryResponse(
          experimentId: 'exp-1',
          channel: 'sensor_1',
          data: List.generate(
            100,
            (i) => PointHistoryItem(
              timestamp:
                  DateTime(2024, 3, 15, 10, i).millisecondsSinceEpoch * 1000000,
              value: i.toDouble(),
            ),
          ),
          totalPoints: 150,
        );

        when(() => mockService.getPointHistory(
              'exp-1',
              'sensor_1',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => page1Response);

        final notifier = ExperimentDetailNotifier(mockService);
        await notifier.loadPointHistory('exp-1', 'sensor_1');
        expect(notifier.state.pointHistory.length, equals(100));

        // 重置加载
        await notifier.loadPointHistory('exp-1', 'sensor_1', reset: true);

        // 页码重置为1，数据保持（重新加载）
        expect(notifier.state.historyPage, equals(2)); // 加载完成后递增
      });
    });

    group('CSV导出功能', () {
      test('exportToCsv生成正确的CSV格式', () async {
        final experiment = Experiment(
          id: 'exp-1',
          userId: 'user-1',
          name: '温度测试',
          status: ExperimentStatus.completed,
          createdAt: DateTime(2024, 3, 15),
          updatedAt: DateTime(2024, 3, 15),
        );

        final history = [
          PointHistoryData(
            timestamp: DateTime(2024, 3, 15, 10),
            value: 25.5,
          ),
          PointHistoryData(
            timestamp: DateTime(2024, 3, 15, 10, 1),
            value: 26.0,
          ),
        ];

        final notifier = ExperimentDetailNotifier(mockService);
        // 设置状态
        notifier.state = ExperimentDetailState(
          experiment: experiment,
          pointHistory: history,
        );

        final csv = await notifier.exportToCsv();

        expect(csv, contains('Timestamp,Value'));
        expect(csv, contains('2024-03-15T10:00:00.000,25.5'));
        expect(csv, contains('2024-03-15T10:01:00.000,26.0'));
      });

      test('exportToCsv处理空数据', () async {
        final experiment = Experiment(
          id: 'exp-1',
          userId: 'user-1',
          name: '空测试',
          status: ExperimentStatus.completed,
          createdAt: DateTime(2024, 3, 15),
          updatedAt: DateTime(2024, 3, 15),
        );

        final notifier = ExperimentDetailNotifier(mockService);
        notifier.state = ExperimentDetailState(
          experiment: experiment,
          pointHistory: [],
        );

        final csv = await notifier.exportToCsv();

        expect(csv, equals('Timestamp,Value\n'));
      });

      test('exportToCsv没有试验时返回空字符串', () async {
        final notifier = ExperimentDetailNotifier(mockService);

        final csv = await notifier.exportToCsv();

        expect(csv, equals(''));
      });

      test('exportToCsv处理特殊数值', () async {
        final experiment = Experiment(
          id: 'exp-1',
          userId: 'user-1',
          name: '特殊值测试',
          status: ExperimentStatus.completed,
          createdAt: DateTime(2024, 3, 15),
          updatedAt: DateTime(2024, 3, 15),
        );

        final history = [
          PointHistoryData(
            timestamp: DateTime(2024, 3, 15, 10),
            value: 0.0,
          ),
          PointHistoryData(
            timestamp: DateTime(2024, 3, 15, 10, 1),
            value: -10.5,
          ),
          PointHistoryData(
            timestamp: DateTime(2024, 3, 15, 10, 2),
            value: 3.14159,
          ),
        ];

        final notifier = ExperimentDetailNotifier(mockService);
        notifier.state = ExperimentDetailState(
          experiment: experiment,
          pointHistory: history,
        );

        final csv = await notifier.exportToCsv();

        expect(csv, contains('0.0'));
        expect(csv, contains('-10.5'));
        expect(csv, contains('3.14159'));
      });

      test('exportToCsv处理大数据集', () async {
        final notifier = ExperimentDetailNotifier(mockService);

        // 生成1000条数据
        final history = List.generate(
          1000,
          (i) => PointHistoryData(
            timestamp: DateTime(2024, 3, 15, 10, i ~/ 60, i % 60),
            value: i.toDouble(),
          ),
        );

        notifier.state = ExperimentDetailState(
          experiment: Experiment(
            id: 'exp-1',
            userId: 'user-1',
            name: '大数据测试',
            status: ExperimentStatus.completed,
            createdAt: DateTime(2024, 3, 15),
            updatedAt: DateTime(2024, 3, 15),
          ),
          pointHistory: history,
        );

        final stopwatch = Stopwatch()..start();
        final csv = await notifier.exportToCsv();
        stopwatch.stop();

        // 验证性能（1000条数据应在100ms内完成）
        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        // 验证行数（1行表头 + 1000行数据 + 1行空行）
        expect(csv.split('\n').length, equals(1002));
      });
    });

    group('状态转换和并发控制', () {
      test('加载详情时不影响历史数据加载状态', () async {
        when(() => mockService.getExperiment('exp-1'))
            .thenAnswer((_) async => Experiment(
                  id: 'exp-1',
                  userId: 'user-1',
                  name: '测试',
                  status: ExperimentStatus.idle,
                  createdAt: DateTime(2024),
                  updatedAt: DateTime(2024),
                ));

        final notifier = ExperimentDetailNotifier(mockService);

        // 模拟正在加载历史数据
        notifier.state = notifier.state.copyWith(isLoadingHistory: true);

        await notifier.loadExperiment('exp-1');

        // isLoadingHistory应该保持不变
        expect(notifier.state.isLoadingHistory, isTrue);
        expect(notifier.state.isLoading, isFalse);
      });

      test('加载历史数据时不影响详情加载状态', () async {
        const response = PointHistoryResponse(
          experimentId: 'exp-1',
          channel: 'sensor_1',
          data: [],
          totalPoints: 0,
        );

        when(() => mockService.getPointHistory(any(), any(),
            limit: any(named: 'limit'))).thenAnswer((_) async => response);

        final notifier = ExperimentDetailNotifier(mockService);

        // 模拟正在加载详情
        notifier.state = notifier.state.copyWith(isLoading: true);

        await notifier.loadPointHistory('exp-1', 'sensor_1');

        // isLoading应该保持不变
        expect(notifier.state.isLoading, isTrue);
        expect(notifier.state.isLoadingHistory, isFalse);
      });

      test('防止重复加载历史数据', () async {
        when(() => mockService.getPointHistory(any(), any(),
            limit: any(named: 'limit'))).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const PointHistoryResponse(
            experimentId: 'exp-1',
            channel: 'sensor_1',
            data: [],
            totalPoints: 0,
          );
        });

        final notifier = ExperimentDetailNotifier(mockService);

        // 同时调用两次
        final future1 = notifier.loadPointHistory('exp-1', 'sensor_1');
        final future2 = notifier.loadPointHistory('exp-1', 'sensor_1');

        await future1;
        await future2;

        // 只调用一次API
        verify(() => mockService.getPointHistory(any(), any(),
            limit: any(named: 'limit'))).called(1);
      });
    });
  });
}
