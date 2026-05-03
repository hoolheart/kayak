/// Modbus RTU 协议参数表单
///
/// 包含串口选择（支持扫描）、波特率、数据位、停止位、校验、从站ID、超时。
/// 支持连接测试功能。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/protocol_config.dart';
import '../../validators/device_validators.dart';
import '../../services/protocol_service.dart';
import 'connection_test_widget.dart';

/// 串口扫描状态
enum ScanState { idle, scanning, completed, noDevices, failed }

/// Modbus RTU 协议参数表单
class ModbusRtuForm extends ConsumerStatefulWidget {
  final RtuConfig? initialConfig;
  final bool isEditMode;
  final String? deviceId;

  /// 字段变更回调，用于追踪表单脏状态
  final VoidCallback? onFieldChanged;

  const ModbusRtuForm({
    super.key,
    this.initialConfig,
    this.isEditMode = false,
    this.deviceId,
    this.onFieldChanged,
  });

  @override
  ConsumerState<ModbusRtuForm> createState() => ModbusRtuFormState();
}

/// Modbus RTU 协议表单状态
class ModbusRtuFormState extends ConsumerState<ModbusRtuForm> {
  // === 控制器 ===
  late final TextEditingController _slaveIdController;
  late final TextEditingController _timeoutController;

  // === 选择器状态 ===
  String? _selectedPort;
  int _baudRate = 9600;
  int _dataBits = 8;
  int _stopBits = 1;
  String _parity = 'None';

  // === 异步状态 ===
  List<SerialPort> _availablePorts = [];
  ScanState _scanState = ScanState.idle;
  ConnectionTestState _testState = ConnectionTestState.idle;
  String? _testMessage;
  int? _testLatencyMs;

