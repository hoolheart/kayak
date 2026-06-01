import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/app_localizations.dart';
import '../../models/device.dart';
import '../../models/point.dart';
import '../../providers/point_provider.dart';
import '../../providers/services.dart';
import '../../widgets/toast.dart';

// ============================================================
// PointFormDialog — 添加/编辑测点对话框
//
// 支持添加和编辑两种模式。
// - 添加模式：字段为空/默认值，POST /api/v1/points
// - 编辑模式：父组件通过 [existing] 参数传入 [Point] 对象预填表单
//
// 响应式：
// - 桌面端 (≥600px)：AlertDialog，宽 560px
// - 移动端 (<600px)：ModalBottomSheet，100% 宽
//
// Modbus 设备：额外显示 Modbus 配置区域
// ============================================================

/// PointFormDialog — 添加/编辑测点对话框
class PointFormDialog extends ConsumerStatefulWidget {
  const PointFormDialog({
    super.key,
    required this.deviceId,
    this.existing,
    this.isMobile = false,
  });

  /// 所属设备 ID
  final String deviceId;

  /// 现有测点（编辑模式时传入）
  final Point? existing;

  /// 是否为移动端布局
  final bool isMobile;

  /// 显示测点配置对话框
  ///
  /// 根据屏幕宽度自动选择样式：
  /// - < 600px：底部 Sheet
  /// - >= 600px：居中 Dialog
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String deviceId,
    Point? existing,
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
        builder: (_) => PointFormDialog(
          deviceId: deviceId,
          existing: existing,
          isMobile: true,
        ),
      );
    }

    return showDialog(
      context: context,
      builder: (_) => PointFormDialog(
        deviceId: deviceId,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<PointFormDialog> createState() => _PointFormDialogState();
}

class _PointFormDialogState extends ConsumerState<PointFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // 文本控制器
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _minValueController;
  late final TextEditingController _maxValueController;
  late final TextEditingController _defaultValueController;
  late final TextEditingController _addressController;

  // 下拉选择值
  DataType? _selectedDataType;
  AccessType? _selectedAccessType;
  String? _selectedRegisterType;
  String? _selectedDataFormat;

  // 表单状态
  bool _isSaving = false;
  bool _modbusExpanded = true;
  bool _isModbusDevice = false;

  // 是否为编辑模式
  bool get _isEdit => widget.existing != null;

  // 编辑模式初始值（用于变更检测）
  String _initialName = '';
  String _initialUnit = '';
  String _initialMinValue = '';
  String _initialMaxValue = '';
  String _initialDefaultValue = '';
  DataType? _initialDataType;
  AccessType? _initialAccessType;

  /// 编辑模式下表单是否有未保存的变更。
  /// 添加模式下始终为 true（保存按钮始终启用）。
  bool get _isDirty {
    if (!_isEdit) return true;
    return _nameController.text != _initialName ||
        _unitController.text != _initialUnit ||
        _minValueController.text != _initialMinValue ||
        _maxValueController.text != _initialMaxValue ||
        _defaultValueController.text != _initialDefaultValue ||
        _selectedDataType != _initialDataType ||
        _selectedAccessType != _initialAccessType;
  }

  // Modbus 寄存器类型选项
  static const _registerTypeOptions = [
    'Coil',
    'Discrete Input',
    'Holding Register',
    'Input Register',
  ];

  // Modbus 数据格式选项
  static const _dataFormatOptions = [
    'uint16',
    'int16',
    'float32',
    'uint32',
    'int32',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _unitController = TextEditingController(text: existing?.unit ?? '');
    _minValueController = TextEditingController(
      text: existing?.minValue?.toString() ?? '',
    );
    _maxValueController = TextEditingController(
      text: existing?.maxValue?.toString() ?? '',
    );
    _defaultValueController = TextEditingController(
      text: existing?.defaultValue ?? '',
    );
    _addressController = TextEditingController();

    _selectedDataType = existing?.dataType ?? DataType.number;
    _selectedAccessType = existing?.accessType ?? AccessType.ro;

    // 保存初始值用于编辑模式变更检测
    if (_isEdit) {
      _initialName = existing?.name ?? '';
      _initialUnit = existing?.unit ?? '';
      _initialMinValue = existing?.minValue?.toString() ?? '';
      _initialMaxValue = existing?.maxValue?.toString() ?? '';
      _initialDefaultValue = existing?.defaultValue ?? '';
      _initialDataType = existing?.dataType;
      _initialAccessType = existing?.accessType;
    }

    // 异步检查设备类型
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeviceProtocol();
      _loadModbusParams();
    });
  }

  /// 检查设备协议类型，判断是否需要显示 Modbus 配置区域
  Future<void> _checkDeviceProtocol() async {
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final device = await deviceService.getById(widget.deviceId);
      if (mounted) {
        setState(() {
          _isModbusDevice = device.protocolType == ProtocolType.modbusTcp ||
              device.protocolType == ProtocolType.modbusRtu;
        });
      }
    } catch (_) {
      // 静默失败，默认不显示 Modbus 配置
    }
  }

  /// 编辑模式时从 device protocol_params 加载 Modbus 配置
  Future<void> _loadModbusParams() async {
    if (!_isEdit) return;
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final device = await deviceService.getById(widget.deviceId);
      final protocolParams = device.protocolParams;
      if (protocolParams != null) {
        final points = protocolParams['points'] as Map<String, dynamic>?;
        if (points != null) {
          final pointConfig = points[widget.existing!.id] as Map<String, dynamic>?;
          if (pointConfig != null && mounted) {
            setState(() {
              _selectedRegisterType = pointConfig['register_type'] as String?;
              _addressController.text =
                  (pointConfig['address'] as num?)?.toString() ?? '';
              _selectedDataFormat = pointConfig['data_format'] as String?;
            });
          }
        }
      }
    } catch (_) {
      // 静默失败
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    _defaultValueController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// 收集基础字段数据
  Map<String, dynamic> _collectBasicData() {
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'data_type': _selectedDataType!.name,
      'access_type': _selectedAccessType!.name,
    };

    if (_unitController.text.trim().isNotEmpty) {
      data['unit'] = _unitController.text.trim();
    }
    if (_minValueController.text.trim().isNotEmpty) {
      data['min_value'] = double.tryParse(_minValueController.text.trim());
    }
    if (_maxValueController.text.trim().isNotEmpty) {
      data['max_value'] = double.tryParse(_maxValueController.text.trim());
    }
    if (_defaultValueController.text.trim().isNotEmpty) {
      data['default_value'] = _defaultValueController.text.trim();
    }

    return data;
  }

  /// 保存 Modbus 配置到 device protocol_params
  Future<void> _saveModbusConfig(String pointId) async {
    if (!_isModbusDevice) return;
    if (_selectedRegisterType == null &&
        _addressController.text.trim().isEmpty &&
        _selectedDataFormat == null) {
      return;
    }

    final deviceService = ref.read(deviceServiceProvider);
    final device = await deviceService.getById(widget.deviceId);

    // Read-modify-write: 读取现有 protocol_params
    final protocolParams = Map<String, dynamic>.from(
      device.protocolParams ?? {},
    );
    final points = Map<String, dynamic>.from(
      (protocolParams['points'] as Map<String, dynamic>?) ?? {},
    );
    points[pointId] = {
      if (_selectedRegisterType != null) 'register_type': _selectedRegisterType,
      if (_addressController.text.trim().isNotEmpty)
        'address': int.tryParse(_addressController.text.trim()),
      if (_selectedDataFormat != null) 'data_format': _selectedDataFormat,
    };
    protocolParams['points'] = points;

    await deviceService.update(widget.deviceId, {
      'protocol_params': protocolParams,
    });
  }

  /// 保存
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      if (_isEdit) {
        // 编辑模式
        await ref
            .read(pointListProvider(widget.deviceId).notifier)
            .updatePoint(widget.existing!.id, _collectBasicData());

        // 保存 Modbus 配置
        if (_isModbusDevice) {
          await _saveModbusConfig(widget.existing!.id);
        }
      } else {
        // 添加模式
        final notifier = ref.read(pointListProvider(widget.deviceId).notifier);
        final newPoint = await notifier.createPoint(
          name: _nameController.text.trim(),
          dataType: _selectedDataType!.name,
          accessType: _selectedAccessType!.name,
          unit: _unitController.text.trim().isNotEmpty
              ? _unitController.text.trim()
              : null,
          minValue: double.tryParse(_minValueController.text.trim()),
          maxValue: double.tryParse(_maxValueController.text.trim()),
          defaultValue: _defaultValueController.text.trim().isNotEmpty
              ? _defaultValueController.text.trim()
              : null,
        );

        // 保存 Modbus 配置
        if (_isModbusDevice) {
          await _saveModbusConfig(newPoint.id);
        }
      }

      if (!mounted) return;
      Toast.show(
        context: context,
        message: l10n.pointSaveSuccess,
        type: ToastType.success,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context: context,
        message: '${l10n.pointSaveFailed}: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMobile = widget.isMobile;

    final dialogTitle = _isEdit ? l10n.editPoint : l10n.addPointTitle;

    final dialogContent = Form(
      key: _formKey,
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 头部
            _buildHeader(l10n, dialogTitle, colorScheme, textTheme),
            // 内容区
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicFields(l10n, colorScheme, textTheme),
                    if (_isModbusDevice) ...[
                      const SizedBox(height: 8),
                      _buildModbusConfig(l10n, colorScheme, textTheme),
                    ],
                  ],
                ),
              ),
            ),
            // 操作按钮
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

  /// 头部
  Widget _buildHeader(
    AppLocalizations l10n,
    String title,
    ColorScheme colorScheme,
    TextTheme textTheme,
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
            tooltip: l10n.cancel,
          ),
        ],
      ),
    );
  }

  /// 基础字段
  Widget _buildBasicFields(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 名称
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: '${l10n.pointNameLabel} *',
            hintText: l10n.pointNameHint,
            helperText: '${_nameController.text.length}/255',
            helperMaxLines: 1,
          ),
          maxLength: 255,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (context, {required int currentLength, required bool isFocused, required int? maxLength}) {
            return Text(
              '$currentLength/$maxLength',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            );
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.pointNameRequired;
            }
            if (value.trim().length > 255) {
              return l10n.pointNameTooLong;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 数据类型
        DropdownButtonFormField<DataType>(
          key: ValueKey('data_type_$_selectedDataType'),
          value: _selectedDataType,
          initialValue: _selectedDataType,
          decoration: InputDecoration(
            labelText: '${l10n.pointDataTypeLabel} *',
          ),
          items: DataType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_dataTypeLabel(type, l10n)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedDataType = value);
          },
          validator: (value) {
            if (value == null) return l10n.fieldRequired;
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 访问权限
        DropdownButtonFormField<AccessType>(
          key: ValueKey('access_type_$_selectedAccessType'),
          value: _selectedAccessType,
          initialValue: _selectedAccessType,
          decoration: InputDecoration(
            labelText: '${l10n.pointAccessTypeLabel} *',
          ),
          items: AccessType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_accessTypeLabel(type, l10n)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedAccessType = value);
          },
          validator: (value) {
            if (value == null) return l10n.fieldRequired;
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 单位
        TextFormField(
          controller: _unitController,
          decoration: InputDecoration(
            labelText: l10n.pointUnitLabel,
            hintText: '°C',
          ),
          maxLength: 32,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (context, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
        ),
        const SizedBox(height: 16),
        // 最小值
        TextFormField(
          controller: _minValueController,
          decoration: InputDecoration(
            labelText: l10n.pointMinValueLabel,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        // 最大值
        TextFormField(
          controller: _maxValueController,
          decoration: InputDecoration(
            labelText: l10n.pointMaxValueLabel,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final minVal = double.tryParse(_minValueController.text);
              final maxVal = double.tryParse(value);
              if (minVal != null && maxVal != null && maxVal <= minVal) {
                return l10n.pointRangeInvalid;
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 默认值
        TextFormField(
          controller: _defaultValueController,
          decoration: InputDecoration(
            labelText: l10n.pointDefaultValueLabel,
          ),
        ),
      ],
    );
  }

  /// Modbus 配置区域
  Widget _buildModbusConfig(
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
        title: Row(
          children: [
            Icon(
              Icons.settings_ethernet,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.pointModbusConfig,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        initiallyExpanded: _modbusExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _modbusExpanded = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 寄存器类型
                DropdownButtonFormField<String>(
                  key: ValueKey('register_type_$_selectedRegisterType'),
                  value: _selectedRegisterType,
                  initialValue: _selectedRegisterType,
                  decoration: InputDecoration(
                    labelText: '${l10n.pointRegisterTypeLabel} *',
                  ),
                  items: _registerTypeOptions.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRegisterType = value);
                  },
                ),
                const SizedBox(height: 16),
                // 起始地址
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: '${l10n.pointAddressLabel} *',
                    hintText: '0-65535',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isModbusDevice &&
                        value != null &&
                        value.isNotEmpty) {
                      final address = int.tryParse(value);
                      if (address == null || address < 0 || address > 65535) {
                        return l10n.pointAddressRange;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 数据格式
                DropdownButtonFormField<String>(
                  key: ValueKey('data_format_$_selectedDataFormat'),
                  value: _selectedDataFormat,
                  initialValue: _selectedDataFormat,
                  decoration: InputDecoration(
                    labelText: '${l10n.pointDataFormatLabel} *',
                  ),
                  items: _dataFormatOptions.map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(format),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedDataFormat = value);
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
                  onPressed: (_isSaving || !_isDirty) ? null : _handleSave,
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
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: (_isSaving || !_isDirty) ? null : _handleSave,
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

  /// 数据类型标签
  String _dataTypeLabel(DataType type, AppLocalizations l10n) {
    switch (type) {
      case DataType.number:
        return l10n.dataTypeNumber;
      case DataType.integer:
        return l10n.dataTypeInteger;
      case DataType.boolean:
        return l10n.dataTypeBoolean;
      case DataType.string:
        return l10n.dataTypeString;
    }
  }

  /// 访问权限标签
  String _accessTypeLabel(AccessType type, AppLocalizations l10n) {
    switch (type) {
      case AccessType.ro:
        return l10n.accessTypeRo;
      case AccessType.wo:
        return l10n.accessTypeWo;
      case AccessType.rw:
        return l10n.accessTypeRw;
    }
  }
}
