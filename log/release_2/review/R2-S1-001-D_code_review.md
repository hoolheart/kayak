# Code Review Report - R2-S1-001-D

## Review Information
- **Reviewer**: sw-jerry
- **Date**: 2026-05-10
- **Branch**: feature/R2-S1-001-hdf5-data-api

## Summary
- **Status**: CHANGES_REQUESTED
- **Total Issues**: 9
- **Critical**: 1
- **High**: 2
- **Medium**: 5
- **Low**: 1

---

## lttb.rs

### [Critical] Issue 1: 输入切片长度未校验，存在 panic 风险
- **Location**: `LttbDownsampler::downsample`, Line 25
- **Description**: 函数仅获取 `timestamps.len()` 作为 `n`，但后续同时索引 `timestamps` 和 `values`。如果调用者传入长度不一致的两个切片，会导致 panic（越界访问）。当前没有任何 `debug_assert!` 或运行时检查。
- **Impact**: 服务稳定性风险，恶意或错误调用会导致线程 panic。
- **Recommendation**: 在函数入口添加 `assert_eq!(timestamps.len(), values.len(), "timestamps and values must have the same length");` 或返回 `Option`/`Result`。
- **Status**: OPEN

### [High] Issue 2: threshold < 3 时的隐藏除零与不正确行为
- **Location**: `LttbDownsampler::downsample`, Line 36-46
- **Description**: 当 `threshold = 2` 时，`bucket_size = (n - 2) as f64 / 0 as f64` 产生 `inf`；虽然循环范围 `1..1` 为空避免了实际使用 `inf`，但属于隐藏的未定义行为依赖。当 `threshold = 1` 且 `n > 1` 时，函数返回 2 个点（首尾），违反了 "返回 `threshold` 个点" 的契约。
- **Impact**: API 语义不一致，调用者期望返回指定数量的点，实际可能多返回。
- **Recommendation**: 显式前置条件：`if threshold < 3 { return (timestamps.to_vec(), values.to_vec()); }` 或直接 panic/assert threshold >= 3。
- **Status**: OPEN

### [Medium] Issue 3: LTTB 算法实现偏差 — 使用中间点代替 bucket 平均值
- **Location**: `LttbDownsampler::downsample`, Line 58-60
- **Description**: 标准 LTTB 算法（Steinarsson 2013）要求使用**下一个 bucket 的平均坐标点** `(avg_x, avg_y)` 作为三角形顶点。当前实现使用 `avg_idx = next_bucket_start + (next_bucket_end - next_bucket_start) / 2`，即 bucket 的**中间索引点**，而非平均值。这导致降采样后的曲线保真度下降，尤其在数据波动剧烈的 bucket 中偏差显著。
- **Impact**: 降采样质量不符合算法标准，前端可能观察到不应有的特征丢失或伪影。
- **Recommendation**: 计算 `avg_x = timestamps[next_bucket_start..next_bucket_end].iter().sum::<f64>() / count`，`avg_y` 同理。
- **Status**: OPEN

### [Low] Issue 4: 浮点运算可在循环外预计算
- **Location**: `LttbDownsampler::downsample`, Line 49-50
- **Description**: 每次循环中重复计算 `(i as f64 * bucket_size).floor() as usize + 1`，可改为整数步长累加避免浮点运算。
- **Impact**: 性能影响极小（编译器可能已优化），但代码可读性可提升。
- **Recommendation**: 使用 `bucket_start = prev_bucket_end; bucket_end = bucket_start + bucket_size_int;` 的整数累加方式。
- **Status**: OPEN

---

## experiment_data.rs (Handler)

### [High] Issue 5: 验证错误未转换为项目标准的字段级错误格式
- **Location**: `query_experiment_data`, Line 58-60
- **Description**: `body.validate()` 失败时，使用 `AppError::validation_error_single("body", e.to_string())` 将整个验证错误压缩为单条字符串。validator 返回的 `ValidationErrors` 包含多个字段的具体错误信息，应解析并映射为 `Vec<FieldError>`，使用 `AppError::validation_error(fields)`。
- **Impact**: 前端无法根据字段名精准定位错误，用户体验差。
- **Recommendation**: 遍历 `ValidationErrors`，提取每个字段的 `message` 和 `code`，构造 `FieldError` 列表。
- **Status**: OPEN

### [Medium] Issue 6: 时间范围边界条件不完整
- **Location**: `query_experiment_data`, Line 62-75
- **Description**: 当前仅当 `start_time` 和 `end_time` **同时存在**时才验证时间顺序和窗口大小。若只提供 `end_time` 不提供 `start_time`，handler 不拦截，service 中将 `start_time` 视为 0（1970-01-01），可能触发全量历史数据读取。虽然 service 有 30 天限制检查，但 handler 缺失这一层防护。
- **Impact**: 可能导致意外的大量数据查询，影响性能。
- **Recommendation**: 在 handler 中补充：若只提供一侧时间边界，也应检查时间窗口或拒绝查询。
- **Status**: OPEN

