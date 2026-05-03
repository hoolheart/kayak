/// Modbus TCP 协议参数表单
///
/// 包含主机地址 (IP)、端口、从站ID、超时时间、连接池大小。
/// 支持连接测试功能。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/protocol_config.dart';
import '../../validators/device_validators.dart';
import '../../services/protocol_service.dart';
import 'connection_test_widget.dart';

/// Modbus TCP 协议参数表单
class ModbusTcpForm extends ConsumerStatefulWidget {
  final TcpConfig? initialConfig;
  final bool isEditMode;
  final String? deviceId;

  /// 字段变更回调，用于追踪表单脏状态
  final VoidCallback? onFieldChanged;

  const ModbusTcpForm({
    super.key,
    this.initialConfig,
    this.isEditMode = false,
    this.deviceId,
    this.onFieldChanged,
  });

  @override
  ConsumerState<ModbusTcpForm> createState() => ModbusTcpFormState();
}

/// Modbus TCP 协议表单状态
class ModbusTcpFormState extends ConsumerState<ModbusTcpForm> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _slaveIdController;
  late final TextEditingController _timeoutController;
  late final TextEditingController _poolSizeController;

  ConnectionTestState _testState = ConnectionTestState.idle;
  String? _testMessage;
  int? _testLatencyMs;

  @override
  void initState() {
    super.initState();
    final c = widget.initialConfig ?? TcpConfig.defaults();
    _hostController = TextEditingController(text: c.host);
    _portController = TextEditingController(text: c.port.toString());
    _slaveIdController = TextEditingController(text: c.slaveId.toString());
    _timeoutController = TextEditingController(text: c.timeoutMs.toString());
    _poolSizeController =
        TextEditingController(text: c.connectionPoolSize.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _slaveIdController.dispose();
    _timeoutController.dispose();
    _poolSizeController.dispose();
    super.dispose();
  }

  // === 公共方法 ===

  /// 验证表单字段
  bool validate() {
    // 主机地址验证
    if (DeviceValidators.ipAddress(_hostController.text) != null) return false;
    // 端口验证
    if (DeviceValidators.port(_portController.text) != null) return false;
    // 从站ID验证
    if (DeviceValidators.slaveId(_slaveIdController.text) != null) return false;
    // 超时验证
    if (DeviceValidators.timeout(_timeoutController.text) != null) return false;
    // 连接池验证
    if (DeviceValidators.poolSize(_poolSizeController.text) != null) {
      return false;
    }
    return true;
  }

  /// 获取当前配置
  TcpConfig getConfig() {
    return TcpConfig(
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 502,
      slaveId: int.tryParse(_slaveIdController.text) ?? 1,
      timeoutMs: int.tryParse(_timeoutController.text) ?? 5000,
      connectionPoolSize: int.tryParse(_poolSizeController.text) ?? 4,
    );
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
      key: const Key('modbus-tcp-params-section'),
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
          // 主机地址 * (60%) | 端口 * (40%)
          Row(
            children: [
              Expanded(flex: 3, child: _buildHostField(theme)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildPortField(theme)),
            ],
          ),
          const SizedBox(height: 16),
          // 从站ID * (33%) | 超时 (33%) | 连接池大小 (33%)
          Row(
            children: [
              Expanded(child: _buildSlaveIdField(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeoutField(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildPoolSizeField(theme)),
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
          Icons.lan,
          size: 24,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modbus TCP 协议参数',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '通过 TCP/IP 网络与 Modbus 从站设备通信',
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

  Widget _buildHostField(ThemeData theme) {
    return TextFormField(
      key: const Key('tcp-host-field'),
      controller: _hostController,
      decoration: const InputDecoration(
        labelText: '主机地址 *',
        hintText: '192.168.1.100',
        filled: true,
      ),
      keyboardType: TextInputType.url,
      onChanged: (_) => widget.onFieldChanged?.call(),
      validator: DeviceValidators.ipAddress,
    );
  }

  Widget _buildPortField(ThemeData theme) {
    return TextFormField(
      key: const Key('tcp-port-field'),
      controller: _portController,
      decoration: const InputDecoration(
        labelText: '端口 *',
        hintText: '502',
        filled: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => widget.onFieldChanged?.call(),
      validator: DeviceValidators.port,
    );
  }

  Widget _buildSlaveIdField(ThemeData theme) {
    return TextFormField(
      key: const Key('tcp-slave-id-field'),
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
        hintText: '5000',
        suffixText: 'ms',
        filled: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => widget.onFieldChanged?.call(),
      validator: DeviceValidators.timeout,
    );
  }

  Widget _buildPoolSizeField(ThemeData theme) {
    return TextFormField(
      key: const Key('tcp-pool-size-field'),
      controller: _poolSizeController,
      decoration: const InputDecoration(
        labelText: '连接池大小',
        hintText: '4',
        filled: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => widget.onFieldChanged?.call(),
      validator: DeviceValidators.poolSize,
    );
  }
}
