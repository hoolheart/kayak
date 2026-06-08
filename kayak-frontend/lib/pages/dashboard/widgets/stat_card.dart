import 'package:flutter/material.dart';

/// 统计数字卡片组件。
///
/// 包含图标 + 大数字 + 标签文本。
/// 数字从 0 计数动画到目标值（600ms, ease-out-cubic）。
/// 大值（≥10000）显示千位分隔符，字号自适应缩小。
class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
  });

  /// 统计卡片图标
  final IconData icon;

  /// 统计数值
  final int value;

  /// 统计标签
  final String label;

  /// 紧凑模式（移动端使用）
  final bool compact;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _hasAnimated = false;
      _controller.reset();
      _startAnimation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset animation on re-visit (when widget is re-inserted into tree)
    _hasAnimated = false;
    _controller.reset();
    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_hasAnimated && mounted) {
      _hasAnimated = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start animation on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimation();
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final iconSize = widget.compact ? 24.0 : 28.0;
    final numberSize = widget.compact ? 36.0 : 48.0;
    final padding = widget.compact ? 16.0 : 24.0;
    final minHeight = widget.compact ? 100.0 : 120.0;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Icon(
              widget.icon,
              size: iconSize,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            // 动画数字
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final displayValue = (_animation.value * widget.value).round();
                final formattedValue = _formatNumber(displayValue);
                final useLargeFont = widget.value >= 10000;
                return Text(
                  displayValue > 0 || _animation.value > 0
                      ? formattedValue
                      : '0',
                  style:
                      (useLargeFont
                              ? textTheme.headlineMedium
                              : textTheme.displayLarge)
                          ?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w300,
                            fontSize: useLargeFont ? 36.0 : numberSize,
                          ),
                );
              },
            ),
            const SizedBox(height: 4),
            // 标签
            Text(
              widget.label,
              style:
                  (widget.compact ? textTheme.bodySmall : textTheme.bodyMedium)
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化数字，大数值添加千位分隔符。
  String _formatNumber(int value) {
    if (value >= 10000) {
      // 添加千位分隔符
      final str = value.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return value.toString();
  }
}
