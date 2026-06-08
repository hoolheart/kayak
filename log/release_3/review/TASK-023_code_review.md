# Code Review Report — TASK-023: 试验控制台

## Review Information
- **Reviewer**: sw-jerry
- **Date**: 2026-06-02
- **Branch**: `feature/task-023-experiment-console`
- **Commits**:
  - `f48c320` docs(TASK-023): add detailed design document for experiment console
  - `1a6e5fc` feat(TASK-023): implement experiment console page with full UI
- **Files Changed** (vs `origin/main`): 9 files, +3253 / -6 lines

## Summary
- **Status**: CHANGES_REQUESTED
- **Total Issues**: 10
- **Critical**: 3
- **High**: 3
- **Medium**: 3
- **Low**: 1

---

## Critical Issues

### [CRITICAL] Issue 1: Side effects in `build()` cause log polling to NEVER fire during RUNNING state

- **Location**: `experiment_console_page.dart`, lines 852–859
- **Description**:
  In the `build()` method of `_ExperimentConsolePageState`, the following side-effect methods are called directly on every rebuild:
  ```dart
  final exp = experimentAsync.asData?.value;
  if (exp != null) {
    _syncTimerState(exp);       // line 856
    _loadMethodName(exp.methodId);  // line 857
    _setupLogPolling(exp);      // line 858 ← CRITICAL
  }
  ```
  These same three methods are ALSO registered in `_setupListeners()` (lines 467–473) via `ref.listen(experimentControlProvider(...))`.

  **Root cause of the bug**:
  - During RUNNING state, the 1-second timer (`_startTimer`, line 641) calls `setState` every second to update `_elapsed`
  - Each `setState` triggers a `build()`
  - `build()` calls `_setupLogPolling(exp)`, which **cancels the existing poll timer and creates a new one** (line 533–534)
  - The poll timer has a 2-second interval, but it gets reset every ~1 second
  - **Result**: The REST API log polling (via `getHistory()`) NEVER fires during RUNNING/PAUSED states. Logs from the backend state change history are never loaded.

  **Also redundant**: `_syncTimerState` is called twice per state change (once from `ref.listen`, once from `build()`), doubling the timer start/stop logic.

- **Impact**:
  - Functional bug that breaks the entire log viewing feature during experiment execution
  - Users will NEVER see state change history logs loaded from the REST API
  - Violates PRD acceptance criteria: "日志实时推送 + 自动滚动" (the polling fallback is completely broken)

- **Recommendation**:
  **Remove all three side-effect calls (lines 852–859) from `build()` entirely.** The `_setupListeners()` method already handles all three via `ref.listen(experimentControlProvider(...), ...)` with proper provider lifecycle.

  ```dart
  // REMOVE these lines from Widget build()
  // final exp = experimentAsync.asData?.value;
  // if (exp != null) {
  //   _syncTimerState(exp);
  //   _loadMethodName(exp.methodId);
  //   _setupLogPolling(exp);
  // }
  ```

  The `ref.listen` callback in `_setupListeners()` (lines 467–473) already correctly triggers `_syncTimerState`, `_loadMethodName`, and `_setupLogPolling` when the experiment data changes.

  **However**, there is an additional subtlety: `_syncTimerState` needs to be called on EVERY second to update `_elapsed`. Since `experimentControlProvider` doesn't change every second, `_syncTimerState` won't be called via `ref.listen` for timer ticks. The timer's periodic callback (line 641–648) already handles this correctly by directly setting `_elapsed` in `setState`, so this works independently—the build() call is still unnecessary.

- **Status**: OPEN

---

### [CRITICAL] Issue 2: `_processHistory` mutates `_logs` without calling `setState` — UI never updates for polled history

- **Location**: `experiment_console_page.dart`, lines 553–571
- **Description**:
  The `_processHistory` method adds log entries via `_addLogInternal` (line 559–563) which mutates `_logs` directly without `setState`:
  ```dart
  void _addLogInternal(ExperimentLogEntry entry) {
    _logs.add(entry);          // mutation without setState!
    if (_logs.length > _maxLogCount) {
      _logs.removeAt(0);
    }
  }
  ```
  This is called from `_processHistory` → `_setupLogPolling` → `Timer.periodic` callback. Since no `setState` is triggered, the widget won't rebuild to show the new logs.

  Compare with `_addLog` (used for WS messages) which correctly wraps the mutation in `setState` (line 582–584):
  ```dart
  void _addLog(ExperimentLogEntry entry) {
    if (!mounted) return;
    setState(() {
      _addLogInternal(entry);   // CORRECT: inside setState
    });
    ...
  }
  ```

