# R2-S1-001-E HDF5 时序数据查询 API — 测试执行报告

**任务 ID**: R2-S1-001-E  
**测试执行者**: sw-mike  
**日期**: 2026-05-10  
**被测分支**: `feature/R2-S1-001-hdf5-data-api`  
**测试用例来源**: `log/release_2/test/R2-S1-001-A_test_cases.md`

---

## 一、执行摘要

| 项目 | 结果 |
|------|------|
| **编译环境** | 不可用（缺少 `libudev-dev`） |
| **单元测试执行** | 未执行（编译失败） |
| **代码级验证** | 已完成（静态分析 + 逻辑推演） |
| **LTTB 算法验证** | 通过（3/3 核心场景） |
| **Handler 验证** | 通过（错误码映射正确） |
| **发现 Bug** | 1 个（`downsample` 最小值验证） |
| **测试资产新增** | 3 个单元测试函数（已提交到 `lttb.rs`） |

---

## 二、环境限制说明

### 2.1 编译失败信息

```
error: failed to run custom build command for `libudev-sys v0.1.4`

The system library `libudev` required by crate `libudev-sys` was not found.
The file `libudev.pc` needs to be installed and the PKG_CONFIG_PATH
environment variable must contain its parent directory.
```

### 2.2 影响范围

- `cargo test` 无法编译执行
- `cargo build` 无法完成
- 所有需要链接系统库（`libudev`、`libhdf5`）的操作均不可用

### 2.3 应对措施

1. **代码级静态验证**：通过逐行阅读和分析代码逻辑，推演执行路径和边界行为
2. **测试资产编写**：在 `lttb.rs` 中补充了 3 个符合测试用例要求的单元测试函数
3. **逻辑推演替代运行**：对 LTTB 算法的每个边界条件进行手动的输入/输出推演

---

## 三、LTTB 算法验证

### 3.1 被测文件

`kayak-backend/src/services/lttb.rs`

### 3.2 边界条件验证

| 场景 | 输入条件 | 代码逻辑 | 预期结果 | 验证结论 |
|------|----------|----------|----------|----------|
| **N < D** | `n=5, threshold=10` | `if n <= threshold` 为真，直接返回克隆 | 返回 5 个点，与原始数据一致 | **通过** |
| **N == D** | `n=1000, threshold=1000` | `if n <= threshold` 为真，直接返回克隆 | 返回 1000 个点（未走 LTTB） | **差异（见 3.3）** |
| **N > D** | `n=5000, threshold=1000` | 进入主循环，`bucket_size = 4998/998 ≈ 5.008` | 返回恰好 1000 个点 | **通过** |
| **空数据** | `n=0, threshold=10` | `if n <= threshold` 为真，返回空 Vec | 返回空数组 | **通过** |
| **单点** | `n=1, threshold=10` | `if n <= threshold` 为真，返回单点 | 返回 1 个点 | **通过** |
| **D = 2** | `n=100, threshold=2` | `bucket_size = 98/0 = inf`，但 `for i in 1..1` 为空 | 只返回首尾 2 个点 | **通过** |
| **长度不一致** | `ts.len()=5, vals.len()=3` | 首行检查 `!=` 直接返回克隆 | 安全返回原始数据 | **通过** |

### 3.3 N == D 场景的差异说明

**代码行为**：当 `N == D` 时，`lttb.rs` 第 52 行的 `if n <= threshold` 会直接返回全部原始数据，**不执行 LTTB 算法**。

**测试用例期望**（TC-DOWN-003）：当 `N = D` 时，应触发 LTTB 并返回经过 LTTB 选择的 D 个点（含首尾，中间 D-2 个桶）。

**影响评估**：
- 返回的点数相同（均为 D 个）
- 当 N == D 时，LTTB 的 bucket_size = 1，每个桶选 1 个点，结果与原始数据在数量上一致
- 从功能正确性角度，不构成功能缺陷
- 从算法一致性角度，建议统一为 `n < threshold`（将 `<=` 改为 `<`），使 N >= D 均走 LTTB 路径

**建议**：将第 52 行 `if n <= threshold` 改为 `if n < threshold`，与测试用例的边界定义保持一致。

### 3.4 长度不一致处理验证

最新提交已正确处理长度不一致场景：

```rust
if timestamps.len() != values.len() {
    return (timestamps.to_vec(), values.to_vec());
}
```

验证结论：
- 不会 panic，安全返回原始数据
- 返回值长度可能不同（与输入一致），调用方需自行处理
- 符合"fail-safe"原则

---

## 四、Handler 验证

### 4.1 被测文件

