# S2-008 Test Cases: Experiment Process State Machine

**Task ID**: S2-008
**Task Name**: Experiment Process State Machine Implementation
**Test Version**: 1.0
**Date**: 2026-04-02

---

## Test Overview

This document defines test cases for the experiment process state machine, covering:
1. State transition validation
2. Operation authorization per state
3. State persistence
4. State change logging
5. Edge cases and error handling

---

## State Machine Reference (from PRD 2.3.1)

```
          +---------+
          |  IDLE   |
          +----+----+
               | load
               v
          +---------+
    +---->| LOADED  |<----+
    |     +----+----+     |
    |          | start    |
    |          v          |
 pause      +---------+   |
+---------->| RUNNING |---+---> error
|           +----+----+   |
|                | pause  |
|                v        |
|           +---------+   |
+-----------| PAUSED  |---+
            +---------+
```

### Control Operations (from PRD 2.3.2)

| Operation | Description | Required State | Target State |
|-----------|-------------|----------------|--------------|
| Load | Load experiment method | IDLE | LOADED |
| Start | Start experiment | LOADED/PAUSED | RUNNING |
| Pause | Pause experiment | RUNNING | PAUSED |
| Resume | Resume experiment | PAUSED | RUNNING |
| Stop | Stop experiment | RUNNING/PAUSED | LOADED |
| Reset | Reset state to Idle | Any non-terminal state | IDLE |

**Design Decisions** (clarified from PRD ambiguity):
1. **Reset target**: Reset goes to **IDLE** (not LOADED). This clears the loaded method and returns the experiment to its initial state. The PRD diagram labels the arrow as "stop/reset" but semantically Reset means "start over", which maps to IDLE.
2. **Reset from terminal states**: Reset is **NOT** allowed from Completed or Aborted states. Terminal states are final — a new experiment must be created.
3. **Running -> Completed**: This is an inferred transition (experiment finishes normally). The PRD diagram shows `Completed` as a state but doesn't draw the arrow explicitly.
4. **Running/Paused -> Aborted**: The PRD diagram shows `---> error` from RUNNING. This maps to the `Aborted` state (error-induced termination).

---

## Test Cases

### TC-001: State Enum Completeness

**Description**: Verify ExperimentStatus enum contains all required states.

**Test Steps**:
1. Check that ExperimentStatus enum includes: Idle, Loaded, Running, Paused, Completed, Aborted
2. Verify each state can be serialized/deserialized correctly

**Expected Results**:
- All 6 states exist in the enum
- Serialization produces uppercase strings: "IDLE", "LOADED", "RUNNING", "PAUSED", "COMPLETED", "ABORTED"
- Deserialization from these strings works correctly

---

### TC-002: Valid State Transitions

**Description**: Verify all valid state transitions are allowed.

**Test Steps**:
1. Test each valid transition from the state machine:
   - Idle -> Loaded (via load)
   - Loaded -> Running (via start)
   - Running -> Paused (via pause)
   - Paused -> Running (via resume)
   - Running -> Loaded (via stop)
   - Paused -> Loaded (via stop)
   - Any state -> Idle (via reset)
   - Running -> Completed (via normal end)
   - Running -> Aborted (via error)
   - Paused -> Aborted (via error)

**Expected Results**:
- All valid transitions return `Ok`
- State is correctly updated after transition

---

### TC-003: Invalid State Transitions

**Description**: Verify invalid state transitions are rejected with appropriate errors.

**Test Steps**:
1. Test invalid transitions:
   - Idle -> Running (must load first)
   - Idle -> Paused
   - Loaded -> Paused
   - Loaded -> Idle (use reset instead)
   - Paused -> Idle (use reset instead)
   - Completed -> any state (terminal state)
   - Aborted -> any state (terminal state)
   - Running -> Idle (use reset instead)
   - Loaded -> Loaded (no self-transition)
   - Running -> Running (no self-transition)
   - Paused -> Paused (no self-transition)
   - Idle -> Completed (must go through Running first)
   - Idle -> Aborted (must go through Running first)
   - Loaded -> Completed (must go through Running first)
   - Loaded -> Aborted (must go through Running first)

**Expected Results**:
- All invalid transitions return `Err(StateMachineError::InvalidTransition)`
- Error message describes the invalid transition

---

### TC-004: Operation Authorization Per State

**Description**: Verify each operation is only allowed in the correct states.

**Test Steps**:
1. For each operation, test authorization in each state:

| Operation | Idle | Loaded | Running | Paused | Completed | Aborted |
|-----------|------|--------|---------|--------|-----------|---------|
| Load | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Start | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |
| Pause | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Resume | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Stop | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| Reset | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Complete | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Abort | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |

**Expected Results**:
- Operation returns `Ok` only when allowed
- Operation returns `Err(OperationNotAllowed)` when not allowed

---

### TC-005: State Machine with Method Loading

**Description**: Verify state machine correctly tracks loaded method ID.

**Test Steps**:
1. Create experiment in Idle state
2. Load method with method_id = UUID_X
3. Verify state is Loaded and method_id is set
4. Start experiment
5. Verify state is Running and method_id is preserved
6. Stop experiment
7. Verify state is Loaded and method_id is preserved
8. Reset experiment
9. Verify state is Idle and method_id is cleared

