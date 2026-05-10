/// 控制面板组件
///
/// 提供试验选择、设备选择、测点选择、时间范围、降采样设置等功能。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/experiments/models/experiment.dart';
import '../models/chart_models.dart';
import '../providers/analysis_controller_provider.dart';
import '../providers/chart_data_provider.dart';
import '../theme/chart_colors.dart';

/// 控制面板
class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Experiment Selection
            _ControlCard(
              icon: Icons.science,
              title: '选择试验',
              child: _ExperimentSelector(),
            ),
            SizedBox(height: 16),
            // Device & Point Selection
            _ControlCard(
              icon: Icons.memory,
              title: '选择设备与测点',
              child: _DevicePointSelector(),
            ),
            SizedBox(height: 16),
            // Time Range
            _ControlCard(
              icon: Icons.schedule,
              title: '时间范围',
              child: _TimeRangeSelector(),
            ),
            SizedBox(height: 16),
            // Settings
            _ControlCard(
              icon: Icons.tune,
              title: '图表设置',
              child: _ChartSettings(),
            ),
            SizedBox(height: 16),
            // Action Buttons
            _ActionButtons(),
          ],
        ),
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.controlCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: textTheme.titleSmall),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

class _ExperimentSelector extends ConsumerWidget {
  const _ExperimentSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final controlState = ref.watch(analysisControllerProvider);
    final controller = ref.read(analysisControllerProvider.notifier);
    final experimentsAsync = ref.watch(experimentListForAnalysisProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: controlState.selectedExperimentId,
          hint: const Text('请选择试验'),
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: experimentsAsync.when(
            data: (experiments) => experiments.map((exp) {
              return DropdownMenuItem(
                value: exp.id,
                child: Text(exp.name),
              );
            }).toList(),
            loading: () => null,
            error: (_, __) => null,
          ),
          onChanged: controller.selectExperiment,
        ),
        if (controlState.selectedExperimentId != null)
          const _ExperimentMetadata(),
      ],
    );
  }
}

class _ExperimentMetadata extends ConsumerWidget {
  const _ExperimentMetadata();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(analysisControllerProvider);
    final experimentsAsync = ref.watch(experimentListForAnalysisProvider);