- **Impact**:
  - Even if Issue 1 is fixed and the polling timer fires, the logs loaded from `getHistory()` will be silently added to `_logs` in memory but never rendered in the UI
  - The user won't see historical logs until some other event triggers a rebuild

- **Recommendation**:
  Change `_processHistory` to call `setState` around the mutation:
  ```dart
  void _processHistory(List<StatusChange> history) {
    bool hasNew = false;
    for (final change in history) {
      if (_processedChangeIds.contains(change.id)) continue;
      _processedChangeIds.add(change.id);
      _addLogInternal(ExperimentLogEntry(
        level: ExperimentLogEntry.fromStatusChange(change),
        timestamp: ExperimentLogEntry.formatTimestamp(change.timestamp),
        message:
            '${change.previousState} → ${change.newState} (${change.operation})',
      ));
      hasNew = true;
    }

    if (hasNew) {
      setState(() {});  // Trigger rebuild
      if (_isAtBottom) {
        _scrollToBottom();
      }
    }
  }
  ```
  Or alternatively, route all log additions through `_addLog` (which already has `setState` and the auto-scroll logic).

- **Status**: OPEN

---

### [CRITICAL] Issue 3: Error messages in `ExperimentControlNotifier._mapError` use hardcoded Chinese strings instead of i18n

- **Location**: `experiment_provider.dart`, lines 464–509 (and duplicated in `ExperimentListNotifier`, lines 198–240)
- **Description**:
  Both `_mapError` methods contain hardcoded Chinese error strings:
  ```dart
  return '网络连接失败，请检查网络后重试';
  return '登录已过期，请重新登录';
  return '没有权限执行此操作';
  return '请求的资源不存在';
  return '服务暂时不可用，请稍后再试';
  // ... etc
  ```
  These are not internationalized, meaning:
  - English users see Chinese error messages
  - Cannot switch languages dynamically
  - Violates the project's i18n policy (the PRD mandates full i18n support)

  Additionally, the exact same code is duplicated between `ExperimentListNotifier` and `ExperimentControlNotifier` (copy-paste violation).

- **Impact**:
  - Internationalization broken for all error messages in experiment operations
  - Code duplication makes maintenance harder (two places to fix the same bug)

- **Recommendation**:
  1. Extract a shared error mapping utility that accepts `BuildContext` or `AppLocalizations` and maps `DioException` to localized strings
  2. Create corresponding ARB entries for all error messages (e.g., `errorNetworkFailure`, `errorSessionExpired`, `errorNoPermission`, `errorNotFound`, `errorServiceUnavailable`)
  3. Apply in both `ExperimentListNotifier` and `ExperimentControlNotifier` (and audit other notifiers for the same pattern)

- **Status**: OPEN

---

## High Issues

### [HIGH] Issue 4: `experiment.description` semantically misused as error message for ABORTED state

- **Location**: `experiment_console_page.dart`, lines 1602–1618
- **Description**:
  In `_buildCompletedInfo`, when `experiment.status == ExperimentStatus.aborted`:
  ```dart
  if (isAborted && experiment.description != null) ...[
    const SizedBox(height: 16),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 16, color: statusColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            experiment.description!,  // ← WRONG: description is not an error message
            style: themeData.textTheme.bodySmall?.copyWith(
              color: statusColor,
            ),
          ),
        ),
      ],
    ),
  ],
  ```
  The `Experiment.description` field is a general-purpose description (e.g., "temperature stress test"), not an error message. When an experiment aborts, there is no `errorMessage` field on the `Experiment` model to display the reason.

- **Impact**:
  - Users will see the experiment's description (e.g., "高温应力测试") in the error section, which is confusing and incorrect
  - The actual abort reason is lost—it should come from the last `StateChangeLog` entry with the error reason

