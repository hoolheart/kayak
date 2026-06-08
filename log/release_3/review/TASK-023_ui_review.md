# UI Design Review — TASK-023 试验控制台

> **Reviewer**: sw-jerry (Software Architect)
> **Date**: 2026-06-02
> **Documents Reviewed**:
> - `log/release_3/ui/specifications/experiment_console_spec.md`
> - `log/release_3/ui/figma/TASK-023_experiment_console.txt`
> **Verdict**: **NEEDS_REVISION** — 2 blocking issues, 2 high issues

---

## Summary

| Dimension | Assessment |
|-----------|------------|
| **Layout & Responsive** | 🟢 GOOD — 3 breakpoints, clear structure, matches Sprint 4 conventions |
| **ExperimentProvider 对接** | 🟡 PARTIAL — 5 control buttons map perfectly; info card resolution blocked |
| **WsService 对接** | 🔴 BLOCKING — `ExperimentMessage` missing `log` type for execution logs |
| **Info Card (工作台/方法)** | 🔴 BLOCKING — `Experiment` model has no `workbenchId`; resolution path undefined |
| **Control Button State Matrix** | 🟢 GOOD — Aligns exactly with `ExperimentControlNotifier._validateStateTransition` |
| **Timer Implementation** | 🟢 GOOD — `Experiment.startedAt`/`endedAt` available; `Timer.periodic` feasible |
| **Log Viewer Feasibility** | 🟡 PARTIAL — UI layout fine; data source missing |
| **WebSocket Status Indicator** | 🟢 GOOD — `WsConnectionState` enum maps 1:1 to spec states |
| **Status History Timeline** | 🟢 GOOD — `StatusChange` model + `loadHistory()` already exist |
| **Animation Spec** | 🟢 GOOD — All parameters achievable with standard Flutter animation widgets |
| **Dark Theme** | 🟢 GOOD — Proper token mapping for all 6 states |
| **i18n** | 🟡 NEEDS WORK — ~30 new translation keys implied, not enumerated |

---

## Issue 1: Experiment Model Missing `workbenchId` (CRITICAL — BLOCKING)

**Location**: `kayak-frontend/lib/models/experiment.dart` line 28
**Description**: The UI spec §3.1 Info Card displays workbench info:

```
Row 1: 工作台 → "温度实验室" (Body Large, On Surface)
Row 2: 方法 → "标准热循环" (Body Large, On Surface)
Row 3: 创建时间 → "2026-06-02 09:30"
```

However, the `Experiment` model has **no `workbenchId` field**:

```dart
class Experiment {
  final String id;
  final String userId;
  final String? methodId;      // ← only method binding
  final String name;
  final String? description;
  final ExperimentStatus status;
  final String ownerType;       // ← "individual" / "team", not workbench
  final String ownerId;
  // ... no workbenchId
}
```

The `ownerType`/`ownerId` fields represent **ownership** (who created the experiment), not the workbench that the experiment runs on. The workbench → experiment binding is a separate relationship that currently does not exist in the data model.

**Attempted workarounds evaluated and rejected**:
1. **Derive from method**: The `Method` model also has no `workbenchId`. Methods are standalone entities, not bound to a single workbench.
2. **Use ownerType/ownerId**: These are for user/team ownership, not workbench equipment binding.

**Impact**: The Info Card's "工作台" row cannot be populated. This is a visible, user-facing gap in the primary information area of the console.

**Recommendation**:
1. Add `workbench_id` field to the backend `experiments` table via a migration (note: this was already flagged in TASK-022 review §Issue 2 but never resolved).
2. Update backend `CreateExperimentRequest` to accept `workbench_id`.
3. Update the frontend `Experiment` model to include `workbenchId`.
4. Add a `WorkbenchService.getById()` method (current service only has `list()` and `create()`) for name resolution.

**Alternative** (if backend change is out of scope for this release): Drop the "工作台" row from the Info Card for now, showing only "方法" and "创建时间". Add a `[PLANNED]` annotation for a future release.

---

## Issue 2: WebSocket Missing Log Message Type (CRITICAL — BLOCKING)

**Location**: `kayak-frontend/lib/models/experiment_message.dart` line 10-46
**Description**: The UI spec's log viewer (§4) depends on receiving **execution log entries** via WebSocket. Each log entry requires:

