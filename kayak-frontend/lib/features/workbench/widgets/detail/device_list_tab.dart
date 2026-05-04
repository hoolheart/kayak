/// 设备列表Tab内容
///
/// 显示设备卡片列表，可展开查看测点表格
/// Figma设计：设备卡片 → 展开测点表格

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_schemes.dart';
import '../../models/device.dart';
import '../../models/point.dart';
import '../../providers/device_tree_provider.dart';
import '../../providers/point_list_provider.dart';

/// 设备列表Tab内容组件
class DeviceListTab extends ConsumerStatefulWidget {
  const DeviceListTab({
    super.key,
    required this.workbenchId,
  });
  final String workbenchId;

  @override
  ConsumerState<DeviceListTab> createState() => _DeviceListTabState();
}

class _DeviceListTabState extends ConsumerState<DeviceListTab> {
  String? _expandedDeviceId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(deviceTreeProvider(widget.workbenchId).notifier).loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceTreeProvider(widget.workbenchId));
    final colorScheme = Theme.of(context).colorScheme;

    // Loading
    if (state.isLoading && state.nodes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (state.error != null && state.nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(deviceTreeProvider(widget.workbenchId).notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // Empty
    if (state.nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('暂无设备', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '点击左侧「添加设备」按钮开始配置',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    // Device list
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(deviceTreeProvider(widget.workbenchId).notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.nodes.length,
        itemBuilder: (context, index) {
          final node = state.nodes[index];
          final isExpanded = _expandedDeviceId == node.device.id;
          return _DeviceCard(
            device: node.device,
            isExpanded: isExpanded,
            onTap: () {
              setState(() {
                _expandedDeviceId = isExpanded ? null : node.device.id;
              });
            },
          );
        },
      ),
    );
  }
}

/// 设备卡片组件
class _DeviceCard extends ConsumerStatefulWidget {
  const _DeviceCard({
    required this.device,
    required this.isExpanded,
    required this.onTap,
  });
  final Device device;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  ConsumerState<_DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends ConsumerState<_DeviceCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovering || widget.isExpanded
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            // 卡片头部
            InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // 设备图标
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.memory,
                        size: 20,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 设备名称
                    Expanded(
                      child: Text(
                        widget.device.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // Protocol Chip
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.device.protocolType.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                    // 连接/断开按钮
                    OutlinedButton(
                      onPressed: () {
                        // TODO: Toggle connection
                      },
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(48, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('连接', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    // 展开/折叠图标
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: widget.isExpanded ? 0.5 : 0,
                      child: const Icon(Icons.expand_more, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // 展开的测点表格
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: widget.isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: SizedBox(
                width: double.infinity,
                child: _buildPointTable(context),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointTable(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pointsAsync = ref.watch(pointListProvider(widget.device.id));

    return pointsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 28, color: colorScheme.error),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      data: (points) {
        if (points.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.sensors,
                  size: 32,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  '该设备暂无测点',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Table header
        return Column(
          children: [
            Divider(height: 1, color: colorScheme.outlineVariant),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
              child: const Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      '名称',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '类型',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '值',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '单位',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '状态',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...points.asMap().entries.map((entry) {
              final point = entry.value;
              final isEven = entry.key.isEven;
              final isActive = point.status == PointStatus.active;
              return Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isEven
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        point.name,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        _dataTypeLabel(point.dataType),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        point.defaultValue ?? '-',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        point.unit ?? '-',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    // Status dot
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colorScheme.success
                                  : colorScheme.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? '正常' : '禁用',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// Convert DataType enum to display label
  String _dataTypeLabel(DataType type) {
    return switch (type) {
      DataType.number => '数值',
      DataType.integer => '整数',
      DataType.string => '字符串',
      DataType.boolean => '布尔',
    };
  }
}
