/// Modbus 测点配置模型
///
/// 表示一个 Modbus 测点的完整配置信息，
/// 包含功能码、地址、数量、数据类型、缩放因子和偏移量。
library;

/// Modbus 功能码枚举
enum ModbusFunctionCode {
  /// FC01 - Coil (线圈), 读写
  fc01(1, 'Coil (线圈)', 'bool'),

  /// FC02 - Discrete Input (离散输入), 只读
  fc02(2, 'Discrete Input (离散输入)', 'bool'),

  /// FC03 - Holding Register (保持寄存器), 读写
  fc03(3, 'Holding Register (保持寄存器)', 'uint16'),

  /// FC04 - Input Register (输入寄存器), 只读
  fc04(4, 'Input Register (输入寄存器)', 'uint16');

  const ModbusFunctionCode(this.code, this.label, this.defaultDataType);

  /// 功能码数值 (1-4)
  final int code;

  /// 显示标签
  final String label;

  /// 默认数据类型
  final String defaultDataType;

  /// 根据功能码数值查找枚举
  static ModbusFunctionCode fromCode(int code) {
    return ModbusFunctionCode.values.firstWhere(
      (fc) => fc.code == code,
      orElse: () => ModbusFunctionCode.fc03,
    );
  }

  /// 数据类型是否锁定为 BOOL (FC01/FC02 锁定)
  bool get isBoolLocked => code == 1 || code == 2;

  /// 是否为只读功能码 (FC02, FC04)
  bool get isReadOnly => code == 2 || code == 4;

  /// 格式化显示文本
  String get displayText => '${code.toString().padLeft(2, '0')} - $label';
}

/// Modbus 测点数据类型
enum ModbusDataType {
  /// 无符号16位整数
  uint16('uint16'),

  /// 有符号16位整数
  int16('int16'),

  /// 32位浮点数 (占2个寄存器)
  float32('float32'),

  /// 布尔型 (仅用于 FC01/FC02)
  bool_('bool');

  const ModbusDataType(this.value);

  /// 字符串值
  final String value;

  /// 根据字符串查找枚举
  static ModbusDataType fromString(String value) {
    return ModbusDataType.values.firstWhere(
      (dt) => dt.value == value,
      orElse: () => ModbusDataType.uint16,
    );
  }

  /// 返回对应的通用 DataType
  String get genericDataType {
    switch (this) {
      case ModbusDataType.bool_:
        return 'boolean';
      case ModbusDataType.float32:
        return 'number';
      case ModbusDataType.uint16:
      case ModbusDataType.int16:
        return 'integer';
    }
  }
}

/// Modbus 测点配置
class ModbusPointConfig {
  /// 功能码
  final ModbusFunctionCode functionCode;

  /// 起始地址 (0-65535)
  final int address;

  /// 数量 (1-125, float32时1-62)
  final int quantity;

  /// 数据类型
  final ModbusDataType dataType;

  /// 缩放因子 (默认 1.0)
  final double scale;

  /// 偏移量 (默认 0.0)
  final double offset;

  const ModbusPointConfig({
    this.functionCode = ModbusFunctionCode.fc03,
    required this.address,
    required this.quantity,
    this.dataType = ModbusDataType.uint16,
    this.scale = 1.0,
    this.offset = 0.0,
  });

  /// 默认配置 (FC03, address=0, quantity=1, uint16)
  factory ModbusPointConfig.defaults() => const ModbusPointConfig(
        address: 0,
        quantity: 1,
      );

