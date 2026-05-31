import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/app_localizations.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../providers/services.dart';
import 'async_value_widget.dart';
import 'confirm_dialog.dart';
import 'device_config_dialog.dart';
import 'empty_view.dart';
import 'toast.dart';

// ============================================================
// DeviceTree — 设备树组件
//
// 树形展示设备层级结构，支持展开/折叠、选中、上下文菜单等操作。
//
// 用法：
// ```dart
// DeviceTree(
//   workbenchId: 'wb-1',
//   onDeviceSelected: (deviceId) { ... },
// )
// ```
// ============================================================

/// DeviceTree — 设备树组件
///
/// 使用 [deviceTreeProvider] 加载设备树数据，递归渲染树节点。
/// 支持加载/空/错误三种状态，选中态通过回调通知父组件。
class DeviceTree extends ConsumerStatefulWidget {
  const DeviceTree({
    super.key,
    required this.workbenchId,
    this.onDeviceSelected,
    this.selectedDeviceId,
  });

  /// 工作台 ID
  final String workbenchId;

  /// 设备选中回调
  final ValueChanged<String>? onDeviceSelected;

  /// 当前选中的设备 ID
  final String? selectedDeviceId;

  @override
  ConsumerState<DeviceTree> createState() => _DeviceTreeState();
}

