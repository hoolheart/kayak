/// 测点值Provider
///
/// 处理测点值的定时刷新
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/point.dart';
import '../services/point_service.dart';

/// 测点值状态
class PointValueState {
  const PointValueState({
    this.value,
    this.isLoading = false,
    this.error,
  });
  final PointValue? value;
  final bool isLoading;
  final String? error;

  PointValueState copyWith({
    PointValue? value,
    bool? isLoading,
    String? error,
  }) {
    return PointValueState(
      value: value ?? this.value,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 测点值Notifier
class PointValueNotifier extends StateNotifier<PointValueState> {
  PointValueNotifier(this._service, this.pointId)
      : super(const PointValueState()) {
    _loadValue();
    _startAutoRefresh();
  }
  final PointServiceInterface _service;
  final String pointId;
  Timer? _refreshTimer;
  static const defaultInterval = Duration(seconds: 5);

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(defaultInterval, (_) {
      _loadValue();
    });
  }

  Future<void> _loadValue() async {
    try {
      final value = await _service.readPointValue(pointId);
      state = state.copyWith(value: value, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// 手动刷新
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadValue();
  }

  /// 停止刷新
  void stopRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}

/// Provider for PointValueNotifier
final pointValueProvider =
    StateNotifierProvider.family<PointValueNotifier, PointValueState, String>(
        (ref, pointId) {
  final service = ref.watch(pointServiceProvider);
  return PointValueNotifier(service, pointId);
});
