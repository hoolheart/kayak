# S2-010 Design Re-Review: 表达式引擎基础

**Task ID**: S2-010
**Review Version**: 2.0
**Date**: 2026-04-02
**Reviewer**: sw-jerry (Software Architect)

---

## 1. Previous Review Summary

My previous review (v1.0) identified 4 issues requiring revision:

| # | Issue | Severity | Required Fix |
|---|-------|----------|--------------|
| 1 | Test code bug (line 704): `engine.eval` with undefined variable | Minor | Change to `EvalexprEngine::new().eval` |
| 2 | Naming mismatch: `UnknownVariable` vs `UndefinedVariable` | Major | Align naming across design and tests |
| 3 | Directory structure: `engine/` not in arch.md | Minor | Add note that arch.md needs updating |
| 4 | Dependency: evalexpr not declared in Cargo.toml | Critical | Document that it's a NEW dependency |

---

## 2. Verification of Fixes

### Issue 1: Test Code Bug (Line 704) — ✅ RESOLVED

**Original**: `engine.eval("!x", &context)` — `engine` was undefined

**Revised** (line 711):
```rust
let result = EvalexprEngine::new().eval("!x", &context);
```

**Verification**: Correctly uses `EvalexprEngine::new()` to create instance inline.

---

### Issue 2: Naming Mismatch — ✅ RESOLVED

**Original**: `UnknownVariable` used inconsistently in ExpressionError enum

**Revised**: All occurrences changed to `UndefinedVariable`:
- Line 115: `UndefinedVariable(String)` in enum definition
- Line 139: `ExpressionError::UndefinedVariable(name)` in Display impl
- Line 363: `ExpressionError::UndefinedVariable(var_name.to_string())` in error mapping
- Line 689: `ExpressionError::UndefinedVariable("undefined_var".to_string())` in test

**Verification**: Naming is now consistent across all sections.

---

### Issue 3: Directory Structure Note — ✅ RESOLVED

**Revised** (lines 435-436):
```markdown
**注意**：当前 `arch.md` 中尚未包含 `engine/` 目录结构。实现时需更新 `arch.md` 添加 `engine/` 目录。
```

**Verification**: Clear note added that arch.md requires update before implementation.

---

### Issue 4: Dependency Documentation — ✅ RESOLVED

**Revised** (lines 471-477):
```markdown
**新增依赖** - 以下内容需添加到 `kayak-backend/Cargo.toml` 的 `[dependencies]` 部分：
```

```toml
[dependencies]
# Expression evaluation
evalexpr = "10"
```

**Verification**: Clearly marked as NEW dependency that must be added to Cargo.toml.

---

## 3. Minor Observations

### New Bug Found (Not in Original Review Scope)

In the test code (lines 747, 753), two tests reference `engine.eval` without initializing `engine`:

```rust
#[test]
fn test_overflow() {
    let result = engine.eval("1e308 * 10", &ctx(&[])).unwrap();  // engine undefined
    ...
}

#[test]
fn test_nan() {
    let result = engine.eval("0.0 / 0.0", &ctx(&[])).unwrap();  // engine undefined
    ...
}
```

These should use `EvalexprEngine::new().eval(...)` like the fix at line 711.

**Note**: This bug was not in the original review scope. The revision note v1.1 stated only line 704 was fixed. However, these additional bugs should be addressed before implementation.

---

## 4. Final Verdict

### Resolution Status

| Issue | Status |
|-------|--------|
| Issue 1: Test code bug (line 704) | ✅ Resolved |
| Issue 2: Naming mismatch | ✅ Resolved |
| Issue 3: Directory structure note | ✅ Resolved |
| Issue 4: Dependency documentation | ✅ Resolved |

**All issues from the previous review are resolved.**

### Additional Recommendation

Before implementation, fix the undefined `engine` variable in `test_overflow` (line 747) and `test_nan` (line 753) to use `EvalexprEngine::new().eval(...)`.

---

## 5. Final Decision

**VERDICT: APPROVED**

The revised design S2-010 addresses all four issues from the previous review. The design is ready for implementation.

**Required before implementation**:
1. Add `evalexpr = "10"` to `kayak-backend/Cargo.toml`
2. Update `arch.md` to include `engine/` directory structure
3. Fix undefined `engine` variable in `test_overflow` and `test_nan` test functions

---

**Reviewer Sign-off**: sw-jerry (Software Architect)
**Date**: 2026-04-02
