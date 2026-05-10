/// 数据预览表格组件
///
/// 显示时序数据的表格预览，可折叠展开。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chart_data_provider.dart';
import '../theme/chart_colors.dart';

/// 数据预览表格
class DataPreviewTable extends ConsumerWidget {
  const DataPreviewTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chartState = ref.watch(chartDataProvider);

    if (chartState.data == null || chartState.data!.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final data = chartState.data!;
    final brightness = Theme.of(context).brightness;
    final curveColors = ChartColors.getCurves(brightness);
    const maxRows = 100;

    // Build table rows
    final points = data.points;
    final timestamps = points.first.timestamps;
    final rowCount = timestamps.length > maxRows ? maxRows : timestamps.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '数据预览',
                  style: textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '共 ${timestamps.length} 行',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Table
          Flexible(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    colorScheme.surfaceContainerLow,
                  ),
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 36,
                  columns: [
                    const DataColumn(
                      label: SizedBox(
                        width: 160,
                        child: Text('时间戳'),
                      ),
                    ),
                    ...points.asMap().entries.map((entry) {
                      final index = entry.key;
                      final series = entry.value;
                      return DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: curveColors[index % curveColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${series.pointName} (${series.unit})'),
                          ],
                        ),
                      );
                    }),
                  ],
                  rows: List.generate(rowCount, (rowIndex) {
                    final ts = timestamps[rowIndex];
                    final dt = DateTime.fromMillisecondsSinceEpoch(ts);

                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return colorScheme.tableRowHoverBackground;
                        }
                        return rowIndex.isEven
                            ? colorScheme.tableRowEvenBackground
                            : colorScheme.surface;
                      }),
                      cells: [
                        DataCell(
                          Text(
                            _formatTimestamp(dt),
                            style: textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        ...points.map((series) {
                          final value = rowIndex < series.values.length
                              ? series.values[rowIndex]
                              : null;
                          return DataCell(
                            Text(
                              value != null
                                  ? value.toStringAsFixed(2)
                                  : '--',
                              style: textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
