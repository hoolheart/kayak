/// 设备表单验证器集合
///
/// 所有验证器返回 null 表示通过，返回 String 表示错误消息。
library;

/// 设备表单验证器 - 工具类，禁止实例化
class DeviceValidators {
  DeviceValidators._();

  // === IPv4 正则 ===
  static final RegExp _ipv4Pattern = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );

  // === 通用验证 ===

  /// 必填字段验证
  static String? required(String? value, [String message = '此字段不能为空']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  // === IP 地址验证 ===

  /// IPv4 地址格式验证 (允许 localhost)
  static String? ipAddress(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入主机地址';
    if (value == 'localhost') return null;
    if (!_ipv4Pattern.hasMatch(value.trim())) return 'IP地址格式无效';
    return null;
  }

  // === 端口验证 ===

  /// 端口范围验证 (默认 1-65535)
  static String? port(String? value, {int min = 1, int max = 65535}) {
    if (value == null || value.trim().isEmpty) return '请输入端口号';
    final port = int.tryParse(value);
    if (port == null) return '请输入有效端口号';
    if (port < min || port > max) return '端口范围 $min-$max';
    return null;
  }

  // === 从站ID验证 ===

  /// 从站ID范围验证 (默认 1-247)
  static String? slaveId(String? value, {int min = 1, int max = 247}) {
    if (value == null || value.trim().isEmpty) return '请输入从站ID';
    final id = int.tryParse(value);
    if (id == null) return '请输入有效数字';
    if (id < min || id > max) return '从站ID范围 $min-$max';
    return null;
  }

  // === 超时验证 ===

  /// 超时时间验证 (默认 100-60000ms)
  static String? timeout(String? value, {int min = 100, int max = 60000}) {
    if (value == null || value.trim().isEmpty) return '请输入超时时间';
    final timeout = int.tryParse(value);
    if (timeout == null) return '请输入有效数字';
    if (timeout < min || timeout > max) return '超时范围 $min-${max}ms';
    return null;
  }

  // === 连接池验证 ===

  /// 连接池大小验证 (默认 1-32)
  static String? poolSize(String? value, {int min = 1, int max = 32}) {
    if (value == null || value.trim().isEmpty) return '请输入连接池大小';
    final size = int.tryParse(value);
    if (size == null) return '请输入有效数字';
    if (size < min || size > max) return '连接池大小 $min-$max';
    return null;
  }

  // === Virtual 协议验证 ===

  /// 最小值 ≤ 最大值验证
  static String? minMax(String? minValue, String? maxValue) {
    final min = double.tryParse(minValue ?? '');
    final max = double.tryParse(maxValue ?? '');
    if (min != null && max != null && min > max) {
      return '最小值不能大于最大值';
    }
    return null;
  }

  /// 固定值必填 (Fixed 模式)
  static String? fixedValue(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入固定值';
    return null;
  }

  // === 串口验证 ===

  /// 串口选择验证
  static String? serialPort(String? value) {
    if (value == null || value.trim().isEmpty) return '请选择串口';
    return null;
  }

  /// 串口参数组合验证 (Modbus RTU 不支持 7N1)
  static String? serialParams(int dataBits, String parity) {
    if (dataBits == 7 && parity == 'None') {
      return '数据位7时校验位不能为None（请选择Even或Odd）';
    }
    return null;
  }
}
