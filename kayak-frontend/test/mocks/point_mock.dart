/// 测点Mock数据
///
/// 提供测点测试所需的Mock数据
library;

import 'package:kayak_frontend/features/workbench/models/point.dart';

/// 创建Mock测点
Point createMockPoint({
  String id = 'point-1',
  String deviceId = 'device-1',
  String name = 'Test Point',
  DataType dataType = DataType.number,
  AccessType accessType = AccessType.ro,
  String? unit,
  double? minValue,
  double? maxValue,
  String? defaultValue,
  PointStatus status = PointStatus.active,
}) {
  return Point(
    id: id,
    deviceId: deviceId,
    name: name,
    dataType: dataType,
    accessType: accessType,
    unit: unit,
    minValue: minValue,
    maxValue: maxValue,
    defaultValue: defaultValue,
    status: status,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

/// 创建多个Mock测点
List<Point> createMockPoints() {
  return [
    createMockPoint(
      id: 'point-temperature',
      name: 'Temperature',
      unit: '°C',
      minValue: -40.0,
      maxValue: 85.0,
    ),
    createMockPoint(
      id: 'point-pressure',
      name: 'Pressure',
      unit: 'Pa',
      minValue: 0.0,
      maxValue: 1000.0,
    ),
    createMockPoint(
      id: 'point-status',
      name: 'Status',
      dataType: DataType.integer,
    ),
    createMockPoint(
      id: 'point-switch',
      name: 'Switch',
      dataType: DataType.boolean,
      accessType: AccessType.rw,
    ),
    createMockPoint(
      id: 'point-label',
      name: 'Label',
      dataType: DataType.string,
    ),
    createMockPoint(
      id: 'point-disabled',
      name: 'Disabled Point',
      status: PointStatus.disabled,
    ),
  ];
}

/// 创建只读测点列表
List<Point> createMockReadOnlyPoints() {
  return [
    createMockPoint(
      id: 'point-ro-1',
      name: 'Read Only Point 1',
    ),
    createMockPoint(
      id: 'point-ro-2',
      name: 'Read Only Point 2',
      dataType: DataType.integer,
    ),
  ];
}

/// 创建可写测点列表
List<Point> createMockWritablePoints() {
  return [
    createMockPoint(
      id: 'point-rw-1',
      name: 'Read Write Point 1',
      accessType: AccessType.rw,
    ),
    createMockPoint(
      id: 'point-wo-1',
      name: 'Write Only Point 1',
      dataType: DataType.boolean,
      accessType: AccessType.wo,
    ),
  ];
}

/// 创建Mock测点值
PointValue createMockPointValue({
  String pointId = 'point-1',
  dynamic value = 25.5,
  DateTime? timestamp,
}) {
  return PointValue(
    pointId: pointId,
    value: value,
    timestamp: timestamp ?? DateTime.now(),
  );
}

/// 创建不同类型的测点值
Map<String, PointValue> createMockPointValues() {
  return {
    'point-temperature': createMockPointValue(
      pointId: 'point-temperature',
    ),
    'point-pressure': createMockPointValue(
      pointId: 'point-pressure',
      value: 101.325,
    ),
    'point-status': createMockPointValue(
      pointId: 'point-status',
      value: 1,
    ),
    'point-switch': createMockPointValue(
      pointId: 'point-switch',
      value: true,
    ),
    'point-label': createMockPointValue(
      pointId: 'point-label',
      value: 'status_ok',
    ),
  };
}
