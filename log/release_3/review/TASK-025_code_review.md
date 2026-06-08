# Code Review Report — TASK-025

## Review Information

- **Reviewer**: sw-jerry (Software Architect)
- **Date**: 2026-06-08
- **Branch**: `feature/task-025-method-management-ui`
- **Commits Reviewed**: ae4b7dd (1 commit: "feat(method): implement TASK-025 method management UI")
- **Base Commit**: 0375daf
- **Task**: TASK-025 — M7 试验方法管理 UI

---

## Summary

- **Status**: CHANGES_REQUESTED
- **Total Issues**: 12
- **Critical**: 1
- **High**: 4
- **Medium**: 5
- **Low**: 2

### Files Changed

| File | Change | Lines |
|------|--------|-------|
| `lib/pages/method/method_list_page.dart` | Modified | +600 |
| `lib/pages/method/method_edit_page.dart` | Modified | +1557 |
| `lib/providers/method_provider.dart` | Added | +259 |
| `lib/services/method_service.dart` | Modified | +102 |

### Overall Assessment

The implementation is **functionally solid** — the core UX flow (list → create/edit → save → delete) is well-structured, the JSON editor with line numbers is a nice touch, the response-adaptive layout works correctly, and `flutter analyze` passes with zero issues. However, there is **one critical architectural violation** (no l10n) and several high-severity code quality issues that must be addressed before merging.

---

## Issues Found

---

### [CRITICAL] Issue 1: All user-facing strings are hardcoded — no l10n integration

- **Location**: 
  - `kayak-frontend/lib/pages/method/method_list_page.dart` — Lines 102, 103, 107, 113, 114, 122, 130-133, 141-142, 149-151, 179, 189, 223, 423, 441, 451
  - `kayak-frontend/lib/pages/method/method_edit_page.dart` — Lines 142, 201, 222, 246, 258, 268, 284, 297, 311, 319, 346, 355, 377, 386, 389, 434-435, 444, 467, 484, 494, 510, 515-516, 522, 532-533, 546, 551, 552, 556, 575, 593, 595, 601, 612, 638, 652, 709, 723-725, 729, 733, 740, 750, 754, 763, 772, 778, 799, 829, 832, 853, 861, 863, 909, 932-933, 946, 961, 963-964, 973, 1028, 1031, 1239, 1260, 1289, 1331-1347, etc.
- **Description**: The tasks.md §TASK-025 explicitly requires use of reusable components from TASK-007, which in turn requires all text via l10n from TASK-006. Currently, **every single string** in both pages is hardcoded Chinese, including buttons, labels, error messages, tooltips, section titles, hints, column headers, and dialog text. This affects approximately **100+ strings**.
- **Impact**: 
  - Violates the fundamental architectural principle established in TASK-006 (all user-facing text must go through ARB files)
  - No English fallback — app is unusable for non-Chinese users
  - Any future language addition requires hunting down every hardcoded string
  - Error messages cannot be reused across the app
- **Recommendation**: 
  1. Add all method-related keys to `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`
  2. Replace every hardcoded string with `AppLocalizations.of(context)!` calls
  3. Follow the pattern already established in other pages (e.g., `l10n.workbenchList`, `l10n.create`, `l10n.cancel`, etc.)
- **Status**: OPEN

---

### [HIGH] Issue 2: `DropdownButtonFormField` uses `initialValue` instead of `value`

- **Location**: 
  - `kayak-frontend/lib/pages/method/method_edit_page.dart`, Line 775: `initialValue: paramType`
  - `kayak-frontend/lib/pages/method/method_edit_page.dart`, Line 905: `initialValue: enumOptions.value.contains(...)`
- **Description**: Both `DropdownButtonFormField` instances inside `_showParameterDialog` use the `initialValue` parameter. This value is only set once during `FormFieldState.initState()`. When the user changes the parameter type (via `onChanged` → `setDialogState` → rebuild), the `DropdownButtonFormField` widget is re-created at the same position in the widget tree, but Flutter's element lifecycle **may not update** the dropdown's displayed value because `initialValue` is only consulted at creation and on `didUpdateWidget` (which requires the widget instance to have a different `initialValue`). In practice with `StatefulBuilder`, this often works due to widget key recreation, but the pattern is **fragile and non-idiomatic**.
- **Impact**: Potential for the dropdown display to become desynchronized from the actual `paramType` state, causing user confusion.
- **Recommendation**: Replace `initialValue:` with `value:` parameter and manage the dropdown's current value explicitly in the stateful builder's closure scope (which already works because `paramType` is a local variable captured by the builder). Example fix:
  ```dart
  DropdownButtonFormField<String>(
    value: paramType,  // <-- use value, not initialValue
    decoration: const InputDecoration(...),
    items: [...],
    onChanged: (value) {
      setDialogState(() {
        paramType = value ?? 'number';
      });
    },
  ),
  ```
  Same fix applies to the enum default value dropdown at line 904.
