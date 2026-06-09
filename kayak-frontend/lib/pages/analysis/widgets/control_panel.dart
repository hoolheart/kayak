import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import '../../../providers/analysis_provider.dart';
import 'device_dropdown.dart';
import 'downsample_slider.dart';
import 'experiment_dropdown.dart';
import 'point_checkbox_list.dart';
import 'time_range_selector.dart';

/// ControlPanel — 数据分析控制面板
///
/// 包含试验/设备/测点选择、时间范围、降采样和操作按钮。
class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final notifier = ref.read(analysisProvider.notifier);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final hasChartData = state.chartData.hasValue &&
        state.chartData.value != null &&
        !state.chartData.value!.isEmpty;

    // Responsive width: desktop >1200px uses 350px, tablet 600-1200px uses 280px
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth > 1200 ? 350.0 : 280.0;

    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(128),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Experiment selection
            const ExperimentDropdown(),
            const _DividerWithSpacing(),

            // Device selection
            const DeviceDropdown(),
            const _DividerWithSpacing(),

            // Point selection
            const PointCheckboxList(),
            const _DividerWithSpacing(),

            // Time range
            const TimeRangeSelector(),
            const _DividerWithSpacing(),

            // Downsample
            const DownsampleSlider(),
            const _DividerWithSpacing(),

            // Action buttons
            // Load data button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: state.canLoadData &&
                        state.timeRangeError == null &&
                        !state.isLoadingData
                      ? notifier.loadChartData
                      : null,
                icon: state.isLoadingData
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 20),
                label: Text(state.isLoadingData ? loc.loading : loc.analysisLoadData),
              ),
            ),
            const SizedBox(height: 8),

            // Reset view button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: hasChartData ? notifier.resetChart : null,
                icon: const Icon(Icons.zoom_out_map, size: 20),
                label: Text(loc.analysisResetView),
              ),
            ),
            const SizedBox(height: 16),

            // Data table toggle
            Row(
              children: [
                Text(
                  loc.analysisDataTable,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: state.showDataTable,
                  onChanged: hasChartData
                      ? (_) => notifier.toggleDataTable()
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 带间距的分隔线
class _DividerWithSpacing extends StatelessWidget {
  const _DividerWithSpacing();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withAlpha(128),
      ),
    );
  }
}
