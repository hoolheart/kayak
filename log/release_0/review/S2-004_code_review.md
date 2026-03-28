# S2-004 Code Review: Experiment Query API

**Branch:** `feature/S2-004-experiment-query-api`  
**Review Date:** 2026-03-28  
**Reviewer:** sw-jerry (Software Architect)

---

## Executive Summary

The implementation demonstrates good architectural discipline with proper layered separation (API → Service → Repository) and follows Interface-Driven Development principles. However, there are several issues ranging from **architectural violations** to **misleading error handling** that should be addressed before integration.

**Overall Assessment:** ⚠️ **Needs Revision** (7 issues, 2 critical)

---

## 1. Architecture Review

### 1.1 Separation of Concerns ✅

| Layer | Component | Assessment |
|-------|-----------|------------|
| API Handlers | `experiment.rs` | ✅ Handles HTTP extractors/responses |
| Service | `experiment_query/service.rs` | ✅ Defines business contracts via trait |
| Repository | `point_history/repository.rs` | ✅ Abstracts HDF5 data access |
| DTOs | `experiment_query.rs` | ✅ Clean data transfer objects |

### 1.2 Dependency Inversion ⚠️ **VIOLATION**

**Issue:** Handlers depend on **concrete implementation**, not interface.

**Location:** `experiment.rs:84`
```rust
let repo = Hdf5PointHistoryRepository::new(state.data_root.clone());
```

**Problem:** Per DIP, handlers should depend on `PointHistoryRepository` trait, not `Hdf5PointHistoryRepository`. This creates tight coupling and makes testing difficult.

**Recommendation:** Accept repository via state or constructor injection:
```rust
pub struct ExperimentState {
    pub data_root: PathBuf,
    pub point_history_repo: Arc<dyn PointHistoryRepository>,  // Add trait object
}
```

---

## 2. Code Quality Issues

### 2.1 Misleading Error in `download_data_file` ⚠️ **CRITICAL**

**Location:** `experiment.rs:136-139`
```rust
Err(PointHistoryError::Hdf5FileNotFound(
    "Streaming download not implemented".to_string(),
))
```

**Problem:** Returns `Hdf5FileNotFound` error with message "Streaming download not implemented" — this is semantically wrong. If the file exists but streaming isn't implemented, this should be a distinct error variant like `StreamingNotImplemented`.

**Recommendation:** Add new error variant or use `Internal`:
```rust
// In error.rs
#[error("流式传输未实现")]
StreamingNotImplemented,
```

---

### 2.2 Timestamp Unit Mismatch Potential ⚠️ **HIGH**

**Location:** `point_history/repository.rs:113-118`
```rust
let dt = Utc.timestamp_opt(nanos / 1_000_000_000, (nanos % 1_000_000_000) as u32)
    .single();
match (dt, &time_range) {
    (Some(dt), Some(range)) => dt >= range.start && dt <= range.end,
    _ => true,
}
```

**Problem:** HDF5 stores timestamps as nanoseconds (i64), `TimeRange` stores `DateTime<Utc>` (seconds precision). The division `/ 1_000_000_000` converts nanoseconds → seconds correctly. However, the filtering happens **after** reading all data into memory, which is inefficient for large files.

**Additional Issue:** Line 100-105 uses `read_raw()` which loads **entire dataset** into memory. For large HDF5 files (millions of points), this could cause OOM.

**Recommendation:** 
1. Consider HDF5 slicing for time-range queries at storage level
2. Document nanosecond timestamp assumption clearly

---

### 2.3 Missing User Context Propagation ⚠️ **MEDIUM**

**Location:** `experiment.rs:62-113`

**Problem:** Service trait accepts `user_id: Uuid` for authorization checks, but handlers don't extract or pass user context:

```rust
// Service signature expects user_id
async fn get_point_history(&self, experiment_id: Uuid, channel: String, 
    time_range: Option<TimeRange>, limit: usize, user_id: Uuid) -> Result<...>

// Handler doesn't pass user_id
let points = repo.get_channel_data(exp_id, &channel, time_range.clone(), limit).await?;
```

**Impact:** Authorization cannot work; all queries are effectively unauthenticated.

---

### 2.4 Empty Response for Unimplemented Endpoints ⚠️ **LOW**

