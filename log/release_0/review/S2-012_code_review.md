# S2-012: 试验方法管理页面 - Code Review

**Reviewer**: sw-jerry (Software Architect/Designer)
**Date**: 2026-04-03
**Status**: **NEEDS-FIX**

---

## Summary

The implementation covers the core requirements: CRUD API, validation API, method list page, and method edit page with JSON editor and parameter configuration. The overall architecture follows the project's established patterns (trait-based DI in Rust, Riverpod in Flutter). However, several critical and major issues need to be addressed before this can be considered production-ready.

---

## Critical Issues (Must Fix)

### C1. Route ordering bug: `/validate` is unreachable
**File**: `kayak-backend/src/api/routes.rs:253-265`

```rust
Router::new()
    .route("/", post(method::create_method))
    .route("/", get(method::list_methods))
    .route("/{id}", get(method::get_method))
    .route("/{id}", put(method::update_method))
    .route("/{id}", delete(method::delete_method))
    .route("/validate", post(method::validate_method))
```

Axum matches routes in order. The `"/{id}"` pattern will match `"validate"` as a path parameter, so `POST /api/v1/methods/validate` will be routed to the `/{id}` handlers before reaching `/validate`. The `/validate` route must be placed **before** the `/{id}` routes.

**Fix**: Move `.route("/validate", post(method::validate_method))` above the `/{id}` routes.

### C2. `get_method` does not check ownership — any user can read any method
**File**: `kayak-backend/src/api/handlers/method.rs:178-189`

The `get_method` handler receives `RequireAuth(_user_ctx)` but discards `user_ctx`. It then calls `handler.get_method(id)` which queries the repository without any user_id filter. Any authenticated user can read any other user's methods. Same issue exists for `update_method` and `delete_method`.

**Fix**: Pass `user_ctx.user_id` to the service layer and verify ownership before returning/modifying/deleting.

### C3. `MethodEditNotifier` provider is shared across all edit pages — state leaks between navigations
**File**: `kayak-frontend/lib/features/methods/providers/method_edit_provider.dart:246-250`

```dart
final methodEditProvider =
    StateNotifierProvider<MethodEditNotifier, MethodEditState>((ref) {
  final service = ref.watch(methodServiceProvider);
  return MethodEditNotifier(service);
});
```

`methodEditProvider` is a global singleton. When the user navigates from editing method A to creating a new method (or editing method B), the previous state persists. The `loadMethod` call in `initState` is async — during the load, the UI will display stale data from the previous edit session.

**Fix**: Either (a) use `AutoDisposeStateNotifierProvider` so the provider is disposed when the page is popped, or (b) reset state in `initState` before loading. The design doc shows `MethodEditState` with `isLoaded` flag but this is insufficient — the old state's `name`, `processDefinitionJson`, and `parameters` are visible until the new data loads.

### C4. `MethodListResponse.fromJson` expects nested `data` key but `getMethods` passes the full response
**File**: `kayak-frontend/lib/features/methods/services/method_service.dart:41-45`

```dart
final response = await _apiClient.get(...);
return MethodListResponse.fromJson(response as Map<String, dynamic>);
```

`MethodListResponse.fromJson` (method.dart:99) reads `json['data']` expecting the response to be wrapped in `{code, data, message}`. But `getMethods` passes the raw API response directly. This is inconsistent with how `getMethod`, `createMethod`, and `updateMethod` all extract `data['data']` themselves.

**Fix**: Either extract `data['data']` in `getMethods` before passing to `fromJson`, or change `MethodListResponse.fromJson` to accept the unwrapped data object.

---

## Major Issues (Should Fix)

### M1. `update_method` allows clearing `description` but not setting it to null explicitly
**File**: `kayak-backend/src/services/method_service.rs:78-84`

```rust
if let Some(d) = description {
    method.description = Some(d);
}
```

The repository update logic in `method_repo.rs:101-103` always wraps `description` in `Some(d)`. There is no way for a user to set `description` back to `null` once it has a value. The `UpdateMethodRequest` allows `Option<String>` but the repository treats `Some("")` as a non-null value.

**Fix**: The repository should distinguish between "don't update" (`None`) and "set to null" (a separate sentinel or explicit flag).

### M2. `MethodServiceAdapter` and `MethodServiceTrait` are defined in the handler layer
**File**: `kayak-backend/src/api/handlers/method.rs:23-104`

The trait and adapter live in `api/handlers/method.rs`. Traits should be defined in the service layer or a shared contracts module. Having the handler define the service trait inverts the dependency direction — the service layer should not depend on the handler layer, but the adapter pattern here forces the handler to know about `MethodService<SqlxMethodRepository>` concrete types.

**Fix**: Move `MethodServiceTrait` to `src/services/` or a `src/contracts/` module.

### M3. `validate_process_definition` creates a circular dependency from service → handler
**File**: `kayak-backend/src/services/method_service.rs:135`

```rust
) -> crate::api::handlers::method::ValidationResult {
```

The service layer imports `ValidationResult` from the handler layer (`crate::api::handlers::method`). This is a layering violation — the service should not depend on the handler.

