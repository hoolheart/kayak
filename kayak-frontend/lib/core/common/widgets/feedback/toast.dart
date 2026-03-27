/// Toast and snackbar notification components
library;

import 'package:flutter/material.dart';

/// Toast notification severity levels
enum ToastSeverity {
  info,
  success,
  warning,
  error,
}

/// Custom snackbar content with icon
class SnackBarContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;

  const SnackBarContent({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (message != null)
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Toast helper class for showing snackbars
class Toast {
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    ToastSeverity severity = ToastSeverity.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    IconData icon;
    Color iconColor;

    switch (severity) {
      case ToastSeverity.info:
        icon = Icons.info_outline;
        iconColor = Colors.blue;
        break;
      case ToastSeverity.success:
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case ToastSeverity.warning:
        icon = Icons.warning_amber_outlined;
        iconColor = Colors.orange;
        break;
      case ToastSeverity.error:
        icon = Icons.error_outline;
        iconColor = Colors.red;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SnackBarContent(
          icon: icon,
          iconColor: iconColor,
          title: title,
          message: message,
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    show(
      context,
      title: title,
      message: message,
      severity: ToastSeverity.success,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    show(
      context,
      title: title,
      message: message,
      severity: ToastSeverity.error,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    show(
      context,
      title: title,
      message: message,
      severity: ToastSeverity.warning,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    show(
      context,
      title: title,
      message: message,
      severity: ToastSeverity.info,
    );
  }
}
