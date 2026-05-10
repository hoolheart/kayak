/// 图表工具栏组件
///
/// 提供图表操作按钮：放大、缩小、平移、光标、全屏、导出、设置。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chart_models.dart';
import '../providers/chart_data_provider.dart';
import '../theme/chart_colors.dart';

/// 图表工具栏
class ChartToolbar extends ConsumerStatefulWidget {
  const ChartToolbar({super.key});

  @override
  ConsumerState<ChartToolbar> createState() => _ChartToolbarState();
}

class _ChartToolbarState extends ConsumerState<ChartToolbar> {
  bool _isPanMode = false;
  bool _isCursorMode = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chartState = ref.watch(chartDataProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.chartToolbarBackground,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Left group: zoom controls
          _ToolbarIconButton(
            icon: Icons.zoom_in,
            tooltip: '放大',
            onPressed: () {
              // Zoom in logic will be implemented in future iterations
            },
          ),
          _ToolbarIconButton(
            icon: Icons.zoom_out,
            tooltip: '缩小',
            onPressed: () {
              // Zoom out logic will be implemented in future iterations
            },
          ),
          _ToolbarIconButton(
            icon: Icons.pan_tool,
            tooltip: '平移模式',
            isActive: _isPanMode,
            onPressed: () {
              setState(() {
                _isPanMode = !_isPanMode;
                if (_isPanMode) _isCursorMode = false;
              });
            },
          ),
          _ToolbarIconButton(
            icon: Icons.mouse,
            tooltip: '光标模式',
            isActive: _isCursorMode,
            onPressed: () {
              setState(() {
                _isCursorMode = !_isCursorMode;
                if (_isCursorMode) _isPanMode = false;
              });
            },
          ),

          const SizedBox(width: 16),

          // Center group: current range info
          if (chartState.data != null) ...[
            Expanded(
              child: Center(
                child: Text(
                  _formatRange(chartState.data!),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
          ],

          // Right group: actions
          _ToolbarIconButton(
            icon: Icons.fullscreen,
            tooltip: '全屏',
            onPressed: () {
              // Fullscreen logic will be implemented in future iterations
            },
          ),
          _ToolbarIconButton(
            icon: Icons.save,
            tooltip: '导出图片',
            onPressed: () {
              // Export logic will be implemented in future iterations
            },
          ),
          _ToolbarIconButton(
            icon: Icons.settings,
            tooltip: '图表配置',
            onPressed: () {
              // Settings logic will be implemented in future iterations
            },
          ),
        ],
      ),
    );
  }

  String _formatRange(ChartDataResponse data) {
    if (data.points.isEmpty) return '';
    final timestamps = data.points.first.timestamps;
    if (timestamps.length < 2) return '';

    final start = DateTime.fromMillisecondsSinceEpoch(timestamps.first);
    final end = DateTime.fromMillisecondsSinceEpoch(timestamps.last);

    return '${_formatDateTime(start)} ~ ${_formatDateTime(end)}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          backgroundColor: isActive
              ? colorScheme.primaryContainer
              : Colors.transparent,
          foregroundColor: isActive
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
