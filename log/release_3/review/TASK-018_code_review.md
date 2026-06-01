# Code Review Report — TASK-018

## Review Information
- **Reviewer**: sw-jerry
- **Date**: 2026-06-01
- **Branch**: `feature/task-018-point-management`
- **Commits Reviewed**: 19e6834, c7c523d, 99c606e, 79b37c7, effc643, e88a9eb, 06ed30e
- **Reference Docs**:
  - Detailed Design: `log/release_3/design/TASK-018_design.md` (v1.1)
  - UI Spec: `log/release_3/ui/specifications/point_list_spec.md`
  - Figma: `log/release_3/ui/figma/TASK-018_point_management.txt`
  - Test Cases: `log/release_3/test/TASK-018_test_cases.md`

## Summary
- **Status**: **NEEDS_FIX**
- **Total Issues**: 11
- **Critical**: 2
- **High**: 5
- **Medium**: 3
- **Low**: 1

---

## Issues Found

### [CRITICAL] Issue 1: Hardcoded English Strings — Violates i18n Requirement

**Location**: 
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Line 420
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Line 483
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Line 505
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Line 515 (hint)
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Line 622 (hint)
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Line 443 (`helperText`)

**Description**: Multiple hardcoded English strings exist in `PointFormDialog`, violating the strict "no hardcoded strings" rule and the i18n requirement (PRD §9, TC-WD-003). These are NOT just decorative — they are user-facing text that must be translated.

**Hardcoded strings found**:
| Line | Current Value | Should Be |
|------|--------------|-----------|
| 420 | `tooltip: 'Close'` | Add new l10n key `close` or `dialogClose` (or reuse existing `cancel`) |
| 483 | `return 'Required';` | Needs a new l10n key like `fieldRequired` |
| 505 | `return 'Required';` | Same as above |
| 515 | `hintText: '°C'` | Skip — this is a unit symbol, not language-specific. Acceptable but consider a l10n key `unitHint` if needed. |
| 622 | `hintText: '0-65535'` | This is a range hint — acceptable as a placeholder pattern, but consider extracting to l10n for consistency. |

**Impact**: When locale is set to Chinese, these strings remain in English, breaking the user experience. TC-WD-003 explicitly requires "无硬编码中文字符串" and "无硬编码英文占位符". 

**Recommendation**: Add l10n keys `fieldRequired` (and optionally `dialogClose`) to both `app_en.arb` and `app_zh.arb`. Replace all `'Required'` and `'Close'` strings with their l10n equivalents.

**Status**: OPEN

---

### [CRITICAL] Issue 2: Skeleton Blocks Lack Shimmer Animation

**Location**: 
- `kayak-frontend/lib/pages/point/point_list_widget.dart`, Lines 278–293 (`_skeletonBlock`)
- `kayak-frontend/lib/pages/point/point_value_display.dart`, Lines 282–314 (`_buildSkeleton`)

**Description**: The skeleton loading screens use **static colored containers** (`Container` with `colorScheme.surfaceContainerHighest.withAlpha(128)`) instead of **animated shimmer placeholders** as required by:

- **Design Spec §3.8**: "脉冲动画 (shimmer)" for the 5-row table skeleton
- **Design Spec §5.5**: "shimmer 动画" for the value display skeleton
- **Figma Screen 3**: Loading state with shimmer animation visual specification
- **Design Document §6.1 Step 1**: "SkeletonTable（5 行 × 6 列 shimmer）"
- **Design Document Appendix B-1 (B-01/S-03)**: Explicitly calls for "shimmer 动画逻辑" with reused infrastructure from `widgets/skeleton.dart`
- **TC-PL-001**: "脉冲动画占位行（Skeleton 风格）"
- **TC-PV-007**: "骨架占位（灰色脉冲矩形）"

**Impact**: Loading states appear as flat, lifeless colored rectangles with no visual indicator that content is actively loading. Users may perceive this as a rendering bug rather than a loading state. This is a **significant visual quality regression** from the design specification.

