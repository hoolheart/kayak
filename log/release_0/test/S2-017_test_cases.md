# S2-017 Test Cases: 错误处理与反馈

**Created**: 2026-03-26
**Task**: S2-017 错误处理与反馈
**Status**: Ready for Review

---

## Test Scope

Test global error handling and feedback system:
- API error interceptor and toast notifications
- Network connectivity error handling
- Form validation error display
- Global error boundary for rendering errors

---

## Test Cases

### TC-S2-017-01: ApiErrorInterceptor captures 4xx errors

**Description**: Verify API error interceptor captures and displays 4xx client errors

**Preconditions**: None

**Test Steps**:
1. Mock an HTTP 400 Bad Request response from API
2. Trigger the API call through repository
3. Verify error is caught by interceptor
4. Verify Toast notification is displayed with error message

**Expected Result**: User-friendly error message displayed via Toast for 4xx errors

---

### TC-S2-017-02: ApiErrorInterceptor captures 5xx errors

**Description**: Verify API error interceptor captures and displays 5xx server errors

**Preconditions**: None

**Test Steps**:
1. Mock an HTTP 500 Internal Server Error response from API
2. Trigger the API call through repository
3. Verify error is caught by interceptor
4. Verify Toast notification is displayed

**Expected Result**: Generic error message displayed via Toast for 5xx errors (no sensitive details)

---

### TC-S2-017-03: Network error displays offline notification

**Description**: Verify network connectivity error shows user-friendly offline message

**Preconditions**: None

**Test Steps**:
1. Simulate network disconnection
2. Attempt API call
3. Verify custom offline notification is displayed
4. Verify notification indicates no internet connection

**Expected Result**: "网络连接已断开" message displayed when network unavailable

---

### TC-S2-017-04: Network status recovery auto-dismiss

**Description**: Verify offline notification is dismissed when network recovers

**Preconditions**: Network disconnected state

**Test Steps**:
1. Display offline notification
2. Simulate network reconnection
3. Verify notification is automatically dismissed
4. Verify app resumes normal operation

**Expected Result**: Toast disappears automatically on network recovery

---

### TC-S2-017-05: Form validation errors display inline

**Description**: Verify form validation errors display next to relevant fields

**Preconditions**: Form with validation-enabled fields

**Test Steps**:
1. Submit form with invalid/empty required fields
2. Verify error messages appear near corresponding input fields
3. Verify error messages are specific to each field
4. Verify submit button remains disabled until validation passes

**Expected Result**: Inline validation error messages displayed per field

---

### TC-S2-017-06: Global error boundary catches widget errors

**Description**: Verify error boundary catches and handles rendering exceptions

**Preconditions**: None

**Preprocess**: Set up error boundary wrapper

**Test Steps**:
1. Render a widget that throws an exception during build
2. Verify error boundary catches the exception
3. Verify error UI is displayed instead of blank/crashed screen
4. Verify app continues functioning

**Expected Result**: Graceful error UI displayed, app doesn't crash

---

### TC-S2-017-07: Error boundary retry button works

**Description**: Verify error boundary's retry button resets error state

**Preconditions**: Widget with error boundary catching error

**Test Steps**:
1. Trigger a widget rendering error
2. Verify error boundary catches it and shows error UI
3. Click retry/reset button
4. Verify error state is cleared
5. Verify widget attempts to re-render

**Expected Result**: Retry button clears error and re-renders widget

---

### TC-S2-017-08: Toast shows API error message

**Description**: Verify API errors show appropriate Toast with message from server

**Preconditions**: API returning error response

**Test Steps**:
1. Trigger API call that returns error with message
2. Verify Toast shows the error message from response
3. If no message, verify generic fallback message shown

**Expected Result**: Toast displays meaningful error message

---

### TC-S2-017-09: Toast error auto-dismiss

**Description**: Verify error Toast automatically dismisses after duration

**Preconditions**: None

**Test Steps**:
1. Trigger API error that shows Toast
2. Verify Toast appears
3. Wait for auto-dismiss duration (default 4 seconds)
4. Verify Toast disappears

**Expected Result**: Toast auto-dismisses after configured duration

---

### TC-S2-017-10: Multiple rapid errors show single Toast

**Description**: Verify multiple API errors in quick succession show one Toast

**Preconditions**: None

**Test Steps**:
1. Trigger multiple API errors within 1 second
2. Verify only one Toast is displayed
3. Verify Toast shows last error message
4. Verify no overlapping Toasts

**Expected Result**: Only one Toast shown for burst of errors

---

### TC-S2-017-11: ErrorHandler processes Dio exceptions

**Description**: Verify error handler properly processes Dio network exceptions

**Preconditions**: Dio HTTP client configured

**Test Steps**:
1. Mock DioException with connection timeout
2. Pass through error handler
3. Verify appropriate error message generated
4. Verify Toast notification shown

**Expected Result**: Dio exceptions converted to user-friendly messages

---

### TC-S2-017-12: Auth error (401) redirects to login

**Description**: Verify 401 Unauthorized error triggers re-authentication flow

**Preconditions**: User authenticated with expired token

**Test Steps**:
1. Make API call with expired/invalid token
2. Verify 401 response
3. Verify user is redirected to login page
4. Verify current state is cleared

**Expected Result**: Automatic redirect to login on 401

---

### TC-S2-017-13: Form field-level error styling

**Description**: Verify invalid form fields show error styling

**Preconditions**: Form with validation

**Test Steps**:
1. Enter invalid data in form field
2. Verify field border turns red
3. Verify error text appears below field
4. Fix the error
5. Verify error styling is removed

**Expected Result**: Visual error indication on invalid fields

---

### TC-S2-017-14: Error service singleton access

**Description**: Verify error handler can be accessed globally via singleton

**Preconditions**: App initialized with error handler

**Test Steps**:
1. Access ErrorHandler.instance from different parts of app
2. Verify same instance is returned
3. Verify configuration persists across access points

**Expected Result**: Global singleton accessible throughout app

---

### TC-S2-017-15: Server error (500) shows generic message

**Description**: Verify 500 errors don't leak server details to user

**Preconditions**: API returning 500 error

**Test Steps**:
1. Trigger API call that returns 500 Internal Server Error
2. Verify Toast shows generic message like "服务器错误，请稍后重试"
3. Verify no stack traces or server details shown
4. Verify error is logged locally

**Expected Result**: Generic user-safe error message, details logged only

---

## Test Execution Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-S2-017-01 | ApiErrorInterceptor 4xx errors | Pending |
| TC-S2-017-02 | ApiErrorInterceptor 5xx errors | Pending |
| TC-S2-017-03 | Network error offline notification | Pending |
| TC-S2-017-04 | Network recovery auto-dismiss | Pending |
| TC-S2-017-05 | Form validation inline errors | Pending |
| TC-S2-017-06 | Global error boundary catches errors | Pending |
| TC-S2-017-07 | Error boundary retry button | Pending |
| TC-S2-017-08 | Toast shows API error message | Pending |
| TC-S2-017-09 | Toast error auto-dismiss | Pending |
| TC-S2-017-10 | Multiple rapid errors single Toast | Pending |
| TC-S2-017-11 | Dio exception processing | Pending |
| TC-S2-017-12 | 401 redirects to login | Pending |
| TC-S2-017-13 | Form field error styling | Pending |
| TC-S2-017-14 | Error handler singleton | Pending |
| TC-S2-017-15 | Server error generic message | Pending |

**Total**: 15 test cases