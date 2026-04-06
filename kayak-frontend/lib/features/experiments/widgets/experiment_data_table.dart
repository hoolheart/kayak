/// 试验数据表格
///
/// 显示试验列表数据
library;

import 'package:flutter/material.dart';
import '../models/experiment.dart';

/// 试验数据表格组件
class ExperimentDataTable extends StatelessWidget {
  final List<Experiment> experiments;
  final ValueChanged<Experiment> onViewDetails;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;

  const ExperimentDataTable({
    super.key,
    required this.experiments,
    required this.onViewDetails,
    required this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // 表头
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  _buildHeaderCell(context, '名称', flex: 3),
                  _buildHeaderCell(context, '状态'),
                  _buildHeaderCell(context, '开始时间', flex: 2),
                  _buildHeaderCell(context, '结束时间', flex: 2),
                  _buildHeaderCell(context, '操作'),
                ],
              ),
            ),

            // 表体
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  ...experiments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final experiment = entry.value;
                    final isEven = index % 2 == 0;

                    return Material(
                      color: isEven
                          ? colorScheme.surface
                          : colorScheme.surfaceContainerLowest,
                      child: InkWell(
                        onTap: () => onViewDetails(experiment),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              _buildDataCell(context, experiment.name, flex: 3),
                              _buildStatusCell(context, experiment.status),
                              _buildDataCell(
                                context,
                                _formatDateTime(experiment.startedAt),
                                flex: 2,
                              ),
                              _buildDataCell(
                                context,
                                _formatDateTime(experiment.endedAt),
                                flex: 2,
                              ),
                              _buildActionCell(context, experiment),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // 加载更多
                  if (hasMore)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: isLoadingMore
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : TextButton(
                              onPressed: onLoadMore,
                              child: const Text('加载更多'),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildDataCell(BuildContext context, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusCell(BuildContext context, ExperimentStatus status,
      {int flex = 1}) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ExperimentStatus.idle:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case ExperimentStatus.loaded:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      case ExperimentStatus.running:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case ExperimentStatus.paused:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case ExperimentStatus.completed:
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade700;
        break;
      case ExperimentStatus.aborted:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        break;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getStatusLabel(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCell(BuildContext context, Experiment experiment,
      {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextButton(
          onPressed: () => onViewDetails(experiment),
          child: const Text('查看'),
        ),
      ),
    );
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
