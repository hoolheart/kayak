import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/method.dart';
import '../../providers/method_provider.dart';
import '../../providers/services.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/error_view.dart';
import '../../widgets/toast.dart';

// ============================================================
// MethodEditPage — 方法编辑页
// ============================================================

/// 方法编辑页
///
/// 路由：`/methods/:id/edit`（编辑模式）、`/methods/new/edit`（创建模式）
/// 包含基本信息表单、JSON 过程定义编辑器、参数表 CRUD。
class MethodEditPage extends ConsumerStatefulWidget {
  const MethodEditPage({super.key, this.id});

  /// 方法 ID，为 null 时表示为创建模式
  final String? id;

  @override
  ConsumerState<MethodEditPage> createState() => _MethodEditPageState();
}

class _MethodEditPageState extends ConsumerState<MethodEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _jsonController = TextEditingController();

  /// 参数列表（本地状态，保存时序列化）
  List<MethodParameter> _parameters = [];

  /// JSON 是否有效
  bool _isJsonValid = true;

  /// JSON 验证错误消息
  String? _jsonErrorMessage;

  /// 表单是否已修改
  bool _isDirty = false;

  /// 是否正在加载（编辑模式）
  bool _isLoading = true;

  /// 加载错误
  String? _loadError;

  /// 是否正在保存
  bool _isSaving = false;

  /// 是否正在验证
  bool _isValidating = false;

  /// 是否为创建模式
  bool get _isCreateMode => widget.id == null || widget.id == 'new';

  /// 默认 JSON 模板
  static const String _defaultJson = '{\n  "nodes": [],\n  "edges": []\n}';

  @override
  void initState() {
    super.initState();
    _jsonController.text = _defaultJson;
    _loadMethod();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  /// 加载方法数据（编辑模式）
  Future<void> _loadMethod() async {
    if (_isCreateMode) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final method = await ref.read(methodDetailProvider(widget.id!).future);
      _nameController.text = method.name;
      _descriptionController.text = method.description ?? '';
      _jsonController.text = _formatJson(method.processDefinition);
      _parameters = method.parameters ?? [];
      _isJsonValid = true;
      _jsonErrorMessage = null;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  /// 格式化 JSON 为缩进字符串
  String _formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  /// 标记表单为已修改
  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  /// 验证 JSON
  void _validateJson() {
    try {
      jsonDecode(_jsonController.text);
      setState(() {
        _isJsonValid = true;
        _jsonErrorMessage = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _isJsonValid = false;
        _jsonErrorMessage = 'JSON 格式错误：${e.message}';
      });
    }
  }

  /// 解析 JSON 字符串为 Map
  Map<String, dynamic>? _parseJson(String text) {
    try {
      final parsed = jsonDecode(text);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 构建参数 schema
  Map<String, dynamic> _buildParameterSchema() {
    final properties = <String, dynamic>{};
    final required = <String>[];

    for (final param in _parameters) {
      final prop = <String, dynamic>{
        'type': param.type,
      };
      if (param.defaultValue != null) {
        prop['default'] = param.defaultValue;
      }
      if (param.min != null) {
        prop['minimum'] = param.min;
      }
      if (param.max != null) {
        prop['maximum'] = param.max;
      }
      if (param.options != null && param.options!.isNotEmpty) {
        prop['enum'] = param.options;
      }
      properties[param.key] = prop;

      if (param.isRequired) {
        required.add(param.key);
      }
    }

    return {
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };
  }

  /// 验证表单
  bool _validateForm() {
    final nameValid = _nameController.text.trim().length >= 2;
    if (!nameValid) {
      Toast.show(
        context: context,
        message: '请输入方法名称（至少 2 个字符）',
        type: ToastType.error,
      );
      return false;
    }
    _validateJson();
    return _isJsonValid;
  }

  /// 保存方法
  Future<void> _save() async {
    if (!_validateForm()) return;

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final processDefinition = _parseJson(_jsonController.text);
      if (processDefinition == null) {
        Toast.show(
          context: context,
          message: 'JSON 格式无效',
          type: ToastType.error,
        );
        setState(() => _isSaving = false);
        return;
      }

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'process_definition': processDefinition,
        'parameter_schema': _buildParameterSchema(),
        'parameters': _parameters.map((p) => p.toJson()).toList(),
      };

      if (_isCreateMode) {
        await ref
            .read(methodDetailProvider('new').notifier)
            .createMethod(data);
        if (!mounted) return;
        Toast.show(
          context: context,
          message: '创建成功',
          type: ToastType.success,
        );
        if (!mounted) return;
        context.go('/methods');
      } else {
        await ref
            .read(methodDetailProvider(widget.id!).notifier)
            .updateMethod(data);
        if (!mounted) return;
        Toast.show(
          context: context,
          message: '保存成功',
          type: ToastType.success,
        );
        if (!mounted) return;
        context.go('/methods');
      }
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context: context,
        message: '保存失败：$e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 验证方法定义
  Future<void> _validateMethod() async {
    _validateJson();
    if (!_isJsonValid) {
      Toast.show(
        context: context,
        message: 'JSON 格式错误，请先修正',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isValidating = true);

    try {
      final processDefinition = _parseJson(_jsonController.text);
      if (processDefinition == null) {
        Toast.show(
          context: context,
          message: 'JSON 格式无效',
          type: ToastType.error,
        );
        setState(() => _isValidating = false);
        return;
      }

      final service = ref.read(methodServiceProvider);
      final result = await service.validate(processDefinition);

      if (result.valid) {
        if (!mounted) return;
        Toast.show(
          context: context,
          message: '方法定义有效',
          type: ToastType.success,
        );
      } else {
        if (!mounted) return;
        Toast.show(
          context: context,
          message: result.errors.isNotEmpty
              ? result.errors.join('\n')
              : '方法定义无效',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context: context,
        message: '验证失败：$e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  /// 处理返回确认
  Future<bool> _confirmLeave() async {
    if (!_isDirty) return true;

    // Use a completer to bridge the dialog callbacks
    final completer = Completer<bool>();
    final dialogResult = ConfirmDialog.show(
      context: context,
      title: '有未保存的更改',
      description: '离开此页面将丢失未保存的更改。是否继续？',
      onConfirm: () {
        completer.complete(true);
      },
      onCancel: () {
        completer.complete(false);
      },
      confirmLabel: '继续离开',
      cancelLabel: '留在页面',
    );

    unawaited(dialogResult.then((_) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }));

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 加载状态
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isCreateMode ? '创建方法' : '编辑方法'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 错误状态
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isCreateMode ? '创建方法' : '编辑方法'),
        ),
        body: ErrorView(
          title: '方法加载失败',
          description: _loadError,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _loadError = null;
            });
            _loadMethod();
          },
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final canSave = _isDirty && _isJsonValid && !_isSaving;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_isDirty) return;
        final shouldPop = await _confirmLeave();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_isDirty) {
                final shouldPop = await _confirmLeave();
                if (shouldPop && context.mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
          ),
          title: Text(_isCreateMode ? '创建方法' : '编辑方法'),
          actions: [
            // 验证状态标签
            if (_isJsonValid && _isDirty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    '格式正确',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: colorScheme.primaryContainer.withAlpha(128),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
            else if (!_isJsonValid && _jsonController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Chip(
                  avatar: Icon(
                    Icons.error,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  label: Text(
                    '格式错误',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: colorScheme.errorContainer.withAlpha(128),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            // 保存按钮
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: canSave ? _save : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('保存'),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === 基本信息 ===
                    const _SectionHeader(title: '基本信息'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '方法名称 *',
                        hintText: '请输入方法名称',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 64,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return '请输入方法名称（至少 2 个字符）';
                        }
                        return null;
                      },
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '方法描述',
                        hintText: '请输入方法描述（选填）',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      minLines: 2,
                      maxLength: 256,
                      onChanged: (_) => _markDirty(),
                    ),

                    const SizedBox(height: 24),

                    // === 过程定义 (JSON) ===
                    _SectionHeader(
                      title: '过程定义 (JSON)',
                      trailing: _isJsonValid && _jsonController.text.isNotEmpty
                          ? Icon(Icons.check_circle,
                              size: 18, color: colorScheme.primary)
                          : (!_isJsonValid && _jsonController.text.isNotEmpty
                              ? Icon(Icons.error,
                                  size: 18, color: colorScheme.error)
                              : null),
                    ),
                    const SizedBox(height: 8),
                    _JsonEditor(
                      controller: _jsonController,
                      isValid: _isJsonValid,
                      errorMessage: _jsonErrorMessage,
                      onChanged: (value) {
                        _markDirty();
                        _validateJson();
                      },
                    ),

                    const SizedBox(height: 24),

                    // === 参数列表 ===
                    _SectionHeader(
                      title: '参数列表',
                      trailing: TextButton.icon(
                        onPressed: _showParameterDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加参数'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_parameters.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.tune,
                                size: 40,
                                color: colorScheme.onSurfaceVariant
                                    .withAlpha(128),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '暂无参数',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: _showParameterDialog,
                                child: const Text('添加第一个参数'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (isMobile)
                      _ParameterCardList(
                        parameters: _parameters,
                        onEdit: (index) =>
                            _showParameterDialog(index: index),
                        onDelete: _removeParameter,
                      )
                    else
                      _ParameterTable(
                        parameters: _parameters,
                        onEdit: (index) =>
                            _showParameterDialog(index: index),
                        onDelete: _removeParameter,
                      ),

                    const SizedBox(height: 32),

                    // === 底部操作栏 ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isValidating ? null : _validateMethod,
                          child: _isValidating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('验证'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: canSave ? _save : null,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('保存'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示参数编辑对话框
  void _showParameterDialog({int? index}) {
    final isEditing = index != null;
    final param = isEditing ? _parameters[index] : null;

    // 对话框字段值
    final keyController = TextEditingController(text: param?.key ?? '');
    final labelController = TextEditingController(text: param?.label ?? '');
    String paramType = param?.type ?? 'number';
    bool isRequired = param?.isRequired ?? false;
    final unitController = TextEditingController(text: param?.unit ?? '');
    final minController =
        TextEditingController(text: param?.min?.toString() ?? '');
    final maxController =
        TextEditingController(text: param?.max?.toString() ?? '');
    final defaultValueController = TextEditingController(
      text: param?.defaultValue?.toString() ?? '',
    );
    final descriptionController =
        TextEditingController(text: param?.description ?? '');
    final enumOptions = ValueNotifier<List<String>>(
      param?.options ?? [],
    );
    final enumInputController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void showParamDialog() {
      showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final isEnumType = paramType == 'enum';
              final isNumberType =
                  paramType == 'number' || paramType == 'integer';
              final isBooleanType = paramType == 'boolean';

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(isEditing ? '编辑参数' : '添加参数'),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 560,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 参数键
                          TextFormField(
                            controller: keyController,
                            decoration: const InputDecoration(
                              labelText: '参数键 *',
                              hintText: '仅允许字母、数字和下划线',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入参数键';
                              }
                              final regex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
                              if (!regex.hasMatch(value)) {
                                return '参数键只能包含字母、数字和下划线，且不能以数字开头';
                              }
                              // 唯一性校验
                              if (!isEditing) {
                                final exists = _parameters
                                    .any((p) => p.key == value);
                                if (exists) {
                                  return '参数键已存在';
                                }
                              } else {
                                final exists = _parameters
                                    .asMap()
                                    .entries
                                    .any((e) =>
                                        e.value.key == value &&
                                        e.key != index);
                                if (exists) {
                                  return '参数键已存在';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 显示标签
                          TextFormField(
                            controller: labelController,
                            decoration: const InputDecoration(
                              labelText: '显示标签',
                              hintText: '默认等于参数键',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 参数类型 + 是否必填
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: paramType,
                                  decoration: const InputDecoration(
                                    labelText: '参数类型 *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'number',
                                      child: Text('数值'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'integer',
                                      child: Text('整数'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'string',
                                      child: Text('字符串'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'boolean',
                                      child: Text('布尔'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'enum',
                                      child: Text('枚举'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {
                                      paramType = value ?? 'number';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SwitchListTile(
                                  title: const Text('必填'),
                                  value: isRequired,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      isRequired = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 单位（仅 number/integer）
                          if (isNumberType)
                            TextFormField(
                              controller: unitController,
                              decoration: const InputDecoration(
                                labelText: '单位',
                                hintText: '如 kN、°C、s',
                                border: OutlineInputBorder(),
                              ),
                            )
                          else if (isEnumType)
                            ..._buildEnumFields(
                              enumOptions: enumOptions,
                              inputController: enumInputController,
                              setDialogState: setDialogState,
                            ),

                          if (isNumberType) ...[
                            const SizedBox(height: 16),
                            // 最小值 + 最大值
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: minController,
                                    decoration: const InputDecoration(
                                      labelText: '最小值',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: maxController,
                                    decoration: const InputDecoration(
                                      labelText: '最大值',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          minController.text.isNotEmpty) {
                                        final min =
                                            double.tryParse(minController.text);
                                        final max = double.tryParse(value);
                                        if (min != null &&
                                            max != null &&
                                            max < min) {
                                          return '最大值不能小于最小值';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          // 默认值
                          if (isBooleanType)
                            SwitchListTile(
                              title: const Text('默认值'),
                              value: defaultValueController.text == 'true',
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) {
                                setDialogState(() {
                                  defaultValueController.text =
                                      value.toString();
                                });
                              },
                            )
                          else if (isEnumType)
                            DropdownButtonFormField<String>(
                              initialValue: enumOptions.value.contains(
                                      defaultValueController.text)
                                  ? defaultValueController.text
                                  : null,
                              decoration: const InputDecoration(
                                labelText: '默认值',
                                border: OutlineInputBorder(),
                              ),
                              items: enumOptions.value
                                  .map(
                                    (opt) => DropdownMenuItem(
                                      value: opt,
                                      child: Text(opt),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  defaultValueController.text = value ?? '';
                                });
                              },
                            )
                          else
                            TextFormField(
                              controller: defaultValueController,
                              decoration: const InputDecoration(
                                labelText: '默认值',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: isNumberType
                                  ? TextInputType.number
                                  : TextInputType.text,
                            ),

                          const SizedBox(height: 16),

                          // 描述
                          TextFormField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: '描述',
                              hintText: '参数说明（选填）',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 2,
                            maxLength: 128,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;

                      final newParam = MethodParameter(
                        key: keyController.text.trim(),
                        type: paramType,
                        label: labelController.text.trim().isEmpty
                            ? null
                            : labelController.text.trim(),
                        defaultValue: _parseDefaultValue(
                          defaultValueController.text,
                          paramType,
                        ),
                        isRequired: isRequired,
                        unit: unitController.text.trim().isEmpty
                            ? null
                            : unitController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        min: double.tryParse(minController.text),
                        max: double.tryParse(maxController.text),
                        options: enumOptions.value.isEmpty
                            ? null
                            : List.from(enumOptions.value),
                      );

                      setState(() {
                        if (isEditing) {
                          _parameters[index] = newParam;
                        } else {
                          _parameters.add(newParam);
                        }
                        _markDirty();
                      });

                      Navigator.of(ctx).pop();
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    showParamDialog();
  }

  /// 构建枚举选项字段
  List<Widget> _buildEnumFields({
    required ValueNotifier<List<String>> enumOptions,
    required TextEditingController inputController,
    required void Function(VoidCallback) setDialogState,
  }) {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: inputController,
              decoration: const InputDecoration(
                labelText: '枚举选项',
                hintText: '输入选项后点击添加',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              final text = inputController.text.trim();
              if (text.isNotEmpty && !enumOptions.value.contains(text)) {
                setDialogState(() {
                  enumOptions.value = [...enumOptions.value, text];
                  inputController.clear();
                });
              }
            },
          ),
        ],
      ),
      if (enumOptions.value.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: enumOptions.value.map((opt) {
              return Chip(
                label: Text(opt, style: const TextStyle(fontSize: 13)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setDialogState(() {
                    enumOptions.value =
                        enumOptions.value.where((o) => o != opt).toList();
                  });
                },
              );
            }).toList(),
          ),
        ),
    ];
  }

  /// 解析默认值
  Object? _parseDefaultValue(String text, String type) {
    if (text.isEmpty) return null;
    switch (type) {
      case 'number':
        return double.tryParse(text);
      case 'integer':
        return int.tryParse(text);
      case 'boolean':
        return text == 'true';
      default:
        return text;
    }
  }

  /// 删除参数
  void _removeParameter(int index) {
    setState(() {
      _parameters.removeAt(index);
      _markDirty();
    });
  }
}

// ============================================================
// 子组件
// ============================================================

/// Section 标题组件
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

/// JSON 编辑器
class _JsonEditor extends StatefulWidget {
  const _JsonEditor({
    required this.controller,
    required this.isValid,
    this.errorMessage,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isValid;
  final String? errorMessage;
  final ValueChanged<String> onChanged;

  @override
  State<_JsonEditor> createState() => _JsonEditorState();
}

class _JsonEditorState extends State<_JsonEditor> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNode.hasFocus
              ? colorScheme.primary
              : (widget.isValid
                  ? colorScheme.outlineVariant
                  : colorScheme.error),
          width: _focusNode.hasFocus ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 编辑器区域
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 行号栏
                Container(
                  width: 48,
                  color: colorScheme.surfaceContainerHighest.withAlpha(77),
                  child: _buildLineNumbers(),
                ),
                // 编辑区域
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                      isCollapsed: true,
                    ),
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ],
            ),
          ),
          // 底部栏
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(51),
            ),
            child: Row(
              children: [
                // 统计信息
                Text(
                  '行数: ${'\n'.allMatches(widget.controller.text).length + 1} | 字符数: ${widget.controller.text.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // 验证状态
                if (widget.controller.text.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isValid
                            ? Icons.check_circle
                            : Icons.error,
                        size: 14,
                        color: widget.isValid
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isValid
                            ? 'JSON 格式正确'
                            : (widget.errorMessage ?? 'JSON 格式错误'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: widget.isValid
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers() {
    final lines = widget.controller.text.split('\n');
    final lineCount = lines.length;

    return ListView.builder(
      itemCount: lineCount,
      itemExtent: 20,
      itemBuilder: (context, index) {
        return Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 12),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withAlpha(153),
            ),
          ),
        );
      },
    );
  }
}

/// 参数表（桌面端 DataTable）
class _ParameterTable extends StatelessWidget {
  const _ParameterTable({
    required this.parameters,
    required this.onEdit,
    required this.onDelete,
  });

  final List<MethodParameter> parameters;
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 52,
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('参数键')),
          DataColumn(label: Text('显示标签')),
          DataColumn(label: Text('类型')),
          DataColumn(label: Text('必填')),
          DataColumn(label: Text('默认值')),
          DataColumn(label: Text('单位')),
          DataColumn(label: Text('描述')),
          DataColumn(label: Text('操作')),
        ],
        rows: parameters.asMap().entries.map((entry) {
          final index = entry.key;
          final param = entry.value;
          return DataRow(
            cells: [
              DataCell(Text(param.key,
                  style: const TextStyle(fontFamily: 'RobotoMono'))),
              DataCell(Text(param.label ?? '-')),
              DataCell(_TypeChip(type: param.type)),
              DataCell(Icon(
                param.isRequired
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 18,
                color: param.isRequired
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              )),
              DataCell(Text(param.defaultValue?.toString() ?? '-')),
              DataCell(Text(param.unit ?? '-')),
              DataCell(
                SizedBox(
                  width: 120,
                  child: Text(
                    param.description ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 18, color: colorScheme.primary),
                      tooltip: '编辑',
                      onPressed: () => onEdit(index),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outlined,
                          size: 18, color: colorScheme.error),
                      tooltip: '删除',
                      onPressed: () => onDelete(index),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// 类型徽章
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;
    String label;

    switch (type) {
      case 'number':
      case 'integer':
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        label = type == 'number' ? '数值' : '整数';
        break;
      case 'string':
        bgColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        label = '字符串';
        break;
      case 'boolean':
        bgColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        label = '布尔';
        break;
      case 'enum':
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        label = '枚举';
        break;
      default:
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
}

/// 参数卡片列表（移动端）
class _ParameterCardList extends StatelessWidget {
  const _ParameterCardList({
    required this.parameters,
    required this.onEdit,
    required this.onDelete,
  });

  final List<MethodParameter> parameters;
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      children: parameters.asMap().entries.map((entry) {
        final index = entry.key;
        final param = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${param.label ?? param.key} (${param.key})',
                        style: textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 18, color: colorScheme.primary),
                      tooltip: '编辑',
                      onPressed: () => onEdit(index),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outlined,
                          size: 18, color: colorScheme.error),
                      tooltip: '删除',
                      onPressed: () => onDelete(index),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _TypeChip(type: param.type),
                    const SizedBox(width: 8),
                    Text(
                      '必填: ${param.isRequired ? "●" : "○"}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '默认值: ${param.defaultValue?.toString() ?? "-"}${param.unit != null ? " ${param.unit}" : ""}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (param.description != null &&
                    param.description!.isNotEmpty)
                  Text(
                    param.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
