// ignore_for_file: avoid_redundant_argument_values
import 'package:kayak_frontend/models/point.dart';
import 'package:kayak_frontend/services/point_service.dart';

/// FakePointService — 用于 Point 相关 Widget 单元测试的 Fake PointService
///
/// 提供完全可控的行为：成功/失败、延迟、调用计数、参数记录。
/// 实现了 [PointService] 的所有公有接口。
class FakePointService implements PointService {
  FakePointService({
    this.points = const [],
    this.values = const {},
    this.delay,
    this.listFails = false,
    this.getByIdFails = false,
    this.createFails = false,
    this.updateFails = false,
    this.deleteFails = false,
    this.getValueFails = false,
    this.setValueFails = false,
  });

  // ========== 配置参数 ==========
  final List<Point> points;
  final Map<String, PointValue> values;
  final Duration? delay;
  final bool listFails;
  final bool getByIdFails;
  final bool createFails;
  final bool updateFails;
  final bool deleteFails;
  final bool getValueFails;
  final bool setValueFails;

  // ========== 可观测状态 ==========
  int listByDeviceCallCount = 0;
  int getByIdCallCount = 0;
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  int getValueCallCount = 0;
  int setValueCallCount = 0;

  String? lastListDeviceId;
  String? lastGetById;
  String? lastDeleteId;
  String? lastGetValueId;
  String? lastSetValueId;
  Object? lastSetValue;

  Map<String, dynamic>? lastCreateData;
  Map<String, dynamic>? lastUpdateData;

  /// 重置可观测状态
  void reset() {
    listByDeviceCallCount = 0;
    getByIdCallCount = 0;
    createCallCount = 0;
    updateCallCount = 0;
    deleteCallCount = 0;
    getValueCallCount = 0;
    setValueCallCount = 0;

    lastListDeviceId = null;
    lastGetById = null;
    lastDeleteId = null;
    lastGetValueId = null;
    lastSetValueId = null;
    lastSetValue = null;
    lastCreateData = null;
    lastUpdateData = null;
  }

  @override
  Future<List<Point>> listByDevice(String deviceId) async {
    listByDeviceCallCount++;
    lastListDeviceId = deviceId;

    if (delay != null) await Future.delayed(delay!);
    if (listFails) throw Exception('Failed to load points');

    return points.where((p) => p.deviceId == deviceId).toList();
  }

  @override
  Future<Point> getById(String id) async {
    getByIdCallCount++;
    lastGetById = id;

    if (getByIdFails) throw Exception('Point not found');

    final point = points.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Point not found'),
    );
    return point;
  }

  @override
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
    createCallCount++;
    lastCreateData = {
      'device_id': deviceId,
      'name': name,
      'data_type': dataType,
      'access_type': accessType,
      'unit': unit,
      'min_value': minValue,
      'max_value': maxValue,
      'default_value': defaultValue,
    };

    if (delay != null) await Future.delayed(delay!);
    if (createFails) throw Exception('Create point failed');

    return Point(
      id: 'pt-new-$createCallCount',
      deviceId: deviceId,
      name: name,
      dataType: DataType.values.firstWhere(
        (d) => d.name == dataType,
        orElse: () => DataType.number,
      ),
      accessType: AccessType.values.firstWhere(
        (a) => a.name == accessType,
        orElse: () => AccessType.ro,
      ),
      unit: unit,
      minValue: minValue,
      maxValue: maxValue,
      defaultValue: defaultValue,
      status: 'normal',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Point> update(String id, Map<String, dynamic> data) async {
    updateCallCount++;
    lastUpdateData = data;

    if (updateFails) throw Exception('Update point failed');

    final point = points.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Point not found'),
    );
    return point;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    lastDeleteId = id;

    if (deleteFails) throw Exception('Delete point failed');
  }

  @override
  Future<PointValue> getValue(String id) async {
    getValueCallCount++;
    lastGetValueId = id;

    if (delay != null) await Future.delayed(delay!);
    if (getValueFails) throw Exception('Failed to get value');

    if (values.containsKey(id)) {
      return values[id]!;
    }

    return PointValue(pointId: id, value: null);
  }

  @override
  Future<void> setValue(String id, Object value) async {
    setValueCallCount++;
    lastSetValueId = id;
    lastSetValue = value;

    if (setValueFails) throw Exception('Set value failed');
  }
}
