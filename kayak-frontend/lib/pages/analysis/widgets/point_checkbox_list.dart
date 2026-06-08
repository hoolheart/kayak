import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/analysis_provider.dart';

/// PointCheckboxList — 测点复选框列表
///
/// 级联依赖设备选择。最多同时勾选 4 个。
class PointCheckboxList extends ConsumerWidget {
  const PointCheckboxList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final notifier = ref.read(analysisProvider.notifier);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final points = state.points;
    final isDisabled = !state.hasDevice;
    final isLoading = points == null && state.hasDevice;
    final colors = chartLineColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '测点 (最多选择 ${4 - state.selectedPointIds.length} 条)',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          const _PointSkeleton()
        else if (isDisabled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '请先选择设备',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else if (points == null || points.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '该设备下暂无测点',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...List.generate(points.length, (index) {
            final point = points[index];
            final isSelected = state.selectedPointIds.contains(point.id);
            final color = colors[index % colors.length];
            final atMax = state.selectedPointIds.length >= 4;
            final canSelect = !atMax || isSelected;

            return Opacity(
              opacity: canSelect ? 1.0 : 0.38,
              child: InkWell(
                onTap: canSelect
                    ? () => notifier.togglePoint(point.id)
                    : () => _showMaxToast(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: canSelect
                              ? (_) => notifier.togglePoint(point.id)
                              : null,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withAlpha(180),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        point.name,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (point.unit != null && point.unit!.isNotEmpty)
                        Text(
                          ' (${point.unit})',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        if (points != null && points.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '已选择: ${state.selectedPointIds.length}/4',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  void _showMaxToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('最多同时选择 4 条曲线'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 测点列表加载骨架屏
class _PointSkeleton extends StatelessWidget {
  const _PointSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skeletonColor = colorScheme.surfaceContainerHighest.withAlpha(128);

    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
