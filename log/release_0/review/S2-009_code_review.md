# S2-009 Code Review: Basic Step Execution Engine

**Reviewer**: sw-jerry (Software Architect)  
**Date**: 2026-04-02  
**Branch**: `feature/s2-009-step-execution-engine`  
**Design Reference**: `log/release_0/design/S2-009_design.md` (v1.1)  
**Status**: NEEDS REVISION

---

## Overall Assessment

The implementation is **well-structured and largely faithful** to the approved design. The module organization is clean, the trait abstractions follow DIP principles, and the 14 inline tests all pass. The core execution flow (empty process handling, linear step execution, fail-fast error propagation, listener callbacks) matches the design specification.

However, there are several issues that need addressing before this can be approved — most notably a **tight coupling in `DriverAccessAdapter`** that undermines the DIP goals, a **lock-type discrepancy** from the design, and **missing test coverage** for the failure-propagation path.

---

## Specific Issues

### MAJOR

#### M-1: `DriverAccessAdapter` is tightly coupled to `VirtualConfig` (DIP concern)

**File**: `adapter.rs` (lines 17-21)

```rust
pub struct DriverAccessAdapter<'a> {
    driver: &'a dyn DeviceDriver<
        Config = crate::drivers::r#virtual::VirtualConfig,
        Error = DriverError,
    >,
}
```

**Problem**: The adapter hardcodes `VirtualConfig` as the associated type constraint. This means `DriverAccessAdapter` can only work with `VirtualDriver`, defeating the purpose of the `DriverAccess` abstraction. When a `ModbusDriver` or `CanDriver` is added later, this adapter will need to be rewritten or duplicated.

The design document (Section 4.5) shows the adapter accepting `&'a dyn DeviceDriver` without associated type constraints, implying a more generic approach.

**Impact**: Future driver types cannot use this adapter without modification. The engine layer now has a transitive dependency on `drivers::r#virtual`, which violates the layering boundary.

**Recommendation**: Either:
- (a) Make the adapter generic: `DriverAccessAdapter<'a, D: DeviceDriver>` — but this leaks the concrete type to callers.
- (b) Use a trait-object-friendly approach: define a separate internal trait (e.g., `DriverAccessProvider`) that `DeviceManager` implements, avoiding the associated-type problem entirely.
- (c) Accept the current approach as a pragmatic S2-009 limitation but add a `TODO` comment and track it as a known technical debt item for S2-010+.

**Severity**: MAJOR — undermines the DIP principle that this module was designed around.

---

#### M-2: Lock type discrepancy — `read()` vs `write()` lock

**File**: `step_engine.rs` (line 83)

```rust
let driver = driver_lock.read().map_err(|_| {
```

**Problem**: The design document (Section 4.2, line 820) explicitly specifies acquiring a **write lock** (`driver_lock.write()`), but the implementation uses a **read lock** (`driver_lock.read()`).

**Analysis**: The implementation is actually *correct* and *better* than the design. `DeviceDriver::read_point` and `write_point` both take `&self` (not `&mut self`), so a read lock is sufficient. The design document was mistaken in specifying a write lock.

**Recommendation**: The code is correct as-is. **Update the design document** to reflect `read()` lock instead of `write()`, and update the comment on line 82 of `step_engine.rs` which says "获取驱动的可变引用（写锁）" — it should say "获取驱动的只读引用（读锁）". The comment was already partially corrected but the parenthetical still says "写锁".

**Severity**: MAJOR (documentation/design sync issue, not a code bug).

---

#### M-3: Missing failure-propagation integration test

**Files**: `step_engine.rs` (tests module)

**Problem**: There is no test that verifies the **fail-fast behavior** — i.e., when a step fails, subsequent steps are not executed. The design explicitly requires this (Section 4.3), and the error sequence diagram (Section 6.3) illustrates it. The current tests only cover success paths and `DeviceNotFound`.

**Missing scenarios**:
- A Read step fails (e.g., driver not connected) → subsequent steps should not execute
- The `EngineError::ExecutionFailed` variant should contain the correct `context` with logs from steps that ran before the failure
- The listener's `step_failed` and `process_completed` callbacks should fire on failure

