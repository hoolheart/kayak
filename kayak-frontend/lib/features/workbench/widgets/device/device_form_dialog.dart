/// 设备表单对话框
///
/// 主对话框容器，协议路由中心，提交逻辑管理。
/// 支持创建和编辑设备，支持三种协议的动态表单。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../models/device.dart';
import '../../models/protocol_config.dart';
import '../../services/device_service.dart';
import 'common_fields.dart';
import 'protocol_selector.dart';
import 'virtual_form.dart';
import 'modbus_tcp_form.dart';
import 'modbus_rtu_form.dart';

/// 设备表单对话框
///
/// 使用协议路由：根据 [_selectedProtocol] 动态渲染对应的协议表单。
/// 编辑模式下协议选择器锁定。
class DeviceFormDialog extends ConsumerStatefulWidget {
  final Device? device; // null = 创建模式, non-null = 编辑模式
  final String workbenchId;

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

  // === 通用字段控制器 ===
  late final TextEditingController _nameController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late final TextEditingController _snController;

  // === 协议表单 GlobalKey (用于跨组件验证) ===
  final _virtualFormKey = GlobalKey<VirtualProtocolFormState>();
  final _tcpFormKey = GlobalKey<ModbusTcpFormState>();
  final _rtuFormKey = GlobalKey<ModbusRtuFormState>();

  // === 状态 ===
  ProtocolType _selectedProtocol = ProtocolType.virtual;
  bool _isSubmitting = false;
  bool _isDirty = false;

  bool get _isEditMode => widget.device != null;