- **Status**: OPEN

---

### [HIGH] Issue 3: No tests exist for method pages

- **Location**: `kayak-frontend/test/` — no `method_*` test files found
- **Description**: The TDD workflow mandated by tasks.md requires test cases to be written before or alongside implementation. No widget tests or unit tests exist for `MethodListPage`, `MethodEditPage`, `MethodListNotifier`, or `MethodDetailNotifier`. The test specification `log/release_3/test/TASK-025_test_cases.md` (43 test cases) has been prepared but zero tests have been implemented.
- **Impact**:
  - Critical regressions may go undetected
  - Hardcoded strings would have been immediately caught by test assertions against l10n
  - `_validateForm`, `_buildParameterSchema`, `_save`, `_confirmLeave`, and `_confirmDelete` logic is untested
  - Riverpod state transitions (loading → data/error/empty) are unverified
- **Recommendation**: Implement at minimum the P0 test cases from the test spec:
  - TC-001: Loading skeleton screen
  - TC-002: Data state with card list
  - TC-005: Empty state guidance
  - TC-006: Error state + retry
  - TC-007: Search filtering
  - TC-010/011: Edit/Delete card actions
  - TC-012: Create button navigation
  - TC-017: Create mode initialization
  - TC-019: Name validation
  - TC-022: JSON validation
  - TC-026: Add parameter
  - TC-033: Save create → navigate back
  - TC-037: Unsaved changes confirmation
- **Status**: OPEN

---

### [HIGH] Issue 4: `_confirmLeave` uses unnecessarily complex `Completer<bool>` + `unawaited` pattern

- **Location**: `kayak-frontend/lib/pages/method/method_edit_page.dart`, Lines 339-365
- **Description**: The `_confirmLeave` method uses a `Completer<bool>` to bridge the `onConfirm`/`onCancel` callbacks of `ConfirmDialog.show()`. While functionally correct, this is fragile:
  1. The fallback `unawaited(dialogResult.then(...))` races with `onConfirm`/`onCancel` callbacks
  2. If `ConfirmDialog.show()` ever changes its internal callback timing relative to `Navigator.pop()`, this silently breaks
  3. The dialog dismisses `dismissible: true` (default), so clicking outside completes the completer via the fallback — but this sidesteps the explicit user intent capture
- **Impact**: Fragile code that may break if `ConfirmDialog.show()` is refactored. Hard to reason about and debug.
- **Recommendation**: Two options:
  1. **Preferred**: Modify `ConfirmDialog.show()` to return `Future<bool>` (confirm = `true`, cancel/dismiss = `false`). Then `_confirmLeave` simplifies to:
     ```dart
     Future<bool> _confirmLeave() async {
       if (!_isDirty) return true;
       return ConfirmDialog.show(
         context: context,
         title: l10n.unsavedChanges,
         description: l10n.unsavedChangesHint,
         confirmLabel: l10n.discardAndLeave,
         cancelLabel: l10n.stayOnPage,
         dismissible: false,  // force explicit choice
       );
     }
     ```
  2. **Fallback**: If modifying the shared component isn't desired, at minimum set `dismissible: false` to prevent the ambiguous dismissed-without-choice path, and add a comment explaining the pattern.
- **Status**: OPEN

---

### [HIGH] Issue 5: Both `parameter_schema` and `parameters` sent in save payload

- **Location**: `kayak-frontend/lib/pages/method/method_edit_page.dart`, Lines 229-237
- **Description**: The `_save()` method builds the request body with both `parameter_schema` (generated by `_buildParameterSchema()`) and `parameters` (serialized list of `MethodParameter`). These represent the same data in two different formats. The JSON Schema-style `parameter_schema` uses field names like `minimum`, `maximum`, `type`, `properties`, `required` while the `parameters` list uses `MethodParameter.toJson()` with field names like `min`, `max`, `type`, `key`, `required`, `default_value`, etc.
- **Impact**: Potential backend ambiguity — which field is authoritative? If the backend ignores one and uses the other, redundant data is sent. If the backend validates both and they differ, unexpected errors may occur.
- **Recommendation**: Clarify with the backend which format is expected. Send only the authoritative field. If both are needed (e.g., `parameter_schema` for validation, `parameters` for display), add a comment documenting the purpose of each.
- **Status**: OPEN

---

### [MEDIUM] Issue 6: `FormatException` internal message leaked to user in `_validateJson`

