/// 设备通用字段组件
///
/// 设备名称(必填)、制造商、型号、序列号字段。
/// 协议切换时字段值保持不变。
library;

import 'package:flutter/material.dart';
import '../../validators/device_validators.dart';

/// 通用字段组件
///
/// 封装设备表单的通用字段：设备名称、制造商、型号、序列号
class CommonFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController manufacturerController;
  final TextEditingController modelController;
  final TextEditingController snController;

  const CommonFields({
    super.key,
    required this.nameController,
    required this.manufacturerController,
    required this.modelController,
    required this.snController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '基本信息',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        // 设备名称 (必填)
        TextFormField(
          key: const Key('device-name-field'),
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '设备名称 *',
            hintText: '输入设备名称',
            filled: true,
          ),
          validator: (value) => DeviceValidators.required(value, '设备名称不能为空'),
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        // 制造商
        TextFormField(
          controller: manufacturerController,
          decoration: const InputDecoration(
            labelText: '制造商',
            hintText: '输入制造商（可选）',
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
        // 型号
        TextFormField(
          controller: modelController,
          decoration: const InputDecoration(
            labelText: '型号',
            hintText: '输入型号（可选）',
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
        // 序列号
        TextFormField(
          controller: snController,
          decoration: const InputDecoration(
            labelText: '序列号',
            hintText: '输入序列号（可选）',
            filled: true,
          ),
        ),
      ],
    );
  }
}
