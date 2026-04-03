# S2-012 Code Review: 试验方法管理页面

**Reviewer**: sw-jerry (Software Architect/Designer)
**Date**: 2026-04-03
**Status**: **NEEDS-FIX**

---

## Summary

The implementation covers all PRD requirements: backend CRUD + validation API, frontend list page + edit page with JSON editor and parameter configuration. The overall architecture follows the established patterns (trait-based DI, Riverpod state management, go_router). However, there are several critical and major issues that must be addressed before this can be merged.

---

## Critical Issues (Must Fix)

### C1. Backend: `validate_method` handler returns wrong HTTP status code for creation

**File**: `kayak-backend/src/api/handlers/method.rs`, line 149

```rust
Ok(Json(ApiResponse::success(result)))
```

The `create_method` handler uses `ApiResponse::success()` which returns `code: 200`. The test case TC-S2-012-BE-007 expects status code **201** for creation. Compare with `workbench.rs` and `device.rs` which correctly use `ApiResponse::created()`.

**Fix**: Change `ApiResponse::success(result)` to `ApiResponse::created(result)`.

### C2. Backend: `validate_method` route ordering conflict

**File**: `kayak-backend/src/api/routes.rs`, lines 257-263

```rust
Router::new()
    .route("/", post(method::create_method))
    .route("/", get(method::list_methods))
    .route("/{id}", get(method::get_method))
    .route("/{id}", put(method::update_method))
    .route("/{id}", delete(method::delete_method))
    .route("/validate", post(method::validate_method))
```

The `/validate` route is placed **after** `/{id}`. In Axum, route matching is order-dependent. A request to `POST /api/v1/methods/validate` could potentially match `/{id}` first if Axum tries to parse "validate" as a UUID. While Axum's path matching typically handles this correctly (literal routes take precedence over parameterized ones), this is fragile and inconsistent with best practice. The `/validate` route should be placed **before** `/{id}` routes.

**Fix**: Reorder to place `/validate` before `/{id}`:
```rust
.route("/", post(method::create_method))
.route("/", get(method::list_methods))
.route("/validate", post(method::validate_method))
.route("/{id}", get(method::get_method))
.route("/{id}", put(method::update_method))
.route("/{id}", delete(method::delete_method))
```

### C3. Backend: `MethodService` has circular dependency on handler layer

**File**: `kayak-backend/src/services/method_service.rs`, lines 135, 140, 151, 158, 207

```rust
) -> crate::api::handlers::method::ValidationResult {
```

The service layer directly references `crate::api::handlers::method::ValidationResult`. This violates the dependency inversion principle — the service (domain/application layer) should NOT depend on the handler (presentation layer). The `ValidationResult` type belongs in the handler layer but is used by the service.

**Fix**: Move `ValidationResult` to a shared location (e.g., `src/models/dto/method_dto.rs` or a new `src/domain/` module) and have both the service and handler import it from there.

### C4. Frontend: Parameter dialog "add" flow is broken

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart`, lines 278-281, 559-567

When clicking "添加参数", the code calls `addParameter()` which creates a parameter with a default name, then shows the dialog. But in the dialog's save handler (line 559-567), the `else` branch for new parameters has a comment `// For new params, we need to add it manually since addParameter already created one` but **never actually updates the state** — it just builds a `params` map and does nothing with it.

```dart
} else {
  // For new params, we need to add it manually since addParameter already created one
  final params = Map<String, ParameterConfig>.from(state.parameters);
  params[name] = param;
  // Use the notifier's internal state update  <-- DEAD CODE
}
```

The user's edited parameter values from the dialog are **never saved** for new parameters. Only the default values from `addParameter()` persist.

**Fix**: Call `notifier.updateParameter(newParam.name, param)` or add a dedicated `addParameterWithConfig` method to the notifier.

