/// 试验列表页面
///
/// 显示所有试验记录
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../models/experiment.dart';
import '../providers/experiment_list_provider.dart';
import '../widgets/experiment_filter_bar.dart';
import '../widgets/experiment_data_table.dart';

/// 试验列表页面
class ExperimentListPage extends ConsumerStatefulWidget {
  const ExperimentListPage({super.key});

  @override
  ConsumerState<ExperimentListPage> createState() => _ExperimentListPageState();
}

class _ExperimentListPageState extends ConsumerState<ExperimentListPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时获取试验列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(experimentListProvider.notifier).loadExperiments(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(experimentListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 页面标题
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 32,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '试验记录',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (state.total > 0)
                  Text(
                    '共 ${state.total} 条记录',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),

          // 筛选工具栏
          ExperimentFilterBar(
            currentStatus: state.statusFilter,
            startDate: state.startDateFilter,
            endDate: state.endDateFilter,
            onStatusChanged: (status) {
              ref.read(experimentListProvider.notifier).setStatusFilter(status);
              ref
                  .read(experimentListProvider.notifier)
                  .loadExperiments(reset: true);
            },
            onDateRangeChanged: (start, end) {
              ref
                  .read(experimentListProvider.notifier)
                  .setDateRange(start, end);
              ref
                  .read(experimentListProvider.notifier)
                  .loadExperiments(reset: true);
            },
            onReset: () {
              ref.read(experimentListProvider.notifier).clearFilters();
              ref
                  .read(experimentListProvider.notifier)
                  .loadExperiments(reset: true);
            },
            onRefresh: () {
              ref.read(experimentListProvider.notifier).refresh();
            },
          ),

          // 错误提示
          if (state.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.close, color: colorScheme.onErrorContainer),
                    onPressed: () {
                      ref.read(experimentListProvider.notifier).refresh();
                    },
                  ),
                ],
              ),
            ),

          // 数据表格
          Expanded(
            child: state.isLoading && state.experiments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.experiments.isEmpty
                    ? _buildEmptyState(context)
                    : ExperimentDataTable(
                        experiments: state.experiments,
                        onViewDetails: (experiment) {
                          context.go('/experiments/${experiment.id}');
                        },
                        onLoadMore: () {
                          ref.read(experimentListProvider.notifier).loadMore();
                        },
                        isLoadingMore: state.isLoading,
                        hasMore: state.hasNext,
                      ),
          ),

          // 分页信息
          if (state.experiments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '第 ${state.page} 页',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  if (state.hasNext)
                    TextButton(
                      onPressed: () {
                        ref.read(experimentListProvider.notifier).loadMore();
                      },
                      child: const Text('加载更多'),
                    ),
                ],
              ),
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
            Icons.science_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无试验记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始一个新试验来查看数据',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}
