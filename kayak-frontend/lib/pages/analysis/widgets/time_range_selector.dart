import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import '../../../providers/analysis_provider.dart';

/// TimeRangeSelector — 时间范围选择器
///
/// 包含预设按钮（1小时/24小时/全部）和自定义时间选择。
class TimeRangeSelector extends ConsumerWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final notifier = ref.read(analysisProvider.notifier);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final isCustom = state.customStart != null || state.customEnd != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.analysisTimeRange,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Preset button group
        SegmentedButton<TimeRangePreset>(
          segments: [
            ButtonSegment(
              value: TimeRangePreset.oneHour,
              label: Text(loc.analysisTimeRange1h),
            ),
            ButtonSegment(
              value: TimeRangePreset.twentyFourHours,
              label: Text(loc.analysisTimeRange24h),
            ),
            ButtonSegment(
              value: TimeRangePreset.all,
              label: Text(loc.analysisTimeRangeAll),
            ),
          ],
          selected: isCustom
              ? <TimeRangePreset>{}
              : {state.timePreset},
          onSelectionChanged: (selected) {
            notifier.selectTimePreset(selected.first);
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: colorScheme.primary,
            selectedForegroundColor: colorScheme.onPrimary,
            backgroundColor: Colors.transparent,
            foregroundColor: colorScheme.onSurfaceVariant,
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        const SizedBox(height: 8),
        // Custom time input
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                context: context,
                label: loc.analysisStartTime,
                value: state.customStart,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: state.customStart ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        state.customStart ?? DateTime.now(),
                      ),
                    );
                    if (time != null) {
                      notifier.setCustomStart(DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      ));
                    }
                  }
                },
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateField(
                context: context,
                label: loc.analysisEndTime,
                value: state.customEnd,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: state.customEnd ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        state.customEnd ?? DateTime.now(),
                      ),
                    );
                    if (time != null) {
                      notifier.setCustomEnd(DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      ));
                    }
                  }
                },
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        // Validation error
        if (state.timeRangeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.timeRangeErrorLocalized(loc)!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final loc = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          prefixIcon: Icon(
            Icons.calendar_today,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        child: Text(
          value != null
              ? '${value.year}-${_pad(value.month)}-${_pad(value.day)} '
                  '${_pad(value.hour)}:${_pad(value.minute)}'
              : loc.analysisSelectTime,
          style: textTheme.bodySmall?.copyWith(
            color: value != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
