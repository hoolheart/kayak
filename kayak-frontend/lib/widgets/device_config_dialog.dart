import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/app_localizations.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import 'toast.dart';

// ============================================================
// DeviceConfigDialog — 设备配置对话框
//
// 用于创建或编辑设备，包含基础信息、协议配置、高级信息三个区域。
// 协议配置区域根据选择的协议类型动态切换。
//
// 用法：
// ```dart
// // 添加设备
// DeviceConfigDialog.show(
//   context: context,
//   ref: ref,
//   workbenchId: 'wb-1',
// );
//
// // 编辑设备
// DeviceConfigDialog.show(
//   context: context,
//   ref: ref,
//   workbenchId: 'wb-1',
//   device: existingNode,
// );
// ```
// ============================================================

/// DeviceConfigDialog — 设备配置对话框
///
/// 支持创建和编辑两种模式。
/// 创建模式下从 [DeviceService.create] 调用，编辑模式下从 [DeviceService.update] 调用。
class DeviceConfigDialog extends ConsumerStatefulWidget {
  const DeviceConfigDialog({
    super.key,
    required this.workbenchId,
    this.device,
    this.parentId,
    this.isMobile = false,
  });

  /// 所属工作台 ID
  final String workbenchId;

  /// 设备树节点（编辑模式时传入）
  final DeviceTreeNode? device;

  /// 父设备 ID（添加子设备时传入）
  final String? parentId;

  /// 是否为移动端布局
  final bool isMobile;

  /// 显示设备配置对话框
  ///
  /// 根据屏幕宽度自动选择样式：
  /// - < 600px：底部 Sheet
  /// - >= 600px：居中 Dialog
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String workbenchId,
    DeviceTreeNode? device,
    String? parentId,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (_) => DeviceConfigDialog(
          workbenchId: workbenchId,
          device: device,
          parentId: parentId,
          isMobile: true,
        ),
      );
    }

    return showDialog(
      context: context,
      builder: (_) => DeviceConfigDialog(
        workbenchId: workbenchId,
        device: device,
        parentId: parentId,
      ),
    );
  }

  @override
  ConsumerState<DeviceConfigDialog> createState() =>
      _DeviceConfigDialogState();
}

class _DeviceConfigDialogState extends ConsumerState<DeviceConfigDialog> {
  final _formKey = GlobalKey<FormState>();

  // 控制器
  late final TextEditingController _nameController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late final TextEditingController _snController;

  // 虚拟设备控制器
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _intervalController;

  // Modbus TCP 控制器
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _tcpSlaveIdController;
  late final TextEditingController _tcpTimeoutController;

  // Modbus RTU 控制器
  late final TextEditingController _serialPortController;
  late final TextEditingController _rtuSlaveIdController;
  late final TextEditingController _rtuTimeoutController;

  // 表单状态
  ProtocolType? _selectedProtocol;
  String? _virtualMode;
  String? _virtualDataType;
  String? _serialPort;
  int? _baudRate;
  int? _dataBits;
  int? _stopBits;
  String? _parity;
  bool _isSaving = false;
  bool _advancedExpanded = false;

  // 协议类型选项
  static const _protocolOptions = [
    ProtocolType.virtual,
    ProtocolType.modbusTcp,
    ProtocolType.modbusRtu,
  ];

  // 虚拟模式选项
  static const _virtualModeOptions = [
    'random',
    'sine_wave',
    'fixed_value',
    'increment',
  ];

  // 虚拟数据类型选项
  static const _virtualDataTypeOptions = [
    'int8',
    'int16',
    'int32',
    'int64',
    'float32',
    'float64',
    'bool',
  ];

  // 波特率选项
  static const _baudRateOptions = [9600, 19200, 38400, 57600, 115200];

  // 数据位选项
  static const _dataBitsOptions = [7, 8];

  // 停止位选项
  static const _stopBitsOptions = [1, 2];

  // 校验位选项
  static const _parityOptions = ['none', 'odd', 'even'];

  // 串口选项（将由后端 API 提供，目前保留为自由输入）

  // 是否为编辑模式
  bool get _isEditMode => widget.device != null;