`kayak-backend/src/api/handlers/experiment_data.rs`

### 4.2 错误码映射验证

| 触发条件 | Handler 代码 | AppError 类型 | HTTP Status | 测试用例 | 验证结论 |
|----------|-------------|---------------|-------------|----------|----------|
| 无效 UUID 格式 | `Uuid::parse_str` 失败 | `BadRequest` | 400 | TC-ERR-006 | **通过** |
| 请求体验证失败 | `body.validate()` 失败 | `validation_error_single` -> `BadRequest` | 400 | TC-ERR-011 | **通过** |
| `start_time > end_time` | 显式检查 | `BadRequest` | 400 | TC-BOUND-007 | **通过** |
| 时间窗口 > 30 天 | 显式检查 | `BadRequest` | 400 | — | **通过** |
| 试验不存在 | Service: `find_by_id` 返回 `None` | `NotFound` | 404 | TC-ERR-001 | **通过** |
| 无权限访问 | Service: `user_id` 不匹配 | `Forbidden` | 403 | TC-ERR-002 | **通过** |
| 试验 `running` 状态 | Service: `matches!(Running \| Paused)` | `Conflict` | 409 | TC-ERR-003 | **通过** |
| HDF5 文件不存在 | Service: `!hdf5_path.exists()` | `NotFound` | 404 | TC-ERR-012 | **通过** |
| 设备不存在 | Service: `file.group()` 失败 | `NotFound` | 404 | TC-ERR-005 | **通过** |
| 测点不存在 | Service: `file.group()` 失败 | `NotFound` | 404 | TC-BOUND-005 | **通过** |
| HDF5 读取错误 | Service: `hdf5::File::open` 等失败 | `InternalError` | 500 | TC-ERR-012 | **通过** |

### 4.3 响应格式验证

Handler 返回类型：
```rust
Result<Json<ApiResponse<ExperimentDataResponse>>, AppError>
```

验证结论：
- 成功路径使用 `ApiResponse::success(response)` 包裹 — **通过**
- 错误路径通过 `?` 传播 `AppError`，由全局中间件统一转换为 `ApiResponse` — **通过**
- 符合项目标准 `ApiResponse` 结构（含 `code`, `message`, `data`, `timestamp`） — **通过**

---

## 五、Service 层验证

### 5.1 被测文件

`kayak-backend/src/services/experiment_data/mod.rs`

### 5.2 关键逻辑验证

| 逻辑点 | 代码位置 | 验证结论 |
|--------|----------|----------|
| 试验状态检查 | 第 174-182 行，`Running \| Paused` 返回 409 | **通过** |
| `error` 状态允许查询 | 第 174 行未包含 `Error`，允许通过 | **通过**（符合 TC-BOUND-009） |
| 空时间范围交集 | 第 114-116 行，`start_idx >= end_idx` 返回空数组 | **通过**（符合 TC-BOUND-003/004） |
| 多测点独立降采样 | 第 210-242 行，`for` 循环每个测点独立调用 `lttb_downsample` | **通过** |
| `downsample` 默认值 | 第 155 行，`unwrap_or(1000)` | **通过**（符合 TC-DOWN-007） |
| HDF5 属性缺失容错 | `read_string_attr` 使用 `unwrap_or_default()` | **通过** |
| timestamps/values 长度校验 | 第 96-100 行，不一致返回 `InternalError` | **通过** |

---

## 六、DTO 验证规则审查

### 6.1 被测文件

`kayak-backend/src/models/dto/experiment_data_query.rs`

### 6.2 验证规则检查

```rust
#[validate(length(min = 1, max = 50))]
pub point_ids: Vec<Uuid>,           // ✅ 正确：至少 1 个，最多 50 个

#[validate(range(min = 1, max = 10000))]
pub downsample: Option<usize>,      // ⚠️ 见 Bug 报告
```

---

## 七、Bug 报告

### Bug #1: `downsample` 最小值验证过宽（Severity: High）

**位置**：`kayak-backend/src/models/dto/experiment_data_query.rs` 第 23 行

**当前代码**：
```rust
#[validate(range(min = 1, max = 10000))]
pub downsample: Option<usize>,
```

**问题描述**：
当前验证允许 `downsample = 1`，但 LTTB 算法在 `threshold = 1` 时会导致以下问题：
1. `bucket_size = (n - 2) as f64 / (1 - 2) as f64 = -(n - 2)`，结果为**负数**
2. 主循环 `for i in 1..(threshold - 1)` = `1..0`，为空循环
3. 只推入首尾两点，最终返回 **2 个点**，而非用户期望的 1 个点
4. 与测试用例 TC-ERR-010 冲突：该用例明确要求 `downsample = 1` 返回 400