**Recommendation**: 
1. Extract the shimmer animation logic from `lib/widgets/skeleton.dart` into a reusable `ShimmerContainer` or `ShimmerBlock` widget (or create a shared shimmer builder).
2. Replace all `_skeletonBlock` calls with shimmer-animated equivalents. Options:
   - Use `Shimmer.fromColors()` from the `shimmer` package (if already a dependency)
   - Use `AnimatedContainer` with a periodic `Timer` to toggle between two surface colors
   - Create a custom `ShimmerBox` that wraps the existing skeleton blocks

**Status**: OPEN

---

### [HIGH] Issue 3: Table Type Chip Labels are Hardcoded English

**Location**: `kayak-frontend/lib/pages/point/point_list_widget.dart`, Lines 695–706 (`_dataTypeLabel`)

**Description**: The `_dataTypeLabel` method returns hardcoded English strings (`'Number'`, `'Integer'`, `'Boolean'`, `'String'`) for the TypeChip labels in the table. These are user-facing UI labels and should be localized.

**Impact**: In Chinese locale, type chips still show "Number" instead of "浮点数". TC-WD-003 explicitly requires all visible text to come from l10n.

**Recommendation**: Replace the hardcoded `_dataTypeLabel` implementation with l10n lookups using the already-defined `dataTypeNumber`, `dataTypeInteger`, `dataTypeBoolean`, `dataTypeString` keys. Note that the chip labels may benefit from shorter variants (e.g., "Num", "Int", "Bool", "Str") to fit the 80px column width — consider adding `pointDataTypeShort` keys if needed.

**Status**: OPEN

---

### [HIGH] Issue 4: Fragile New Point ID Inference for Modbus Config Saving

