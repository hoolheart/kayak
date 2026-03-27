# S2-003 设计审查报告 (v2)

**任务ID**: S2-003  
**任务名称**: 时序数据写入服务 (Time-series Data Writing Service)  
**审查版本**: v2  
**审查日期**: 2026-03-27  
**审查人**: sw-jerry (Software Architect)

---

## 1. 审查背景

### 1.1 上次审查发现的问题

| 问题编号 | 问题描述 |
|---------|---------|
| #1 | flush_scheduler 机制不明确 |
| #2 | ChannelBuffer.points 无锁保护 |
| #3 | 数据安全保证存在矛盾 |

### 1.2 本次审查目的

验证修订后的设计是否正确解决上述三个问题。

---

## 2. 问题逐一审核

### 问题 #1: flush_scheduler 机制 ✅ 已解决

**原问题**: flush_scheduler 后台刷新任务的生命周期管理机制不清晰

**修订后的设计** (Section 6.3):
> 本服务**不包含后台刷新任务**。刷新触发方式：
> 1. **容量触发**: `write_point`/`write_batch` 写入后检查，缓冲区超限立即刷新
> 2. **时间触发**: `write_point`/`write_batch` 写入后检查，距上次刷新超时间隔则刷新
> 3. **手动触发**: 调用方主动调用 `flush()` 接口

**评价**: 
- flush_scheduler 已被移除
- 改为简单的触发机制：容量触发 + 时间触发 + 手动触发
- 明确说明"如需后台定时刷新，可在调用层（业务层）定期调用 `flush()`"
- 设计简洁，避免了后台任务生命周期管理的复杂性

**结论**: ✅ 已正确解决

---

### 问题 #2: ChannelBuffer.points 锁保护 ⚠️ 部分解决

**原问题**: ChannelBuffer.points 无锁保护

**修订后的设计**:

Section 6.1 定义:
```rust
struct ChannelBuffer {
    name: String,
    points: Vec<TimeSeriesPoint>,
    last_flush_at: DateTime<Utc>,
    points_lock: tokio::sync::Mutex<()>,  // 锁字段
}
```

Section 6.2 锁层次:
```
buffers RwLock (service层)
  └── ExperimentBuffer Mutex
        ├── channels_lock Mutex
        │     └── ChannelBuffer (per channel, 无需独立锁)
        ├── is_flushing Mutex
        └── is_closed Mutex
```

Section 11.1 锁策略表:
| 数据结构 | 锁类型 | 保护内容 |
|---------|--------|---------|
| `ChannelBuffer.points` | 无独立锁 | 通过 ExperimentBuffer 锁层次保护 |

**矛盾之处**:
- `ChannelBuffer` 结构体中声明了 `points_lock: tokio::sync::Mutex<()>`
- 但 Section 11.1 表格明确说明 `ChannelBuffer.points` **无独立锁**，依赖 ExperimentBuffer 的锁层次
- Section 6.1 注释说"此字段通过外层 Mutex 保护，不直接暴露给外部"

**分析**:
- 如果按照 Section 11.1 的说明，`points_lock` 字段是**冗余/未使用**的
- 实际保护机制是：`channels_lock` → `ExperimentBuffer 锁` → `ChannelBuffer.points`

**结论**: 
- 锁保护机制存在（通过 ExperimentBuffer 层次）
- 但 `points_lock` 字段是**冗余代码**，应删除以避免混淆
- 建议：移除 `points_lock` 字段，或明确说明其用途

**状态**: ⚠️ 需要小幅修改（删除冗余字段）

---

### 问题 #3: 数据安全保证 ✅ 已解决

**原问题**: 数据安全保证描述存在矛盾

**修订后的设计** (Section 1.3):
> **⚠️ 数据安全级别说明**
>
> 本服务提供 **尽力而为 (Best-Effort)** 的数据持久化保证：
>
> | 场景 | 数据安全保证 | 说明 |
> |------|-------------|------|
> | 正常 flush | ✅ 数据写入 HDF5 | flush 成功后数据持久化 |
> | close_buffer / delete_buffer | ✅ 数据写入 HDF5 | 关闭前强制刷新 |
> | 服务异常崩溃 | ⚠️ 可能丢失 | 内存缓冲区数据未刷新会丢失 |
> | 进程正常退出 | ✅ 数据写入 HDF5 | drop 时自动 flush（若实现） |
>
> **如需更高安全级别（硬保证），需实现 WAL (Write-Ahead Log)**

**评价**:
- 明确标注为 "Best-Effort" 尽力而为
- 表格清晰列出各场景的数据安全级别
- 明确说明崩溃场景下数据可能丢失
- 提供了 WAL 作为未来升级方案

**结论**: ✅ 已正确解决

---

## 3. 剩余问题汇总

### 3.1 需要修改的问题

| 问题 | 描述 | 严重程度 |
|-----|------|---------|
| A | `ChannelBuffer.points_lock` 字段冗余 | 低 |

**问题 A 详细说明**:

`ChannelBuffer` 结构体中声明了 `points_lock: tokio::sync::Mutex<()>` 字段，但根据 Section 11.1 的锁策略表和 Section 6.2 的锁层次图，实际保护机制是通过 `ExperimentBuffer` 的锁层次实现的，而不是依赖 `ChannelBuffer` 自身的锁。

这个字段:
- 被声明但从未在代码中使用
- 容易造成误解，以为有双重锁保护
- 应该删除以保持设计一致性

**建议修复**:
```rust
// 删除 points_lock 字段
struct ChannelBuffer {
    name: String,
    points: Vec<TimeSeriesPoint>,  // 通过外层 ExperimentBuffer 锁保护
    last_flush_at: DateTime<Utc>,
    // points_lock: tokio::sync::Mutex<()>,  // 删除此行
}
```

---

## 4. 总体评价

### 4.1 改进点

1. ✅ **flush_scheduler 已移除** - 改为简单的触发机制，设计更清晰
2. ✅ **数据安全已明确** - Best-Effort 策略清晰标注，各场景说明完整
3. ✅ **锁层次结构已文档化** - Section 11.1 和 11.2 详细说明了锁策略

### 4.2 剩余问题

1. ⚠️ **`points_lock` 冗余字段** - 建议删除，避免误解

---

## 5. 审查结论

| 项目 | 状态 |
|-----|------|
| flush_scheduler 机制 | ✅ 已解决 |
| ChannelBuffer.points 锁保护 | ⚠️ 机制正确，但有冗余字段 |
| 数据安全保证 | ✅ 已解决 |

### 最终判定: **Needs More Revision**

**原因**: 虽然三个主要问题都已得到有效解决，但存在一个小的代码质量问题：`ChannelBuffer` 结构体中的 `points_lock` 字段是冗余的，应删除以保持设计一致性。

### 建议操作:

1. 删除 `ChannelBuffer.points_lock` 字段及其初始化代码
2. 更新 Section 6.1 中的 ChannelBuffer 结构体定义
3. 确认修改后，设计可以通过最终审查

---

**审查人**: sw-jerry  
**审查日期**: 2026-03-27
