import 'dart:async';

import 'package:flutter/material.dart';

/// Toast 类型。
enum ToastType {
  /// 成功：绿色背景 + 对勾图标。
  success,

  /// 错误：红色背景 + 错误图标。
  error,

  /// 警告：橙色背景 + 警告图标。
  warning,

  /// 信息：蓝色背景 + 信息图标。
  info,

  /// 加载中：Surface Variant 背景 + 旋转图标。
  loading,
}

/// Toast 条目数据。
class _ToastEntryData {
  _ToastEntryData({
    required this.id,
    required this.message,
    required this.type,
    this.duration,
  });

  final String id;
  final String message;
  final ToastType type;
  final Duration? duration;
}

/// Toast 组件。
///
/// 用于操作结果的轻量级反馈，自动消失不干扰用户当前操作。
/// 支持 Success/Error/Warning/Info/Loading 五种类型，可堆叠最多 3 个。
///
/// 用法：
/// ```dart
/// Toast.show(
///   context: context,
///   message: '工作台创建成功',
///   type: ToastType.success,
/// );
///
/// // Loading（不自动消失）
/// Toast.show(
///   context: context,
///   message: '正在保存...',
///   type: ToastType.loading,
/// );
/// ```
class Toast {
  Toast._();

  static _ToastManagerState? _managerState;

  /// 初始化 Toast 管理器。
  ///
  /// 应在 MaterialApp 的 builder 中调用。
  static Widget init(BuildContext context, Widget? child) {
    return _ToastManager(child: child);
  }

  /// 显示一个 Toast。
  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration? duration,
  }) {
    _managerState?.show(
      context,
      message,
      type,
      duration,
    );
  }

  /// 手动关闭指定 ID 的 Toast。
  static void dismiss(String id) {
    _managerState?.dismiss(id);
  }

  /// 关闭所有 Toast。
  static void dismissAll() {
    _managerState?.dismissAll();
  }
}

/// Toast 管理器 State。
class _ToastManager extends StatefulWidget {
  const _ToastManager({required this.child});

  final Widget? child;

  @override
  State<_ToastManager> createState() => _ToastManagerState();
}

class _ToastManagerState extends State<_ToastManager>
    with TickerProviderStateMixin {
  final List<_ToastEntryData> _toasts = [];
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    Toast._managerState = this;
  }

  @override
  void dispose() {
    Toast._managerState = null;
    super.dispose();
  }

  void show(
    BuildContext context,
    String message,
    ToastType type,
    Duration? duration,
  ) {
    final id = 'toast_${_nextId++}';

    // 去重：相同消息不重复显示
    final existingIndex = _toasts.indexWhere(
      (t) => t.message == message && t.type == type,
    );
    if (existingIndex >= 0) {
      return;
    }

    setState(() {
      // 最多 3 个，超过则移除最早的
      if (_toasts.length >= 3) {
        _toasts.removeAt(0);
      }
      _toasts.add(_ToastEntryData(
        id: id,
        message: message,
        type: type,
        duration: duration,
      ));
    });
  }

  void dismiss(String id) {
    if (!mounted) return;
    setState(() {
      _toasts.removeWhere((t) => t.id == id);
    });
  }

  void dismissAll() {
    if (!mounted) return;
    setState(_toasts.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        _ToastOverlay(
          toasts: List.unmodifiable(_toasts),
          onDismiss: dismiss,
        ),
      ],
    );
  }
}

/// Toast 覆盖层，显示所有活跃 Toast。
class _ToastOverlay extends StatelessWidget {
  const _ToastOverlay({
    required this.toasts,
    required this.onDismiss,
  });

  final List<_ToastEntryData> toasts;
  final void Function(String id) onDismiss;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (toasts.isEmpty) return const SizedBox.shrink();

    if (isMobile) {
      return Positioned(
        bottom: 32,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: toasts.reversed.map((toast) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                  left: 16,
                  right: 16,
                ),
                child: _ToastEntry(
                  key: ValueKey(toast.id),
                  data: toast,
                  isMobile: true,
                  onDismiss: onDismiss,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Positioned(
      top: 24,
      right: 24,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: toasts.reversed.map((toast) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ToastEntry(
                key: ValueKey(toast.id),
                data: toast,
                isMobile: false,
                onDismiss: onDismiss,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 单个 Toast 条目。
class _ToastEntry extends StatefulWidget {
  const _ToastEntry({
    super.key,
    required this.data,
    required this.isMobile,
    required this.onDismiss,
  });

  final _ToastEntryData data;
  final bool isMobile;
  final void Function(String id) onDismiss;

  @override
  State<_ToastEntry> createState() => _ToastEntryState();
}

class _ToastEntryState extends State<_ToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.isMobile ? const Offset(0, 1) : const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // 设置自动消失（非 Loading 类型）
    if (widget.data.type != ToastType.loading) {
      final duration = widget.data.duration ?? _defaultDuration(widget.data.type);
      _dismissTimer = Timer(duration, () {
        if (mounted) {
          widget.onDismiss(widget.data.id);
        }
      });
    }
  }

  Duration _defaultDuration(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Duration(seconds: 3);
      case ToastType.error:
        return const Duration(seconds: 5);
      case ToastType.warning:
        return const Duration(seconds: 4);
      case ToastType.info:
        return const Duration(seconds: 3);
      case ToastType.loading:
        return const Duration(days: 365);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _ToastContent(
          message: widget.data.message,
          type: widget.data.type,
          isMobile: widget.isMobile,
        ),
      ),
    );
  }
}

/// Toast 内容组件（无动画，纯渲染）。
class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    required this.type,
    required this.isMobile,
  });

  final String message;
  final ToastType type;
  final bool isMobile;

  Color _backgroundColor(ColorScheme colorScheme) {
    switch (type) {
      case ToastType.success:
        return colorScheme.primary.withAlpha(30);
      case ToastType.error:
        return colorScheme.errorContainer;
      case ToastType.warning:
        return Colors.orange.withAlpha(30);
      case ToastType.info:
        return colorScheme.primary.withAlpha(30);
      case ToastType.loading:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _foregroundColor(ColorScheme colorScheme) {
    switch (type) {
      case ToastType.success:
        return colorScheme.primary;
      case ToastType.error:
        return colorScheme.onErrorContainer;
      case ToastType.warning:
        return Colors.orange.shade800;
      case ToastType.info:
        return colorScheme.primary;
      case ToastType.loading:
        return colorScheme.onSurface;
    }
  }

  Color _borderColor(ColorScheme colorScheme) {
    switch (type) {
      case ToastType.success:
        return colorScheme.primary.withAlpha(77);
      case ToastType.error:
        return Colors.transparent;
      case ToastType.warning:
        return Colors.orange.withAlpha(77);
      case ToastType.info:
        return colorScheme.primary.withAlpha(77);
      case ToastType.loading:
        return Colors.transparent;
    }
  }

  IconData _icon() {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_outline;
      case ToastType.loading:
        return Icons.sync;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = isMobile
        ? MediaQuery.of(context).size.width - 32
        : 400.0;

    final bgColor = _backgroundColor(colorScheme);
    final fgColor = _foregroundColor(colorScheme);
    final borderColor = _borderColor(colorScheme);

    Widget iconWidget;
    if (type == ToastType.loading) {
      iconWidget = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else {
      iconWidget = Icon(_icon(), size: 20, color: fgColor);
    }

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor.a > 0
            ? Border.all(color: borderColor)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: fgColor),
            ),
          ),
        ],
      ),
    );
  }
}
