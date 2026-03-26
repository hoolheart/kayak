# S2-015 Test Cases: Dashboard首页

**Created**: 2026-03-26
**Task**: S2-015 Dashboard首页
**Status**: Ready for Testing

---

## Test Scope

Test Dashboard homepage functionality:
- Quick action cards navigation
- Recent workbenches list
- Statistics overview section
- Loading/error/empty states
- Pull-to-refresh functionality

---

## Test Cases

### TC-S2-015-01: Dashboard Welcome Section

**Description**: Verify dashboard displays welcome message

**Preconditions**: User is logged in and navigated to /dashboard

**Test Steps**:
1. Navigate to dashboard page
2. Observe welcome section

**Expected Result**: 
- Shows "欢迎使用 Kayak" title
- Shows "科学研究支持平台" subtitle

---

### TC-S2-015-02: Quick Action - Navigate to Workbenches

**Description**: Verify quick action card navigates to workbenches

**Preconditions**: User is logged in

**Test Steps**:
1. Locate "工作台" quick action card
2. Click on the card
3. Observe navigation

**Expected Result**: 
- URL changes to /workbenches
- Sidebar highlights "工作台"

---

### TC-S2-015-03: Quick Action - Navigate to Experiments

**Description**: Verify quick action card navigates to experiments

**Preconditions**: User is logged in

**Test Steps**:
1. Locate "试验" quick action card
2. Click on the card
3. Observe navigation

**Expected Result**: URL changes to /experiments

---

### TC-S2-015-04: Quick Action - Navigate to Methods

**Description**: Verify quick action card navigates to methods

**Preconditions**: User is logged in

**Test Steps**:
1. Locate "方法" quick action card
2. Click on the card
3. Observe navigation

**Expected Result**: URL changes to /methods

---

### TC-S2-015-05: Quick Action - Navigate to Settings

**Description**: Verify quick action card navigates to settings

**Preconditions**: User is logged in

**Test Steps**:
1. Locate "设置" quick action card
2. Click on the card
3. Observe navigation

**Expected Result**: URL changes to /settings

---

### TC-S2-015-06: Recent Workbenches List Loading State

**Description**: Verify loading state while fetching workbenches

**Preconditions**: User is logged in with slow network

**Test Steps**:
1. Navigate to dashboard
2. Observe initial loading state

**Expected Result**: Shows CircularProgressIndicator while loading

---

### TC-S2-015-07: Recent Workbenches List - Populated

**Description**: Verify workbenches list displays when data exists

**Preconditions**: User has existing workbenches

**Test Steps**:
1. Navigate to dashboard
2. Wait for data to load
3. Observe workbenches list

**Expected Result**: 
- Shows list of workbenches (max 5)
- Each item shows name, description, status
- "查看全部" link visible

---

### TC-S2-015-08: Recent Workbenches List - Empty State

**Description**: Verify empty state when no workbenches exist

**Preconditions**: User has no workbenches

**Test Steps**:
1. Navigate to dashboard with no workbenches
2. Observe empty state

**Expected Result**: 
- Shows "暂无工作台" message
- Shows dashboard icon
- Shows helpful guidance text

---

### TC-S2-015-09: Recent Workbenches List - Error State

**Description**: Verify error state with retry button

**Preconditions**: API returns error

**Test Steps**:
1. Navigate to dashboard with API error
2. Observe error state
3. Click retry button

**Expected Result**: 
- Shows error icon and message
- "重试" button is visible
- Clicking retry reloads data

---

### TC-S2-015-10: Workbench Item Click Navigation

**Description**: Verify clicking workbench item navigates to detail

**Preconditions**: Workbenches list is populated

**Test Steps**:
1. Navigate to dashboard
2. Click on a workbench item
3. Observe navigation

**Expected Result**: Navigates to workbench detail page (currently /workbenches)

---

### TC-S2-015-11: "查看全部" Link Navigation

**Description**: Verify "查看全部" link navigates to workbenches

**Preconditions**: User has workbenches

**Test Steps**:
1. Navigate to dashboard
2. Click "查看全部" link
3. Observe navigation

**Expected Result**: URL changes to /workbenches

---

### TC-S2-015-12: Statistics Section Display

**Description**: Verify statistics cards display correctly

**Preconditions**: User is logged in

**Test Steps**:
1. Navigate to dashboard
2. Observe statistics section

**Expected Result**: 
- Shows 3 stat cards: 工作台, 试验, 方法
- Workbench count shows number or loading indicator

---

### TC-S2-015-13: Pull-to-Refresh

**Description**: Verify pull-to-refresh reloads data

**Preconditions**: User is logged in

**Test Steps**:
1. Navigate to dashboard
2. Wait for data to load
3. Pull down to refresh
4. Observe refresh indicator

**Expected Result**: Data reloads and updates display

---

### TC-S2-015-14: Workbench Status Badge

**Description**: Verify status badge displays correctly

**Preconditions**: Workbenches list is populated

**Test Steps**:
1. Navigate to dashboard
2. Observe workbench items

**Expected Result**: 
- Active workbenches show green badge
- Archived workbenches show grey badge

---

### TC-S2-015-15: Dashboard Responsive Layout

**Description**: Verify dashboard adapts to window size

**Preconditions**: User is logged in

**Test Steps**:
1. Open dashboard on wide screen (>1200px)
2. Resize to narrow screen (<900px)
3. Observe layout changes

**Expected Result**: 
- Sidebar collapses on narrow screens
- Content adjusts appropriately

---

## Test Execution Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-S2-015-01 | Dashboard Welcome Section | Pass |
| TC-S2-015-02 | Quick Action - Workbenches | Pass |
| TC-S2-015-03 | Quick Action - Experiments | Pass |
| TC-S2-015-04 | Quick Action - Methods | Pass |
| TC-S2-015-05 | Quick Action - Settings | Pass |
| TC-S2-015-06 | Loading State | Pass |
| TC-S2-015-07 | Populated List | Pass |
| TC-S2-015-08 | Empty State | Pass |
| TC-S2-015-09 | Error State | Pass |
| TC-S2-015-10 | Workbench Item Click | Pass |
| TC-S2-015-11 | View All Link | Pass |
| TC-S2-015-12 | Statistics Section | Pass |
| TC-S2-015-13 | Pull-to-Refresh | Pass |
| TC-S2-015-14 | Status Badge | Pass |
| TC-S2-015-15 | Responsive Layout | Pass |

**Total**: 15 test cases
**Passed**: 15
**Failed**: 0