- **Location**: `kayak-frontend/lib/pages/method/method_edit_page.dart`, Line 142
- **Description**: 
  ```dart
  _jsonErrorMessage = 'JSON 格式错误：${e.message}';
  ```
  The `FormatException.message` from `dart:convert` is technically internal and can include raw character positions like `"Unexpected character (at offset 5)"`. This is not a user-friendly message.
- **Impact**: Debug information leaked to users; inconsistent with the task requirement of friendly error messages.
- **Recommendation**: Use a generic, l10n-ized message for the user, and only log the technical details:
  ```dart
  _jsonErrorMessage = l10n.jsonFormatError;  // "JSON format is invalid"
  // optionally: log the technical message for debugging
  ```
- **Status**: OPEN

---

### [MEDIUM] Issue 7: Search executes immediately on every keystroke without debounce

- **Location**: `kayak-frontend/lib/pages/method/method_list_page.dart`, Lines 59-61
- **Description**: The search `onChanged` callback directly calls `ref.read(methodListProvider.notifier).search(value)`, which triggers a full state transition to `AsyncLoading` and rebuilds the entire list. The UI spec (`method_spec.md` §2.2) and test spec (`TC-007`) both require a 200-300ms debounce. Currently, typing "拉伸" fires 3 state transitions (one per character), each causing a complete list rebuild.
- **Impact**: Flashing/jittering UI during rapid typing; unnecessary provider rebuilds degrading performance; visual loading indicators appearing and disappearing rapidly.
- **Recommendation**: Implement debounce in either the `MethodListNotifier.search()` method (using a `Timer`) or in the page widget (using a `Timer` + `_debounceTimer`). The prefab `_SearchBar` sub-widget should fire `onChanged`, and the page should debounce before forwarding to the provider:
  ```dart
  Timer? _debounce;
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(methodListProvider.notifier).search(value);
    });
  }
  ```
- **Status**: OPEN

---

### [MEDIUM] Issue 8: `_SearchBar` clear button visibility depends on parent rebuild timing

- **Location**: `kayak-frontend/lib/pages/method/method_list_page.dart`, Lines 228-239
- **Description**: The `_SearchBar` is a `StatelessWidget` that evaluates `controller.text.isNotEmpty` at build time to show/hide the clear button. Since it doesn't listen to the controller (no `ListenableBuilder`/`ValueListenableBuilder`), the clear button's visibility only updates when the parent widget rebuilds. The parent does rebuild because `search()` triggers provider state change, but this is indirect and fragile — if search is ever optimized away or debounced, the button won't respond until the next rebuild.
- **Impact**: Potential UX bug if the widget tree changes — the clear button may not appear when text is entered, or may linger after the text is cleared programmatically.
- **Recommendation**: Make `_SearchBar` a `StatefulWidget` that adds a listener to the controller:
  ```dart
  class _SearchBar extends StatefulWidget { ... }
  
  class _SearchBarState extends State<_SearchBar> {
    @override
    void initState() {
      super.initState();
      widget.controller.addListener(_onControllerChanged);
    }
    
    void _onControllerChanged() => setState(() {});
  
    @override
    Widget build(BuildContext context) {
      final hasText = widget.controller.text.isNotEmpty;
      // ...
    }
  }
  ```
- **Status**: OPEN

---

### [MEDIUM] Issue 9: `_BuildMethodButton` uses `MediaQuery` instead of `LayoutBuilder`

- **Location**: `kayak-frontend/lib/pages/method/method_list_page.dart`, Lines 173-174
- **Description**: The `_BuildMethodButton` widget uses `MediaQuery.of(context).size.width` to determine mobile vs desktop layout, while `_MethodGrid` on the same page uses `LayoutBuilder`. These two approaches have subtly different semantics — `MediaQuery` gives the full display width (including system bars on mobile) while `LayoutBuilder` gives the parent widget's constraints. Using both inconsistently can lead to different breakpoint behavior between the button and the grid.
- **Impact**: On some devices (e.g., a browser window at exactly 600px), the button may show the mobile variant while the grid shows 2 columns, or vice versa. Minor visual inconsistency.
- **Recommendation**: Use `LayoutBuilder` consistently throughout the page for breakpoint decisions, matching the pattern used by `_MethodGrid`.
- **Status**: OPEN

---

### [MEDIUM] Issue 10: `ValidationResult` class is not frozen/sealed

