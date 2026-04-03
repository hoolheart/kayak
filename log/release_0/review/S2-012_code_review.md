# S2-012: 试验方法管理页面 - Code Review

**Reviewer**: sw-jerry (Software Architect/Designer)
**Date**: 2026-04-03
**Status**: **NEEDS-FIX**

---

## Summary

The implementation covers all core requirements: CRUD API, validation API, method list page, and method edit page with JSON editor and parameter configuration. The architecture follows established patterns (trait-based DI in Rust, Riverpod in Flutter). However, there are **4 critical** and **10 major** issues that must be addressed before merge.

---

## Critical Issues (Must Fix)

### C1. `MethodListResponse.fromJson` double-unwraps `data` key — runtime crash

**Files**: 
- `kayak-frontend/lib/features/methods/services/method_service.dart:40-45`
- `kayak-frontend/lib/features/methods/models/method.dart:99-109`

```dart
// method_service.dart
final response = await _apiClient.get('/api/v1/methods', ...);
return MethodListResponse.fromJson(response as Map<String, dynamic>);

// method.dart — MethodListResponse.fromJson
final data = json['data'] as Map<String, dynamic>;
```

The API response is `{code: 200, data: {items: [...], total: 5, ...}}`. `MethodListResponse.fromJson` reads `json['data']` which is correct. But this is inconsistent with `getMethod`, `createMethod`, `updateMethod` which all extract `['data']` themselves before calling `fromJson`. This inconsistency is a latent bug — if someone "fixes" `getMethods` to also extract `['data']`, it will crash.

**Fix**: Make the pattern consistent. Extract `response['data']` in `getMethods` and change `MethodListResponse.fromJson` to accept unwrapped data.

### C2. `ValidationResult.fromJson` double-unwraps `data` key

**File**: `kayak-frontend/lib/features/methods/models/method.dart:122-128`

```dart
factory ValidationResult.fromJson(Map<String, dynamic> json) {
  final data = json['data'] as Map<String, dynamic>;
  return ValidationResult(
    valid: data['valid'] as bool,
    errors: (data['errors'] as List<dynamic>).map((e) => e as String).toList(),
  );
}
```

Same issue as C1. The service passes the full API response, and `fromJson` tries to unwrap `['data']` again.

**Fix**: Extract `['data']` in the service before calling `fromJson`, or change `fromJson` to accept unwrapped data.

### C3. Parameter dialog "add" path never saves the new parameter

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart:278-280, 526-568`

The flow:
1. User taps "添加参数" → `addParameter()` creates a placeholder `new_parameter_N`
2. Dialog opens, user fills in details, taps "确定"
3. The save handler builds a `ParameterConfig` but then:

```dart
} else {
    final params = Map<String, ParameterConfig>.from(state.parameters);
    params[name] = param;
    // Use the notifier's internal state update  <-- NOTHING HAPPENS
}
```

The `params` map is created locally but **never passed to the notifier**. The user's configured parameter is silently lost.

**Fix**: Call `notifier.addParameterWithConfig(param)` or similar to actually persist the new parameter.

### C4. `TextEditingController.text` mutated in `build()` — cursor jumping

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart:67-78`

```dart
if (_nameController.text != state.name) {
  _nameController.text = state.name;
  _nameController.selection = TextSelection.fromPosition(
    TextPosition(offset: _nameController.text.length),
  );
}
```

Setting `TextEditingController.text` inside `build()` is a Flutter anti-pattern. Every state change resets the cursor to the end, making mid-string editing impossible.

**Fix**: Only sync controllers on initial load (in `initState` or when `isLoaded` transitions to true), not on every build.

---

## Major Issues (Should Fix)

### M1. Unnecessary `MethodServiceAdapter` boilerplate

The adapter is ~50 lines of pure delegation. Consider using a simpler approach or generating the adapter.

### M2. Inconsistent `fromJson` patterns across models

`Method.fromJson`, `MethodListResponse.fromJson`, and `ValidationResult.fromJson` all handle the API response wrapper differently. Standardize on one pattern.

