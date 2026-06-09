import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import '../../../providers/analysis_provider.dart';

/// DownsampleSlider — 降采样滑块
///
/// 范围 100~10000，使用对数刻度。
class DownsampleSlider extends ConsumerWidget {
  const DownsampleSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final notifier = ref.read(analysisProvider.notifier);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Log scale mapping: linear value 0~1 → log 100~10000
    final sliderValue = _logToLinear(state.downsample);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.analysisDownsample,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              loc.analysisDownsampleCurrent(_formatNumber(state.downsample)),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Slider(
          value: sliderValue,
          divisions: 200,
          label: '${state.downsample}',
          onChanged: (value) {
            final intVal = _linearToLog(value);
            notifier.setDownsample(intVal);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '100',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '10,000',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 将对数值（100~10000）映射到线性值（0~1）
  double _logToLinear(int value) {
    // log10(100) = 2, log10(10000) = 4
    final logVal = value > 0 ? log10(value / 100.0) : 0.0;
    return (logVal / 2.0).clamp(0.0, 1.0);
  }

  /// 将线性值（0~1）映射到对数值（100~10000）
  int _linearToLog(double linear) {
    // 实际值 = 100 × 10^(linear × 2)
    final raw = 100 * math.pow(10, linear * 2.0);
    // 取整到最接近的 100
    return ((raw / 100).round() * 100).clamp(100, 10000);
  }

  double log10(double x) => math.log(x) / math.ln10;

  String _formatNumber(int n) {
    if (n >= 10000) return '10,000';
    if (n >= 1000) return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    return n.toString();
  }
}
