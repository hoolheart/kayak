/// 协议选择器组件
///
/// 下拉选择框，选项包含 Virtual / Modbus TCP / Modbus RTU。
/// 编辑模式下禁用。每个选项带有图标和描述。
library;

import 'package:flutter/material.dart';
import '../../models/device.dart';

/// 协议选择器组件
class ProtocolSelector extends StatelessWidget {
  final ProtocolType value;
  final bool enabled;
  final ValueChanged<ProtocolType> onChanged;

  const ProtocolSelector({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  /// 支持的协议选项列表
  /// 目前支持三个协议: Virtual, Modbus TCP, Modbus RTU
  static const List<_ProtocolOption> _options = [
    _ProtocolOption(
      type: ProtocolType.virtual,
      icon: Icons.developer_board,
      label: 'Virtual',
      description: '虚拟设备，用于测试和模拟',
    ),
    _ProtocolOption(
      type: ProtocolType.modbusTcp,
      icon: Icons.lan,
      label: 'Modbus TCP',
      description: 'TCP/IP 网络通信协议',
    ),
    _ProtocolOption(
      type: ProtocolType.modbusRtu,
      icon: Icons.usb,
      label: 'Modbus RTU',
      description: '串口通信协议 (RS485/RS232)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<ProtocolType>(
      key: const Key('protocol-type-dropdown'),
      initialValue: value,
      isDense: true,
      decoration: const InputDecoration(
        labelText: '协议类型 *',
        filled: true,
      ),
      items: _options.map((opt) {
        return DropdownMenuItem<ProtocolType>(
          value: opt.type,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                opt.icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    opt.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    opt.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return _options.map((opt) {
          return DropdownMenuItem<ProtocolType>(
            value: opt.type,
            child: Text(
              opt.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          );
        }).toList();
      },
      onChanged: enabled
          ? (value) {
              if (value != null) onChanged(value);
            }
          : null,
      // 编辑模式下 onChanged 为 null，自动禁用下拉框
    );
  }
}

/// 协议选项内部数据类
class _ProtocolOption {
  final ProtocolType type;
  final IconData icon;
  final String label;
  final String description;

  const _ProtocolOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
  });
}