**Location**: `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Lines 301–308

**Description**: After `createPoint()` succeeds, the implementation reads the state and takes `.lastOrNull` to find the newly created point ID:

```dart
final currentPoints = ref.read(pointListProvider(widget.deviceId));
final newPoint = currentPoints.value?.lastOrNull;
if (newPoint != null) {
  await _saveModbusConfig(newPoint.id);
}
```

This relies on two unreliable assumptions:
1. **Ordering not guaranteed**: The backend API does not guarantee the new point will be the **last** item in the list (depends on SQL `ORDER BY` which may not be chronological).
2. **`createPoint()` returns `Future<void>`**: The Design Document §2.3 shows `createPoint` should have a return value, but the current `PointListNotifier.createPoint` returns `void`, forcing this workaround.

**Impact**: If the wrong point ID is inferred, Modbus configuration is saved under the wrong point's ID in `protocol_params`, causing data corruption and silent misconfiguration.

**Recommendation**: 
- **Preferred**: Modify `PointListNotifier.createPoint()` to return the created `Point` object (i.e., `Future<Point> createPoint(...)`), then use the returned ID directly. This matches the Design Document's recommended pattern (Appendix C-1, Step 1: `final newPoint = await ...createPoint(...)`).
- **Alternative (short-term)**: Keep the returned Point from `PointService.create()` and find it by name match, or pass the created point ID through a callback/Completer.

**Status**: OPEN

---

### [HIGH] Issue 5: Toast Displayed from Potentially Invalid Context After ConfirmDialog Pop

**Location**: `kayak-frontend/lib/pages/point/point_list_widget.dart`, Lines 66–86

**Description**: The `_handleDeletePoint` method's `onConfirm` callback is invoked inside `ConfirmDialog`'s build method like this:

```dart
// ConfirmDialog line 221-223:
onPressed: () {
  onConfirm();          // starts async delete operation
  Navigator.of(context).pop();   // dismisses dialog immediately
}
```

The `onConfirm` callback in `PointListWidget` runs an async delete operation and then shows a Toast:
```dart
onConfirm: () async {
  try {
    await ref.read(...).deletePoint(point.id);
    if (!mounted) return;
    Toast.show(context: context, ...);   // ← context is from _buildContent's build
  } catch (e) {
    if (!mounted) return;
    Toast.show(context: context, ...);   // ← same issue
  }
}
```

The `context` used for `Toast.show` is the `_PointListWidgetState`'s build context, which is **not** the dialog context. This should be safe because the widget's build context remains valid (the dialog pop doesn't affect the parent). 

However, the real concern is: the `ConfirmDialog` calls `onConfirm()` and **immediately** calls `Navigator.pop()`. The async `deletePoint` call starts, then `pop()` fires, dismisses the dialog, and when `deletePoint` completes, the Toast shows. This is technically correct but the `ConfirmDialog` contract (its `show` method signature) takes `VoidCallback` — not `Future<void> Function()`. The dialog is designed to close synchronously, so the async fire-and-forget pattern is intentional.

**Verdict**: This is actually safe given the `ConfirmDialog` design. However, the `mounted` check at line 71/78 ensures the widget is still in the tree, and since the Toast uses the parent widget's context (not the dialog's), it should work. **Downgrading this to LOW/INFO — no fix needed**, but keeping for documentation.

Wait — actually, re-reading the code, the `context` in `_handleDeletePoint` is captured from `build()`:
```dart
final l10n = AppLocalizations.of(context)!;
```
This `context` is the `_PointListWidgetState`'s build context, which is correct and stays valid even after the dialog is dismissed. No issue here.

**Revised**: This is not a real issue. The Toast context is correct. Marking as resolved.

**Status**: RETRACTED

---

### [HIGH] Issue 6: Error Messages in `_mapError` are Hardcoded Chinese

**Location**: `kayak-frontend/lib/providers/point_provider.dart`, Lines 162–204

**Description**: The `_mapError` method in `PointListNotifier` returns hardcoded Chinese strings for all error cases:

| Line | Current |
|------|---------|
| 168 | `'网络连接失败，请检查网络后重试'` |
| 175 | `'网络异常，请稍后重试'` |
| 186 | `'请求参数有误，请检查输入'` |
| 188–202 | 7 more hardcoded Chinese messages |

**Impact**: When locale is English, error messages display in Chinese. While providers cannot directly access `AppLocalizations` (they need `BuildContext`), this is a known architectural challenge with Riverpod notifiers. 

**Recommendation**: Two approaches (choose one):
1. **Return error codes**: Have `_mapError` return an error code string (e.g., `'network_error'`, `'unauthorized'`), and let the UI layer map these to l10n strings.
2. **L10n injection**: Pass `AppLocalizations` into the notifier method calls (e.g., `deletePoint(pointId, l10n)`), though this tightens coupling.

Note: This issue exists in other providers too (e.g., Workbench) and is not unique to this task. Consider addressing it holistically in a separate refactoring task rather than blocking this PR.

**Status**: OPEN (consider deferring to a separate i18n task for providers)

---

### [HIGH] Issue 7: Edit Mode Save Button Always Enabled — No Change Detection

**Location**: `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Lines 266–267, `_handleSave`

**Description**: The design specification §4.6 "保存按钮状态" and test case TC-PF-010 require that in edit mode:
- **Save button should be disabled when no changes have been made** ("数据未改变" → 禁用)

Currently, the save button's enabled state is controlled only by `_isSaving`:
```dart
onPressed: _isSaving ? null : _handleSave,
```

The `_handleSave` method calls `_formKey.currentState!.validate()`, which only checks field validity — NOT whether any values were actually modified from their initial state.

**Impact**: TC-PF-010's expected result ("保存按钮初始为禁用状态（数据未改变）") cannot be satisfied. Users can click Save even when no modifications were made, triggering unnecessary API calls.