```
Log Entry = { level: "INFO"|"WARN"|"ERROR"|"DEBUG", timestamp: "14:30:01", message: "..." }
```

However, `ExperimentMessage` sealed class only handles TWO message types:

```dart
sealed class ExperimentMessage {
  const factory ExperimentMessage.statusChange(StatusChangeData data) = ...;  // ← state changes
  const factory ExperimentMessage.wsError(WsErrorData data) = ...;             // ← errors only
}
```

**Missing**: `log` type for execution log entries. The `ExperimentMessage.fromJson()` factory has:
```dart
switch (type) {
  case 'status_change': ...  // ✅ exists
  case 'error': ...          // ✅ exists
  default: throw FormatException(...)  // ❌ log type will throw
}
```

**StatusChangeData fields** (`experimentId`, `oldStatus`, `newStatus`, `operation`, `userId`, `timestamp`) do NOT include `level` or `message` — these are state transition records, not execution logs.

**Impact**: The entire Log Viewer (right panel, ~40% of the page layout) has no data source. All 10 log-related Figma boards (画板 1, 2, 10, 11, 15, 18, 22, 26, 27, and the log interaction flow) cannot be implemented.

**Recommendation**: Define a `LogEntry` message type and add it to `ExperimentMessage`:

```dart
/// 日志条目数据
class LogEntryData {
  const LogEntryData({
    required this.experimentId,
    required this.level,      // "INFO" | "WARN" | "ERROR" | "DEBUG"
    required this.timestamp,  // RFC 3339 string
    required this.message,    // log message text
  });

  final String experimentId;
  final String level;
  final String timestamp;
  final String message;

  factory LogEntryData.fromJson(Map<String, dynamic> json) => LogEntryData(
    experimentId: json['experiment_id'] as String,
    level: json['level'] as String,
    timestamp: json['timestamp'] as String,
    message: json['message'] as String,
  );
}

// In ExperimentMessage sealed class, add:
case 'log':
  return ExperimentMessage.log(
    LogEntryData.fromJson(json['data'] as Map<String, dynamic>),
  );
```

**Double-check**: The PRD §1.4 lists `WS /ws/experiments/{id}` as providing "试验状态+日志推送". The backend must be verified/updated to actually send `type: "log"` messages. If the backend doesn't send them yet, this becomes a **backend dependency** for TASK-023.

---

## Issue 3: `getById()` Method for Workbench Service Missing (HIGH)

**Location**: `kayak-frontend/lib/services/workbench_service.dart` line 13-132
**Description**: To resolve workbench name in the Info Card (once Issue 1 is addressed), the frontend needs to call `GET /api/v1/workbenches/{id}`. However, `WorkbenchService` currently provides only:

| Method | Status |
|--------|--------|
| `list({page, size, search})` | ✅ Exists |
| `create(request)` | ✅ Exists |
| **`getById(id)`** | ❌ **Missing** |

**Impact**: Even after Issue 1 is resolved (adding `workbenchId` to Experiment), the workbench name cannot be fetched for display.

**Recommendation**: Add `WorkbenchService.getById(String id)`:

```dart
Future<Workbench> getById(String id) async {
  final response = await _client.get('/api/v1/workbenches/$id');
  final apiResponse = ApiResponse<Workbench>.fromJson(
    response.data as Map<String, dynamic>,
    (json) => Workbench.fromJson(json as Map<String, dynamic>),
  );
  return apiResponse.data;
}
```

---

## Issue 4: `ExperimentControlNotifier.build()` Doesn't Resolve Related Names (HIGH)

**Location**: `kayak-frontend/lib/providers/experiment_provider.dart` line 303-308
**Description**: The current `ExperimentControlNotifier.build()`:

```dart
Future<Experiment> build() async {
  final service = ref.read(experimentServiceProvider);
  final experiment = await service.getById(_experimentId);
  return experiment;  // ← returns bare Experiment, no related name resolution
}
```

The UI spec's Info Card requires:
- **Workbench name** (needs workbenchId + `WorkbenchService.getById()` — see Issue 1, 3)
- **Method name** (needs `MethodService.getById()`)

Compare with `ExperimentListNotifier` which explicitly fetches method names via `_fetchMethodNames()` and maintains a `_methodNames` cache.

