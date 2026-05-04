/// 设备服务
///
/// 处理设备相关的API调用
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/authenticated_api_client.dart';
import '../../../core/auth/providers.dart';
import '../models/device.dart';

/// 设备服务接口
abstract class DeviceServiceInterface {
  Future<List<Device>> listDevices(String workbenchId);
  Future<Device> createDevice({
    required String workbenchId,
    required String name,
    required ProtocolType protocolType,
    String? parentId,
    Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
  });
  Future<Device> updateDevice({
    required String deviceId,
    String? name,
    Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
    DeviceStatus? status,
  });
  Future<Device> getDevice(String deviceId);
  Future<void> deleteDevice(String deviceId);
}

/// 设备服务实现
class DeviceService implements DeviceServiceInterface {
  DeviceService(this._apiClient);
  final ApiClientInterface _apiClient;

  @override
  Future<List<Device>> listDevices(String workbenchId) async {
    final response = await _apiClient.get(
      '/api/v1/workbenches/$workbenchId/devices',
    );

    final data = (response as Map)['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();

    return items;
  }

  @override
  Future<Device> createDevice({
    required String workbenchId,
    required String name,
    required ProtocolType protocolType,
    String? parentId,
    Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
  }) async {
    final Map<String, dynamic> requestData = {
      'name': name,
      'protocol_type': protocolType.name,
    };

    if (parentId != null) requestData['parent_id'] = parentId;
    if (protocolParams != null) {
      requestData['protocol_params'] = protocolParams;
    }
    if (manufacturer != null) requestData['manufacturer'] = manufacturer;
    if (model != null) requestData['model'] = model;
    if (sn != null) requestData['sn'] = sn;

    final response = await _apiClient.post(
      '/api/v1/workbenches/$workbenchId/devices',
      data: requestData,
    );

    return Device.fromJson((response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<Device> updateDevice({
    required String deviceId,
    String? name,
    Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
    DeviceStatus? status,
  }) async {
    final Map<String, dynamic> requestData = {};

    if (name != null) requestData['name'] = name;
    if (protocolParams != null) {
      requestData['protocol_params'] = protocolParams;
    }
    if (manufacturer != null) requestData['manufacturer'] = manufacturer;
    if (model != null) requestData['model'] = model;
    if (sn != null) requestData['sn'] = sn;
    if (status != null) requestData['status'] = status.name;

    final response = await _apiClient.put(
      '/api/v1/devices/$deviceId',
      data: requestData,
    );

    return Device.fromJson((response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<Device> getDevice(String deviceId) async {
    final response = await _apiClient.get('/api/v1/devices/$deviceId');
    return Device.fromJson((response as Map)['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    await _apiClient.delete('/api/v1/devices/$deviceId');
  }
}

/// Device Service Provider
final deviceServiceProvider = Provider<DeviceServiceInterface>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeviceService(apiClient);
});
