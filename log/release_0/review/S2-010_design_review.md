# S2-010 Design Review: 表达式引擎基础

**Task ID**: S2-010
**Review Version**: 1.0
**Date**: 2026-04-02
**Reviewer**: sw-jerry (Software Architect)

---

## 1. Overall Assessment

**Design Summary**: The S2-010 Expression Engine design provides a well-structured implementation plan for a critical component of the Kayak experiment control system. The design follows solid software engineering principles with proper interface abstraction and a clear type coercion policy.

**Verdict**: **NEEDS REVISION**

**Critical Issues Found**: 3
**Suggestions for Improvement**: 5

---

## 2. Architecture Consistency

### 2.1 Compatibility with Layered Architecture

**Status**: ⚠️ Minor Issue

The design places the Expression Engine under `kayak-backend/src/engine/expression/` with the following structure:
```
kayak-backend/src/engine/expression/
├── mod.rs
├── engine.rs
├── result.rs
└── tests/
```

However, reviewing `arch.md` Section 9.2 (Backend Directory Structure), the current structure uses:
- `services/` - for business logic services
- `models/` - for data models
- `drivers/` - for device drivers
- `db/` - for database access
- `core/` - for core utilities

The `engine/` directory is **not defined** in the approved architecture. While the design correctly identifies the Expression Engine as a foundational component for S2-009 (Step Engine), the directory placement needs to be reconciled with the existing architecture.

**Recommendation**: Either:
1. Add `engine/` as a new top-level directory in the architecture, or
2. Place the expression module under `core/` since it's a utility component

### 2.2 Interface-Driven Design Compliance

**Status**: ✅ Pass

The design properly implements Interface-Driven Development:
- `ExpressionEngine` trait is defined before implementation
- `EvalexprEngine` implements the trait
- All dependencies follow DIP (depends on `PointValue` abstraction, not concrete types)

---

## 3. Interface Design Review

### 3.1 ExpressionEngine Trait

**Status**: ✅ Well-Designed

```rust
pub trait ExpressionEngine: Send + Sync {
    fn eval(
        &self,
        expression: &str,
        context: &HashMap<String, PointValue>,
    ) -> Result<EvalResult, ExpressionError>;
}
```

**Strengths**:
- `Send + Sync` bounds ensure thread safety for concurrent use
- Pure function interface (no side effects)
- Uses `HashMap<String, PointValue>` compatible with `ExecutionContext.variables`
- Well-documented with doc comments and examples

### 3.2 EvalResult Enum

**Status**: ✅ Well-Designed

```rust
pub enum EvalResult {
    Number(f64),
    Boolean(bool),
    String(String),
}
```

Proper derivation of `Debug`, `Clone`, `PartialEq` supports testing.

### 3.3 ExpressionError Enum

**Status**: ⚠️ Minor Issue - Naming Inconsistency

The design defines:
```rust
pub enum ExpressionError {
    UnknownVariable(String),  // Line 112
    // ...
}
```

However, the test cases document (`S2-010_test_cases.md` lines 97-107) expect:
```rust
pub enum ExpressionError {
    UndefinedVariable(String),  // Line 98
    // ...
}
```

**Impact**: Test case TC-S2-010-042 expects `ExpressionError::UndefinedVariable("undefined_var")` but the design provides `ExpressionError::UnknownVariable`. This mismatch will cause test failures.

**Recommendation**: Align on `UndefinedVariable` as the error variant name to match the test cases.

---

## 4. Technical Feasibility

### 4.1 evalexpr Dependency

**Status**: ❌ Critical Issue

The design specifies using `evalexpr` crate version 10.x (Section 1.4, Section 5.3):
```toml
[dependencies]
# Expression evaluation
evalexpr = "10"
```

However, reviewing `kayak-backend/Cargo.toml`, **there is NO `evalexpr` dependency declared**.

This is a critical oversight that will prevent implementation from compiling.

**Recommendation**: Add to `Cargo.toml` before implementation:
```toml
evalexpr = "10"
```

### 4.2 Type Mapping Analysis

The design correctly maps `PointValue` to `evalexpr::Value`:

| PointValue | evalexpr::Value |
|------------|-----------------|
| Number(f64) | Float(f64) |
| Integer(i64) | Float(f64 as f64) |
| Boolean(bool) | Boolean(bool) |
| String(String) | String(String) |

This mapping is feasible and correct.

### 4.3 Error Mapping

The design provides comprehensive error mapping from `evalexpr` errors to `ExpressionError`. The `map_evalexpr_error` function (Section 6.2) covers the main error cases.

---

## 5. Type Coercion Policy

**Status**: ✅ Clearly Defined and Implementable

Section 3 provides a clear type coercion policy:

| Conversion | Rule | Example | Result |
|------------|------|---------|--------|
| Integer → Number | Always promote | `Integer(42)` in arithmetic | `Number(42.0)` |
| Boolean → Number | Allowed (IEEE 754) | `true + 1` | `Number(2.0)` |
| Number → Boolean | **Forbidden** (requires explicit comparison) | `!5.0` | `TypeError` |
| Integer/Number → Boolean | Via comparison only | `x > 0` | `Boolean` |

**Design Rationale** (Section 3.2) is sound:
1. Integer → Number simplification is pragmatic
2. Boolean → Number follows IEEE 754 tradition (C, Go, JavaScript)
3. Number → Boolean prohibition avoids truthy/falsy ambiguity

The policy is **testable** and aligns with the test cases (TC-045, TC-047).