**Impact**: The `AsyncValue<Experiment>` returned by `experimentControlProvider` does not include the workbench/method names needed by the Info Card. The page would need to make additional API calls, creating a waterfall:

```
1. experimentControlProvider.build() → get experiment (1 HTTP call)
2. Page detects methodId → MethodService.getById() (1 HTTP call)
3. Page detects workbenchId → WorkbenchService.getById() (1 HTTP call)
```

This waterfall of 3 sequential HTTP calls before the Info Card can render.

**Recommendation**: Either:
1. **(Preferred)** Update `ExperimentControlNotifier` to resolve related names during `build()` (parallel fetches after getting experiment), returning a richer state. Or create a dedicated `ExperimentConsoleNotifier` that wraps both the experiment and resolved metadata.
2. **(Simple)** Have the console page make parallel `Future.wait()` calls for workbench+method names, displaying skeleton placeholders until all resolve. This is simpler but moves data-fetching logic into the UI layer.

---

## Detailed Feasibility Assessment

### Layout & ExperimentProvider/WsService 对接

#### ✅ Control Button Group → `ExperimentControlNotifier`

The 5 control buttons map directly to notifier methods:

| Button | Spec State | Notifier Method | State Guard |
|--------|-----------|-----------------|-------------|
| 载入 (load) | IDLE only | `load(methodId:)` | `_validateStateTransition('load')` |
| 开始 (start) | LOADED only | `start()` | `_validateStateTransition('start')` |
| 暂停 (pause) | RUNNING only | `pause()` | `_validateStateTransition('pause')` |
| 继续 (resume) | PAUSED only | `resume()` | `_validateStateTransition('resume')` |
| 停止 (stop) | RUNNING/PAUSED | `stop()` | `_validateStateTransition('stop')` |

**State matrix alignment**: The spec's §8.2 button matrix matches `_validateStateTransition` exactly. ✅

**Loading state**: The notifier already sets `state = const AsyncLoading()` during operations and has `_isOperationInProgress` flag — both map directly to the spec's §8.3 "被点击按钮显示 CircularProgressIndicator, 其他按钮禁用". ✅

**Error state**: The notifier sets `AsyncError` on failure — maps to spec's §8.4 "显示 Error Toast". ✅

**Stop confirmation**: The spec requires a confirm dialog before `stop()`. This is a UI-layer concern (not notifier-level), implemented with `showDialog` before calling `notifier.stop()`. ✅

**Note on `load()` methodId parameter**: The notifier's `load()` requires a `methodId` parameter. The UI spec doesn't show a method selector before the "载入" button becomes active. This implies the method was already selected during experiment creation (TASK-022), and the experiment's `methodId` field should already be populated. The page should read `experiment.methodId` and pass it to `load()`. This is fine as long as the experiment has a method assigned.

#### ✅ WebSocket Connection State → `WsConnectionState`

The spec's `WsIndicator` component (§2.5) specifies 5 connection states. These map 1:1 to the `WsConnectionState` enum:

| Spec State | Dot Color | Text | WsConnectionState enum | Available via |
|------------|-----------|------|----------------------|---------------|
| disconnected | 🔴 Error | "已断开" | `disconnected` | `experimentConnectionStateProvider` |
| connecting | 🟡 Warning (blink) | "连接中..." | `connecting` | `experimentConnectionStateProvider` |
| connected | 🟢 Success | "已连接" | `connected` | `experimentConnectionStateProvider` |
| reconnecting | 🟡 Warning (blink) | "重连中(N/5)" | `reconnecting` | `experimentConnectionStateProvider` + `wsService.reconnectAttempts` |
| failed | 🔴 Error | "连接失败" + reconnect button | `failed` | `experimentConnectionStateProvider` |

**Reconnect attempt count**: `WsService.reconnectAttempts` provides the `N` for "重连中(N/5)". ✅

**Manual reconnect**: `WsService.reconnect()` is available. ✅

**Flashing animation**: The `connecting`/`reconnecting` states need a `BlinkingDot` widget (simple `AnimationController` with opacity loop). Feasible. ✅

#### ✅ Timer → `Experiment.startedAt`/`endedAt`