**Recommendation**: Implement dirty-checking in edit mode:
1. Store initial form values in `initState` (already done via `TextEditingController` initialization)
2. Add a `_isDirty` getter that compares current field values against initial values
3. Use `_isDirty && !_isSaving` as the enable condition for the save button

**Status**: OPEN

---

### [MEDIUM] Issue 8: `point_form_dialog.dart` — `_buildHeader` Close Button Uses Hardcoded `'Close'`

**Location**: `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Line 420

**Description**: The close button in the dialog header has `tooltip: 'Close'` — a hardcoded English string. This is a subset of Issue 1 but called out separately because it is user-accessible (screen reader) and doesn't use the existing `l10n.cancel` key.

**Impact**: Screen reader users in Chinese locale hear "Close" instead of "关闭" or "取消".

**Recommendation**: Replace with `tooltip: l10n.cancel` or add a dedicated `dialogClose` l10n key.

**Status**: OPEN (fix alongside Issue 1)

---

### [MEDIUM] Issue 9: Inconsistent Use of `DropdownButtonFormField.initialValue`

**Location**: 
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Lines 467–486 (DataType)
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Lines 489–508 (AccessType)
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Lines 600–615 (RegisterType)
- `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Lines 639–654 (DataFormat)

**Description**: All `DropdownButtonFormField` instances use the `initialValue` parameter but do NOT set the `value` parameter. In Flutter's `DropdownButtonFormField<T>` (which extends `FormField<T>`):
- `initialValue` sets the form field's initial state (used by `FormField` for reset/dirty tracking)
- `value` controls which item is currently displayed/selected in the dropdown

The analyzer passed (0 issues), which means `initialValue` is a valid inherited parameter from `FormField`. However, exclusively using `initialValue` without `value` may cause the dropdown to not sync with external state changes (e.g., when `_selectedDataType` changes via `setState`). The current state is tracked via `_selectedDataType`/`_selectedAccessType` which works because of the `ValueKey` forcing rebuilds, but this is fragile.

**Recommendation**: Use BOTH `value` (to control display) and `initialValue` (for form state) as the Flutter convention expects:
```dart
DropdownButtonFormField<DataType>(
  value: _selectedDataType,
  initialValue: _selectedDataType,
  ...
)
```

**Status**: OPEN

---

### [MEDIUM] Issue 10: `point_list_widget.dart` — Widget Type Design Deviation

**Location**: `kayak-frontend/lib/pages/point/point_list_widget.dart`, Lines 27–35

**Description**: The Design Document §2.2 explicitly specifies:
```dart
class PointListWidget extends ConsumerWidget {
```

But the implementation uses:
```dart
class PointListWidget extends ConsumerStatefulWidget {
```

The `_PointListWidgetState` does not hold any mutable state that requires `ConsumerStatefulWidget` — all methods (`_handleAddPoint`, `_handleEditPoint`, `_handleDeletePoint`) access `context` and `ref` directly and do not call `setState`. A `ConsumerWidget` would suffice and aligns with the design.

**Impact**: Minor design deviation. The stateful widget adds unnecessary lifecycle overhead (initState, dispose) with no benefit. Does not affect functionality.

**Recommendation**: Change to `ConsumerWidget` and move the handler methods as local functions inside `build()`, or convert to private methods with `Ref` and `BuildContext` parameters.

**Status**: OPEN (optional — can be deferred)

---

### [LOW] Issue 11: `Toast.show` Called Before `Navigator.pop()` in Success Path

**Location**: `kayak-frontend/lib/pages/point/point_form_dialog.dart`, Lines 312–317

**Description**: In `_handleSave`, on success:
```dart
if (!mounted) return;
Navigator.of(context).pop();       // line 312: dismiss dialog first
Toast.show(                         // line 313: then show toast
  context: context,
  ...
);
```

The `Toast.show` uses the dialog's context after `pop()`. In practice, Flutter's route removal is asynchronous (happens at the end of the frame), so the `Overlay` is still accessible. However, this is an anti-pattern — the recommended order is:
1. Show Toast first (while dialog is still in tree)
2. Then dismiss dialog

