# Code Review Report — TASK-020

## Review Information
- **Reviewer**: sw-jerry
- **Date**: 2026-06-01
- **Branch**: `feature/task-020-experiment-service-provider`
- **Reference Docs**:
  - Detailed Design: `log/release_3/design/TASK-020_design.md` (v2.0)
  - Test Cases: `log/release_3/test/TASK-020_test_cases.md`
  - Architecture: `arch.md`

## Summary
- **Status**: **APPROVED**
- **Total Issues**: 4
- **Critical**: 0
- **High**: 0
- **Medium**: 1
- **Low**: 3

---

## Issues Found

### [MEDIUM] Issue 1: Inconsistent JSON Serialization — Manual `fromJson`/`toJson` vs. `@JsonSerializable` Codegen

**Location**:
- `kayak-frontend/lib/models/experiment.dart`, Lines 111–136 (`CreateExperimentRequest`)
- `kayak-frontend/lib/models/experiment.dart`, Lines 146–209 (`ExperimentControlDto`)
- `kayak-frontend/lib/models/experiment.dart`, Lines 218–260 (`ExperimentStatusDto`)
- `kayak-frontend/lib/models/experiment.dart`, Lines 269–325 (`StatusChange`)
- `kayak-frontend/lib/models/experiment.dart`, Lines 332–372 (`DataQueryParams`)
- `kayak-frontend/lib/models/experiment.dart`, Lines 380–416 (`TimeSeriesData`)
- `kayak-frontend/lib/models/experiment_message.dart`, Lines 1–175 (`ExperimentMessage`, `StatusChangeData`, `WsErrorData`)

**Description**: The design document (§7.1-7.7) explicitly specifies `@JsonSerializable()` for six model classes (`CreateExperimentRequest`, `StatusChange`, `DataQueryParams`, `TimeSeriesData`, `ExperimentControlDto`, `ExperimentStatusDto`) and `@Freezed`/`@Freezed()` for three sealed-related classes (`ExperimentMessage`, `StatusChangeData`, `WsErrorData`).

However, the implementation uses **hand-written `fromJson()` and `toJson()`** for all nine classes. Only the pre-existing `Experiment` class uses `@JsonSerializable()` with `_$ExperimentFromJson`/`_$ExperimentToJson`.

The rest of the codebase consistently uses `@JsonSerializable()` as the standard pattern:
- `point.dart` → `point.g.dart` (generated)
- `device.dart` → `device.g.dart` (generated)
- `method.dart` → `method.g.dart` (generated)
- `workbench.dart` → `workbench.g.dart` (generated)
- `common.dart` → `common.g.dart` (generated)

For the `ExperimentMessage` sealed class, the design specifies freezed (`@Freezed` annotation) — the implementation uses a manual sealed class with factory constructors, which is functionally equivalent but misses freezed's pattern-matching helpers (`when`, `map`, `maybeWhen`).

**Impact**:
- **Style inconsistency**: The file uses two different serialization strategies (`@JsonSerializable` for `Experiment`, manual for everything else) within the same file.
- **Maintenance burden**: Adding/renaming a field requires editing the hand-written `fromJson`/`toJson` in addition to the constructor — `@JsonSerializable` generates this automatically.
- **Human error risk**: A missed field in the manual `fromJson`/`toJson` (e.g., not adding `@JsonKey(name: 'method_id')` updates in both directions) can introduce subtle serialization bugs that the codegen would prevent.
- **No `experiment_message.freezed.dart` or `experiment_message.g.dart`**: The generated files don't exist, confirming these are all manual implementations.

**Recommendation**: 
1. Apply `@JsonSerializable()` to `CreateExperimentRequest`, `ExperimentControlDto`, `ExperimentStatusDto`, `StatusChange`, `DataQueryParams`, and `TimeSeriesData`.
2. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate.
3. Consider migrating `ExperimentMessage` to freezed for sealed class pattern-matching support.

**Effort**: ~1-2 hours for a follow-up refactoring task.

**Status**: OPEN (non-blocking — defer to follow-up task)

---

### [LOW] Issue 2: Enum `ConnectionState` Renamed to `WsConnectionState` Without Design Doc Note

**Location**: `kayak-frontend/lib/services/ws_service.dart`, Lines 10–25

**Description**: The design document (§6.2) defines the enum as `ConnectionState`. The implementation uses `WsConnectionState`. This is a pragmatic choice — Dart/Flutter already has a built-in `ConnectionState` in `dart:async` (used by `StreamSubscription`), so the rename avoids ambiguity and potential import conflicts.

