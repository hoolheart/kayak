/// 测点列表Provider
///
/// 处理测点列表的状态
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/point.dart';
import '../services/point_service.dart';

/// 测点列表Notifier
class PointListNotifier extends StateNotifier<AsyncValue<List<Point>>> {
  final PointServiceInterface _service;
  final String deviceId;

  PointListNotifier(this._service, this.deviceId)
      : super(const AsyncValue.loading()) {
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final points = await _service.listPoints(deviceId);
      state = AsyncValue.data(points);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPoints();
  }
}

/// Provider for PointListNotifier
final pointListProvider = StateNotifierProvider.family<PointListNotifier,
    AsyncValue<List<Point>>, String>((ref, deviceId) {
  final service = ref.watch(pointServiceProvider);
  return PointListNotifier(service, deviceId);
});
