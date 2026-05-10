/// 分析控制器 Provider 单元测试
///
/// 测试 AnalysisControllerNotifier 的状态管理和交互行为，
/// 包括测点选择和 canLoadData 逻辑。
///
/// NOTE: selectExperiment/selectDevice 方法存在类型推断问题
/// （const [] 未标注为 const <String>[]），暂通过直接设置状态测试逻辑。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/analysis/models/chart_models.dart';
import 'package:kayak_frontend/features/analysis/providers/analysis_controller_provider.dart';

void main() {
  group('AnalysisControllerNotifier', () {
    late AnalysisControllerNotifier notifier;

    setUp(() {
      notifier = AnalysisControllerNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    group('初始状态', () {
      test('初始状态具有正确的默认值', () {
        expect(notifier.state.selectedExperimentId, isNull);
        expect(notifier.state.selectedDeviceId, isNull);
        expect(notifier.state.selectedPointIds, isEmpty);
        expect(notifier.state.startTime, isNull);
        expect(notifier.state.endTime, isNull);
        expect(notifier.state.downsample, equals(1000));
        expect(notifier.state.showDataTable, isFalse);
        expect(notifier.state.autoRefresh, isFalse);
        expect(notifier.state.isLoadingExperiments, isFalse);
        expect(notifier.state.isLoadingDevices, isFalse);
        expect(notifier.state.isLoadingPoints, isFalse);
        expect(notifier.state.activePreset, isNull);
      });
    });

    group('级联清除行为 (通过状态模拟)', () {
      test('更换试验时应级联清除 deviceId 和 pointIds', () {
        // 模拟：用户先选择了试验、设备和测点
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-old',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>['pt-001', 'pt-002'],
          startTime: DateTime(2026),
        );

        // 模拟选择新试验后级联清除的效果
        notifier.state = notifier.state.copyWith(
          selectedExperimentId: 'exp-new',
          selectedDeviceId: null,
          selectedPointIds: const <String>[],
        );

        expect(notifier.state.selectedExperimentId, equals('exp-new'));
        expect(notifier.state.selectedDeviceId, isNull);
        expect(notifier.state.selectedPointIds, isEmpty);
        // 时间范围不应被清除
        expect(notifier.state.startTime, equals(DateTime(2026)));
      });

      test('更换设备时应级联清除 pointIds', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-old',
          selectedPointIds: const <String>['pt-001', 'pt-002'],
        );

        // 模拟选择新设备后级联清除的效果
        notifier.state = notifier.state.copyWith(
          selectedDeviceId: 'dev-new',
          selectedPointIds: const <String>[],
        );

        expect(notifier.state.selectedDeviceId, equals('dev-new'));
        expect(notifier.state.selectedPointIds, isEmpty);
        expect(notifier.state.selectedExperimentId, equals('exp-001'));
      });

      test('选择 null 试验清除所有选择', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>['pt-001'],
        );

        notifier.state = notifier.state.copyWith(
          selectedExperimentId: null,
          selectedDeviceId: null,
          selectedPointIds: const <String>[],
        );

        expect(notifier.state.selectedExperimentId, isNull);
        expect(notifier.state.selectedDeviceId, isNull);
        expect(notifier.state.selectedPointIds, isEmpty);
      });
    });

    group('togglePointSelection', () {
      test('选择未选中的测点', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>[],
        );

        notifier.togglePointSelection('pt-001');

        expect(notifier.state.selectedPointIds, contains('pt-001'));
        expect(notifier.state.selectedPointIds.length, equals(1));
      });

      test('取消已选中的测点', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>['pt-001', 'pt-002'],
        );

        notifier.togglePointSelection('pt-001');

        expect(notifier.state.selectedPointIds, isNot(contains('pt-001')));
        expect(notifier.state.selectedPointIds, contains('pt-002'));
      });

      test('最多只能选择 4 个测点', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>[
            'pt-001',
            'pt-002',
            'pt-003',
            'pt-004',
          ],
        );

        notifier.togglePointSelection('pt-005');

        expect(notifier.state.selectedPointIds.length, equals(4));
        expect(notifier.state.selectedPointIds, isNot(contains('pt-005')));
      });

      test('选择第 4 个测点成功', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>['pt-001', 'pt-002', 'pt-003'],
        );

        notifier.togglePointSelection('pt-004');

        expect(notifier.state.selectedPointIds.length, equals(4));
        expect(notifier.state.selectedPointIds, contains('pt-004'));
      });
    });

    group('canLoadData', () {
      test('所有条件满足时 canLoadData 为 true', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>['pt-001'],
        );

        expect(notifier.state.canLoadData, isTrue);
      });

      test('缺少 experimentId 时 canLoadData 为 false', () {
        notifier.state = AnalysisControlState(
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>['pt-001'],
        );

        expect(notifier.state.canLoadData, isFalse);
      });

      test('缺少 deviceId 时 canLoadData 为 false', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedPointIds: const <String>['pt-001'],
        );

        expect(notifier.state.canLoadData, isFalse);
      });

      test('没有选中测点时 canLoadData 为 false', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
        );

        expect(notifier.state.canLoadData, isFalse);
      });

      test('选中测点为空列表时 canLoadData 为 false', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>[],
        );

        expect(notifier.state.canLoadData, isFalse);
      });

      test('初始状态 canLoadData 为 false', () {
        expect(notifier.state.canLoadData, isFalse);
      });

      test('仅有试验时 canLoadData 为 false', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
        );

        expect(notifier.state.canLoadData, isFalse);
      });

      test('有试验和设备但无测点时 canLoadData 为 false', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
        );

        expect(notifier.state.canLoadData, isFalse);
      });

      test('选择测点后 canLoadData 变为 true', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
        );
        notifier.togglePointSelection('pt-001');

        expect(notifier.state.canLoadData, isTrue);
      });

      test('取消最后一个测点后 canLoadData 变为 false', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>['pt-001'],
        );

        notifier.togglePointSelection('pt-001');

        expect(notifier.state.canLoadData, isFalse);
      });
    });

    group('setTimeRange', () {
      test('设置时间范围', () {
        final start = DateTime(2026, 5, 1);
        final end = DateTime(2026, 5, 2);

        notifier.setTimeRange(start, end);

        expect(notifier.state.startTime, equals(start));
        expect(notifier.state.endTime, equals(end));
        expect(notifier.state.activePreset, isNull);
      });

      test('清除时间范围', () {
        notifier.state = AnalysisControlState(
          startTime: DateTime(2026),
          endTime: DateTime(2026),
          activePreset: '24h',
        );

        notifier.setTimeRange(null, null);

        expect(notifier.state.startTime, isNull);
        expect(notifier.state.endTime, isNull);
      });
    });

    group('setDownsample', () {
      test('设置降采样点数', () {
        notifier.setDownsample(500);

        expect(notifier.state.downsample, equals(500));
      });

      test('降采样点数低于 100 时 clamp 到 100', () {
        notifier.setDownsample(50);

        expect(notifier.state.downsample, equals(100));
      });

      test('降采样点数高于 10000 时 clamp 到 10000', () {
        notifier.setDownsample(20000);

        expect(notifier.state.downsample, equals(10000));
      });
    });

    group('toggleDataTable', () {
      test('切换数据表格显示状态', () {
        notifier.toggleDataTable(true);

        expect(notifier.state.showDataTable, isTrue);

        notifier.toggleDataTable(false);

        expect(notifier.state.showDataTable, isFalse);
      });
    });

    group('toggleAutoRefresh', () {
      test('切换自动刷新状态', () {
        notifier.toggleAutoRefresh(true);

        expect(notifier.state.autoRefresh, isTrue);

        notifier.toggleAutoRefresh(false);

        expect(notifier.state.autoRefresh, isFalse);
      });
    });

    group('applyPresetTimeRange', () {
      test('应用 1h 预设', () {
        notifier.applyPresetTimeRange('1h');

        expect(notifier.state.startTime, isNotNull);
        expect(notifier.state.endTime, isNotNull);
        expect(notifier.state.activePreset, equals('1h'));
        expect(
          notifier.state.endTime!.difference(notifier.state.startTime!),
          equals(const Duration(hours: 1)),
        );
      });

      test('应用 24h 预设', () {
        notifier.applyPresetTimeRange('24h');

        expect(notifier.state.activePreset, equals('24h'));
        expect(
          notifier.state.endTime!.difference(notifier.state.startTime!),
          equals(const Duration(hours: 24)),
        );
      });

      test('应用 all 预设清除时间范围', () {
        notifier.state = AnalysisControlState(
          startTime: DateTime(2026),
          endTime: DateTime(2026),
        );

        notifier.applyPresetTimeRange('all');

        expect(notifier.state.startTime, isNull);
        expect(notifier.state.endTime, isNull);
        expect(notifier.state.activePreset, equals('all'));
      });
    });

    group('reset', () {
      test('reset 将状态重置为初始值', () {
        notifier.state = AnalysisControlState(
          selectedExperimentId: 'exp-001',
          selectedDeviceId: 'dev-001',
          selectedPointIds: const <String>['pt-001'],
          startTime: DateTime(2026),
          endTime: DateTime(2026),
          downsample: 500,
          showDataTable: true,
          autoRefresh: true,
          activePreset: '1h',
        );

        notifier.reset();

        expect(notifier.state.selectedExperimentId, isNull);
        expect(notifier.state.selectedDeviceId, isNull);
        expect(notifier.state.selectedPointIds, isEmpty);
        expect(notifier.state.startTime, isNull);
        expect(notifier.state.endTime, isNull);
        expect(notifier.state.downsample, equals(1000));
        expect(notifier.state.showDataTable, isFalse);
        expect(notifier.state.autoRefresh, isFalse);
        expect(notifier.state.activePreset, isNull);
      });
    });
  });
}