    final experiment = experimentsAsync.when(
      data: (list) => list.firstWhere(
        (e) => e.id == controlState.selectedExperimentId,
        orElse: () => Experiment(
          id: '',
          userId: '',
          name: '',
          status: ExperimentStatus.idle,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      loading: () => null,
      error: (_, __) => null,
    );

    if (experiment == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          _MetadataRow(label: '状态', value: experiment.status.value),
          _MetadataRow(
            label: '开始时间',
            value: experiment.startedAt != null
                ? '${experiment.startedAt!.year}-${experiment.startedAt!.month.toString().padLeft(2, '0')}-${experiment.startedAt!.day.toString().padLeft(2, '0')}'
                : '未开始',
          ),
          _MetadataRow(
            label: '采样数',
            value: experiment.updatedAt
                .difference(experiment.createdAt)
                .inMinutes
                .toString(),
          ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicePointSelector extends ConsumerWidget {
  const _DevicePointSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(analysisControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Device Selector
        if (controlState.selectedExperimentId != null) ...[
          const _DeviceDropdown(),
          const SizedBox(height: 16),
        ],
        // Point Selector
        if (controlState.selectedDeviceId != null) ...[
          Text(
            '测点（最多4个）',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          const _PointList(),
          const SizedBox(height: 8),
          Text(
            '已选择 ${controlState.selectedPointIds.length}/4',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ],
    );
  }
}

class _DeviceDropdown extends ConsumerWidget {
  const _DeviceDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(analysisControllerProvider);
    final controller = ref.read(analysisControllerProvider.notifier);
    final devicesAsync = ref.watch(
      deviceListForAnalysisProvider(controlState.selectedExperimentId!),
    );

    return DropdownButtonFormField<String>(
      value: controlState.selectedDeviceId,
      hint: const Text('请选择设备'),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: devicesAsync.when(
        data: (devices) => devices.map((dev) {
          return DropdownMenuItem(
            value: dev.id,
            child: Text(dev.name),
          );
        }).toList(),
        loading: () => null,
        error: (_, __) => null,
      ),
      onChanged: controller.selectDevice,
    );
  }
}

class _PointList extends ConsumerWidget {
  const _PointList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(analysisControllerProvider);
    final controller = ref.read(analysisControllerProvider.notifier);
    final pointsAsync = ref.watch(
      pointListForAnalysisProvider(controlState.selectedDeviceId!),
    );
    final brightness = Theme.of(context).brightness;
    final curveColors = ChartColors.getCurves(brightness);

    return pointsAsync.when(
      data: (points) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: points.length,
            itemBuilder: (context, index) {
              final point = points[index];
              final isSelected = controlState.selectedPointIds.contains(point.id);
              final selectionIndex =
                  controlState.selectedPointIds.indexOf(point.id);
              final isMaxReached =
                  controlState.selectedPointIds.length >= 4 && !isSelected;

              return Opacity(
                opacity: isMaxReached ? 0.38 : 1.0,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: isMaxReached
                            ? null
                            : (_) {
                                if (controlState.selectedPointIds.length >= 4 &&
                                    !isSelected) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('最多选择4个测点'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                controller.togglePointSelection(point.id);
                              },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (isSelected && selectionIndex >= 0) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: curveColors[
                                selectionIndex % curveColors.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        point.unit ?? '',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('加载测点失败')),
    );
  }
}

class _TimeRangeSelector extends ConsumerWidget {
  const _TimeRangeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(analysisControllerProvider);
    final controller = ref.read(analysisControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset buttons
        Row(
          children: [
            _PresetButton(
              label: '最近1小时',
              isActive: false,
              onPressed: () => controller.applyPresetTimeRange('1h'),
            ),
            const SizedBox(width: 8),
            _PresetButton(
              label: '最近24小时',
              isActive: false,
              onPressed: () => controller.applyPresetTimeRange('24h'),
            ),
            const SizedBox(width: 8),
            _PresetButton(
              label: '全部',
              isActive: false,
              onPressed: () => controller.applyPresetTimeRange('all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Custom range
        _DateTimeInput(
          label: '开始时间',
          value: controlState.startTime,
          onChanged: (dt) => controller.setTimeRange(dt, controlState.endTime),
        ),
        const SizedBox(height: 8),
        _DateTimeInput(
          label: '结束时间',
          value: controlState.endTime,
          onChanged: (dt) =>
              controller.setTimeRange(controlState.startTime, dt),
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        backgroundColor:
            isActive ? colorScheme.primaryContainer : Colors.transparent,
        foregroundColor:
            isActive ? colorScheme.onPrimaryContainer : colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isActive
              ? BorderSide.none
              : BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _DateTimeInput extends StatelessWidget {
  const _DateTimeInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2020),
          lastDate: now.add(const Duration(days: 1)),
        );
        if (date != null && context.mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value ?? now),
          );
          if (time != null) {
            onChanged(
              DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              ),
            );
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: colorScheme.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')} '
                  '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
              : 'YYYY-MM-DD HH:mm',
          style: TextStyle(
            color: value != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ChartSettings extends ConsumerWidget {
  const _ChartSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(analysisControllerProvider);
    final controller = ref.read(analysisControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Downsample slider
        Row(
          children: [
            Expanded(
              child: Text(
                '降采样点数',
                style: textTheme.bodyMedium,
              ),
            ),
            Text(
              '${controlState.downsample}',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: controlState.downsample.toDouble(),
            min: 100,
            max: 10000,
            divisions: 99,
            label: controlState.downsample.toString(),
            onChanged: (value) => controller.setDownsample(value.round()),
          ),
        ),
        const Divider(height: 24),
        // Show data table toggle
        Row(
          children: [
            Expanded(
              child: Text(
                '显示数据表格',
                style: textTheme.bodyMedium,
              ),
            ),
            Switch(
              value: controlState.showDataTable,
              onChanged: controller.toggleDataTable,
            ),
          ],
        ),
        // Auto refresh toggle
        Row(
          children: [
            Expanded(
              child: Text(
                '自动刷新',
                style: textTheme.bodyMedium,
              ),
            ),
            Switch(
              value: controlState.autoRefresh,
              onChanged: controller.toggleAutoRefresh,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(analysisControllerProvider);
    final chartNotifier = ref.read(chartDataProvider.notifier);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 40,
          child: FilledButton.icon(
            onPressed: controlState.canLoadData
                ? () {
                    final request = DataQueryRequest(
                      experimentId: controlState.selectedExperimentId!,
                      deviceId: controlState.selectedDeviceId!,
                      pointIds: controlState.selectedPointIds,
                      startTime: controlState.startTime,
                      endTime: controlState.endTime,
                      downsample: controlState.downsample,
                    );
                    chartNotifier.loadData(request);
                  }
                : null,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('加载数据'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            onPressed: chartNotifier.reset,
            icon: const Icon(Icons.restart_alt, size: 20),
            label: const Text('重置视图'),
          ),
        ),
      ],
    );
  }
}