**测试用例冲突**：
- TC-ERR-010: `downsample = 1` → 预期 HTTP 400，`message` 包含 "downsample must be >= 2"
- TC-ERR-009: `downsample = 0` → 预期 HTTP 400（当前 `min = 1` 已覆盖）

**修复建议**：
```rust
#[validate(range(min = 2, max = 10000))]
pub downsample: Option<usize>,
```

同时更新默认值逻辑：默认值 1000 已满足 `>= 2`，无需调整。

**影响范围**：
- 所有传入 `downsample = 1` 的请求会错误地通过验证
- 可能导致 LTTB 返回意外的 2 个点（而非 1 个）
- 违反 PRD 对 downsample 范围的定义

---

## 八、新增测试资产

### 8.1 新增测试函数

已在 `kayak-backend/src/services/lttb.rs` 的 `#[cfg(test)]` 模块中追加以下 3 个测试：

| 测试函数名 | 验证场景 | 对应测试用例 |
|-----------|---------|-------------|
| `test_lttb_no_downsample` | N < threshold，返回全部数据 | TC-DOWN-002 |
| `test_lttb_downsample` | N > threshold，返回 threshold 个点 | TC-DOWN-001 |
| `test_lttb_mismatched_lengths` | timestamps 与 values 长度不一致时安全处理 | 边界条件 |

### 8.2 现有测试覆盖

`lttb.rs` 原有 8 个测试 + 新增 3 个 = **共 11 个单元测试**

原有测试覆盖：
- `test_lttb_no_downsample_n_less_than_threshold` — N < D
- `test_lttb_no_downsample_n_equals_threshold` — N == D
- `test_lttb_downsample_returns_exact_threshold` — N > D，返回数量
- `test_lttb_preserves_first_and_last` — 首尾保留
- `test_lttb_minimum_threshold` — D = 2
- `test_lttb_empty_input` — 空输入
- `test_lttb_single_point` — 单点
- `test_lttb_standalone_function` — 独立函数包装

---

## 九、测试结果汇总

### 9.1 测试用例覆盖矩阵（代码级验证）

| 用例 ID | 场景 | 验证方式 | 结果 | 备注 |
|---------|------|----------|------|------|
| TC-QUERY-001 | 单测点完整查询 | 代码推演 | **通过** | — |
| TC-QUERY-002 | 多测点同时查询 | 代码推演 | **通过** | — |
| TC-QUERY-003 | 时间范围起始偏移 | 代码推演 | **通过** | — |
| TC-QUERY-004 | 时间范围结束偏移 | 代码推演 | **通过** | — |
| TC-QUERY-005 | 精确单点查询 | 代码推演 | **通过** | — |
| TC-QUERY-006 | 跨天查询 | 代码推演 | **通过** | — |
| TC-DOWN-001 | 大数据量 LTTB | 代码推演 | **通过** | — |
| TC-DOWN-002 | 小数据量不触发 | 代码推演 | **通过** | — |
| TC-DOWN-003 | N = D 边界 | 代码推演 | **差异** | 未走 LTTB，但数量正确 |
| TC-DOWN-004 | D = 2 最小值 | 代码推演 | **通过** | — |
| TC-DOWN-005 | D = 10000 最大值 | 代码推演 | **通过** | — |
| TC-DOWN-006 | 多测点独立降采样 | 代码推演 | **通过** | — |
| TC-DOWN-007 | 默认值 1000 | 代码推演 | **通过** | — |
| TC-BOUND-001 | 空数据集 | 代码推演 | **通过** | — |
| TC-BOUND-002 | 单点数据 | 代码推演 | **通过** | — |
| TC-BOUND-003 | 时间范围完全之前 | 代码推演 | **通过** | — |
| TC-BOUND-004 | 时间范围完全之后 | 代码推演 | **通过** | — |
| TC-BOUND-005 | 测点不存在 | 代码推演 | **通过** | — |
| TC-BOUND-006 | 部分测点不存在 | 代码推演 | **通过** | 采用方案 A（整体失败） |
| TC-BOUND-007 | 非法时间顺序 | 代码推演 | **通过** | — |
| TC-BOUND-008 | 空 point_ids | 代码推演 | **通过** | `validator` 拦截 |
| TC-BOUND-009 | error 状态查询 | 代码推演 | **通过** | — |
| TC-ERR-001 | 试验不存在 | 代码推演 | **通过** | — |
| TC-ERR-002 | 无权限 | 代码推演 | **通过** | — |
| TC-ERR-003 | running 状态 409 | 代码推演 | **通过** | — |
| TC-ERR-004 | 未认证 | 代码推演 | **通过** | 中间件处理 |
| TC-ERR-005 | 无效 device_id | 代码推演 | **通过** | — |
| TC-ERR-006 | 无效 UUID | 代码推演 | **通过** | — |
| TC-ERR-007 | downsample 负数 | 代码推演 | **通过** | `usize` 天然不可为负 |
| TC-ERR-008 | downsample > 10000 | 代码推演 | **通过** | `validator` 拦截 |
| TC-ERR-009 | downsample = 0 | 代码推演 | **通过** | `validator` 拦截 |
| TC-ERR-010 | downsample = 1 | **失败** | **BUG** | `validator` 允许，需修复 |
| TC-ERR-011 | 缺少必填字段 | 代码推演 | **通过** | — |
| TC-ERR-012 | HDF5 文件不存在 | 代码推演 | **通过** | — |
| TC-FMT-001 | ApiResponse 结构 | 代码推演 | **通过** | — |
| TC-FMT-002 | ISO 8601 timestamp | 代码推演 | **通过** | `ApiResponse` 统一生成 |
| TC-FMT-003 | data 字段结构 | 代码推演 | **通过** | — |
| TC-FMT-004 | 数组长度一致性 | 代码推演 | **通过** | — |
| TC-FMT-005 | 错误响应格式 | 代码推演 | **通过** | — |
| TC-FMT-006 | Unix 毫秒精度 | 代码推演 | **通过** | — |
| TC-FMT-007 | 大数据 JSON 完整性 | 代码推演 | **通过** | — |
| TC-PERF-001~005 | 性能测试 | **未验证** | **跳过** | 需运行环境支持 |

