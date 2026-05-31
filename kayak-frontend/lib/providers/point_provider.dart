import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/point.dart';
import 'services.dart';

// ============================================================
// PointListNotifier — 测点列表状态管理器
// ============================================================

/// PointListNotifier — 测点列表状态管理器
///
/// 使用 Riverpod 3.x [AsyncNotifier] API，通过 family 方式按设备 ID 区分。
/// [deviceId] 为 family 参数，表示设备 ID。
///
/// 状态通过 [AsyncValue]<[List]<[Point]>> 表达列表生命周期：
/// - [AsyncLoading] — 加载中
/// - [AsyncData] — 加载成功，包含测点列表
/// - [AsyncError] — 加载失败
///
/// 额外维护测点值的 Map（pointId → PointValue），
/// 由 [refreshValues] 方法批量加载。
class PointListNotifier extends AsyncNotifier<List<Point>> {
  /// 创建 PointListNotifier 实例
  ///
  /// [deviceId] 设备 ID，由 family provider 传入。
  PointListNotifier(this.deviceId);

  /// 设备 ID（由 family 参数传入）
  final String deviceId;

  /// 测点当前值缓存 Map（pointId → PointValue）
  final Map<String, PointValue> _values = {};

  /// 获取当前缓存的测点值
  Map<String, PointValue> get values => Map.unmodifiable(_values);

  @override
  Future<List<Point>> build() async {
    final service = ref.read(pointServiceProvider);
    final points = await service.listByDevice(deviceId);

    // 清空旧的值缓存
    _values.clear();

    return points;
  }

  /// 刷新测点列表
  ///
  /// 重新加载数据。刷新期间状态为 [AsyncLoading]。
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// 创建测点，创建成功后刷新列表
  ///
  /// [name] 测点名称
  /// [dataType] 数据类型
  /// [accessType] 访问类型
  /// [unit] 单位（可选）
  /// [minValue] 最小值（可选）
  /// [maxValue] 最大值（可选）
  /// [defaultValue] 默认值（可选）
  Future<void> createPoint({
    required String name,
    required String dataType,
    required String accessType,
    String? unit,
    double? minValue,
    double? maxValue,
    String? defaultValue,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(pointServiceProvider);
      await service.create(
        deviceId: deviceId,
        name: name,
        dataType: dataType,
        accessType: accessType,
        unit: unit,
        minValue: minValue,
        maxValue: maxValue,
        defaultValue: defaultValue,
      );

      // 创建成功后刷新列表
      state = await AsyncValue.guard(build);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 删除测点，删除成功后刷新列表
  ///
  /// [pointId] 要删除的测点 ID
  Future<void> deletePoint(String pointId) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(pointServiceProvider);
      await service.delete(pointId);

      // 删除成功后刷新列表
      state = await AsyncValue.guard(build);
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
    }
  }

  /// 批量读取所有测点的当前值
  ///
  /// 遍历当前列表中的每个测点，调用 [PointService.getValue]。
  /// 单个测点读取失败不影响其他测点。
  /// 结果缓存在 [_values] 中，可通过 [values] 获取。
  Future<Map<String, PointValue>> refreshValues() async {
    final currentPoints = state.value ?? <Point>[];

    for (final point in currentPoints) {
      try {
        final service = ref.read(pointServiceProvider);
        final pointValue = await service.getValue(point.id);
        _values[point.id] = pointValue;
      } catch (e) {
        // 单个测点值读取失败不影响其他测点
        // 保留原有缓存值（如有）
        if (!_values.containsKey(point.id)) {
          _values[point.id] = PointValue(pointId: point.id);
        }
      }
    }

    // 触发 UI 重建以反映最新的值
    state = AsyncData(state.value ?? <Point>[]);

    return Map.unmodifiable(_values);
  }

  /// 将异常映射为用户可读的错误消息
  String _mapError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络后重试';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return _mapStatusCode(statusCode);

        default:
          return '网络异常，请稍后重试';
      }
    }

    return error.toString();
  }

  /// 将 HTTP 状态码映射为用户可读的消息
  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数有误，请检查输入';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 409:
        return '资源冲突，请检查是否已存在相同名称的测点';
      case 422:
        return '数据验证失败，请检查输入';
      case 500:
      case 502:
      case 503:
        return '服务暂时不可用，请稍后再试';
      default:
        return '操作失败，请重试（错误码: $statusCode）';
    }
  }
}

/// 测点列表 Provider
///
/// 通过 [AsyncNotifierProvider.family] 暴露 [PointListNotifier]，
/// 提供 [AsyncValue]<[List]<[Point]>> 类型的列表状态，按设备 ID 区分。
///
/// 读取方式：
/// ```dart
/// // 读取状态
/// final listState = ref.watch(pointListProvider('dev-1'));
///
/// // 获取当前值缓存
/// final values = ref.read(pointListProvider('dev-1').notifier).values;
///
/// // 调用方法
/// ref.read(pointListProvider('dev-1').notifier).refresh();
/// ref.read(pointListProvider('dev-1').notifier).createPoint(name: 'Temp', ...);
/// ref.read(pointListProvider('dev-1').notifier).refreshValues();
/// ```
final pointListProvider = AsyncNotifierProvider.family<
  PointListNotifier,
  List<Point>,
  String
>(
  PointListNotifier.new,
);
