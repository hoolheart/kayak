import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/experiment.dart';
import '../../../providers/analysis_provider.dart';
import '../../../widgets/async_value_widget.dart';

/// ExperimentDropdown — 试验选择下拉框
///
/// 显示已完成/中止的试验列表，选中后触发级联设备加载。
class ExperimentDropdown extends ConsumerWidget {
  const ExperimentDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final notifier = ref.read(analysisProvider.notifier);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '试验',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AsyncValueWidget<List<Experiment>>(
          value: state.experiments,
          onRetry: notifier.refreshExperiments,
          loadingBuilder: const _ExperimentSkeleton(),
          emptyBuilder: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '暂无已完成或中止的试验',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          dataBuilder: (experiments) {
            return _buildDropdown(context, experiments, state, notifier,
                textTheme, colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    List<Experiment> experiments,
    AnalysisState state,
    AnalysisNotifier notifier,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedExperimentId,
          isExpanded: true,
          hint: const Text('请选择试验'),
          isDense: true,
          items: experiments.map((experiment) {
            final statusLabel =
                experiment.status == ExperimentStatus.completed
                    ? '已完成'
                    : '已中止';
            final statusColor =
                experiment.status == ExperimentStatus.completed
                    ? colorScheme.primary
                    : Colors.orange;

            return DropdownMenuItem<String>(
              value: experiment.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          experiment.name,
                          style: textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateRange(experiment),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: notifier.selectExperiment,
        ),
      ),
    );
  }

  String _formatDateRange(Experiment experiment) {
    final start = experiment.startedAt ?? experiment.createdAt;
    final end = experiment.endedAt ?? DateTime.now();
    return '${_formatDate(start)} ~ ${_formatDate(end)}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

/// 试验下拉框加载骨架屏
class _ExperimentSkeleton extends StatelessWidget {
  const _ExperimentSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skeletonColor = colorScheme.surfaceContainerHighest.withAlpha(128);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 48,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
