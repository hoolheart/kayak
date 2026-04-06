/// 工作台列表页面
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workbench.dart';
import '../models/workbench_form_state.dart';
import '../models/workbench_list_state.dart';
import '../providers/view_mode_provider.dart';
import '../providers/workbench_list_provider.dart';
import '../providers/workbench_form_provider.dart';
import '../services/workbench_service.dart';
import '../widgets/create_workbench_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_state_widget.dart';
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
    // 初始加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workbenchListProvider.notifier).loadWorkbenches();
    });

    // 监听滚动用于加载更多
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('工作台'),
        actions: [
          // 视图切换按钮
          SegmentedButton<ViewMode>(
            segments: const [
              ButtonSegment(
                value: ViewMode.card,
                icon: Icon(Icons.grid_view),
                tooltip: '网格视图',
              ),
              ButtonSegment(
                value: ViewMode.list,
                icon: Icon(Icons.list),
                tooltip: '列表视图',
              ),
            ],
            selected: {viewMode},
            onSelectionChanged: (selection) {
              ref.read(viewModeProvider.notifier).setViewMode(selection.first);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(listState, viewMode),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('创建工作台'),
      ),
    );
  }

  Widget _buildBody(WorkbenchListState listState, ViewMode viewMode) {
    if (listState.isLoading && listState.workbenches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (listState.error != null && listState.workbenches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(listState.error!),
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

    if (listState.workbenches.isEmpty) {
      return EmptyStateWidget(
        title: '暂无工作台',
        message: '点击下方按钮创建第一个工作台',
        actionLabel: '创建工作台',
        onAction: _showCreateDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(workbenchListProvider.notifier).refresh(),
      child: viewMode == ViewMode.card
          ? _buildGridView(listState)
          : _buildListView(listState),
    );
  }

  Widget _buildGridView(WorkbenchListState listState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 响应式列数
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth > 1440) {
          crossAxisCount = 4;
          childAspectRatio = 1.4;
        } else if (constraints.maxWidth > 1024) {
          crossAxisCount = 3;
          childAspectRatio = 1.4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 1.5;
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: listState.workbenches.length + (listState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= listState.workbenches.length) {
              return const Center(child: CircularProgressIndicator());
            }

            final workbench = listState.workbenches[index];
            return WorkbenchCard(
              workbench: workbench,
              onTap: () => _onWorkbenchTap(workbench),
              onEdit: () => _showEditDialog(workbench),
              onDelete: () => _showDeleteDialog(workbench),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(WorkbenchListState listState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: listState.workbenches.length + (listState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= listState.workbenches.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final workbench = listState.workbenches[index];
        return WorkbenchListTile(
          workbench: workbench,
          onTap: () => _onWorkbenchTap(workbench),
          onEdit: () => _showEditDialog(workbench),
          onDelete: () => _showDeleteDialog(workbench),
        );
      },
    );
  }

  void _onWorkbenchTap(Workbench workbench) {
    // TODO: 导航到工作台详情页 (S1-015)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('点击了工作台: ${workbench.name}')),
    );
  }

  Future<void> _showCreateDialog() async {
    ref.read(workbenchFormProvider.notifier).reset();
    final result = await showCreateWorkbenchDialog(context);
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('工作台创建成功')),
        );
      }
    }
  }

  Future<void> _showEditDialog(Workbench workbench) async {
    ref.read(workbenchFormProvider.notifier).reset();
    final result = await showEditWorkbenchDialog(context, workbench);
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('工作台更新成功')),
        );
      }
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
