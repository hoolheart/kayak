# Bug 跟踪记录 — Release 2

**维护者**: sw-mike  
**最后更新**: 2026-05-10

---

## Bug #R2-001

### 基本信息

| 项目 | 内容 |
|------|------|
| **Bug ID** | R2-001 |
| **发现日期** | 2026-05-10 |
| **发现人** | sw-mike |
| **任务来源** | R2-S1-001-E HDF5 时序数据查询 API 测试执行 |
| **严重级别** | High |
| **优先级** | High |
| **状态** | ✅ CLOSED |
| **指派给** | sw-tom |

### 问题描述

`downsample` 参数的最小值验证过宽，允许传入 `downsample = 1`，但 LTTB 算法在 `threshold = 1` 时行为异常。

### 受影响文件

- `kayak-backend/src/models/dto/experiment_data_query.rs` 第 23 行

### 当前代码

```rust
#[validate(range(min = 1, max = 10000))]
pub downsample: Option<usize>,
```

### 预期行为（来自测试用例 TC-ERR-010）

- `downsample = 1` → HTTP 400 Bad Request
- 错误消息包含 "downsample must be >= 2"

### 实际行为

- `downsample = 1` 通过验证，进入 LTTB 算法
- LTTB 算法中 `bucket_size = (n - 2) / (1 - 2) = -(n - 2)` 为负数
- 主循环 `for i in 1..(threshold - 1)` = `1..0` 为空循环
- 最终返回首尾 2 个点，而非用户期望的 1 个点
- 违反 PRD 对 downsample 范围的定义

### 根因分析

1. DTO 验证宏 `#[validate(range(min = 1))]` 允许最小值为 1
2. LTTB 算法要求 `threshold >= 2` 才能形成有意义的桶划分（`threshold - 2` 为分母）
3. 测试用例明确约束 `downsample >= 2`

### 修复建议

将 `kayak-backend/src/models/dto/experiment_data_query.rs` 第 23 行：

```rust
#[validate(range(min = 1, max = 10000))]
```

改为：

```rust
#[validate(range(min = 2, max = 10000))]
```

默认值 `1000` 已满足 `>= 2`，无需调整。

### 验证步骤

修复后，应验证：
1. `downsample = 1` 的请求返回 HTTP 400
2. `downsample = 2` 的请求正常通过
3. `downsample = 10000` 的请求正常通过
4. `downsample = 10001` 的请求返回 HTTP 400
5. 不传入 `downsample` 时默认使用 1000

### 相关测试用例

- TC-ERR-010: downsample = 1 → 400
- TC-ERR-009: downsample = 0 → 400（当前已满足）
- TC-DOWN-004: downsample = 2 → 正常工作

---

## Bug #R2-002（观察项，非功能性缺陷）

### 基本信息

| 项目 | 内容 |
|------|------|
| **Bug ID** | R2-002 |
| **发现日期** | 2026-05-10 |
| **发现人** | sw-mike |
| **严重级别** | Low |
| **优先级** | Low |
| **状态** | ✅ CLOSED (by design) |
| **指派给** | sw-tom |

### 问题描述

LTTB 算法在 `N == D`（数据点数等于 downsample 阈值）时直接返回原始数据，不执行 LTTB 降采样逻辑。

### 受影响文件

- `kayak-backend/src/services/lttb.rs` 第 52 行

### 当前代码

```rust
if n <= threshold {
    return (timestamps.to_vec(), values.to_vec());
}
```

### 测试用例期望（TC-DOWN-003）

当 `N = D` 时，应触发 LTTB 算法，返回经过 LTTB 选择的 D 个点（含首尾，中间 D-2 个桶）。

### 影响评估

- 返回的点数相同（均为 D 个），**不构成功能缺陷**
- 从算法一致性角度，`N >= D` 均应走 LTTB 路径
- 建议改为 `if n < threshold` 以统一行为

### 修复建议（可选）

```rust
if n < threshold {
    return (timestamps.to_vec(), values.to_vec());
}
```

---

## 修复状态更新
- 2026-05-10: Bug R2-001 已修复（downsample min 改为 2）
- 2026-05-10: Bug R2-002 关闭（N<=threshold 返回原始数据是设计选择）

---

## Bug #R2-003

### 基本信息

| 项目 | 内容 |
|------|------|
| **Bug ID** | R2-003 |
| **发现日期** | 2026-05-11 |
| **发现人** | sw-mike |
| **任务来源** | 前端分析模块测试创建 |
| **严重级别** | Medium |
| **优先级** | Medium |
| **状态** | ✅ CLOSED |
| **指派给** | sw-tom |

### 问题描述

`AnalysisControllerNotifier.selectExperiment()` 和 `selectDevice()` 方法中 `const []` 类型推断为 `List<dynamic>`，在 `AnalysisControlState.copyWith` 中 cast 到 `List<String>` 时运行时抛出 `TypeError`。

### 修复状态

✅ 已在 commit `de50289` 修复：将 `const []` 改为 `const <String>[]`

### 受影响文件

- `kayak-frontend/lib/features/analysis/providers/analysis_controller_provider.dart` 第 146、155 行

### 当前代码

```dart
void selectExperiment(String? experimentId) {
  state = state.copyWith(
    selectedExperimentId: experimentId,
    selectedDeviceId: null,
    selectedPointIds: const [],   // ← List<dynamic>
  );
}

void selectDevice(String? deviceId) {
  state = state.copyWith(
    selectedDeviceId: deviceId,
    selectedPointIds: [],         // ← List<dynamic>
  );
}
```

### 实际行为

运行时异常：`type 'List<dynamic>' is not a subtype of type 'List<String>' in type cast`

### 修复建议

```dart
selectedPointIds: const <String>[],
```

---

## Bug #R2-004

### 基本信息

| 项目 | 内容 |
|------|------|
| **Bug ID** | R2-004 |
| **发现日期** | 2026-05-11 |
| **发现人** | sw-mike |
| **任务来源** | 前端分析模块测试创建 |
| **严重级别** | Low |
| **优先级** | Low |
| **状态** | ✅ CLOSED |
| **指派给** | sw-tom |

### 问题描述

`ChartViewState.copyWith()` 中 `hoveredSeriesIndex` 参数使用 `??` 操作符，导致无法通过 `copyWith` 将 `hoveredSeriesIndex` 设为 `null`。

### 修复状态

✅ 已在 commit `de50289` 修复：使用 sentinel 模式（`Object()`）区分"不修改"和"设为 null"。

---

## 修复状态更新汇总
- 2026-05-10: Bug R2-001 已修复（downsample min 改为 2）
- 2026-05-10: Bug R2-002 关闭（N<=threshold 返回原始数据是设计选择）
- 2026-05-11: Bug R2-003 已修复（`const <String>[]` 类型推断）
- 2026-05-11: Bug R2-004 已修复（sentinel 模式处理 null）

*本文档由 sw-mike 维护，所有 bug 已修复。*
