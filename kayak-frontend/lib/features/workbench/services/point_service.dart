/// 测点服务
///
/// 处理测点相关的API调用
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/authenticated_api_client.dart';
import '../../../core/auth/providers.dart';
import '../models/point.dart';

/// 测点服务接口
abstract class PointServiceInterface {
  Future<List<Point>> listPoints(String deviceId);
  Future<Point> createPoint({
    required String deviceId,
    required String name,
    required DataType dataType,
    required AccessType accessType,
    String? unit,
    double? minValue,
    double? maxValue,
    String? defaultValue,
  });
  Future<Point> updatePoint({
    required String pointId,
    String? name,
    String? unit,
    double? minValue,
    double? maxValue,
    String? defaultValue,
    PointStatus? status,
  });
  Future<Point> getPoint(String pointId);
  Future<void> deletePoint(String pointId);
  Future<PointValue> readPointValue(String pointId);
  Future<void> writePointValue(String pointId, double value);
}

/// 测点服务实现
class PointService implements PointServiceInterface {
  final ApiClientInterface _apiClient;

  PointService(this._apiClient);

  @override
  Future<List<Point>> listPoints(String deviceId) async {
    final response = await _apiClient.get(
      '/api/v1/devices/$deviceId/points',
    );

    final data = (response as Map)['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => Point.fromJson(e as Map<String, dynamic>))
        .toList();

    return items;
  }

  @override
  Future<Point> createPoint({
    required String deviceId,
    required String name,
    required DataType dataType,
    required AccessType accessType,
    String? unit,
    double? minValue,
    double? maxValue,
    String? defaultValue,
  }) async {
    final Map<String, dynamic> requestData = {
      'name': name,
      'data_type': dataType.name,
      'access_type': accessType.name,
    };

    if (unit != null) requestData['unit'] = unit;
    if (minValue != null) requestData['min_value'] = minValue;
    if (maxValue != null) requestData['max_value'] = maxValue;
    if (defaultValue != null) requestData['default_value'] = defaultValue;

    final response = await _apiClient.post(
      '/api/v1/devices/$deviceId/points',
      data: requestData,
    );

    return Point.fromJson((response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<Point> updatePoint({
    required String pointId,
    String? name,
    String? unit,
    double? minValue,
    double? maxValue,
    String? defaultValue,
    PointStatus? status,
  }) async {
    final Map<String, dynamic> requestData = {};

    if (name != null) requestData['name'] = name;
    if (unit != null) requestData['unit'] = unit;
    if (minValue != null) requestData['min_value'] = minValue;
    if (maxValue != null) requestData['max_value'] = maxValue;
    if (defaultValue != null) requestData['default_value'] = defaultValue;
    if (status != null) requestData['status'] = status.name;

    final response = await _apiClient.put(
      '/api/v1/points/$pointId',
      data: requestData,
    );

    return Point.fromJson((response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<Point> getPoint(String pointId) async {
    final response = await _apiClient.get('/api/v1/points/$pointId');
    return Point.fromJson((response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deletePoint(String pointId) async {
    await _apiClient.delete('/api/v1/points/$pointId');
  }

  @override
  Future<PointValue> readPointValue(String pointId) async {
    final response = await _apiClient.get(
      '/api/v1/points/$pointId/value',
    );
    return PointValue.fromJson(
        (response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> writePointValue(String pointId, double value) async {
    await _apiClient.put(
      '/api/v1/points/$pointId/value',
      data: {'value': value},
    );
  }
}

/// Point Service Provider
final pointServiceProvider = Provider<PointServiceInterface>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PointService(apiClient);
});
