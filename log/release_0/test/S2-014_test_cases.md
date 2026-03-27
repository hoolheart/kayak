# S2-014 Test Cases: 应用导航框架与路由

**Created**: 2026-03-26
**Task**: S2-014 应用导航框架与路由
**Status**: Ready for Testing

---

## Test Scope

Test navigation framework components:
- AppShell layout with responsive sidebar
- Sidebar navigation with collapse/expand
- Breadcrumb navigation
- Route switching and guards
- Window resize adaptation

---

## Test Cases

### TC-S2-014-01: Sidebar Navigation Items Display

**Description**: Verify sidebar displays all navigation items correctly

**Preconditions**: 
- User is logged in
- App is at dashboard route `/dashboard`

**Test Steps**:
1. Observe sidebar on left side of screen
2. Verify navigation items are visible: 首页, 工作台, 试验, 方法, 设置

**Expected Result**: All 5 navigation items are displayed with correct labels and icons

---

### TC-S2-014-02: Sidebar Collapse Toggle

**Description**: Verify sidebar can be collapsed and expanded

**Preconditions**: 
- User is logged in
- App is at dashboard route `/dashboard`

**Test Steps**:
1. Locate sidebar collapse toggle button
2. Click collapse button
3. Observe sidebar width changes
4. Click expand button
5. Observe sidebar returns to normal width

**Expected Result**: 
- Sidebar collapses to narrow width (icons only)
- Sidebar expands back to full width with labels

---

### TC-S2-014-03: Navigate to Workbenches

**Description**: Verify navigation to workbenches page

**Preconditions**: 
- User is logged in
- App is at dashboard route `/dashboard`

**Test Steps**:
1. Click on "工作台" navigation item
2. Observe URL changes to `/workbenches`
3. Verify content area shows workbench placeholder

**Expected Result**: 
- URL changes to `/workbenches`
- Breadcrumb shows: 首页 > 工作台
- Content displays workbench page

---

### TC-S2-014-04: Navigate to Experiments

**Description**: Verify navigation to experiments list page

**Preconditions**: 
- User is logged in
- App is at dashboard route `/dashboard`

**Test Steps**:
1. Click on "试验" navigation item
2. Observe URL changes to `/experiments`
3. Verify content area shows experiment list page

**Expected Result**: 
- URL changes to `/experiments`
- Breadcrumb shows: 首页 > 试验
- Content displays experiment list page

---

### TC-S2-014-05: Navigate to Methods

**Description**: Verify navigation to methods management page

**Preconditions**: 
- User is logged in
- App is at dashboard route `/dashboard`

**Test Steps**:
1. Click on "方法" navigation item
2. Observe URL changes to `/methods`
3. Verify content area shows method list page

**Expected Result**: 
- URL changes to `/methods`
- Breadcrumb shows: 首页 > 方法
- Content displays method list page

---

### TC-S2-014-06: Navigate to Settings

**Description**: Verify navigation to settings page

**Preconditions**: 
- User is logged in
- App is at dashboard route `/dashboard`

**Test Steps**:
1. Click on "设置" navigation item
2. Observe URL changes to `/settings`
3. Verify content area shows settings page

**Expected Result**: 
- URL changes to `/settings`
- Breadcrumb shows: 首页 > 设置
- Content displays settings page

---

### TC-S2-014-07: Sidebar Responsive - Wide Screen

**Description**: Verify sidebar behavior on wide screen (>1200px)

**Preconditions**: 
- User is logged in
- Browser window width > 1200px

**Test Steps**:
1. Observe sidebar at full width
2. Verify navigation labels are visible

**Expected Result**: Sidebar displays at full width with navigation labels visible

---

### TC-S2-014-08: Sidebar Responsive - Medium Screen

**Description**: Verify sidebar behavior on medium screen (900-1200px)

**Preconditions**: 
- User is logged in
- Browser window width between 900px and 1200px

**Test Steps**:
1. Resize window to medium width
2. Observe sidebar auto-collapses

