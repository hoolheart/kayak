/// Custom Title Bar for Desktop
///
/// Provides drag-to-move functionality and window controls
library;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom title bar widget for desktop application
class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted && isMaximized != _isMaximized) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (_isMaximized) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
        height: 40,
        color: colorScheme.surfaceContainerHigh,
        child: Row(
          children: [
            const SizedBox(width: 16),
            // App icon and title
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
            // Window controls
            _WindowButton(
              icon: Icons.remove,
              onPressed: () => windowManager.minimize(),
              tooltip: 'Minimize',
            ),
            _WindowButton(
              icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
              onPressed: () async {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              tooltip: _isMaximized ? 'Restore' : 'Maximize',
            ),
            _WindowButton(
              icon: Icons.close,
              onPressed: () => windowManager.close(),
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
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });

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

/// Title bar wrapper that adds the custom title bar to any page
class TitleBarWrapper extends StatelessWidget {
  final Widget child;

  const TitleBarWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomTitleBar(),
        Expanded(child: child),
      ],
    );
  }
}
