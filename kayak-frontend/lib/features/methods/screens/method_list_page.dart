/// Method list page
///
/// Displays all methods with CRUD operations
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/method.dart';
import '../providers/method_list_provider.dart';

/// Method list page
class MethodListPage extends ConsumerStatefulWidget {
  const MethodListPage({super.key});

  @override
  ConsumerState<MethodListPage> createState() => _MethodListPageState();
}

class _MethodListPageState extends ConsumerState<MethodListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(methodListProvider.notifier).loadMethods();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(methodListProvider);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoadingMore) {
      ref.read(methodListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(methodListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('方法管理'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.push('/methods/create'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('创建方法'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.methods.isEmpty
              ? _buildErrorState(context, state.error!)
              : state.methods.isEmpty
                  ? _buildEmptyState(context)
                  : _buildContent(context, state),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(methodListProvider.notifier).loadMethods();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无方法',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建第一个试验方法开始自动化测试',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/methods/create'),
            icon: const Icon(Icons.add),
            label: const Text('创建方法'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MethodListState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.methods.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.methods.length) {
          return _buildLoadMoreIndicator(context);
        }

        final method = state.methods[index];
        return _buildMethodCard(context, method, state);
      },
    );
  }

  Widget _buildMethodCard(
    BuildContext context,
    Method method,
    MethodListState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/methods/${method.id}/edit'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    key: Key('edit_method_${method.id}'),
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => context.push('/methods/${method.id}/edit'),
                    tooltip: '编辑',
                  ),
                  IconButton(
                    key: Key('delete_method_${method.id}'),
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _showDeleteDialog(context, method),
                    tooltip: '删除',
                  ),
                ],
              ),
              if (method.description != null &&
                  method.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  method.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '创建于 ${_formatDateTime(method.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  void _showDeleteDialog(BuildContext context, Method method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除方法'),
        content: Text('确定要删除"${method.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            key: Key('confirm_delete_${method.id}'),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(methodListProvider.notifier).deleteMethod(method.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
