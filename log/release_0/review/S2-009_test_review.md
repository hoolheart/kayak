# S2-009 Test Cases Review

**Task ID**: S2-009
**Task Name**: 基础环节执行引擎
**Reviewer**: sw-tom
**Date**: 2026-04-02
**Status**: Needs Revision

---

## Overall Assessment

**Verdict: Needs Revision**

The test cases are well-structured, comprehensive, and demonstrate good coverage of the acceptance criteria. The document is organized logically with clear sections for parsing, execution, context management, logging, error handling, and integration. However, several technical issues need to be addressed before the test cases can be approved.

---

## 1. Completeness Review

### Acceptance Criteria Coverage

| Acceptance Criterion | Coverage | Assessment |
|---------------------|----------|------------|
| 可执行包含 Start-Read-Delay-Control-End 的简单过程 | TC-025, TC-024, TC-030 | ✅ Well covered |
| Read 环节读取虚拟设备数据 | TC-014, TC-015, TC-016, TC-047 | ✅ Well covered |
| 每个环节执行记录日志 | TC-035, TC-036, TC-037, TC-039 | ✅ Well covered |

### Additional Coverage (Beyond AC)

The test cases go beyond the acceptance criteria to cover:
- JSON parsing validation (TC-001 ~ TC-011)
- Individual step executor tests (TC-012 ~ TC-023)
- Execution context management (TC-031 ~ TC-034)
- Error handling (TC-040 ~ TC-045)
- Integration with StateMachine, ExperimentControlService, Method model (TC-046 ~ TC-050)

This is good — the extra coverage is appropriate for a foundational component.

---

## 2. Correctness Review (Against Existing Codebase)

### 2.1 DriverError Alignment — Issues Found

**TC-S2-009-016, TC-S2-009-041**: The expected error type `DriverError::NotConnected` is correct — this matches `drivers/error.rs` line 9. ✅

**TC-S2-009-018, TC-S2-009-042**: The expected error type `DriverError::ReadOnlyPoint` is correct — this matches `drivers/error.rs` line 17. ✅

**TC-S2-009-019**: The test mentions adjusting VirtualDriver's `data_type` configuration for each write. However, looking at `virtual.rs` line 227-245, the `write_point` method performs type checking against `self.config.data_type`. This means you cannot simply "adjust" the config between writes on the same driver instance — you would need separate driver instances or a mutable config. The test steps should clarify this.

### 2.2 VirtualDriver Behavior — Issues Found

**TC-S2-009-047**: The expected result states:
> "after" 的值为 Control 写入的 80.0（因为 VirtualDriver 对已写入的 RW 点返回写入值）

This is **correct** based on `virtual.rs` lines 209-212: `read_point` first checks `point_values` HashMap for user-written values before falling back to `generate_value()`. ✅

However, there is a **subtle issue**: the test uses the **same** `point_id` for both Read steps and the Control step. In `virtual.rs`, `read_point` returns the stored value for a given `point_id`. So the "before" read would return the generated value (Fixed mode), and the "after" read would return the Control-written value — but only if they share the same `point_id`. The test steps should explicitly state whether the same or different `point_id` is used for each step, as this affects the expected outcome.

### 2.3 StateMachine Integration — Issues Found

**TC-S2-009-046**: The test describes a full lifecycle through `ExperimentControlService`. However, `ExperimentControlService` (in `services/experiment_control/mod.rs`) does **not** have any method that directly invokes the step execution engine. The service only handles state transitions (load, start, pause, resume, stop, reset, complete, abort). The step execution engine is a separate component that would be triggered externally. The test steps 7-8 describe "启动执行引擎执行过程定义" and "引擎执行 End 步骤后，触发 StateMachine::Complete 操作" — but there is no existing code that connects these two. This test case assumes integration glue code that doesn't exist yet.

**Recommendation**: Either (a) mark this as a future integration test pending the glue code, or (b) clarify that this test requires creating the integration layer as part of S2-009.

**TC-S2-009-048, TC-S2-009-049**: Similar issue — these tests describe the engine triggering StateMachine transitions, but the engine doesn't currently have this capability. The StateMachine is a pure function (no side effects), and the ExperimentControlService is the one that orchestrates state changes. The engine would need a callback or event mechanism to trigger these transitions.

### 2.4 Method Model — Issues Found

**TC-S2-009-050**: The test references `Method.process_definition` which is `serde_json::Value` (from `method.rs` line 19). This is correct. ✅

---

## 3. Testability Review

### 3.1 Time-Sensitive Tests