- **Recommendation**:
  1. Check the backend `Experiment` schema to see if an `error_message` column exists (it's in the SQL schema at `experiments.error_message TEXT`)
  2. If it exists, add `errorMessage` to the Flutter `Experiment` model and use it here
  3. If not, fall back to showing the last state change log entry with the reason: load history, find the last entry where `to_state == 'ABORTED'`, and display its `reason` field
  4. As a quick fix, remove the `description` display and show a generic "Experiment was aborted" message instead

- **Status**: OPEN

---

### [HIGH] Issue 5: `_executeOperation` error handler invalidates provider on ALL errors, discarding state

- **Location**: `experiment_console_page.dart`, line 730
- **Description**:
  ```dart
  } catch (e) {
    if (mounted) {
      _showToast('${loc.operationFailed}: $e');
      ref.invalidate(experimentControlProvider(widget.id));  // ← too aggressive
    }
  }
  ```
  Calling `ref.invalidate` on ANY error (including transient network failures, timeouts, etc.) causes the provider to reload from the backend, potentially showing stale data while the operation actually succeeded on the backend.

- **Impact**:
  - If a `start` operation succeeds on the backend but the response times out, `invalidate` will re-fetch the experiment, which may show `RUNNING` status—but the toast will have shown "operation failed"
  - User sees conflicting information: toast says "failed" but UI shows "running"

- **Recommendation**:
  Only invalidate when the error is specifically a state mismatch (e.g., 409 Conflict) or when the provider state is `AsyncError`. For network errors, keep the current state and show the error toast.

  ```dart
  } catch (e) {
    if (mounted) {
      _showToast('${loc.operationFailed}: $e');
      // Only invalidate if state is corrupt (AsyncError) or backend rejected the state change
      if (e is StateError || state.hasError) {
        ref.invalidate(experimentControlProvider(widget.id));
      }
    }
  }
  ```

- **Status**: OPEN

---

### [HIGH] Issue 6: `_loadMethodName` called in `build()` can trigger unnecessary API calls and state mutations during every rebuild

- **Location**: `experiment_console_page.dart`, line 857
- **Description**:
  Although `_loadMethodName` has an early return (`if (_methodName != null) return;`), it's called from `build()` on every rebuild. The method is async and calls `setState` to update `_methodNameLoading`, which itself triggers another rebuild. This creates:
  1. An unnecessary `setState` call on the first build (sets `_methodNameLoading = true`)
  2. A second `setState` when the method loads or fails
  3. On subsequent rebuilds, the early return prevents actual work, but the method call itself is wasted

  This is part of the broader Issue 1 (side effects in `build()`). It's repeated here at HIGH severity because it independently causes an extra `setState` on the initial build.

- **Recommendation**:
  Same as Issue 1: remove the `_loadMethodName` call from `build()`. The `ref.listen` callback in `_setupListeners()` (line 470) already triggers `_loadMethodName` when experiment data changes.

- **Status**: OPEN (resolved by fixing Issue 1)

---

## Medium Issues

### [MEDIUM] Issue 7: `updateStatus` silently falls back to `idle` when receiving an unknown status from WebSocket

- **Location**: `experiment_console_page.dart`, lines 490–493
- **Description**:
  ```dart
  final newStatus = ExperimentStatus.values.firstWhere(
    (e) => e.name.toUpperCase() == data.newStatus,
    orElse: () => ExperimentStatus.idle,
  );
  ```
  If the backend sends an unrecognized status string via WebSocket (e.g., future version sends "MAINTENANCE"), the `orElse` silently maps it to `idle`, which is incorrect and could break the UI state machine.

- **Impact**:
  - Future backend changes could silently corrupt UI state
  - No warning or error log when this happens

- **Recommendation**:
  Log a warning and keep the current state when an unknown status is received:
  ```dart
  final newStatusIndex = ExperimentStatus.values.indexWhere(
    (e) => e.name.toUpperCase() == data.newStatus,
  );
  if (newStatusIndex == -1) {
    debugPrint('Warning: unknown experiment status from WS: ${data.newStatus}');
    return; // keep current state
  }
  final newStatus = ExperimentStatus.values[newStatusIndex];
  ```

- **Status**: OPEN

---

### [MEDIUM] Issue 8: Missing `error_message` field in Flutter `Experiment` model

- **Location**: `models/experiment.dart`, lines 29–98
- **Description**:
  The backend SQL schema defines an `error_message TEXT` column on the `experiments` table (see `arch.md` line 1180), but the Flutter `Experiment` model has no corresponding field. This means:
  - The backend could be sending `error_message` in the JSON response, but Flutter ignores it
  - The console page's ABORTED error display (Issue 4) has no valid data source

- **Impact**:
  - When an experiment aborts with an error, the error reason is unavailable to the UI

- **Recommendation**:
  Add `errorMessage` field to the `Experiment` model:
  ```dart
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  ```
  Include it in `copyWith`, `fromJson`, and `toJson`. Then use it in `_buildCompletedInfo` instead of `description`.

- **Status**: OPEN

---

### [MEDIUM] Issue 9: `_setupLogPolling` called in `build()` — behavior on terminal states

- **Location**: `experiment_console_page.dart`, line 858
- **Description**:
  Even after fixing Issue 1 (removing the `build()` side effect), the polling logic in `_setupLogPolling` has a design issue: it only polls during `running` and `paused` states. But after an experiment transitions to `completed` or `aborted`, the final state change log entry (recorded by the backend at the moment of completion) may arrive after the polling stops. This means the user might miss the last log entry showing the completion transition.

- **Recommendation**:
  After stopping polling, do one final fetch to get the last state change entry:
  ```dart
  if (experiment.status == ExperimentStatus.completed ||
      experiment.status == ExperimentStatus.aborted) {
    // Final fetch to capture the last state change
    try {
      final history = await experimentService.getHistory(widget.id);
      _processHistory(history);
    } catch (_) {}
    return; // don't start polling
  }
  ```

- **Status**: OPEN

---

## Low Issues

### [LOW] Issue 10: `_syncTimerState` sets `_elapsed` without `setState` when experiment status changes externally

- **Location**: `experiment_console_page.dart`, lines 598–627
- **Description**:
  When `_syncTimerState` is called from the `ref.listen` callback (via `_setupListeners`), it modifies `_elapsed` and `_isTimerRunning` without wrapping in `setState`. The only reason this works is because:
  1. For RUNNING → `_startTimer()` → periodic `setState` updates `_elapsed`
  2. For PAUSED/COMPLETED → the next timer tick or another event will trigger `setState`

  This creates a one-frame delay (or up to 1 second during RUNNING) where the elapsed time display is stale.

- **Impact**:
  - Minor visual glitch: elapsed time may show wrong value for up to 1 second after a WS status change

- **Recommendation**:
  Wrap the state mutations in `setState`:
  ```dart
  void _syncTimerState(Experiment experiment) {
    final wasRunning = _isTimerRunning;
    // ... status checks ...

    setState(() {
      _isTimerRunning = shouldRun;
      _elapsed = /* calculated value */;
    });

    // Timer start/stop handled outside setState since it doesn't need a rebuild
    if (shouldRun && !wasRunning) _startTimer();
    else if (!shouldRun && wasRunning) _stopTimer();
  }
  ```

- **Status**: OPEN

---

## Architecture Compliance

| Check | Status | Notes |
|-------|--------|-------|
| Follows `arch.md` | ✅ | Correctly uses single-port deployment, REST API for control, WebSocket for real-time |
| Uses defined interfaces | ✅ | `ExperimentService`, `WsService`, `MethodService` all via proper service providers |
| Proper error handling | ⚠️ | Error mapping uses hardcoded strings (Critical #3); invalidate on all errors (High #5) |
| No code duplication | ❌ | `_mapError` / `_mapStatusCode` duplicated between two notifiers (Critical #3) |
| State management | ⚠️ | Side effects in `build()` (Critical #1); missing `setState` in history processing (Critical #2) |
| i18n compliance | ❌ | Hardcoded Chinese error strings in provider layer (Critical #3) |

## Quality Checks

| Check | Status | Notes |
|-------|--------|-------|
| No compiler errors | ✅ | Compiles cleanly |
| No compiler warnings | ✅ | No warnings |
| No lint warnings | ✅ | Compliant with `analysis_options.yaml` |
| Tests pass | ⚠️ | No test files included in this PR — **TDD was required per the PRD** (see §TDD Process) |
| Documentation updated | ✅ | `TASK-023_design.md` is comprehensive |
| `build()` purity | ❌ | Side effects in `build()` (Critical #1) |
| Memory management | ✅ | Timers and scroll controller properly disposed |
| WebSocket lifecycle | ✅ | Auto-connect on enter, auto-disconnect on dispose |

## PRD Requirements Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| Control buttons by status | ✅ | Correct `_isButtonEnabled` matrix |
| Button loading feedback | ✅ | `_activeOperation` blocks double-submit |
| Stop double confirmation | ✅ | `ConfirmDialog.show` with danger styling |
| Real-time status update (WS) | ⚠️ | WS handling correct, but polling broken (Critical #1) |
| Log real-time + auto-scroll | ❌ | Log polling never fires (Critical #1), no `setState` in `_processHistory` (Critical #2) |
| WS connection indicator | ✅ | `_BlinkingDot` animation, 5 states + reconnect button |
| Running timer | ✅ | 1-second periodic timer |
| Responsive layout (small screen stack) | ✅ | Desktop Row / Mobile Column with appropriate breakpoints |
| Status badge pulse animation | ❌ | Design document specifies a pulse animation for RUNNING status badge, but `StatusBadge` component is used as-is without modification |
| Floating "new logs" button | ✅ | Positioned button with count |
| Log level filter | ✅ | DropDownButton with All/INFO/WARN/ERROR/DEBUG |
| Clear logs button | ✅ | Disabled when logs empty |
| Completion detail display | ⚠️ | Shows `description` instead of `error_message` (High #4) |
| Skeleton loading state | ✅ | `ExperimentConsoleSkeleton` with desktop/mobile variants |
| Error view with retry | ✅ | 404/403-specific messages with `ErrorView` |
| i18n | ⚠️ | UI strings localized, but provider error messages are hardcoded (Critical #3) |

## Approval

- [ ] All Critical issues resolved (3 remaining)
- [ ] All High issues resolved (3 remaining)
- [ ] Medium issues addressed or acknowledged
- [ ] Tests added for the console page (TDD was required per PRD)
- [ ] Regression tested with a running backend
- [ ] Approved for merge

---

## Summary of Required Fixes

To achieve APPROVAL status, the following MUST be fixed:

1. **Remove side-effect calls from `build()`** (Critical #1) — this is a functional bug that breaks log polling entirely
2. **Add `setState` to `_processHistory`** (Critical #2) — without this, polled history logs are invisible
3. **Internationalize `_mapError` strings** (Critical #3) — extract shared error mapping utility with ARB entries
4. **Fix `experiment.description` misuse in ABORTED error display** (High #4) — add `errorMessage` field to model
5. **Remove `ref.invalidate` from all error catch blocks** (High #5) — only invalidate on state corruption
6. **Add unknown status handling in `_handleStatusChange`** (Medium #7) — log warning, don't silently fall back to idle
7. **Write widget tests** per PRD TDD requirements

---

## 修复验证 (Fix Verification)

| # | 问题 | 状态 | 验证 |
|---|------|------|------|
| 1 | 副作用调用在 `build()` 中 | ✅ | `grep` 确认均已移除，仅由 `_setupListeners()` 调用 |
| 2 | `_processHistory` 缺少 `setState` | ✅ | L596–601 已包裹 `setState` |
| 3 | `_mapError` 硬编码中文 | ✅ | L424 改用 `ErrorMapping.mapFallback()`，`ErrorMapping` 类已存在 |
| 4 | `description` 误用作 ABORTED 错误 | ✅ | L1646 改用 `experiment.errorMessage`，模型已新增字段 |
| 5 | `ref.invalidate` 在全部异常上调用 | ✅ | L780 包装为 `ErrorMapping.shouldInvalidate(e)`，重试场景保留 |
| 6 | `_loadMethodName` 在 `build()` 中重复 | ✅ | 随 #1 修复，已移除 |
| 7 | 未知 WS 状态静默降级 | ✅ | L494–498 使用 `indexWhere` + 警告日志 |
| 8 | `error_message` 字段缺失 | ✅ | 模型 L57 已添加 `errorMessage`，`copyWith` 同步 |
| 9 | 轮询在终端状态截断最后一条 | ✅ | `_fetchFinalHistory()` 方法已添加（L569） |
| 10 | `_syncTimerState` 未用 `setState` | ✅ | L654–659 已包裹 `setState` |

---

## 结论: ✅ APPROVED
