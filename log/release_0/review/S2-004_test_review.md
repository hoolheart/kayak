# S2-004 测试用例审查报告

**审查日期**: 2026-03-28  
**任务**: S2-004 试验数据查询API (Experiment Data Query API)  
**审查人**: sw-tom  
**状态**: **NEEDS REVISION**

---

## 1. 审查概要

| 审查项 | 结果 | 说明 |
|--------|------|------|
| 验收标准覆盖完整性 | ⚠️ 部分缺失 | 覆盖充分但存在无效测试 |
| 测试用例可执行性 | ❌ 存在问题 | 多个测试依赖未定义的API/辅助函数 |
| 测试用例结构 | ✅ 良好 | 代码结构清晰，命名规范 |
| 与架构对齐 | ⚠️ 需确认 | API端点存在不一致 |

**总计测试用例**: 36个  
**建议通过**: 28个  
**需修订**: 8个

---

## 2. 验收标准覆盖分析

### AC1: GET /api/v1/points/{id}/history 支持时间过滤 ✅

| 测试用例 | 覆盖内容 | 状态 |
|----------|----------|------|
| TC-HIST-001 | 基本查询 | ✅ |
| TC-HIST-002 | 时间范围过滤 | ✅ |
| TC-HIST-003 | 完整时间范围 | ⚠️ 断言无效 |
| TC-HIST-004 | 无效时间格式 | ✅ |
| TC-HIST-005 | 时间范围倒置 | ✅ |
| TC-HIST-006 | 不存在的测点ID | ✅ |
| TC-HIST-007 | 响应数据结构验证 | ✅ |
| TC-HIST-008 | 空数据范围 | ✅ |
| TC-HIST-009 | 分页支持 | ⚠️ API未定义分页参数 |
| TC-HIST-010 | 多通道数据 | ✅ |

### AC2: 试验列表支持分页 ✅

| 测试用例 | 覆盖内容 | 状态 |
|----------|----------|------|
| TC-EXP-API-001 | 默认分页 | ✅ |
| TC-EXP-API-002 | 自定义分页参数 | ✅ |
| TC-EXP-API-003 | 最后一页 | ✅ |
| TC-EXP-API-004 | 空列表 | ✅ |
| TC-EXP-API-005 | 无效分页参数 | ✅ |
| TC-EXP-API-006 | 按状态筛选 | ✅ |
| TC-EXP-API-007 | 按时间范围筛选 | ⚠️ 断言过弱 |
| TC-EXP-API-008 | 组合筛选 | ✅ |
| TC-EXP-API-009 | 排序验证 | ✅ |
| TC-EXP-API-010 | 响应结构验证 | ✅ |

### AC3: 数据文件可下载 ⚠️

| 测试用例 | 覆盖内容 | 状态 |
|----------|----------|------|
| TC-DOWN-001 | 有效试验ID下载 | ✅ |
| TC-DOWN-002 | 不存在的试验 | ✅ |
| TC-DOWN-003 | 无关联数据文件 | ✅ |
| TC-DOWN-004 | 文件完整性验证 | ❌ 依赖未定义API |
| TC-DOWN-005 | 文件大小验证 | ❌ 依赖未定义API |
| TC-DOWN-006 | 无效试验ID格式 | ✅ |
| TC-DOWN-007 | 并发下载 | ✅ |
| TC-DOWN-008 | Streaming下载 | ⚠️ 断言过弱 |

---

## 3. 问题详细分析

### P0 - 必须修复（阻止实施）

#### 问题 1: TC-DOWN-004 & TC-DOWN-005 依赖未定义的 `/data-file/metadata` API

**影响的测试用例**: TC-DOWN-004, TC-DOWN-005

**问题描述**:
```rust
// TC-DOWN-004: 文件完整性验证
let metadata_response = app.get(&format!(
    "/api/v1/experiments/{}/data-file/metadata",  // ❌ 此API未在arch.md中定义
    experiment_id
))
.await;
```

**架构对照**:
arch.md 第661-667行定义的 Data File API:
```
GET    /api/v1/data-files
GET    /api/v1/data-files/{id}
GET    /api/v1/data-files/{id}/download
DELETE /api/v1/data-files/{id}
```