**Recommendation**: Add at least one integration test:
```rust
#[tokio::test]
async fn test_execute_fail_fast_on_read_error() {
    // Register a VirtualDriver but don't connect it
    // Execute a process with Start -> Read -> End
    // Verify: Read fails, End is NOT executed, context.status == Failed
    // Verify: listener.step_failed and listener.process_completed were called
}
```

**Severity**: MAJOR — fail-fast is a core design requirement that is untested at the integration level.

---

### MINOR

#### m-1: Unused import in `step_engine.rs`

**File**: `step_engine.rs` (line 12)

```rust
use super::executor::{DriverAccess, StepExecutor};
```

`DriverAccess` is imported but not directly used in this file (it's used via `DriverAccessAdapter`). The `StepExecutor` trait is also not directly referenced — the concrete executor structs are used. These imports are not harmful but are unnecessary.

**Severity**: MINOR

---

#### m-2: Test `MockDriver` in `start.rs` uses `unimplemented!()`

**File**: `steps/start.rs` (lines 84-90)

The `MockDriver` in the Start step tests uses `unimplemented!()` for `read_point` and `write_point`. This is fine for Start tests since those methods are never called, but it's a code smell. If someone accidentally calls them, the test will panic rather than fail gracefully.

**Recommendation**: Use `Err(ExecutionError::InternalError(...))` or `unreachable!()` instead to make intent clearer. Alternatively, use a shared mock from a test utilities module (as suggested in the design's Section 9.2).

**Severity**: MINOR

---

#### m-3: `use` statement ordering in test modules

**Files**: `steps/start.rs` (line 91), `steps/delay.rs` (line 46), `steps/end.rs` (line 39)

In several test modules, `use uuid::Uuid;` appears at the bottom of the test module after the `MockDriver` struct definition. Conventionally, `use` statements should be at the top of the module.

**Severity**: MINOR (style)

---

#### m-4: `ProcessResult::from_context` loses original error type

**File**: `types.rs` (lines 441-446)

```rust
error: context
    .logs
    .iter()
    .find(|log| log.status == StepStatus::Failed)
    .and_then(|log| log.error_message.as_ref())
    .map(|msg| ExecutionError::InternalError(msg.clone())),
```

The original `ExecutionError` is converted to a string in the log entry, then reconstructed as `ExecutionError::InternalError`. This loses the original error variant (`DriverError`, `ConfigError`, etc.). The `EngineError::ExecutionFailed` variant preserves the original error, so this is not critical — but `ProcessResult` is the type exposed to listeners, and listeners lose error type information.

**Recommendation**: Consider storing the original `ExecutionError` (or at least its variant type) in `StepLogEntry` instead of just the string message. This is a design-level observation for future improvement.

**Severity**: MINOR (design observation, not a bug)

---

#### m-5: `ExecutionContext` not `Clone` — limits future extensibility

**File**: `types.rs` (line 252)

`ExecutionContext` derives only `Debug`. The design does not require `Clone`, and it's reasonable given that `StepLogEntry` contains `DateTime<Utc>` which is `Clone` but the overall struct is intentionally non-copyable. However, if pause/resume functionality (design Section 12, item 4) is added later, `Clone` or `Serialize` will be needed.

**Recommendation**: No action needed now. Add a comment noting this intentional omission with a reference to the pause/resume future work item.

**Severity**: MINOR (future-proofing note)

---

#### m-6: `adapter.rs` imports `VirtualConfig` creating cross-layer dependency

**File**: `adapter.rs` (line 10)

```rust
use crate::drivers::core::{DeviceDriver, DriverError, PointValue};
```

Combined with the associated type constraint `Config = crate::drivers::r#virtual::VirtualConfig`, the `engine` module now has a direct dependency on `drivers::r#virtual`. The design (Section 1.3) states the engine should depend on `drivers::core::DeviceDriver` (trait) and `drivers::manager::DeviceManager`, but not on specific driver implementations.

This is the same root cause as M-1.

**Severity**: MINOR (architectural layering concern, subsumed by M-1)

---

## Positive Observations

1. **Clean module structure**: The file layout matches the design exactly. Each concern is well-separated.
2. **Trait design**: `ExecutionListener` with default empty implementations is elegant and matches the design perfectly.
3. **Idempotent Start**: The Start step correctly implements idempotency (TC-014) by checking `start_time.is_none()` before setting.
4. **Error handling**: The `EngineError::ExecutionFailed` variant carrying the full `ExecutionContext` is well-designed for debugging.
5. **Test quality**: The listener test using `AtomicUsize` is a clean approach for verifying callback counts without `Mutex` overhead.
6. **All 14 tests pass**: No compilation warnings in the engine module itself.
7. **`ProcessDefinition` validation**: Duplicate ID check, first/last step validation — all correctly implemented.
8. **`lib.rs` registration**: `pub mod engine;` is correctly added.

---

## Suggestions for Improvement

1. **Add a `MockDriverAccess` test utility** as specified in the design (Section 9.2). The design provides a well-thought-out `MockDriverAccess` and `MockExecutionListener` that should be added to a `test_utils` module within `engine/` for reuse across all step tests.

2. **Consider adding a Control step to `test_execute_full_process`**: The current full process test includes Start, Read, Delay, End but skips Control. Adding a Control step would increase integration coverage.

3. **Add `#[must_use]` to `ProcessResult`**: Since `ProcessResult` is constructed but its return value from `from_context` is only used for listener callbacks, marking it `#[must_use]` would prevent accidental discarding in future code.

4. **Document the lock choice**: Add a comment in `step_engine.rs` explaining why a read lock is used instead of a write lock, referencing the `DeviceDriver` trait's `&self` signature on `read_point`/`write_point`.

---

## Test Coverage Summary

| Scenario | Covered? | Location |
|----------|----------|----------|
| Empty process → Completed | Yes | `test_execute_empty_process` |
| Simple Start→End | Yes | `test_execute_simple_start_end` |
| Full process (Start, Read, Delay, End) | Yes | `test_execute_full_process` |
| Device not found | Yes | `test_execute_device_not_found` |
| Listener callbacks (success) | Yes | `test_execute_with_listener` |
| Start idempotency | Yes | `test_start_is_idempotent` |
| Start sets Running status | Yes | `test_start_sets_running_status` |
| Read stores variable | Yes | `test_read_stores_variable` |
| Read invalid point_id | Yes | `test_read_invalid_point_id` |
| Control writes value | Yes | `test_control_writes_value` |
| Control invalid point_id | Yes | `test_control_invalid_point_id` |
| Delay waits for duration | Yes | `test_delay_waits_for_duration` |
| Delay zero duration | Yes | `test_delay_zero_returns_immediately` |
| End sets Completed status | Yes | `test_end_sets_completed_status` |
| **Fail-fast on step failure** | **No** | — |
| **Listener callbacks on failure** | **No** | — |
| **LockError path** | **No** | — |
| **ProcessDefinition parsing validation** | **No** | — |

---

## Final Verdict: NEEDS REVISION

The implementation is solid and demonstrates good engineering practices. However, the following must be addressed before approval:

### Required Changes
1. **M-1**: Address the `DriverAccessAdapter` coupling to `VirtualConfig`. At minimum, add a `TODO` comment and document this as known technical debt. Ideally, refactor to a more generic approach.
2. **M-2**: Update the design document and code comments to reflect the `read()` lock (the code is correct, the docs are wrong).
3. **M-3**: Add a fail-fast integration test verifying that step failure stops execution and fires the correct listener callbacks.

### Recommended Changes
- m-1: Remove unused imports in `step_engine.rs`
- m-3: Fix `use` statement ordering in test modules
- Add Control step to `test_execute_full_process`
- Add `MockDriverAccess` test utility per design spec

---

**Reviewed by**: sw-jerry  
**Review date**: 2026-04-02  
**Next step**: Address required changes and request re-review
