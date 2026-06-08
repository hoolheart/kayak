import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/device.dart';
import '../../../providers/analysis_provider.dart';

/// DeviceDropdown — 设备选择下拉框
///
/// 级联依赖试验选择。未选试验时禁用。
class DeviceDropdown extends ConsumerWidget {
  const DeviceDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final notifier = ref.read(analysisProvider.notifier);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final isDisabled = !state.hasExperiment;
    final devices = state.devices;
    final isLoading = devices == null && state.hasExperiment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '设备',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          const _DeviceSkeleton()
        else if (isDisabled)
          _buildDisabledDropdown(context, '请先选择试验')
        else if (devices != null && devices.isEmpty)
          _buildDisabledDropdown(context, '该工作台下暂无设备')
        else
          _buildDropdown(context, devices ?? [], state, notifier),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    List<Device> devices,
    AnalysisState state,
    AnalysisNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedDeviceId,
          isExpanded: true,
          hint: const Text('请选择设备'),
          isDense: true,
          items: devices.map((device) {
            return DropdownMenuItem<String>(
              value: device.id,
              child: Text(
                device.name,
                style: textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: notifier.selectDevice,
        ),
      ),
    );
  }

  Widget _buildDisabledDropdown(BuildContext context, String placeholder) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Opacity(
      opacity: 0.38,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                placeholder,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// 设备下拉框加载骨架屏
class _DeviceSkeleton extends StatelessWidget {
  const _DeviceSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skeletonColor = colorScheme.surfaceContainerHighest.withAlpha(128);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: skeletonColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
