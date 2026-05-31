import 'package:dio/dio.dart';

import '../models/common.dart';
import '../models/device.dart';
import 'api_client.dart';

/// DeviceService — 设备服务
///
/// 封装设备相关的 HTTP API 调用，提供类型安全的接口。
/// 使用 [ApiClient] 发起请求，利用 [ErrorInterceptor] 统一处理错误。
///
/// 所有方法不捕获异常 —— 异常由 ErrorInterceptor 和 Provider 层处理。
class DeviceService {
  /// 创建 DeviceService 实例
  ///
  /// [client] ApiClient 实例，提供 HTTP GET/POST/PUT/DELETE 方法
  DeviceService(this._client);

  final ApiClient _client;

  /// 获取指定工作台下的所有设备（平铺列表）
  ///
  /// 调用 `GET /api/v1/devices?workbench_id={workbenchId}`。
  ///
  /// [workbenchId] 工作台 ID
  /// 返回 [List]<[Device]> 设备列表
  Future<List<Device>> listByWorkbench(String workbenchId) async {
    final response = await _client.get(
      '/api/v1/devices',
      queryParameters: <String, dynamic>{'workbench_id': workbenchId},
    );

    final apiResponse = ApiResponse<List<Device>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>)
          .map((item) => Device.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// 获取设备详情
  ///
  /// 调用 `GET /api/v1/devices/{id}`。
  ///
  /// [id] 设备 ID
  /// 返回 [Device] 对象
  /// 如果资源不存在，抛出 404 [DioException]
  Future<Device> getById(String id) async {
    final response = await _client.get(
      '/api/v1/devices/$id',
    );

    final apiResponse = ApiResponse<Device>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Device.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 创建设备
  ///
  /// 调用 `POST /api/v1/devices`。
  ///
  /// [workbenchId] 所属工作台 ID
  /// [name] 设备名称
  /// [protocolType] 协议类型
  /// [protocolParams] 协议参数（可选）
  /// [parentId] 父设备 ID（可选，用于创建设备树中的子设备）
  /// 返回创建的 [Device] 对象
  Future<Device> create({
    required String workbenchId,
    required String name,
    required String protocolType,
    Map<String, dynamic>? protocolParams,
    String? parentId,
  }) async {
    final data = <String, dynamic>{
      'workbench_id': workbenchId,
      'name': name,
      'protocol_type': protocolType,
    };

    if (protocolParams != null) {
      data['protocol_params'] = protocolParams;
    }
    if (parentId != null) {
      data['parent_id'] = parentId;
    }

    final response = await _client.post(
      '/api/v1/devices',
      data: data,
    );

    final apiResponse = ApiResponse<Device>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Device.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 更新设备
  ///
  /// 调用 `PUT /api/v1/devices/{id}`。
  /// 支持部分更新：只传递需要变更的字段即可。
  ///
  /// [id] 设备 ID
  /// [data] 需要更新的字段，如 `{'name': 'New Name'}`
  /// 返回更新后的 [Device] 对象
  Future<Device> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '/api/v1/devices/$id',
      data: data,
    );

    final apiResponse = ApiResponse<Device>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Device.fromJson(json as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// 删除设备
  ///
  /// 调用 `DELETE /api/v1/devices/{id}`。
  ///
  /// [id] 设备 ID
  /// 正常返回 void；如果资源不存在，抛出 404 [DioException]
  Future<void> delete(String id) async {
    await _client.delete(
      '/api/v1/devices/$id',
    );
  }

  /// 测试设备连接
  ///
  /// 调用 `POST /api/v1/devices/{id}/test-connection`。
  ///
  /// [id] 设备 ID
  /// 返回连接测试结果 Map（如 `{'success': true, 'latency_ms': 15}`）
  Future<Map<String, dynamic>> testConnection(String id) async {
    final response = await _client.post(
      '/api/v1/devices/$id/test-connection',
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as Map<String, dynamic>,
    );

    return apiResponse.data;
  }

  /// 连接设备
  ///
  /// 调用 `POST /api/v1/devices/{id}/connect`。
  ///
  /// [id] 设备 ID
  Future<void> connect(String id) async {
    await _client.post(
      '/api/v1/devices/$id/connect',
    );
  }

  /// 断开设备
  ///
  /// 调用 `POST /api/v1/devices/{id}/disconnect`。
  ///
  /// [id] 设备 ID
  Future<void> disconnect(String id) async {
    await _client.post(
      '/api/v1/devices/$id/disconnect',
    );
  }

  /// 获取设备状态
  ///
  /// 调用 `GET /api/v1/devices/{id}/status`。
  ///
  /// [id] 设备 ID
  /// 返回状态字符串（如 `'online'`, `'offline'`, `'error'`）
  Future<String> getStatus(String id) async {
    final response = await _client.get(
      '/api/v1/devices/$id/status',
    );

    final apiResponse = ApiResponse<String>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as String,
    );

    return apiResponse.data;
  }
}
