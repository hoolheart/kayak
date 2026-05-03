/// 连接测试共享组件
///
/// 用于 Modbus TCP 和 Modbus RTU 表单，提供统一的连接测试按钮和结果展示。
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/color_schemes.dart';

/// 连接测试状态
enum ConnectionTestState { idle, testing, success, failed }

/// 连接测试共享组件
///
/// 封装连接测试按钮和结果消息的渲染逻辑，
/// 在 ModbusTcpForm 和 ModbusRtuForm 中复用。
class ConnectionTestWidget extends StatelessWidget {
  final ConnectionTestState state;
  final String? message;
  final int? latencyMs;
  final VoidCallback onTest;

  const ConnectionTestWidget({
    super.key,
    required this.state,
    required this.onTest,
    this.message,
    this.latencyMs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildButton(theme),
        if (state == ConnectionTestState.failed && message != null) ...[
          const SizedBox(height: 8),
          _buildResultMessage(theme),
        ],
        if (state == ConnectionTestState.success && message != null) ...[
          const SizedBox(height: 8),
          _buildResultMessage(theme),
        ],
      ],
    );
  }

  Widget _buildButton(ThemeData theme) {
    final isTesting = state == ConnectionTestState.testing;

    const successFg = AppColorSchemes.success;

    Color? fgColor;
    if (state == ConnectionTestState.success) {
      fgColor = successFg;
    } else if (state == ConnectionTestState.failed) {
      fgColor = theme.colorScheme.error;
    } else {
      fgColor = theme.colorScheme.primary;
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('connection-test-button'),
        onPressed: isTesting ? null : onTest,
        icon: isTesting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                state == ConnectionTestState.success
                    ? Icons.check_circle
                    : state == ConnectionTestState.failed
                        ? Icons.error
                        : Icons.bug_report,
                size: 20,
              ),
        label: Text(
          isTesting
              ? '测试中...'
              : state == ConnectionTestState.success
                  ? '连接成功'
                  : state == ConnectionTestState.failed
                      ? '连接失败'
                      : '测试连接',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
        ),
      ),
    );
  }

  Widget _buildResultMessage(ThemeData theme) {
    final isSuccess = state == ConnectionTestState.success;
    final msg =
        isSuccess ? '$message · 延迟 ${latencyMs ?? '?'}ms' : message ?? '';

    const successFg = AppColorSchemes.success;
    final successBg = AppColorSchemes.success.withValues(alpha: 0.12);
    final errorFg = theme.colorScheme.error;
    final errorBg = theme.colorScheme.errorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSuccess ? successBg : errorBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            size: 16,
            color: isSuccess ? successFg : errorFg,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSuccess ? successFg : errorFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