**Location:** `experiment.rs:34-51`
```rust
pub async fn list_experiments(...) -> Result<Json<PagedResponse<Experiment>>, ...> {
    // TODO: Implement with actual experiment repository
    // For now, return empty list
    Ok(Json(PagedResponse { items: vec![], ... }))
}
```

**Problem:** Returns HTTP 200 with empty data instead of 501 Not Implemented or at least a warning log.

**Recommendation:** Return explicit 501 or log a warning for incomplete implementation.

---

## 3. Error Handling Review

### 3.1 Error Types ✅

| Error Type | Coverage | Assessment |
|------------|----------|------------|
| `ExperimentQueryError` | NotFound, AccessDenied, InvalidPagination, InvalidQuery, DatabaseError, Internal | ✅ Comprehensive |
| `PointHistoryError` | ExperimentNotFound, ChannelNotFound, Hdf5FileNotFound, Hdf5ReadError, InvalidTimeRange, TimeRangeReversed, DataTooLarge | ✅ Well structured |
| `DataFileError` | ExperimentNotFound, AccessDenied, DataFileNotFound, FileReadError, FileTooLarge | ✅ Complete |

### 3.2 Error Messages (Chinese) ✅

All user-facing error messages use Chinese with clear meanings:
- `试验不存在` (Experiment not found)
- `无权限访问该试验` (Access denied)
- `HDF5文件不存在` (HDF5 file not found)

---

## 4. Integration Readiness

### 4.1 Handler Integration Points ✅

| Handler | Status | Notes |
|---------|--------|-------|
| `get_point_history` | ✅ Functional | Works with HDF5 repository |
| `list_experiments` | ⚠️ Returns empty | Needs `ExperimentRepository` integration |
| `get_experiment` | ⚠️ Returns 501 | Needs `ExperimentRepository` integration |
| `download_data_file` | ⚠️ Broken | Streaming not implemented |

### 4.2 Service Trait Contract ✅

The `ExperimentQueryService` trait is well-designed with clear method signatures. When concrete implementations are added, they should integrate cleanly.

---

## 5. Summary of Issues

| Priority | Issue | Location |
|----------|-------|----------|
| 🔴 Critical | Handler depends on concrete `Hdf5PointHistoryRepository` instead of trait | `experiment.rs:84` |
| 🔴 Critical | Misleading error in `download_data_file` | `experiment.rs:136-139` |
| 🟡 High | Timestamp filtering after full memory load (OOM risk) | `repository.rs:107-125` |
| 🟡 Medium | Missing user context propagation (auth broken) | `experiment.rs` handlers |
| 🟢 Low | Empty response instead of 501 for unimplemented | `experiment.rs:34-51` |
| 🟢 Low | No logging for incomplete implementations | Throughout handlers |

---

## 6. Recommendations

### Must Fix Before Integration:
1. **Inject repository via state** - Change `ExperimentState` to hold `Arc<dyn PointHistoryRepository>`
2. **Fix `download_data_file` error** - Add `StreamingNotImplemented` variant or use `Internal`

### Should Fix Before Production:
3. **Implement user context extraction** - Add auth middleware to extract user_id
4. **Consider streaming reads** - For large HDF5 files, use HDF5 slicing instead of `read_raw()`

### Nice to Have:
5. **Add 501 responses** - For explicitly unimplemented endpoints
6. **Add instrumentation** - Log when unimplemented code paths are hit

---

## 7. Files Reviewed

| File | Lines | Assessment |
|------|-------|------------|
| `api/handlers/experiment.rs` | 140 | ⚠️ Needs revision |
| `services/experiment_query/mod.rs` | 9 | ✅ Good module structure |
| `services/experiment_query/service.rs` | 56 | ✅ Clean trait definition |
| `services/experiment_query/error.rs` | 70 | ✅ Comprehensive errors |
| `services/experiment_query/types.rs` | 16 | ✅ Simple and clear |
| `services/point_history/mod.rs` | 7 | ✅ Good module structure |
| `services/point_history/repository.rs` | 229 | ⚠️ Works, needs optimization |
| `services/point_history/types.rs` | 11 | ✅ Simple and clear |
| `models/dto/experiment_query.rs` | 77 | ✅ Clean DTOs |

---

*Review stored at: `log/release_0/review/S2-004_code_review.md`*
