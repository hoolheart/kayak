/// 图表模型单元测试
///
/// 测试 ChartPointSeries、ChartDataResponse、ChartViewState、AnalysisControlState
/// 等数据模型的基本行为和边界条件。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/analysis/models/chart_models.dart';

void main() {
  group('ChartPointSeries', () {
    test('基本属性正确', () {
      const series = ChartPointSeries(
        pointId: 'pt-001',
        pointName: 'Temperature',
        unit: '°C',
        dataType: 'float32',
        timestamps: [1000, 2000, 3000],
        values: [25.0, 30.0, 35.0],
      );

      expect(series.pointId, equals('pt-001'));
      expect(series.pointName, equals('Temperature'));
      expect(series.unit, equals('°C'));
      expect(series.dataType, equals('float32'));
      expect(series.length, equals(3));
    });

    test('空数据时 length 为 0', () {
      const series = ChartPointSeries(
        pointId: 'pt-empty',
        pointName: 'Empty',
        unit: '-',
        dataType: 'float32',
        timestamps: [],
        values: [],
      );

      expect(series.length, equals(0));
      expect(series.timestamps, isEmpty);
      expect(series.values, isEmpty);
    });

    test('单点数据时 length 为 1', () {
      const series = ChartPointSeries(
        pointId: 'pt-single',
        pointName: 'Single',
        unit: 'Pa',
        dataType: 'float32',
        timestamps: [5000],
        values: [101325.0],
      );

      expect(series.length, equals(1));
      expect(series.minValue, equals(101325.0));
      expect(series.maxValue, equals(101325.0));
    });

    test('多点数据时 minValue / maxValue 计算正确', () {
      const series = ChartPointSeries(
        pointId: 'pt-multi',
        pointName: 'Multi',
        unit: '°C',
        dataType: 'float32',
        timestamps: [1000, 2000, 3000, 4000, 5000],
        values: [10.0, 5.0, 20.0, -5.0, 15.0],
      );

      expect(series.minValue, equals(-5.0));
      expect(series.maxValue, equals(20.0));
    });

    test('负值数据的 minValue / maxValue 计算正确', () {
      const series = ChartPointSeries(
        pointId: 'pt-neg',
        pointName: 'Negative',
        unit: 'V',
        dataType: 'float32',
        timestamps: [1000, 2000, 3000],
        values: [-10.0, -50.0, -20.0],
      );

      expect(series.minValue, equals(-50.0));
      expect(series.maxValue, equals(-10.0));
    });

    test('dateTimes 正确转换时间戳', () {
      const series = ChartPointSeries(
        pointId: 'pt-dt',
        pointName: 'DateTime',
        unit: '-',
        dataType: 'float32',
        timestamps: [0, 1000, 2000],
        values: [1.0, 2.0, 3.0],
      );

      final dateTimes = series.dateTimes;
      expect(dateTimes.length, equals(3));
      expect(dateTimes[0], equals(DateTime.fromMillisecondsSinceEpoch(0)));
      expect(
        dateTimes[1],
        equals(DateTime.fromMillisecondsSinceEpoch(1000)),
      );
    });

    test('copyWith 创建新实例并保留未修改字段', () {
      const series = ChartPointSeries(
        pointId: 'pt-001',
        pointName: 'Temperature',
        unit: '°C',
        dataType: 'float32',
        timestamps: [1000, 2000],
        values: [25.0, 30.0],
      );

      final copied = series.copyWith(pointName: 'Updated');

      expect(copied.pointName, equals('Updated'));
      expect(copied.pointId, equals('pt-001'));
      expect(copied.unit, equals('°C'));
      expect(copied.values, equals(series.values));
    });

    test('空数据时 minValue 调用抛出 StateError', () {
      const series = ChartPointSeries(
        pointId: 'pt-empty',
        pointName: 'Empty',
        unit: '-',
        dataType: 'float32',
        timestamps: [],
        values: [],
      );

      expect(() => series.minValue, throwsA(isA<StateError>()));
    });

    test('空数据时 maxValue 调用抛出 StateError', () {
      const series = ChartPointSeries(
        pointId: 'pt-empty',
        pointName: 'Empty',
        unit: '-',
        dataType: 'float32',
        timestamps: [],
        values: [],
      );

      expect(() => series.maxValue, throwsA(isA<StateError>()));
    });
  });

  group('ChartDataResponse', () {
    test('基本属性正确', () {
      const response = ChartDataResponse(
        experimentId: 'exp-001',
        deviceId: 'dev-001',
        points: [],
        totalSamples: 0,
        returnedSamples: 0,
      );

      expect(response.experimentId, equals('exp-001'));
      expect(response.deviceId, equals('dev-001'));
      expect(response.points, isEmpty);
      expect(response.totalSamples, equals(0));
    });

    test('allTimestamps 返回排序后的时间戳并集', () {
      const response = ChartDataResponse(
        experimentId: 'exp-001',
        deviceId: 'dev-001',
        points: [
          ChartPointSeries(
            pointId: 'pt-001',
            pointName: 'A',
            unit: '-',
            dataType: 'float32',
            timestamps: [1000, 3000, 5000],
            values: [1.0, 2.0, 3.0],
          ),
          ChartPointSeries(
            pointId: 'pt-002',
            pointName: 'B',
            unit: '-',
            dataType: 'float32',
            timestamps: [2000, 4000, 5000],
            values: [4.0, 5.0, 6.0],
          ),
        ],
        totalSamples: 6,
        returnedSamples: 6,
      );

      final timestamps = response.allTimestamps;
      expect(timestamps, equals([1000, 2000, 3000, 4000, 5000]));
    });

    test('fromJson 正确解析响应', () {
      final json = {
        'experiment_id': 'exp-001',
        'device_id': 'dev-001',
        'points': [
          {
            'point_id': 'pt-001',
            'point_name': 'Temperature',
            'unit': '°C',
            'data_type': 'float32',
            'timestamps': [1000, 2000],
            'values': [25.0, 30.0],
          },
        ],
        'total_samples': 100,
        'returned_samples': 100,
      };

      final response = ChartDataResponse.fromJson(json);

      expect(response.experimentId, equals('exp-001'));
      expect(response.points.length, equals(1));
      expect(response.points.first.pointName, equals('Temperature'));
      expect(response.points.first.values, equals([25.0, 30.0]));
    });
  });

  group('ChartViewState', () {
    test('初始状态默认值正确', () {
      const state = ChartViewState();

      expect(state.state, equals(ChartState.empty));
      expect(state.data, isNull);
      expect(state.errorMessage, isNull);
      expect(state.visibleSeries, isEmpty);
      expect(state.hoveredSeriesIndex, isNull);
    });

    test('isSeriesVisible 正确判断可见性', () {
      const state = ChartViewState(
        visibleSeries: {'pt-001', 'pt-002'},
      );

      expect(state.isSeriesVisible('pt-001'), isTrue);
      expect(state.isSeriesVisible('pt-002'), isTrue);
      expect(state.isSeriesVisible('pt-003'), isFalse);
    });

    test('copyWith 更新单个字段', () {
      const state = ChartViewState();
      final newState = state.copyWith(state: ChartState.loading);

      expect(newState.state, equals(ChartState.loading));
      expect(newState.visibleSeries, equals(state.visibleSeries));
    });
  });

  group('AnalysisControlState', () {
    test('初始状态默认值正确', () {
      const state = AnalysisControlState();

      expect(state.selectedExperimentId, isNull);
      expect(state.selectedDeviceId, isNull);
      expect(state.selectedPointIds, isEmpty);
      expect(state.startTime, isNull);
      expect(state.endTime, isNull);
      expect(state.downsample, equals(1000));
      expect(state.showDataTable, isFalse);
      expect(state.autoRefresh, isFalse);
      expect(state.activePreset, isNull);
    });

    test('canLoadData 当所有条件满足时返回 true', () {
      final state = AnalysisControlState(
        selectedExperimentId: 'exp-001',
        selectedDeviceId: 'dev-001',
        selectedPointIds: ['pt-001'],
      );

      expect(state.canLoadData, isTrue);
    });

    test('canLoadData 当缺少 experimentId 时返回 false', () {
      const state = AnalysisControlState(
        selectedDeviceId: 'dev-001',
        selectedPointIds: ['pt-001'],
      );

      expect(state.canLoadData, isFalse);
    });

    test('canLoadData 当缺少 deviceId 时返回 false', () {
      const state = AnalysisControlState(
        selectedExperimentId: 'exp-001',
        selectedPointIds: ['pt-001'],
      );

      expect(state.canLoadData, isFalse);
    });

    test('canLoadData 当没有选中测点时返回 false', () {
      const state = AnalysisControlState(
        selectedExperimentId: 'exp-001',
        selectedDeviceId: 'dev-001',
      );

      expect(state.canLoadData, isFalse);
    });

    test('copyWith 使用 Object() 占位符保留原值', () {
      const state = AnalysisControlState(
        selectedExperimentId: 'exp-001',
        downsample: 500,
      );

      final newState = state.copyWith(downsample: 2000);

      expect(newState.downsample, equals(2000));
      expect(newState.selectedExperimentId, equals('exp-001'));
    });
  });
}
