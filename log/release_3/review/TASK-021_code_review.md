# Code Review Report — TASK-021

## Review Information
- **Reviewer**: sw-jerry (Software Architect)
- **Date**: 2026-06-01
- **Branch**: `feature/task-021-experiment-list`
- **Commits Reviewed**: `024886d` → `9b1f650`

## Files Reviewed
| File | Status | Lines |
|------|--------|-------|
| `lib/pages/experiment/experiment_list_page.dart` | Rewritten | 1180 |
| `lib/widgets/status_badge.dart` | New | 285 |
| `lib/providers/experiment_provider.dart` | Modified | +33/-6 |
| `lib/l10n/app_en.arb` | Updated | +177 |
| `lib/l10n/app_zh.arb` | Updated | +177 |

## Summary
- **Status**: 🔴 CHANGES_REQUESTED
- **Total Issues**: 9
- **Critical**: 1
- **High**: 3
- **Medium**: 2
- **Low**: 3

`flutter analyze --fatal-infos` passes: ✅ zero warnings.

---

## Issues Found

### [CRITICAL] Issue 1: StatusBadge hardcodes English text — violates l10n requirement

- **Location**: `lib/widgets/status_badge.dart`, Lines 268–284
- **Description**: The `_statusLabel()` method returns hardcoded English strings (`'Idle'`, `'Loaded'`, `'Running'`, `'Paused'`, `'Completed'`, `'Aborted'`). Since `StatusBadge` is a reusable component displayed in `experiment_list_page.dart` (lines 670, 824), it will always show English text regardless of the user's locale setting.

- **Impact**: This directly violates the TASK-006 requirement that **all user-facing text must go through l10n** (ARB files). A Chinese user will see "Running" instead of "运行中" in the status badge, while every other UI element is properly localized.

- **Recommendation**: Add a `label` parameter to `StatusBadge`:
  ```dart
  const StatusBadge({
    required this.status,
    this.label,  // Optional: override text from l10n
    this.showIcon = true,
    this.showPulse = true,
    this.onTap,
    this.compact = false,
  });

  final String? label;
  ```
  Then in `_statusLabel()`, return `widget.label ?? fallback`. Caller uses l10n:
  ```dart
  StatusBadge(
    status: exp.status,
    label: l10n.statusRunning,  // or _statusText(context, exp.status)
  )
  ```

- **Status**: OPEN

---

### [HIGH] Issue 2: RUNNING card top border uses wrong color (blue instead of green)

- **Location**: `lib/pages/experiment/experiment_list_page.dart`, Lines 794–796
- **Description**: The RUNNING card's top border uses `colorScheme.primary` (which is Blue `#1976D2`), but the UI design spec requires a **green** border:
  - **§2.4 Mobile Card List**: "RUNNING: 顶部 3px 绿色边框 (Success)"
  - **§4.1 响应式适配**: "RUNNING 卡片顶部 3px 绿色边框"
  - **§2.1 StatusBadge**: RUNNING status uses `#2E7D32` (green)

  The table row tint at line 639 correctly uses green (`const Color(0xFF2E7D32)`), but the card border at line 796 uses blue (`colorScheme.primary`). This inconsistency is visually jarring.

- **Impact**: Users will see a blue border on RUNNING experiment cards, breaking the visual language where RUNNING = green. Confusing when the StatusBadge on the same card shows green.

- **Recommendation**: Change line 796 from:
  ```dart
  color: colorScheme.primary,
  ```
  to:
  ```dart
  color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
  ```
  Or extract a shared `_statusColor(status, isDark)` method that the entire page uses consistently.

- **Status**: OPEN

---

### [HIGH] Issue 3: `methodId` (UUID) displayed instead of human-readable method name

