# S2-003 设计审查报告

**任务ID**: S2-003  
**任务名称**: 时序数据写入服务  
**审查日期**: 2026-03-27  
**审查人**: sw-jerry (Software Architect)

---

## 审查结论

**状态**: ⚠️ **Needs Revision**

设计整体架构合理，trait+impl 模式正确，错误类型定义完善。但存在若干技术问题需要在实现前澄清或修正。

---

## 1. 技术可行性评估

### 1.1 与现有 Hdf5Service 接口兼容性

| Hdf5Service 方法 | 设计中使用方式 | 状态 |
|-----------------|--------------|------|
| `write_timeseries(group, name, timestamps, values)` | 写入时序数据 | ✅ 兼容 |
| `create_file_with_directories(path)` | 创建 HDF5 文件 | ✅ 兼容 |
| `create_group(parent, name)` | 创建 channel group | ✅ 兼容 |
| `is_path_safe(path)` | 路径安全检查 | ✅ 兼容 |

**结论**: 技术上可行，接口兼容。

### 1.2 压缩功能

设计已正确记录压缩功能需待 Hdf5Service 扩展后生效。✅

---

## 2. 架构质量评估

### 2.1 优点

- ✅ Trait + Impl 模式正确遵循
- ✅ 分离了 ChannelBuffer、ExperimentBuffer、TimeSeriesBufferServiceImpl 职责
- ✅ 使用 thiserror 定义错误类型，枚举值语义清晰
- ✅ 文档结构完整，包含 UML 图

### 2.2 问题

#### 问题 #2.1: flush_scheduler 机制不明确

**位置**: 6.3 节 `TimeSeriesBufferServiceImpl` 结构体 + 7.2 节刷新逻辑

**问题描述**:
- 结构体中定义了 `flush_scheduler: Arc<Mutex<Option<JoinHandle<()>>>>`
- 但 7.2 节写道："时间触发检查在 `write_point` 和 `write_batch` 时进行"
- 这意味着**只有在写入操作时才会检查时间触发条件**，而不是通过后台定时器

**风险**:
- 如果长时间没有写入操作，缓冲区数据将不会自动刷新
- 与"定时刷新"的预期行为不符

**建议**:
- 明确说明是否需要后台定时刷新任务
- 如需后台定时器，需在 `create_buffer` 时启动定时任务，在 `close_buffer`/`delete_buffer` 时取消
- 或修正设计描述，澄清时间触发仅在写入时检查

---

## 3. 错误处理评估

### 3.1 优点

- ✅ 错误类型覆盖全面（BufferNotFound、FlushInProgress、Overflow 等）
- ✅ 错误消息格式统一
- ✅ 包含 `DataLoss` 错误类型用于检测数据丢失

### 3.2 问题

#### 问题 #3.1: DataLoss 错误未在设计中使用

**位置**: 5.1 节错误类型定义 + 10.1 节写入失败策略

**问题描述**:
- `DataLoss` 错误已定义但未在任何流程中使用
- 10.1 节描述"HDF5 写入失败时，保留缓冲区数据不丢失"，但没有说明何时触发 `DataLoss` 错误

**建议**:
- 明确 `DataLoss` 的触发场景（例如：重试多次后仍失败）
- 或移除此错误类型，简化设计

---

## 4. 线程安全评估

### 4.1 锁策略检查

| 数据结构 | 锁类型 | 保护内容 | 评估 |
|---------|--------|---------|------|
| `buffers: RwLock<HashMap<...>>` | RwLock | buffer map | ✅ 合理 |
| `ExperimentBuffer.is_flushing` | Mutex | 刷新状态 | ✅ 合理 |
| `ExperimentBuffer.is_closed` | Mutex | 关闭状态 | ✅ 合理 |
| `ChannelBuffer.points` | 未见锁 | 数据点列表 | ⚠️ **需确认** |

#### 问题 #4.1: ChannelBuffer.points 访问安全性

**问题描述**:
- `ChannelBuffer` 结构体中的 `points: Vec<TimeSeriesPoint>` 未使用锁保护
- 在 11.2 节描述"同一 channel 的并发写入通过 channel mutex 串行化"，但 `ChannelBuffer` 结构体中未定义 mutex

**建议**:
- 确认 `ChannelBuffer.points` 的并发访问控制机制
- 如果 `ExperimentBuffer` 层已保证同一 channel 的串行访问，则无需额外锁
- 或在 `ChannelBuffer` 中添加 `Mutex<Vec<TimeSeriesPoint>>`

---

## 5. 性能评估

