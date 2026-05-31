import 'package:json_annotation/json_annotation.dart';

part 'protocol.g.dart';

// ============================================================
// ProtocolConfig — 协议配置基类
// ============================================================
sealed class ProtocolConfig {
  const ProtocolConfig();

  factory ProtocolConfig.fromJson(Map<String, dynamic> json) {
    final type = json['runtimeType'] as String?;
    switch (type) {
      case 'virtual':
        return VirtualConfig.fromJson(json);
      case 'modbusTcp':
        return ModbusTcpConfig.fromJson(json);
      case 'modbusRtu':
        return ModbusRtuConfig.fromJson(json);
      default:
        throw ArgumentError('Unknown ProtocolConfig type: $type');
    }
  }
}

// ============================================================
// VirtualConfig — 虚拟协议配置
// ============================================================
@JsonSerializable()
class VirtualConfig extends ProtocolConfig {

  const VirtualConfig({
    required this.mode,
    required this.dataType,
    this.min,
    this.max,
    this.intervalMs,
    this.$type = 'virtual',
  });

  factory VirtualConfig.fromJson(Map<String, dynamic> json) =>
      _$VirtualConfigFromJson(json);
  final String mode;
  @JsonKey(name: 'data_type')
  final String dataType;
  final double? min;
  final double? max;
  @JsonKey(name: 'interval_ms')
  final int? intervalMs;
  @JsonKey(name: 'runtimeType')
  final String? $type;
  Map<String, dynamic> toJson() => _$VirtualConfigToJson(this);

  VirtualConfig copyWith({
    String? mode,
    String? dataType,
    double? min,
    double? max,
    int? intervalMs,
    String? $type,
  }) {
    return VirtualConfig(
      mode: mode ?? this.mode,
      dataType: dataType ?? this.dataType,
      min: min ?? this.min,
      max: max ?? this.max,
      intervalMs: intervalMs ?? this.intervalMs,
      $type: $type ?? this.$type,
    );
  }
}

// ============================================================
// ModbusTcpConfig — Modbus TCP 协议配置
// ============================================================
@JsonSerializable()
class ModbusTcpConfig extends ProtocolConfig {

  const ModbusTcpConfig({
    required this.host,
    required this.port,
    this.slaveId,
    this.timeoutMs,
    this.$type = 'modbusTcp',
  });

  factory ModbusTcpConfig.fromJson(Map<String, dynamic> json) =>
      _$ModbusTcpConfigFromJson(json);
  final String host;
  final int port;
  @JsonKey(name: 'slave_id')
  final int? slaveId;
  @JsonKey(name: 'timeout_ms')
  final int? timeoutMs;
  @JsonKey(name: 'runtimeType')
  final String? $type;
  Map<String, dynamic> toJson() => _$ModbusTcpConfigToJson(this);

  ModbusTcpConfig copyWith({
    String? host,
    int? port,
    int? slaveId,
    int? timeoutMs,
    String? $type,
  }) {
    return ModbusTcpConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      slaveId: slaveId ?? this.slaveId,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      $type: $type ?? this.$type,
    );
  }
}

// ============================================================
// ModbusRtuConfig — Modbus RTU 协议配置
// ============================================================
@JsonSerializable()
class ModbusRtuConfig extends ProtocolConfig {

  const ModbusRtuConfig({
    required this.serialPort,
    this.baudRate,
    this.dataBits,
    this.stopBits,
    this.parity,
    this.slaveId,
    this.timeoutMs,
    this.$type = 'modbusRtu',
  });

  factory ModbusRtuConfig.fromJson(Map<String, dynamic> json) =>
      _$ModbusRtuConfigFromJson(json);
  @JsonKey(name: 'serial_port')
  final String serialPort;
  @JsonKey(name: 'baud_rate')
  final int? baudRate;
  @JsonKey(name: 'data_bits')
  final int? dataBits;
  @JsonKey(name: 'stop_bits')
  final int? stopBits;
  final String? parity;
  @JsonKey(name: 'slave_id')
  final int? slaveId;
  @JsonKey(name: 'timeout_ms')
  final int? timeoutMs;
  @JsonKey(name: 'runtimeType')
  final String? $type;
  Map<String, dynamic> toJson() => _$ModbusRtuConfigToJson(this);

  ModbusRtuConfig copyWith({
    String? serialPort,
    int? baudRate,
    int? dataBits,
    int? stopBits,
    String? parity,
    int? slaveId,
    int? timeoutMs,
    String? $type,
  }) {
    return ModbusRtuConfig(
      serialPort: serialPort ?? this.serialPort,
      baudRate: baudRate ?? this.baudRate,
      dataBits: dataBits ?? this.dataBits,
      stopBits: stopBits ?? this.stopBits,
      parity: parity ?? this.parity,
      slaveId: slaveId ?? this.slaveId,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      $type: $type ?? this.$type,
    );
  }
}