### 9.2 统计

| 类别 | 总数 | 通过 | 失败 | 跳过 |
|------|------|------|------|------|
| 正常查询场景 | 6 | 6 | 0 | 0 |
| 降采样功能 | 7 | 6 | 0 | 1（TC-DOWN-003 差异） |
| 边界条件 | 9 | 9 | 0 | 0 |
| 错误处理 | 12 | 11 | 1 | 0 |
| 响应格式 | 7 | 7 | 0 | 0 |
| 性能测试 | 5 | 0 | 0 | 5 |
| **合计** | **46** | **39** | **1** | **6** |

---

## 十、LTTB 算法验证结论

### 10.1 算法正确性

LTTB 实现遵循了标准的 Largest Triangle Three Buckets 算法：

1. **桶划分正确**：`bucket_size = (n - 2) / (threshold - 2)`，排除首尾点后均匀划分
2. **三角形面积计算正确**：使用叉积公式 `|(ax-cx)*(by-ay) - (ax-bx)*(cy-ay)|`，省略 0.5 不影响相对比较
3. **首尾点保留**：第一个点和最后一个点始终被选中
4. **平均点计算**：使用下一桶的中点索引作为三角形第三个顶点

### 10.2 边界处理

| 边界 | 处理 | 评价 |
|------|------|------|
| 空输入 | 直接返回空 Vec | 优秀 |
| 单点 | 直接返回单点 | 优秀 |
| N < D | 直接返回全部 | 优秀 |
| N == D | 直接返回全部（未走 LTTB） | 可接受，建议统一 |
| N > D | 标准 LTTB 流程 | 优秀 |
| D = 2 | 仅返回首尾 | 正确 |
| 长度不一致 | 安全返回原始数据 | 优秀 |

### 10.3 代码质量

- `#[inline]` 标记了 `triangle_area`，有助于编译器优化
- `Vec::with_capacity(threshold)` 预分配内存，避免重复扩容
- 使用 `usize` 类型确保索引非负

---

## 十一、待办事项

| 序号 | 事项 | 负责人 | 优先级 |
|------|------|--------|--------|
| 1 | 修复 `downsample` 验证最小值：`min = 1` → `min = 2` | sw-tom | **High** |
| 2 | （可选）统一 N == D 边界：`n <= threshold` → `n < threshold` | sw-tom | Low |
| 3 | 安装 `libudev-dev` 后重新执行 `cargo test` 验证所有测试 | sw-mike | High |
| 4 | 安装 `libhdf5-dev` 确保完整编译环境 | 运维 | High |

---

## 十二、签字

**测试执行者**: sw-mike  
**日期**: 2026-05-10  
**状态**: 已完成（代码级验证 + 测试资产编写）

---

*本报告基于静态代码分析和逻辑推演生成。待编译环境恢复后，应补充实际运行结果。*
