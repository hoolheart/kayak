/// 设备表单对话框
///
/// 用于创建和编辑设备
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';

/// 设备表单对话框
class DeviceFormDialog extends ConsumerStatefulWidget {
  final Device? device; // null for create, non-null for edit
  final String workbenchId; // required for create

  const DeviceFormDialog({
    super.key,
    this.device,
    required this.workbenchId,
  });

  @override
  ConsumerState<DeviceFormDialog> createState() => _DeviceFormDialogState();
}

class _DeviceFormDialogState extends ConsumerState<DeviceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late final TextEditingController _snController;
  late final TextEditingController _sampleIntervalController;
  late final TextEditingController _minValueController;
  late final TextEditingController _maxValueController;

  ProtocolType _protocolType = ProtocolType.virtual;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device?.name);
    _manufacturerController =
        TextEditingController(text: widget.device?.manufacturer);
    _modelController = TextEditingController(text: widget.device?.model);
    _snController = TextEditingController(text: widget.device?.sn);

    // Default values for Virtual protocol params
    _sampleIntervalController = TextEditingController(text: '1000');
    _minValueController = TextEditingController(text: '0');
    _maxValueController = TextEditingController(text: '100');

    // Set protocol type from device if editing
    if (widget.device != null) {
      _protocolType = widget.device!.protocolType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _snController.dispose();
    _sampleIntervalController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.device != null;

    return AlertDialog(
      key: Key(isEdit
          ? 'edit-device-dialog-${widget.device?.id}'
          : 'create-device-dialog'),
      title: Text(isEdit ? '编辑设备' : '添加设备'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 设备名称
                TextFormField(
                  key: const Key('device-name-field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '设备名称 *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '设备名称不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 协议类型 - 仅支持Virtual
                DropdownButtonFormField<ProtocolType>(
                  key: const Key('protocol-type-dropdown'),
                  initialValue: _protocolType,
                  decoration: const InputDecoration(
                    labelText: '协议类型 *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: ProtocolType.virtual,
                      child: Text('VIRTUAL'),
                    ),
                    // 其他协议类型禁用
                    ...ProtocolType.values
                        .where((p) => p != ProtocolType.virtual)
                        .map((p) => DropdownMenuItem(
                              value: p,
                              enabled: false,
                              child: Text(p.name.toUpperCase()),
                            )),
                  ],
                  onChanged: isEdit
                      ? null // 编辑模式下协议类型不可修改
                      : (value) {
                          if (value != null) {
                            setState(() => _protocolType = value);
                          }
                        },
                ),
                const SizedBox(height: 16),

                // Virtual协议参数
                if (_protocolType == ProtocolType.virtual) ...[
                  Text(
                    'Virtual协议参数',
                    key: const Key('virtual-params-section'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('virtual-sample-interval'),
                    controller: _sampleIntervalController,
                    decoration: const InputDecoration(
                      labelText: '采样间隔 (ms)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入采样间隔';
                      }
                      final interval = int.tryParse(value);
                      if (interval == null || interval <= 0) {
                        return '请输入正整数';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minValueController,
                          decoration: const InputDecoration(
                            labelText: '最小值',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _maxValueController,
                          decoration: const InputDecoration(
                            labelText: '最大值',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // 可选字段
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: '制造商',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: '型号',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _snController,
                  decoration: const InputDecoration(
                    labelText: '序列号',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel-device-button'),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('submit-device-button'),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确定'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final deviceService = ref.read(deviceServiceProvider);

      if (widget.device != null) {
        // 编辑
        await deviceService.updateDevice(
          deviceId: widget.device!.id,
          name: _nameController.text,
          manufacturer: _manufacturerController.text.isEmpty
              ? null
              : _manufacturerController.text,
          model: _modelController.text.isEmpty ? null : _modelController.text,
          sn: _snController.text.isEmpty ? null : _snController.text,
        );
      } else {
        // 创建
        Map<String, dynamic>? protocolParams;
        if (_protocolType == ProtocolType.virtual) {
          protocolParams = {
            'sampleInterval': int.parse(_sampleIntervalController.text),
            'minValue': double.parse(_minValueController.text),
            'maxValue': double.parse(_maxValueController.text),
          };
        }

        await deviceService.createDevice(
          workbenchId: widget.workbenchId,
          name: _nameController.text,
          protocolType: _protocolType,
          protocolParams: protocolParams,
          manufacturer: _manufacturerController.text.isEmpty
              ? null
              : _manufacturerController.text,
          model: _modelController.text.isEmpty ? null : _modelController.text,
          sn: _snController.text.isEmpty ? null : _snController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