**Impact**: None functionally. The rename prevents confusion with Flutter's `ConnectionState`. However, the design document was not updated to reflect this change.

**Recommendation**: Add a comment in the design document explaining the rationale for the rename. No code changes needed.

**Status**: OPEN (minor — document the rationale)

---

### [LOW] Issue 3: `StreamController` Used Instead of `BehaviorSubject` for Connection State

**Location**: `kayak-frontend/lib/services/ws_service.dart`, Lines 49, 54, 57

**Description**: The design document (§6.2) specifies using `BehaviorSubject<ConnectionState>` from the `rxdart` package to manage connection state, which provides "replay latest value to new subscribers" semantics. The implementation uses a plain `StreamController<WsConnectionState>.broadcast()` (line 49) with a separate `_currentConnectionState` field (line 54) to track the latest value, plus the `connectionState` getter (line 63-64) that falls back to `Stream.empty()` when no controller exists.

This is functionally equivalent but:
- The fallback `Stream.empty()` in the getter means new subscribers during `disconnect()` will receive an empty stream instead of the last known state (`disconnected`).
- The `BehaviorSubject.seeded(ConnectionState.disconnected)` pattern from the design would provide the disconnected state to all subscribers at all times.

**Impact**: Low. In practice, subscribers access `connectionState` while the controller is active, and the `currentConnectionState` getter provides the current snapshot. The `Stream.empty()` fallback is only hit during the brief window between `connect()` and `_tryConnect()` establishing the state controller.

**Recommendation**: Consider using `BehaviorSubject.seeded(WsConnectionState.disconnected)` from `rxdart` (if already a dependency) for cleaner semantics. Or add a `StreamController.broadcast()` that is initialized eagerly (not lazily in `connect()`) so the fallback is never needed.

**Status**: OPEN (minor — can defer indefinitely)

---

### [LOW] Issue 4: `AsyncNotifier` Used Instead of `AutoDisposeAsyncNotifier` as Specified in Design

**Location**:
- `kayak-frontend/lib/providers/experiment_provider.dart`, Line 27 (`ExperimentListNotifier extends AsyncNotifier`)
- `kayak-frontend/lib/providers/experiment_provider.dart`, Line 220 (`ExperimentControlNotifier extends AsyncNotifier`)

**Description**: The design document class diagram (§2) and interface definitions (§6.3) specify both notifiers as extending `AutoDisposeAsyncNotifier`:
```
ExperimentListNotifier --|> AutoDisposeAsyncNotifier : 继承
ExperimentControlNotifier --|> AutoDisposeAsyncNotifier : 继承
```

The implementation uses plain `AsyncNotifier` for both. This is a pragmatic choice:
- `ExperimentListNotifier` is a top-level provider that should live for the app's lifetime — auto-dispose would be counterproductive.
- `ExperimentControlNotifier` is already scoped by `AsyncNotifierProvider.family` with the experiment ID — different IDs are different providers, so garbage collection is naturally scoped.

**Impact**: None functionally. For these providers, the auto-dispose behavior would actually be undesirable (the list should stay in memory, and the experiment detail should persist while the user is on the page).

**Recommendation**: Update the design document to reflect the actual implementation choice (plain `AsyncNotifier`). No code changes needed. This deviation is well-justified.

**Status**: OPEN (document only — update design doc)

---

## Architecture Compliance