---

## 6. Testability Analysis

### 6.1 Test Coverage

**Status**: ✅ Excellent

The design references 76 test cases covering:
- Arithmetic operations (TC-001 ~ TC-016)
- Comparison operations (TC-017 ~ TC-023)
- Logical operations (TC-024 ~ TC-031)
- Variable substitution (TC-032 ~ TC-043)
- Type coercion (TC-044 ~ TC-053)
- Error handling (TC-054 ~ TC-062)
- Floating-point edge cases (TC-063 ~ TC-067)
- Variable name validation (TC-068 ~ TC-069)
- Integration tests (TC-070 ~ TC-076)

### 6.2 Test Helper Functions

**Status**: ✅ Well-Designed

The design includes helpful test utilities (lines 590-616):
```rust
fn ctx(vars: &[(&str, PointValue)]) -> HashMap<String, PointValue>
fn assert_eval(expr: &str, context: &HashMap, expected: EvalResult)
fn assert_eval_error(expr: &str, context: &HashMap, expected_error: ExpressionError)
```

### 6.3 Issue in Test Code

**Status**: ⚠️ Bug Found

In `test_number_to_boolean_requires_comparison` (lines 701-706), the test code has an error:
```rust
fn test_number_to_boolean_requires_comparison() {
    // ...
    let result = engine.eval("!x", &context);  // BUG: 'engine' not defined
    assert!(result.is_err());
}
```

The function uses `engine` but should use `self` or the helper function `assert_eval_error`.

---

## 7. Completeness Review

### 7.1 Acceptance Criteria Coverage

| Acceptance Criteria | Coverage |
|---------------------|----------|
| 1. Support arithmetic expressions | ✅ TC-001~016, TC-030, TC-032~033, TC-036, TC-038~039, TC-044, TC-046, TC-052~053, TC-067, TC-076 |
| 2. Support conditional expressions | ✅ TC-017~031, TC-035~036, TC-042~043, TC-047~048 |
| 3. Variable substitution correct | ✅ TC-032~043, TC-044~053, TC-058, TC-070~075 |

### 7.2 Module Structure

The file layout (Section 5.1) is logical:
- `result.rs` - Contains `EvalResult` and `ExpressionError`
- `engine.rs` - Contains `ExpressionEngine` trait and `EvalexprEngine` implementation
- Test files organized by category

---

## 8. Specific Issues

### Issue 1: Missing Dependency in Cargo.toml (CRITICAL)
**Severity**: Critical
**Location**: Section 5.3 vs `kayak-backend/Cargo.toml`

The design specifies `evalexpr = "10"` as a dependency, but it is not present in the actual `Cargo.toml`.

**Fix Required**: Add the dependency before implementation begins.

### Issue 2: Error Variant Naming Mismatch (MAJOR)
**Severity**: Major
**Location**: Section 2.2 vs Test Cases

Design: `ExpressionError::UnknownVariable(String)`
Tests: `ExpressionError::UndefinedVariable(String)`

**Fix Required**: Choose one naming convention and ensure consistency across design and tests.

### Issue 3: Directory Structure Not in Architecture (MINOR)
**Severity**: Minor
**Location**: Section 5.1 vs arch.md

The `engine/` directory is not defined in the approved architecture.

**Fix Required**: Either update arch.md or relocate the module.

### Issue 4: Test Code Bug (MINOR)
**Severity**: Minor
**Location**: Line 704

`engine.eval` should be `self.engine.eval` or use the helper function.

---

## 9. Suggestions for Improvement

### Suggestion 1: Add Integration Test Guidance
The design could benefit from explicit examples of how the Expression Engine integrates with S2-009 (Step Engine) and S2-011 (Experiment Control Service).

### Suggestion 2: Document strict_mode Behavior
`EngineConfig::strict_mode` is mentioned but its effect on behavior is not detailed. Clarify what "strict mode" enforcement looks like.

### Suggestion 3: Add Performance Considerations
For future optimization (Section 12.1 mentions "Expression Caching"), consider documenting the expected evaluation frequency to guide caching decisions.

### Suggestion 4: Clarify String Comparison Semantics
Section 2.1 mentions "String results in Release 0 only for string equality comparison". The design should clarify that `==` for strings is supported but other string operations may not be.

### Suggestion 5: Consider Adding From Trait Implementations
For cleaner conversion code, consider implementing `From<PointValue> for evalexpr::Value` and `From<evalexpr::Value> for EvalResult`.

---

## 10. Final Verdict

**VERDICT: NEEDS REVISION**

### Required Changes Before Approval:

1. **Add `evalexpr = "10"` to `Cargo.toml`**
2. **Resolve `UnknownVariable` vs `UndefinedVariable` naming conflict**
3. **Clarify `engine/` directory placement relative to arch.md**
4. **Fix test code bug on line 704**

### Approval Preconditions:
- [ ] Cargo.toml updated with evalexpr dependency
- [ ] Error enum naming aligned with test cases
- [ ] Architecture clarification provided
- [ ] Test code bug fixed

---

## 11. Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| evalexpr behavior differs from expectations | Medium | Low | Comprehensive test coverage (76 cases) |
| Type coercion edge cases | Medium | Low | Clear policy documentation |
| Float precision issues | Low | Medium | Epsilon-based comparisons in tests |
| Missing dependency causes build failure | High | High | Add to Cargo.toml |

---

**Reviewer Sign-off**: sw-jerry (Software Architect)
**Date**: 2026-04-02
