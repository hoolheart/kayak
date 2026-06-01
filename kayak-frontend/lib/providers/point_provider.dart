import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/app_localizations.dart';
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

  /// 创建测点，创建成功后刷新列表并返回创建的 [Point] 对象。
  ///
  /// [name] 测点名称
  /// [dataType] 数据类型
  /// [accessType] 访问类型
  /// [unit] 单位（可选）
  /// [minValue] 最小值（可选）
  /// [maxValue] 最大值（可选）
  /// [defaultValue] 默认值（可选）
  /// 返回创建的 [Point] 对象。
  Future<Point> createPoint({
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
      final newPoint = await service.create(
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

      return newPoint;
    } catch (e, st) {
      state = AsyncError(_mapError(e), st);
      rethrow;
    }
  }

  /// 更新测点，更新成功后刷新列表
  ///
  /// [pointId] 要更新的测点 ID
  /// [data] 需要更新的字段 Map
  Future<void> updatePoint(String pointId, Map<String, dynamic> data) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(pointServiceProvider);
      await service.update(pointId, data);

      // 更新成功后刷新列表
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

  /// 将异常映射为错误代码标识符。
  ///
  /// 返回以 `error.` 为前缀的错误代码，UI 层可通过 [resolveErrorCode] 结合 l10n 显示。
  /// 相比于直接返回硬编码字符串，此方式支持国际化。
  String _mapError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return 'error.network';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return _mapStatusCode(statusCode);

        default:
          return 'error.network';
      }
    }

    return error.toString();
  }

  /// 将 HTTP 状态码映射为错误代码
  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'error.badRequest';
      case 401:
        return 'error.unauthorized';
      case 403:
        return 'error.forbidden';
      case 404:
        return 'error.notFound';
      case 409:
        return 'error.conflict';
      case 422:
        return 'error.validation';
      case 500:
      case 502:
      case 503:
        return 'error.server';
      default:
        return 'error.unknown($statusCode)';
    }
  }
}

/// 将 Provider 错误代码解析为用户可读的错误消息。
///
/// [errorCode] _mapError 返回的错误代码字符串。
/// [l10n] AppLocalizations 实例，用于获取本地化文本。
/// 返回本地化的错误消息。
String resolveErrorCode(String errorCode, AppLocalizations l10n) {
  switch (errorCode) {
    case 'error.network':
      return l10n.networkError;
    case 'error.unauthorized':
      return l10n.sessionExpired;
    case 'error.badRequest':
      return '${l10n.pointSaveFailed}: ${l10n.errorBadRequest}';
    case 'error.forbidden':
      return l10n.errorForbidden;
    case 'error.notFound':
      return l10n.errorNotFound;
    case 'error.conflict':
      return l10n.errorConflict;
    case 'error.validation':
      return l10n.errorValidation;
    case 'error.server':
      return l10n.errorServer;
    default:
      return errorCode.startsWith('error.')
          ? '${l10n.errorDefault} ($errorCode)'
          : errorCode;
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
/// ref.read(pointListProvider('dev-1').notifier).updatePoint('pt-1', {'name': 'New Name'});
/// ref.read(pointListProvider('dev-1').notifier).deletePoint('pt-1');
/// ref.read(pointListProvider('dev-1').notifier).refreshValues();
/// ```
final pointListProvider = AsyncNotifierProvider.family<
  PointListNotifier,
  List<Point>,
  String
>(
  PointListNotifier.new,
);

/// 单测点值 Provider
///
/// 通过 [FutureProvider.family] 暴露，以 pointId 为参数。
/// 返回 [PointValue] 对象，包含 pointId, value, timestamp。
/// 通过 [ref.invalidate] 触发刷新。
final pointValueProvider = FutureProvider.family<PointValue, String>((ref, pointId) async {
  final service = ref.read(pointServiceProvider);
  return service.getValue(pointId);
});
