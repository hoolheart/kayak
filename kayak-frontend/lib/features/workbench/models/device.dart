/// 设备数据模型
///
/// 定义设备的核心属性和序列化逻辑
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';
part 'device.g.dart';

/// 设备模型
@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    required String workbenchId,
    String? parentId,
    required String name,
    required ProtocolType protocolType,
    Map<String, dynamic>? protocolParams,
    String? manufacturer,
    String? model,
    String? sn,
    required DeviceStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}

/// 协议类型枚举
enum ProtocolType {
  @JsonValue('virtual')
  virtual,
  @JsonValue('modbus_tcp')
  modbusTcp,
  @JsonValue('modbus_rtu')
  modbusRtu,
  @JsonValue('can')
  can,
  @JsonValue('visa')
  visa,
  @JsonValue('mqtt')
  mqtt,
}

/// 设备状态枚举
enum DeviceStatus {
  @JsonValue('offline')
  offline,
  @JsonValue('online')
  online,
  @JsonValue('error')
  error,
}