  @override
  void initState() {
    super.initState();

    final device = widget.device;

    // 通用字段
    _nameController = TextEditingController(text: device?.name ?? '');
    _manufacturerController =
        TextEditingController(text: device?.manufacturer ?? '');
    _modelController = TextEditingController(text: device?.model ?? '');
    _snController = TextEditingController(text: device?.sn ?? '');

    // 协议类型
    if (_isEditMode) {
      _selectedProtocol = device!.protocolType;
      _isDirty = false;
    } else {
      _selectedProtocol = ProtocolType.virtual;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _snController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      key: Key(_isEditMode
          ? 'edit-device-dialog-${widget.device?.id}'
          : 'create-device-dialog'),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _isEditMode ? '编辑设备 - ${_nameController.text}' : '创建设备',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onCancel,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          minWidth: 480,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Section 1: 基本信息
                _buildBasicInfoSection(theme),
                const SizedBox(height: 24),
                // Section 2: 协议配置
                _buildProtocolSection(theme),
              ],
            ),
          ),
        ),
      ),
      contentPadding: const EdgeInsets.all(24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: _buildActions(theme),
    );
  }

  // === Section 1: 基本信息 ===
  Widget _buildBasicInfoSection(ThemeData theme) {
    return CommonFields(
      nameController: _nameController,
      manufacturerController: _manufacturerController,
      modelController: _modelController,
      snController: _snController,
      onFieldChanged: () => setState(() => _isDirty = true),
    );
  }

  // === Section 2: 协议配置 ===
  Widget _buildProtocolSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '协议配置',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        // 协议选择器
        ProtocolSelector(
          value: _selectedProtocol,
          enabled: !_isEditMode, // 编辑模式下禁用
          onChanged: _onProtocolChanged,
        ),
        const SizedBox(height: 16),
        // 协议表单 (AnimatedSwitcher + 条件渲染)
        _buildProtocolForm(),
      ],
    );
  }

  // === 协议表单路由 (AnimatedSwitcher + ValueKey) ===
  Widget _buildProtocolForm() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_selectedProtocol),
        child: switch (_selectedProtocol) {
          ProtocolType.virtual => VirtualProtocolForm(
              key: _virtualFormKey,
              initialConfig: _isEditMode ? _buildInitialVirtualConfig() : null,
              isEditMode: _isEditMode,
              onFieldChanged: () => setState(() => _isDirty = true),
            ),
          ProtocolType.modbusTcp => ModbusTcpForm(
              key: _tcpFormKey,
              initialConfig: _isEditMode ? _buildInitialTcpConfig() : null,
              isEditMode: _isEditMode,
              deviceId: widget.device?.id,
              onFieldChanged: () => setState(() => _isDirty = true),
            ),
          ProtocolType.modbusRtu => ModbusRtuForm(
              key: _rtuFormKey,
              initialConfig: _isEditMode ? _buildInitialRtuConfig() : null,
              isEditMode: _isEditMode,
              deviceId: widget.device?.id,
              onFieldChanged: () => setState(() => _isDirty = true),
            ),
          _ => Container(
              key: ValueKey('${_selectedProtocol.name}-empty'),
              child: const SizedBox(),
            ),
        },
      ),
    );
  }

  // === 编辑模式数据预填充 ===

  VirtualConfig? _buildInitialVirtualConfig() {
    final params = widget.device?.protocolParams;
    if (params == null) return null;
    return VirtualConfig.fromJson(params);
  }

  TcpConfig? _buildInitialTcpConfig() {
    final params = widget.device?.protocolParams;
    if (params == null) return null;
    return TcpConfig.fromJson(params);
  }

  RtuConfig? _buildInitialRtuConfig() {
    final params = widget.device?.protocolParams;
    if (params == null) return null;
    return RtuConfig.fromJson(params);
  }

  // === 底部操作按钮 ===
  List<Widget> _buildActions(ThemeData theme) {
    return [
      TextButton(
        key: const Key('cancel-device-button'),
        onPressed: _isSubmitting ? null : _onCancel,
        child: const Text('取消'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        key: const Key('submit-device-button'),
        onPressed: _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Text(_isEditMode ? '保存' : '创建'),
      ),
    ];
  }

  // === 协议切换处理 ===
  void _onProtocolChanged(ProtocolType newProtocol) {
    if (_selectedProtocol == newProtocol) return;

    if (_isDirty) {
      _showProtocolSwitchConfirmDialog(newProtocol);
    } else {
      setState(() => _selectedProtocol = newProtocol);
    }
  }

  /// 协议切换确认对话框
  Future<void> _showProtocolSwitchConfirmDialog(
      ProtocolType newProtocol) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon:
            const Icon(Icons.warning, color: AppColorSchemes.warning, size: 48),
        title: const Text('切换协议？'),
        content: const Text('切换协议类型将清空当前已填写的协议参数。是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认切换'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _selectedProtocol = newProtocol;
        _isDirty = false;
      });
    }
  }

  // === 取消处理 ===
  void _onCancel() {
    if (_isDirty) {
      _showDiscardConfirmDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// 放弃修改确认对话框
  Future<void> _showDiscardConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃修改？'),
        content: const Text('您有未保存的修改，确定要放弃吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  // === 提交逻辑 ===
  Future<void> _submit() async {
    // Step 1: 验证通用字段
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) {
      return;
    }

    // Step 2: 验证协议字段
    final bool protocolValid = switch (_selectedProtocol) {
      ProtocolType.virtual => _virtualFormKey.currentState?.validate() ?? false,
      ProtocolType.modbusTcp => _tcpFormKey.currentState?.validate() ?? false,
      ProtocolType.modbusRtu => _rtuFormKey.currentState?.validate() ?? false,
      _ => false,
    };

    if (!protocolValid) {
      _showValidationError();
      return;
    }

    // Step 3: 构建数据并提交
    setState(() => _isSubmitting = true);

    try {
      final deviceService = ref.read(deviceServiceProvider);
      final protocolParams = _buildProtocolParams();

      if (widget.device != null) {
        // 编辑模式
        await deviceService.updateDevice(
          deviceId: widget.device!.id,
          name: _nameController.text,
          protocolParams: protocolParams,
          manufacturer: _manufacturerController.text.isEmpty
              ? null
              : _manufacturerController.text,
          model: _modelController.text.isEmpty ? null : _modelController.text,
          sn: _snController.text.isEmpty ? null : _snController.text,
        );
      } else {
        // 创建模式
        await deviceService.createDevice(
          workbenchId: widget.workbenchId,
          name: _nameController.text,
          protocolType: _selectedProtocol,
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
      _handleSubmitError(e);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 构建协议参数 JSON
  Map<String, dynamic>? _buildProtocolParams() {
    return switch (_selectedProtocol) {
      ProtocolType.virtual =>
        _virtualFormKey.currentState?.getConfig().toJson(),
      ProtocolType.modbusTcp => _tcpFormKey.currentState?.getConfig().toJson(),
      ProtocolType.modbusRtu => _rtuFormKey.currentState?.getConfig().toJson(),
      _ => null,
    };
  }

  /// 验证失败提示
  void _showValidationError() {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: theme.colorScheme.onError, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '请检查协议参数字段并修正错误',
                style: TextStyle(color: theme.colorScheme.onError),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 提交错误处理
  void _handleSubmitError(Object error) {
    if (!mounted) return;

    String message;
    if (error is Exception) {
      message = '操作失败: ${error.toString()}';
    } else {
      message = '操作失败: $error';
    }

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: theme.colorScheme.onError, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onError),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.error,
        action: SnackBarAction(
          label: '重试',
          textColor: theme.colorScheme.onError,
          onPressed: _submit,
        ),
      ),
    );
  }
}