Or, use `.pop(true)` and handle the Toast in the caller.

**Impact**: Low risk in current Flutter behavior, but could break in future Flutter versions if route disposal becomes more eager.

**Recommendation**: Swap the order: show Toast first, then `Navigator.pop()`. Or return a result from the dialog and show the Toast in the calling method.

**Status**: OPEN (optional — very low risk)

---

## Architecture Compliance

| Check | Status | Notes |
|-------|:------:|-------|
| Follows Riverpod 3.x AsyncNotifier pattern | ✅ | `PointListNotifier extends AsyncNotifier<List<Point>>` with `build()`. `pointValueProvider` uses `FutureProvider.family`. |
| Data flow: Backend → Service → Provider → Widget | ✅ | Clean unidirectional flow: `PointService` ↔ `PointListNotifier` ↔ `PointListWidget` |
| Uses existing reusable components | ✅ | `ConfirmDialog`, `EmptyView`, `ErrorView`, `Toast` all properly used |
| PointFormDialog pattern matches DeviceConfigDialog | ✅ | Both use `static show()` with responsive check (`<600px` → BottomSheet, `≥600px` → AlertDialog) |
| Point deletion goes through Provider layer | ✅ | `deletePoint()` on `PointListNotifier` called from widget |
| All user-facing text uses l10n | ❌ | See Issues 1, 3, 6, 8 — multiple hardcoded strings |
| `mounted` checks after async operations | ✅ | All async paths have proper `mounted` guards |
| Three-state handling (loading/error/empty/data) | ✅ | `when(loading:, error:, data:)` correctly implemented |
| Responsive layout (desktop table / mobile cards) | ✅ | `LayoutBuilder` with `<600` breakpoint for card layout |
| Modbus fields conditionally displayed | ✅ | `_checkDeviceProtocol()` correctly checks `ProtocolType.modbusTcp` / `modbusRtu` |
| Skeleton loading has shimmer animation | ❌ | See Issue 2 — static containers, no animation |
| Desktop table uses hover effect (On Surface 4%) | ✅ | `InkWell` with `colorScheme.onSurface.withAlpha(10)` |
| 100+ point scroll performance via `ListView.builder` | ✅ | `ListView.builder` used in table data rows |

## Quality Checks

| Check | Status | Notes |
|-------|:------:|-------|
| No compiler errors | ✅ | `flutter analyze` passes with 0 issues |
| No compiler warnings | ✅ | Clean |
| No lint warnings | ✅ | Clean |
| Tests written | N/A | TASK-018 test cases exist in `log/release_3/test/TASK-018_test_cases.md` — execution by sw-mike pending |
| Documentation updated | ✅ | Detailed design document complete |
| Code matches design document | ⚠️ | Minor deviations: widget type (Issue 10), save button change detection (Issue 7) |
| Code matches UI spec | ⚠️ | No shimmer animation (Issue 2), missing button disabled states (Issue 7) |
| No code duplication | ✅ | Components properly extracted and reused |
| Proper error handling | ⚠️ | Provider error messages are hardcoded Chinese (Issue 6) |
| l10n keys match both ARB files | ✅ | All 48 keys present in both `app_en.arb` and `app_zh.arb` with matching `@placeholders` |
| Dark theme colors correct | ✅ | All color references use `colorScheme.*`, no hardcoded colors |

## File-by-File Verdict

### New Files

| File | Verdict | Notes |
|------|:-------:|-------|
| `lib/pages/point/point_list_widget.dart` | ⚠️ Fix Required | No shimmer (Issue 2), hardcoded type labels (Issue 3), widget type deviation (Issue 10) |
| `lib/pages/point/point_form_dialog.dart` | ❌ Fix Required | Multiple hardcoded strings (Issues 1, 8), fragile point ID inference (Issue 4), no change detection (Issue 7), DropdownButtonFormField (Issue 9), pop-before-toast (Issue 11) |
| `lib/pages/point/point_value_display.dart` | ⚠️ Fix Required | No shimmer on skeleton (Issue 2) |