| Check | Status | Notes |
|-------|:------:|-------|
| Follows Riverpod 3.x AsyncNotifier pattern | ✅ | `ExperimentListNotifier extends AsyncNotifier<List<Experiment>>`, `ExperimentControlNotifier extends AsyncNotifier<Experiment>` with `build()`, both correct |
| Data flow: Backend → Service → Provider → Widget | ✅ | Clean unidirectional flow: `ExperimentService` / `WsService` → `ExperimentListNotifier` / `ExperimentControlNotifier` → Widget layer |
| Service constructor injection | ✅ | `ExperimentService(ApiClient)` matches `DeviceService` pattern |
| Uses `ApiResponse<T>` wrapping for all HTTP calls | ✅ | All service methods unwrap via `ApiResponse<T>.fromJson(data, fromJsonT)` |
| Uses `PaginatedResponse<T>` for list endpoints | ✅ | `list()` returns `PaginatedResponse<Experiment>` with `items` and `total` |
| WebSocket URL construction correct | ✅ | `ws://localhost:8080/ws/experiments/{id}?token={token}` — matches backend |
| Connection state machine (5 states) | ✅ | `WsConnectionState`: disconnected → connecting → connected → reconnecting → failed |
| Exponential backoff reconnect | ✅ | `_nextReconnectDelay()` uses `pow(2, attempt-1)` capped at 8s, max 5 attempts |
| Stream cancellation safety (`cancelOnError: false`) | ✅ | Correctly set on WebSocket stream subscription |
| `_disposed` flag prevents reconnect after manual disconnect | ✅ | Checked in `_onDone()`, `_tryConnect()`, and `disconnect()` |
| Control operation state transition validation | ✅ | `_validateStateTransition()` enforces the 6-status matrix per design §3.1 |
| Anti-concurrency guard (`_isOperationInProgress`) | ✅ | Prevents duplicate control operations, throws `StateError` |
| Provider auto-cleanup on dispose | ✅ | `ref.onDispose(wsService.disconnect)` in experimentWsProvider |
| Three-state handling (loading/error/data) | ✅ | `AsyncLoading` / `AsyncError` / `AsyncData` correctly used |

## Quality Checks

| Check | Status | Notes |
|-------|:------:|-------|
| No compiler errors | ✅ | `flutter analyze` passes clean |
| No compiler warnings | ✅ | Clean |
| No lint warnings | ✅ | Clean |
| Tests execution pending | ⚠️ | Test cases exist in `log/release_3/test/TASK-020_test_cases.md` — execution by sw-mike pending |
| Code matches design document | ⚠️ | 1 Medium deviation (serialization pattern), 3 Low deviations (enum name, BehaviorSubject, AutoDispose) |
| No code duplication | ✅ | `_executeControl` pattern properly shared across all 5 control methods |
| Proper error handling | ✅ | DioException type handling, HTTP status code mapping, error state recovery |
| JSON field name mapping (snake_case ↔ camelCase) | ✅ | All `@JsonKey` annotations correct where applicable |
| Dispose/cleanup correctness | ✅ | `_cleanup()` cancels timer, closes WebSocket sink, closes StreamControllers |
| Broadcast StreamController pattern | ✅ | Correctly used for multi-subscriber scenarios |

## File-by-File Verdict

### New/Modified Files

| File | Verdict | Notes |
|------|:-------:|-------|
| `lib/models/experiment.dart` | ⚠️ Style Issue | `Experiment` uses `@JsonSerializable()` ✅. All 6 new classes (`CreateExperimentRequest`, `ExperimentControlDto`, `ExperimentStatusDto`, `StatusChange`, `DataQueryParams`, `TimeSeriesData`) use manual `fromJson`/`toJson` — deviation from codebase convention and design spec (Issue 1). `copyWith` is manual (not generated) — correct for this case. |
| `lib/models/experiment_message.dart` | ⚠️ Style Issue | Sealed class manually implemented (not freezed as per design §7.5). `StatusChangeData` and `WsErrorData` use manual serialization (Issue 1). `ExperimentMessage.fromJson()` dispatch logic correct. |
| `lib/services/experiment_service.dart` | ✅ Good | Clean API wrapping. All 12 methods follow the `ApiResponse<T>.fromJson()` pattern. Enum→UPPERCASE serialization correct. DateTime→ISO 8601 correct. `queryData` correctly builds `DataQueryParams` and merges `device_id`. |
| `lib/services/ws_service.dart` | ✅ Good | WebSocket lifecycle correctly managed. Auto-reconnect with exponential backoff correct. `_onDone` gate (`_disposed`, `_reconnectAttempts >= maxReconnectAttempts`) correct. Message parsing delegates to `ExperimentMessage.fromJson()`. `cancelOnError: false` prevents stream termination on parse errors. Manual enum name `WsConnectionState` avoids Flutter `ConnectionState` conflict (Issue 2). |
| `lib/providers/experiment_provider.dart` | ✅ Good | `ExperimentListNotifier`: build/refresh/loadMore/setFilter all correct. `_currentPage--` on error is a good defensive pattern. `ExperimentControlNotifier`: `_executeControl` generic pattern shared across all 5 operations. `_validateStateTransition` enforces 6-status matrix correctly. `_isOperationInProgress` guard works. State recovery on error preserves previous state. WebSocket providers correctly set up with `onDispose`. |
| `lib/providers/services.dart` | ✅ Good | Two new providers (`experimentServiceProvider`, `wsServiceProvider`) cleanly registered. |

