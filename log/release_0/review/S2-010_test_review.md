# S2-010 Test Cases Review: 表达式引擎基础

**Task ID**: S2-010
**Task Name**: 表达式引擎基础
**Test Document**: `log/release_0/test/S2-010_test_cases.md`
**Reviewer**: sw-tom
**Review Date**: 2026-04-02
**Status**: Needs Revision

---

## Overall Assessment

The test cases are **well-structured and comprehensive**, with 65 test cases covering all three acceptance criteria. The operator coverage matrix and error type coverage matrix are excellent additions. However, there are several issues that need to be addressed before the test cases can be approved.

**Verdict**: **Needs Revision** — see specific issues below.

---

## 1. Completeness Review

### Coverage of Acceptance Criteria

| Acceptance Criterion | Coverage | Assessment |
|---------------------|----------|------------|
| 支持算术运算表达式 | TC-001 ~ TC-013 | ✅ Good |
| 支持条件表达式 | TC-014 ~ TC-028 | ✅ Good |
| 变量替换正确执行 | TC-029 ~ TC-039 | ✅ Good |

### Missing Scenarios

| Issue | Description | Suggested Addition |
|-------|-------------|-------------------|
| **M-01: Modulo operator not tested** | The operator table lists `%` (取模), but no test case actually exercises it. TC-001~TC-013 cover `+`, `-`, `*`, `/` but skip `%`. | Add TC for `"10 % 3"` → `EvalResult::Number(1.0)` and `"10 % 0"` → `DivisionByZero` |
| **M-02: f64 overflow/underflow** | No test for expressions that produce `inf` or `NaN` (e.g., `"1e308 * 10"` or `"0.0 / 0.0"`). These are critical for scientific computing. | Add TC for overflow behavior and NaN handling |
| **M-03: Very long expressions** | No test for expression length limits or deeply nested parentheses (e.g., 100+ levels). Could cause stack overflow with recursive parsers. | Add TC for max expression depth or length |
| **M-04: Variable names with special characters** | No test for whether variable names like `temp_1`, `temp.value`, `1var` are valid or rejected. The parser behavior is undefined. | Add TC for valid/invalid variable name patterns |
| **M-05: String concatenation** | The `+` operator with two strings is not tested. Should `"hello" + "world"` work (concatenation) or return `TypeError`? | Add TC for string + string behavior |
| **M-06: Negative number in variable context** | TC-009 tests literal `-5 + 3`, but no test for a variable holding a negative value: `{"x": PointValue::Number(-5.0)}` with expression `"x * 2"`. | Add TC for negative variable values |

---

## 2. Correctness Review

### Issues with Expected Types

| Test Case | Issue | Detail |
|-----------|-------|--------|
| **TC-029** | Expected result type ambiguity | The expected result says `EvalResult::Integer(42)` **or** `EvalResult::Number(42.0)`. Since `PointValue::Integer(42)` is passed in, the test should specify which `EvalResult` variant is expected. If using `evalexpr`, it will likely return `Float(42.0)`. **Recommendation**: Decide on a consistent type coercion policy and update the expected result. |
| **TC-041** | Ambiguous acceptance criteria | The test says "如果引擎支持...如果不支持..." — this is not a testable assertion. The behavior must be decided **before** implementation. Given that `PointValue::Boolean` has `to_f64()` returning `1.0`/`0.0` in the existing codebase, the engine should support Boolean→Number conversion. **Recommendation**: Change to a definitive expected result. |
| **TC-055** | Same ambiguity as TC-041 | Same issue — "如果引擎支持...如果不支持..." is not testable. **Recommendation**: Decide on behavior. Given `PointValue::to_f64()` exists, `!x` where `x=5.0` should either return `Boolean(false)` (truthy) or `TypeError`. Pick one. |

### Interface Definition Concerns

The test document defines an expected `ExpressionEngine` interface with:

```rust
pub fn eval(&self, expression: &str, context: &HashMap<String, PointValue>) -> Result<EvalResult, ExpressionError>;
```

**Concerns**:
1. The `evalexpr` crate (likely candidate) uses its own `Value` type, not `PointValue`. A conversion layer will be needed. The test cases should acknowledge this mapping.
2. `EvalResult` has both `Number(f64)` and `Integer(i64)` — this mirrors `PointValue` but `evalexpr` uses a single `Float` type. The test cases should clarify whether the engine preserves `Integer` type information or always promotes to `Number(f64)`.
3. `ExpressionError::EmptyExpression` is a separate variant from `SyntaxError`. Consider whether an empty string is truly a distinct error category or just a syntax error. This affects how many error variants the implementation needs.

---

## 3. Testability Review

### Positive Aspects
- All unit test cases (TC-001 ~ TC-055) are straightforward to implement as Rust `#[test]` functions
- The use of `HashMap<String, PointValue>` as context aligns with `ExecutionContext.variables`
- Expected results are concrete and assertable

### Concerns

| Test Case | Issue | Recommendation |
|-----------|-------|----------------|
| **TC-056, TC-057, TC-059, TC-060** | These integration tests reference `ExecutionContext` and `set_variable`, which exist in the codebase. However, they assume the expression engine can directly consume `ExecutionContext.variables`. The actual integration point needs to be defined. | Clarify whether the engine takes `&HashMap<String, PointValue>` or `&ExecutionContext` as input |
| **TC-061** | Performance benchmark with `< 100ms for 10000 iterations` — this is reasonable but depends heavily on whether expressions are parsed once or re-parsed each time. If using `evalexpr`'s `eval()` function (which parses each time), this may be tight. | Consider adding a "pre-compiled expression" variant if the engine supports it, or adjust the threshold |
| **TC-065** | Depends on S2-011 (分支/条件步骤) which is a **future task** not yet implemented. This test cannot be executed until S2-011 is done. | Mark as "deferred" or move to S2-011's test cases |
| **All tests** | No mention of `evalexpr` crate version or alternative. The `Cargo.toml` does not yet include this dependency. | Add a note about the required dependency version |