- **Location**: `lib/pages/experiment/experiment_list_page.dart`, Lines 662, 832
- **Description**: The code displays `exp.methodId` directly as the "Method" column value. `methodId` is a UUID string (e.g., `"a1b2c3d4-e5f6-7890-abcd-ef1234567890"`). Users cannot understand what method this refers to. The design spec (§2.3 DataTable) shows examples like "拉伸方法", "循环方法" — human-readable names, not UUIDs.

  This was identified as **H2 in the UI design review** (TASK-021_ui_review.md §3.5): "ExperimentResponse 只返回 method_id（UUID），不返回方法名称。"

- **Impact**: All experiments with a method assigned will show an unreadable UUID in the table/card. Very poor UX.

- **Recommendation**: 
  1. **Short-term (recommended)**: Show "Loading..." initially, then batch-fetch method names. The `MethodService.getById()` can be used. Deduplicate `methodId` values and fetch them once per list load.
  2. **Long-term**: Advocate for backend to include `method_name` in `ExperimentResponse` via a JOIN.

  At minimum, add a TODO comment acknowledging the known gap.

- **Status**: OPEN

---

### [HIGH] Issue 4: Mobile card list does not use compact StatusBadge

- **Location**: `lib/pages/experiment/experiment_list_page.dart`, Lines 824
- **Description**: The card list (mobile layout, `<600px`) creates `StatusBadge(status: exp.status)` without `compact: true`. The UI design spec (§2.1 StatusBadge — 响应式) specifies:
  | Mobile (< 600px) | 20px height | 10px text | 6px dot |
  | Tablet/Desktop (> 600px) | 24px height | 12px text | 8px dot |
  
  The `StatusBadge` component already supports `compact: true` (lines 163, 171–172, 200–203), but the call site doesn't use it.

- **Impact**: Status badges on mobile cards are unnecessarily large (24px vs spec 20px), wasting vertical space on small screens.

- **Recommendation**: Change line 824 from:
  ```dart
  StatusBadge(status: exp.status),
  ```
  to:
  ```dart
  StatusBadge(status: exp.status, compact: true),
  ```

- **Status**: OPEN

---

### [MEDIUM] Issue 5: Code duplication — `_formatDateTime` and `_formatDuration`

- **Location**: 
  - `lib/pages/experiment/experiment_list_page.dart`, Lines 712–750 (`_ExperimentDataTable`)
  - `lib/pages/experiment/experiment_list_page.dart`, Lines 898–927 (`_ExperimentCardList`)
