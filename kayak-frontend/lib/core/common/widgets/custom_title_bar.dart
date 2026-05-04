/// Custom Title Bar for Desktop
///
/// Provides drag-to-move functionality and window controls.
/// On Web platform, this widget renders nothing since the browser
/// provides its own title bar / window controls.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'
    if (dart.library.html) 'stub.dart';

/// Custom title bar widget for desktop application.
///
/// On Web, this widget returns an empty SizedBox(0).
class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _checkMaximized();
    }
  }

  Future<void> _checkMaximized() async {
    try {
      final isMaximized = await windowManager.isMaximized();
      if (mounted && isMaximized != _isMaximized) {
        setState(() => _isMaximized = isMaximized);
      }
    } catch (e) {
      // Ignore on unsupported platforms
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web 平台：不显示自定义标题栏（浏览器自带窗口控制）
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanStart: (_) {
        try {
          windowManager.startDragging();
        } catch (e) {
          // Ignore
        }
      },
      onDoubleTap: () async {
        try {
          if (_isMaximized) {
            await windowManager.unmaximize();
            setState(() => _isMaximized = false);
          } else {
            await windowManager.maximize();
            setState(() => _isMaximized = true);
          }
        } catch (e) {
          // Ignore
        }
      },
      child: Container(
        height: 40,
        color: colorScheme.surfaceContainerHigh,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.science,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Kayak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            _WindowButton(
              icon: Icons.remove,
              onPressed: () {
                try {
                  windowManager.minimize();
                } catch (e) {
                  // Ignore
                }
              },
              tooltip: 'Minimize',
            ),
            _WindowButton(
              icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
              onPressed: () async {
                try {
                  if (_isMaximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                  setState(() => _isMaximized = !_isMaximized);
                } catch (e) {
                  // Ignore
                }
              },
              tooltip: _isMaximized ? 'Restore' : 'Maximize',
            ),
            _WindowButton(
              icon: Icons.close,
              onPressed: () {
                try {
                  windowManager.close();
                } catch (e) {
                  // Ignore
                }
              },
              tooltip: 'Close',
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual window control button
class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color iconColor;

    if (_isHovered) {
      if (widget.isClose) {
        backgroundColor = Colors.red;
        iconColor = Colors.white;
      } else {
        backgroundColor = colorScheme.surfaceContainerHighest;
        iconColor = colorScheme.onSurface;
      }
    } else {
      backgroundColor = Colors.transparent;
      iconColor = colorScheme.onSurfaceVariant;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            height: 40,
            color: backgroundColor,
            child: Center(
              child: Icon(
                widget.icon,
                size: 18,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title bar wrapper that adds the custom title bar to any page.
///
/// On Web, it simply returns the child without a title bar.
class TitleBarWrapper extends StatelessWidget {
  const TitleBarWrapper({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return child;
    }
    return Column(
      children: [
        const CustomTitleBar(),
        Expanded(child: child),
      ],
    );
  }
}
