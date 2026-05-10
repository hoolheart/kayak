/// 图表数据 Provider 单元测试
///
/// 测试 ChartDataNotifier 的状态管理和交互行为。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/analysis/models/chart_models.dart';
import 'package:kayak_frontend/features/analysis/providers/chart_data_provider.dart';
import 'package:kayak_frontend/features/analysis/services/mock_analysis_service.dart';
import 'package:mocktail/mocktail.dart';

/// Mock 分析服务
class MockAnalysisService extends Mock implements AnalysisService {}

/// Fake DataQueryRequest for mocktail fallback
class DataQueryRequestFake extends Fake implements DataQueryRequest {}

/// 创建测试用图表数据响应
ChartDataResponse createTestResponse({
  List<ChartPointSeries> points = const [],
  String experimentId = 'exp-001',
  String deviceId = 'dev-001',
  int totalSamples = 0,
  int returnedSamples = 0,
}) {
  return ChartDataResponse(
    experimentId: experimentId,
    deviceId: deviceId,
    points: points,
    totalSamples: totalSamples,
    returnedSamples: returnedSamples,
  );
}

/// 创建测试用数据序列
ChartPointSeries createTestSeries({
  String pointId = 'pt-001',
  String pointName = 'Temperature',
  String unit = '°C',
  List<int> timestamps = const [1000, 2000, 3000],
  List<double> values = const [25.0, 30.0, 35.0],
}) {
  return ChartPointSeries(
    pointId: pointId,
    pointName: pointName,
    unit: unit,
    dataType: 'float32',
    timestamps: timestamps,
    values: values,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const DataQueryRequest(
        experimentId: '',
        deviceId: '',
        pointIds: [],
      ),
    );
  });

  group('ChartDataNotifier', () {
    late MockAnalysisService mockService;
    late ChartDataNotifier notifier;

    setUp(() {
      mockService = MockAnalysisService();
      notifier = ChartDataNotifier(mockService);
    });

    tearDown(() {
      notifier.dispose();
    });

    group('初始状态', () {
      test('初始状态为 empty', () {
        expect(notifier.state.state, equals(ChartState.empty));
        expect(notifier.state.data, isNull);
        expect(notifier.state.visibleSeries, isEmpty);
        expect(notifier.state.errorMessage, isNull);
        expect(notifier.state.hoveredSeriesIndex, isNull);
      });
    });

    group('toggleSeriesVisibility', () {
      test('切换不可见序列变为可见', () {
        notifier.state = ChartViewState(
          state: ChartState.loaded,
          data: createTestResponse(
            points: [
              createTestSeries(pointId: 'pt-001'),
              createTestSeries(pointId: 'pt-002'),
            ],
          ),
          visibleSeries: const {'pt-001'},
        );

        notifier.toggleSeriesVisibility('pt-002');

        expect(notifier.state.visibleSeries, contains('pt-002'));
        expect(notifier.state.visibleSeries, contains('pt-001'));
      });

      test('切换可见序列变为不可见', () {
        notifier.state = ChartViewState(
          state: ChartState.loaded,
          data: createTestResponse(
            points: [
              createTestSeries(pointId: 'pt-001'),
              createTestSeries(pointId: 'pt-002'),
            ],
          ),
          visibleSeries: const {'pt-001', 'pt-002'},
        );

        notifier.toggleSeriesVisibility('pt-001');

        expect(notifier.state.visibleSeries, isNot(contains('pt-001')));
        expect(notifier.state.visibleSeries, contains('pt-002'));
      });

      test('切换单个序列不影响其他序列', () {
        notifier.state = ChartViewState(
          state: ChartState.loaded,
          data: createTestResponse(
            points: [
              createTestSeries(pointId: 'pt-001'),
              createTestSeries(pointId: 'pt-002'),
              createTestSeries(pointId: 'pt-003'),
            ],
          ),
          visibleSeries: const {'pt-001', 'pt-002', 'pt-003'},
        );

        notifier.toggleSeriesVisibility('pt-002');

        expect(notifier.state.visibleSeries, contains('pt-001'));
        expect(notifier.state.visibleSeries, isNot(contains('pt-002')));
        expect(notifier.state.visibleSeries, contains('pt-003'));
      });
    });

    group('reset', () {
      test('reset 将状态重置为初始值', () {
        notifier.state = ChartViewState(
          state: ChartState.loaded,
          data: createTestResponse(
            points: [createTestSeries()],
          ),
          visibleSeries: const {'pt-001'},
          errorMessage: 'some error',
          hoveredSeriesIndex: 2,
        );

        notifier.reset();

        expect(notifier.state.state, equals(ChartState.empty));
        expect(notifier.state.data, isNull);
        expect(notifier.state.visibleSeries, isEmpty);
        expect(notifier.state.errorMessage, isNull);
        expect(notifier.state.hoveredSeriesIndex, isNull);
      });

      test('reset 后 toggleSeriesVisibility 不影响空状态', () {
        notifier.state = ChartViewState(
          state: ChartState.loaded,
          visibleSeries: const {'pt-001'},
        );

        notifier.reset();
        notifier.toggleSeriesVisibility('pt-001');

        expect(notifier.state.visibleSeries, equals({'pt-001'}));
      });
    });

    group('soloSeries', () {
      test('soloSeries 仅显示指定序列', () {
        notifier.state = ChartViewState(
          state: ChartState.loaded,
          data: createTestResponse(
            points: [
              createTestSeries(pointId: 'pt-001'),
              createTestSeries(pointId: 'pt-002'),
              createTestSeries(pointId: 'pt-003'),
            ],
          ),
          visibleSeries: const {'pt-001', 'pt-002', 'pt-003'},
        );

        notifier.soloSeries('pt-002');

        expect(notifier.state.visibleSeries, equals({'pt-002'}));
      });
    });

    group('showAllSeries', () {
      test('showAllSeries 显示所有数据序列', () {
        notifier.state = ChartViewState(
          state: ChartState.loaded,
          data: createTestResponse(
            points: [
              createTestSeries(pointId: 'pt-001'),
              createTestSeries(pointId: 'pt-002'),
            ],
          ),
          visibleSeries: const {'pt-001'},
        );

        notifier.showAllSeries();

        expect(notifier.state.visibleSeries, contains('pt-001'));
        expect(notifier.state.visibleSeries, contains('pt-002'));
      });

      test('showAllSeries 在 data 为 null 时清空可见序列', () {
        notifier.state = const ChartViewState(
          state: ChartState.empty,
          visibleSeries: {'pt-001'},
        );

        notifier.showAllSeries();

        expect(notifier.state.visibleSeries, isEmpty);
      });
    });

    group('setHoveredSeriesIndex', () {
      test('设置悬停序列索引', () {
        notifier.setHoveredSeriesIndex(3);

        expect(notifier.state.hoveredSeriesIndex, equals(3));
      });

      test('覆盖已有悬停序列索引', () {
        notifier.state = const ChartViewState(hoveredSeriesIndex: 2);

        notifier.setHoveredSeriesIndex(5);

        expect(notifier.state.hoveredSeriesIndex, equals(5));
      });
    });

    group('loadData', () {
      test('加载成功时状态变为 loaded', () async {
        final response = createTestResponse(
          points: [createTestSeries()],
          totalSamples: 3,
          returnedSamples: 3,
        );
        when(() => mockService.queryData(any())).thenAnswer(
          (_) async => response,
        );

        await notifier.loadData(
          const DataQueryRequest(
            experimentId: 'exp-001',
            deviceId: 'dev-001',
            pointIds: ['pt-001'],
          ),
        );

        expect(notifier.state.state, equals(ChartState.loaded));
        expect(notifier.state.data, isNotNull);
        expect(notifier.state.visibleSeries, contains('pt-001'));
      });

      test('加载空数据时状态变为 noDataInRange', () async {
        final response = createTestResponse(
          points: [
            const ChartPointSeries(
              pointId: 'pt-001',
              pointName: 'Empty',
              unit: '-',
              dataType: 'float32',
              timestamps: [],
              values: [],
            ),
          ],
        );
        when(() => mockService.queryData(any())).thenAnswer(
          (_) async => response,
        );

        await notifier.loadData(
          const DataQueryRequest(
            experimentId: 'exp-001',
            deviceId: 'dev-001',
            pointIds: ['pt-001'],
          ),
        );

        expect(notifier.state.state, equals(ChartState.noDataInRange));
      });

      test('加载出错时状态变为 error', () async {
        when(() => mockService.queryData(any())).thenThrow(
          Exception('Network error'),
        );

        await notifier.loadData(
          const DataQueryRequest(
            experimentId: 'exp-001',
            deviceId: 'dev-001',
            pointIds: ['pt-001'],
          ),
        );

        expect(notifier.state.state, equals(ChartState.error));
        expect(notifier.state.errorMessage, contains('Network error'));
      });
    });
  });
}
