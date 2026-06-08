import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final hasChartData = state.chartData.hasValue &&
        state.chartData.value != null &&
        !state.chartData.value!.isEmpty;

    // 响应式宽度：桌面 >1200px 使用 350px，平板 600-1200px 使用 280px（Issue 6）
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
            // 试验选择
            const ExperimentDropdown(),
            const _DividerWithSpacing(),

            // 设备选择
            const DeviceDropdown(),
            const _DividerWithSpacing(),

            // 测点选择
            const PointCheckboxList(),
            const _DividerWithSpacing(),

            // 时间范围
            const TimeRangeSelector(),
            const _DividerWithSpacing(),

            // 降采样
            const DownsampleSlider(),
            const _DividerWithSpacing(),

            // 操作按钮
            // 加载数据按钮
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
                label: Text(state.isLoadingData ? '加载中...' : '加载数据'),
              ),
            ),
            const SizedBox(height: 8),

            // 重置视图按钮
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: hasChartData ? notifier.resetChart : null,
                icon: const Icon(Icons.zoom_out_map, size: 20),
                label: const Text('重置视图'),
              ),
            ),
            const SizedBox(height: 16),

            // 数据表格开关
            Row(
              children: [
                Text(
                  '数据表格',
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
