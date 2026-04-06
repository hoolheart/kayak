/// 试验详情页面
///
/// 显示试验详细信息和测点历史数据
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/experiment.dart';
import '../../models/experiment_detail_state.dart';
import '../../providers/experiment_detail_provider.dart';

/// 试验详情页面
class ExperimentDetailPage extends ConsumerStatefulWidget {
  final String experimentId;

  const ExperimentDetailPage({
    super.key,
    required this.experimentId,
  });

  @override
  ConsumerState<ExperimentDetailPage> createState() =>
      _ExperimentDetailPageState();
}

class _ExperimentDetailPageState extends ConsumerState<ExperimentDetailPage> {
  String _selectedChannel = 'default';
  bool _historyAutoLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(experimentDetailProvider.notifier)
          .loadExperiment(widget.experimentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(experimentDetailProvider);

    // Auto-load history after experiment is loaded
    if (state.experiment != null && !_historyAutoLoaded) {
      _historyAutoLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(experimentDetailProvider.notifier).loadPointHistory(
            widget.experimentId, _selectedChannel,
            reset: true);
      });
    }

    return Scaffold(
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorState(context, state.error!)
              : state.experiment == null
                  ? _buildNotFoundState(context)
                  : _buildContent(context, state),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('retry_button'),
            onPressed: () {
              ref
                  .read(experimentDetailProvider.notifier)
                  .loadExperiment(widget.experimentId);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '试验不存在',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/experiments'),
            child: const Text('返回列表'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExperimentDetailState state) {
    final experiment = state.experiment!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 头部导航
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.go('/experiments'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  experiment.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _buildStatusChip(experiment.status),
            ],
          ),
        ),

        // 试验信息卡片
        Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '试验信息',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('ID', experiment.id),
                  if (experiment.description != null)
                    _buildInfoRow('描述', experiment.description!),
                  _buildInfoRow('开始时间', _formatDateTime(experiment.startedAt)),
                  _buildInfoRow('结束时间', _formatDateTime(experiment.endedAt)),
                  _buildInfoRow('创建时间', _formatDateTime(experiment.createdAt)),
                ],
              ),
            ),
          ),
        ),

        // 测点历史数据
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                '测点数据',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              // 通道选择下拉框
              DropdownButton<String>(
                key: const Key('channel_selector'),
                value: _selectedChannel,
                items: const [
                  DropdownMenuItem(value: 'default', child: Text('default')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedChannel = value;
                    });
                    ref
                        .read(experimentDetailProvider.notifier)
                        .loadPointHistory(
                          widget.experimentId,
                          value,
                          reset: true,
                        );
                  }
                },
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                key: const Key('export_csv_button'),
                onPressed: state.pointHistory.isEmpty
                    ? null
                    : () => _exportCsv(context),
                icon: const Icon(Icons.download),
                label: const Text('导出CSV'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ref.read(experimentDetailProvider.notifier).loadPointHistory(
                        widget.experimentId,
                        _selectedChannel,
                        reset: true,
                      );
                },
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
              ),
            ],
          ),
        ),

        // 数据表格
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: state.isLoadingHistory && state.pointHistory.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.pointHistory.isEmpty
                    ? _buildEmptyHistoryState(context)
                    : _buildHistoryTable(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ExperimentStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ExperimentStatus.idle:
        backgroundColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        break;
      case ExperimentStatus.loaded:
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        break;
      case ExperimentStatus.running:
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        break;
      case ExperimentStatus.paused:
        backgroundColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        break;
      case ExperimentStatus.completed:
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        break;
      case ExperimentStatus.aborted:
        backgroundColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无测点数据',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '测点数据将在试验运行时生成',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context, ExperimentDetailState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 表头
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildHeaderCell(context, '时间', flex: 2)),
              Expanded(child: _buildHeaderCell(context, '数值')),
            ],
          ),
        ),
        // 表体
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: ListView.builder(
              itemCount:
                  state.pointHistory.length + (state.hasMoreHistory ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.pointHistory.length) {
                  return _buildLoadMoreButton(context, state);
                }

                final point = state.pointHistory[index];
                final isEven = index % 2 == 0;

                return Container(
                  color: isEven
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerLowest,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          point.timestamp.toIso8601String(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point.value.toStringAsFixed(4),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(
      BuildContext context, ExperimentDetailState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: state.isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : TextButton(
              onPressed: () {
                ref.read(experimentDetailProvider.notifier).loadPointHistory(
                      widget.experimentId,
                      _selectedChannel,
                    );
              },
              child: const Text('加载更多'),
            ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final csv =
          await ref.read(experimentDetailProvider.notifier).exportToCsv();

      // Save to file
      final experiment = ref.read(experimentDetailProvider).experiment!;
      final fileName =
          '${experiment.name}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(fileName);
      await file.writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已导出到: $fileName'),
            action: SnackBarAction(
              label: '确定',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getStatusLabel(ExperimentStatus status) {
    switch (status) {
      case ExperimentStatus.idle:
        return '空闲';
      case ExperimentStatus.loaded:
        return '已载入';
      case ExperimentStatus.running:
        return '运行中';
      case ExperimentStatus.paused:
        return '已暂停';
      case ExperimentStatus.completed:
        return '已完成';
      case ExperimentStatus.aborted:
        return '已中止';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