- **Description**: Both `_ExperimentDataTable` and `_ExperimentCardList` contain **verbatim copies** of `_formatDateTime()` and `_formatDuration()`. This violates DRY (Don't Repeat Yourself) and makes future changes (e.g., date format updates) require editing in two places.

- **Impact**: Maintenance burden and risk of divergence. If one location's format is updated but not the other, mobile and desktop will show different date/duration formats.

- **Recommendation**: Extract both methods to either:
  1. **Top-level private functions** in the same file (`String _formatDuration(...)` at file scope)
  2. **A shared utility module** if used across multiple pages
  3. **A static `ExperimentFormatting` class**

- **Status**: OPEN

---

### [MEDIUM] Issue 6: `durationFormat` l10n key defined but unused

- **Location**: `lib/l10n/app_en.arb` / `app_zh.arb` (defined), `experiment_list_page.dart` (not used)
- **Description**: The design doc (§6.1) defines a `durationFormat` i18n key:
  - EN: `"{h}h {m}m {s}s"`
  - ZH: `"{h}小时{m}分{s}秒"`
  But the code at lines 743–749 and 921–927 uses hardcoded `HH:mm:ss` format (`"00:00:00"`). The l10n key exists in the ARB files but is never consumed.

- **Impact**: Duration is always displayed in `HH:mm:ss` format regardless of locale. While this is internationally understood, it misses the opportunity for localized natural-language duration formatting.

- **Recommendation**: Change duration rendering to use the `l10n.durationFormat(h, m, s)` key. For long durations (> 1 hour), show natural language ("2h 15m 30s" / "2小时15分30秒"). For short durations (< 1 hour), `mm:ss` format is still acceptable.

- **Status**: OPEN

---

### [LOW] Issue 7: filterDateRange ARB label shortened from design spec

- **Location**: `lib/l10n/app_en.arb`: `"filterDateRange": "Date"`, `app_zh.arb`: `"filterDateRange": "时间"`
- **Description**: The design doc §6.1 specifies `filterDateRange` as "Date Range" (EN) and "时间范围" (ZH). The ARB has "Date" and "时间" — the "Range" / "范围" suffix is missing. This makes the label ambiguous — a user scanning the label won't immediately understand it's a date *range* picker.

- **Impact**: Minor — the two date fields with a `~` separator convey the range intent visually. But the label is slightly less clear than spec.

- **Recommendation**: Update ARB files:
  - EN: `"filterDateRange": "Date Range"`
  - ZH: `"filterDateRange": "时间范围"`
  Re-run `flutter gen-l10n`.

- **Status**: OPEN

---

### [LOW] Issue 8: Redundant double-rebuild on filter change

- **Location**: `lib/pages/experiment/experiment_list_page.dart`, Lines 113–115 (and similar filter handlers)
- **Description**: When a filter changes, two rebuilds are triggered:
  1. `setState(() => _statusFilter = status)` — rebuilds the local widget tree
  2. `_applyFilter(notifier)` → `notifier.setFilter(...)` — triggers provider state change → rebuilds watchers
  
  The first `setState` rebuild is unnecessary because the widget tree doesn't depend on `_statusFilter` directly — it's only passed to the notifier via `_applyFilter`. The actual list rendering depends on `ref.watch(experimentListProvider)`, which is driven by the notifier.

- **Impact**: Performance — one extra widget rebuild per filter change. Not noticeable in practice (lists are < 50 items).

- **Recommendation**: Remove the `setState` calls from filter change handlers. The UI will rebuild when the provider state updates. Keep `setState` only for truly local state like `_pageSize`.

  ```dart
  onStatusChanged: (status) {
    _statusFilter = status;  // No setState needed — list is driven by notifier
    _applyFilter(notifier);
  },
  ```
  This requires `_hasActiveFilter` to derive from the notifier's filter state instead of local variables.

- **Status**: OPEN

---

### [LOW] Issue 9: Toast potentially shows raw exception message

- **Location**: `lib/pages/experiment/experiment_list_page.dart`, Line 282
- **Description**: When the stop operation fails, the code calls `l10n.stopFailed(e.toString())`. This passes the raw Dart exception's `toString()` to the user. For unexpected errors (e.g., a `StateError` or `DioException` that wasn't handled), the user might see technical exception details like stack traces or internal error names.

- **Impact**: Low — the `ExperimentListNotifier._mapError()` and `ExperimentControlNotifier._mapError()` already convert most DioExceptions to user-friendly Chinese messages. However, cases that bypass `_mapError` (e.g., `StateError` with raw message) could leak technical details.

- **Recommendation**: Add a top-level `catch` in `_handleStop` that provides a generic fallback:
  ```dart
  } catch (e) {
    if (mounted) {
      Toast.show(
        context: context,
        message: e is DioException || e is StateError
            ? l10n.stopFailed(e.toString())
            : l10n.stopFailed(l10n.unknownError),  // fallback
        type: ToastType.error,
      );
    }
  }
  ```

- **Status**: OPEN

---

## Architecture Compliance

| Check | Status | Notes |
|-------|--------|-------|
| Follows arch.md | ✅ | Correct use of Riverpod 3.x, go_router, Material 3 |
| Uses defined interfaces | ✅ | `ExperimentListNotifier`, `ExperimentControlNotifier` via providers |
| Proper error handling | ⚠️ | Three-state (loading/error/data) is complete. Toast error feedback for stop operation is present. See Issue 9 for raw exception concern. |
| No code duplication | ❌ | Issue 5 — `_formatDateTime`/`_formatDuration` duplicated |
| l10n compliance | ❌ | Issue 1 — StatusBadge hardcodes English. Issue 6 — l10n key unused. Issue 7 — ARB label mismatch. |

