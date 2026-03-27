# S2-016 Test Cases: 全局UI组件库

**Created**: 2026-03-26
**Task**: S2-016 全局UI组件库
**Status**: Ready for Testing

---

## Test Scope

Test global UI component library:
- Loading indicator components
- Toast/Snackbar notifications
- Confirmation dialogs
- Form input components
- Data table component

---

## Test Cases

### TC-S2-016-01: LoadingOverlay Component

**Description**: Verify LoadingOverlay displays correctly when loading

**Preconditions**: None

**Test Steps**:
1. Create widget with LoadingOverlay showing isLoading=true
2. Verify overlay covers child content
3. Verify CircularProgressIndicator is displayed
4. Change isLoading to false
5. Verify overlay disappears

**Expected Result**: Loading overlay appears/disappears based on isLoading state

---

### TC-S2-016-02: EmptyState Component

**Description**: Verify EmptyState displays with icon, title, and optional elements

**Preconditions**: None

**Test Steps**:
1. Create EmptyState with icon, title, description, and action
2. Verify icon is displayed
3. Verify title is displayed
4. Verify description is displayed
5. Verify action button is displayed

**Expected Result**: EmptyState displays all provided elements correctly

---

### TC-S2-016-03: ErrorState Component with Retry

**Description**: Verify ErrorState displays with retry button

**Preconditions**: None

**Test Steps**:
1. Create ErrorState with message and onRetry callback
2. Verify error icon is displayed
3. Verify message is displayed
4. Click retry button
5. Verify callback is called

**Expected Result**: ErrorState displays correctly and retry button works

---

### TC-S2-016-04: Toast.showSuccess

**Description**: Verify Toast.showSuccess displays success snackbar

**Preconditions**: None

**Test Steps**:
1. Call Toast.showSuccess with title and message
2. Verify snackbar appears
3. Verify success icon (check_circle_outline) is shown
4. Verify green color scheme

**Expected Result**: Success snackbar displays with correct styling

---

### TC-S2-016-05: Toast.showError

**Description**: Verify Toast.showError displays error snackbar

**Preconditions**: None

**Test Steps**:
1. Call Toast.showError with title and message
2. Verify snackbar appears
3. Verify error icon (error_outline) is shown
4. Verify red color scheme

**Expected Result**: Error snackbar displays with correct styling

---

### TC-S2-016-06: ConfirmationDialog

**Description**: Verify ConfirmationDialog displays with custom buttons

**Preconditions**: MaterialApp wrapping

**Test Steps**:
1. Call ConfirmationDialog.show with custom labels
2. Verify title and message are displayed
3. Verify custom confirm and cancel buttons
4. Click cancel and verify dialog returns false
5. Show dialog again and click confirm
6. Verify dialog returns true

**Expected Result**: Dialog returns correct value based on button clicked

---

### TC-S2-016-07: DeleteConfirmationDialog

**Description**: Verify DeleteConfirmationDialog with dangerous styling

**Preconditions**: MaterialApp wrapping

**Test Steps**:
1. Call DeleteConfirmationDialog.show
2. Verify dangerous styling (red confirm button)
3. Verify delete icon is shown
4. Verify warning message format

**Expected Result**: Delete confirmation dialog displays with appropriate styling

---

### TC-S2-016-08: SearchInput Component

**Description**: Verify SearchInput with clear button

**Preconditions**: None

**Test Steps**:
1. Create SearchInput with controller
2. Type text into search field
3. Verify clear button appears when text is entered
4. Click clear button
5. Verify text is cleared

**Expected Result**: SearchInput functions correctly with clear functionality

---

### TC-S2-016-09: FilterChipSelector Single Selection

**Description**: Verify FilterChipSelector single selection mode

**Preconditions**: None

**Test Steps**:
1. Create FilterChipSelector with options list
2. Verify "全部" chip is shown
3. Select an option
4. Verify only one option is selected
5. Select "全部" chip
6. Verify selection is cleared

**Expected Result**: Single selection works correctly

---

### TC-S2-016-10: StatusBadge Factory Methods

**Description**: Verify StatusBadge factory methods

**Preconditions**: None

**Test Steps**:
1. Create StatusBadge.success
2. Verify green color scheme
3. Create StatusBadge.warning
4. Verify orange color scheme
5. Create StatusBadge.error
6. Verify red color scheme
7. Create StatusBadge.neutral
8. Verify grey color scheme

**Expected Result**: All factory methods create correctly styled badges

---

### TC-S2-016-11: KayakDataTable Basic Display

**Description**: Verify KayakDataTable displays data correctly

**Preconditions**: None

**Test Steps**:
1. Create KayakDataTable with columns and data
2. Verify column headers are displayed
3. Verify data rows are shown
4. Verify pagination controls appear

**Expected Result**: Data table displays data with pagination

---

### TC-S2-016-12: KayakDataTable Sorting

**Description**: Verify KayakDataTable sorting functionality

**Preconditions**: None

**Test Steps**:
1. Create KayakDataTable with sortable columns
2. Click column header to sort
3. Verify data is sorted ascending
4. Click again to sort descending
5. Verify data is sorted descending

**Expected Result**: Sorting works correctly with visual indicator

---

### TC-S2-016-13: KayakDataTable Pagination

**Description**: Verify KayakDataTable pagination

**Preconditions**: None

**Test Steps**:
1. Create KayakDataTable with data exceeding page size
2. Verify pagination controls
3. Click next page
4. Verify new page data is displayed
5. Click previous page
6. Verify original data is displayed

**Expected Result**: Pagination navigates correctly

---

### TC-S2-016-14: KayakDataTable Empty State

**Description**: Verify KayakDataTable empty state

**Preconditions**: None

**Test Steps**:
1. Create KayakDataTable with empty data list
2. Verify empty state message is displayed
3. Verify icon is shown

**Expected Result**: Empty state displays when no data

---

### TC-S2-016-15: Material Design 3 Theme Compatibility

**Description**: Verify components adapt to Material Design 3 theme

**Preconditions**: MaterialApp with Material 3 theme

**Test Steps**:
1. Apply Material 3 light theme
2. Verify component styling matches theme
3. Switch to dark theme
4. Verify component styling adapts to dark theme

**Expected Result**: Components properly support Material 3 theming

---

## Test Execution Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-S2-016-01 | LoadingOverlay Component | Pass |
| TC-S2-016-02 | EmptyState Component | Pass |
| TC-S2-016-03 | ErrorState Component | Pass |
| TC-S2-016-04 | Toast.showSuccess | Pass |
| TC-S2-016-05 | Toast.showError | Pass |
| TC-S2-016-06 | ConfirmationDialog | Pass |
| TC-S2-016-07 | DeleteConfirmationDialog | Pass |
| TC-S2-016-08 | SearchInput Component | Pass |
| TC-S2-016-09 | FilterChipSelector | Pass |
| TC-S2-016-10 | StatusBadge Factory | Pass |
| TC-S2-016-11 | KayakDataTable Display | Pass |
| TC-S2-016-12 | KayakDataTable Sorting | Pass |
| TC-S2-016-13 | KayakDataTable Pagination | Pass |
| TC-S2-016-14 | KayakDataTable Empty State | Pass |
| TC-S2-016-15 | Material Design 3 Theme | Pass |

**Total**: 15 test cases
**Passed**: 15
**Failed**: 0