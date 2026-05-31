// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VirtualConfig _$VirtualConfigFromJson(Map<String, dynamic> json) =>
    VirtualConfig(
      mode: json['mode'] as String,
      dataType: json['data_type'] as String,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      intervalMs: (json['interval_ms'] as num?)?.toInt(),
      $type: json['runtimeType'] as String? ?? 'virtual',
    );

Map<String, dynamic> _$VirtualConfigToJson(VirtualConfig instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'data_type': instance.dataType,
      'min': instance.min,
      'max': instance.max,
      'interval_ms': instance.intervalMs,
      'runtimeType': instance.$type,
    };

ModbusTcpConfig _$ModbusTcpConfigFromJson(Map<String, dynamic> json) =>
    ModbusTcpConfig(
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      slaveId: (json['slave_id'] as num?)?.toInt(),
      timeoutMs: (json['timeout_ms'] as num?)?.toInt(),
      $type: json['runtimeType'] as String? ?? 'modbusTcp',
    );

Map<String, dynamic> _$ModbusTcpConfigToJson(ModbusTcpConfig instance) =>
    <String, dynamic>{
      'host': instance.host,
      'port': instance.port,
      'slave_id': instance.slaveId,
      'timeout_ms': instance.timeoutMs,
      'runtimeType': instance.$type,
    };

ModbusRtuConfig _$ModbusRtuConfigFromJson(Map<String, dynamic> json) =>
    ModbusRtuConfig(
      serialPort: json['serial_port'] as String,
      baudRate: (json['baud_rate'] as num?)?.toInt(),
      dataBits: (json['data_bits'] as num?)?.toInt(),
      stopBits: (json['stop_bits'] as num?)?.toInt(),
      parity: json['parity'] as String?,
      slaveId: (json['slave_id'] as num?)?.toInt(),
      timeoutMs: (json['timeout_ms'] as num?)?.toInt(),
      $type: json['runtimeType'] as String? ?? 'modbusRtu',
    );

Map<String, dynamic> _$ModbusRtuConfigToJson(ModbusRtuConfig instance) =>
    <String, dynamic>{
      'serial_port': instance.serialPort,
      'baud_rate': instance.baudRate,
      'data_bits': instance.dataBits,
      'stop_bits': instance.stopBits,
      'parity': instance.parity,
      'slave_id': instance.slaveId,
      'timeout_ms': instance.timeoutMs,
      'runtimeType': instance.$type,
    };
