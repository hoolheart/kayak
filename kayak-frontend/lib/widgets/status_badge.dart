import 'package:flutter/material.dart';

import '../models/experiment.dart';

/// StatusBadge — 状态标签可复用组件
///
/// 用于展示试验的 6 种状态：IDLE / LOADED / RUNNING / PAUSED / COMPLETED / ABORTED。
/// RUNNING 状态带有脉冲动画效果。
///
/// 构造函数参数：
/// ```dart
/// StatusBadge(
///   status: ExperimentStatus.running,  // 必填
///   showIcon: true,                    // 是否显示图标/圆点
///   showPulse: true,                   // RUNNING 是否脉冲动画
///   onTap: () => _filterByStatus(),    // 点击回调
///   compact: false,                    // 紧凑模式
/// )
/// ```
class StatusBadge extends StatefulWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.showIcon = true,
    this.showPulse = true,
    this.onTap,
    this.compact = false,
  });

  /// 试验状态。
  final ExperimentStatus status;

  /// 自定义标签文本（从 l10n 传入）。
  ///
  /// 如果提供，将替代默认的英文 fallback 文本。
  /// 使用方应通过 AppLocalizations 传入本地化状态文本。
  final String? label;

  /// 是否显示状态图标/圆点，默认 true。
  final bool showIcon;

  /// RUNNING 状态是否显示脉冲动画，默认 true。
  final bool showPulse;

  /// 点击回调（可选）。
  final VoidCallback? onTap;

  /// 紧凑模式（小屏/小空间使用），默认 false。
  final bool compact;

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.showPulse != widget.showPulse) {
      _disposePulseAnimation();
      _initPulseAnimation();
    }
  }

  @override
  void dispose() {
    _disposePulseAnimation();
    super.dispose();
  }

  void _initPulseAnimation() {
    if (widget.status == ExperimentStatus.running && widget.showPulse) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      _pulseAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: Curves.easeOut,
        ),
      );
      _fadeAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: Curves.easeOut,
        ),
      );
      _pulseController!.repeat();
    }
  }

  void _disposePulseAnimation() {
    _pulseController?.dispose();
    _pulseController = null;
    _pulseAnimation = null;
    _fadeAnimation = null;
  }

  bool get _shouldAnimate =>
      widget.status == ExperimentStatus.running &&
      widget.showPulse &&
      _pulseController != null &&
      !MediaQuery.of(context).accessibleNavigation &&
      MediaQuery.of(context).disableAnimations == false;

  // ============================================================
  // 颜色常量（匹配设计规范）
  // ============================================================
  static const _statusColors = <ExperimentStatus, Color>{
    ExperimentStatus.idle: Color(0xFF757575),
    ExperimentStatus.loaded: Color(0xFF1976D2),
    ExperimentStatus.running: Color(0xFF2E7D32),
    ExperimentStatus.paused: Color(0xFFED6C02),
    ExperimentStatus.completed: Color(0xFF2E7D32),
    ExperimentStatus.aborted: Color(0xFFBA1A1A),
  };

  static const _darkStatusColors = <ExperimentStatus, Color>{
    ExperimentStatus.idle: Color(0xFFBDBDBD),
    ExperimentStatus.loaded: Color(0xFF90CAF9),
    ExperimentStatus.running: Color(0xFF81C784),
    ExperimentStatus.paused: Color(0xFFFFB74D),
    ExperimentStatus.completed: Color(0xFF81C784),
    ExperimentStatus.aborted: Color(0xFFFFB4AB),
  };

  // ============================================================
  // 状态图标
  // ============================================================
  static const _statusIcons = <ExperimentStatus, IconData>{
    ExperimentStatus.idle: Icons.circle,
    ExperimentStatus.loaded: Icons.circle,
    ExperimentStatus.running: Icons.play_arrow,
    ExperimentStatus.paused: Icons.pause,
    ExperimentStatus.completed: Icons.check,
    ExperimentStatus.aborted: Icons.close,
  };

  Color _getColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark && _darkStatusColors.containsKey(widget.status)) {
      return _darkStatusColors[widget.status]!;
    }
    return _statusColors[widget.status] ?? const Color(0xFF757575);
  }

  IconData _getIcon() {
    return _statusIcons[widget.status] ?? Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final bgColor = color.withAlpha(30); // ~12% opacity

    final labelStyle = TextStyle(
      fontSize: widget.compact ? 10 : 12,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.33,
    );

    // 紧凑模式：仅显示颜色圆点 + 简短文字
    final iconSize = widget.compact ? 6.0 : 8.0;
    final iconWidget = widget.showIcon
        ? Padding(
            padding: EdgeInsets.only(right: widget.compact ? 2 : 4),
            child: Icon(
              _getIcon(),
              size: widget.compact ? 10 : 12,
              color: color,
            ),
          )
        : const SizedBox.shrink();

    final dotWidget = widget.showIcon
        ? Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        : const SizedBox.shrink();

    final hasDot = widget.status == ExperimentStatus.idle ||
        widget.status == ExperimentStatus.loaded;

    final leading = hasDot ? dotWidget : iconWidget;

    final badge = Container(
      height: widget.compact ? 20 : 24,
      constraints: const BoxConstraints(minWidth: 48),
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showIcon) ...[
                leading,
                const SizedBox(width: 4),
              ],
              Text(
                _statusLabel(widget.status),
                style: labelStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    // RUNNING 脉冲动画包装
    if (_shouldAnimate) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // 脉冲外层
          AnimatedBuilder(
            animation: _pulseController!,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation?.value ?? 0,
                child: Transform.scale(
                  scale: _pulseAnimation?.value ?? 1.0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color.withAlpha(76), // ~30%
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          // 内层静态标签
          badge,
        ],
      );
    }

    return badge;
  }

  /// 获取状态文本。
  ///
  /// 如果提供了 [widget.label]，优先使用（即 l10n 文本）。
  /// 否则返回默认英文 fallback。
  String _statusLabel(ExperimentStatus status) {
    if (widget.label != null) return widget.label!;
    // 默认英文 fallback
    switch (status) {
      case ExperimentStatus.idle:
        return 'Idle';
      case ExperimentStatus.loaded:
        return 'Loaded';
      case ExperimentStatus.running:
        return 'Running';
      case ExperimentStatus.paused:
        return 'Paused';
      case ExperimentStatus.completed:
        return 'Completed';
      case ExperimentStatus.aborted:
        return 'Aborted';
    }
  }
}