| Spec Requirement | Data Source | Implementation |
|------------------|------------|----------------|
| Running timer (HH:MM:SS, 1s update) | `experiment.startedAt` | `Timer.periodic(1s)` computing `DateTime.now().difference(startedAt)` |
| Paused timer (frozen) | Same, but timer paused | Stop `Timer.periodic`, retain last computed value |
| IDLE/LOADED → hidden | `startedAt == null` | Conditional rendering |
| COMPLETED/ABORTED → fixed | `endedAt - startedAt` | Compute once from model fields |

**Cleanup**: `Timer.periodic` must be cancelled on dispose. Use `ref.onDispose` in a dedicated timer provider, or manage within a `StatefulWidget`. ✅

#### 🔴 Log Viewer → No Data Source (see Issue 2)

The log viewer requires:
- **Data source**: WebSocket stream of `type: "log"` messages — **MISSING** from `ExperimentMessage`
- **Log entry model**: `LogEntryData` with `level`, `timestamp`, `message` — **NOT DEFINED**
- **Maximum 1000 entries**: Client-side list truncation — simple `.sublist(max(0, length-1000))`

The log viewer's UI components (empty state, scroll-to-bottom, floating button, level filter, clear button) are all technically feasible once the data model is defined. See Issue 2.

#### ✅ Status History Timeline (Figma 画板 28)

The completed/aborted state shows a status history timeline. Data source: `ExperimentControlNotifier.loadHistory()` returns `List<StatusChange>` (already implemented). The `StatusChange` model has all fields needed (previousState, newState, operation, userId, timestamp). ✅

### Info Card Data Resolution Flow

Once Issues 1-4 are addressed, the data flow is:

```
ExperimentControlNotifier.build()
  → ExperimentService.getById(id)       ← Experiment with workbenchId, methodId
  ↓
  → WorkbenchService.getById(workbenchId)  ← workbench name
  → MethodService.getById(methodId)        ← method name
  ↓
  Returns rich console state:
  { experiment, workbenchName, methodName }
```

### Responsive Layout Feasibility

The spec defines 3 breakpoints matching Sprint 4 conventions:

| Breakpoint | Layout | Implementation |
|------------|--------|----------------|
| ≥1024px (Desktop) | Row 38:62 | `LayoutBuilder` with `Row` |
| 600-1024px (Tablet) | Row 40:60 | `LayoutBuilder` with `Row` |
| <600px (Mobile) | Column | `LayoutBuilder` with `Column` |

**Note on breakpoint values**: The spec says `≥1200px` for desktop, but Sprint 4 uses `≥1024px`. See Issue 7 below.

### Widget Reuse Opportunities

| Spec Component | Existing Widget | Compatibility |
|---------------|----------------|---------------|
| Empty State | `EmptyView` | ✅ Direct reuse |
| Error State | `ErrorView` | ✅ Direct reuse |
| Skeleton Loading | `Skeleton` | ✅ Direct reuse |
| Toast | `Toast` | ✅ Direct reuse |
| ConfirmDialog (Stop) | Custom `AlertDialog` | ⚠️ Needs danger variant styling |
| StatusBadge/Chip | New `StatusChip` | ❌ New widget needed |
| WsIndicator | New `WsIndicator` | ❌ New widget needed |
| TimerDisplay | New `TimerDisplay` | ❌ New widget needed |
| LogEntry | New `LogEntry` | ❌ New widget needed |
| ControlButton | Material `FilledButton` | ✅ With custom styling |

### Animation Feasibility

All specified animations achievable with standard Flutter widgets:

| Animation | Widget | Cost |
|-----------|--------|------|
| Page entry (fade+slide) | `AnimatedSwitcher` or route transition | Low |
| Status text fade-out/in | `AnimatedOpacity` + `setState` | Low |
| Button press scale 0.97 | `AnimatedScale` or `Transform.scale` in `GestureDetector.onTapDown` | Low |
| StatusBadge pulse (RUNNING) | `AnimationController` repeat + `ScaleTransition` + `FadeTransition` | Medium |
| Log entry slide-in | `AnimatedList` or manual `SlideTransition` | Medium |
| Floating "New Logs" button | `AnimatedPositioned` + `FadeTransition` | Low |
| WS dot blink | `AnimationController` opacity loop | Low |

---

## Missing Implementation Dependencies