## Approval

- [x] No Critical issues — no blocking items
- [x] No High issues — no security/performance/robustness concerns
- [x] Medium issues: 1 (serialization inconsistency — deferrable)
- [x] Low issues: 3 (documentation/patterns — deferrable)
- [x] Code meets quality standards
- [x] **APPROVED for merge**

---

## Overall Assessment

The implementation is **architecturally solid and functionally complete**. The three-layer design (Model ↔ Service ↔ Provider) is correctly implemented following the established Riverpod 3.x patterns used throughout the codebase.

### Strengths
1. **WebSocket lifecycle management** is robust: exponential backoff reconnect, dispose-safety via `_disposed` flag, `cancelOnError: false` for message parsing resilience, and proper cleanup in all exit paths.
2. **State transition validation** is comprehensive: the 6×5 validation matrix from the design document is faithfully implemented with clear `StateError` messages for each invalid transition.
3. **Anti-concurrency guard** (`_isOperationInProgress`) prevents duplicate control operations at the Provider level.
4. **Error handling** follows the established `_mapError` / `_mapStatusCode` pattern used in other providers.
5. **Provider cleanup** is correct: `ref.onDispose(wsService.disconnect)` ensures WebSocket is torn down when the widget tree disposes.

### Concerns (all non-blocking)
The primary concern is the **inconsistent serialization pattern** (Issue 1). The codebase standard is `@JsonSerializable()` with code generation — six of the seven new model classes (plus three experiment_message classes) use manual `fromJson`/`toJson` instead. While functionally correct, this creates a maintenance divergence within the same file (`Experiment` uses codegen, everything else is manual) and against the project-wide convention.

The three Low issues are all design doc deviations with sound rationale (enum rename avoids Flutter conflict, `AsyncNotifier` fits the lifecycle better than `AutoDisposeAsyncNotifier`, `StreamController` is functionally equivalent to `BehaviorSubject`). They should be documented in the design doc but do not warrant code changes.

### Recommendation
**Merge as-is.** The Medium issue (serialization) should be addressed in a follow-up refactoring task that also updates the design document for the three Low-issue deviations. Creating a dedicated task avoids scope creep on TASK-020 and allows sw-tom to focus on remaining release tasks.

---

## 终审结论

**审查人**: sw-jerry  
**日期**: 2026-06-01  
**结论**: ✅ **APPROVED** — 无 blocking issues，可合并

| 严重等级 | 总数 | 阻塞合并 | 延后处理 |
|:-------:|:---:|:-------:|:-------:|
| Critical | 0 | 0 | 0 |
| High | 0 | 0 | 0 |
| Medium | 1 | 0 | 1 |
| Low | 3 | 0 | 3 |

### Issue 明细

| Issue | 严重等级 | 状态 | 说明 |
|:-----:|:-------:|:----:|:-----|
| 1 — 手动 JSON vs `@JsonSerializable` | Medium | ⏸️ DEFERRED | 9 个类使用手动 `fromJson`/`toJson`，与代码库的 `@JsonSerializable` 惯例（point.dart、device.dart 等）不一致。功能正确，不阻塞合并。建议后续创建统一 refactoring 任务。 |
| 2 — `ConnectionState` → `WsConnectionState` | Low | ⏸️ DEFERRED | 为避免与 Dart 内置 `ConnectionState` 冲突而重命名。功能正确，更新设计文档即可。 |
| 3 — `StreamController` vs `BehaviorSubject` | Low | ⏸️ DEFERRED | 功能等价。`Stream.empty()` fallback 仅在短暂的时间窗口内使用，无实际影响。 |
| 4 — `AsyncNotifier` vs `AutoDisposeAsyncNotifier` | Low | ⏸️ DEFERRED | 对列表 Provider 和 family Provider 而言，非 auto-dispose 更符合生命周期需求。更新设计文档即可。 |

### 验证方法

```
cd kayak-frontend && flutter analyze --fatal-infos
```
**结果**：`No issues found!` — 零警告、零错误。

### 技术债务备注
- **Issue 1** 建议创建独立 TASK（`TASK-0xx：统一实验模型 JSON 序列化为 @JsonSerializable`），工作量约 1-2 小时，风险极低。
- **Issue 2-4** 建议更新 `log/release_3/design/TASK-020_design.md` 修订记录，记录实施过程中的这些合理偏离及其理由。
