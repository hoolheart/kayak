/// Modbus 测点配置对话框
///
/// 提供完整的 Modbus 测点配置界面，包括：
///   - 功能码选择、地址/数量输入、数据类型选择、缩放/偏移输入
///   - 测点列表增删操作（含地址重叠检测）
///   - 配置验证
///   - 提交/取消操作
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/modbus_point_config.dart';
import '../../providers/point_config_provider.dart';
import 'point_config_form.dart';
import 'point_config_list_item.dart';

/// 测点配置对话框回调
typedef PointConfigSubmitCallback = void Function(
    List<ModbusPointConfig> configs);

/// 测点配置对话框
class PointConfigDialog extends ConsumerStatefulWidget {
  /// 设备名称 (用于标题)
  final String deviceName;

  /// 设备ID
  final String deviceId;

  /// 已有的测点配置列表 (编辑模式下预填充)
  final List<ModbusPointConfig>? existingConfigs;

  /// 提交回调
  final PointConfigSubmitCallback? onSubmit;

  const PointConfigDialog({
    super.key,
    required this.deviceName,
    required this.deviceId,
    this.existingConfigs,
    this.onSubmit,
  });

  @override
  ConsumerState<PointConfigDialog> createState() => _PointConfigDialogState();
}

class _PointConfigDialogState extends ConsumerState<PointConfigDialog> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 预加载已有配置
    if (widget.existingConfigs != null && widget.existingConfigs!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final listNotifier = ref.read(pointConfigListProvider.notifier);
        for (final config in widget.existingConfigs!) {
          listNotifier.addConfig(config);
        }
      });
    }
  }

  @override
  void dispose() {
    // 清理状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      // ref.read is not valid in dispose, so we handle state reset elsewhere
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configList = ref.watch(pointConfigListProvider);
    final formNotifier = ref.read(pointConfigFormProvider.notifier);
    final listNotifier = ref.read(pointConfigListProvider.notifier);

    return AlertDialog(
      key: Key('point-config-dialog-${widget.deviceId}'),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '测点配置 - ${widget.deviceName}',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
          minWidth: 480,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 配置表单
            _buildFormSection(theme),
            const Divider(height: 32),
            // 已配置列表
            _buildListSection(theme, configList, formNotifier, listNotifier),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: _buildActions(theme, configList, formNotifier, listNotifier),
    );
  }

  /// 表单区域
  Widget _buildFormSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '配置测点',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const PointConfigForm(),
        const SizedBox(height: 12),
        // 添加/更新按钮
        _buildAddUpdateButton(theme),
      ],
    );
  }

  /// 添加/更新按钮
  Widget _buildAddUpdateButton(ThemeData theme) {
    final formNotifier = ref.read(pointConfigFormProvider.notifier);
    final listNotifier = ref.read(pointConfigListProvider.notifier);
    final isEditing = formNotifier.isEditing;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: Icon(isEditing ? Icons.check : Icons.add),
        label: Text(isEditing ? '更新测点' : '添加测点到列表'),
        onPressed: () => _handleAddUpdate(formNotifier, listNotifier),
      ),
    );
  }

  /// 处理添加/更新操作
  void _handleAddUpdate(
    PointConfigFormNotifier formNotifier,
    PointConfigListNotifier listNotifier,
  ) {
    // 验证表单
    if (!formNotifier.validate()) {
      _showSnackBar('请检查表单中的错误', isError: true);
      return;
    }

    final formState = ref.read(pointConfigFormProvider);
    final config = formState.tryCreateConfig();
    if (config == null) {
      _showSnackBar('表单数据无效', isError: true);
      return;
    }

    bool success;
    if (formNotifier.isEditing) {
      success = listNotifier.updateConfig(formNotifier.editingIndex, config);
    } else {
      success = listNotifier.addConfig(config);
    }

    if (!success) {
      // 地址重叠冲突
      _showSnackBar(
        '地址范围与已有测点冲突，请修改地址或数量后重试',
        isError: true,
      );
      return;
    }

    formNotifier.reset();
    _showSnackBar(
      formNotifier.isEditing ? '测点已更新' : '测点已添加',
      isError: false,
    );
  }

  /// 已配置列表区域
  Widget _buildListSection(
    ThemeData theme,
    List<ModbusPointConfig> configList,
    PointConfigFormNotifier formNotifier,
    PointConfigListNotifier listNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题行
        Row(
          children: [
            Icon(Icons.list, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '已配置测点',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            if (configList.isNotEmpty) ...[
              Text(
                '共 ${configList.length} 个测点',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('清空'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () => _confirmClearAll(listNotifier),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // 列表内容
        if (configList.isEmpty)
          _buildEmptyState(theme)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: configList.length,
              itemBuilder: (context, index) {
                final config = configList[index];
                return PointConfigListItem(
                  config: config,
                  index: index,
                  onEdit: () => formNotifier.loadForEdit(index, config),
                  onDelete: () => listNotifier.removeConfig(index),
                );
              },
            ),
          ),
      ],
    );
  }

  /// 空列表状态
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.add_circle_outline,
              size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            '暂未配置测点',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '请在上方完成配置后点击"添加测点到列表"',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 清空确认
  Future<void> _confirmClearAll(PointConfigListNotifier listNotifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空所有测点？'),
        content: const Text('将移除列表中所有已配置的测点，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      listNotifier.clearAll();
      ref.read(pointConfigFormProvider.notifier).reset();
    }
  }

  /// 底部操作按钮
  List<Widget> _buildActions(
    ThemeData theme,
    List<ModbusPointConfig> configList,
    PointConfigFormNotifier formNotifier,
    PointConfigListNotifier listNotifier,
  ) {
    return [
      TextButton(
        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: _isSubmitting ? null : () => _handleSubmit(configList),
        child: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : const Text('保存配置'),
      ),
    ];
  }

  /// 提交配置
  Future<void> _handleSubmit(List<ModbusPointConfig> configList) async {
    setState(() => _isSubmitting = true);

    try {
      if (widget.onSubmit != null) {
        widget.onSubmit!(List.from(configList));
      }
      if (mounted) {
        Navigator.of(context).pop(configList);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存失败: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 显示 SnackBar 消息
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? theme.colorScheme.error : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
