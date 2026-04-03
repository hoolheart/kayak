/// Method edit page
///
/// Creates or edits a test method with JSON editor and parameter config
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/method.dart';
import '../providers/method_edit_provider.dart';

/// Method edit page
class MethodEditPage extends ConsumerStatefulWidget {
  final String? methodId;

  const MethodEditPage({super.key, this.methodId});

  @override
  ConsumerState<MethodEditPage> createState() => _MethodEditPageState();
}

class _MethodEditPageState extends ConsumerState<MethodEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _jsonController = TextEditingController();
  final _paramNameController = TextEditingController();
  final _paramTypeController = TextEditingController();
  final _paramDefaultController = TextEditingController();
  final _paramUnitController = TextEditingController();
  final _paramDescController = TextEditingController();

  // C5 fix: Track last shown error to prevent snackbar loop
  String? _lastShownError;

  // M7 fix: Track initial sync state to avoid wasteful rebuilds
  bool _initialSyncDone = false;

  @override
  void initState() {
    super.initState();
    if (widget.methodId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(methodEditProvider.notifier).loadMethod(widget.methodId!);
      });
    } else {
      // For create mode, mark initial sync as done since there's no method to load
      _initialSyncDone = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _jsonController.dispose();
    _paramNameController.dispose();
    _paramTypeController.dispose();
    _paramDefaultController.dispose();
    _paramUnitController.dispose();
    _paramDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(methodEditProvider);
    final isCreateMode = widget.methodId == null;

    // M7 fix: Only sync controllers on initial load, not every rebuild
    if (!_initialSyncDone && (state.isLoaded || isCreateMode)) {
      _initialSyncDone = true;
      _nameController.text = state.name;
      _descriptionController.text = state.description ?? '';
      _jsonController.text = state.processDefinitionJson;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreateMode ? '新建方法' : '编辑方法'),
        actions: [
          if (state.isValidating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: () {
                ref.read(methodEditProvider.notifier).validateMethod();
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('验证'),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: state.canSave ? _saveMethod : null,
            icon: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 18),
            label: Text(state.isSaving ? '保存中...' : '保存'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      // M9 fix: Warn user about unsaved changes when navigating away
      body: PopScope(
        canPop: !state.isDirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _showDiscardDialog();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        },
        child: state.error != null
            ? _buildErrorBanner(context, state.error!)
            : _buildContent(context, state),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    // C5 fix: Only show snackbar once per error (not on every rebuild)
    if (error != _lastShownError) {
      _lastShownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              action: SnackBarAction(
                label: '关闭',
                textColor: Theme.of(context).colorScheme.onErrorContainer,
                onPressed: () {
                  ref.read(methodEditProvider.notifier).clearError();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      });
    }
    return _buildContent(context, ref.watch(methodEditProvider));
  }

  Widget _buildContent(BuildContext context, MethodEditState state) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '名称 *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '名称不能为空';
              }
              if (value.length > 255) {
                return '名称不能超过255个字符';
              }
              return null;
            },
            onChanged: (value) {
              ref.read(methodEditProvider.notifier).updateName(value);
            },
          ),
          const SizedBox(height: 16),

          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '描述',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
            onChanged: (value) {
              ref
                  .read(methodEditProvider.notifier)
                  .updateDescription(value.isEmpty ? null : value);
            },
          ),
          const SizedBox(height: 24),

          // Process definition JSON editor
          _buildJsonEditor(context, state),
          const SizedBox(height: 24),

          // Parameter table
          _buildParameterSection(context, state),
          const SizedBox(height: 24),

          // Validation result
          if (state.validationResult != null)
            _buildValidationResult(context, state),
        ],
      ),
    );
  }

  Widget _buildJsonEditor(BuildContext context, MethodEditState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '过程定义 (JSON)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            if (state.hasJsonError)
              Text(
                'JSON格式错误',
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  state.hasJsonError ? colorScheme.error : colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _jsonController,
            maxLines: 15,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              hintText: '输入JSON格式的过程定义...',
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            onChanged: (value) {
              ref
                  .read(methodEditProvider.notifier)
                  .updateProcessDefinition(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSection(BuildContext context, MethodEditState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '参数表',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                // C4 fix: Don't pre-create placeholder, just show dialog
                // Parameter will be added via addParameterWithConfig when dialog confirms
                _showParameterDialog(context, null, null);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加参数'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.parameters.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Center(
              child: Text(
                '暂无参数配置',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          )
        else
          ...state.parameters.entries.map((entry) {
            final param = entry.value;
            return _buildParameterCard(context, entry.key, param, state);
          }).toList(),
      ],
    );
  }

  Widget _buildParameterCard(BuildContext context, String name,
      ParameterConfig param, MethodEditState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(param.type),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showParameterDialog(context, name, param),
                  tooltip: '编辑',
                ),
                IconButton(
                  key: Key('delete_param_$name'),
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () {
                    ref.read(methodEditProvider.notifier).removeParameter(name);
                  },
                  tooltip: '删除',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '默认值: ${param.defaultValue ?? '无'}${param.unit != null && param.unit!.isNotEmpty ? ' ${param.unit}' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (param.description != null && param.description!.isNotEmpty)
              Text(
                param.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationResult(BuildContext context, MethodEditState state) {
    final result = state.validationResult!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.valid
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.valid ? Icons.check_circle : Icons.error,
                color: result.valid
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Text(
                result.valid ? '验证通过' : '验证失败',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: result.valid
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          if (!result.valid && result.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.errors.map((e) => Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Text(
                    '• $e',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _showParameterDialog(BuildContext context, String? existingName,
      ParameterConfig? existingParam) {
    final notifier = ref.read(methodEditProvider.notifier);
    final state = ref.read(methodEditProvider);

    _paramNameController.text = existingName ?? '';
    _paramTypeController.text = existingParam?.type ?? 'number';
    _paramDefaultController.text =
        existingParam?.defaultValue?.toString() ?? '';
    _paramUnitController.text = existingParam?.unit ?? '';
    _paramDescController.text = existingParam?.description ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingName == null ? '添加参数' : '编辑参数'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _paramNameController,
                    decoration: const InputDecoration(
                      labelText: '参数名称 *',
                      border: OutlineInputBorder(),
                    ),
                    enabled: existingName == null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paramTypeController.text,
                    decoration: const InputDecoration(
                      labelText: '类型',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'number', child: Text('number')),
                      DropdownMenuItem(
                          value: 'integer', child: Text('integer')),
                      DropdownMenuItem(value: 'string', child: Text('string')),
                      DropdownMenuItem(
                          value: 'boolean', child: Text('boolean')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          _paramTypeController.text = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paramDefaultController,
                    decoration: const InputDecoration(
                      labelText: '默认值',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paramUnitController,
                    decoration: const InputDecoration(
                      labelText: '单位',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paramDescController,
                    decoration: const InputDecoration(
                      labelText: '描述',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = _paramNameController.text.trim();
                if (name.isEmpty) return;

                dynamic defaultValue;
                switch (_paramTypeController.text) {
                  case 'number':
                    defaultValue =
                        double.tryParse(_paramDefaultController.text);
                    break;
                  case 'integer':
                    defaultValue = int.tryParse(_paramDefaultController.text);
                    break;
                  case 'boolean':
                    defaultValue =
                        _paramDefaultController.text.toLowerCase() == 'true';
                    break;
                  default:
                    defaultValue = _paramDefaultController.text;
                }

                final param = ParameterConfig(
                  name: name,
                  type: _paramTypeController.text,
                  defaultValue: defaultValue,
                  unit: _paramUnitController.text.isEmpty
                      ? null
                      : _paramUnitController.text,
                  description: _paramDescController.text.isEmpty
                      ? null
                      : _paramDescController.text,
                );

                if (existingName != null) {
                  notifier.updateParameter(existingName, param);
                } else {
                  // C4 fix: Actually save the new parameter via notifier
                  notifier.addParameterWithConfig(param);
                }

                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMethod() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(methodEditProvider.notifier);
    final success = await notifier.saveMethod();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.methodId == null ? '方法创建成功' : '方法更新成功'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
      context.pop();
    }
  }

  // M9 fix: Show confirmation dialog when user has unsaved changes
  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃更改?'),
        content: const Text('您有未保存的更改，确定要放弃吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
