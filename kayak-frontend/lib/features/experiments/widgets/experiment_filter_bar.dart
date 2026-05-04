/// 试验筛选工具栏
///
/// 提供状态筛选和日期范围筛选
library;

import 'package:flutter/material.dart';
import '../models/experiment.dart';

/// 试验筛选工具栏组件
class ExperimentFilterBar extends StatelessWidget {
  const ExperimentFilterBar({
    super.key,
    this.currentStatus,
    this.startDate,
    this.endDate,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onReset,
    required this.onRefresh,
  });
  final ExperimentStatus? currentStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<ExperimentStatus?> onStatusChanged;
  final void Function(DateTime?, DateTime?) onDateRangeChanged;
  final VoidCallback onReset;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          // 状态筛选
          _buildStatusFilter(context),
          const SizedBox(width: 16),

          // 日期范围筛选
          _buildDateRangeFilter(context),
          const SizedBox(width: 16),

          // 重置按钮
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.clear_all),
            label: const Text('重置'),
          ),
          const Spacer(),

          // 刷新按钮
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '状态:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        DropdownButton<ExperimentStatus?>(
          value: currentStatus,
          hint: const Text('全部'),
          items: [
            const DropdownMenuItem(
              child: Text('全部'),
            ),
            ...ExperimentStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusChip(context, status),
                    const SizedBox(width: 8),
                    Text(_getStatusLabel(status)),
                  ],
                ),
              );
            }),
          ],
          onChanged: onStatusChanged,
          underline: Container(
            height: 1,
            color: colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, ExperimentStatus status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '时间:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _showDateRangePicker(context),
          icon: const Icon(Icons.date_range, size: 18),
          label: Text(
            startDate != null || endDate != null
                ? '${_formatDate(startDate)} - ${_formatDate(endDate)}'
                : '选择日期范围',
          ),
        ),
      ],
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (result != null) {
      onDateRangeChanged(result.start, result.end);
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