| Dependency | Status | Owner | Notes |
|-----------|--------|-------|-------|
| `Experiment.workbenchId` + backend support | ❌ Missing | Backend | Issue 1 — inherited from TASK-022 |
| `WorkbenchService.getById()` | ❌ Missing | Frontend | Issue 3 |
| `ExperimentMessage.log` type + `LogEntryData` | ❌ Missing | Frontend/Backend | Issue 2 |
| Backend WS sends `type: "log"` messages | ❓ Unknown | Backend | Issue 2 — needs verification |
| `StatusChip` (StatusBadge) component | ❌ New | Frontend (TASK-023) | ~80 LOC |
| `WsIndicator` component | ❌ New | Frontend (TASK-023) | ~60 LOC |
| `TimerDisplay` component | ❌ New | Frontend (TASK-023) | ~50 LOC |
| `LogEntry` / `LogViewer` component | ❌ New | Frontend (TASK-023) | ~200 LOC |
| `StopConfirmDialog` (danger variant) | ❌ New | Frontend (TASK-023) | ~60 LOC |
| l10n keys (~30 new) | ❌ Missing | Frontend (TASK-015) | Button labels, status text, log controls |

---

## Issue 5: `load()` Requires methodId But No UI for It (MEDIUM)

**Location**: Spec §3.2, `ExperimentControlNotifier.load()` line 313
**Description**: The notifier's `load()` method is:

```dart
Future<void> load({required String methodId}) async { ... }
```

The UI spec shows the "载入" button in IDLE state becoming active, but there is **no user-facing UI** for selecting or confirming which method to load. The spec's Info Card already shows a "方法" row, implying the method was selected during experiment creation (TASK-022). However:

- If the experiment's `methodId` is `null` (experiment created without method), the `load()` button has nothing to pass.
- The spec doesn't show a method selector dropdown or confirmation step before loading.

**Impact**: Edge case — experiments created without a method cannot transition from IDLE → LOADED, and the UI provides no path to select one.

**Recommendation**: Either:
1. **(Preferred)** During experiment creation (TASK-022), make `methodId` mandatory for experiments that will be loaded/executed.
2. **(Fallback)** In the console page, if `experiment.methodId == null`, show a method selector (dropdown) within the Info Card and disable the "载入" button until one is selected.

---

## Issue 6: Status Display — "大字状态" Not Consistent Across Spec Sections (LOW)

**Location**: Spec §3.3, §3.4
**Description**: §3.3 describes the status text as "32px (桌面) / 28px (移动端), w600". §3.4 provides the color mapping. However, the Figma (画板 1) shows:

```
Text: "RUNNING" (32px, w600, Success #2E7D32)
Subtext: "试验运行中" (Body Small, On Surface Variant)
```

The `ExperimentStatus` enum values (in Dart) are lowercase: `idle`, `loaded`, `running`, etc. The UI spec and Figma show UPPERCASE: "RUNNING", "IDLE", etc. This implies a `status.name.toUpperCase()` mapping, which is trivial but should be documented.

**Additionally**: The RUNNING state shows a **pulse animation** on the StatusBadge (top bar), but the spec §3.3 explicitly says the status text itself has **no animation** — only the badge pulses. This is a deliberate design decision that works well (avoids distracting the operator). ✅

**Recommendation**: Add a note in the implementation: status enum → display text via `status.name.toUpperCase()`. No changes to spec needed.

---

## Issue 7: Breakpoint Values Inconsistent with Sprint 4 (LOW)

**Location**: Spec §5.1
**Description**: The spec defines:

| Breakpoint | Width | Sprint 4 (arch.md) | Compatible? |
|------------|-------|---------------------|:-----------:|
| Desktop | ≥1200px | ≥1024px | ⚠️ Off by 176px |
| Tablet | 600-1200px | 600-1024px | ⚠️ Off by 176px |
| Mobile | <600px | <600px | ✅ |

This inconsistency was already flagged in TASK-022 review §Issue 5 and remains unresolved.

**Recommendation**: Align with Sprint 4 conventions (`≥1024px` for desktop). Update spec §5.1 breakpoint table. The existing `AppShell` already uses this breakpoint for `NavigationRail` vs `BottomNavigationBar`.

---

## Review Checklist

