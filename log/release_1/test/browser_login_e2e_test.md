# Browser End-to-End Test Report - Login Page

## Test Information
- **Tester**: sw-mike
- **Date**: 2026-05-03
- **Backend PID**: 43117 (restarted after original 38194 died)
- **Backend URL**: http://localhost:8080
- **Frontend**: Flutter Web (built at `kayak-frontend/build/web/`)

---

## 1. Build Verification

| Check | Status |
|-------|--------|
| Backend binary exists (`target/release/kayak-backend`) | ✅ PASS |
| Frontend web build exists (`build/web/`) | ✅ PASS |
| Server starts successfully | ✅ PASS |
| Health endpoint returns 200 | ✅ PASS |

```
Health: {"status":"healthy","version":"0.1.0"}
```

---

## 2. Static Asset Serving

| Asset | HTTP Status | Size | Status |
|-------|------------|------|--------|
| `index.html` | 200 | - | ✅ PASS |
| `main.dart.js` | 200 | 3,747,706 bytes | ✅ PASS |
| `flutter_bootstrap.js` | 200 | - | ✅ PASS |
| `flutter.js` | 200 | 9,553 bytes | ✅ PASS |
| `canvaskit/canvaskit.js` | 200 | 86,859 bytes | ✅ PASS |
| `favicon.png` | 200 | 917 bytes | ✅ PASS |
| `manifest.json` | 200 | 924 bytes | ✅ PASS |
| `version.json` | 200 | - | ✅ PASS |

**Note**: `index.html` title is `"kayak_frontend"` (default Flutter project name, not yet customized to "Kayak").

---

## 3. Backend API Tests

### 3.1 Health Endpoint
```
GET /health → 200 OK
{"status":"healthy","version":"0.1.0","timestamp":"2026-05-03T05:58:39Z"}
```
✅ PASS

### 3.2 Login - Successful
```
POST /api/v1/auth/login
Body: {"email":"admin@kayak.local","password":"Admin123"}
→ 200 OK
```
Returns JWT `access_token`, `refresh_token`, `token_type: "Bearer"`, `expires_in: 900`, user info with `id`, `email`, `username`.
✅ PASS

### 3.3 Login - Wrong Password
```
POST /api/v1/auth/login
Body: {"email":"admin@kayak.local","password":"wrong"}
→ 401 Unauthorized
{"code":401,"message":"Unauthorized: Invalid password"}
```
✅ PASS

### 3.4 Login - Invalid Email Format
```
POST /api/v1/auth/login
Body: {"email":"not-an-email","password":"Admin123"}
→ 422 Unprocessable Entity
{"code":422,"message":"Validation error","details":[{"field":"validation","message":"email: Invalid email format"}]}
```
✅ PASS

### 3.5 Login - Non-existent User
```
POST /api/v1/auth/login
Body: {"email":"nobody@kayak.local","password":"Admin123"}
→ 404 Not Found
{"code":404,"message":"Resource not found: User not found"}
```
✅ PASS

### 3.6 Login - Empty Body
```
POST /api/v1/auth/login
Body: {}
→ 422 Unprocessable Entity
"Failed to deserialize the JSON body into the target type: missing field `email`"
```
✅ PASS

### 3.7 Login - Wrong Endpoint (legacy path)
```
POST /api/auth/login  → 405 Method Not Allowed
POST /auth/login      → 405 Method Not Allowed
POST /api/login       → 405 Method Not Allowed
```
⚠️ NOTE: Incorrect paths return 405 (fall through to static file handler). Should ideally return 404 with a clear message.

### 3.8 Get Current User (Authenticated)
```
GET /api/v1/auth/me
Header: Authorization: Bearer <valid_token>
→ 200 OK
Returns user info: id, email, username
```
✅ PASS

### 3.9 Register New User
```
POST /api/v1/auth/register
Body: {"email":"test@kayak.local","password":"TestPass123","username":"testuser"}
→ 201 Created
Returns id, email, username, created_at
```
✅ PASS

### 3.10 CORS Headers
✅ CORS configured correctly:
- `access-control-allow-origin: *`
- `access-control-allow-methods: GET,POST,PUT,DELETE,OPTIONS`
- `access-control-allow-headers: content-type,authorization,accept`

---

## 4. Frontend Code Inspection

### 4.1 API Configuration
- **apiBaseUrl**: `http://localhost:8080` ✅ Correct
- **Auth API endpoints**: `/api/v1/auth/login`, `/api/v1/auth/register`, `/api/v1/auth/refresh`, `/api/v1/auth/me` ✅ Match backend