测试用例使用的端点是 `/api/v1/experiments/{id}/data-file/metadata`，与架构定义的 `/api/v1/data-files/{id}` 路径不一致。

**建议修复**:
1. 如果 metadata 端点需要实现，则应添加到架构文档
2. 如果使用现有 `/api/v1/data-files/{id}` 端点获取metadata，则需调整测试
3. 明确是否需要在 Experiment API 中暴露 data-file metadata

**相关问题**: `calculate_sha256` 辅助函数未定义

---

### P1 - 应该修复（影响测试质量）

#### 问题 2: TC-EXP-API-007 时间范围筛选断言过弱

**测试用例**: TC-EXP-API-007

**当前代码**:
```rust
// 筛选创建时间在 earlier 之后的试验
let response = app.get(&format!(
    "/api/v1/experiments?created_after={}",
    earlier.to_rfc3339()
))
.await;

// ❌ 断言太弱，只验证 >= 1
assert!(body.total_items >= 1);
```

**问题**: 断言 `body.total_items >= 1` 几乎总是成立，无法有效验证时间过滤功能。

**建议修复**:
```rust
// 应该验证 exp2 肯定在结果中，exp1 可能在其中
assert!(body.items.iter().any(|e| e.id == exp2.id));

// 如果 earlier 足够接近现在，exp1 可能已经不在结果中
// 或者明确验证结果数量
let count_before = /* 计算 earlier 之前创建的试验数量 */;
assert_eq!(body.total_items, 1); // 只有 exp2
```

---

#### 问题 3: TC-HIST-003 使用硬编码日期且断言无效

**测试用例**: TC-HIST-003

**当前代码**:
```rust
let start_time = "2024-01-01T00:00:00Z";
let end_time = "2024-12-31T23:59:59Z";

let response = app.get(&format!(
    "/api/v1/points/{}/history?start_time={}&end_time={}",
    point_id, start_time, end_time
))
.await;

// ❌ 断言永远为真
assert!(history.data.len() >= 0);
```

**问题**:
1. 硬编码的日期 "2024-01-01" 到 "2024-12-31" 与实际测试数据的时间戳无关
2. `data.len() >= 0` 是永真断言，无任何验证意义

**建议修复**:
```rust
// 先获取实际数据的完整时间范围
let full_response = app.get(&format!("/api/v1/points/{}/history", point_id)).await;
let full_history: PointHistoryResponse = full_response.json().await;

// 使用实际时间范围进行测试
let mid_time = DateTime::from_timestamp_millis(
    (full_history.start_time.timestamp_millis() + full_history.end_time.timestamp_millis()) / 2
).unwrap();

let response = app.get(&format!(
    "/api/v1/points/{}/history?start_time={}&end_time={}",
    point_id,
    mid_time.to_rfc3339(),
    full_history.end_time.to_rfc3339()
))
.await;

// 验证返回数据确实在指定范围内
let history: PointHistoryResponse = response.json().await;
assert!(history.data.iter().all(|p| p.timestamp >= mid_time.timestamp_millis() * 1_000_000));
```

---

#### 问题 4: TC-DOWN-008 Streaming测试断言过弱

**测试用例**: TC-DOWN-008

**当前代码**:
```rust
// 验证支持 Range 请求（分段下载）
assert!(
    range_response.status() == StatusCode::PARTIAL_CONTENT || 
    range_response.status() == StatusCode::OK  // ❌ OK 也算通过
);
```

**问题**: 如果大文件下载不支持 Range 请求但返回 200 OK，测试仍会通过。这无法真正验证 Streaming/Random Access 功能。

**建议修复**:
```rust
// 对于大文件，应该验证支持 Range 请求
if file_size > LARGE_FILE_THRESHOLD {
    assert_eq!(
        range_response.status(),
        StatusCode::PARTIAL_CONTENT,
        "Large files should support Range requests for streaming"
    );
    
    // 验证 Content-Range header
    assert!(range_response.headers().contains_key("content-range"));
} else {
    // 小文件可以只返回 200 OK
    assert_eq!(range_response.status(), StatusCode::OK);
}
```

---

#### 问题 5: TC-HIST-009 分页参数与API定义不一致

**测试用例**: TC-HIST-009

