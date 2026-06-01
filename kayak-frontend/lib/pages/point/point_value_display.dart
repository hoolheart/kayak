import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/app_localizations.dart';
import '../../models/point.dart';
import '../../providers/point_provider.dart';
import '../../providers/services.dart';

// ============================================================
// PointValueDisplay — 测点值显示组件
//
// 显示测点的实时数值和状态指示。
// 内部维护自己的加载状态，刷新时不影响其他行。
//
// 状态指示：
// - normal：灰色圆点 + 正常颜色数值
// - timeout：橙色圆点 + 灰色数值
// - error：红色圆点 + "—"
// ============================================================

/// PointValueDisplay — 测点值显示组件
class PointValueDisplay extends ConsumerStatefulWidget {
  const PointValueDisplay({
    super.key,
    required this.pointId,
    required this.dataType,
    this.unit,
    this.status = 'normal',
  });

  /// 测点 ID
  final String pointId;

  /// 数据类型（用于格式化）
  final DataType dataType;

  /// 单位
  final String? unit;

  /// 测点状态（来自 Point.status）
  final String status;

  @override
  ConsumerState<PointValueDisplay> createState() => _PointValueDisplayState();
}

class _PointValueDisplayState extends ConsumerState<PointValueDisplay>
    with SingleTickerProviderStateMixin {
  Object? _latestValue;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadValue();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// 初始加载测点值
  Future<void> _loadValue() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(pointServiceProvider);
      final pointValue = await service.getValue(widget.pointId);
      if (mounted) {
        setState(() {
          _latestValue = pointValue.value;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// 手动刷新
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    _rotationController.repeat();

    try {
      final service = ref.read(pointServiceProvider);
      final pointValue = await service.getValue(widget.pointId);
      if (mounted) {
        setState(() {
          _latestValue = pointValue.value;
          _isRefreshing = false;
          _errorMessage = null;
        });
        _rotationController.stop();
        _rotationController.reset();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _errorMessage = e.toString();
        });
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  /// 格式化数值
  String _formatValue(Object? value) {
    if (value == null) return '—';
    switch (widget.dataType) {
      case DataType.number:
        return (value as num).toStringAsFixed(2);
      case DataType.integer:
        return (value as num).toStringAsFixed(0);
      case DataType.boolean:
        final l10n = AppLocalizations.of(context);
        if (l10n == null) return value.toString();
        return (value == true) ? l10n.booleanTrue : l10n.booleanFalse;
      case DataType.string:
        return value.toString();
    }
  }

  /// 状态颜色
  Color _statusColor(ColorScheme colorScheme) {
    switch (widget.status.toLowerCase()) {
      case 'normal':
        return colorScheme.onSurfaceVariant;
      case 'timeout':
        return Colors.orange;
      case 'error':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  /// 状态文本
  String _statusLabel(AppLocalizations l10n) {
    switch (widget.status.toLowerCase()) {
      case 'normal':
        return l10n.pointStatusNormal;
      case 'timeout':
        return l10n.pointStatusTimeout;
      case 'error':
        return l10n.pointStatusError;
      default:
        return widget.status;
    }
  }

  /// 数值颜色（超时时显示灰色）
  Color _valueColor(ColorScheme colorScheme) {
    if (widget.status.toLowerCase() == 'timeout') {
      return colorScheme.onSurfaceVariant;
    }
    return colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 加载中（包括初始加载和骨架屏）
    if (_isLoading) {
      return _buildSkeleton(colorScheme);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态圆点
        if (_errorMessage == null)
          Tooltip(
            message: _statusLabel(l10n),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(colorScheme),
              ),
            ),
          )
        else
          Tooltip(
            message: _errorMessage ?? '',
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(width: 8),
        // 数值 + 单位
        if (_errorMessage != null)
          Text(
            '—',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          Text(
            _formatValue(_latestValue),
            style: textTheme.bodyLarge?.copyWith(
              color: _valueColor(colorScheme),
            ),
          ),
          if (widget.unit != null && widget.unit!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              widget.unit!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
        const SizedBox(width: 16),
        // 刷新按钮
        SizedBox(
          width: 20,
          height: 20,
          child: IconButton(
            icon: _isRefreshing
                ? RotationTransition(
                    turns: _rotationController,
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    size: 16,
                    color: colorScheme.primary,
                  ),
            onPressed: _handleRefresh,
            tooltip: l10n.refresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// 骨架占位（加载中）
  Widget _buildSkeleton(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 20,
          height: 20,
          child: IconButton(
            icon: Icon(
              Icons.refresh,
              size: 16,
              color: colorScheme.primary.withAlpha(128),
            ),
            onPressed: null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
          ),
        ),
      ],
    );
  }
}
