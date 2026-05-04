/// 工作台详情页面
///
/// Figma设计：AppBar → 信息区 → 左右分栏(设备树 280px + 内容区)
/// 左侧设备树，右侧 Tab 导航（设备列表/设置）

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/workbench_detail_state.dart';
import '../../providers/device_tree_provider.dart';
import '../../providers/workbench_detail_provider.dart';
import '../../services/workbench_service.dart';
import '../../widgets/create_workbench_dialog.dart';
import '../../widgets/detail/detail_header.dart';
import '../../widgets/detail/detail_tab_bar.dart';
import '../../widgets/detail/device_list_tab.dart';
import '../../widgets/detail/settings_tab.dart';
import '../../widgets/device/device_form_dialog.dart';
import '../../widgets/device_tree/device_tree.dart';

/// 工作台详情页面
class WorkbenchDetailPage extends ConsumerStatefulWidget {
  const WorkbenchDetailPage({
    super.key,
    required this.workbenchId,
  });
  final String workbenchId;

  @override
  ConsumerState<WorkbenchDetailPage> createState() =>
      _WorkbenchDetailPageState();
}

class _WorkbenchDetailPageState extends ConsumerState<WorkbenchDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load workbench detail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(workbenchDetailProvider(widget.workbenchId).notifier)
          .loadWorkbench(widget.workbenchId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(workbenchDetailProvider(widget.workbenchId));
    final isWideScreen = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/workbenches'),
        ),
        title: Text(detailState.workbench?.name ?? '工作台详情'),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              final workbench = detailState.workbench;
              if (workbench == null) return;
              final result = await showEditWorkbenchDialog(context, workbench);
              if (result == true && mounted) {
                ref
                    .read(workbenchDetailProvider(widget.workbenchId).notifier)
                    .refresh();
              }
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('编辑'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              _showDeleteDialog(context);
            },
            icon: Icon(
              Icons.delete_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              '删除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(detailState, isWideScreen),
    );
  }

  Widget _buildBody(WorkbenchDetailState detailState, bool isWideScreen) {
    // Loading state
    if (detailState.isLoading && detailState.workbench == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (detailState.error != null && detailState.workbench == null) {
      return _buildErrorView(detailState.error!);
    }

    // No data
    if (detailState.workbench == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final workbench = detailState.workbench!;

    return Column(
      children: [
        // ===== 信息头部区域 =====
        DetailHeader(
          workbench: workbench,
        ),

        // ===== 主内容区：左右分栏 =====
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧设备树面板
              if (isWideScreen) ...[
                SizedBox(
                  width: 280,
                  child: _buildDeviceTreePanel(),
                ),
                // 垂直分隔线
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ],

              // 右侧内容区
              Expanded(
                child: Column(
                  children: [
                    // Tab Bar
                    ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      child: DetailTabBar(tabController: _tabController),
                    ),
                    // Tab 内容
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          DeviceListTab(workbenchId: widget.workbenchId),
                          SettingsTab(workbench: workbench),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 设备树面板
  Widget _buildDeviceTreePanel() {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        children: [
          // 添加设备按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => DeviceFormDialog(
                      workbenchId: widget.workbenchId,
                    ),
                  );
                  if (result == true && mounted) {
                    ref
                        .read(deviceTreeProvider(widget.workbenchId).notifier)
                        .refresh();
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加设备'),
              ),
            ),
          ),
          const Divider(height: 1),
          // 设备树列表
          Expanded(
            child: DeviceTree(workbenchId: widget.workbenchId),
          ),
        ],
      ),
    );
  }

  /// Error view
  Widget _buildErrorView(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    String errorMessage = '加载失败，请重试';
    if (error.contains('404') || error.contains('NotFound')) {
      errorMessage = '工作台不存在或已被删除';
    } else if (error.contains('403') || error.contains('Forbidden')) {
      errorMessage = '无权访问此工作台';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(workbenchDetailProvider(widget.workbenchId).notifier)
                  .refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        var isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: const Text('确定要删除此工作台吗？此操作不可撤销。'),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            final router = GoRouter.of(context);
                            await ref
                                .read(workbenchServiceProvider)
                                .deleteWorkbench(widget.workbenchId);
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            router.go('/workbenches');
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('删除失败: $e'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('删除'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
