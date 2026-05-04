/// 协议相关 API 服务
///
/// 处理协议列表、串口扫描、连接测试等 API 调用。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/authenticated_api_client.dart';
import '../../../core/auth/providers.dart';
import '../models/protocol_config.dart';

/// 协议服务
class ProtocolService {
  ProtocolService(this._apiClient);
  final ApiClientInterface _apiClient;

  /// 获取支持的协议列表
  Future<List<ProtocolInfo>> getProtocols() async {
    final response = await _apiClient.get('/api/v1/protocols');
    final data = (response as Map)['data'] as List;
    return data
        .map((e) => ProtocolInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取可用串口列表
  Future<List<SerialPort>> getSerialPorts() async {
    final response = await _apiClient.get('/api/v1/system/serial-ports');
    final data = (response as Map)['data'] as List;
    return data
        .map((e) => SerialPort.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 测试设备连接
  Future<ConnectionTestResult> testConnection(
    String deviceId,
    Map<String, dynamic> config,
  ) async {
    final response = await _apiClient.post(
      '/api/v1/devices/$deviceId/test-connection',
      data: config,
    );
    final data = (response as Map)['data'] as Map<String, dynamic>;
    return ConnectionTestResult.fromJson(data);
  }
}

/// Protocol Service Provider
final protocolServiceProvider = Provider<ProtocolService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProtocolService(apiClient);
});