### [Medium] Issue 7: 所有权检查与 PRD 团队资源共享模型未对齐
- **Location**: `experiment_data.rs` (handler) 及 `services/experiment_data/mod.rs`
- **Description**: PRD 第 2.2.2 节定义了团队资源共享模型（`owner_type` + `owner_id`），且 `experiments` 表已计划新增 `owner_type` / `owner_id`。当前实现仅检查 `experiment.user_id != user_id`，未考虑团队访问场景。此代码在 Sprint 2 团队管理功能接入后需要大规模重构。
- **Impact**: 技术债务，Sprint 2 需要返工。
- **Recommendation**: 在 service 层添加 TODO 注释，说明当前为临时实现，待团队权限中间件完成后替换为统一的资源权限检查。
- **Status**: OPEN

---

## experiment_data service (mod.rs)

### [Medium] Issue 8: HDF5 文件重复打开
- **Location**: `ExperimentDataServiceImpl::query_experiment_data`, Line 120-135 及 `read_point_data`
- **Description**: Service 先打开 HDF5 文件验证设备组存在（Line 120-135），关闭后又在 `read_point_data` 中**为每个 point 重新打开文件**。对于 4 个测点的查询，文件被打开 5 次。HDF5 文件打开是有开销的。
- **Impact**: 增加 I/O 开销和延迟，PRD 要求 HDF5 查询 < 3s，重复打开可能影响性能指标。
- **Recommendation**: 在 `query_experiment_data` 中打开文件一次，将 `hdf5::File` 对象传给 `read_point_data`（或重构为读取方法接受已打开的文件/组）。
- **Status**: OPEN

### [Medium] Issue 9: `#[allow(clippy::type_complexity)]` 是设计异味
- **Location**: `ExperimentDataServiceImpl::read_point_data`, Line 58
- **Description**: 返回 `(Vec<i64>, Vec<f64>, String, String, String)` 这种 5 元组是明显的代码异味，需要 `#[allow]` 来抑制 clippy 警告。
- **Impact**: 可读性差，调用处容易混淆字段顺序。
- **Recommendation**: 定义命名结构体 `struct PointData { timestamps: Vec<i64>, values: Vec<f64>, name: String, unit: String, data_type: String }`。
- **Status**: OPEN

---

## Architecture Compliance
- [x] Follows arch.md 的单端口部署、分层架构
- [x] Uses defined interfaces (`ExperimentDataService` trait + `async_trait`)
- [x] Proper error handling（使用 `AppError` 统一错误类型）
- [ ] **No compiler warnings** — `#[allow(clippy::type_complexity)]` 表示存在已知警告
- [ ] **Algorithm correctness** — LTTB 实现有偏差

## Quality Checks
- [x] No compiler errors
- [ ] **Compiler warning exists** (`#[allow(clippy::type_complexity)]`)
- [ ] Lint warning suppressed rather than fixed
- [ ] Tests pass but algorithm correctness not fully verified
- [ ] **Documentation** — handler doc comments 存在，但 LTTB 算法文档未说明与标准算法的差异

---

## 修改建议汇总

1. **lttb.rs 必须修复**：
   - 添加 `timestamps.len() == values.len()` 断言
   - 显式处理 `threshold < 3` 的边界（返回原始数据或 panic）
   - **修正 LTTB 算法**：使用下一个 bucket 的坐标平均值而非中间索引点
   - 添加算法参考来源注释（Steinarsson 2013）

2. **experiment_data handler 必须修复**：
   - 将 `validator` 错误解析为 `Vec<FieldError>`，使用 `AppError::validation_error()`
   - 补充单边时间边界的时间窗口验证

3. **experiment_data service 强烈建议修复**：
   - 将 `read_point_data` 的返回类型重构为命名结构体，移除 `#[allow(clippy::type_complexity)]`
   - 优化 HDF5 文件打开逻辑：只打开一次，复用 `File` 对象
   - 在 `query_experiment_data` 的权限检查处添加 TODO/FIXME，说明团队资源共享待接入
   - `read_point_data` 的时间范围查找可考虑二分查找优化（大数据集时 O(log N) vs O(N)）

4. **测试补充建议**：
   - LTTB：添加 `timestamps` 和 `values` 长度不等的 panic 测试（使用 `#[should_panic]`）
   - LTTB：添加已知数据集（如正弦波）的降采样质量对比测试，验证与标准实现的输出一致性
   - Handler：添加验证错误返回多字段错误的集成测试

---

## Approval
- [ ] All issues resolved
- [ ] Code meets standards
- [ ] Approved for merge

**当前状态：不通过，需修改后重新审查。**