---

## 4. Redundancy Review

The following test cases have significant overlap and could be consolidated:

| Group | Test Cases | Issue | Suggestion |
|-------|-----------|-------|------------|
| **Comparison operators** | TC-014, TC-015, TC-016, TC-017, TC-018, TC-019 | Each comparison operator gets its own test case with nearly identical structure. These could be parameterized into a single test with a matrix of `(operator, left, right, expected)` tuples. | Consolidate into 1-2 parameterized tests using `#[rstest]` or similar |
| **Boolean logic truth table** | TC-021, TC-022, TC-023, TC-024 | These cover the complete truth table for `&&` and `\|\|`. Could be a single parameterized test. | Consolidate into 1 parameterized test |
| **Integration tests** | TC-056, TC-057, TC-059, TC-060 | All follow the same pattern: create context → set variables → evaluate expression → assert boolean result. TC-057 and TC-059 are nearly identical in structure. | TC-057 and TC-059 could be merged; TC-056 and TC-060 are distinct enough to keep |
| **Performance + consistency** | TC-061, TC-062 | TC-061 already checks "所有求值结果一致正确" which overlaps with TC-062's purpose. | Consider merging TC-062 into TC-061 |

**Note**: Consolidation is optional — having separate test cases improves readability and makes it easier to identify which specific operator fails. However, for a codebase that will use `#[test]` functions, parameterized tests would reduce boilerplate significantly.

---

## 5. Specific Issues by Test Case

| ID | Severity | Issue |
|----|----------|-------|
| TC-029 | Medium | Expected result type ambiguous (`Integer` vs `Number`). Decide on type coercion policy. |
| TC-041 | Medium | Acceptance criteria is conditional ("如果..."). Must be definitive before implementation. |
| TC-055 | Medium | Same as TC-041 — conditional acceptance criteria. |
| TC-065 | High | Depends on S2-011 which is not yet implemented. Cannot be executed in this sprint. |
| TC-061 | Low | Performance threshold may need adjustment based on implementation approach (parsed vs pre-compiled). |
| TC-042 | Low | String equality comparison is P1 but should arguably be P0 if string variables are supported in the domain model. |
| TC-053 | Low | Testing that `sin(45)` fails is good, but consider also testing other common functions like `max()`, `min()`, `abs()` to ensure they're also rejected. |

---

## 6. Suggestions for Improvement

### 6.1 Add Modulo Operator Tests
The operator table lists `%` but no test exercises it. Add:
- `"10 % 3"` → `EvalResult::Number(1.0)`
- `"10 % 0"` → `ExpressionError::DivisionByZero`
- `"-7 % 3"` → verify behavior with negative operands

### 6.2 Clarify Type Coercion Policy
Before implementation, decide and document:
1. Does `Integer + Number` → `Number`? (Currently implied by TC-040)
2. Does `Boolean` participate in arithmetic? (TC-041 is ambiguous)
3. Does `Number` participate in logical operations? (TC-055 is ambiguous)
4. What is the result type of `Integer == Integer`? `Boolean` or `Integer`?

### 6.3 Add Edge Cases for Scientific Computing
Given this is a scientific research platform:
- Very large numbers: `"1e308 * 10"` → should return `inf` or error?
- Very small numbers: `"1e-308 / 10"` → should return `0.0` or subnormal?
- `NaN` propagation: if any operand is `NaN`, should the result be `NaN` or error?

### 6.4 Defer TC-065
Move TC-065 to S2-011's test cases since it depends on branch/conditional steps that don't exist yet.

### 6.5 Consider Parameterized Tests
For the comparison and logic operator tests, consider using `#[rstest]` or `#[case]` attributes to reduce boilerplate:

```rust
#[rstest]
#[case("10 > 5", EvalResult::Boolean(true))]
#[case("5 > 10", EvalResult::Boolean(false))]
#[case("10 >= 10", EvalResult::Boolean(true))]
fn test_comparison_operators(#[case] expr: &str, #[case] expected: EvalResult) {
    // ...
}
```

---

## 7. Final Verdict

**Status**: ❌ **Needs Revision**

The test cases are well-organized and cover the acceptance criteria thoroughly. The operator coverage matrix and error type coverage matrix are excellent. However, the following must be addressed before approval:

### Must Fix (Blockers)
1. **TC-041 and TC-055**: Remove conditional acceptance criteria. Decide on type coercion behavior and update expected results.
2. **TC-065**: Defer to S2-011 or remove — it depends on unimplemented functionality.
3. **Missing modulo tests**: Add test cases for the `%` operator listed in the operator table.

### Should Fix (Recommended)
4. **TC-029**: Clarify expected result type (`Integer` vs `Number`).
5. **Add f64 overflow/NaN tests**: Critical for scientific computing domain.
6. **Add negative variable value test**: TC-009 tests literal negatives but not variable-held negatives.

### Nice to Have (Optional)
7. Consolidate redundant comparison/logic tests using parameterized test patterns.
8. Add tests for variable name validation (special characters, reserved words).
9. Add tests for string concatenation behavior.

---

**Reviewer**: sw-tom
**Date**: 2026-04-02
