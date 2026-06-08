import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/analysis_provider.dart';

/// DataTablePanel — 数据表格面板
///
/// 显示降采样后的时序数据，支持垂直滚动固定表头。
class DataTablePanel extends ConsumerWidget {
  const DataTablePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final chartValue = state.chartData.asData?.value;
    if (chartValue == null) {
      return const SizedBox.shrink();
    }

    if (!state.showDataTable || chartValue.isEmpty) {
      return const SizedBox.shrink();
    }

    final points = chartValue.points
        .where((p) => !state.hiddenPointIds.contains(p.pointId))
        .toList(growable: false);

    // 构建列
    final columns = <DataColumn>[
      DataColumn(
        label: Text(
          '时间戳',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...points.map(
        (point) => DataColumn(
          numeric: true,
          label: Text(
            '${point.pointName}${point.unit.isNotEmpty ? '(${point.unit})' : ''}',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ];

    // 构建行
    // 取第一个点的 timestamps 作为时间轴
    final timestamps = points.isNotEmpty ? points.first.timestamps : <DateTime>[];
    final rows = <DataRow>[];

    for (var i = 0; i < timestamps.length && i < 100; i++) {
      final ts = timestamps[i];
      final timeStr =
          '${ts.hour.toString().padLeft(2, '0')}:'
          '${ts.minute.toString().padLeft(2, '0')}:'
          '${ts.second.toString().padLeft(2, '0')}';

      final cells = <DataCell>[
        DataCell(Text(
          timeStr,
          style: textTheme.bodySmall,
        )),
        ...points.map((point) {
          final value = i < point.values.length ? point.values[i] : null;
          final valueStr = value != null ? value.toStringAsFixed(2) : '—';
          return DataCell(Text(
            valueStr,
            style: textTheme.bodySmall,
            textAlign: TextAlign.right,
          ));
        }),
      ];

      rows.add(DataRow(cells: cells));
    }

    final totalRows = points.isNotEmpty ? points.first.timestamps.length : 0;
    final displayedRows = rows.length;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Column(
          children: [
            // 行数提示（Issue 8）
            if (totalRows > displayedRows)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '显示前 $displayedRows 行 / 共 $totalRows 行',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Theme(
                  data: theme.copyWith(
                    dataTableTheme: DataTableThemeData(
                      headingRowColor: WidgetStateProperty.all(
                        colorScheme.surfaceContainerHighest,
                      ),
                      dataRowColor: WidgetStateProperty.all(colorScheme.surface),
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 48,
                      horizontalMargin: 16,
                    ),
                  ),
                  child: DataTable(
                    columns: columns,
                    rows: rows,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