  /// 从 JSON 创建
  factory ModbusPointConfig.fromJson(Map<String, dynamic> json) {
    return ModbusPointConfig(
      functionCode:
          ModbusFunctionCode.fromCode((json['function_code'] as num).toInt()),
      address: (json['address'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      dataType: ModbusDataType.fromString(json['data_type'] as String),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offset: (json['offset'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON (用于 API 请求 metadata.modbus)
  Map<String, dynamic> toJson() => {
        'function_code': functionCode.code,
        'address': address,
        'quantity': quantity,
        'data_type': dataType.value,
        'scale': scale,
        'offset': offset,
      };

  /// 复制并修改字段
  ModbusPointConfig copyWith({
    ModbusFunctionCode? functionCode,
    int? address,
    int? quantity,
    ModbusDataType? dataType,
    double? scale,
    double? offset,
  }) {
    return ModbusPointConfig(
      functionCode: functionCode ?? this.functionCode,
      address: address ?? this.address,
      quantity: quantity ?? this.quantity,
      dataType: dataType ?? this.dataType,
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
    );
  }

  /// 获取地址范围 [startAddr, endAddr]
  /// float32 时每个值占2个寄存器
  (int, int) get addressRange {
    final effectiveQuantity =
        dataType == ModbusDataType.float32 ? quantity * 2 : quantity;
    return (address, address + effectiveQuantity - 1);
  }

  /// 检测与另一个配置的地址范围是否重叠
  bool overlapsWith(ModbusPointConfig other) {
    final (start1, end1) = addressRange;
    final (start2, end2) = other.addressRange;
    // 区间重叠: max(start1, start2) ≤ min(end1, end2)
    return start1 <= end2 && start2 <= end1;
  }

  /// 计算覆盖的寄存器数量
  int get registerCount =>
      dataType == ModbusDataType.float32 ? quantity * 2 : quantity;

  @override
  String toString() =>
      'ModbusPointConfig(fc=${functionCode.code}, addr=$address, '
      'qty=$quantity, type=${dataType.value}, scale=$scale, offset=$offset)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModbusPointConfig &&
          functionCode == other.functionCode &&
          address == other.address &&
          quantity == other.quantity &&
          dataType == other.dataType &&
          scale == other.scale &&
          offset == other.offset;

  @override
  int get hashCode =>
      Object.hash(functionCode, address, quantity, dataType, scale, offset);
}

/// 测点配置表单状态
class PointConfigFormState {
  /// 功能码
  final ModbusFunctionCode functionCode;

  /// 地址文本 (用于 TextEditingController)
  final String address;

  /// 数量文本
  final String quantity;

  /// 数据类型
  final ModbusDataType dataType;

  /// 缩放因子文本
  final String scale;

  /// 偏移量文本
  final String offset;

  /// 地址验证错误
  final String? addressError;

  /// 数量验证错误
  final String? quantityError;

  /// 缩放验证错误
  final String? scaleError;

  /// 偏移验证错误
  final String? offsetError;

  const PointConfigFormState({
    this.functionCode = ModbusFunctionCode.fc03,
    this.address = '',
    this.quantity = '',
    this.dataType = ModbusDataType.uint16,
    this.scale = '1.0',
    this.offset = '0.0',
    this.addressError,
    this.quantityError,
    this.scaleError,
    this.offsetError,
  });

  /// 带默认值的初始状态
  factory PointConfigFormState.initial() => const PointConfigFormState(
        
      );

  /// 从 ModbusPointConfig 预填充
  factory PointConfigFormState.fromConfig(ModbusPointConfig config) {
    return PointConfigFormState(
      functionCode: config.functionCode,
      address: config.address.toString(),
      quantity: config.quantity.toString(),
      dataType: config.dataType,
      scale: config.scale.toString(),
      offset: config.offset.toString(),
    );
  }

  PointConfigFormState copyWith({
    ModbusFunctionCode? functionCode,
    String? address,
    String? quantity,
    ModbusDataType? dataType,
    String? scale,
    String? offset,
    String? addressError,
    String? quantityError,
    String? scaleError,
    String? offsetError,
    bool clearAddressError = false,
    bool clearQuantityError = false,
    bool clearScaleError = false,
    bool clearOffsetError = false,
  }) {
    return PointConfigFormState(
      functionCode: functionCode ?? this.functionCode,
      address: address ?? this.address,
      quantity: quantity ?? this.quantity,
      dataType: dataType ?? this.dataType,
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
      addressError:
          clearAddressError ? null : (addressError ?? this.addressError),
      quantityError:
          clearQuantityError ? null : (quantityError ?? this.quantityError),
      scaleError: clearScaleError ? null : (scaleError ?? this.scaleError),
      offsetError: clearOffsetError ? null : (offsetError ?? this.offsetError),
    );
  }

  /// 是否全部验证通过
  bool get isValid =>
      addressError == null &&
      quantityError == null &&
      scaleError == null &&
      offsetError == null;

  /// 尝试创建 ModbusPointConfig
  ModbusPointConfig? tryCreateConfig() {
    final addr = int.tryParse(address);
    final qty = int.tryParse(quantity);
    final scl = double.tryParse(scale);
    final off = double.tryParse(offset);

    if (addr == null || qty == null || scl == null || off == null) return null;

    return ModbusPointConfig(
      functionCode: functionCode,
      address: addr,
      quantity: qty,
      dataType: dataType,
      scale: scl,
      offset: off,
    );
  }
}