  @override
  void initState() {
    super.initState();
    final device = widget.device;

    _nameController = TextEditingController(text: device?.name ?? '');
    _manufacturerController =
        TextEditingController(text: device?.manufacturer ?? '');
    _modelController = TextEditingController(text: device?.model ?? '');
    _snController = TextEditingController(text: device?.sn ?? '');

    _minController = TextEditingController();
    _maxController = TextEditingController();
    _intervalController = TextEditingController(text: '1000');

    _hostController = TextEditingController();
    _portController = TextEditingController(text: '502');
    _tcpSlaveIdController = TextEditingController(text: '1');
    _tcpTimeoutController = TextEditingController(text: '5000');

    _serialPortController = TextEditingController(text: device != null ? (device.protocolParams?['serial_port'] as String? ?? '') : '');
    _rtuSlaveIdController = TextEditingController(text: '1');
    _rtuTimeoutController = TextEditingController(text: '5000');

    if (device != null) {
      _selectedProtocol = device.protocolType;
      _loadProtocolParams(device.protocolParams);
    }
  }

  /// 加载协议参数到表单控制器
  void _loadProtocolParams(Map<String, dynamic>? params) {
    if (params == null) return;

    switch (_selectedProtocol) {
      case ProtocolType.virtual:
        _virtualMode = params['mode'] as String?;
        _virtualDataType = params['data_type'] as String?;
        _minController.text = (params['min'] as num?)?.toString() ?? '';
        _maxController.text = (params['max'] as num?)?.toString() ?? '';
        _intervalController.text =
            (params['interval_ms'] as int?)?.toString() ?? '1000';
        break;
      case ProtocolType.modbusTcp:
        _hostController.text = params['host'] as String? ?? '';
        _portController.text = (params['port'] as int?)?.toString() ?? '502';
        _tcpSlaveIdController.text =
            (params['slave_id'] as int?)?.toString() ?? '1';
        _tcpTimeoutController.text =
            (params['timeout_ms'] as int?)?.toString() ?? '5000';
        break;
      case ProtocolType.modbusRtu:
        _serialPort = params['serial_port'] as String?;
        _serialPortController.text = _serialPort ?? '';
        _baudRate = params['baud_rate'] as int?;
        _dataBits = params['data_bits'] as int?;
        _stopBits = params['stop_bits'] as int?;
        _parity = params['parity'] as String?;
        _rtuSlaveIdController.text =
            (params['slave_id'] as int?)?.toString() ?? '1';
        _rtuTimeoutController.text =
            (params['timeout_ms'] as int?)?.toString() ?? '5000';
        break;
      case ProtocolType.can:
      case ProtocolType.visa:
      case ProtocolType.mqtt:
        break;
      case null:
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _snController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _intervalController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _tcpSlaveIdController.dispose();
    _tcpTimeoutController.dispose();
    _serialPortController.dispose();
    _rtuSlaveIdController.dispose();
    _rtuTimeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMobile = widget.isMobile;

    final dialogTitle =
        _isEditMode ? l10n.editDeviceDialogTitle : l10n.addDeviceDialogTitle;

    final dialogContent = Form(
      key: _formKey,
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 头部
            _buildHeader(dialogTitle, colorScheme, textTheme, isMobile),
            // 内容区
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicSection(l10n, colorScheme, textTheme),
                    const SizedBox(height: 24),
                    if (_selectedProtocol != null)
                      _buildProtocolSection(l10n, colorScheme, textTheme),
                    if (_selectedProtocol != null) ...[
                      const SizedBox(height: 24),
                    ],
                    _buildAdvancedSection(l10n, colorScheme, textTheme),
                  ],
                ),
              ),
            ),
            // 按钮区
            _buildActions(l10n, colorScheme, isMobile),
          ],
        ),
      ),
    );

    if (isMobile) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: dialogContent,
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      content: dialogContent,
    );
  }

  /// 对话框头部
  Widget _buildHeader(
    String title,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isMobile,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  /// 基础信息区域
  Widget _buildBasicSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.basicInfo,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        // 设备名称
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.deviceName,
            hintText: l10n.deviceNameHint,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.deviceNameRequired;
            }
            if (value.trim().length > 255) {
              return l10n.deviceNameMaxLength;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 协议类型
        DropdownButtonFormField<ProtocolType>(
          key: ValueKey(_selectedProtocol),
          initialValue: _selectedProtocol,
          decoration: InputDecoration(
            labelText: l10n.protocolType,
            hintText: l10n.protocolTypeHint,
          ),
          items: _protocolOptions.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_protocolTypeLabel(type, l10n)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProtocol = value;
              // 切换时清空协议专用字段
              _clearProtocolFields();
            });
          },
          validator: (value) {
            if (value == null) {
              return l10n.protocolTypeRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 根据协议类型动态构建配置区域
  Widget _buildProtocolSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // 使用 AnimatedSwitcher 实现淡入淡出切换
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Container(
        key: ValueKey(_selectedProtocol),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.protocolConfig,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            switch (_selectedProtocol!) {
              ProtocolType.virtual => _buildVirtualConfig(l10n),
              ProtocolType.modbusTcp => _buildModbusTcpConfig(l10n),
              ProtocolType.modbusRtu => _buildModbusRtuConfig(l10n),
              ProtocolType.can => const SizedBox.shrink(),
              ProtocolType.visa => const SizedBox.shrink(),
              ProtocolType.mqtt => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }

  /// Virtual 协议配置
  Widget _buildVirtualConfig(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 虚拟模式
        DropdownButtonFormField<String>(
          key: ValueKey('virtual_mode_$_virtualMode'),
          initialValue: _virtualMode,
          decoration: InputDecoration(
            labelText: l10n.virtualMode,
            hintText: l10n.virtualModeHint,
          ),
          items: _virtualModeOptions.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Text(_virtualModeLabel(mode, l10n)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _virtualMode = value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.virtualModeRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 数据类型
        DropdownButtonFormField<String>(
          key: ValueKey(_virtualDataType),
          initialValue: _virtualDataType,
          decoration: InputDecoration(
            labelText: l10n.dataType,
            hintText: l10n.dataTypeHint,
          ),
          items: _virtualDataTypeOptions.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _virtualDataType = value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.dataTypeRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 取值范围
        Text(
          l10n.valueRange,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minController,
                decoration: InputDecoration(
                  labelText: l10n.minValue,
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return l10n.validNumberRequired;
                    }
                  }
                  return null;
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~'),
            ),
            Expanded(
              child: TextFormField(
                controller: _maxController,
                decoration: InputDecoration(
                  labelText: l10n.maxValue,
                  hintText: '100',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return l10n.validNumberRequired;
                    }
                    // 检查最小值 < 最大值
                    final minVal = double.tryParse(_minController.text);
                    final maxVal = double.tryParse(value);
                    if (minVal != null && maxVal != null && minVal >= maxVal) {
                      return l10n.maxGreaterThanMin;
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 更新间隔
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _intervalController,
                decoration: InputDecoration(
                  labelText: l10n.updateInterval,
                  hintText: '1000',
                  suffixText: l10n.ms,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final interval = int.tryParse(value);
                    if (interval == null || interval < 100) {
                      return l10n.minIntervalMs;
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Modbus TCP 协议配置
  Widget _buildModbusTcpConfig(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主机地址
        TextFormField(
          controller: _hostController,
          decoration: InputDecoration(
            labelText: l10n.hostAddress,
            hintText: l10n.hostAddressHint,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.hostAddressRequired;
            }
            // 简单 IPv4 格式验证
            final parts = value.trim().split('.');
            if (parts.length != 4) {
              return l10n.hostAddressInvalid;
            }
            for (final part in parts) {
              final num = int.tryParse(part);
              if (num == null || num < 0 || num > 255) {
                return l10n.hostAddressInvalid;
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 端口
        TextFormField(
          controller: _portController,
          decoration: InputDecoration(
            labelText: l10n.port,
            hintText: l10n.portHint,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.portRequired;
            }
            final port = int.tryParse(value);
            if (port == null || port < 1 || port > 65535) {
              return l10n.portInvalid;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 从站 ID
        TextFormField(
          controller: _tcpSlaveIdController,
          decoration: InputDecoration(
            labelText: l10n.slaveId,
            hintText: l10n.slaveIdHint,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final id = int.tryParse(value);
              if (id == null || id < 1 || id > 247) {
                return l10n.slaveIdInvalid;
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 超时
        TextFormField(
          controller: _tcpTimeoutController,
          decoration: InputDecoration(
            labelText: l10n.timeout,
            hintText: l10n.timeoutHint,
            suffixText: l10n.ms,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final timeout = int.tryParse(value);
              if (timeout == null || timeout < 100) {
                return l10n.minTimeoutMs;
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Modbus RTU 协议配置
  Widget _buildModbusRtuConfig(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 串口（自由输入，待后端 API 提供可用串口列表）
        TextFormField(
          controller: _serialPortController,
          decoration: InputDecoration(
            labelText: l10n.serialPort,
            hintText: '/dev/ttyUSB0',
          ),
          onChanged: (value) {
            _serialPort = value;
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.serialPortRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 波特率
        DropdownButtonFormField<int>(
          initialValue: _baudRate,
          decoration: InputDecoration(
            labelText: l10n.baudRate,
            hintText: l10n.baudRateHint,
          ),
          items: _baudRateOptions.map((rate) {
            return DropdownMenuItem(
              value: rate,
              child: Text('$rate'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _baudRate = value);
          },
          validator: (value) {
            if (value == null) {
              return l10n.baudRateRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 数据位
        DropdownButtonFormField<int>(
          initialValue: _dataBits,
          decoration: InputDecoration(
            labelText: l10n.dataBits,
            hintText: '8',
          ),
          items: _dataBitsOptions.map((bits) {
            return DropdownMenuItem(
              value: bits,
              child: Text('$bits'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _dataBits = value);
          },
        ),
        const SizedBox(height: 16),
        // 停止位
        DropdownButtonFormField<int>(
          initialValue: _stopBits,
          decoration: InputDecoration(
            labelText: l10n.stopBits,
            hintText: '1',
          ),
          items: _stopBitsOptions.map((bits) {
            return DropdownMenuItem(
              value: bits,
              child: Text('$bits'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _stopBits = value);
          },
        ),
        const SizedBox(height: 16),
        // 校验位
        DropdownButtonFormField<String>(
          initialValue: _parity,
          decoration: InputDecoration(
            labelText: l10n.parity,
            hintText: l10n.none,
          ),
          items: _parityOptions.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(_parityLabel(p, l10n)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _parity = value);
          },
        ),
        const SizedBox(height: 16),
        // 从站 ID
        TextFormField(
          controller: _rtuSlaveIdController,
          decoration: InputDecoration(
            labelText: l10n.slaveId,
            hintText: l10n.slaveIdHint,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final id = int.tryParse(value);
              if (id == null || id < 1 || id > 247) {
                return l10n.slaveIdInvalid;
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 超时
        TextFormField(
          controller: _rtuTimeoutController,
          decoration: InputDecoration(
            labelText: l10n.timeout,
            hintText: l10n.timeoutHint,
            suffixText: l10n.ms,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final timeout = int.tryParse(value);
              if (timeout == null || timeout < 100) {
                return l10n.minTimeoutMs;
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 高级信息区域
  Widget _buildAdvancedSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          l10n.advancedInfo,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        initiallyExpanded: _advancedExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _advancedExpanded = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // 制造商
                TextFormField(
                  controller: _manufacturerController,
                  decoration: InputDecoration(
                    labelText: l10n.manufacturer,
                    hintText: l10n.manufacturerHint,
                  ),
                  validator: (value) {
                    if (value != null && value.length > 255) {
                      return l10n.max255Chars;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 型号
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: l10n.modelName,
                    hintText: l10n.modelHint,
                  ),
                  validator: (value) {
                    if (value != null && value.length > 255) {
                      return l10n.max255Chars;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 序列号
                TextFormField(
                  controller: _snController,
                  decoration: InputDecoration(
                    labelText: l10n.serialNumber,
                    hintText: l10n.serialNumberHint,
                  ),
                  validator: (value) {
                    if (value != null && value.length > 255) {
                      return l10n.max255Chars;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 底部操作按钮
  Widget _buildActions(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
    );
  }

  /// 保存设备（通过 Provider）
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      final treeNotifier = ref.read(
        deviceTreeProvider(widget.workbenchId).notifier,
      );

      // 将枚举 name (camelCase) 转为 snake_case
      final protocolStr = _protocolTypeToSnakeCase(_selectedProtocol!);

      if (_isEditMode) {
        // 编辑模式
        await treeNotifier.updateDevice(
          widget.device!.id,
          _buildUpdateData(),
        );
      } else {
        // 创建模式
        await treeNotifier.createDevice(
          wbId: widget.workbenchId,
          name: _nameController.text.trim(),
          protocolType: protocolStr,
          protocolParams: _buildProtocolParams(),
          parentId: widget.parentId,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.show(
        context: context,
        message: l10n.deviceSaveSuccess,
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context: context,
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 将 ProtocolType 枚举名称转为 snake_case
  ///
  /// ProtocolType.modbusTcp.name → "modbusTcp" → "modbus_tcp"
  String _protocolTypeToSnakeCase(ProtocolType type) {
    return type.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }

  /// 构建更新数据
  Map<String, dynamic> _buildUpdateData() {
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'protocol_type': _protocolTypeToSnakeCase(_selectedProtocol!),
      'protocol_params': _buildProtocolParams(),
    };

    if (_manufacturerController.text.isNotEmpty) {
      data['manufacturer'] = _manufacturerController.text.trim();
    }
    if (_modelController.text.isNotEmpty) {
      data['model'] = _modelController.text.trim();
    }
    if (_snController.text.isNotEmpty) {
      data['sn'] = _snController.text.trim();
    }

    return data;
  }

  /// 构建协议参数
  Map<String, dynamic>? _buildProtocolParams() {
    switch (_selectedProtocol) {
      case ProtocolType.virtual:
        return {
          'mode': _virtualMode,
          'data_type': _virtualDataType,
          if (_minController.text.isNotEmpty)
            'min': double.tryParse(_minController.text),
          if (_maxController.text.isNotEmpty)
            'max': double.tryParse(_maxController.text),
          if (_intervalController.text.isNotEmpty)
            'interval_ms': int.tryParse(_intervalController.text),
        };
      case ProtocolType.modbusTcp:
        return {
          'host': _hostController.text.trim(),
          'port': int.tryParse(_portController.text) ?? 502,
          if (_tcpSlaveIdController.text.isNotEmpty)
            'slave_id': int.tryParse(_tcpSlaveIdController.text),
          if (_tcpTimeoutController.text.isNotEmpty)
            'timeout_ms': int.tryParse(_tcpTimeoutController.text),
        };
      case ProtocolType.modbusRtu:
        return {
          'serial_port': _serialPortController.text.isNotEmpty
              ? _serialPortController.text.trim()
              : null,
          'baud_rate': _baudRate,
          'data_bits': _dataBits,
          'stop_bits': _stopBits,
          'parity': _parity,
          if (_rtuSlaveIdController.text.isNotEmpty)
            'slave_id': int.tryParse(_rtuSlaveIdController.text),
          if (_rtuTimeoutController.text.isNotEmpty)
            'timeout_ms': int.tryParse(_rtuTimeoutController.text),
        };
      case ProtocolType.can:
      case ProtocolType.visa:
      case ProtocolType.mqtt:
        return null;
      case null:
        return null;
    }
  }

  /// 切换协议时清空专用字段
  void _clearProtocolFields() {
    _virtualMode = null;
    _virtualDataType = null;
    _minController.clear();
    _maxController.clear();
    _intervalController.text = '1000';
    _hostController.clear();
    _portController.text = '502';
    _tcpSlaveIdController.text = '1';
    _tcpTimeoutController.text = '5000';
    _serialPort = null;
    _serialPortController.clear();
    _baudRate = null;
    _dataBits = null;
    _stopBits = null;
    _parity = null;
    _rtuSlaveIdController.text = '1';
    _rtuTimeoutController.text = '5000';
  }

  /// 协议类型标签
  String _protocolTypeLabel(ProtocolType type, AppLocalizations l10n) {
    switch (type) {
      case ProtocolType.virtual:
        return l10n.virtualDevice;
      case ProtocolType.modbusTcp:
        return l10n.modbusTcp;
      case ProtocolType.modbusRtu:
        return l10n.modbusRtu;
      case ProtocolType.can:
        return 'CAN';
      case ProtocolType.visa:
        return 'VISA';
      case ProtocolType.mqtt:
        return 'MQTT';
    }
  }

  /// 虚拟模式标签
  String _virtualModeLabel(String mode, AppLocalizations l10n) {
    switch (mode) {
      case 'random':
        return l10n.random;
      case 'sine_wave':
        return l10n.sineWave;
      case 'fixed_value':
        return l10n.fixedValue;
      case 'increment':
        return l10n.increment;
      default:
        return mode;
    }
  }

  /// 校验位标签
  String _parityLabel(String parity, AppLocalizations l10n) {
    switch (parity) {
      case 'none':
        return l10n.none;
      case 'odd':
        return l10n.oddParity;
      case 'even':
        return l10n.evenParity;
      default:
        return parity;
    }
  }
}