### C5. Frontend: `_buildErrorBanner` causes infinite snackbar loop

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart`, lines 125-146

```dart
Widget _buildErrorBanner(BuildContext context, String error) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  });
  return _buildContent(context, ref.watch(methodEditProvider));
}
```

Every time `state.error != null`, this widget rebuilds and schedules another `addPostFrameCallback` to show a snackbar. If the error persists across rebuilds (which it will until `clearError()` is called), this will show **multiple duplicate snackbars**. Additionally, `ref.watch()` inside `_buildErrorBanner` triggers a rebuild when the provider changes, which can re-trigger the callback.

**Fix**: Use a local `_hasShownError` flag in the widget state, or better yet, use a `Listener`/`ref.listen` pattern to show snackbars only on state transitions (when error changes from null to non-null).

---

## Major Issues (Should Fix)

### M1. Backend: No ownership check on update/delete

**File**: `kayak-backend/src/api/handlers/method.rs`, lines 194-206, 211-222

The `update_method` and `delete_method` handlers extract `RequireAuth(_user_ctx)` but **never pass `user_id` to the service**. Compare with `device.rs` and `workbench.rs` which pass `user_ctx.user_id` to verify ownership. A user could update or delete any method by guessing its UUID.

**Fix**: Pass `user_ctx.user_id` to the service layer and add ownership verification in the repository or service.

### M2. Backend: `get_method` does not verify ownership

**File**: `kayak-backend/src/api/handlers/method.rs`, lines 178-189

Same issue — `_user_ctx` is extracted but `user_id` is never used. Any authenticated user can read any method.

**Fix**: Either pass `user_id` for ownership check, or explicitly document that methods are globally readable (if that's the intent).

### M3. Backend: `method_error_to_app_error` leaks internal error details

**File**: `kayak-backend/src/api/handlers/method.rs`, lines 241-250

```rust
MethodServiceError::Repository(repo_err) => {
    tracing::error!("Method repository error: {:?}", repo_err);
    AppError::InternalError("数据库操作失败".to_string())
}
```

This is actually good practice — internal errors are not leaked. However, the `tracing::error!` with `{:?}` could leak sensitive data (SQL queries, connection strings) in logs. Consider using `{}` instead of `{:?}` or sanitizing the error.

**Severity**: Low, but worth noting for production hardening.

### M4. Backend: `MethodServiceAdapter` and `MethodServiceTrait` defined in handler layer

**File**: `kayak-backend/src/api/handlers/method.rs`, lines 23-104

The trait `MethodServiceTrait` and its adapter `MethodServiceAdapter` are defined in the handler module. Per the project's architecture (and comparing with `device.rs`/`workbench.rs` which use `Arc<dyn DeviceService>` / `Arc<dyn WorkbenchService>` directly), the trait should be defined alongside the service, not in the handler. The adapter pattern is a workaround for the fact that `MethodService<R>` is generic over the repository — but this adds unnecessary indirection.

**Fix**: Either:
1. Define `MethodServiceTrait` in `method_service.rs` and have `MethodService<R>` implement it directly, or
2. Use a concrete type in routes (like `ExperimentControlService` does) instead of a trait.

### M5. Frontend: `Method.fromJson` crashes on null `process_definition` or `parameter_schema`

**File**: `kayak-frontend/lib/features/methods/models/method.dart`, lines 35-38

```dart
processDefinition:
    (json['process_definition'] as Map<String, dynamic>?) ?? {},
parameterSchema:
    (json['parameter_schema'] as Map<String, dynamic>?) ?? {},
```

If the backend returns `process_definition` as a non-null but non-Map value (e.g., a string), the `as Map<String, dynamic>?` cast will throw a `TypeError`. The null-coalescing `?? {}` only handles the null case, not type mismatch.

**Fix**: Use a safer cast pattern:
```dart
processDefinition: json['process_definition'] is Map
    ? Map<String, dynamic>.from(json['process_definition'])
    : {},
