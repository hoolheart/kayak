# Test Cases — Python SDK (R2-S2-003-A)

## Test Information
- **Task**: R2-S2-003-A — Python SDK Test Case Design
- **Tester**: sw-mike
- **Date**: 2026-05-11
- **Status**: Draft
- **Target**: `kayak-python-client/` — Python SDK for Kayak REST API

---

## Table of Contents

1. [Login / Logout Flow](#1-login--logout-flow)
2. [Token Refresh](#2-token-refresh)
3. [Context Manager Behavior](#3-context-manager-behavior)
4. [Resource Listing APIs](#4-resource-listing-apis)
5. [Data Download](#5-data-download)
6. [Data Conversion (HDF5 → DataFrame / ndarray)](#6-data-conversion-hdf5--dataframe--ndarray)
7. [Error Handling & HTTP Status Mapping](#7-error-handling--http-status-mapping)
8. [Invalid Input Validation](#8-invalid-input-validation)
9. [Concurrent Usage & Thread Safety](#9-concurrent-usage--thread-safety)
10. [Session Persistence](#10-session-persistence)
11. [Traceability Matrix](#11-traceability-matrix)

---

## 1. Login / Logout Flow

### TC-SDK-001: Login — Success
- **Description**: Verify that `client.login(email, password)` authenticates successfully and stores the access/refresh tokens.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. `KayakClient` instantiated with a valid `base_url`.
  2. Backend mock returns `200 OK` with JWT access token and refresh token.
- **Steps**:
  1. Instantiate `client = KayakClient(base_url="http://localhost:8080")`.
  2. Mock `POST /api/v1/auth/login` to return:
     ```json
     {
       "code": 200,
       "data": {
         "access_token": "eyJhbGciOiJIUzI1NiIs...",
         "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2g...",
         "token_type": "Bearer",
         "expires_in": 3600
       }
     }
     ```
  3. Call `client.login("admin@kayak.local", "Admin123")`.
- **Expected Results**:
  1. Method returns `True` (or similar success indicator).
  2. `client.auth.access_token` is populated.
  3. `client.auth.refresh_token` is populated.
  4. `client.auth.token_expires_at` is set to approximately `now + 3600s`.
  5. Subsequent requests include `Authorization: Bearer <access_token>` header.
- **Mock Requirements**:
  - `pytest-httpx` or `responses` to intercept `POST /api/v1/auth/login`.

---

### TC-SDK-002: Login — Invalid Credentials
- **Description**: Verify that login with wrong password raises `AuthenticationError`.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. `KayakClient` instantiated.
  2. Backend mock returns `401 Unauthorized`.
- **Steps**:
  1. Mock `POST /api/v1/auth/login` to return `401` with body:
     ```json
     {"code": 401, "message": "Invalid email or password"}
     ```
  2. Call `client.login("admin@kayak.local", "WrongPassword")`.
- **Expected Results**:
  1. Raises `kayak.AuthenticationError`.
  2. Exception message contains "Invalid email or password".
  3. `client.auth.access_token` remains `None`.
- **Mock Requirements**:
  - `pytest-httpx` to return `401` for login endpoint.

---

### TC-SDK-003: Login — Server Unavailable During Login
- **Description**: Verify that connection failure during login raises `ConnectionError`.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. `KayakClient` instantiated with unreachable URL.
- **Steps**:
  1. Mock `POST /api/v1/auth/login` to raise `httpx.ConnectError`.
  2. Call `client.login("admin@kayak.local", "Admin123")`.
- **Expected Results**:
  1. Raises `kayak.ConnectionError`.
  2. Original `httpx.ConnectError` is available via `__cause__`.
  3. No token state is modified.
- **Mock Requirements**:
  - `pytest-httpx` to simulate connection failure.

---

### TC-SDK-004: Login — Empty Email or Password
- **Description**: Verify that empty credentials are rejected locally without making an HTTP request.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. `KayakClient` instantiated.
- **Steps**:
  1. Call `client.login("", "Admin123")`.
  2. Call `client.login("admin@kayak.local", "")`.
  3. Call `client.login("", "")`.
- **Expected Results**:
  1. Each call raises `kayak.ValidationError` (or `ValueError`).
  2. No HTTP request is sent for any of the three calls.
- **Mock Requirements**:
  - Assert zero HTTP requests dispatched.

---

### TC-SDK-005: Logout — Success
- **Description**: Verify that logout clears local token state and optionally notifies the backend.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated (valid tokens stored).
- **Steps**:
  1. Mock `POST /api/v1/auth/logout` to return `200 OK`.
  2. Call `client.logout()`.
- **Expected Results**:
  1. `client.auth.access_token` is `None`.
  2. `client.auth.refresh_token` is `None`.
  3. `client.auth.token_expires_at` is `None`.
  4. If backend logout endpoint exists, it is called with the current token.
- **Mock Requirements**:
  - `pytest-httpx` to intercept `POST /api/v1/auth/logout`.

---

### TC-SDK-006: Logout — Without Prior Login
- **Description**: Verify that calling logout on an unauthenticated client is a no-op (no error).
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. `KayakClient` instantiated but never logged in.
- **Steps**:
  1. Call `client.logout()`.
- **Expected Results**:
  1. No exception raised.
  2. No HTTP request sent.
  3. Token state remains `None`.

---

## 2. Token Refresh

### TC-SDK-007: Automatic Token Refresh — Triggered Before Expiry
- **Description**: Verify that an API call made when the access token is about to expire (within 5 minutes) triggers a background token refresh before the original request is sent.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP + time manipulation)
- **Preconditions**:
  1. Client is authenticated.
  2. Access token expires in 4 minutes 30 seconds.
- **Steps**:
  1. Mock `POST /api/v1/auth/refresh` to return new access token (expires_in: 3600).
  2. Mock `GET /api/v1/workbenches` to return `200 OK`.
  3. Call `client.workbenches.list()`.
- **Expected Results**:
  1. `POST /api/v1/auth/refresh` is called first with the current refresh token.
  2. `GET /api/v1/workbenches` is called second with the **new** access token.
  3. `client.auth.access_token` is updated to the new token.
  4. `client.auth.token_expires_at` is extended by ~3600s.
- **Mock Requirements**:
  - `pytest-httpx` with request ordering assertions.
  - `freezegun` to set token expiry precisely.

---

### TC-SDK-008: Automatic Token Refresh — Not Triggered When Token Is Fresh
- **Description**: Verify that no refresh occurs when the token has more than 5 minutes of remaining life.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
  2. Access token expires in 30 minutes.
- **Steps**:
  1. Mock `GET /api/v1/workbenches` to return `200 OK`.
  2. Call `client.workbenches.list()`.
- **Expected Results**:
  1. `POST /api/v1/auth/refresh` is **not** called.
  2. `GET /api/v1/workbenches` is called with the existing access token.
- **Mock Requirements**:
  - `pytest-httpx` with request count assertion.

---

### TC-SDK-009: Automatic Token Refresh — On 401 Response
- **Description**: Verify that if a request returns `401` due to an already-expired token, the SDK refreshes the token and retries the request **once**.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated with an expired token.
- **Steps**:
  1. Mock `GET /api/v1/workbenches` to return `401` on first call, `200` on second call.
  2. Mock `POST /api/v1/auth/refresh` to return new valid token.
  3. Call `client.workbenches.list()`.
- **Expected Results**:
  1. `GET /api/v1/workbenches` is called once with old token → `401`.
  2. `POST /api/v1/auth/refresh` is called.
  3. `GET /api/v1/workbenches` is retried with new token → `200`.
  4. Final result is the list of workbenches.
- **Mock Requirements**:
  - `pytest-httpx` with response sequence and request inspection.

---

### TC-SDK-010: Automatic Token Refresh — Refresh Token Also Expired
- **Description**: Verify that if both access and refresh tokens are expired/invalid, `AuthenticationError` is raised after refresh attempt fails.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated but refresh token is revoked.
- **Steps**:
  1. Mock `POST /api/v1/auth/refresh` to return `401 Unauthorized`.
  2. Mock `GET /api/v1/workbenches` to return `401 Unauthorized`.
  3. Call `client.workbenches.list()`.
- **Expected Results**:
  1. `POST /api/v1/auth/refresh` is attempted.
  2. Raises `kayak.AuthenticationError`.
  3. Tokens are cleared (client is effectively logged out).
- **Mock Requirements**:
  - `pytest-httpx` to simulate refresh failure.

---

### TC-SDK-011: Manual Token Refresh — Success
- **Description**: Verify that `client.auth.refresh()` can be called explicitly to refresh the token.
- **Priority**: P1
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `POST /api/v1/auth/refresh` to return new token pair.
  2. Call `client.auth.refresh()`.
- **Expected Results**:
  1. Method returns `True`.
  2. `client.auth.access_token` is updated.
  3. `client.auth.token_expires_at` is updated.
- **Mock Requirements**:
  - `pytest-httpx` to intercept refresh endpoint.

---

### TC-SDK-012: Manual Token Refresh — Without Login
- **Description**: Verify that calling refresh before login raises an error.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. `KayakClient` instantiated but not logged in.
- **Steps**:
  1. Call `client.auth.refresh()`.
- **Expected Results**:
  1. Raises `kayak.AuthenticationError` (or `RuntimeError`) with message indicating no refresh token available.
  2. No HTTP request sent.

---

## 3. Context Manager Behavior

### TC-SDK-013: Context Manager — Successful Entry and Exit
- **Description**: Verify that `with KayakClient(...) as client:` instantiates the client and cleans up resources on exit.
- **Priority**: P0
- **Test Type**: Unit
- **Preconditions**:
  1. No active HTTP connections.
- **Steps**:
  1. Execute:
     ```python
     with KayakClient(base_url="http://localhost:8080") as client:
         assert client.base_url == "http://localhost:8080"
     ```
- **Expected Results**:
  1. `client` is an instance of `KayakClient` inside the block.
  2. `__enter__` returns the client.
  3. `__exit__` is called on block exit.
  4. HTTP client session is closed (no open sockets leaked).

---

### TC-SDK-014: Context Manager — Auto-Logout on Exit When Logged In
- **Description**: Verify that exiting the context manager when authenticated triggers logout/cleanup.
- **Priority**: P1
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated inside the context.
- **Steps**:
  1. Mock `POST /api/v1/auth/logout` to return `200 OK`.
  2. Execute:
     ```python
     with KayakClient(base_url="http://localhost:8080") as client:
         client.login("admin@kayak.local", "Admin123")
     ```
- **Expected Results**:
  1. Inside block: login succeeds.
  2. On exit: `POST /api/v1/auth/logout` is called.
  3. Tokens are cleared after exit.

---

### TC-SDK-015: Context Manager — Exception Inside Block Does Not Suppress Error
- **Description**: Verify that exceptions raised inside the `with` block propagate correctly and `__exit__` still runs.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. `KayakClient` instantiated.
- **Steps**:
  1. Execute:
     ```python
     with KayakClient(base_url="http://localhost:8080") as client:
         raise ValueError("test error")
     ```
- **Expected Results**:
  1. `ValueError("test error")` propagates to the caller.
  2. `__exit__` is still invoked (no resource leak).

---

### TC-SDK-016: Context Manager — Combined Login, API Call, and Logout
- **Description**: End-to-end happy path using context manager for a complete workflow.
- **Priority**: P0
- **Test Type**: Integration (mocked HTTP)
- **Preconditions**:
  1. Backend mock provides login, workbench list, and logout endpoints.
- **Steps**:
  1. Mock `POST /api/v1/auth/login` → success.
  2. Mock `GET /api/v1/workbenches` → list of 2 workbenches.
  3. Mock `POST /api/v1/auth/logout` → success.
  4. Execute:
     ```python
     with KayakClient(base_url="http://localhost:8080") as client:
         client.login("admin@kayak.local", "Admin123")
         workbenches = client.workbenches.list()
     ```
- **Expected Results**:
  1. `workbenches` contains 2 items.
  2. All three mocked endpoints are called in correct order.
  3. No token state remains after exiting context.

---

## 4. Resource Listing APIs

### TC-SDK-017: List Workbenches — Success
- **Description**: Verify that `client.workbenches.list()` returns a list of workbench objects.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/workbenches` to return:
     ```json
     {
       "code": 200,
       "data": [
         {"id": "wb-1", "name": "Workbench A", "description": "Test bench"},
         {"id": "wb-2", "name": "Workbench B", "description": null}
       ]
     }
     ```
  2. Call `client.workbenches.list()`.
- **Expected Results**:
  1. Returns a list of length 2.
  2. Each item is a `Workbench` model (or dict) with `id`, `name`, `description`.
  3. Request includes `Authorization: Bearer <token>` header.

---

### TC-SDK-018: List Workbenches — With Scope / Team Filter
- **Description**: Verify that `client.workbenches.list(scope="team", team_id="...")` passes query parameters correctly.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/workbenches?scope=team&team_id=team-123` to return `200 OK` with one workbench.
  2. Call `client.workbenches.list(scope="team", team_id="team-123")`.
- **Expected Results**:
  1. Request URL contains query string `scope=team&team_id=team-123`.
  2. Returns filtered list.

---

### TC-SDK-019: List Devices — Success
- **Description**: Verify that `client.devices.list()` returns all devices.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/devices` to return list of devices.
  2. Call `client.devices.list()`.
- **Expected Results**:
  1. Returns list of `Device` models.
  2. Each device has `id`, `name`, `driver_type`, `status`.

---

### TC-SDK-020: List Devices — Per Workbench
- **Description**: Verify filtering devices by workbench ID.
- **Priority**: P1
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/devices?workbench_id=wb-1` to return filtered list.
  2. Call `client.devices.list(workbench_id="wb-1")`.
- **Expected Results**:
  1. Query parameter `workbench_id=wb-1` is present in the request URL.
  2. Returns only devices belonging to that workbench.

---

### TC-SDK-021: List Methods — Success
- **Description**: Verify that `client.methods.list()` returns all methods.
- **Priority**: P1
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/methods` to return list of methods.
  2. Call `client.methods.list()`.
- **Expected Results**:
  1. Returns list of `Method` models with `id`, `name`, `steps`.

---

### TC-SDK-022: List Experiments — Success
- **Description**: Verify that `client.experiments.list()` returns experiments.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments` to return list of experiments.
  2. Call `client.experiments.list()`.
- **Expected Results**:
  1. Returns list of `Experiment` models.
  2. Each experiment has `id`, `name`, `status`, `created_at`.

---

### TC-SDK-023: List Experiments — With Status Filter
- **Description**: Verify filtering experiments by status.
- **Priority**: P1
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments?status=running` to return only running experiments.
  2. Call `client.experiments.list(status="running")`.
- **Expected Results**:
  1. Query parameter `status=running` is present.
  2. Returns filtered results.

---

### TC-SDK-024: Get Experiment Details — Success
- **Description**: Verify `client.experiments.get(id)` returns a single experiment with full details.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments/exp-123` to return:
     ```json
     {
       "code": 200,
       "data": {
         "id": "exp-123",
         "name": "Temperature Test",
         "status": "completed",
         "workbench_id": "wb-1",
         "method_id": "method-1",
         "created_at": "2026-05-01T00:00:00Z",
         "updated_at": "2026-05-01T01:00:00Z"
       }
     }
     ```
  2. Call `client.experiments.get("exp-123")`.
- **Expected Results**:
  1. Returns `Experiment` model with all fields populated.
  2. `id` matches the requested UUID.

---

### TC-SDK-025: Get Experiment Details — Not Found
- **Description**: Verify that requesting a non-existent experiment raises `NotFoundError`.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments/does-not-exist` to return `404`.
  2. Call `client.experiments.get("does-not-exist")`.
- **Expected Results**:
  1. Raises `kayak.NotFoundError`.
  2. Exception message contains the experiment ID or "not found".

---

### TC-SDK-026: List Resources — Unauthenticated Request
- **Description**: Verify that calling resource APIs without login raises `AuthenticationError`.
- **Priority**: P0
- **Test Type**: Unit
- **Preconditions**:
  1. `KayakClient` instantiated but not logged in.
- **Steps**:
  1. Call `client.workbenches.list()`.
- **Expected Results**:
  1. Raises `kayak.AuthenticationError` before sending HTTP request.
  2. Or sends request without token, receives `401`, and raises `AuthenticationError`.

---

## 5. Data Download

### TC-SDK-027: Download Experiment Data — HDF5 File Integrity
- **Description**: Verify that `client.data.download(experiment_id)` downloads a valid HDF5 file.
- **Priority**: P0
- **Test Type**: Integration (mocked HTTP + file I/O)
- **Preconditions**:
  1. Client is authenticated.
  2. A valid HDF5 file is available as mock response body.
- **Steps**:
  1. Create a temporary HDF5 file with known dataset structure (e.g., `/points/temperature/values`).
  2. Mock `GET /api/v1/experiments/exp-123/data/download` to return the file bytes with `Content-Type: application/octet-stream`.
  3. Call `data = client.data.download("exp-123")`.
- **Expected Results**:
  1. Returns a `DataDownload` (or similar) object.
  2. The underlying file/stream is a valid HDF5 readable by `h5py`.
  3. File size matches the mock response.
- **Mock Requirements**:
  - `pytest-httpx` to return binary response.
  - `tmp_path` fixture for file operations.

---

### TC-SDK-028: Download Experiment Data — With Time Range Filter
- **Description**: Verify that time range parameters are passed to the download endpoint.
- **Priority**: P1
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments/exp-123/data/download?start_time=2026-05-01T00:00:00Z&end_time=2026-05-01T23:59:59Z` to return `200 OK`.
  2. Call:
     ```python
     client.data.download(
         "exp-123",
         start_time="2026-05-01T00:00:00Z",
         end_time="2026-05-01T23:59:59Z"
     )
     ```
- **Expected Results**:
  1. Request URL contains `start_time` and `end_time` query parameters.
  2. Response is handled correctly.

---

### TC-SDK-029: Download Experiment Data — Save to Local Path
- **Description**: Verify `data.save(path)` writes the HDF5 file to disk.
- **Priority**: P0
- **Test Type**: Integration (mocked HTTP + file I/O)
- **Preconditions**:
  1. Client is authenticated.
  2. Download mock returns HDF5 bytes.
- **Steps**:
  1. Mock download endpoint with HDF5 bytes.
  2. Call `data = client.data.download("exp-123")`.
  3. Call `data.save("/tmp/exp-123.h5")`.
- **Expected Results**:
  1. File `/tmp/exp-123.h5` exists.
  2. File is a valid HDF5 (can be opened with `h5py.File`).
  3. File contents match the mock response bytes.

---

### TC-SDK-030: Download Experiment Data — Experiment Not Found
- **Description**: Verify that downloading data for a non-existent experiment raises `NotFoundError`.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments/does-not-exist/data/download` to return `404`.
  2. Call `client.data.download("does-not-exist")`.
- **Expected Results**:
  1. Raises `kayak.NotFoundError`.

---

### TC-SDK-031: Download Experiment Data — Experiment Still Running
- **Description**: Verify that downloading data for a running experiment raises an appropriate error (409 Conflict per backend spec).
- **Priority**: P1
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments/exp-running/data/download` to return `409 Conflict`.
  2. Call `client.data.download("exp-running")`.
- **Expected Results**:
  1. Raises `kayak.ServerError` (or dedicated error) with message indicating experiment is still running.

---

## 6. Data Conversion (HDF5 → DataFrame / ndarray)

### TC-SDK-032: Convert to pandas DataFrame — Success
- **Description**: Verify `data.to_dataframe()` returns a pandas DataFrame with correct structure.
- **Priority**: P0
- **Test Type**: Integration (mocked HTTP + data conversion)
- **Preconditions**:
  1. Client is authenticated.
  2. Downloaded HDF5 contains multiple point datasets with timestamps and values.
- **Steps**:
  1. Mock download endpoint with an HDF5 file containing:
     - `/points/temperature/timestamps` → [1714521600000, 1714521601000]
     - `/points/temperature/values` → [25.3, 25.4]
     - `/points/pressure/timestamps` → [1714521600000, 1714521601000]
     - `/points/pressure/values` → [101.3, 101.4]
  2. Call `data = client.data.download("exp-123")`.
  3. Call `df = data.to_dataframe()`.
- **Expected Results**:
  1. `df` is an instance of `pandas.DataFrame`.
  2. Columns include `timestamp`, `temperature`, `pressure`.
  3. Row count equals the number of unique timestamps (2).
  4. Values match the mock data.
- **Mock Requirements**:
  - `pytest-httpx` for binary response.
  - `pandas` must be installed.

---

### TC-SDK-033: Convert to pandas DataFrame — Missing Optional Dependency
- **Description**: Verify graceful error when `pandas` is not installed.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. `pandas` is unimportable (mocked import failure).
- **Steps**:
  1. Mock `import pandas` to raise `ImportError`.
  2. Call `data.to_dataframe()`.
- **Expected Results**:
  1. Raises `ImportError` with helpful message: "pandas is required for to_dataframe(). Install with: pip install kayak[pandas]".

---

### TC-SDK-034: Convert to numpy ndarray — Success
- **Description**: Verify `data.to_numpy()` returns a numpy ndarray.
- **Priority**: P0
- **Test Type**: Integration (mocked HTTP + data conversion)
- **Preconditions**:
  1. Client is authenticated.
  2. Downloaded HDF5 contains point datasets.
- **Steps**:
  1. Mock download endpoint with HDF5 file (same structure as TC-SDK-032).
  2. Call `data = client.data.download("exp-123")`.
  3. Call `arr = data.to_numpy()`.
- **Expected Results**:
  1. `arr` is an instance of `numpy.ndarray`.
  2. Shape matches `(samples, points)` or similar documented shape.
  3. Values match mock data.

---

### TC-SDK-035: Convert to numpy ndarray — Missing Optional Dependency
- **Description**: Verify graceful error when `numpy` is not installed.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. `numpy` is unimportable (mocked import failure).
- **Steps**:
  1. Mock `import numpy` to raise `ImportError`.
  2. Call `data.to_numpy()`.
- **Expected Results**:
  1. Raises `ImportError` with helpful message: "numpy is required for to_numpy(). Install with: pip install kayak[numpy]".

---

### TC-SDK-036: Data Conversion — Empty HDF5 (No Points)
- **Description**: Verify behavior when the downloaded HDF5 contains no measurement points.
- **Priority**: P1
- **Test Type**: Integration (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock download endpoint with an HDF5 file that has no `/points` group.
  2. Call `data = client.data.download("exp-123")`.
  3. Call `df = data.to_dataframe()` and `arr = data.to_numpy()`.
- **Expected Results**:
  1. Both methods return empty structures:
     - `df` is an empty DataFrame with expected columns (or fully empty).
     - `arr` is an empty ndarray with shape `(0,)` or documented empty shape.
  2. No exception raised.

---

### TC-SDK-037: Data Conversion — Single Point Dataset
- **Description**: Verify conversion works with only one measurement point in the HDF5.
- **Priority**: P1
- **Test Type**: Integration (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock download endpoint with HDF5 containing only `/points/temperature`.
  2. Call `data = client.data.download("exp-123")`.
  3. Call `df = data.to_dataframe()`.
- **Expected Results**:
  1. `df` has columns `['timestamp', 'temperature']`.
  2. Data values are correct.

---

## 7. Error Handling & HTTP Status Mapping

### TC-SDK-038: AuthenticationError — 401 on Any API Call
- **Description**: Verify that any `401 Unauthorized` response raises `AuthenticationError`.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated (token stored).
- **Steps**:
  1. Mock `GET /api/v1/workbenches` to return `401` (token revoked on server side).
  2. Call `client.workbenches.list()`.
- **Expected Results**:
  1. Raises `kayak.AuthenticationError`.
  2. Exception contains HTTP status code `401`.

---

### TC-SDK-039: NotFoundError — 404 on Any API Call
- **Description**: Verify that `404 Not Found` raises `NotFoundError`.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/devices/no-such-device` to return `404`.
  2. Call `client.devices.get("no-such-device")`.
- **Expected Results**:
  1. Raises `kayak.NotFoundError`.
  2. Exception contains HTTP status code `404`.

---

### TC-SDK-040: ServerError — 5xx Responses
- **Description**: Verify that `500`, `502`, `503` raise `ServerError`.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments` to return `500 Internal Server Error`.
  2. Call `client.experiments.list()`.
  3. Repeat for `502` and `503`.
- **Expected Results**:
  1. Each call raises `kayak.ServerError`.
  2. Exception contains the respective HTTP status code.

---

### TC-SDK-041: ConnectionError — Network Failure
- **Description**: Verify that network-level failures raise `ConnectionError`.
- **Priority**: P0
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/workbenches` to raise `httpx.ConnectTimeout`.
  2. Call `client.workbenches.list()`.
  3. Repeat with `httpx.NetworkError`.
- **Expected Results**:
  1. Each call raises `kayak.ConnectionError`.
  2. Original exception is chained via `__cause__`.

---

### TC-SDK-042: ValidationError — 422 Response
- **Description**: Verify that `422 Unprocessable Entity` raises `ValidationError`.
- **Priority**: P1
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `POST /api/v1/teams` to return `422` with validation errors (if SDK supports POST).
  2. Or mock `GET /api/v1/experiments?status=invalid` to return `422`.
- **Expected Results**:
  1. Raises `kayak.ValidationError`.
  2. Exception contains server-provided validation messages.

---

### TC-SDK-043: Unknown 4xx Error — Fallback to KayakError
- **Description**: Verify that unmapped 4xx errors (e.g., `409 Conflict`, `410 Gone`) raise the base `KayakError`.
- **Priority**: P2
- **Test Type**: Unit (mocked HTTP)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/experiments/exp-123/data/download` to return `409`.
  2. Call `client.data.download("exp-123")`.
- **Expected Results**:
  1. Raises `kayak.KayakError` (base class).
  2. Exception contains HTTP status code `409` and server message.

---

## 8. Invalid Input Validation

### TC-SDK-044: Invalid Base URL — Missing Scheme
- **Description**: Verify that a base URL without `http://` or `https://` is rejected at initialization.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. None.
- **Steps**:
  1. Call `KayakClient(base_url="localhost:8080")`.
- **Expected Results**:
  1. Raises `kayak.ValidationError` (or `ValueError`) with message indicating URL must include scheme.

---

### TC-SDK-045: Invalid Base URL — Malformed URL
- **Description**: Verify that completely malformed URLs are rejected.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. None.
- **Steps**:
  1. Call `KayakClient(base_url="not a url !!!")`.
- **Expected Results**:
  1. Raises `kayak.ValidationError`.

---

### TC-SDK-046: Invalid UUID Format in Resource APIs
- **Description**: Verify that invalid UUID strings are rejected locally before making HTTP requests.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Call `client.experiments.get("not-a-uuid")`.
  2. Call `client.devices.get("12345")`.
  3. Call `client.data.download("")`.
- **Expected Results**:
  1. Each call raises `kayak.ValidationError` (or `ValueError`).
  2. No HTTP request is sent for invalid inputs.

---

### TC-SDK-047: Invalid Time Range — End Before Start
- **Description**: Verify that `start_time > end_time` in data download is rejected locally.
- **Priority**: P1
- **Test Type**: Unit
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Call:
     ```python
     client.data.download(
         "exp-123",
         start_time="2026-05-02T00:00:00Z",
         end_time="2026-05-01T00:00:00Z"
     )
     ```
- **Expected Results**:
  1. Raises `kayak.ValidationError`.
  2. No HTTP request is sent.

---

### TC-SDK-048: Invalid Email Format in Login
- **Description**: Verify that login with malformed email raises validation error.
- **Priority**: P2
- **Test Type**: Unit
- **Preconditions**:
  1. `KayakClient` instantiated.
- **Steps**:
  1. Call `client.login("not-an-email", "password123")`.
- **Expected Results**:
  1. Raises `kayak.ValidationError` (or `ValueError`).
  2. No HTTP request is sent.

---

### TC-SDK-049: Extra / Unexpected Keyword Arguments
- **Description**: Verify that unknown kwargs to SDK methods raise `TypeError`.
- **Priority**: P2
- **Test Type**: Unit
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Call `client.workbenches.list(unknown_param="value")`.
- **Expected Results**:
  1. Raises `TypeError` indicating unexpected keyword argument.

---

## 9. Concurrent Usage & Thread Safety

### TC-SDK-050: Concurrent API Calls from Multiple Threads
- **Description**: Verify that multiple threads can safely call API methods on the same `KayakClient` instance.
- **Priority**: P1
- **Test Type**: Integration (mocked HTTP + threading)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Mock `GET /api/v1/workbenches` and `GET /api/v1/experiments` to return successful responses after a small delay.
  2. Start 5 threads, each calling a different API method on the same client instance.
  3. Wait for all threads to complete.
- **Expected Results**:
  1. All 5 calls succeed without exceptions.
  2. No race conditions in token state (if token is shared read-only after auth).
  3. No `httpx` client state corruption.
- **Mock Requirements**:
  - `pytest-httpx` with concurrent response handling.
  - `threading.Thread` or `concurrent.futures.ThreadPoolExecutor`.

---

### TC-SDK-051: Token Refresh During Concurrent Requests
- **Description**: Verify that a token refresh triggered by one thread does not cause other threads to fail.
- **Priority**: P1
- **Test Type**: Integration (mocked HTTP + threading + time manipulation)
- **Preconditions**:
  1. Client is authenticated with a token expiring in 3 minutes.
- **Steps**:
  1. Mock `POST /api/v1/auth/refresh` to return new token after 100ms delay.
  2. Mock `GET /api/v1/workbenches` to return `200` (may receive old or new token).
  3. Start 3 threads simultaneously calling `client.workbenches.list()`.
- **Expected Results**:
  1. Only one `POST /api/v1/auth/refresh` request is made (refresh is synchronized).
  2. All 3 API calls eventually succeed (either with old valid token or after waiting for refresh).
  3. No `AuthenticationError` is raised due to race condition.
- **Mock Requirements**:
  - `freezegun` to control token expiry.
  - Thread-safe mock server or `pytest-httpx` with ordered responses.

---

### TC-SDK-052: Concurrent Login Attempts
- **Description**: Verify that concurrent login calls on the same client instance are handled safely.
- **Priority**: P2
- **Test Type**: Unit (mocked HTTP + threading)
- **Preconditions**:
  1. `KayakClient` instantiated but not logged in.
- **Steps**:
  1. Mock `POST /api/v1/auth/login` to return valid token.
  2. Start 2 threads both calling `client.login("admin@kayak.local", "Admin123")`.
- **Expected Results**:
  1. At least one login succeeds.
  2. Token state is consistent (not partially written).
  3. No unhandled exceptions.

---

## 10. Session Persistence

### TC-SDK-053: Session Persistence — Save and Restore Tokens
- **Description**: Verify that tokens can be saved to disk and restored in a new `KayakClient` instance.
- **Priority**: P1
- **Test Type**: Integration (file I/O)
- **Preconditions**:
  1. Client is authenticated.
- **Steps**:
  1. Call `client.auth.save_session("/tmp/kayak_session.json")`.
  2. Create new client: `client2 = KayakClient(base_url="http://localhost:8080")`.
  3. Call `client2.auth.load_session("/tmp/kayak_session.json")`.
  4. Call `client2.workbenches.list()` with mocked backend.
- **Expected Results**:
  1. Session file `/tmp/kayak_session.json` exists and contains access_token, refresh_token, expires_at.
  2. `client2` is authenticated without calling `login()`.
  3. `client2.workbenches.list()` succeeds using the restored token.
- **Mock Requirements**:
  - `tmp_path` fixture for session file.
  - `pytest-httpx` to verify restored token is used.

---

### TC-SDK-054: Session Persistence — Restore Expired Session
- **Description**: Verify that loading an expired session triggers automatic refresh on first API call.
- **Priority**: P1
- **Test Type**: Integration (file I/O + time manipulation)
- **Preconditions**:
  1. A session file contains tokens that expired 1 hour ago.
- **Steps**:
  1. Create a session file with `expires_at` in the past.
  2. Load session into new client.
  3. Mock `POST /api/v1/auth/refresh` to return new valid token.
  4. Mock `GET /api/v1/workbenches` to return `200`.
  5. Call `client.workbenches.list()`.
- **Expected Results**:
  1. `POST /api/v1/auth/refresh` is called automatically before `GET /api/v1/workbenches`.
  2. API call succeeds with new token.

---

### TC-SDK-055: Session Persistence — Corrupted Session File
- **Description**: Verify that loading a corrupted or invalid session file raises an error.
- **Priority**: P1
- **Test Type**: Unit (file I/O)
- **Preconditions**:
  1. A session file exists but contains invalid JSON.
- **Steps**:
  1. Write `"not json"` to `/tmp/bad_session.json`.
  2. Call `client.auth.load_session("/tmp/bad_session.json")`.
- **Expected Results**:
  1. Raises `kayak.ValidationError` (or `json.JSONDecodeError`).
  2. Client remains unauthenticated.

---

### TC-SDK-056: Session Persistence — Missing Session File
- **Description**: Verify that loading a non-existent session file raises an error.
- **Priority**: P2
- **Test Type**: Unit
- **Preconditions**:
  1. File `/tmp/nonexistent_session.json` does not exist.
- **Steps**:
  1. Call `client.auth.load_session("/tmp/nonexistent_session.json")`.
- **Expected Results**:
  1. Raises `FileNotFoundError`.
  2. Client remains unauthenticated.

---

## 11. Traceability Matrix

| Feature Area | Test Cases | Priority Coverage | PRD Reference |
|--------------|------------|-------------------|---------------|
| **1. Login/logout flow** | TC-SDK-001 ~ TC-SDK-006 | P0 × 4, P1 × 2 | PRD §2.4.3, §2.4.4 |
| **2. Token refresh** | TC-SDK-007 ~ TC-SDK-012 | P0 × 4, P1 × 2 | PRD §2.4.3, §3.2 |
| **3. Context manager behavior** | TC-SDK-013 ~ TC-SDK-016 | P0 × 2, P1 × 2 | PRD §2.4.3 |
| **4. Resource listing** | TC-SDK-017 ~ TC-SDK-026 | P0 × 6, P1 × 3 | PRD §2.4.3 |
| **5. Data download** | TC-SDK-027 ~ TC-SDK-031 | P0 × 3, P1 × 2 | PRD §2.4.3 |
| **6. Data conversion** | TC-SDK-032 ~ TC-SDK-037 | P0 × 2, P1 × 4 | PRD §2.4.3, §2.4.5 |
| **7. Error handling** | TC-SDK-038 ~ TC-SDK-043 | P0 × 4, P1 × 1, P2 × 1 | PRD §2.4.4 |
| **8. Invalid input validation** | TC-SDK-044 ~ TC-SDK-049 | P1 × 4, P2 × 2 | PRD §2.4.3 |
| **9. Concurrent usage** | TC-SDK-050 ~ TC-SDK-052 | P1 × 2, P2 × 1 | PRD §3.2, §3.4 |
| **10. Session persistence** | TC-SDK-053 ~ TC-SDK-056 | P1 × 3, P2 × 1 | PRD §2.4.3 |

### Coverage Verification

| # | Required Feature Area | Covered By | Status |
|---|-----------------------|------------|--------|
| 1 | Login/logout flow | TC-SDK-001 ~ 006 | ✅ 6 test cases |
| 2 | Token refresh (automatic and manual) | TC-SDK-007 ~ 012 | ✅ 6 test cases |
| 3 | Context manager behavior | TC-SDK-013 ~ 016 | ✅ 4 test cases |
| 4 | Resource listing (workbenches, experiments) | TC-SDK-017 ~ 026 | ✅ 10 test cases |
| 5 | Data download (HDF5 file integrity) | TC-SDK-027 ~ 031 | ✅ 5 test cases |
| 6 | Data conversion (HDF5 → DataFrame, HDF5 → ndarray) | TC-SDK-032 ~ 037 | ✅ 6 test cases |
| 7 | Error handling (401, 404, 500, connection errors) | TC-SDK-038 ~ 043 | ✅ 6 test cases |
| 8 | Invalid input validation | TC-SDK-044 ~ 049 | ✅ 6 test cases |
| 9 | Concurrent usage (thread safety) | TC-SDK-050 ~ 052 | ✅ 3 test cases |
| 10 | Session persistence | TC-SDK-053 ~ 056 | ✅ 4 test cases |

**Total**: 56 test cases | **P0**: 23 | **P1**: 24 | **P2**: 9

### Mock & Dependency Summary

| Dependency | Purpose | Test Cases |
|------------|---------|------------|
| `pytest` | Test framework | All |
| `pytest-httpx` | HTTP request/response mocking | TC-SDK-001~005, 007~043, 050~052 |
| `freezegun` | Time manipulation for token expiry | TC-SDK-007, 051, 054 |
| `tmp_path` (pytest built-in) | Temporary file I/O | TC-SDK-027, 029, 053~056 |
| `h5py` | HDF5 file creation/validation | TC-SDK-027, 029, 032, 034, 036, 037 |
| `pandas` | DataFrame conversion validation | TC-SDK-032, 033, 036, 037 |
| `numpy` | ndarray conversion validation | TC-SDK-034, 035, 036, 037 |
| `threading` / `concurrent.futures` | Concurrent execution | TC-SDK-050~052 |

---

*End of Document*