### Modified Files

| File | Verdict | Notes |
|------|:-------:|-------|
| `lib/pages/workbench/workbench_detail_page.dart` | ✅ Good | Clean integration of `PointListWidget`. Removed old `_PointListSection`/`_PointListItem` classes. Correctly uses `l10n.pointListTitle`. |
| `lib/providers/point_provider.dart` | ⚠️ Fix Required | `updatePoint()` implementation correct. `createPoint()` returns `void` (Issue 4). Hardcoded Chinese error messages (Issue 6). |
| `lib/l10n/app_en.arb` | ✅ Good | All 48 keys present, correct `@placeholders` for `pointCount` and `pointDeleteConfirm`. |
| `lib/l10n/app_zh.arb` | ✅ Good | All 48 keys present with accurate Chinese translations. |

## Approval

- [ ] All Critical issues resolved
- [ ] All High issues resolved
- [ ] Medium issues triaged (fix or defer)
- [ ] Code meets quality standards
- [ ] **NOT Approved for merge — NEEDS_FIX**

---

## Fix Priority Summary

### Must Fix Before Merge (Blocking)

1. **[CRITICAL] Issue 1**: Replace all hardcoded English strings in `point_form_dialog.dart` with l10n keys
2. **[CRITICAL] Issue 2**: Add shimmer animation to skeleton blocks in `point_list_widget.dart` and `point_value_display.dart`
3. **[HIGH] Issue 3**: Localize `_dataTypeLabel` type chip labels using l10n
4. **[HIGH] Issue 4**: Fix fragile new-point ID inference for Modbus config saving (return Point from `createPoint`)

### Should Fix Before Merge (Strongly Recommended)

5. **[HIGH] Issue 7**: Implement save button change-detection in edit mode
6. **[HIGH] Issue 6**: Address hardcoded Chinese in provider error messages (or defer to separate task)
7. **[MEDIUM] Issue 8**: Use l10n for close button tooltip

### Can Defer

8. **[MEDIUM] Issue 9**: Add explicit `value` parameter alongside `initialValue` in DropdownButtonFormField
9. **[MEDIUM] Issue 10**: Change `PointListWidget` from `ConsumerStatefulWidget` to `ConsumerWidget`
10. **[LOW] Issue 11**: Swap Toast-before-pop order in `_handleSave`

---

## Overall Assessment

The implementation is **structurally sound** — the architecture follows Riverpod 3.x patterns correctly, data flow is unidirectional, existing reusable components are well utilized, and the code compiles cleanly with zero analyzer warnings. The 48 l10n keys are complete and consistent across both locale files.

However, several **quality and compliance issues** prevent approval:

1. **Hardcoded strings** (Issues 1, 3, 8) violate the zero-hardcoded-strings policy and would break i18n in practice — users would see untranslated English in a Chinese UI.

2. **Missing shimmer animation** (Issue 2) is a significant visual quality regression from the design specification. Static skeleton blocks mislead users about the loading state.

3. **Fragile point ID inference** (Issue 4) creates a real risk of data corruption when saving Modbus configurations for newly created points.

These issues are well-scoped and should take approximately 2–4 hours to resolve across all files.

---

## 终审结论

**审查人**: sw-jerry
**日期**: 2026-06-01
**结论**: ✅ **APPROVED** — 全部 11 个 issues 已关闭 (其中 1 个 reviews 时已撤回，9 个已修复，1 个延后)

| 严重等级 | 总数 | 已关闭 | 已撤回 | 延后 | 未关闭 |
|:-------:|:---:|:-----:|:-----:|:---:|:-----:|
| Critical | 2 | 2 | 0 | 0 | 0 |
| High | 5 | 4 | 1 | 0 | 0 |
| Medium | 3 | 1 | 0 | 2 | 0 |
| Low | 1 | 1 | 0 | 0 | 0 |