### M3. Error banner SnackBar fires on every build

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart:125-146`

`addPostFrameCallback` is called on every `build` while `state.error != null`. Multiple SnackBars will queue up.

**Fix**: Track `_lastShownError` and only show when error changes.

### M4. No loading state during edit-mode data fetch

When opening an existing method for editing, there's no loading indicator while `loadMethod` is in progress. The UI shows stale or empty data.

### M5. Missing `@override` annotations

Several `State` methods and Riverpod provider overrides lack `@override` annotations.

### M6. Empty strings used instead of `null` for optional fields

In the parameter dialog, empty `unit` and `description` are stored as `''` rather than `null`.

### M7. No parameter name uniqueness validation

The parameter dialog allows duplicate names, which will cause issues when serializing to JSON.

### M8. `Method.fromJson` not null-safe

If API response is missing fields like `version` or `created_by`, the `as int` / `as String` cast throws a runtime `TypeError`.

### M9. No loading state during delete operation

The delete operation has no intermediate loading state. If the API is slow, the user sees no feedback.

### M10. `method_edit_page.dart` is 595 lines

Should be decomposed into smaller widget classes or separate files.

---

## Minor Issues

### m1. Dead code: unused `_isEditingParameter` and `_editingParamName` fields
### m2. Too many `TextEditingController` instances — hard to manage lifecycle
### m3. No debounce on JSON editor input
### m4. Missing `Debug` derive on some structs
### m5. `MethodServiceTrait.validate_method` return type is misleading (always returns Ok)
### m6. `_onScroll` fires on every scroll tick
### m7. `size` parameter accepted but never used by caller
### m8. Missing `const` on widget literals

---

## Positive Observations

1. **Good trait-based architecture**: `MethodServiceTrait` enables proper DI and testability
2. **Comprehensive validation**: `validate_process_definition` correctly checks Start/End nodes, valid node types, unique node IDs
3. **Clean error mapping**: `method_error_to_app_error` properly maps service errors to HTTP status codes
4. **Riverpod state management**: Immutable state with `copyWith` follows Flutter best practices
5. **Real-time JSON validation**: `hasJsonError` and `jsonError` getters provide immediate syntax feedback
6. **Pagination with infinite scroll**: Both backend and frontend implement pagination
7. **Route configuration complete**: All 6 endpoints registered
8. **UI follows Material Design 3**: Proper use of `colorScheme`, `FilledButton`, `Card`
9. **Good unit test coverage for DTOs**: Serialization, deserialization, and error conversion tests present
10. **Empty state and error state**: List page handles both gracefully

---

## Completeness vs PRD/Test Cases

| Requirement | Status | Notes |
|---|---|---|
| GET /api/v1/methods | ✅ | Implemented with pagination |
| POST /api/v1/methods | ✅ | With validation |
| GET /api/v1/methods/{id} | ✅ | |
| PUT /api/v1/methods/{id} | ✅ | |
| DELETE /api/v1/methods/{id} | ✅ | |
| POST /api/v1/methods/validate | ✅ | |
| JWT authentication | ✅ | `RequireAuth` on all endpoints |
| Method list page | ✅ | Pagination, empty state, error state |
| Method edit page (create) | ✅ | JSON editor + params |
| Method edit page (edit) | ⚠️ | No loading state (M4) |
| JSON editor with validation | ✅ | Real-time syntax check |
| Parameter table config | ❌ | Add dialog doesn't save (C3) |
| TC-S2-012-FE-014 (param add) | ❌ | Broken (C3) |
| TC-S2-012-FE-012 (JSON editor) | ⚠️ | Cursor jumping (C4) |

---

## Final Verdict: NEEDS-FIX

**4 Critical** and **10 Major** issues must be resolved before merge. Priority order:

1. **C3**: Fix parameter dialog — new parameters are never saved (blocks TC-S2-012-FE-014)
2. **C4**: Fix controller mutation in build() — cursor jumping makes editing unusable
3. **C1/C2**: Fix double-unwrapping of `data` key — runtime crash risk
4. **M3**: Fix SnackBar double-fire on error banner
5. **M8**: Add null-safety to `Method.fromJson`
6. **M4**: Add loading state during edit-mode data fetch