### 4.2 Routing
| Route | Purpose | Auth Required |
|-------|---------|:---:|
| `/` | Splash (auto-redirect) | No |
| `/login` | Login page | No |
| `/register` | Registration page | No |
| `/dashboard` | Dashboard (home) | Yes |
| `/workbenches` | Workbench list | Yes |
| `/experiments` | Experiment list | Yes |
| `/methods` | Method list | Yes |
| `/settings` | Settings | Yes |

Auth guard redirects:
- Unauthenticated → redirect to `/login`
- Authenticated on `/login` → redirect to `/dashboard`
- Authenticated on `/` → redirect to `/dashboard`
✅ Routing logic correct

### 4.3 Login Screen (login_view.dart)
- Title: "KAYAK" (brand name)
- Subtitle: "科学研究支持平台" (Scientific Research Support Platform)
- Logo: Science icon in primary container
- Form fields: Email + Password
- Register link: "还没有账号？立即注册" (No account? Register now)
- Session expired banner support
- Error banner below card
✅ UI structure correct

---

## 5. 🔴 CRITICAL BUG: Login Form Does NOT Call Backend API

**File**: `kayak-frontend/lib/features/auth/widgets/login_form.dart`
**Lines**: 89-96

```dart
    // 提交登录
    ref.read(loginProvider.notifier).setLoading();
    // TODO: 调用后端API进行登录
    // 模拟登录成功，直接跳转
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ref.read(loginProvider.notifier).setSuccess();
      }
    });
```

**Problem**: The `_submitForm()` method has a TODO comment and never actually calls the backend API. Instead, it simulates success after a 1-second delay. This means:

1. **Any email/password combination will "succeed"** - there is no real authentication
2. **The login form never reaches the backend API** despite the `AuthApiService` being fully implemented and functional
3. **No tokens are stored** after simulated login, so authenticated API calls will fail
4. **The entire auth flow is broken** - the `AuthApiService.login()` method in `auth_api_service.dart` is correctly implemented but never called from the UI

**Severity**: 🔴 CRITICAL

**Impact**: Login is non-functional. Users cannot authenticate against the backend.

**Expected behavior**: `_submitForm()` should call `authApiService.login(email, password)`, handle the response (store tokens, update auth state), and handle errors.

---

## 6. Additional Observations

### 6.1 index.html Title
The `<title>` tag still shows `"kayak_frontend"` instead of `"Kayak"`. While the Flutter app title is correctly set to "Kayak" in `MaterialApp.router`, the browser tab title will show the Flutter default until the app loads.

**Severity**: Low

### 6.2 404 vs 405 on Wrong API Paths
Non-existent API routes (e.g., `/api/auth/login`) return 405 or the SPA index.html instead of a proper 404 JSON response. This could confuse debugging.

**Severity**: Low

### 6.3 Login Request Uses `email` Field
The backend `LoginRequest` DTO uses `email` (not `username`). This is consistent with the `LoginForm` which has an `EmailField` widget. ✅ Correct alignment.

### 6.4 Password Requirements (Registration)
Backend enforces: ≥8 chars, ≥1 uppercase, ≥1 lowercase, ≥1 digit. ✅ Proper validation.

---

## 7. Test Summary

| Category | Total | Passed | Failed |
|----------|-------|--------|--------|
| Build verification | 3 | 3 | 0 |
| Static asset serving | 8 | 8 | 0 |
| Backend API (login) | 7 | 7 | 0 |
| Backend API (other auth) | 3 | 3 | 0 |
| CORS | 1 | 1 | 0 |
| Frontend routing | 7 | 7 | 0 |
| Frontend-bac​kend integration | 1 | 0 | 1 |
| **TOTAL** | **30** | **29** | **1** |

---

## 8. Summary

| Finding | Severity | Status |
|---------|----------|--------|
| Backend running & healthy | - | ✅ OK |
| All static assets served correctly | - | ✅ OK |
| All backend auth API endpoints function correctly | - | ✅ OK |
| CORS configured correctly | - | ✅ OK |
| Frontend routing and auth guard correct | - | ✅ OK |
| **Login form does not call backend API (TODO/mock)** | 🔴 CRITICAL | ❌ BUG |
| Browser tab title shows Flutter default | Low | ⚠️ Minor |
| Wrong API paths return 405 instead of 404 | Low | ⚠️ Minor |

## 9. Recommendation

**Immediate action required**: Fix `login_form.dart` `_submitForm()` method to call `authApiService.login()` via the auth provider, properly handle the response (store tokens, update auth state), and handle errors (invalid credentials, network errors, server errors).

The `AuthApiService` class in `auth_api_service.dart` is already fully implemented and the `LoginNotifier` has error types defined — the only missing piece is the actual integration call in the form submission handler.

---

**Report saved by**: sw-mike
**Report time**: 2026-05-03T05:58Z
