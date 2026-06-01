import 'package:kayak_frontend/models/device.dart';
import 'package:kayak_frontend/services/device_service.dart';

/// FakeDeviceService — 用于 DeviceTree 单元测试的 Fake DeviceService
///
/// 提供完全可控的行为：成功/失败、延迟、调用计数、参数记录。
/// 实现了 [DeviceService] 的所有公有接口。
class FakeDeviceService implements DeviceService {
  FakeDeviceService({
    this.devices = const [],
    this.delay,
    this.listFails = false,
    this.deleteFails = false,
    this.getByIdFails = false,
  });

  // ========== 配置参数 ==========
  final List<Device> devices;
  final Duration? delay;
  final bool listFails;
  final bool deleteFails;
  final bool getByIdFails;

  // ========== 可观测状态 ==========
  int listByWorkbenchCallCount = 0;
  int getByIdCallCount = 0;
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  int testConnectionCallCount = 0;
  int connectCallCount = 0;
  int disconnectCallCount = 0;
  int getStatusCallCount = 0;

  String? lastListWorkbenchId;
  String? lastGetById;
  String? lastDeleteId;
  String? lastCreateWorkbenchId;
  String? lastCreateName;

  /// 重置可观测状态
  void reset() {
    listByWorkbenchCallCount = 0;
    getByIdCallCount = 0;
    createCallCount = 0;
    updateCallCount = 0;
    deleteCallCount = 0;
    testConnectionCallCount = 0;
    connectCallCount = 0;
    disconnectCallCount = 0;
    getStatusCallCount = 0;

    lastListWorkbenchId = null;
    lastGetById = null;
    lastDeleteId = null;
    lastCreateWorkbenchId = null;
    lastCreateName = null;
  }

  @override
  Future<List<Device>> listByWorkbench(String workbenchId) async {
    listByWorkbenchCallCount++;
    lastListWorkbenchId = workbenchId;

    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (listFails) {
      throw Exception('Failed to load devices');
    }

    return devices.where((d) => d.workbenchId == workbenchId).toList();
  }

  @override
  Future<Device> getById(String id) async {
    getByIdCallCount++;
    lastGetById = id;

    if (getByIdFails) {
      throw Exception('Device not found');
    }

    final device = devices.firstWhere(
      (d) => d.id == id,
      orElse: () => throw Exception('Device not found'),
    );
    return device;
  }

  @override
  Future<Device> create({
    required String workbenchId,
    required String name,
    required String protocolType,
    Map<String, dynamic>? protocolParams,
    String? parentId,
  }) async {
    createCallCount++;
    lastCreateWorkbenchId = workbenchId;
    lastCreateName = name;

    final device = Device(
      id: 'new-device-$createCallCount',
      workbenchId: workbenchId,
      parentId: parentId,
      name: name,
      protocolType: ProtocolType.values.firstWhere(
        (p) => p.name == protocolType,
        orElse: () => ProtocolType.virtual,
      ),
      status: 'offline',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return device;
  }

  @override
  Future<Device> update(String id, Map<String, dynamic> data) async {
    updateCallCount++;
    final device = await getById(id);
    return device;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    lastDeleteId = id;

    if (deleteFails) {
      throw Exception('Delete failed');
    }
  }

  @override
  Future<Map<String, dynamic>> testConnection(String id) async {
    testConnectionCallCount++;
    return {'success': true, 'latency_ms': 15};
  }

  @override
  Future<void> connect(String id) async {
    connectCallCount++;
  }

  @override
  Future<void> disconnect(String id) async {
    disconnectCallCount++;
  }

  @override
  Future<String> getStatus(String id) async {
    getStatusCallCount++;
    return 'online';
  }
}
