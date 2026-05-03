/// Virtual 协议参数表单
///
/// 包含模式选择、数据类型、访问类型、最小值/最大值、固定值（条件显示）。
/// 状态内部管理，通过 [validate] 和 [getConfig] 向父级暴露。
library;

import 'package:flutter/material.dart';
import '../../models/protocol_config.dart';

/// Virtual 协议参数表单
class VirtualProtocolForm extends StatefulWidget {
  final VirtualConfig? initialConfig;
  final bool isEditMode;

  /// 字段变更回调，用于追踪表单脏状态
  final VoidCallback? onFieldChanged;

  const VirtualProtocolForm({
    super.key,
    this.initialConfig,
    this.isEditMode = false,
    this.onFieldChanged,
  });

  @override
  VirtualProtocolFormState createState() => VirtualProtocolFormState();
}

/// Virtual 协议表单状态
class VirtualProtocolFormState extends State<VirtualProtocolForm> {
  // === 控制器 ===
  late final TextEditingController _minValueController;
  late final TextEditingController _maxValueController;
  late final TextEditingController _fixedValueController;
  late final TextEditingController _sampleIntervalController;

  // === 选择器状态 ===
  VirtualMode _mode = VirtualMode.random;
  VirtualDataType _dataType = VirtualDataType.number;
  AccessType _accessType = AccessType.rw;

  // === 生命周期 ===
  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _mode = widget.initialConfig!.mode;
      _dataType = widget.initialConfig!.dataType;
      _accessType = widget.initialConfig!.accessType;
      _minValueController = TextEditingController(
        text: widget.initialConfig!.minValue.toString(),
      );
      _maxValueController = TextEditingController(
        text: widget.initialConfig!.maxValue.toString(),
      );
      _sampleIntervalController = TextEditingController(
        text: widget.initialConfig!.sampleInterval.toString(),
      );
      _fixedValueController = TextEditingController(
        text: widget.initialConfig!.fixedValue?.toString() ?? '',
      );
    } else {
      _minValueController = TextEditingController(text: '0');
      _maxValueController = TextEditingController(text: '100');
      _sampleIntervalController = TextEditingController(text: '1000');
      _fixedValueController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _minValueController.dispose();
    _maxValueController.dispose();
    _fixedValueController.dispose();
    _sampleIntervalController.dispose();
    super.dispose();
  }

  // === 公共方法 ===

  /// 验证表单字段
  bool validate() {
    // 验证采样间隔
    if (_sampleIntervalController.text.isEmpty ||
        int.tryParse(_sampleIntervalController.text) == null ||
        int.parse(_sampleIntervalController.text) <= 0) {
      return false;
    }

    // 验证最小值 ≤ 最大值
    final min = double.tryParse(_minValueController.text);
    final max = double.tryParse(_maxValueController.text);
    if (min != null && max != null && min > max) {
      return false;
    }

    // Fixed 模式下固定值必填
    if (_mode == VirtualMode.fixed && _fixedValueController.text.isEmpty) {
      return false;
    }

    return true;
  }

  /// 获取当前配置
  VirtualConfig getConfig() {
    return VirtualConfig(
      mode: _mode,
      dataType: _dataType,
      accessType: _accessType,
      minValue: double.tryParse(_minValueController.text) ?? 0,
      maxValue: double.tryParse(_maxValueController.text) ?? 100,
      fixedValue: _mode == VirtualMode.fixed
          ? double.tryParse(_fixedValueController.text)
          : null,
      sampleInterval: int.tryParse(_sampleIntervalController.text) ?? 1000,
    );
  }

  // === 构建 ===
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('virtual-params-section'),
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
          // 数据模式 *
          _buildModeDropdown(theme),
          const SizedBox(height: 16),
          // 数据类型 * | 访问类型 *
          _buildTypeRow(theme),
          const SizedBox(height: 16),
          // 采样间隔
          _buildSampleIntervalField(theme),
          const SizedBox(height: 16),
          // 最小值 * | 最大值 *
          _buildMinMaxRow(theme),
          // 固定值 (仅 Fixed 模式)
          if (_mode == VirtualMode.fixed) ...[
            const SizedBox(height: 16),
            _buildFixedValueField(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleRow(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.developer_board,
          size: 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Virtual 协议参数',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '虚拟设备用于软件测试和开发，无需物理硬件',
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

  Widget _buildModeDropdown(ThemeData theme) {
    return DropdownButtonFormField<VirtualMode>(
      initialValue: _mode,
      decoration: const InputDecoration(
        labelText: '数据模式 *',
        filled: true,
      ),
      items: VirtualMode.values.map((mode) {
        return DropdownMenuItem(
          value: mode,
          child: Text(mode.label),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _mode = value);
          widget.onFieldChanged?.call();
        }
      },
    );
  }

  Widget _buildTypeRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<VirtualDataType>(
            initialValue: _dataType,
            decoration: const InputDecoration(
              labelText: '数据类型 *',
              filled: true,
            ),
            items: VirtualDataType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _dataType = value);
                widget.onFieldChanged?.call();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<AccessType>(
            initialValue: _accessType,
            decoration: const InputDecoration(
              labelText: '访问类型 *',
              filled: true,
            ),
            items: AccessType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _accessType = value);
                widget.onFieldChanged?.call();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSampleIntervalField(ThemeData theme) {
    return TextFormField(
      key: const Key('virtual-sample-interval'),
      controller: _sampleIntervalController,
      decoration: const InputDecoration(
        labelText: '采样间隔 (ms)',
        hintText: '1000',
        filled: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => widget.onFieldChanged?.call(),
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入采样间隔';
        final interval = int.tryParse(value);
        if (interval == null || interval <= 0) return '请输入正整数';
        return null;
      },
    );
  }

  Widget _buildMinMaxRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: const Key('virtual-min-value-field'),
            controller: _minValueController,
            decoration: const InputDecoration(
              labelText: '最小值 *',
              hintText: '0.0',
              filled: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => widget.onFieldChanged?.call(),
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入最小值';
              if (double.tryParse(value) == null) return '请输入有效数字';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            key: const Key('virtual-max-value-field'),
            controller: _maxValueController,
            decoration: const InputDecoration(
              labelText: '最大值 *',
              hintText: '100.0',
              filled: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => widget.onFieldChanged?.call(),
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入最大值';
              if (double.tryParse(value) == null) return '请输入有效数字';
              // 跨字段验证
              final min = double.tryParse(_minValueController.text);
              final max = double.tryParse(value);
              if (min != null && max != null && min > max) {
                return '最小值不能大于最大值';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFixedValueField(ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: TextFormField(
        controller: _fixedValueController,
        decoration: const InputDecoration(
          labelText: '固定值 *',
          hintText: '50.0',
          filled: true,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => widget.onFieldChanged?.call(),
        validator: (value) {
          if (value == null || value.isEmpty) return '请输入固定值';
          if (double.tryParse(value) == null) return '请输入有效数字';
          return null;
        },
      ),
    );
  }
}
