import 'package:freezed_annotation/freezed_annotation.dart';

part 'protocol.freezed.dart';
part 'protocol.g.dart';

// ============================================================
// ProtocolConfig — 协议配置密封联合（sealed union）
// ============================================================
@freezed
sealed class ProtocolConfig with _$ProtocolConfig {
  const factory ProtocolConfig.virtual({
    required String mode,
    @JsonKey(name: 'data_type') required String dataType,
    double? min,
    double? max,
    @JsonKey(name: 'interval_ms') int? intervalMs,
  }) = VirtualConfig;

  const factory ProtocolConfig.modbusTcp({
    required String host,
    required int port,
    @JsonKey(name: 'slave_id') int? slaveId,
    @JsonKey(name: 'timeout_ms') int? timeoutMs,
  }) = ModbusTcpConfig;

  const factory ProtocolConfig.modbusRtu({
    @JsonKey(name: 'serial_port') required String serialPort,
    @JsonKey(name: 'baud_rate') int? baudRate,
    @JsonKey(name: 'data_bits') int? dataBits,
    @JsonKey(name: 'stop_bits') int? stopBits,
    String? parity,
    @JsonKey(name: 'slave_id') int? slaveId,
    @JsonKey(name: 'timeout_ms') int? timeoutMs,
  }) = ModbusRtuConfig;

  factory ProtocolConfig.fromJson(Map<String, dynamic> json) =>
      _$ProtocolConfigFromJson(json);
}