**TC-S2-009-020**: Testing Delay with 10ms and expecting `< 50ms` is reasonable for unit tests. ✅

**TC-S2-009-030**: Testing total execution time `>= 30ms` with three 10ms delays is reasonable. ✅

**TC-S2-009-038**: Testing timestamp ordering is fine, but the assertion "每条日志的 start_time >= 前一条日志的 end_time" may be flaky on heavily loaded systems. Consider adding a small tolerance.

### 3.2 Database-Dependent Tests

**TC-S2-009-046, TC-S2-009-050**: These require a database (SQLite in-memory). The test environment requirements mention this, which is good. However, these tests will need mock repositories or a test database setup. The test steps should specify whether to use real repositories or mocks.

### 3.3 Async Tests

The `DeviceDriver` trait uses `async_trait`, and `ExperimentControlService` methods are all `async`. The test cases don't explicitly mention that tests need to be `#[tokio::test]` async tests. This should be noted in the test execution plan.

---

## 4. Missing Scenarios

### 4.1 Duplicate Step IDs

The test cases don't cover the scenario where two steps have the same `id`. This is a potential edge case that could cause issues in logging or execution tracking. Consider adding a test case for duplicate step ID detection during parsing.

### 4.2 Very Large Process Definitions

No test covers a process definition with a very large number of steps (e.g., 1000+ steps). While not critical for Release 0, a basic sanity test with ~50 steps could verify the engine handles longer sequences without stack overflow or memory issues.

### 4.3 Concurrent Execution

The test cases assume single-threaded, sequential execution. There's no test for what happens if the engine is asked to execute two processes simultaneously (should they share context? should they be isolated?). This may be out of scope for S2-009 but worth noting.

### 4.4 WO (Write-Only) Point Access