### 逐项验证

| Issue | 严重等级 | 原分类 | 状态 | 验证说明 |
|:-----:|:-------:|:------:|:----:|:---------|
| 1 — Hardcoded English Strings | Critical | Must Fix | ✅ FIXED | `tooltip: 'Close'` → `l10n.cancel`；`'Required'` → `l10n.fieldRequired` / `l10n.pointNameRequired`；单元符号 `'°C'` 和范围提示 `'0-65535'` 保留（审查确认可接受） |
| 2 — No Shimmer Animation | Critical | Must Fix | ✅ FIXED | `point_list_widget.dart` 和 `point_value_display.dart` 均引入 `ShimmerBlock` + `ShimmerContainer` + `AnimatedBuilder`——复用 `skeleton.dart` 中的共享 shimmer 基础设施 |
| 3 — Type Chip Labels Hardcoded | High | Must Fix | ✅ FIXED | `_dataTypeLabel` 新增 `l10n` 参数，使用 `l10n.dataTypeNumber` 等键 |
| 4 — Fragile Point ID Inference | High | Must Fix | ✅ FIXED | `createPoint()` 返回类型改为 `Future<Point>`；调用处使用 `final newPoint = await notifier.createPoint(...)` 并直接引用 `newPoint.id` |
| 5 — Toast Context After Pop | High | RETRACTED | ✅ RETRACTED | 审查时已撤回——父 widget 的 `context` 在对话框消失后仍然有效 |
| 6 — Provider Hardcoded Chinese | High | Should Fix | ✅ FIXED | `_mapError` 改为返回错误代码（如 `'error.network'`）；新增 `resolveErrorCode()` 函数在 UI 层映射至 l10n |
| 7 — No Change Detection | High | Should Fix | ✅ FIXED | 新增 `_isDirty` getter 比较当前值/初始值；保存按钮启用条件：`(_isSaving \|\| !_isDirty) ? null : _handleSave` |
| 8 — Close Button Tooltip | Medium | Should Fix | ✅ FIXED | 已合并至 Issue 1 修复（`tooltip: l10n.cancel`） |
| 9 — DropdownButtonFormField `value` | Medium | Can Defer | ⏸️ DEFERRED | 仅使用 `initialValue` 未同步添加 `value` 参数——当前代码通过 `ValueKey` 强制重建，功能正确。低风险，可后续优化 |
| 10 — Widget 类型偏差 | Medium | Can Defer | ✅ RESOLVED | Issue 2 的 shimmer 修复需要 `SingleTickerProviderStateMixin`（用于 `_shimmerController`），故 `ConsumerStatefulWidget` 现已为必要。审查建议已过时 |
| 11 — Toast-before-pop 顺序 | Low | Can Defer | ✅ FIXED | `_handleSave` 中：先 `Toast.show`，后 `Navigator.pop()` |

### 验证方法

```
cd kayak-frontend && flutter analyze --fatal-infos
```
**结果**：`No issues found!` — 零警告、零错误。

### 关键修复验证通过
- **硬编码字符串**：三个文件（point_form_dialog、point_list_widget、point_provider）中所有用户可见字符串现已通过 l10n 管道处理
- **Shimmer 动画**：骨架屏现使用 `ShaderMask` + `LinearGradient` shimmer 效果，与现有 `widgets/skeleton.dart` 组件一致
- **变更检测**：编辑模式下保存按钮初始禁用（`!_isDirty` → `null`），仅在有未保存变更时启用

### 技术债务备注
- Issue 9（`DropdownButtonFormField.value`）：延后至后续 refactoring 任务——当前功能正确且风险极低
- Error code 映射模式（Issue 6）：后续应统一推广至所有 Provider（Workbench 等），已实现为可复用模式