### 5.1 设计分析

**批量写入优化**:
- ✅ 使用内存缓冲减少 HDF5 I/O 次数
- ✅ 批量写入时按 channel 分组，合并相同 channel 的数据

**性能估算**:
- 假设 `max_size = 10000`，`flush_interval_ms = 1000`
- 每秒最多 10,000 个数据点
- **满足 >10k samples/sec 要求**（需要实际 benchmark 验证）

### 5.2 潜在瓶颈

- **HDF5 文件打开/关闭开销**: 每次 flush 都会打开和关闭文件（8.3 节步骤 1, 9）
- **建议**: 考虑在 `ExperimentBuffer` 中缓存文件句柄，或添加 `Hdf5Service` 批处理接口

---

## 6. 数据安全性评估 ⚠️ **严重问题**

### 问题 #6.1: 内存数据在服务崩溃时丢失

**位置**: 15.3 节 "数据恢复"

**问题描述**:
- 设计明确写道："服务异常崩溃后，内存中未刷新的数据会丢失"
- 但验收标准 #3 要求："服务异常不丢失数据"

**矛盾**:
```
验收标准 #3: 服务异常不丢失数据
实际设计: 服务崩溃后内存数据丢失
```

**风险评级**: 🔴 **高**

**建议**:
1. **方案A**: 实现 Write-Ahead Log (WAL) 机制，将数据先写入磁盘日志再写入内存缓冲区
2. **方案B**: 实现定期快照机制，将缓冲区数据定期写入磁盘
3. **方案C**: 降低验收标准，改为"正常关闭时不丢失数据"

**推荐**: 方案C 作为最小化实现，WAL 作为后续迭代特性

### 问题 #6.2: 容量触发逻辑可能提前刷新

**位置**: 7.1 节

**问题描述**:
- 设计说"如果任何通道的缓冲区大小 >= `max_size`，立即触发刷新"
- 但 `max_size` 是 `BufferConfig` 的单一值，没有明确定义是 per-channel 还是 total

**示例**:
```
假设 max_size = 10000
Channel A: 10000 points -> 触发刷新
Channel B: 0 points
```
此时 Channel A 单独刷新，但设计说要清空"所有通道缓冲区"（8.3 步骤 7）

**建议**: 明确 `max_size` 的语义（per-channel 或 per-buffer），并修正刷新逻辑

---

## 7. 具体技术问题

### 7.1 close_buffer 与 delete_buffer 行为差异

**问题**: 两者都执行"强制刷新后"操作，但未说明:
- `close_buffer`: 是否从 `buffers` map 中移除？是否允许后续操作？
- `delete_buffer`: 是否从 `buffers` map 中移除？

**建议**: 明确两者行为差异

### 7.2 追加写入限制未充分强调

**问题**: 9.2 节提到"每次 flush 会覆盖同名 dataset，而非追加"，但:
- 如果实验持续运行，后面的 flush 会覆盖前面的数据
- 这对于长时间实验是不可接受的

**建议**: 
- 在验收标准中明确此限制
- 或考虑在 flush 时追加模式而非覆盖模式

---

## 8. 建议改进清单

### 必须修复（阻塞实现）

| # | 问题 | 优先级 |
|---|------|--------|
| P0 | 澄清 `flush_scheduler` 是否需要后台定时器 | 高 |
| P0 | 明确 `ChannelBuffer.points` 的并发控制机制 | 高 |
| P0 | 解决"服务异常不丢失数据"验收标准与当前设计的矛盾 | 高 |

### 建议改进

| # | 问题 | 优先级 |
|---|------|--------|
| P1 | 明确 `max_size` 是 per-channel 还是 per-buffer | 中 |
| P2 | 明确 `close_buffer` vs `delete_buffer` 行为差异 | 中 |
| P2 | 考虑缓存 HDF5 文件句柄减少 open/close 开销 | 中 |
| P3 | `DataLoss` 错误类型使用场景不明，考虑移除或明确 | 低 |

---

## 9. 总结

**设计优点**:
- 架构清晰，trait+impl 模式正确
- 错误类型定义完善
- 锁策略总体合理

**必须解决**:
1. `flush_scheduler` 机制不明确（是否需要后台定时器？）
2. `ChannelBuffer.points` 访问控制未明确定义
3. **数据安全性矛盾**: 验收标准 #3 要求不丢失数据，但设计承认崩溃时会丢失内存数据

**建议**: 在解决上述 P0 问题后，设计可以进入实现阶段。

---

**审查人**: sw-jerry  
**审查日期**: 2026-03-27
