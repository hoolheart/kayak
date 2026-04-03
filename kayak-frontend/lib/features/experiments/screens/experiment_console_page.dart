/// Experiment console page
///
/// Provides experiment execution console with method selector,
/// parameter config, control buttons, status display, and real-time log
library;

// m-09 fix: Internationalization support
// All user-visible strings in this file should use i18n (flutter_localizations).
// For production, replace hardcoded Chinese strings with:
//   import 'package:flutter_localizations/flutter_localizations.dart';
//   import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// And use AppLocalizations.of(context).xxx for all strings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/experiment.dart';
import '../providers/experiment_console_provider.dart';
import '../services/experiment_ws_client.dart';

/// Experiment console page
class ExperimentConsolePage extends ConsumerStatefulWidget {
  final String? experimentId;

  const ExperimentConsolePage({super.key, this.experimentId});

  @override
  ConsumerState<ExperimentConsolePage> createState() =>
      _ExperimentConsolePageState();
}

class _ExperimentConsolePageState extends ConsumerState<ExperimentConsolePage>
    with SingleTickerProviderStateMixin {
  ExperimentWebSocketClient? _wsClient;
  final ScrollController _logScrollController = ScrollController();
  // C-03 fix: Store TextEditingControllers in a map to manage lifecycle
  final Map<String, TextEditingController> _parameterControllers = {};
  // m-02 fix: Animation controller for RUNNING state pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // BUG-006/007 fix: Track scroll position for auto-scroll and new logs indicator
  bool _userScrolledAwayFromBottom = false;
  bool _newLogsAvailable = false;
  int _lastLogCount = 0;

  @override
  void initState() {
    super.initState();
    // m-02 fix: Initialize pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // BUG-006/007 fix: Add scroll listener to detect user scrolling
    _logScrollController.addListener(_onLogScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // C-05 fix: Pass experimentId to initialize if provided
      ref.read(experimentConsoleProvider.notifier).initialize(
            experimentId: widget.experimentId,
          );
      _setupWebSocket();
    });
  }

  // BUG-006/007 fix: Handle scroll to detect if user scrolled away from bottom
  void _onLogScroll() {
    if (!_logScrollController.hasClients) return;

    final maxScroll = _logScrollController.position.maxScrollExtent;
    final currentScroll = _logScrollController.position.pixels;
    final isAtBottom = (maxScroll - currentScroll) < 50; // 50px threshold

    if (isAtBottom && _userScrolledAwayFromBottom) {
      // User scrolled back to bottom - clear indicator and auto-scroll
      setState(() {
        _userScrolledAwayFromBottom = false;
        _newLogsAvailable = false;
      });
    } else if (!isAtBottom && !_userScrolledAwayFromBottom) {
      setState(() {
        _userScrolledAwayFromBottom = true;
      });
    }
  }

  // BUG-006/007 fix: Scroll to bottom and clear indicator
  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      setState(() {
        _userScrolledAwayFromBottom = false;
        _newLogsAvailable = false;
      });
    }
  }

  void _setupWebSocket() {
    _wsClient = ExperimentWebSocketClient();
    ref.read(experimentConsoleProvider.notifier).setWebSocketClient(_wsClient!);

    // Listen to status changes
    _wsClient!.statusChanges.listen((statusChange) {
      if (mounted) {
        ref
            .read(experimentConsoleProvider.notifier)
            .handleWsStatusChange(statusChange.newStatus);
      }
    });

    // Listen to log entries
    _wsClient!.logEntries.listen((logEntry) {
      if (mounted) {
        ref.read(experimentConsoleProvider.notifier).handleWsLog(logEntry);
      }
    });

    // Listen to connection status
    _wsClient!.connectionStatus.listen((connected) {
      if (mounted) {
        ref.read(experimentConsoleProvider.notifier).setWsConnected(connected);
      }
    });

    // C-05 fix: Connect WebSocket with experiment ID if provided
    // Note: WebSocket URL should include experiment ID for proper routing
    // The actual connection is initiated by the provider when experiment is loaded
  }

  @override
  void dispose() {
    _wsClient?.dispose();
    _logScrollController.dispose();
    // C-03 fix: Dispose all parameter controllers
    for (final controller in _parameterControllers.values) {
      controller.dispose();
    }
    _parameterControllers.clear();
    // m-02 fix: Dispose pulse animation controller
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(experimentConsoleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('试验执行控制台'),
        actions: [
          // WebSocket connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.wsConnected ? Icons.wifi : Icons.wifi_off,
                  size: 18,
                  color: state.wsConnected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  state.wsConnected ? '已连接' : '未连接',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: state.wsConnected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.experiment == null
              ? _buildErrorState(context, state.error!)
              : _buildContent(context, state),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(experimentConsoleProvider.notifier).initialize();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExperimentConsoleState state) {
    return Column(
      children: [
        // Experiment info section
        _buildExperimentInfo(context, state),

        // Control buttons
        _buildControlButtons(context, state),

        // Parameter config
        _buildParameterConfig(context, state),

        // Log output
        Expanded(child: _buildLogOutput(context, state)),
      ],
    );
  }

  Widget _buildExperimentInfo(
      BuildContext context, ExperimentConsoleState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status display
          Row(
            children: [
              const Text('状态: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildStatusChip(context, state),
            ],
          ),
          const SizedBox(height: 12),

          // Method selector (M-07, M-08 fix: handle loading, error, and empty states)
          Row(
            children: [
              const Text('方法: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodSelector(context, state),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // M-07/M-08 fix: Build method selector with error and empty state handling
  Widget _buildMethodSelector(
      BuildContext context, ExperimentConsoleState state) {
    final colorScheme = Theme.of(context).colorScheme;

    // Handle loading state
    if (state.isLoading && state.availableMethods.isEmpty) {
      return const LinearProgressIndicator();
    }

    // Handle empty methods list
    if (state.availableMethods.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '暂无可用方法',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to create method page
                      context.push('/methods/create');
                    },
                    child: const Text('创建方法'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Normal dropdown
    return DropdownButtonFormField<String>(
      key: const Key('method_selector'),
      value: state.selectedMethodId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        hintText: '选择试验方法',
      ),
      items: state.availableMethods
          .map((method) => DropdownMenuItem(
                value: method.id,
                child: Text(method.name),
              ))
          .toList(),
      onChanged: state.experiment?.status == ExperimentStatus.idle
          ? (value) {
              if (value != null) {
                ref
                    .read(experimentConsoleProvider.notifier)
                    .selectMethod(value);
              }
            }
          : null,
    );
  }

  Widget _buildStatusChip(BuildContext context, ExperimentConsoleState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = state.experiment?.status;

    Color backgroundColor;
    Color textColor;
    final bool isRunning = status == ExperimentStatus.running;

    if (status == null) {
      backgroundColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    } else {
      switch (status) {
        case ExperimentStatus.idle:
          backgroundColor = colorScheme.surfaceContainerHighest;
          textColor = colorScheme.onSurfaceVariant;
          break;
        case ExperimentStatus.loaded:
          backgroundColor = colorScheme.secondaryContainer;
          textColor = colorScheme.onSecondaryContainer;
          break;
        case ExperimentStatus.running:
          backgroundColor = colorScheme.primaryContainer;
          textColor = colorScheme.onPrimaryContainer;
          break;
        case ExperimentStatus.paused:
          backgroundColor = colorScheme.tertiaryContainer;
          textColor = colorScheme.onTertiaryContainer;
          break;
        case ExperimentStatus.completed:
          backgroundColor = colorScheme.secondaryContainer;
          textColor = colorScheme.onSecondaryContainer;
          break;
        case ExperimentStatus.aborted:
          backgroundColor = colorScheme.errorContainer;
          textColor = colorScheme.onErrorContainer;
          break;
      }
    }

    // m-02 fix: Wrap RUNNING status in pulse animation
    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        state.statusLabel,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );

    if (isRunning) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: child,
          );
        },
        child: statusChip,
      );
    }

    return statusChip;
  }

  Widget _buildControlButtons(
      BuildContext context, ExperimentConsoleState state) {
    // m-04 fix: Check if specific operation is in progress
    final isLoading = state.currentOperation == ControlOperation.load;
    final isStarting = state.currentOperation == ControlOperation.start;
    final isPausing = state.currentOperation == ControlOperation.pause;
    final isResuming = state.currentOperation == ControlOperation.resume;
    final isStopping = state.currentOperation == ControlOperation.stop;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // m-04 fix: Show spinner inside button when load operation is in progress
          _buildControlButton(
            context: context,
            key: 'btn_load',
            label: '载入',
            icon: Icons.download,
            isLoading: isLoading,
            isEnabled: state.canLoad && !state.isControlling,
            onPressed: isLoading
                ? null
                : () {
                    ref
                        .read(experimentConsoleProvider.notifier)
                        .loadExperiment();
                  },
          ),
          _buildControlButton(
            context: context,
            key: 'btn_start',
            label: '开始',
            icon: Icons.play_arrow,
            isLoading: isStarting,
            isEnabled: state.canStart && !state.isControlling,
            onPressed: isStarting
                ? null
                : () {
                    ref
                        .read(experimentConsoleProvider.notifier)
                        .startExperiment();
                  },
          ),
          _buildControlButton(
            context: context,
            key: 'btn_pause',
            label: '暂停',
            icon: Icons.pause,
            isLoading: isPausing,
            isEnabled: state.canPause && !state.isControlling,
            onPressed: isPausing
                ? null
                : () {
                    ref
                        .read(experimentConsoleProvider.notifier)
                        .pauseExperiment();
                  },
          ),
          _buildControlButton(
            context: context,
            key: 'btn_resume',
            label: '继续',
            icon: Icons.play_circle_outline,
            isLoading: isResuming,
            isEnabled: state.canResume && !state.isControlling,
            onPressed: isResuming
                ? null
                : () {
                    ref
                        .read(experimentConsoleProvider.notifier)
                        .resumeExperiment();
                  },
          ),
          _buildControlButton(
            context: context,
            key: 'btn_stop',
            label: '停止',
            icon: Icons.stop,
            isLoading: isStopping,
            isEnabled: state.canStop && !state.isControlling,
            isError: true,
            onPressed: isStopping
                ? null
                : () {
                    _showStopConfirm(context);
                  },
          ),
        ],
      ),
    );
  }

  // m-04 fix: Helper widget to build button with optional loading indicator
  Widget _buildControlButton({
    required BuildContext context,
    required String key,
    required String label,
    required IconData icon,
    required bool isLoading,
    required bool isEnabled,
    required VoidCallback? onPressed,
    bool isError = false,
  }) {
    final buttonStyle = isError
        ? FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          )
        : null;

    return FilledButton.icon(
      key: Key(key),
      onPressed: onPressed,
      style: buttonStyle,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildParameterConfig(
      BuildContext context, ExperimentConsoleState state) {
    final method = state.availableMethods.firstWhere(
      (m) => m.id == state.selectedMethodId,
      orElse: () => state.availableMethods.isEmpty
          ? throw StateError('No methods')
          : state.availableMethods.first,
    );

    if (method.parameterSchema.isEmpty) {
      // M-03 fix: Show message when method has no parameters
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '此方法无需配置参数',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '参数配置',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              // M-02 fix: Add reset to defaults button
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(experimentConsoleProvider.notifier)
                      .resetParametersToDefaults();
                },
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('重置默认值'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...method.parameterSchema.entries.map((entry) {
            final schema = entry.value as Map<String, dynamic>;
            final type = schema['type'] as String? ?? 'string';
            final unit = schema['unit'] as String?;
            final description = schema['description'] as String?;
            final currentValue = state.parameterValues[entry.key];

            // M-01 fix: Get validation error for this parameter
            final error = state.parameterErrors[entry.key];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            // M-10 fix: Show description as hint text
                            if (description != null && description.isNotEmpty)
                              Text(
                                description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildParameterInput(
                          context,
                          entry.key,
                          type,
                          currentValue,
                          state,
                        ),
                      ),
                      if (unit != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(unit,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
                // M-01 fix: Show validation error below parameter
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 168, bottom: 4),
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // C-03 fix: Get or create controller for parameter
  // m-08 fix: Preserve cursor position when updating text
  TextEditingController _getParameterController(
      String name, dynamic currentValue) {
    if (!_parameterControllers.containsKey(name)) {
      _parameterControllers[name] = TextEditingController(
        text: currentValue?.toString() ?? '',
      );
    } else {
      // Update text if value changed externally, preserving cursor position
      final controller = _parameterControllers[name]!;
      final currentText = currentValue?.toString() ?? '';
      if (controller.text != currentText) {
        // Save cursor position relative to end of text
        final oldLength = controller.text.length;
        final newLength = currentText.length;
        final cursorOffset = controller.selection.baseOffset;
        final cursorFromEnd = cursorOffset >= 0 ? oldLength - cursorOffset : 0;

        controller.text = currentText;

        // Restore cursor position at same distance from end
        final newCursor = newLength - cursorFromEnd;
        if (newCursor >= 0 && newCursor <= newLength) {
          controller.selection = TextSelection.collapsed(offset: newCursor);
        }
      }
    }
    return _parameterControllers[name]!;
  }

  Widget _buildParameterInput(
    BuildContext context,
    String name,
    String type,
    dynamic currentValue,
    ExperimentConsoleState state,
  ) {
    final notifier = ref.read(experimentConsoleProvider.notifier);
    final controller = _getParameterController(name, currentValue);

    switch (type) {
      case 'number':
        return TextField(
          key: Key('param_$name'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          controller: controller,
          onChanged: (value) {
            final num = double.tryParse(value);
            if (num != null) {
              notifier.updateParameter(name, num);
            }
          },
        );
      case 'integer':
        return TextField(
          key: Key('param_$name'),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          controller: controller,
          onChanged: (value) {
            final num = int.tryParse(value);
            if (num != null) {
              notifier.updateParameter(name, num);
            }
          },
        );
      case 'boolean':
        return Switch(
          key: Key('param_$name'),
          value: currentValue == true,
          onChanged: (value) {
            notifier.updateParameter(name, value);
          },
        );
      default:
        return TextField(
          key: Key('param_$name'),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          controller: controller,
          onChanged: (value) {
            notifier.updateParameter(name, value);
          },
        );
    }
  }

  Widget _buildLogOutput(BuildContext context, ExperimentConsoleState state) {
    final colorScheme = Theme.of(context).colorScheme;

    // BUG-006/007 fix: Auto-scroll when new logs arrive if user is at bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.logs.length > _lastLogCount) {
        _lastLogCount = state.logs.length;
        if (!_userScrolledAwayFromBottom) {
          // User is at bottom - auto-scroll to new log
          _scrollToBottom();
        } else {
          // User scrolled away - show indicator
          setState(() {
            _newLogsAvailable = true;
          });
        }
      }
    });

    return Column(
      children: [
        // Log header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border:
                Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Text(
                '执行日志',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ref.read(experimentConsoleProvider.notifier).clearLogs();
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('清空'),
              ),
            ],
          ),
        ),
        // Log content
        Expanded(
          child: Stack(
            children: [
              Container(
                color: colorScheme.surfaceContainerLowest,
                child: ListView.builder(
                  key: const Key('log_list'),
                  controller: _logScrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: state.logs.length,
                  itemBuilder: (context, index) {
                    final log = state.logs[index];
                    return _buildLogEntry(context, log);
                  },
                ),
              ),
              // BUG-007 fix: Show "new logs available" indicator when user scrolled away
              if (_newLogsAvailable)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FilledButton.tonal(
                      onPressed: _scrollToBottom,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_downward, size: 16),
                          SizedBox(width: 4),
                          Text('新日志'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogEntry(BuildContext context, ConsoleLogEntry log) {
    final colorScheme = Theme.of(context).colorScheme;

    Color levelColor;
    switch (log.level.toLowerCase()) {
      case 'error':
        levelColor = colorScheme.error;
        break;
      case 'warn':
        levelColor = colorScheme.tertiary;
        break;
      case 'debug':
        // m-01 fix: Add grey color for debug level
        levelColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
        break;
      default:
        levelColor = colorScheme.onSurfaceVariant;
    }

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[$timeStr] ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            '[${log.level.toUpperCase()}] ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
          ),
          Expanded(
            child: Text(
              log.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStopConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('停止试验'),
        content: const Text('确定要停止当前试验吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm_stop'),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(experimentConsoleProvider.notifier).stopExperiment();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('停止'),
          ),
        ],
      ),
    );
  }
}