- **Location**: `kayak-frontend/lib/services/method_service.dart`, Lines 92-109
- **Description**: The `ValidationResult` class is a manually-coded data class with hand-written `fromJson`/`toJson`. All other data models in this codebase use `freezed` + `json_annotation` for code generation. This inconsistency introduces manual maintenance burden and potential for serialization bugs.
- **Impact**: If `ValidationResult` gains additional fields, the hand-written serialization logic must be manually updated and tested. Inconsistent with the established project pattern.
- **Recommendation**: Either move `ValidationResult` to `lib/models/` and use `freezed` + `json_serializable` (preferred), or add a comment explaining why freezed was not used here (e.g., "small 2-field response object").
- **Status**: OPEN

---

### [LOW] Issue 11: Missing widget keys for testing

- **Location**: All widgets in both pages
- **Description**: None of the widgets have `Key` parameters. Widget tests for interactive elements (search bar, create button, edit/delete buttons, parameter table rows, JSON editor, save/validate buttons) require keys to be found reliably with `find.byKey()`.
- **Impact**: Makes implementing the required widget tests (per TC-001 through TC-043) more difficult. Test authors will need to use fragile `find.text()` or `find.byType()` selectors.
- **Recommendation**: Add `Key` parameters to interactive widgets:
  - Search TextField: `key: const Key('method-search')`
  - Create/New button: `key: const Key('method-create')`
  - Each method card: `key: Key('method-card-${method.id}')`
  - Edit button on card: `key: Key('method-edit-${method.id}')`
  - Delete button on card: `key: Key('method-delete-${method.id}')`
  - JSON editor: `key: const Key('method-json-editor')`
  - Save button: `key: const Key('method-save')`
  - Validate button: `key: const Key('method-validate')`
  - Parameter table add button: `key: const Key('method-add-param')`
- **Status**: OPEN

---

### [LOW] Issue 12: `_BuildMethodButton` class naming convention

- **Location**: `kayak-frontend/lib/pages/method/method_list_page.dart`, Line 166
- **Description**: The class is named `_BuildMethodButton` which reads as a verb phrase. Flutter widget naming convention uses nouns (e.g., `_CreateMethodButton`, `_MethodCardAction`). The `Build` prefix is atypical for widget names.
- **Impact**: Minor readability issue. Could confuse developers unfamiliar with the codebase.
- **Recommendation**: Rename to `_CreateMethodButton` or `_NewMethodButton` to follow the conventional noun-based widget naming pattern.
- **Status**: OPEN

---

## Architecture Compliance

- [ ] **Follows arch.md** — Partially. Routing and component structure are correct, but l10n requirement from TASK-006 is violated.
- [ ] **Uses defined interfaces** — Yes. Uses `MethodService` via provider, `AsyncValueWidget`, `ErrorView`, `EmptyView`, `ConfirmDialog`, `Toast` as designed.
- [ ] **Proper error handling** — Mostly. Dio error mapping in providers is correct. `FormatException` message leak in `_validateJson` needs fixing.
- [ ] **No code duplication** — Mostly. Error mapping (`_mapError`, `_mapStatusCode`) is duplicated between `MethodListNotifier` and `MethodDetailNotifier` — should be extracted to a shared utility.

## Quality Checks

- [x] **No compiler errors** — `flutter analyze` passes with zero issues
- [x] **No compiler warnings** — Clean
- [x] **No lint warnings** — Clean
- [ ] **Tests pass** — **No tests exist** for TASK-025 code
- [ ] **Documentation updated** — N/A (no new architecture changes)

---

## Approval

- [ ] All issues resolved
- [ ] Code meets standards (l10n required)
- [ ] **NOT APPROVED** — changes required

### Required Fixes Before Merge

1. **CRITICAL**: Implement l10n for all strings (Issue 1)
2. **HIGH**: Fix `DropdownButtonFormField` `initialValue` → `value` (Issue 2)
3. **HIGH**: Add widget tests at minimum covering P0 test cases (Issue 3)
4. **HIGH**: Simplify `_confirmLeave` or fix `ConfirmDialog.show` return type (Issue 4)
5. **HIGH**: Clarify/consolidate `parameter_schema` + `parameters` duplication (Issue 5)
6. **MEDIUM**: Fix `FormatException` message leak (Issue 6)
7. **MEDIUM**: Implement search debounce (Issue 7)
8. **MEDIUM**: Make `_SearchBar` reactive to controller changes (Issue 8)

### Recommended (Can Defer to Subsequent Sprint)

9. **MEDIUM**: Use `LayoutBuilder` consistently (Issue 9)
10. **MEDIUM**: Convert `ValidationResult` to freezed (Issue 10)
11. **LOW**: Add widget keys for testability (Issue 11)
12. **LOW**: Rename `_BuildMethodButton` (Issue 12)

---

> **Next step**: sw-tom to address all Critical and High issues, implement tests, then resubmit for re-review.