```

### M6. Frontend: `MethodListResponse.fromJson` assumes `data` wrapper exists

**File**: `kayak-frontend/lib/features/methods/models/method.dart`, line 100

```dart
final data = json['data'] as Map<String, dynamic>;
```

This assumes the API response always has a `data` wrapper. The backend's `ApiResponse<T>` does wrap responses in `{code, message, data, timestamp}`, so this is correct. However, if the API returns an error response (no `data` field), this will crash. The service layer should handle error responses before calling `fromJson`.

**Note**: The `AuthenticatedApiClient` rethrows Dio exceptions, so error responses from the backend (which return non-2xx status codes) will be caught as DioExceptions and won't reach `fromJson`. This is acceptable but should be documented.

### M7. Frontend: Edit page controllers sync logic is inefficient

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart`, lines 67-78

```dart
if (_nameController.text != state.name) {
  _nameController.text = state.name;
  _nameController.selection = TextSelection.fromPosition(...);
}
```

This runs on every `build()` call (which happens on every state change). Setting `_nameController.text` triggers `onChanged`, which updates the provider state, which triggers another build — potentially creating a feedback loop. The guard condition prevents infinite loops, but it's still wasteful.

**Fix**: Use `WidgetsBinding.instance.addPostFrameCallback` for initial load only, or use a `TextEditingController` that is managed by the notifier directly.

### M8. Backend: `validate_process_definition` does not validate `connections`/`edges`

**File**: `kayak-backend/src/services/method_service.rs`, lines 132-211

The validation checks nodes (type, ID uniqueness, Start/End presence) but does not validate:
- Whether nodes are connected (orphaned nodes)
- Whether connections reference valid node IDs
- Whether the graph has cycles (for non-loop node types)
- Whether Start has no incoming edges and End has no outgoing edges

The design doc (section 2.3) only lists 4 validation rules, so this is technically compliant. However, a process definition with disconnected nodes or invalid connections would pass validation and fail at runtime.

**Recommendation**: Add at minimum a check that all node references in connections/edges point to existing node IDs.

### M9. Frontend: No "unsaved changes" warning on navigation away

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart`

The `MethodEditState` tracks `isDirty` but the edit page never uses it to warn the user before navigating away. If a user makes changes and presses the back button, all changes are silently lost.

**Fix**: Use `PopScope` (Flutter 3.12+) or `WillPopScope` to intercept back navigation when `isDirty` is true and show a confirmation dialog.

### M10. Backend: `list_methods` query parameter validation is duplicated

**File**: `kayak-backend/src/api/handlers/method.rs`, lines 160-165

The handler clamps page/size values inline:
```rust
let page = if query.page < 1 { 1 } else { query.page };
let size = if query.size < 1 || query.size > 100 { 10 } else { query.size };
```

This logic is also tested in unit tests (lines 314-330) but is not encapsulated. Compare with `device.rs` which uses `Option<i64>` with `unwrap_or()`. The method handler uses non-optional `i64` with serde defaults, then clamps — a mixed approach.

**Fix**: Either use `Option<i64>` with defaults in the service layer, or create a `clamp()` helper. Consistency with other handlers is recommended.

---

## Minor Issues (Nice to Have)

### m1. Backend: `Path` import placed after function definitions

**File**: `kayak-backend/src/api/handlers/method.rs`, line 252

```rust
use axum::extract::Path;
```

This import appears at line 252, after all the handler functions that use it. It works due to Rust's module-level imports, but it's unconventional and hurts readability.

**Fix**: Move to the top with other imports.

### m2. Frontend: `method_edit_page.dart` has unused fields

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart`, lines 34-36

```dart
// ignore: unused_field
bool _isEditingParameter = false;
// ignore: unused_field
String? _editingParamName; // Reserved for future use
```

Dead code. Remove or implement.

### m3. Frontend: JSON editor lacks syntax highlighting

