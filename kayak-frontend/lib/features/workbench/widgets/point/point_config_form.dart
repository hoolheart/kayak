/// Modbus 测点配置表单组件
///
/// 提供功能码选择、地址/数量输入、数据类型选择、
/// 缩放因子/偏移量输入等完整的测点配置表单。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/modbus_point_config.dart';
import '../../providers/point_config_provider.dart';

/// 测点配置表单组件
class PointConfigForm extends ConsumerWidget {
  const PointConfigForm({
    super.key,
    this.isEditMode = false,
  });

  /// 是否为编辑模式
  final bool isEditMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(pointConfigFormProvider);
    final formNotifier = ref.read(pointConfigFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 功能码选择
        _buildFunctionCodeSelector(context, formState, formNotifier),
        const SizedBox(height: 16),

        // 地址和数量 (同一行)
        _buildAddressQuantityRow(context, formState, formNotifier),
        const SizedBox(height: 16),

        // 数据类型选择
        _buildDataTypeSelector(context, formState, formNotifier),
        const SizedBox(height: 16),

        // 缩放因子和偏移量 (同一行)
        _buildScaleOffsetRow(context, formState, formNotifier),

        // float32 提示
        if (formState.dataType == ModbusDataType.float32)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '每个 float32 占用 2 个寄存器',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  /// 功能码选择下拉框
  Widget _buildFunctionCodeSelector(
    BuildContext context,
    PointConfigFormState formState,
    PointConfigFormNotifier notifier,
  ) {
    return DropdownButtonFormField<ModbusFunctionCode>(
      initialValue: formState.functionCode,
      decoration: const InputDecoration(
        labelText: '功能码',
        border: OutlineInputBorder(),
      ),
      items: ModbusFunctionCode.values.map((fc) {
        return DropdownMenuItem(
          value: fc,
          child: Text(fc.displayText),
        );
      }).toList(),
      onChanged: (fc) {
        if (fc != null) {
          notifier.updateFunctionCode(fc);
        }
      },
    );
  }

  /// 地址 + 数量输入行
  Widget _buildAddressQuantityRow(
    BuildContext context,
    PointConfigFormState formState,
    PointConfigFormNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 地址
        Expanded(
          child: TextFormField(
            initialValue: formState.address,
            decoration: InputDecoration(
              labelText: '起始地址',
              hintText: '0-65535',
              border: const OutlineInputBorder(),
              errorText: formState.addressError,
            ),
            keyboardType: TextInputType.number,
            onChanged: notifier.updateAddress,
          ),
        ),
        const SizedBox(width: 16),
        // 数量
        Expanded(
          child: TextFormField(
            initialValue: formState.quantity,
            decoration: InputDecoration(
              labelText: '数量',
              hintText: formState.dataType == ModbusDataType.float32
                  ? '1-62'
                  : '1-125',
              border: const OutlineInputBorder(),
              errorText: formState.quantityError,
            ),
            keyboardType: TextInputType.number,
            onChanged: notifier.updateQuantity,
          ),
        ),
      ],
    );
  }

  /// 数据类型选择
  Widget _buildDataTypeSelector(
    BuildContext context,
    PointConfigFormState formState,
    PointConfigFormNotifier notifier,
  ) {
    final isLocked = formState.functionCode.isBoolLocked;

    // FC01/FC02 时自动显示 BOOL 类型
    if (isLocked) {
      return DropdownButtonFormField<ModbusDataType>(
        initialValue: ModbusDataType.bool_,
        decoration: const InputDecoration(
          labelText: '数据类型',
          border: OutlineInputBorder(),
          helperText: 'FC01/FC02 仅支持 BOOL 类型',
        ),
        items: const [
          DropdownMenuItem(
            value: ModbusDataType.bool_,
            child: Text('bool (BOOL)'),
          ),
        ],
        onChanged: null, // 禁用
      );
    }

    // FC03/FC04 时可选择 uint16/int16/float32
    final items = [
      ModbusDataType.uint16,
      ModbusDataType.int16,
      ModbusDataType.float32,
    ];

    return DropdownButtonFormField<ModbusDataType>(
      initialValue: formState.dataType == ModbusDataType.bool_
          ? ModbusDataType.uint16
          : formState.dataType,
      decoration: const InputDecoration(
        labelText: '数据类型',
        border: OutlineInputBorder(),
      ),
      items: items.map((dt) {
        String label;
        switch (dt) {
          case ModbusDataType.uint16:
            label = 'uint16 (无符号16位整数)';
            break;
          case ModbusDataType.int16:
            label = 'int16 (有符号16位整数)';
            break;
          case ModbusDataType.float32:
            label = 'float32 (32位浮点数)';
            break;
          case ModbusDataType.bool_:
            label = 'bool';
        }
        return DropdownMenuItem(
          value: dt,
          child: Text(label),
        );
      }).toList(),
      onChanged: (dt) {
        if (dt != null) {
          notifier.updateDataType(dt);
        }
      },
    );
  }

  /// 缩放因子 + 偏移量输入行
  Widget _buildScaleOffsetRow(
    BuildContext context,
    PointConfigFormState formState,
    PointConfigFormNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 缩放因子
        Expanded(
          child: TextFormField(
            initialValue: formState.scale,
            decoration: InputDecoration(
              labelText: '缩放因子',
              hintText: '1.0',
              border: const OutlineInputBorder(),
              errorText: formState.scaleError,
              helperText: '原始值 × 缩放',
              helperMaxLines: 1,
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: notifier.updateScale,
          ),
        ),
        const SizedBox(width: 16),
        // 偏移量
        Expanded(
          child: TextFormField(
            initialValue: formState.offset,
            decoration: InputDecoration(
              labelText: '偏移量',
              hintText: '0.0',
              border: const OutlineInputBorder(),
              errorText: formState.offsetError,
              helperText: '+ 偏移量 = 工程值',
              helperMaxLines: 1,
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: notifier.updateOffset,
          ),
        ),
      ],
    );
  }
}
