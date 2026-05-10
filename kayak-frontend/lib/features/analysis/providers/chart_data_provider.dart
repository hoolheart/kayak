/// 图表数据状态管理
///
/// 管理图表数据的加载、显示和交互状态。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chart_models.dart';
import '../services/mock_analysis_service.dart';
import 'analysis_controller_provider.dart';

/// 图表数据 Provider
final chartDataProvider =
    StateNotifierProvider<ChartDataNotifier, ChartViewState>((ref) {
  final service = ref.watch(analysisServiceProvider);
  return ChartDataNotifier(service);
});

/// 图表数据 Notifier
class ChartDataNotifier extends StateNotifier<ChartViewState> {
  ChartDataNotifier(this._service) : super(const ChartViewState());

  final AnalysisService _service;

  /// 加载数据
  Future<void> loadData(DataQueryRequest request) async {
    state = state.copyWith(
      state: ChartState.loading,
    );

    try {
      final response = await _service.queryData(request);

      if (response.points.isEmpty || response.points.every((p) => p.length == 0)) {
        state = state.copyWith(
          state: ChartState.noDataInRange,
          data: response,
          visibleSeries: const {},
        );
        return;
      }

      // 默认所有序列可见
      final visibleSeries = <String>{};
      for (final point in response.points) {
        visibleSeries.add(point.pointId);
      }

      state = state.copyWith(
        state: ChartState.loaded,
        data: response,
        visibleSeries: visibleSeries,
      );
    } catch (e) {
      state = state.copyWith(
        state: ChartState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 切换序列可见性
  void toggleSeriesVisibility(String pointId) {
    final current = Set<String>.from(state.visibleSeries);
    if (current.contains(pointId)) {
      current.remove(pointId);
    } else {
      current.add(pointId);
    }
    state = state.copyWith(visibleSeries: current);
  }

  /// 仅显示单个序列（双击图例）
  void soloSeries(String pointId) {
    state = state.copyWith(
      visibleSeries: {pointId},
    );
  }

  /// 显示所有序列
  void showAllSeries() {
    final all = <String>{};
    if (state.data != null) {
      for (final point in state.data!.points) {
        all.add(point.pointId);
      }
    }
    state = state.copyWith(visibleSeries: all);
  }

  /// 设置悬停的序列索引
  void setHoveredSeriesIndex(int? index) {
    state = state.copyWith(hoveredSeriesIndex: index);
  }

  /// 重置状态
  void reset() {
    state = const ChartViewState();
  }
}

/// 当前光标数据 Provider（用于 Tooltip）
final chartCursorDataProvider = Provider.autoDispose<ChartCursorData?>((ref) {
  // This will be updated by chart interactions
  return null;
});
