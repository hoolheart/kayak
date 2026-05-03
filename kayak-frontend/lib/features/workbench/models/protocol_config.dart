/// 协议配置数据模型
///
/// 定义三种协议 (Virtual, Modbus TCP, Modbus RTU) 的配置结构，
/// 支持 JSON 序列化。
library;

/// Virtual 协议数据模式
enum VirtualMode {
  random, // 随机生成
  fixed, // 固定值
  sine, // 正弦波
  ramp; // 线性递增
}

/// Virtual 协议数据类型
enum VirtualDataType {
  number, // 浮点数
  integer, // 整数
  string, // 字符串
  boolean; // 布尔值
}

/// 设备访问类型
enum AccessType {
  ro, // 只读
  wo, // 只写
  rw; // 读写

  /// 显示标签
  String get label {
    switch (this) {
      case AccessType.ro:
        return 'RO (只读)';
      case AccessType.wo:
        return 'WO (只写)';
      case AccessType.rw:
        return 'RW (读写)';
    }
  }
}

/// Virtual 模式显示标签
extension VirtualModeLabel on VirtualMode {
  String get label {
    switch (this) {
      case VirtualMode.random:
        return 'Random (随机)';
      case VirtualMode.fixed:
        return 'Fixed (固定)';
      case VirtualMode.sine:
        return 'Sine (正弦)';
      case VirtualMode.ramp:
        return 'Ramp (斜坡)';
    }
  }
}

/// Virtual 数据类型显示标签
extension VirtualDataTypeLabel on VirtualDataType {
  String get label {
    switch (this) {
      case VirtualDataType.number:
        return 'Number (浮点数)';
      case VirtualDataType.integer:
        return 'Integer (整数)';
      case VirtualDataType.string:
        return 'String (字符串)';
      case VirtualDataType.boolean:
        return 'Boolean (布尔值)';
    }
  }
}

/// Virtual 协议配置
class VirtualConfig {
  final VirtualMode mode;
  final VirtualDataType dataType;
  final AccessType accessType;
  final double minValue;
  final double maxValue;
  final double? fixedValue;
  final int sampleInterval;

  const VirtualConfig({
    required this.mode,
    required this.dataType,
    required this.accessType,
    required this.minValue,
    required this.maxValue,
    this.fixedValue,
    this.sampleInterval = 1000,
  });

  /// 默认配置
  factory VirtualConfig.defaults() => const VirtualConfig(
        mode: VirtualMode.random,
        dataType: VirtualDataType.number,
        accessType: AccessType.rw,
        minValue: 0,
        maxValue: 100,
      );

  factory VirtualConfig.fromJson(Map<String, dynamic> json) {
    return VirtualConfig(
      mode: VirtualMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => VirtualMode.random,
      ),
      dataType: VirtualDataType.values.firstWhere(
        (e) => e.name == json['dataType'],
        orElse: () => VirtualDataType.number,
      ),
      accessType: AccessType.values.firstWhere(
        (e) => e.name == json['accessType'],
        orElse: () => AccessType.rw,
      ),
      minValue: (json['minValue'] as num?)?.toDouble() ?? 0,
      maxValue: (json['maxValue'] as num?)?.toDouble() ?? 100,
      fixedValue: (json['fixedValue'] as num?)?.toDouble(),
      sampleInterval: (json['sampleInterval'] as num?)?.toInt() ?? 1000,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'dataType': dataType.name,
        'accessType': accessType.name,
        'minValue': minValue,
        'maxValue': maxValue,
        if (fixedValue != null) 'fixedValue': fixedValue,
        'sampleInterval': sampleInterval,
      };
}

/// Modbus TCP 协议配置
class TcpConfig {
  final String host;
  final int port;
  final int slaveId;
  final int timeoutMs;
  final int connectionPoolSize;

  const TcpConfig({
    required this.host,
    this.port = 502,
    this.slaveId = 1,
    this.timeoutMs = 5000,
    this.connectionPoolSize = 4,
  });

  /// 默认配置
  factory TcpConfig.defaults() => const TcpConfig(host: '');

  factory TcpConfig.fromJson(Map<String, dynamic> json) {
    return TcpConfig(
      host: json['host'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 502,
      slaveId: (json['slave_id'] as num?)?.toInt() ?? 1,
      timeoutMs: (json['timeout_ms'] as num?)?.toInt() ?? 5000,
      connectionPoolSize: (json['connection_pool_size'] as num?)?.toInt() ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'slave_id': slaveId,
        'timeout_ms': timeoutMs,
        'connection_pool_size': connectionPoolSize,
      };
}

/// Modbus RTU 协议配置
class RtuConfig {
  final String port;
  final int baudRate;
  final int dataBits;
  final int stopBits;
  final String parity;
  final int slaveId;
  final int timeoutMs;

  const RtuConfig({
    required this.port,
    this.baudRate = 9600,
    this.dataBits = 8,
    this.stopBits = 1,
    this.parity = 'None',
    this.slaveId = 1,
    this.timeoutMs = 1000,
  });

  /// 默认配置
  factory RtuConfig.defaults() => const RtuConfig(port: '');

  factory RtuConfig.fromJson(Map<String, dynamic> json) {
    return RtuConfig(
      port: json['port'] as String? ?? '',
      baudRate: (json['baud_rate'] as num?)?.toInt() ?? 9600,
      dataBits: (json['data_bits'] as num?)?.toInt() ?? 8,
      stopBits: (json['stop_bits'] as num?)?.toInt() ?? 1,
      parity: json['parity'] as String? ?? 'None',
      slaveId: (json['slave_id'] as num?)?.toInt() ?? 1,
      timeoutMs: (json['timeout_ms'] as num?)?.toInt() ?? 1000,
    );
  }

  Map<String, dynamic> toJson() => {
        'port': port,
        'baud_rate': baudRate,
        'data_bits': dataBits,
        'stop_bits': stopBits,
        'parity': parity,
        'slave_id': slaveId,
        'timeout_ms': timeoutMs,
      };
}

/// 串口信息
class SerialPort {
  final String path;
  final String description;

  const SerialPort({required this.path, required this.description});

  factory SerialPort.fromJson(Map<String, dynamic> json) => SerialPort(
        path: json['path'] as String,
        description: json['description'] as String? ?? '',
      );
}

/// 连接测试结果
class ConnectionTestResult {
  final bool success;
  final int? latencyMs;
  final String message;

  const ConnectionTestResult({
    required this.success,
    this.latencyMs,
    required this.message,
  });

  factory ConnectionTestResult.fromJson(Map<String, dynamic> json) =>
      ConnectionTestResult(
        // Backend TestConnectionResult field is named "connected", not "success"
        // See: kayak-backend/src/services/device/types.rs:41
        success: json['connected'] as bool,
        latencyMs: json['latency_ms'] as int?,
        message: json['message'] as String? ?? '',
      );
}

/// 协议信息
class ProtocolInfo {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> configSchema;

  const ProtocolInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.configSchema,
  });

  factory ProtocolInfo.fromJson(Map<String, dynamic> json) => ProtocolInfo(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        configSchema: json['config_schema'] as Map<String, dynamic>? ?? {},
      );
}