**当前代码**:
```rust
let response = app.get(&format!(
    "/api/v1/points/{}/history?page=1&size=100",  // ❌ arch.md未定义page/size参数
    point_id
))
.await;
```

**架构对照**:
arch.md 第634行定义的历史数据API:
```
GET /api/v1/points/{id}/history?start=&end=&limit=
```

测试用例使用 `page=1&size=100`，但架构定义使用 `limit=`。

**建议修复**:
1. 如果分页是需求，则应更新 arch.md 添加分页参数定义
2. 或者使用现有的 `limit=` 参数，并相应调整测试

---

### P2 - 建议改进

#### 问题 6: 测试辅助函数定义不完整

**缺失的辅助函数**:
- `setup_experiment_with_hdf5_data()` - 仅 stub，未实现
- `setup_experiment_with_multiple_channels()` - 仅 stub，未实现
- `setup_experiment_with_large_hdf5_data()` - 仅 stub，未实现
- `setup_broken_hdf5_app()` - 仅 stub，未实现
- `calculate_sha256()` - 未定义

**影响**: 这些缺失会导致测试无法实际执行。

**建议**: 提供完整的测试夹具实现或明确定义每个辅助函数的接口规范。

---

#### 问题 7: API端点路径不一致

**测试用例使用的路径**:
- `/api/v1/experiments/{id}/data-file` (TC-DOWN-001 ~ TC-DOWN-008)

**arch.md 定义的路径**:
- `/api/v1/data-files/{id}/download`

**建议**: 确认实验数据文件下载的正确API路径，并更新测试或架构文档以保持一致。

---

## 4. 测试用例统计

| 类别 | 测试用例 | 建议通过 | 需修订 |
|------|---------|---------|--------|
| 试验列表API | TC-EXP-API-001 ~ 010 | 9 | 1 |
| 试验详情API | TC-EXP-DETAIL-001 ~ 005 | 5 | 0 |
| 测点历史API | TC-HIST-001 ~ 010 | 7 | 3 |
| 数据文件下载API | TC-DOWN-001 ~ 008 | 5 | 3 |
| 错误处理与边界 | TC-ERR-001 ~ 003 | 2 | 1 |
| **总计** | **36** | **28** | **8** |

---

## 5. 审查结论

### 判定结果: **NEEDS REVISION**

### 必须修复项 (P0):
1. **TC-DOWN-004 & TC-DOWN-005**: 依赖未定义的 `/data-file/metadata` API，需明确 API 设计或调整测试

### 应该修复项 (P1):
2. **TC-EXP-API-007**: 断言 `>= 1` 过弱，需验证具体过滤结果
3. **TC-HIST-003**: 硬编码日期与测试数据无关，断言永真
4. **TC-DOWN-008**: 断言允许 OK 通过，无法验证真正的 Streaming 功能
5. **TC-HIST-009**: 使用 `page=1&size=100` 但架构定义使用 `limit=`

### 建议改进项 (P2):
6. 测试辅助函数定义不完整
7. API 端点路径不一致 (`/api/v1/experiments/{id}/data-file` vs `/api/v1/data-files/{id}/download`)

---

## 6. 修复优先级建议

| 优先级 | 问题 | 建议修复方式 |
|--------|------|-------------|
| P0 | TC-DOWN-004/005 API依赖 | 明确 `/data-file/metadata` 是否属于实现范围 |
| P1 | TC-EXP-API-007 断言过弱 | 改为验证具体过滤结果 |
| P1 | TC-HIST-003 日期与断言 | 使用实际数据时间范围，修复断言 |
| P1 | TC-DOWN-008 断言过弱 | 对大文件强制验证 PARTIAL_CONTENT |
| P1 | TC-HIST-009 参数不一致 | 确认分页需求，更新 arch.md 或修改测试 |
| P2 | 辅助函数不完整 | 补充辅助函数实现或接口规范 |
| P2 | 端点路径不一致 | 统一 API 路径定义 |

---

**审查人**: sw-tom  
**审查日期**: 2026-03-28  
**建议**: 请 sw-prod 确认 P0 问题中 `/data-file/metadata` API 是否在实现范围内，以便决定是补充 API 定义还是调整测试用例。