## Design Compliance Checklist

| Design Requirement | Status | Reference |
|-------------------|--------|-----------|
| Status filter: DropdownButton (single select) | ✅ | §2.2.2, UI review B1 correction applied |
| Date range picker | ✅ | §2.2.2 |
| 6-column DataTable (Desktop) | ✅ | §2.3 |
| Card list (Mobile < 600px) | ⚠️ | §2.4 — RUNNING card border wrong color (Issue 2), compact badge missing (Issue 4) |
| RUNNING StatusBadge pulse animation | ✅ | StatusBadge._initPulseAnimation |
| prefers-reduced-motion respected | ✅ | `_shouldAnimate` checks `disableAnimations` |
| Pagination bar with page numbers | ✅ | `_PaginationBar` |
| Empty state: "No experiments yet" + create button | ✅ | `_buildEmptyView` |
| Filtered empty state: "No matching" + clear filter | ✅ | `_buildEmptyView` with `_hasActiveFilter` check |
| Error state: ErrorView + retry | ✅ | `_buildErrorView` |
| Loading state: Skeleton | ✅ | `_buildSkeleton` |
| Screen width breakpoint: MediaQuery (not LayoutBuilder) | ✅ | Uses `MediaQuery.of(context).size.width` — follows UI review H1 recommendation |
| Context menu / more actions | ⚠️ | Not implemented — not in design spec v1 |
| Method name displayed (not UUID) | ❌ | Issue 3 |
| Duration localization | ❌ | Issue 6 |
| StatusBadge localization | ❌ | Issue 1 |

## Quality Checks

| Check | Result |
|-------|--------|
| No compiler errors | ✅ |
| No analyzer warnings (`flutter analyze --fatal-infos`) | ✅ |
| No lint warnings | ✅ |
| Tests pass | N/A (no test diff for these specific files seen — TASK-021 test cases exist as spec) |
| Documentation updated | ✅ (design document done) |

## Strengths

1. **Clean three-state handling**: Loading/Error/Empty/Data states are thoroughly covered using `AsyncValue.when()`.
2. **Responsive layout**: Proper use of `MediaQuery.of(context).size.width` for breakpoint detection (600px), following the UI review H1 recommendation to decouple from AppShell's LayoutBuilder.
3. **Filtered vs unfiltered empty states**: The distinction between "no experiments at all" and "no matching filter results" is a nice UX touch.
4. **Pagination with ellipsis logic**: `_PaginationBar._buildPageNumbers()` correctly handles truncation with `...` for large page counts.
5. **StatusBadge animation respects accessibility**: `_shouldAnimate` checks `disableAnimations` and `accessibleNavigation` before running the pulse animation.
6. **Proper controller disposal**: `_startDateController` and `_endDateController` are properly disposed in the State's `dispose()`.
7. **Provider extension**: `goToPage()` and `setPageSize()` methods were correctly added to `ExperimentListNotifier` to support pagination UI.

## Approval

- [ ] All Critical issues resolved
- [ ] All High issues resolved or explicitly deferred with rationale
- [ ] Medium/Low issues addressed or acknowledged for future iteration
- [ ] Approved for merge

---

## Resolution Tracking

| Issue | Severity | Resolution | Verifier |
|-------|----------|------------|----------|
| 1: StatusBadge hardcoded text | Critical | | |
| 2: RUNNING card border color | High | | |
| 3: methodId displayed as name | High | | |
| 4: Compact badge on mobile | High | | |
| 5: Code duplication | Medium | | |
| 6: durationFormat unused | Medium | | |
| 7: filterDateRange label | Low | | |
| 8: Double rebuild | Low | | |
| 9: Raw exception in toast | Low | | |

---

*Review completed 2026-06-01 by sw-jerry*
