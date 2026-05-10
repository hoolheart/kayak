/// 分析页面
///
/// 时序数据可视化中心，包含控制面板和图表展示区。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/analysis_controller_provider.dart';
import '../widgets/control_panel.dart';
import '../widgets/data_preview_table.dart';
import '../widgets/time_series_chart.dart';

/// 分析页面
class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controlState = ref.watch(analysisControllerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1280;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Container(
                height: 56,
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '数据分析',
                      style: textTheme.titleLarge,
                    ),
                    Text(
                      '查看试验时序数据',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Main Workspace
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Control Panel
                    SizedBox(
                      width: isDesktop ? 320 : 280,
                      child: const ControlPanel(),
                    ),
                    const SizedBox(width: 16),
                    // Chart Area
                    Expanded(
                      child: Column(
                        children: [
                          const Expanded(
                            child: TimeSeriesChart(),
                          ),
                          // Data Preview
                          if (controlState.showDataTable) ...[
                            const SizedBox(height: 16),
                            const SizedBox(
                              height: 280,
                              child: DataPreviewTable(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