**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart`, lines 241-258

The design doc test case TC-S2-012-FE-012 expects "语法高亮" (syntax highlighting) and "显示行号" (line numbers), but the implementation uses a plain `TextField` with monospace font only.

**Note**: This is a known limitation of using native TextField. Consider using a package like `flutter_code_editor` or `highlight` if syntax highlighting becomes a priority.

### m4. Backend: No rate limiting on validate endpoint

The `/api/v1/methods/validate` endpoint could be abused for DoS since it performs JSON parsing and validation on every call. Consider adding rate limiting.

### m5. Frontend: `MethodListPage` scroll listener fires too aggressively

**File**: `kayak-frontend/lib/features/methods/providers/method_list_provider.dart`, line 68

```dart
final hasMore = newMethods.length < response.total;
```

This compares the accumulated method count against total, but `newMethods.length` after append could exceed `response.total` if the API returns stale data. Should use `response.items.length < response.size` instead.

### m6. Backend: `delete_method` does not check if method is referenced by experiments

If a method is used by an active or historical experiment, deleting it could break data integrity. Consider adding a foreign key check or soft delete.

### m7. Frontend: `ParameterConfig.fromJson` has unsafe cast

**File**: `kayak-frontend/lib/features/methods/models/method.dart`, line 148-156

```dart
factory ParameterConfig.fromJson(String name, Map<String, dynamic> json) {
  return ParameterConfig(
    name: name,
    type: json['type'] as String? ?? 'string',
```

If `json['type']` exists but is not a String (e.g., a number), the cast will throw. Use `json['type']?.toString() ?? 'string'` for safety.

### m8. Backend: `MethodService::update_method` allows setting description to empty string

**File**: `kayak-backend/src/services/method_service.rs`, lines 101-103

```rust
if let Some(d) = description {
    method.description = Some(d);
}
```

If the caller passes `description: Some("")`, it sets description to `Some("")` rather than `None`. This is inconsistent with how `description: None` would leave it unchanged. Consider treating empty string as `None`.

---

## Positive Observations

1. **Good trait-based design**: The `MethodServiceTrait` enables dependency injection and testability, consistent with the project's architecture.

2. **Comprehensive validation**: The `validate_process_definition` function thoroughly checks node types, ID uniqueness, and Start/End presence.

3. **Well-structured frontend state management**: `MethodListState` and `MethodEditState` are well-designed with proper `copyWith` patterns and computed properties (`canSave`, `hasJsonError`).

4. **Pagination support**: Both backend and frontend implement pagination correctly with load-more functionality.

5. **Good unit test coverage**: The backend handler has 11 unit tests covering default values, serialization, and error conversion.

6. **Consistent API response format**: Uses the project's `ApiResponse<T>` wrapper consistently.

7. **Proper auth middleware**: All endpoints are protected with `RequireAuth` middleware.

8. **Clean separation of concerns**: Model → Service → Handler → Route layers are well separated.

---

## Test Case Coverage Analysis

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC-S2-012-BE-001 (list success) | ✅ Covered | Handler + service support |
| TC-S2-012-BE-002 (empty list) | ✅ Covered | Repository returns empty vec |
| TC-S2-012-BE-003 (pagination) | ✅ Covered | Handler clamps page/size |
| TC-S2-012-BE-004 (unauthorized) | ✅ Covered | `RequireAuth` middleware |
| TC-S2-012-BE-005 (detail success) | ✅ Covered | `get_method` handler |
| TC-S2-012-BE-006 (detail not found) | ✅ Covered | Returns 404 |
| TC-S2-012-BE-007 (create success) | ⚠️ **Status code mismatch** | Returns 200, expected 201 |
| TC-S2-012-BE-008 (empty name) | ✅ Covered | Service validates |
| TC-S2-012-BE-009 (name too long) | ✅ Covered | Service validates |
| TC-S2-012-BE-010 (non-object process_def) | ✅ Covered | Service validates |
| TC-S2-012-BE-011 (non-object param_schema) | ✅ Covered | Service validates |
| TC-S2-012-BE-012 (update success) | ✅ Covered | Handler + service |
| TC-S2-012-BE-013 (update not found) | ✅ Covered | Repository returns NotFound |
| TC-S2-012-BE-014 (update process_def) | ✅ Covered | Partial update supported |
| TC-S2-012-BE-015 (delete success) | ✅ Covered | Handler + service |
| TC-S2-012-BE-016 (delete not found) | ✅ Covered | Repository returns NotFound |
| TC-S2-012-BE-017 (verify deleted) | ✅ Covered | GET returns 404 after delete |
| TC-S2-012-BE-018 (validate valid) | ✅ Covered | Validation logic |
| TC-S2-012-BE-019 (missing Start) | ✅ Covered | Validation logic |
| TC-S2-012-BE-020 (missing End) | ✅ Covered | Validation logic |
| TC-S2-012-BE-021 (invalid node type) | ✅ Covered | Validation logic |
| TC-S2-012-FE-001 (loading state) | ✅ Covered | `isLoading` in state |
| TC-S2-012-FE-002 (display list) | ✅ Covered | `_buildMethodCard` |
| TC-S2-012-FE-003 (empty state) | ✅ Covered | `_buildEmptyState` |
| TC-S2-012-FE-004 (create button) | ✅ Covered | `context.push('/methods/create')` |
| TC-S2-012-FE-005 (click card) | ✅ Covered | `context.push('/methods/{id}/edit')` |
| TC-S2-012-FE-006 (delete dialog) | ✅ Covered | `_showDeleteDialog` |
| TC-S2-012-FE-007 (delete confirm) | ✅ Covered | Calls `deleteMethod` |
| TC-S2-012-FE-008 (pagination) | ✅ Covered | `loadMore` with scroll |
| TC-S2-012-FE-009 (create mode) | ✅ Covered | `MethodEditPage` with null methodId |
| TC-S2-012-FE-010 (edit mode) | ✅ Covered | `loadMethod` populates fields |
| TC-S2-012-FE-011 (name validation) | ✅ Covered | `canSave` + form validator |
| TC-S2-012-FE-012 (JSON editor) | ⚠️ **Partial** | No syntax highlighting or line numbers |
| TC-S2-012-FE-013 (JSON validation) | ✅ Covered | `hasJsonError` computed property |
| TC-S2-012-FE-014 (add parameter) | ✅ Covered | `addParameter` + dialog |
| TC-S2-012-FE-015 (delete parameter) | ✅ Covered | `removeParameter` |
| TC-S2-012-FE-016 (save success) | ✅ Covered | `saveMethod` + snackbar + pop |
| TC-S2-012-FE-017 (save failure) | ✅ Covered | Error state + snackbar |
| TC-S2-012-FE-018 (cancel) | ⚠️ **Missing** | No explicit cancel button |
| TC-S2-012-FE-019 (validate button) | ✅ Covered | AppBar validate button |
| TC-S2-012-FE-020 (validate pass) | ✅ Covered | `_buildValidationResult` |
| TC-S2-012-FE-021 (validate fail) | ✅ Covered | Error list display |

---

## Final Verdict: NEEDS-FIX

The implementation is structurally sound and covers most requirements, but the following **must be fixed** before merge:

1. **C1**: Fix HTTP status code for create (200 → 201)
2. **C2**: Reorder `/validate` route before `/{id}` routes
3. **C3**: Move `ValidationResult` out of handler layer to fix circular dependency
4. **C4**: Fix parameter dialog save logic for new parameters (dead code)
5. **C5**: Fix infinite snackbar loop in error banner

And the following **should be fixed**:

6. **M1/M2**: Add ownership verification for update/delete/get operations
7. **M9**: Add unsaved changes warning on navigation away
8. **M5**: Add safer JSON casting in `Method.fromJson`

After these fixes, a follow-up review is recommended.