| # | Check Item | Status |
|---|-----------|--------|
| 1 | Experiment has `workbenchId` for Info Card display | 🔴 MISSING (Issue 1) |
| 2 | `WorkbenchService.getById()` exists for name resolution | 🔴 MISSING (Issue 3) |
| 3 | `MethodService.getById()` exists for method name resolution | ✅ EXISTS |
| 4 | WebSocket emits `type: "log"` messages for Log Viewer | 🔴 MISSING (Issue 2) |
| 5 | `ExperimentMessage.log` type defined in sealed class | 🔴 MISSING (Issue 2) |
| 6 | `ExperimentControlNotifier` resolves related names | 🔴 INCOMPLETE (Issue 4) |
| 7 | Control button state matrix matches notifier validation | ✅ MATCHES |
| 8 | `WsConnectionState` enum maps to spec's 5 connection states | ✅ 1:1 MATCH |
| 9 | Timer data available from `Experiment.startedAt`/`endedAt` | ✅ AVAILABLE |
| 10 | `StatusChange` model + `loadHistory()` for timeline | ✅ EXISTS |
| 11 | Route `/experiments/:id` inside ShellRoute (correct for console) | ✅ CORRECT |
| 12 | Responsive breakpoints consistent with Sprint 4 | ⚠️ INCONSISTENT (Issue 7) |
| 13 | All text uses l10n keys | ⚠️ Keys not enumerated |
| 14 | Light + Dark theme tokens specified for all 6 states | ✅ COMPLETE |
| 15 | Widgets reuse existing components (EmptyView, ErrorView, Skeleton, Toast) | ✅ REUSABLE |
| 16 | Animation parameters achievable with standard Flutter widgets | ✅ ACHIEVABLE |
| 17 | `load()` methodId handling for experiments without method | ⚠️ EDGE CASE (Issue 5) |
| 18 | Stop confirm dialog follows Material 3 dialog patterns | ✅ FEASIBLE |
| 19 | Log floating button state management feasible | ✅ FEASIBLE |
| 20 | 28 Figma boards cover all 6 states + 3 breakpoints + 2 themes | ✅ COMPLETE |

---

## Required Revisions (Blocking Approval)

1. **Add `workbenchId` to `Experiment` model and backend schema** — The Info Card's "工作台" row has no data source. Either add the field or drop the row from the spec. (Issue 1)

2. **Define `LogEntryData` model and add `log` type to `ExperimentMessage`** — The entire Log Viewer has no data source. This requires both:
   - Frontend: New `LogEntryData` model + `ExperimentMessage.log` sealed class variant
   - Backend: Verify/set up WS to send `type: "log"` messages
   (Issue 2)

3. **Add `WorkbenchService.getById()`** — Required for workbench name resolution in Info Card. (Issue 3)

4. **Address Info Card name resolution** — Update `ExperimentControlNotifier.build()` or create console-specific provider to fetch workbench/method names alongside experiment data. (Issue 4)

5. **Handle `load()` methodId edge case** — Document what happens when an experiment has no methodId (either make method mandatory during creation, or add method selector to console page). (Issue 5)

6. **Align responsive breakpoints** — Change spec §5.1 desktop breakpoint from `≥1200px` to `≥1024px` to match Sprint 4 conventions. (Issue 7)

---

## Approved Items (No Revision Needed)

- ✅ Layout structure: 38:62 split, 3 breakpoints, responsive column stack
- ✅ Control button state matrix: matches `_validateStateTransition` exactly
- ✅ Button loading/isOperationInProgress state: maps to `AsyncLoading` + `_isOperationInProgress`
- ✅ WS connection indicator: `WsConnectionState` enum maps 1:1
- ✅ WS lifecycle: auto-connect via `experimentWsProvider`, auto-disconnect via `ref.onDispose`
- ✅ Manual reconnect: `WsService.reconnect()` available
- ✅ Timer implementation: `Experiment.startedAt`/`endedAt` sufficient
- ✅ Status history timeline: `StatusChange` model + `loadHistory()` available
- ✅ Animation specs: all achievable with standard Flutter widgets
- ✅ Dark theme: complete token mapping for all 6 states
- ✅ Stop confirm dialog: feasible with `showDialog` + custom styling
- ✅ Design QA checklist (§9): comprehensive, covers all states and interactions

---

**Document end**