**Expected Result**: Sidebar auto-collapses to icons-only mode

---

### TC-S2-014-09: Sidebar Responsive - Narrow Screen

**Description**: Verify sidebar behavior on narrow screen (<900px)

**Preconditions**: 
- User is logged in
- Browser window width < 900px

**Test Steps**:
1. Resize window to narrow width
2. Observe sidebar is collapsed

**Expected Result**: Sidebar remains collapsed in icons-only mode

---

### TC-S2-014-10: Dashboard Navigation from Quick Actions

**Description**: Verify quick action cards on dashboard navigate correctly

**Preconditions**: 
- User is logged in
- App is at dashboard route `/dashboard`

**Test Steps**:
1. Locate quick action cards on dashboard
2. Click on "工作台" quick action
3. Verify navigation to `/workbenches`

**Expected Result**: Clicking quick action navigates to corresponding page

---

### TC-S2-014-11: Breadcrumb Display

**Description**: Verify breadcrumb navigation displays correctly

**Preconditions**: 
- User is logged in
- App is at experiments page `/experiments`

**Test Steps**:
1. Observe breadcrumb above content area
2. Verify breadcrumb shows: 首页 > 试验

**Expected Result**: Breadcrumb displays correct navigation path with clickable "首页" link

---

### TC-S2-014-12: Auth Guard - Unauthenticated User

**Description**: Verify unauthenticated users are redirected to login

**Preconditions**: 
- User is not logged in
- App token storage is empty

**Test Steps**:
1. Attempt to access `/dashboard` directly
2. Observe redirect to login page

**Expected Result**: User is redirected to `/login` with redirect parameter

---

### TC-S2-014-13: Auth Guard - After Login Redirect

**Description**: Verify login redirects to dashboard after successful login

**Preconditions**: 
- User is on login page
- User has valid credentials

**Test Steps**:
1. Enter valid credentials
2. Click login button
3. Observe redirect destination

**Expected Result**: After successful login, user is redirected to `/dashboard`

---

### TC-S2-014-14: Legacy /home Route Redirect

**Description**: Verify old /home route redirects to /dashboard

**Preconditions**: 
- User is logged in

**Test Steps**:
1. Navigate directly to `/home`
2. Observe URL change

**Expected Result**: `/home` redirects to `/dashboard`

---

### TC-S2-014-15: Back Navigation After Route Change

**Description**: Verify browser back button works correctly

**Preconditions**: 
- User is logged in
- User has navigated from dashboard to experiments

**Test Steps**:
1. Navigate from dashboard to experiments
2. Click browser back button
3. Verify return to dashboard

**Expected Result**: Browser back button returns to previous route

---

## Test Execution Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-S2-014-01 | Sidebar Navigation Items Display | Pass |
| TC-S2-014-02 | Sidebar Collapse Toggle | Pass |
| TC-S2-014-03 | Navigate to Workbenches | Pass |
| TC-S2-014-04 | Navigate to Experiments | Pass |
| TC-S2-014-05 | Navigate to Methods | Pass |
| TC-S2-014-06 | Navigate to Settings | Pass |
| TC-S2-014-07 | Sidebar Responsive - Wide Screen | Pass |
| TC-S2-014-08 | Sidebar Responsive - Medium Screen | Pass |
| TC-S2-014-09 | Sidebar Responsive - Narrow Screen | Pass |
| TC-S2-014-10 | Dashboard Navigation from Quick Actions | Pass |
| TC-S2-014-11 | Breadcrumb Display | Pass |
| TC-S2-014-12 | Auth Guard - Unauthenticated User | Pass |
| TC-S2-014-13 | Auth Guard - After Login Redirect | Pass |
| TC-S2-014-14 | Legacy /home Route Redirect | Pass |
| TC-S2-014-15 | Back Navigation After Route Change | Pass |

**Total**: 15 test cases
**Passed**: 15
**Failed**: 0
**Blocked**: 0
**Skipped**: 0