class _DeviceTreeState extends ConsumerState<DeviceTree> {
  /// 展开的节点 ID 集合
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    // 默认展开第一层节点（根节点第一次 build 时无子节点，后续 state 刷新时展开）
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final treeState = ref.watch(deviceTreeProvider(widget.workbenchId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 面板头部
        _buildPanelHeader(l10n, treeState),
        const Divider(height: 1),
        // 树内容
        Expanded(
          child: AsyncValueWidget<List<DeviceTreeNode>>(
            value: treeState,
            onRetry: () =>
                ref.invalidate(deviceTreeProvider(widget.workbenchId)),
            loadingBuilder: _buildTreeSkeleton(),
            emptyBuilder: EmptyView(
              icon: Icons.device_hub_outlined,
              title: l10n.noDevices,
              compact: true,
            ),
            dataBuilder: (nodes) => _buildTreeList(nodes, l10n),
          ),
        ),
      ],
    );
  }

  /// 面板头部
  Widget _buildPanelHeader(
    AppLocalizations l10n,
    AsyncValue<List<DeviceTreeNode>> treeState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final deviceCount = treeState.asData?.value.length ?? 0;

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
          Text(
            l10n.deviceTreeTitle,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          // 数量标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$deviceCount',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          // 添加设备按钮
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: const Icon(Icons.add, size: 20),
              padding: EdgeInsets.zero,
              color: colorScheme.primary,
              onPressed: () => _showAddDialog(l10n),
              tooltip: l10n.addDevice,
            ),
          ),
        ],
      ),
    );
  }

  /// 树内容骨架屏
  Widget _buildTreeSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: List.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.only(
            left: index.isEven ? 16.0 : 40.0,
            right: 16,
            bottom: 12,
          ),
          child: Row(
            children: [
              // 圆形图标占位
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // 圆形状态点占位
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // 名称占位
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(128),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 递归构建树节点列表
  Widget _buildTreeList(List<DeviceTreeNode> nodes, AppLocalizations l10n) {
    if (nodes.isEmpty) {
      return EmptyView(
        icon: Icons.device_hub_outlined,
        title: l10n.noDevices,
        compact: true,
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: nodes.map((node) {
        return _buildTreeNode(node, 0, l10n);
      }).toList(),
    );
  }

  /// 构建树节点（递归）
  Widget _buildTreeNode(
    DeviceTreeNode node,
    int depth,
    AppLocalizations l10n,
  ) {
    final hasChildren = node.children.isNotEmpty;
    final isExpanded = _expandedIds.contains(node.id);
    final isSelected = widget.selectedDeviceId == node.id;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 协议图标
    final protocolIcon = _protocolIcon(node.protocolType);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 节点行
        InkWell(
          onTap: () {
            widget.onDeviceSelected?.call(node.id);
          },
          onDoubleTap: hasChildren
              ? () => _toggleExpand(node.id)
              : null,
          child: Container(
            height: 40,
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 24.0),
              right: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withAlpha(20)
                  : null,
              border: isSelected
                  ? Border(
                      left: BorderSide(
                        color: colorScheme.primary,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // 展开图标
                SizedBox(
                  width: 20,
                  height: 20,
                  child: hasChildren
                      ? GestureDetector(
                          onTap: () => _toggleExpand(node.id),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : const SizedBox(width: 20),
                ),
                const SizedBox(width: 8),
                // 协议图标
                Icon(
                  protocolIcon,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                // 状态圆点
                _StatusDot(status: node.status),
                const SizedBox(width: 8),
                // 名称
                Expanded(
                  child: Text(
                    node.name,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 上下文菜单（选中或悬停时显示）
                if (isSelected)
                  _ContextMenuButton(
                    node: node,
                    l10n: l10n,
                    onEdit: () => _showEditDialog(node, l10n),
                    onAddSub: () => _showAddSubDialog(node, l10n),
                    onDelete: () => _showDeleteConfirm(node, l10n),
                  ),
              ],
            ),
          ),
        ),
        // 子节点（展开时）
        if (hasChildren && isExpanded)
          ...node.children.map((child) {
            return _buildTreeNode(child, depth + 1, l10n);
          }),
      ],
    );
  }

  /// 获取协议图标
  IconData _protocolIcon(ProtocolType type) {
    switch (type) {
      case ProtocolType.virtual:
        return Icons.memory;
      case ProtocolType.modbusTcp:
        return Icons.lan;
      case ProtocolType.modbusRtu:
        return Icons.cable;
      case ProtocolType.can:
        return Icons.cable;
      case ProtocolType.visa:
        return Icons.usb;
      case ProtocolType.mqtt:
        return Icons.hub;
    }
  }

  /// 展开/折叠节点
  void _toggleExpand(String nodeId) {
    setState(() {
      if (_expandedIds.contains(nodeId)) {
        _expandedIds.remove(nodeId);
      } else {
        _expandedIds.add(nodeId);
      }
    });
  }

  /// 显示添加设备对话框
  void _showAddDialog(AppLocalizations l10n) {
    DeviceConfigDialog.show(
      context: context,
      ref: ref,
      workbenchId: widget.workbenchId,
    );
  }

  /// 显示添加子设备对话框
  void _showAddSubDialog(DeviceTreeNode node, AppLocalizations l10n) {
    DeviceConfigDialog.show(
      context: context,
      ref: ref,
      workbenchId: widget.workbenchId,
      parentId: node.id,
    );
  }

  /// 显示编辑设备对话框
  void _showEditDialog(DeviceTreeNode node, AppLocalizations l10n) {
    DeviceConfigDialog.show(
      context: context,
      ref: ref,
      workbenchId: widget.workbenchId,
      device: node,
    );
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirm(
    DeviceTreeNode node,
    AppLocalizations l10n,
  ) async {
    await ConfirmDialog.show(
      context: context,
      title: l10n.deviceDeleteTitle,
      description: l10n.deviceDeleteDescription(node.name),
      confirmLabel: l10n.confirmDeleteDevice,
      onConfirm: () => _handleDelete(node, l10n),
      isDanger: true,
    );
  }

  /// 执行删除操作
  Future<void> _handleDelete(
    DeviceTreeNode node,
    AppLocalizations l10n,
  ) async {
    try {
      final service = ref.read(deviceServiceProvider);
      await service.delete(node.id);
      // 刷新设备树
      ref.invalidate(deviceTreeProvider(widget.workbenchId));

      if (!mounted) return;
      Toast.show(
        context: context,
        message: l10n.deviceDeleteSuccess,
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context: context,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }
}

// ============================================================
// _StatusDot — 状态圆点
// ============================================================

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    Color dotColor;
    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
      case 'running':
        dotColor = brightness == Brightness.light
            ? const Color(0xFF2E7D32)
            : const Color(0xFF81C784);
        break;
      case 'offline':
      case 'inactive':
      case 'stopped':
        dotColor = colorScheme.onSurfaceVariant;
        break;
      case 'error':
      case 'failed':
        dotColor = brightness == Brightness.light
            ? const Color(0xFFBA1A1A)
            : const Color(0xFFFFB4AB);
        break;
      default:
        dotColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: brightness == Brightness.light
              ? Colors.white
              : colorScheme.surface,
        ),
      ),
    );
  }
}

// ============================================================
// _ContextMenuButton — 上下文菜单按钮
// ============================================================

class _ContextMenuButton extends StatelessWidget {
  const _ContextMenuButton({
    required this.node,
    required this.l10n,
    required this.onEdit,
    required this.onAddSub,
    required this.onDelete,
  });

  final DeviceTreeNode node;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onAddSub;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
              break;
            case 'add_sub':
              onAddSub();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: const Icon(Icons.edit_outlined, size: 20),
              title: Text(l10n.editDevice),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          PopupMenuItem(
            value: 'add_sub',
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline, size: 20),
              title: Text(l10n.addSubDevice),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(
                Icons.delete_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.deleteDevice,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
    );
  }
}