The test cases cover RO and RW access types but don't test WO (Write-Only) points. A Control step writing to a WO point should succeed, but a Read step on a WO point should fail. The VirtualDriver doesn't currently enforce WO semantics in `read_point` (it doesn't check `access_type == WO` before reading), so this may be a gap in both the driver and the tests.

### 4.5 Process Definition Version Field

The JSON format includes a `"version": "1.0"` field, but no test validates version handling (e.g., unknown version, missing version). Consider whether version validation is needed.

---

## 5. Redundancy Review

### 5.1 TC-S2-009-040 vs TC-S2-009-008

**TC-040** ("无效环节定义返回错误") and **TC-008** ("处理无效环节类型") both test the same scenario: an unknown step type `"InvalidType"` / `"Unknown"`. These are effectively duplicates.

**Recommendation**: Remove TC-040 or repurpose it to test a different kind of invalid definition (e.g., missing `type` field entirely, or `steps` field missing from the root object).

### 5.2 TC-S2-009-041 vs TC-S2-009-016

**TC-041** ("Read 环节设备读取失败") and **TC-016** ("Read 环节 — 未连接设备时读取") both test reading from an unconnected device. TC-041 adds the context of a full process execution (Start -> Read -> End) and verifies that subsequent steps don't execute, while TC-016 tests the isolated Read step. These are related but not fully redundant — TC-041 tests error propagation in the execution flow, while TC-016 tests the individual executor.

**Recommendation**: Keep both but clarify the distinction in their descriptions. TC-016 should focus on the executor returning the error, while TC-041 should focus on the engine stopping execution and not running subsequent steps.

### 5.3 TC-S2-009-042 vs TC-S2-009-018

Similar to above — TC-042 tests error propagation in the execution flow, while TC-018 tests the isolated executor. Keep both with clarified scope.

### 5.4 TC-S2-009-045 vs TC-S2-009-041

**TC-045** ("过程中间步骤失败后的状态") and **TC-041** ("Read 环节设备读取失败") have significant overlap. Both test Start -> Read -> ... with an unconnected device, and both verify that subsequent steps don't execute. TC-045 adds verification of the execution context state.

**Recommendation**: Merge TC-041 and TC-045 into a single test, or differentiate them more clearly (e.g., TC-041 focuses on error return value, TC-045 focuses on context state and log records).

---

## 6. Specific Issues by Test Case ID

| Test Case | Issue | Severity | Suggestion |
|-----------|-------|----------|------------|
| TC-S2-009-013 | Expected result is ambiguous ("应成功或返回警告，取决于设计") | Medium | Define the expected behavior explicitly. For a step execution engine, duplicate Start should likely be a no-op or warning, not an error. |
| TC-S2-009-019 | "需调整 VirtualDriver 的 data_type 配置" is not practical — config is immutable after construction | Medium | Use separate VirtualDriver instances for each data type, or test only the types supported by a single driver config. |
| TC-S2-009-022 | Negative `duration_ms` — in JSON, this would be a number, but the Rust type should be `u64` which cannot represent negative values. The parsing would fail at the serde level, not at a validation level. | Low | Clarify that this is tested at the JSON parsing level (serde rejects negative values for unsigned types). |
| TC-S2-009-028 | "仅包含 Start 步骤的过程" — the acceptance criteria mention Start-Read-Delay-Control-End, but a single-Start process is an edge case. The expected result says "执行成功" but doesn't specify what the final state should be. | Low | Clarify expected final state (e.g., "completed" since all steps executed). |
| TC-S2-009-043 | "缺少 point_id 字段（如果解析阶段未捕获）" — this is a conditional test that may never execute if parsing catches it first. | Low | Either remove or reframe as a defensive programming test (what if someone constructs a step struct directly without going through JSON parsing?). |
| TC-S2-009-044 | Timeout mechanism — this assumes the engine has a configurable timeout feature. This is not mentioned in the task description or acceptance criteria. | Medium | Either add timeout as a requirement for S2-009, or move this test to a future task. |
| TC-S2-009-046 | Integration glue code doesn't exist yet (see section 2.3) | High | Clarify whether this test requires new integration code to be built as part of S2-009, or defer to a later task. |
| TC-S2-009-048 | Same as TC-046 — engine doesn't currently trigger StateMachine transitions | High | Same recommendation as TC-046. |
| TC-S2-009-049 | Same as TC-046 — engine doesn't currently trigger StateMachine transitions | High | Same recommendation as TC-046. |

---

## 7. Suggestions for Improvement

### 7.1 Clarify Test Types

Some tests labeled as "单元测试" (unit tests) in the execution plan actually require database setup or multiple component integration. Consider reclassifying:
- TC-046, TC-047, TC-048, TC-049, TC-050 are correctly labeled as "集成测试" ✅
- TC-014, TC-015, TC-016, TC-017, TC-018, TC-019 involve VirtualDriver and could be classified as "集成测试" rather than "单元测试" since they test the engine's integration with the driver, not the engine in isolation.

### 7.2 Add Mock Strategy

For tests involving VirtualDriver, consider specifying whether to use:
- Real VirtualDriver instances (simpler, but tests driver behavior too)
- Mock implementations of `DeviceDriver` trait (more isolated, but requires mock setup)

A hybrid approach is fine: use real VirtualDriver for integration tests and mocks for pure engine unit tests.

### 7.3 Define Execution Context Structure

The test cases reference an "执行上下文" (execution context) but don't define its structure. Before implementation, the context should be defined with at minimum:
- `variables: HashMap<String, PointValue>` — for Read step outputs
- `start_time: DateTime<Utc>` — set by Start step
- `status: ExecutionStatus` — enum with Running/Completed/Failed
- `logs: Vec<StepLogEntry>` — for logging

### 7.4 P0/P1 Ratio

34 out of 50 test cases are P0 (68%). This is unusually high. Consider re-evaluating priorities:
- TC-003 (empty steps), TC-009 (type error), TC-010 (invalid JSON) could be P1
- TC-021 (zero delay), TC-013 (duplicate Start) are correctly P2
- TC-028 (single Start), TC-029 (empty process) could be P1

---

## 8. Final Verdict

**Status: Needs Revision**

The test cases are well-designed and comprehensive, but the following must be addressed before approval:

### Must Fix (Blockers)
1. **TC-046, TC-048, TC-049**: Clarify the integration between the step execution engine and StateMachine/ExperimentControlService. Either define the integration mechanism (callback, event, or direct call) as part of S2-009 scope, or defer these tests to a later task.
2. **TC-040**: Remove or repurpose — duplicates TC-008.
3. **TC-019**: Fix the test approach for testing multiple data types — use separate driver instances.

### Should Fix (Recommended)
4. **TC-013**: Define explicit expected behavior for duplicate Start.
5. **TC-044**: Clarify whether timeout is in scope for S2-009.
6. **TC-041/TC-045**: Merge or clearly differentiate.
7. Rebalance P0/P1 priorities.

### Nice to Have
8. Add test for duplicate step IDs.
9. Add test for WO point access behavior.
10. Define execution context structure in the test document.

---

**Reviewed by**: sw-tom
**Date**: 2026-04-02
**Next Action**: sw-mike to revise test cases based on feedback, then resubmit for review.