**Expected Results**:
- Method ID is set during Load operation
- Method ID is preserved through Running/Loaded transitions
- Method ID is cleared on Reset

---

### TC-006: State Change Logging

**Description**: Verify state changes are logged with timestamps.

**Test Steps**:
1. Create experiment in Idle state
2. Perform sequence: Load -> Start -> Pause -> Resume -> Stop
3. Retrieve state change log
4. Verify log entries contain:
   - Previous state
   - New state
   - Operation that triggered change
   - Timestamp
   - User ID who triggered the change (per PRD 2.3.4: "操作类型、时间、用户")
   - Optional error message

**Expected Results**:
- Log contains 5 entries (one per transition)
- Each entry has correct previous/new state
- Timestamps are in chronological order
- Operation names are correct

---

### TC-007: Terminal State Enforcement

**Description**: Verify Completed and Aborted states are truly terminal.

**Test Steps**:
1. Create experiment, transition to Running
2. Complete the experiment
3. Try all operations: Load, Start, Pause, Resume, Stop, Reset
4. Create another experiment, transition to Running
5. Abort the experiment
6. Try all operations: Load, Start, Pause, Resume, Stop, Reset

**Expected Results**:
- All operations on Completed state return error
- All operations on Aborted state return error
- Even Reset is not allowed from terminal states (experiment must be recreated)

---

### TC-008: State Persistence

**Description**: Verify experiment state is persisted to database.

**Test Steps**:
1. Create experiment in database (Idle state)
2. Load method and verify state is persisted as Loaded
3. Start experiment and verify state is persisted as Running
4. Pause experiment and verify state is persisted as Paused
5. Stop experiment and verify state is persisted as Loaded
6. Query experiment from database and verify state matches

**Expected Results**:
- State is correctly stored in SQLite after each transition
- Querying from database returns the current state
- Timestamps (started_at, ended_at, updated_at) are correctly maintained

---

### TC-009: Timestamp Management

**Description**: Verify timestamps are correctly managed during state transitions.

**Test Steps**:
1. Create experiment - verify created_at and updated_at are set
2. Load method - verify updated_at changes
3. Start experiment - verify started_at is set, updated_at changes
4. Pause experiment - verify updated_at changes, started_at unchanged
5. Resume experiment - verify updated_at changes
6. Stop experiment - verify ended_at is NOT set (stop returns to Loaded)
7. Start again - verify started_at is updated
8. Complete experiment - verify ended_at is set

**Expected Results**:
- started_at is set on first Start, updated on subsequent Starts
- ended_at is only set on Completed or Aborted transitions
- updated_at changes on every state transition

---

### TC-010: State Machine Error Types

**Description**: Verify state machine produces appropriate error types.

**Test Steps**:
1. Test invalid transition -> expect `InvalidTransition` error
2. Test operation not allowed -> expect `OperationNotAllowed` error
3. Test operation on non-existent experiment -> expect `NotFound` error
4. Test loading method that doesn't exist -> expect `MethodNotFound` error

**Expected Results**:
- Each error scenario produces the correct error variant
- Error messages are descriptive

---

### TC-011: Concurrent State Transition Safety

**Description**: Verify state machine handles concurrent transition attempts safely.

**Test Steps**:
1. Create experiment in Loaded state
2. Simulate two concurrent Start operations
3. Verify only one succeeds
4. Verify the other returns an appropriate error

**Expected Results**:
- Only one transition succeeds
- The other operation fails with a conflict error
- Final state is consistent

---

### TC-012: State Machine Service Integration

**Description**: Verify state machine service integrates with Method and Experiment repositories.

**Test Steps**:
1. Create a method in the database
2. Create an experiment
3. Load the method into the experiment via the service
4. Start the experiment via the service
5. Get experiment status via the service
6. Stop the experiment via the service
7. Verify all operations interact correctly with repositories

**Expected Results**:
- Service correctly delegates to repositories
- Method existence is validated before loading
- Experiment existence is validated before operations
- All operations return correct responses

---

## Test Execution Plan

| Test Case | Priority | Type | Estimated Time |
|-----------|----------|------|----------------|
| TC-001 | P0 | Unit | 5 min |
| TC-002 | P0 | Unit | 10 min |
| TC-003 | P0 | Unit | 10 min |
| TC-004 | P0 | Unit | 15 min |
| TC-005 | P0 | Unit | 10 min |
| TC-006 | P1 | Unit | 10 min |
| TC-007 | P0 | Unit | 10 min |
| TC-008 | P0 | Integration | 15 min |
| TC-009 | P1 | Integration | 10 min |
| TC-010 | P0 | Unit | 10 min |
| TC-011 | P1 | Unit | 10 min |
| TC-012 | P0 | Integration | 15 min |

---

## Acceptance Criteria Mapping

| PRD Acceptance Criteria | Test Cases |
|------------------------|------------|
| State transitions match PRD 2.3.1 state diagram | TC-002, TC-003, TC-004 |
| Invalid state transitions are rejected | TC-003, TC-004, TC-007 |
| State change records are logged | TC-006 |
| State is persisted to database | TC-008, TC-009 |

---

**Author**: sw-mike
**Reviewer**: sw-tom
**Status**: ✅ APPROVED (v1.1 - issues fixed)