**Fix**: Move `ValidationResult` to the service layer or a shared DTO module. The handler should import it from there.

### M4. `hasMore` calculation is incorrect
**File**: `kayak-frontend/lib/features/methods/providers/method_list_provider.dart:69`

```dart
final hasMore = newMethods.length < response.total;
```

This compares the accumulated list length against the total count. When appending pages, `newMethods.length` may equal `response.total` even though more pages exist (e.g., total=5, page1 returns 2 items, page2 returns 3 items → `hasMore = 5 < 5 = false`, correct by coincidence). But if total changes between requests (user deletes a method while loading), this produces incorrect results.

**Fix**: Use `(page * size) < response.total` or rely on `response.items.length < size` from the current page response.

### M5. Error banner shows SnackBar on every build
**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart:125-146`

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

`addPostFrameCallback` is called on every `build` while `state.error != null`. If the error persists across multiple rebuilds (e.g., during save retry), this will show multiple SnackBars. The error is also never cleared after the SnackBar is dismissed unless the user explicitly taps "关闭".

**Fix**: Use a flag or `didUpdateWidget`/`didChangeDependencies` to show the SnackBar only once per error change, or use an `Effect`/`Listener` pattern.

### M6. Parameter dialog does not add new parameters correctly
**File**: `kayak-frontend/lib/features/methods/screens/method_edit_page.dart:526-568`

When adding a new parameter via the dialog, `addParameter()` is called first (creating a placeholder), but then the dialog's save handler tries to add the parameter manually:

```dart
} else {
    // For new params, we need to add it manually since addParameter already created one
    final params = Map<String, ParameterConfig>.from(state.parameters);
    params[name] = param;
    // Use the notifier's internal state update
}
```

The comment says it all — the parameter is never actually saved to state. The `params` map is created but never passed to the notifier.

**Fix**: Call `notifier.updateParameter` or a dedicated `addParameterWithConfig` method instead of the incomplete manual map manipulation.

### M7. Missing `description` field clearing in update
**File**: `kayak-backend/src/db/repository/method_repo.rs:101-103`

```rust
if let Some(d) = description {
    method.description = Some(d);
}
```

If the user passes `description: Some("")` in the update request, this sets `method.description = Some("")` rather than treating it as a cleared description. The design doc says `description` is `string | null` in the update request.

### M8. No pagination size validation in the service layer
**File**: `kayak-backend/src/services/method_service.rs:96-110`

The `list_methods` service method accepts `page` and `size` directly without validation. If `page < 1`, the offset calculation `(page - 1) * size` produces a negative value, which SQLite may handle unpredictably. The handler clamps these values, but the service is the one that should enforce invariants.

**Fix**: Add validation in the service layer or use a typed `Pagination` struct that guarantees valid values.

### M9. `Method.fromJson` will throw on missing/null fields
**File**: `kayak-frontend/lib/features/methods/models/method.dart:30-44`

```dart
version: json['version'] as int,
createdBy: json['created_by'] as String,
createdAt: DateTime.parse(json['created_at'] as String),
```

If any of these fields are null or missing from the API response, the cast will throw a `TypeError` rather than a parseable error. The `processDefinition` and `parameterSchema` fields handle nulls gracefully with `?? {}`, but the others do not.

**Fix**: Add null-safe handling or use a JSON parsing library like `freezed`/`json_serializable`.

### M10. `MethodListPage` scroll listener fires on every scroll event
**File**: `kayak-frontend/lib/features/methods/screens/method_list_page.dart:38-46`

```dart
void _onScroll() {
    final state = ref.read(methodListProvider);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoadingMore) {
      ref.read(methodListProvider.notifier).loadMore();
    }
}
```

This fires synchronously on every scroll tick. While the `!state.isLoadingMore` guard prevents duplicate requests, it still reads from the provider on every scroll event. Consider using a `NotificationListener<ScrollNotification>` with `ScrollEndNotification` or debouncing.

---

## Minor Issues (Nice to Have)

### m1. `use axum::extract::Path` import at bottom of file
**File**: `kayak-backend/src/api/handlers/method.rs:252`

The `Path` import is placed after all the handler functions, between the main code and the test module. Imports should be at the top of the file with the other `use` statements.

### m2. `ValidationResult` is duplicated across handler and frontend model
The Rust `ValidationResult` and Flutter `ValidationResult` are structurally identical, which is expected. However, the frontend model expects `json['data']` wrapper while the backend returns `ApiResponse<ValidationResult>`. Verify the frontend `ValidationResult.fromJson` correctly handles the nested `data` key (it does — line 122-128).

### m3. `method_edit_page.dart` has 595 lines — should be split
The edit page is a single 595-line file with multiple widget builders. Consider extracting `_buildJsonEditor`, `_buildParameterSection`, `_buildParameterCard`, `_buildValidationResult`, and `_showParameterDialog` into separate widget classes or a separate file.

### m4. Missing `const` on some widgets
Several `Text`, `Icon`, and `SizedBox` widgets in `method_edit_page.dart` and `method_list_page.dart` could be `const` for better performance.

### m5. `_formatDateTime` should use `intl` package
**File**: `kayak-frontend/lib/features/methods/screens/method_list_page.dart:260-263`

Manual date formatting is fragile. Use `DateFormat` from `package:intl` for locale-aware formatting.

### m6. `MethodService.getMethods` doesn't use the `size` parameter
**File**: `kayak-frontend/lib/features/methods/services/method_service.dart:40`

```dart
Future<MethodListResponse> getMethods({int page = 1, int size = 10}) async {
    final response = await _apiClient.get(
      '/api/v1/methods',
      queryParameters: {'page': page, 'size': size},
    );
```

The `size` parameter is passed but `MethodListNotifier.loadMethods` (line 65) calls `_service.getMethods(page: page)` without passing `size`. The default of 10 is used, which is fine, but the parameter is misleading.

### m7. No loading state during delete operation
**File**: `kayak-frontend/lib/features/methods/providers/method_list_provider.dart:88-96`

The `deleteMethod` method doesn't set any loading state. The UI shows no indication that a delete is in progress. If the API is slow, the user might tap delete multiple times.

### m8. `MethodEditState` default `processDefinitionJson` is hardcoded
**File**: `kayak-frontend/lib/features/methods/providers/method_edit_provider.dart:29-30`

The default JSON template is hardcoded in the state class. This should be a constant or configurable.

### m9. Test coverage gaps
The backend unit tests cover DTOs, error conversion, and query defaults, but do not test:
- The validation logic (`validate_process_definition`) with actual node structures
- The handler-to-service integration
- Ownership checks (once implemented)

### m10. `MethodServiceTrait.validate_method` returns `Result<ValidationResult, MethodServiceError>` but never errors
The `validate_method` in the adapter (line 71-76) always returns `Ok(...)`. The `MethodServiceError` in the `Result` type is misleading since validation never fails with an error — it returns `valid: false` with error messages in the response body.

---

## Positive Observations

1. **Good trait-based architecture**: The `MethodServiceTrait` + `MethodServiceAdapter` pattern enables proper dependency injection and testability.
2. **Comprehensive validation**: The `validate_process_definition` method correctly checks for Start/End nodes, valid node types, and unique node IDs per the design doc.
3. **Clean error handling**: The `method_error_to_app_error` converter properly maps service errors to HTTP status codes.
4. **Pagination support**: Both backend and frontend implement pagination with `hasMore` logic.
5. **Riverpod state management**: The use of `StateNotifier` with immutable state and `copyWith` follows Flutter best practices.
6. **JSON validation in UI**: The `hasJsonError` and `jsonError` getters in `MethodEditState` provide real-time JSON syntax feedback.
7. **Consistent naming**: Method names follow the project conventions (`create_method`, `list_methods`, etc.).
8. **Good test coverage for DTOs**: The backend has unit tests for serialization/deserialization and error conversion.
9. **Route configuration is complete**: All 6 endpoints from the design doc are registered in `routes.rs`.
10. **UI follows Material Design 3**: Uses `colorScheme`, `FilledButton`, `Card`, and proper spacing.

---

## Completeness vs PRD/Test Cases

| Requirement | Status | Notes |
|---|---|---|
| GET /api/v1/methods | ✅ | Implemented with pagination |
| POST /api/v1/methods | ✅ | With validation |
| GET /api/v1/methods/{id} | ✅ | Missing ownership check (C2) |
| PUT /api/v1/methods/{id} | ✅ | Missing ownership check (C2) |
| DELETE /api/v1/methods/{id} | ✅ | Missing ownership check (C2) |
| POST /api/v1/methods/validate | ⚠️ | Route unreachable (C1) |
| JWT authentication | ✅ | `RequireAuth` on all endpoints |
| Method list page | ✅ | With pagination, empty state, error state |
| Method edit page (create) | ✅ | With JSON editor and params |
| Method edit page (edit) | ✅ | Loads existing data |
| JSON editor with validation | ✅ | Real-time syntax check |
| Parameter table config | ⚠️ | Add dialog broken (M6) |
| Route: /methods | ✅ | |
| Route: /methods/create | ✅ | |
| Route: /methods/:id/edit | ✅ | |
| TC-S2-012-BE-018 to 021 (validation) | ⚠️ | Route ordering blocks access |
| TC-S2-012-FE-014 to 015 (param add/delete) | ⚠️ | Add dialog doesn't save (M6) |

---

## Final Verdict: NEEDS-FIX

**4 Critical** and **10 Major** issues must be resolved before this can be merged. The most urgent are:

1. **C1**: Fix route ordering — `/validate` must come before `/{id}`
2. **C2**: Add ownership checks to `get_method`, `update_method`, `delete_method`
3. **C3**: Use `autoDispose` for `methodEditProvider` or reset state on navigation
4. **C4**: Fix `MethodListResponse` JSON parsing inconsistency

After these are fixed, address the parameter dialog bug (M6) and the SnackBar double-fire issue (M5) for a complete implementation.