  // === 串口选项常量 ===
  static const List<int> baudRateOptions = [9600, 19200, 38400, 57600, 115200];
  static const List<int> dataBitsOptions = [7, 8];
  static const List<int> stopBitsOptions = [1, 2];
  static const List<String> parityOptions = ['None', 'Even', 'Odd'];

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _selectedPort = widget.initialConfig!.port;
      _baudRate = widget.initialConfig!.baudRate;
      _dataBits = widget.initialConfig!.dataBits;
      _stopBits = widget.initialConfig!.stopBits;
      _parity = widget.initialConfig!.parity;
      _slaveIdController = TextEditingController(
        text: widget.initialConfig!.slaveId.toString(),
      );
      _timeoutController = TextEditingController(
        text: widget.initialConfig!.timeoutMs.toString(),
      );
    } else {
      _slaveIdController = TextEditingController(text: '1');
      _timeoutController = TextEditingController(text: '1000');
      // 创建模式自动触发串口扫描
      WidgetsBinding.instance.addPostFrameCallback((_) => _scanPorts());
    }
  }

  @override
  void dispose() {
    _slaveIdController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  // === 公共方法 ===

  /// 验证表单字段
  bool validate() {
    // 串口验证
    if (_selectedPort == null || _selectedPort!.isEmpty) return false;
    // 从站ID验证
    if (DeviceValidators.slaveId(_slaveIdController.text) != null) return false;
    // 串口参数组合验证 (Modbus RTU 不支持 7N1)
    if (_dataBits == 7 && _parity == 'None') return false;
    return true;
  }

  /// 获取当前配置
  RtuConfig getConfig() {
    return RtuConfig(
      port: _selectedPort ?? '',
      baudRate: _baudRate,
      dataBits: _dataBits,
      stopBits: _stopBits,
      parity: _parity,
      slaveId: int.tryParse(_slaveIdController.text) ?? 1,
      timeoutMs: int.tryParse(_timeoutController.text) ?? 1000,
    );
  }

  // === 串口扫描 ===
  Future<void> _scanPorts() async {
    setState(() => _scanState = ScanState.scanning);

    try {
      final service = ref.read(protocolServiceProvider);
      final ports = await service.getSerialPorts();

      if (!mounted) return;

      setState(() {
        _availablePorts = ports;
        _scanState = ports.isEmpty ? ScanState.noDevices : ScanState.completed;
        // 自动选中第一个可用串口
        if (ports.isNotEmpty && _selectedPort == null) {
          _selectedPort = ports.first.path;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanState = ScanState.failed);
    }
  }

  // === 连接测试 ===
  Future<void> _testConnection() async {
    setState(() {
      _testState = ConnectionTestState.testing;
      _testMessage = null;
      _testLatencyMs = null;
    });

    try {
      final service = ref.read(protocolServiceProvider);
      final result = await service.testConnection(
        widget.deviceId ?? 'new',
        getConfig().toJson(),
      );

      if (!mounted) return;

      setState(() {
        _testState = result.success
            ? ConnectionTestState.success
            : ConnectionTestState.failed;
        _testMessage = result.message;
        _testLatencyMs = result.latencyMs;
      });

      // 5s 后自动重置成功状态
      if (result.success) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _testState = ConnectionTestState.idle);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testState = ConnectionTestState.failed;
        _testMessage = e.toString();
      });
    }
  }

  // === 构建 ===
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('modbus-rtu-params-section'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          _buildTitleRow(theme),
          const SizedBox(height: 16),
          // 串口 * | 扫描串口按钮
          _buildSerialPortRow(theme),
          const SizedBox(height: 16),
          // 波特率 | 数据位 | 停止位 | 校验
          _buildSerialParamRow(theme),
          const SizedBox(height: 16),
          // 从站ID | 超时
          Row(
            children: [
              Expanded(child: _buildSlaveIdField(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeoutField(theme)),
            ],
          ),
          const SizedBox(height: 16),
          // 连接测试按钮
          ConnectionTestWidget(
            state: _testState,
            message: _testMessage,
            latencyMs: _testLatencyMs,
            onTest: _testConnection,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.usb,
          size: 24,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modbus RTU 协议参数',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '通过串口 (RS485/RS232) 与 Modbus 从站设备通信',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSerialPortRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 串口下拉框
        Expanded(
          child: DropdownButtonFormField<String>(
            key: const Key('rtu-port-dropdown'),
            initialValue: _selectedPort,
            decoration: InputDecoration(
              labelText: '串口 *',
              hintText: _scanState == ScanState.scanning
                  ? '扫描中...'
                  : _availablePorts.isEmpty && _scanState != ScanState.idle
                      ? '无可用串口'
                      : '选择串口...',
              filled: true,
              errorText: _scanState == ScanState.noDevices
                  ? '未检测到串口设备'
                  : _scanState == ScanState.failed
                      ? '串口扫描失败'
                      : null,
            ),
            items: _availablePorts.map((port) {
              return DropdownMenuItem<String>(
                value: port.path,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(port.path),
                    if (port.description.isNotEmpty)
                      Text(
                        port.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPort = value);
                widget.onFieldChanged?.call();
              }
            },
            validator: DeviceValidators.serialPort,
          ),
        ),
        const SizedBox(width: 8),
        // 扫描按钮
        _buildScanButton(theme),
      ],
    );
  }

  Widget _buildScanButton(ThemeData theme) {
    final isScanning = _scanState == ScanState.scanning;
    final isCompleted = _scanState == ScanState.completed;
    final isFailed = _scanState == ScanState.failed;

    return SizedBox(
      height: 56,
      child: TextButton.icon(
        key: const Key('rtu-scan-button'),
        onPressed: isScanning ? null : _scanPorts,
        icon: isScanning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isCompleted
                    ? Icons.check_circle
                    : isFailed
                        ? Icons.error
                        : Icons.radar,
                size: 20,
              ),
        label: Text(
          isScanning
              ? '扫描中...'
              : isCompleted
                  ? '扫描完成'
                  : isFailed
                      ? '扫描失败'
                      : '扫描串口',
        ),
      ),
    );
  }

  Widget _buildSerialParamRow(ThemeData theme) {
    return Row(
      children: [
        // 波特率
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _baudRate,
            decoration: const InputDecoration(
              labelText: '波特率',
              filled: true,
            ),
            items: baudRateOptions.map((rate) {
              return DropdownMenuItem<int>(
                value: rate,
                child: Text(rate.toString()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _baudRate = value);
                widget.onFieldChanged?.call();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        // 数据位
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _dataBits,
            decoration: const InputDecoration(
              labelText: '数据位',
              filled: true,
            ),
            items: dataBitsOptions.map((bits) {
              return DropdownMenuItem<int>(
                value: bits,
                child: Text(bits.toString()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _dataBits = value);
                widget.onFieldChanged?.call();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        // 停止位
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _stopBits,
            decoration: const InputDecoration(
              labelText: '停止位',
              filled: true,
            ),
            items: stopBitsOptions.map((bits) {
              return DropdownMenuItem<int>(
                value: bits,
                child: Text(bits.toString()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _stopBits = value);
                widget.onFieldChanged?.call();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        // 校验
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _parity,
            decoration: const InputDecoration(
              labelText: '校验',
              filled: true,
            ),
            items: parityOptions.map((parity) {
              return DropdownMenuItem<String>(
                value: parity,
                child: Text(parity),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _parity = value);
                widget.onFieldChanged?.call();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlaveIdField(ThemeData theme) {
    return TextFormField(
      controller: _slaveIdController,
      decoration: const InputDecoration(
        labelText: '从站ID *',
        hintText: '1',
        filled: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => widget.onFieldChanged?.call(),
      validator: DeviceValidators.slaveId,
    );
  }

  Widget _buildTimeoutField(ThemeData theme) {
    return TextFormField(
      controller: _timeoutController,
      decoration: const InputDecoration(
        labelText: '超时 (ms)',
        hintText: '1000',
        suffixText: 'ms',
        filled: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => widget.onFieldChanged?.call(),
      validator: DeviceValidators.timeout,
    );
  }
}
