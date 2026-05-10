# R2-S1-001-A HDF5 时序数据查询 API — 测试用例

**任务**: R2-S1-001-A HDF5 时序数据查询 API 测试用例设计  
**测试设计者**: sw-mike  
**日期**: 2026-05-10  
**被测端点**: `POST /api/v1/experiments/{id}/data/query`  
**被测模块**:
- `kayak-backend/src/api/experiments/data.rs` (handler)
- `kayak-backend/src/services/hdf5_service.rs` (HDF5 读取)
- `kayak-backend/src/services/lttb.rs` (LTTB 降采样)
- `kayak-backend/src/models/data_query.rs` (DTO)

---

## 文档目录

1. [测试数据设计](#一测试数据设计)
2. [LTTB 降采样边界条件说明](#二lttb-降采样边界条件说明)
3. [正常查询场景测试](#三正常查询场景测试)
4. [降采样功能测试](#四降采样功能测试)
5. [边界条件测试](#五边界条件测试)
6. [错误处理测试](#六错误处理测试)
7. [响应格式测试](#七响应格式测试)
8. [性能测试](#八性能测试)
9. [用例汇总表](#九用例汇总表)

---

## 一、测试数据设计

### 1.1 模拟试验数据（HDF5 文件结构）

HDF5 文件路径：`data/experiments/{experiment_id}.h5`

**文件内部数据集结构**（与 Release 1 兼容）：
```
/{device_id}/{point_id}
  - 属性: name="Temperature", unit="°C", data_type="float32"
  - 数据集: compound type { timestamp: i64, value: f32 }
```

### 1.2 测试数据集定义

| 数据集名称 | 试验 ID | 状态 | 设备 ID | 测点 | 数据点数量 | 时间范围 | 数据特征 |
|-----------|---------|------|---------|------|-----------|---------|---------|
| `DS-COMPLETE-001` | `exp-001` | `completed` | `dev-001` | `pt-001` (温度), `pt-002` (压力) | 86,400 | 2026-05-01 00:00:00Z ~ 23:59:59Z | 1秒间隔，正弦波 |
| `DS-COMPLETE-002` | `exp-002` | `completed` | `dev-001` | `pt-003` (流量) | 10 | 2026-05-02 10:00:00Z ~ 10:00:09Z | 1秒间隔，线性递增 |
| `DS-COMPLETE-003` | `exp-003` | `completed` | `dev-002` | `pt-004` (转速) | 100,000 | 2026-05-03 00:00:00Z ~ 27:46:39Z | 1秒间隔，随机噪声 |
| `DS-EMPTY` | `exp-004` | `completed` | `dev-001` | `pt-001` | 0 | — | 空数据集 |
| `DS-SINGLE` | `exp-005` | `completed` | `dev-001` | `pt-001` | 1 | 2026-05-04 12:00:00Z | 单点数据 25.0 |
| `DS-RUNNING` | `exp-006` | `running` | `dev-001` | `pt-001` | 5,000 | 2026-05-05 00:00:00Z ~ 01:23:19Z | 1秒间隔 |
| `DS-ERROR` | `exp-007` | `error` | `dev-001` | `pt-001` | 1,000 | 2026-05-06 00:00:00Z ~ 00:16:39Z | 1秒间隔 |
| `DS-OTHER-USER` | `exp-008` | `completed` | `dev-001` | `pt-001` | 100 | — | 属于其他用户 |

### 1.3 数据生成公式（用于验证返回值）

**`DS-COMPLETE-001` — 温度测点 (`pt-001`)**：
```
timestamp[n] = 1714521600000 + n * 1000   (ms, n = 0..86399)
value[n]     = 25.0 + 5.0 * sin(2π * n / 86400)
```
- 最小值: 20.0°C (n=21600, 06:00:00)
- 最大值: 30.0°C (n=64800, 18:00:00)

**`DS-COMPLETE-001` — 压力测点 (`pt-002`)**：
```
timestamp[n] = 1714521600000 + n * 1000
value[n]     = 101325.0 + 1000.0 * cos(2π * n / 86400)
```

**`DS-COMPLETE-002` — 流量测点 (`pt-003`)**：
```
timestamp[n] = 1714154400000 + n * 1000   (n = 0..9)
value[n]     = 10.0 + n * 1.0             // 10.0, 11.0, ..., 19.0
```

### 1.4 测试请求模板

```json
{
  "device_id": "dev-001",
  "point_ids": ["pt-001"],
  "start_time": "2026-05-01T00:00:00Z",
  "end_time": "2026-05-01T23:59:59Z",
  "downsample": 1000
}
```

---

## 二、LTTB 降采样边界条件说明

LTTB（Largest Triangle Three Buckets）算法通过最大化三角形面积选择代表性数据点，在保持视觉形状的同时减少数据量。

### 2.1 核心边界条件

| 场景 | 原始数据点数 N | downsample 参数 D | 预期返回点数 | 说明 |
|------|--------------|------------------|------------|------|
| **不触发降采样** | N < D | D = 1000 | N | 直接返回全部原始数据 |
| **刚好触发降采样** | N = D | D = 1000 | D | LTTB 仍返回 D 个点（含首尾，中间 D-2 个桶） |
| **标准降采样** | N > D | D = 1000 | D | 返回恰好 D 个点 |
| **最小 downsample** | N = 100 | D = 2 | 2 | 返回首尾两个点 |
| **单点数据** | N = 1 | D = 1000 | 1 | 不触发降采样，返回唯一数据点 |
| **空数据** | N = 0 | D = 1000 | 0 | 返回空数组 |
| **最大 downsample** | N = 100000 | D = 10000 | 10000 | PRD 规定的最大值 |

### 2.2 LTTB 算法验证策略

由于 LTTB 为自研实现，需验证其**视觉保真度**而非逐点对比（LTTB 是启发式算法，无标准输出）。验证策略：

1. **形状保持性**: 降采样后的数据应保留原始数据的极值点（最大值、最小值）
2. **首尾点保留**: 第一个点和最后一个点必须保留（LTTB 算法特性）
3. **点数精确性**: 返回点数严格等于 min(N, D)
4. **单调性保持**: 若原始数据单调递增/递减，降采样后趋势应保持

### 2.3 已知极值点验证表（`DS-COMPLETE-001`）

| 极值类型 | 时间点 | Unix 毫秒 | 期望值 | LTTB 后必须包含 |
|---------|--------|----------|--------|---------------|
| 最大值 | 18:00:00 | 1714564800000 | 30.0 | ✅ |
| 最小值 | 06:00:00 | 1714531200000 | 20.0 | ✅ |
| 起始点 | 00:00:00 | 1714521600000 | 25.0 | ✅ |
| 结束点 | 23:59:59 | 1714607999000 | ~25.0 | ✅ |

---

## 三、正常查询场景测试

### TC-QUERY-001: 单测点完整时间范围查询

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 1. 试验 `exp-001` 状态为 `completed`<br>2. HDF5 文件存在且包含 `dev-001/pt-001` 数据集<br>3. 用户已登录并持有有效 JWT |
| **测试步骤** | 1. 构造请求：`device_id=dev-001`, `point_ids=["pt-001"]`<br>2. `start_time="2026-05-01T00:00:00Z"`, `end_time="2026-05-01T23:59:59Z"`<br>3. `downsample=1000`<br>4. 发送 POST 请求到 `/api/v1/experiments/exp-001/data/query`<br>5. 记录响应时间 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `code`: 200, `message`: "success"<br>3. `data.experiment_id`: "exp-001"<br>4. `data.device_id`: "dev-001"<br>5. `data.points` 长度为 1<br>6. `data.points[0].point_id`: "pt-001"<br>7. `data.points[0].point_name`: "Temperature"<br>8. `data.points[0].unit`: "°C"<br>9. `data.points[0].data_type`: "float32"<br>10. `data.total_samples`: 86400<br>11. `data.returned_samples`: 1000（因 N > D，触发 LTTB）<br>12. `timestamps` 和 `values` 数组长度均为 1000<br>13. 第一个 timestamp = 1714521600000<br>14. 最后一个 timestamp ≈ 1714607999000<br>15. 响应时间 < 3s |
| **覆盖需求** | PRD 2.1.2 — 单测点按时间范围查询 |

### TC-QUERY-002: 多测点同时查询

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 同 TC-QUERY-001，HDF5 文件包含 `pt-001` 和 `pt-002` 两个数据集 |
| **测试步骤** | 1. 构造请求：`point_ids=["pt-001", "pt-002"]`，其他参数同 TC-QUERY-001<br>2. 发送 POST 请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `data.points` 长度为 2<br>3. `data.points[0].point_id`: "pt-001"<br>4. `data.points[1].point_id`: "pt-002"<br>5. 两个测点的 `timestamps` 和 `values` 数组长度相同（均为 1000）<br>6. `data.total_samples`: 86400（或按测点分别统计，以设计文档为准）<br>7. `data.returned_samples`: 1000<br>8. 两个测点的 point_name、unit、data_type 各自正确 |
| **覆盖需求** | PRD 2.1.2 — 多测点同时查询 |

### TC-QUERY-003: 时间范围部分过滤（起始偏移）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 同 TC-QUERY-001 |
| **测试步骤** | 1. `start_time="2026-05-01T06:00:00Z"` (06:00:00)<br>2. `end_time="2026-05-01T23:59:59Z"`<br>3. `downsample=1000`<br>4. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `data.total_samples`: 64800（从 06:00:00 到 23:59:59 共 18 小时）<br>3. `data.returned_samples`: 1000（64800 > 1000，触发 LTTB）<br>4. 第一个 timestamp ≥ 1714531200000（06:00:00）<br>5. 最后一个 timestamp ≈ 1714607999000（23:59:59）<br>6. 数据中应包含最小值 20.0（出现在 06:00:00 附近） |
| **覆盖需求** | PRD 2.1.2 — 时间范围切片读取 |

### TC-QUERY-004: 时间范围部分过滤（结束偏移）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 同 TC-QUERY-001 |
| **测试步骤** | 1. `start_time="2026-05-01T00:00:00Z"`<br>2. `end_time="2026-05-01T18:00:00Z"` (18:00:00)<br>3. `downsample=1000`<br>4. 发送请求 |
| **预期结果** | 1. `data.total_samples`: 64801（00:00:00 到 18:00:00）<br>2. `data.returned_samples`: 1000<br>3. 第一个 timestamp = 1714521600000<br>4. 最后一个 timestamp ≤ 1714564800000（18:00:00）<br>5. 数据中应包含最大值 30.0（出现在 18:00:00） |
| **覆盖需求** | PRD 2.1.2 — 时间范围切片读取 |

### TC-QUERY-005: 时间范围精确到单点

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 同 TC-QUERY-001 |
| **测试步骤** | 1. `start_time="2026-05-01T12:00:00Z"`<br>2. `end_time="2026-05-01T12:00:00Z"`（精确到同一秒）<br>3. `downsample=1000`<br>4. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `data.total_samples`: 1<br>3. `data.returned_samples`: 1<br>4. `timestamps`: [1714545600000]<br>5. `values`: [25.0]（sin(π) = 0，所以 25.0 + 0 = 25.0） |
| **覆盖需求** | PRD 2.1.2 — 精确时间切片 |

### TC-QUERY-006: 跨天查询时间范围

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 同 TC-QUERY-001（数据仅存在于 05-01） |
| **测试步骤** | 1. `start_time="2026-04-30T12:00:00Z"`<br>2. `end_time="2026-05-02T12:00:00Z"`<br>3. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. 仅返回 05-01 的数据（86400 点）<br>3. 不报错，超出范围的时间自动过滤 |
| **覆盖需求** | 边界 — 查询范围超出实际数据范围 |

---

## 四、降采样功能测试

### TC-DOWN-001: 大数据量触发 LTTB 降采样（标准场景）

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 试验 `exp-003` 状态 `completed`，包含 100,000 点数据 |
| **测试步骤** | 1. `device_id=dev-002`, `point_ids=["pt-004"]`<br>2. 完整时间范围<br>3. `downsample=1000`<br>4. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `data.total_samples`: 100000<br>3. `data.returned_samples`: 1000（严格等于 downsample 值）<br>4. `timestamps` 长度: 1000<br>5. `values` 长度: 1000<br>6. 首尾点保留（第一个 timestamp = 数据集起始时间，最后一个 = 结束时间）<br>7. 数据中包含原始数据的近似最大值和最小值（允许 ±5% 误差，因 LTTB 启发式特性） |
| **覆盖需求** | PRD 2.1.2 — LTTB 降采样，N > D 时返回 D 个点 |

### TC-DOWN-002: 小数据量不触发降采样（N < D）

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 试验 `exp-002` 状态 `completed`，包含 10 点数据 |
| **测试步骤** | 1. `device_id=dev-001`, `point_ids=["pt-003"]`<br>2. 完整时间范围<br>3. `downsample=1000`<br>4. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `data.total_samples`: 10<br>3. `data.returned_samples`: 10（N < D，返回全部原始数据）<br>4. `timestamps` 长度: 10<br>5. `values` 长度: 10<br>6. `values` 精确等于 [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0]<br>7. **未经过 LTTB 处理**，数据与 HDF5 中原始数据逐点一致 |
| **覆盖需求** | PRD 2.1.2 — 原始数据 < downsample 时返回全部数据 |

### TC-DOWN-003: 刚好等于 downsample（N = D）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 构造一个恰好 1000 点的数据集（可从 `exp-001` 截取） |
| **测试步骤** | 1. 使用 1000 点数据集<br>2. `downsample=1000`<br>3. 发送请求 |
| **预期结果** | 1. `data.returned_samples`: 1000<br>2. `timestamps` 长度: 1000<br>3. `values` 长度: 1000<br>4. 结果应为 LTTB 处理后的 1000 个点（含首尾） |
| **覆盖需求** | LTTB 边界 — N = D |

### TC-DOWN-004: 最小 downsample（D = 2）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-001`（86400 点） |
| **测试步骤** | 1. `downsample=2`<br>2. 发送请求 |
| **预期结果** | 1. `data.returned_samples`: 2<br>2. `timestamps` 长度: 2<br>3. `values` 长度: 2<br>4. 第一个点 = 数据集起始点<br>5. 最后一个点 = 数据集结束点<br>6. 仅保留首尾两个极值点 |
| **覆盖需求** | LTTB 边界 — 最小 downsample |

### TC-DOWN-005: 最大 downsample（D = 10000）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-003`（100000 点） |
| **测试步骤** | 1. `downsample=10000`<br>2. 发送请求 |
| **预期结果** | 1. `data.returned_samples`: 10000<br>2. `timestamps` 长度: 10000<br>3. `values` 长度: 10000<br>4. 响应时间 < 3s |
| **覆盖需求** | PRD 2.1.2 — 最大支持 10000 |

### TC-DOWN-006: 多测点各自独立降采样

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001`，两个测点数据量不同（或相同） |
| **测试步骤** | 1. `point_ids=["pt-001", "pt-002"]`（两测点均有 86400 点）<br>2. `downsample=1000`<br>3. 发送请求 |
| **预期结果** | 1. 两个测点均返回 1000 个点<br>2. 两个测点的 timestamps 数组可能不同（LTTB 对每个测点独立执行）<br>3. 每个测点的 `returned_samples` 均应为 1000 |
| **覆盖需求** | 多测点场景下降采样独立性 |

### TC-DOWN-007: downsample 参数省略（使用默认值）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001`（86400 点） |
| **测试步骤** | 1. 请求体中不传入 `downsample` 字段<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `data.returned_samples`: 1000（使用默认值 1000）<br>3. 后端应用默认 downsample = 1000 |
| **覆盖需求** | PRD 2.1.2 — 默认 downsample = 1000 |

---

## 五、边界条件测试

### TC-BOUND-001: 空数据集查询

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 试验 `exp-004` 状态 `completed`，HDF5 中 `pt-001` 数据集为空 |
| **测试步骤** | 1. `device_id=dev-001`, `point_ids=["pt-001"]`<br>2. 任意时间范围<br>3. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `code`: 200<br>3. `data.points` 长度为 1<br>4. `data.points[0].timestamps`: []（空数组）<br>5. `data.points[0].values`: []（空数组）<br>6. `data.total_samples`: 0<br>7. `data.returned_samples`: 0 |
| **覆盖需求** | 边界 — 空数据优雅处理 |

### TC-BOUND-002: 单点数据查询

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 试验 `exp-005` 状态 `completed`，仅包含 1 个数据点 |
| **测试步骤** | 1. `device_id=dev-001`, `point_ids=["pt-001"]`<br>2. `downsample=1000`<br>3. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `data.total_samples`: 1<br>3. `data.returned_samples`: 1（N=1 < D=1000，不触发降采样）<br>4. `timestamps`: [1715419200000]<br>5. `values`: [25.0]<br>6. `data_type`: "float32" |
| **覆盖需求** | 边界 — 单点数据 |

### TC-BOUND-003: 时间范围与数据无交集（完全之前）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001`（数据在 2026-05-01） |
| **测试步骤** | 1. `start_time="2026-04-01T00:00:00Z"`<br>2. `end_time="2026-04-01T23:59:59Z"`<br>3. 发送请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. `data.total_samples`: 0<br>3. `data.returned_samples`: 0<br>4. `timestamps`: []<br>5. `values`: []<br>6. 不返回 404 或错误，视为正常空结果 |
| **覆盖需求** | 边界 — 时间范围无交集 |

### TC-BOUND-004: 时间范围与数据无交集（完全之后）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001` |
| **测试步骤** | 1. `start_time="2026-06-01T00:00:00Z"`<br>2. `end_time="2026-06-01T23:59:59Z"`<br>3. 发送请求 |
| **预期结果** | 同 TC-BOUND-003，返回空数据 |
| **覆盖需求** | 边界 — 时间范围无交集 |

### TC-BOUND-005: 查询不存在的测点

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001`，HDF5 中不存在 `pt-999` |
| **测试步骤** | 1. `point_ids=["pt-999"]`（不存在的测点）<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `404 Not Found`<br>2. `code`: 404<br>3. `message` 包含 "point not found" 或类似信息<br>4. `data`: null |
| **覆盖需求** | 错误处理 — 测点不存在 |

### TC-BOUND-006: 查询部分存在的测点（混合存在/不存在）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-001`，`pt-001` 存在，`pt-999` 不存在 |
| **测试步骤** | 1. `point_ids=["pt-001", "pt-999"]`<br>2. 发送请求 |
| **预期结果** | 方案 A（严格）: HTTP 404，整体失败<br>方案 B（宽松）: HTTP 200，仅返回存在的测点，不存在的忽略<br>**以设计文档为准，当前预期采用方案 A（整体失败）** |
| **覆盖需求** | 边界 — 部分测点不存在 |

### TC-BOUND-007: start_time > end_time（非法时间范围）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-001` |
| **测试步骤** | 1. `start_time="2026-05-01T23:59:59Z"`<br>2. `end_time="2026-05-01T00:00:00Z"`<br>3. 发送请求 |
| **预期结果** | 1. HTTP Status: `400 Bad Request`<br>2. `code`: 400<br>3. `message` 包含 "start_time must be before end_time" 或类似信息 |
| **覆盖需求** | 输入验证 — 非法时间顺序 |

### TC-BOUND-008: 空 point_ids 数组

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-001` |
| **测试步骤** | 1. `point_ids=[]`（空数组）<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `400 Bad Request`<br>2. `code`: 400<br>3. `message` 包含 "point_ids cannot be empty" 或类似信息 |
| **覆盖需求** | 输入验证 — 空测点列表 |

### TC-BOUND-009: 查询 error 状态的试验

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 试验 `exp-007` 状态为 `error` |
| **测试步骤** | 1. 对 `exp-007` 发送正常查询请求 |
| **预期结果** | 1. HTTP Status: `200 OK`<br>2. 正常返回数据（`error` 状态允许查询）<br>3. 数据内容正确 |
| **覆盖需求** | PRD — `error` 状态允许查询 |

---

## 六、错误处理测试

### TC-ERR-001: 试验不存在

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送 POST 到 `/api/v1/experiments/non-existent-uuid/data/query`<br>2. 使用合法请求体 |
| **预期结果** | 1. HTTP Status: `404 Not Found`<br>2. `code`: 404<br>3. `message`: "Experiment not found" 或类似<br>4. `data`: null |
| **覆盖需求** | PRD — 资源不存在处理 |

### TC-ERR-002: 无权限访问他人试验

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 1. 用户 A 已登录<br>2. 试验 `exp-008` 属于用户 B<br>3. 用户 A 不属于用户 B 的团队 |
| **测试步骤** | 1. 用户 A 发送请求查询 `exp-008` |
| **预期结果** | 1. HTTP Status: `403 Forbidden`<br>2. `code`: 403<br>3. `message`: "Access denied" 或类似<br>4. `data`: null |
| **覆盖需求** | PRD — 资源隔离 |

### TC-ERR-003: running 状态试验返回 409 Conflict

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 试验 `exp-006` 状态为 `running` |
| **测试步骤** | 1. 发送 POST 到 `/api/v1/experiments/exp-006/data/query`<br>2. 使用合法请求体 |
| **预期结果** | 1. HTTP Status: `409 Conflict`<br>2. `code`: 409<br>3. `message`: "Experiment is still running" 或类似<br>4. `data`: null 或包含 `status: "running"`<br>5. **不读取 HDF5 文件**，避免并发冲突 |
| **覆盖需求** | PRD 2.1.2 / R2-RISK-02 — running 状态禁止查询 |

### TC-ERR-004: 未认证访问

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 无 JWT Token 或 Token 已过期 |
| **测试步骤** | 1. 不带 Authorization Header 发送请求<br>2. 或携带过期/无效 JWT |
| **预期结果** | 1. HTTP Status: `401 Unauthorized`<br>2. `code`: 401<br>3. `message`: "Unauthorized" 或类似 |
| **覆盖需求** | 认证中间件 |

### TC-ERR-005: 无效的 device_id（试验中不存在此设备）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-001`，该试验仅关联 `dev-001` |
| **测试步骤** | 1. `device_id="dev-999"`（试验中不存在的设备）<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `404 Not Found`<br>2. `code`: 404<br>3. `message`: "Device not found in experiment" 或类似 |
| **覆盖需求** | 设备归属验证 |

### TC-ERR-006: 无效的 UUID 格式

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. URL 中使用 `experiment_id="not-a-uuid"`<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `400 Bad Request`<br>2. `code`: 400<br>3. `message`: "Invalid UUID format" 或类似 |
| **覆盖需求** | 输入验证 |

### TC-ERR-007: downsample 超出范围（负数）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 用户已登录，使用 `exp-001` |
| **测试步骤** | 1. `downsample=-1`<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `400 Bad Request`<br>2. `code`: 400<br>3. `message`: "downsample must be >= 2" 或类似 |
| **覆盖需求** | 输入验证 |

### TC-ERR-008: downsample 超出范围（过大）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 用户已登录，使用 `exp-001` |
| **测试步骤** | 1. `downsample=10001`（超过最大值 10000）<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `400 Bad Request`<br>2. `code`: 400<br>3. `message`: "downsample must be <= 10000" 或类似 |
| **覆盖需求** | PRD — 最大支持 10000 |

### TC-ERR-009: downsample = 0

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 用户已登录，使用 `exp-001` |
| **测试步骤** | 1. `downsample=0`<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `400 Bad Request`<br>2. `code`: 400<br>3. `message`: "downsample must be >= 2" |
| **覆盖需求** | 输入验证 |

### TC-ERR-010: downsample = 1

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 用户已登录，使用 `exp-001` |
| **测试步骤** | 1. `downsample=1`<br>2. 发送请求 |
| **预期结果** | 1. HTTP Status: `400 Bad Request`<br>2. `code`: 400<br>3. `message`: "downsample must be >= 2"（LTTB 至少需 2 个点才能形成三角形） |
| **覆盖需求** | LTTB 最小约束 |

### TC-ERR-011: 请求体缺少必填字段

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 用户已登录 |
| **测试步骤** | 1. 发送不含 `device_id` 的请求体<br>2. 发送不含 `point_ids` 的请求体<br>3. 发送不含 `start_time` 的请求体<br>4. 发送不含 `end_time` 的请求体 |
| **预期结果** | 每个请求均返回：<br>1. HTTP Status: `400 Bad Request`<br>2. `code`: 400<br>3. `message` 指出具体缺少的字段 |
| **覆盖需求** | 请求体验证 |

### TC-ERR-012: HDF5 文件不存在（数据已丢失）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 试验 `exp-001` 状态 `completed`，但对应 HDF5 文件已被删除或损坏 |
| **测试步骤** | 1. 发送正常查询请求 |
| **预期结果** | 1. HTTP Status: `500 Internal Server Error` 或 `404 Not Found`<br>2. `code`: 500（或 404）<br>3. `message`: "Data file not found" 或 "Failed to read HDF5 file"<br>4. 不暴露文件系统路径等敏感信息 |
| **覆盖需求** | 文件系统错误处理 |

---

## 七、响应格式测试

### TC-FMT-001: 标准 ApiResponse 包裹层结构

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 使用 `exp-001`，正常查询 |
| **测试步骤** | 1. 发送正常查询请求<br>2. 解析响应 JSON |
| **预期结果** | 1. 顶层字段必须包含：`code`, `message`, `data`, `timestamp`<br>2. 不允许有额外顶层字段（除非设计允许）<br>3. `code` 类型为 number (i32)<br>4. `message` 类型为 string<br>5. `data` 类型为 object 或 null<br>6. `timestamp` 类型为 string |
| **覆盖需求** | 项目标准 — ApiResponse 格式一致性 |

### TC-FMT-002: timestamp 格式验证（ISO 8601）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001` |
| **测试步骤** | 1. 发送请求<br>2. 提取 `timestamp` 字段<br>3. 使用正则验证格式：`^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$` |
| **预期结果** | 1. `timestamp` 匹配 ISO 8601 UTC 格式<br>2. 示例：`"2026-05-10T12:00:00Z"`<br>3. 时间戳为服务器生成时间，与数据时间无关 |
| **覆盖需求** | PRD — timestamp 格式 |

### TC-FMT-003: data 字段结构验证

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001`，单测点查询 |
| **测试步骤** | 1. 发送请求<br>2. 验证 `data` 对象结构 |
| **预期结果** | `data` 必须包含：<br>- `experiment_id`: string (UUID)<br>- `device_id`: string (UUID)<br>- `points`: array of object<br>- `total_samples`: number (u64)<br>- `returned_samples`: number (u64)<br><br>`points[0]` 必须包含：<br>- `point_id`: string<br>- `point_name`: string<br>- `unit`: string<br>- `data_type`: string (enum: "float32", "float64", "int32", "int64", "bool")<br>- `timestamps`: array of number (i64, Unix ms)<br>- `values`: array of number (对应 data_type) |
| **覆盖需求** | PRD 2.1.2 — 响应数据结构 |

### TC-FMT-004: timestamps 和 values 数组长度一致性

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001`，多测点查询 |
| **测试步骤** | 1. `point_ids=["pt-001", "pt-002"]`<br>2. 发送请求<br>3. 验证每个测点的数组长度 |
| **预期结果** | 1. 每个测点的 `timestamps.length === values.length`<br>2. `timestamps.length === data.returned_samples`<br>3. 两个测点的 `returned_samples` 相同 |
| **覆盖需求** | 数据结构一致性 |

### TC-FMT-005: 错误响应格式一致性

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 触发多种错误 |
| **测试步骤** | 1. 触发 404（试验不存在）<br>2. 触发 409（running 状态）<br>3. 触发 400（无效参数）<br>4. 验证每种错误的响应格式 |
| **预期结果** | 所有错误响应均包含：`code`, `message`, `data`（可为 null）, `timestamp`<br>格式与成功响应一致，仅 `code` 和 `message` 不同 |
| **覆盖需求** | 统一错误响应格式 |

### TC-FMT-006: Unix 时间戳精度（毫秒）

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-001` |
| **测试步骤** | 1. 发送请求<br>2. 检查 `timestamps` 数组中的值 |
| **预期结果** | 1. 所有 timestamp 值为整数（number 类型，无小数）<br>2. 数值量级在 10^12~10^13 之间（毫秒级 Unix 时间戳）<br>3. 相邻 timestamp 差值反映实际采样间隔（1000ms = 1s） |
| **覆盖需求** | PRD — Unix 毫秒时间戳 |

### TC-FMT-007: 大数据量响应 JSON 结构完整性

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-003`，`downsample=10000` |
| **测试步骤** | 1. 发送请求<br>2. 解析 JSON<br>3. 验证数组长度 |
| **预期结果** | 1. JSON 可成功解析，无截断<br>2. `timestamps` 数组长度精确为 10000<br>3. `values` 数组长度精确为 10000<br>4. 响应体大小约 10000 * (~16 bytes per element) * 2 arrays ≈ 320KB，应完整传输 |
| **覆盖需求** | 大数据响应完整性 |

---

## 八、性能测试

### TC-PERF-001: 10万样本降采样查询响应时间 < 3s

| 项目 | 内容 |
|------|------|
| **优先级** | Critical |
| **前置条件** | 1. 试验 `exp-003` 含 100,000 数据点<br>2. 服务器负载正常（单用户）<br>3. 使用 Release 构建（`cargo build --release`） |
| **测试步骤** | 1. `downsample=1000`<br>2. 使用脚本连续发送 10 次请求<br>3. 记录每次 TTFB（Time To First Byte）和总响应时间<br>4. 计算平均值、P50、P95、最大值 |
| **预期结果** | 1. 平均响应时间 < 3s<br>2. P95 响应时间 < 3s<br>3. 最大响应时间 < 5s<br>4. 所有请求均返回 200<br>5. 响应结果正确（点数 = 1000） |
| **覆盖需求** | PRD 3.1 — HDF5 数据查询 < 3s |

### TC-PERF-002: 最大 downsample（10000）性能

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 同 TC-PERF-001 |
| **测试步骤** | 1. `downsample=10000`<br>2. 发送 10 次请求<br>3. 记录响应时间 |
| **预期结果** | 1. 平均响应时间 < 3s<br>2. `returned_samples` = 10000<br>3. 响应体大小约 ~500KB，传输时间不超时 |
| **覆盖需求** | PRD 3.1 — 大数据量性能 |

### TC-PERF-003: 小数据量查询响应时间 < 500ms

| 项目 | 内容 |
|------|------|
| **优先级** | High |
| **前置条件** | 使用 `exp-002`（10 点数据） |
| **测试步骤** | 1. 发送 10 次请求<br>2. 记录响应时间 |
| **预期结果** | 1. 平均响应时间 < 500ms<br>2. P95 < 500ms<br>3. 无 LTTB 计算开销，主要耗时为 HDF5 文件打开和读取 |
| **覆盖需求** | 小数据量性能基准 |

### TC-PERF-004: 多测点并发查询性能

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-001`，两测点各 86400 点 |
| **测试步骤** | 1. `point_ids=["pt-001", "pt-002"]`<br>2. `downsample=1000`<br>3. 发送 10 次请求<br>4. 记录响应时间 |
| **预期结果** | 1. 平均响应时间 < 3s（与单测点同数量级）<br>2. 两个测点数据均正确返回<br>3. 无内存泄漏或 OOM |
| **覆盖需求** | 多测点性能 |

### TC-PERF-005: 连续查询稳定性（压力测试）

| 项目 | 内容 |
|------|------|
| **优先级** | Medium |
| **前置条件** | 使用 `exp-001` |
| **测试步骤** | 1. 连续发送 100 次查询请求（间隔 100ms）<br>2. 每次使用不同时间范围（模拟缩放/平移）<br>3. 监控后端内存和 CPU 使用 |
| **预期结果** | 1. 所有 100 次请求均成功（成功率 100%）<br>2. 后端内存使用稳定，无持续增长<br>3. CPU 使用率峰值 < 80%<br>4. 无 HDF5 文件句柄泄漏（通过 `lsof` 或类似工具验证） |
| **覆盖需求** | 连续操作稳定性，HDF5 资源释放 |

---

## 九、用例汇总表

### 9.1 分类统计

| 分类 | 用例数 | 说明 |
|------|--------|------|
| **正常查询场景** | 6 | 单/多测点、时间范围过滤 |
| **降采样功能** | 7 | LTTB 触发/不触发、边界值 |
| **边界条件** | 9 | 空数据、单点、无交集、非法输入 |
| **错误处理** | 12 | 404/403/409/401/400/500 |
| **响应格式** | 7 | ApiResponse、timestamp、数据结构 |
| **性能测试** | 5 | 响应时间、稳定性、资源泄漏 |
| **总计** | **46** | — |

### 9.2 优先级分布

| 优先级 | 数量 | 占比 |
|--------|------|------|
| Critical | 8 | 17.4% |
| High | 26 | 56.5% |
| Medium | 12 | 26.1% |
| Low | 0 | 0% |
| **合计** | **46** | **100%** |

### 9.3 用例清单

| ID | 分类 | 描述 | 优先级 |
|----|------|------|--------|
| TC-QUERY-001 | 正常查询 | 单测点完整时间范围查询 | Critical |
| TC-QUERY-002 | 正常查询 | 多测点同时查询 | Critical |
| TC-QUERY-003 | 正常查询 | 时间范围部分过滤（起始偏移） | High |
| TC-QUERY-004 | 正常查询 | 时间范围部分过滤（结束偏移） | High |
| TC-QUERY-005 | 正常查询 | 时间范围精确到单点 | High |
| TC-QUERY-006 | 正常查询 | 跨天查询时间范围 | Medium |
| TC-DOWN-001 | 降采样 | 大数据量触发 LTTB（100000→1000） | Critical |
| TC-DOWN-002 | 降采样 | 小数据量不触发降采样（10<1000） | Critical |
| TC-DOWN-003 | 降采样 | 刚好等于 downsample（N=D） | High |
| TC-DOWN-004 | 降采样 | 最小 downsample（D=2） | Medium |
| TC-DOWN-005 | 降采样 | 最大 downsample（D=10000） | Medium |
| TC-DOWN-006 | 降采样 | 多测点各自独立降采样 | High |
| TC-DOWN-007 | 降采样 | downsample 省略使用默认值 | High |
| TC-BOUND-001 | 边界条件 | 空数据集查询 | High |
| TC-BOUND-002 | 边界条件 | 单点数据查询 | High |
| TC-BOUND-003 | 边界条件 | 时间范围完全之前（无交集） | High |
| TC-BOUND-004 | 边界条件 | 时间范围完全之后（无交集） | High |
| TC-BOUND-005 | 边界条件 | 查询不存在的测点 | High |
| TC-BOUND-006 | 边界条件 | 部分存在的测点（混合） | Medium |
| TC-BOUND-007 | 边界条件 | start_time > end_time | Medium |
| TC-BOUND-008 | 边界条件 | 空 point_ids 数组 | Medium |
| TC-BOUND-009 | 边界条件 | 查询 error 状态试验 | High |
| TC-ERR-001 | 错误处理 | 试验不存在 | Critical |
| TC-ERR-002 | 错误处理 | 无权限访问他人试验 | Critical |
| TC-ERR-003 | 错误处理 | running 状态返回 409 | Critical |
| TC-ERR-004 | 错误处理 | 未认证访问 | High |
| TC-ERR-005 | 错误处理 | 无效的 device_id | Medium |
| TC-ERR-006 | 错误处理 | 无效的 UUID 格式 | Medium |
| TC-ERR-007 | 错误处理 | downsample 负数 | Medium |
| TC-ERR-008 | 错误处理 | downsample 过大（>10000） | Medium |
| TC-ERR-009 | 错误处理 | downsample = 0 | Medium |
| TC-ERR-010 | 错误处理 | downsample = 1 | Medium |
| TC-ERR-011 | 错误处理 | 请求体缺少必填字段 | High |
| TC-ERR-012 | 错误处理 | HDF5 文件不存在 | High |
| TC-FMT-001 | 响应格式 | ApiResponse 包裹层结构 | Critical |
| TC-FMT-002 | 响应格式 | timestamp ISO 8601 格式 | High |
| TC-FMT-003 | 响应格式 | data 字段结构验证 | High |
| TC-FMT-004 | 响应格式 | timestamps/values 长度一致性 | High |
| TC-FMT-005 | 响应格式 | 错误响应格式一致性 | High |
| TC-FMT-006 | 响应格式 | Unix 毫秒时间戳精度 | High |
| TC-FMT-007 | 响应格式 | 大数据量 JSON 完整性 | Medium |
| TC-PERF-001 | 性能测试 | 10万样本查询 < 3s | Critical |
| TC-PERF-002 | 性能测试 | 最大 downsample 10000 性能 | High |
| TC-PERF-003 | 性能测试 | 小数据量查询 < 500ms | High |
| TC-PERF-004 | 性能测试 | 多测点并发查询性能 | Medium |
| TC-PERF-005 | 性能测试 | 连续查询稳定性（100次） | Medium |

### 9.4 需求跟踪矩阵

| 需求 ID | 需求描述 | 覆盖用例 |
|---------|---------|---------|
| R2-ANALYSIS-001 | HDF5 时序数据查询 API | TC-QUERY-001 ~ TC-QUERY-006 |
| R2-ANALYSIS-001-1 | 按设备/测点查询 | TC-QUERY-001, TC-QUERY-002, TC-ERR-005 |
| R2-ANALYSIS-001-2 | 时间范围过滤 | TC-QUERY-003 ~ TC-QUERY-006, TC-BOUND-003, TC-BOUND-004 |
| R2-ANALYSIS-001-3 | LTTB 降采样 | TC-DOWN-001 ~ TC-DOWN-007 |
| R2-ANALYSIS-001-4 | 多测点同时查询 | TC-QUERY-002, TC-DOWN-006 |
| R2-ANALYSIS-001-5 | running 状态 409 | TC-ERR-003, TC-BOUND-009 |
| PRD 3.1 | 性能 < 3s | TC-PERF-001 ~ TC-PERF-005 |
| PRD 3.2 | HDF5 并发读取安全 | TC-ERR-003, TC-PERF-005 |

---

**文档结束**

*本文档基于 Release 2 PRD v2.0 和任务分解文档编制，待 sw-tom 技术评审。*
