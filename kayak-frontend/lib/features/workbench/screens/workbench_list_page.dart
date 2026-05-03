/// 工作台列表页面
///
/// Figma设计：AppBar(标题+切换+添加) → 搜索筛选栏 → 网格/列表视图
/// 支持动画切换视图模式、搜索防抖、空状态、加载状态

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/workbench.dart';
import '../models/workbench_form_state.dart';
import '../models/workbench_list_state.dart';
import '../providers/view_mode_provider.dart';
import '../providers/workbench_list_provider.dart';
import '../providers/workbench_form_provider.dart';
import '../providers/search_provider.dart';
import '../services/workbench_service.dart';
import '../widgets/create_workbench_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/workbench_card.dart';
import '../widgets/workbench_list_tile.dart';

/// 工作台列表页面
class WorkbenchListPage extends ConsumerStatefulWidget {
  const WorkbenchListPage({super.key});

  @override
  ConsumerState<WorkbenchListPage> createState() => _WorkbenchListPageState();
}

class _WorkbenchListPageState extends ConsumerState<WorkbenchListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workbenchListProvider.notifier).loadWorkbenches();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(workbenchListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(workbenchListProvider);
    final viewMode = ref.watch(viewModeProvider);
    final filteredWorkbenches = ref.watch(filteredWorkbenchesProvider);
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('工作台'),
        actions: [
          // 视图切换按钮
          SegmentedButton<ViewMode>(
            segments: const [
              ButtonSegment(
                value: ViewMode.card,
                icon: Icon(Icons.grid_view, size: 20),
                tooltip: '网格视图',
              ),
              ButtonSegment(
                value: ViewMode.list,
                icon: Icon(Icons.list, size: 20),
                tooltip: '列表视图',
              ),
            ],
            selected: {viewMode},
            onSelectionChanged: (selection) {
              ref.read(viewModeProvider.notifier).setViewMode(selection.first);
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          // 添加按钮
          FilledButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('创建'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 搜索筛选栏
          const SearchFilterBar(),

          // 内容区域
          Expanded(
            child: _buildBody(
              listState,
              viewMode,
              filteredWorkbenches,
              searchState.query.isNotEmpty || searchState.statusFilter != null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    WorkbenchListState listState,
    ViewMode viewMode,
    List<Workbench> filteredWorkbenches,
    bool isFiltering,
  ) {
    // Loading state
    if (listState.isLoading && listState.workbenches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (listState.error != null && listState.workbenches.isEmpty) {
      return _buildErrorState(listState.error!);
    }

    // Empty state
    if (listState.workbenches.isEmpty) {
      return EmptyStateWidget(
        title: '暂无工作台',
        message: '点击上方按钮创建第一个工作台',
        icon: Icons.workspace_premium,
        actionLabel: '创建工作台',
        onAction: _showCreateDialog,
      );
    }

    // Search no results
    if (isFiltering && filteredWorkbenches.isEmpty) {
      return _buildNoResults();
    }

    // Content
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: viewMode == ViewMode.card
          ? _buildGridView(filteredWorkbenches, listState.hasMore)
          : _buildTableView(filteredWorkbenches, listState.hasMore),
    );
  }

  /// Build grid view
  Widget _buildGridView(List<Workbench> workbenches, bool hasMore) {
    return LayoutBuilder(
      key: const ValueKey('grid_view'),
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth > 1440) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 1024) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(workbenchListProvider.notifier).refresh(),
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 220,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: workbenches.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= workbenches.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final wb = workbenches[index];
              return WorkbenchCard(
                workbench: wb,
                onTap: () => _onWorkbenchTap(wb),
                onEdit: () => _showEditDialog(wb),
                onDelete: () => _showDeleteDialog(wb),
              );
            },
          ),
        );
      },
    );
  }

  /// Build table/list view
  Widget _buildTableView(List<Workbench> workbenches, bool hasMore) {
    return Column(
      key: const ValueKey('table_view'),
      children: [
        // 表头
        _buildTableHeader(),
        // 列表内容
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(workbenchListProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: workbenches.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= workbenches.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final wb = workbenches[index];
                return WorkbenchListTile(
                  workbench: wb,
                  index: index,
                  onTap: () => _onWorkbenchTap(wb),
                  onEdit: () => _showEditDialog(wb),
                  onDelete: () => _showDeleteDialog(wb),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Table header row
  Widget _buildTableHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 48), // 图标
          SizedBox(
            width: 200,
            child: Text('名称', style: TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 240,
            child: Text('描述', style: TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 80,
            child: Text('设备数', style: TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 100,
            child: Text('状态', style: TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 100,
            child: Text('创建时间', style: TextStyle(fontSize: 12)),
          ),
          SizedBox(width: 80),
        ],
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ref.read(workbenchListProvider.notifier).loadWorkbenches();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// No search results
  Widget _buildNoResults() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            '未找到匹配的工作台',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '尝试使用不同的关键词搜索',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.read(searchProvider.notifier).clear();
            },
            child: const Text('清除搜索'),
          ),
        ],
      ),
    );
  }

  void _onWorkbenchTap(Workbench workbench) {
    context.go('/workbenches/${workbench.id}');
  }

  Future<void> _showCreateDialog() async {
    ref.read(workbenchFormProvider.notifier).reset();
    final result = await showCreateWorkbenchDialog(context);
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('工作台创建成功')),
      );
    }
  }

  Future<void> _showEditDialog(Workbench workbench) async {
    ref.read(workbenchFormProvider.notifier).reset();
    final result = await showEditWorkbenchDialog(context, workbench);
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('工作台更新成功')),
      );
    }
  }

  Future<void> _showDeleteDialog(Workbench workbench) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      itemName: workbench.name,
    );

    if (confirmed == true) {
      try {
        await ref.read(workbenchServiceProvider).deleteWorkbench(workbench.id);
        ref.read(workbenchListProvider.notifier).removeWorkbench(workbench.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('工作台已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
}
