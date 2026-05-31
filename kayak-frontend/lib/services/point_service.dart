import 'package:dio/dio.dart';

import '../models/common.dart';
import '../models/point.dart';
import 'api_client.dart';

/// PointService — 测点服务
///
/// 封装测点相关的 HTTP API 调用，提供类型安全的接口。
/// 使用 [ApiClient] 发起请求，利用 [ErrorInterceptor] 统一处理错误。
///
/// 所有方法不捕获异常 —— 异常由 ErrorInterceptor 和 Provider 层处理。
class PointService {
  /// 创建 PointService 实例
  ///
  /// [client] ApiClient 实例，提供 HTTP GET/POST/PUT/DELETE 方法
  PointService(this._client);

  final ApiClient _client;

  /// 获取指定设备下的所有测点
  ///
  /// 调用 `GET /api/v1/points?device_id={deviceId}`。
  ///
  /// [deviceId] 设备 ID
  /// 返回 [List]<[Point]> 测点列表
  Future<List<Point>> listByDevice(String deviceId) async {
    final response = await _client.get(
      '/api/v1/points',
      queryParameters: <String, dynamic>{'device_id': deviceId},
    );

    final apiResponse = ApiResponse<List<Point>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((item) => Point.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// 获取测点详情
  ///
  /// 调用 `GET /api/v1/points/{id}`。
  ///
  /// [id] 测点 ID
  /// 返回 [Point] 对象
  /// 如果资源不存在，抛出 404 [DioException]
  Future<Point> getById(String id) async {
    final response = await _client.get(
      '/api/v1/points/$id',
    );

    final apiResponse = ApiResponse<Point>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Point.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 创建测点
  ///
  /// 调用 `POST /api/v1/points`。
  ///
  /// [deviceId] 所属设备 ID
  /// [name] 测点名称
  /// [dataType] 数据类型（'number', 'integer', 'string', 'boolean'）
  /// [accessType] 访问类型（'ro', 'wo', 'rw'）
  /// [unit] 单位（可选）
  /// [minValue] 最小值（可选）
  /// [maxValue] 最大值（可选）
  /// [defaultValue] 默认值（可选）
  /// 返回创建的 [Point] 对象
  Future<Point> create({
    required String deviceId,
    required String name,
    required String dataType,
    required String accessType,
    String? unit,
    double? minValue,
    double? maxValue,
    String? defaultValue,
  }) async {
    final data = <String, dynamic>{
      'device_id': deviceId,
      'name': name,
      'data_type': dataType,
      'access_type': accessType,
    };

    if (unit != null) {
      data['unit'] = unit;
    }
    if (minValue != null) {
      data['min_value'] = minValue;
    }
    if (maxValue != null) {
      data['max_value'] = maxValue;
    }
    if (defaultValue != null) {
      data['default_value'] = defaultValue;
    }

    final response = await _client.post(
      '/api/v1/points',
      data: data,
    );

    final apiResponse = ApiResponse<Point>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Point.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 更新测点
  ///
  /// 调用 `PUT /api/v1/points/{id}`。
  /// 支持部分更新：只传递需要变更的字段即可。
  ///
  /// [id] 测点 ID
  /// [data] 需要更新的字段，如 `{'name': 'Updated Name'}`
  /// 返回更新后的 [Point] 对象
  Future<Point> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '/api/v1/points/$id',
      data: data,
    );

    final apiResponse = ApiResponse<Point>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Point.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 删除测点
  ///
  /// 调用 `DELETE /api/v1/points/{id}`。
  ///
  /// [id] 测点 ID
  /// 正常返回 void；如果资源不存在，抛出 404 [DioException]
  Future<void> delete(String id) async {
    await _client.delete(
      '/api/v1/points/$id',
    );
  }

  /// 读取测点值
  ///
  /// 调用 `GET /api/v1/points/{id}/value`。
  ///
  /// [id] 测点 ID
  /// 返回 [PointValue] 对象，包含 pointId, value, timestamp
  Future<PointValue> getValue(String id) async {
    final response = await _client.get(
      '/api/v1/points/$id/value',
    );

    final apiResponse = ApiResponse<PointValue>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => PointValue.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 写入测点值
  ///
  /// 调用 `PUT /api/v1/points/{id}/value`。
  ///
  /// [id] 测点 ID
  /// [value] 要写入的值
  Future<void> setValue(String id, Object value) async {
    await _client.put(
      '/api/v1/points/$id/value',
      data: <String, dynamic>{'value': value},
    );
  }
}
