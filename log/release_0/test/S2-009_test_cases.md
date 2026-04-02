# S2-009 Test Cases: 基础环节执行引擎

**Task ID**: S2-009
**Task Name**: 基础环节执行引擎
**Test Version**: 2.0
**Date**: 2026-04-02

---

## 测试概述

本文档定义基础环节执行引擎的测试用例，覆盖以下方面：
1. 环节定义解析（JSON 格式的过程定义）
2. 五种环节类型的独立执行器（Start、Read、Control、Delay、End）
3. 线性过程执行（多环节顺序执行）
4. 执行上下文管理
5. 环节执行日志记录
6. 错误处理
7. ExecutionListener 回调机制
8. 与现有组件的集成（VirtualDriver、Method 模型）

> **注意**：执行引擎与 StateMachine/ExperimentControlService 的集成将在 S2-011 中完成。S2-009 的引擎通过 `ExecutionListener` trait 提供回调通知机制，S2-011 将实现该 trait 以桥接 StateMachine。

---

## 执行上下文结构定义

执行上下文（`ExecutionContext`）是环节执行引擎在运行过程中维护的状态容器，定义如下：

```rust
pub struct ExecutionContext {
    /// 变量存储：Read 环节的输出存入此映射
    pub variables: HashMap<String, PointValue>,
    /// 过程开始时间（由 Start 环节设置）
    pub start_time: Option<DateTime<Utc>>,
    /// 执行状态
    pub status: ExecutionStatus,
    /// 环节执行日志
    pub logs: Vec<StepLogEntry>,
}

pub enum ExecutionStatus {
    /// 初始状态
    Initialized,
    /// 已开始（Start 环节已执行）
    Running,
    /// 已完成（End 环节已执行）
    Completed,
    /// 执行失败
    Failed,
}

pub struct StepLogEntry {
    pub step_id: String,
    pub step_type: StepType,
    pub step_name: String,
    pub start_time: DateTime<Utc>,
    pub end_time: DateTime<Utc>,
    pub status: StepStatus, // Success / Failed
    pub duration_ms: u64,
    pub error_message: Option<String>,
}
```

### ExecutionListener 回调机制

执行引擎通过 `ExecutionListener` trait 向外部通知执行事件。StateMachine 集成将在 S2-011 中通过实现此 trait 完成。

```rust
pub trait ExecutionListener: Send + Sync {
    /// 环节开始执行时调用
    fn step_started(&self, step: &StepDefinition);
    /// 环节成功完成时调用
    fn step_completed(&self, step: &StepDefinition, result: &StepResult);
    /// 环节执行失败时调用
    fn step_failed(&self, step: &StepDefinition, error: &ExecutionError);
    /// 整个过程执行完成时调用（无论成功或失败）
    fn process_completed(&self, result: &ProcessResult);
}
```

引擎接受一个可选的 `Arc<dyn ExecutionListener>` 参数。若未提供监听器，引擎仍正常执行但不发送通知。

---

## 环节类型参考

| 环节类型 | 必填字段 | 可选字段 | 说明 |
|----------|----------|----------|------|
| Start | id, type, name | 无 | 标记试验开始，初始化执行上下文 |
| Read | id, type, name, point_id, target_var | 无 | 从设备测点读取值，存入执行上下文 |
| Control | id, type, name, point_id, value | 无 | 向设备测点写入控制值 |
| Delay | id, type, name, duration_ms | 无 | 暂停执行指定时长（毫秒） |
| End | id, type, name | 无 | 标记试验结束，触发完成状态 |

### 过程定义 JSON 格式

```json
{
  "version": "1.0",
  "steps": [
    { "id": "step-1", "type": "Start", "name": "开始试验" },
    { "id": "step-2", "type": "Read", "name": "读取温度", "point_id": "uuid", "target_var": "temperature" },
    { "id": "step-3", "type": "Control", "name": "设置加热器", "point_id": "uuid", "value": 100.0 },
    { "id": "step-4", "type": "Delay", "name": "等待10秒", "duration_ms": 10000 },
    { "id": "step-5", "type": "Read", "name": "读取温度后", "point_id": "uuid", "target_var": "temperature_after" },
    { "id": "step-6", "type": "End", "name": "结束试验" }
  ]
}
```

---

## 测试用例

### 一、环节定义解析测试

#### TC-S2-009-001: 解析有效过程定义

**Description**: 验证引擎能正确解析包含所有五种环节类型的有效 JSON 过程定义。

**Preconditions**: 无

**Test Steps**:
1. 构造包含 Start、Read、Control、Delay、End 五种环节的 JSON 过程定义
2. 使用引擎的解析函数解析该 JSON
3. 验证解析结果中的步骤数量
4. 验证每个步骤的类型、ID、名称正确解析
5. 验证 Read 步骤的 point_id 和 target_var 正确解析
6. 验证 Control 步骤的 point_id 和 value 正确解析
7. 验证 Delay 步骤的 duration_ms 正确解析

**Expected Results**:
- 解析成功，返回 Ok
- 步骤数量与 JSON 中定义的一致
- 每个步骤的类型枚举值正确
- 各环节特有字段正确映射到对应结构体字段

**Priority**: P0

---

#### TC-S2-009-002: 解析仅含 Start 和 End 的最小过程定义

**Description**: 验证引擎能解析最简单的 Start->End 过程定义。

**Preconditions**: 无

**Test Steps**:
1. 构造仅包含 Start 和 End 两个步骤的 JSON 过程定义
2. 解析该 JSON
3. 验证解析出两个步骤，类型分别为 Start 和 End

**Expected Results**:
- 解析成功
- 步骤数量为 2
- 第一个步骤类型为 Start，第二个为 End

**Priority**: P0

---

#### TC-S2-009-003: 解析空步骤列表

**Description**: 验证引擎处理空步骤列表的行为。

**Preconditions**: 无

**Test Steps**:
1. 构造 steps 数组为空的 JSON 过程定义 `{"version": "1.0", "steps": []}`
2. 解析该 JSON
3. 验证解析结果

**Expected Results**:
- 解析成功（空列表是合法的）
- 步骤数量为 0
- 执行该过程时应立即完成或返回空结果

**Priority**: P1

---

#### TC-S2-009-004: 处理缺失必填字段 — Read 缺少 point_id

**Description**: 验证 Read 环节缺少 point_id 时返回解析错误。

**Preconditions**: 无

**Test Steps**:
1. 构造 Read 环节 JSON，包含 id、type、name、target_var，但缺少 point_id
2. 尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息指出缺少 point_id 字段

**Priority**: P0

---

#### TC-S2-009-005: 处理缺失必填字段 — Read 缺少 target_var

**Description**: 验证 Read 环节缺少 target_var 时返回解析错误。

**Preconditions**: 无

**Test Steps**:
1. 构造 Read 环节 JSON，包含 id、type、name、point_id，但缺少 target_var
2. 尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息指出缺少 target_var 字段

**Priority**: P0

---

#### TC-S2-009-006: 处理缺失必填字段 — Control 缺少 value

**Description**: 验证 Control 环节缺少 value 时返回解析错误。

**Preconditions**: 无

**Test Steps**:
1. 构造 Control 环节 JSON，包含 id、type、name、point_id，但缺少 value
2. 尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息指出缺少 value 字段

**Priority**: P0

---

#### TC-S2-009-007: 处理缺失必填字段 — Delay 缺少 duration_ms

**Description**: 验证 Delay 环节缺少 duration_ms 时返回解析错误。

**Preconditions**: 无

**Test Steps**:
1. 构造 Delay 环节 JSON，包含 id、type、name，但缺少 duration_ms
2. 尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息指出缺少 duration_ms 字段

**Priority**: P0

---

#### TC-S2-009-008: 处理无效环节类型

**Description**: 验证引擎对未知环节类型的处理。

**Preconditions**: 无

**Test Steps**:
1. 构造包含 `"type": "Unknown"` 的步骤 JSON
2. 尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息指出未知的环节类型 "Unknown"

**Priority**: P0

---

#### TC-S2-009-009: 处理字段类型错误 — duration_ms 为字符串

**Description**: 验证 Delay 环节 duration_ms 字段类型不正确时的处理。

**Preconditions**: 无

**Test Steps**:
1. 构造 Delay 环节 JSON，其中 duration_ms 为字符串 `"10000"` 而非数字 `10000`
2. 尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息指出 duration_ms 字段类型不正确

**Priority**: P1

---

#### TC-S2-009-010: 处理无效 JSON 格式

**Description**: 验证引擎对格式错误的 JSON 输入的处理。

**Preconditions**: 无

**Test Steps**:
1. 传入格式错误的 JSON 字符串（如缺少闭合括号）
2. 尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息描述 JSON 格式错误

**Priority**: P1

---

#### TC-S2-009-011: 解析含多步骤的复杂过程定义

**Description**: 验证引擎能正确解析包含多个同类型步骤的复杂过程定义。

**Preconditions**: 无

**Test Steps**:
1. 构造包含 3 个 Read 步骤和 2 个 Control 步骤的 JSON 过程定义
2. 解析该 JSON
3. 验证所有步骤正确解析，ID 不重复
4. 验证每个 Read 步骤的 target_var 不同
5. 验证每个 Control 步骤的 value 不同

**Expected Results**:
- 解析成功
- 步骤数量正确
- 每个步骤的字段值与 JSON 定义一致

**Priority**: P1

---

#### TC-S2-009-012: 解析含重复步骤 ID 的过程定义

**Description**: 验证引擎在解析过程中检测到重复步骤 ID 时返回错误。

**Preconditions**: 无

**Test Steps**:
1. 构造过程定义 JSON，其中两个步骤具有相同的 id（如 `"id": "step-1"` 出现两次）
2. 尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息指出存在重复的步骤 ID
- 错误信息包含重复的 ID 值

**Priority**: P1

---

### 二、独立环节执行器测试

#### TC-S2-009-013: Start 环节 — 初始化执行上下文

**Description**: 验证 Start 环节正确初始化执行上下文。

**Preconditions**: 无

**Test Steps**:
1. 创建空的执行上下文
2. 创建 Start 环节定义
3. 执行 Start 环节
4. 验证执行上下文已初始化（如记录开始时间、状态标记等）

**Expected Results**:
- 执行成功，返回 Ok
- 执行上下文包含开始时间戳
- 执行上下文状态标记为 Running

**Priority**: P0

---

#### TC-S2-009-014: Start 环节 — 重复执行（幂等性）

**Description**: 验证在同一执行上下文中重复执行 Start 环节的行为为幂等操作。

**Preconditions**: 已执行过一次 Start 环节

**Test Steps**:
1. 创建执行上下文并执行 Start 环节，记录开始时间戳 T1
2. 等待 1ms
3. 再次执行 Start 环节
4. 读取执行上下文中的开始时间戳 T2
5. 验证执行上下文状态

**Expected Results**:
- 第二次执行返回 Ok（成功）
- 开始时间戳不变（T1 == T2），即 Start 为 no-op
- 执行上下文状态保持 Running，无额外副作用
- 不产生额外的日志记录

**Priority**: P2

---

#### TC-S2-009-015: Read 环节 — 从 VirtualDriver 读取数据

**Description**: 验证 Read 环节能从已连接的 VirtualDriver 读取测点值并存入上下文。

**Preconditions**: 
- VirtualDriver 已创建并连接
- VirtualDriver 配置为 Fixed 模式，fixed_value = PointValue::Number(42.0)

**Test Steps**:
1. 创建执行上下文
2. 创建 Read 环节，point_id 为某 UUID，target_var = "test_value"
3. 执行 Read 环节，传入 VirtualDriver
4. 验证执行上下文中 "test_value" 的值

**Expected Results**:
- 执行成功，返回 Ok
- 执行上下文中 "test_value" 的值为 PointValue::Number(42.0)
- 执行日志记录读取操作

**Priority**: P0

---

#### TC-S2-009-016: Read 环节 — 读取 Random 模式数据

**Description**: 验证 Read 环节能从 Random 模式的 VirtualDriver 读取数据。

**Preconditions**:
- VirtualDriver 已创建并连接，配置为 Random 模式，min=0.0, max=100.0

**Test Steps**:
1. 创建执行上下文
2. 创建 Read 环节，target_var = "random_value"
3. 执行 Read 环节
4. 验证上下文中 "random_value" 的值在 [0.0, 100.0) 范围内

**Expected Results**:
- 执行成功
- 读取的值为 PointValue::Number 类型
- 数值在配置的范围内

**Priority**: P1

---

#### TC-S2-009-017: Read 环节 — 未连接设备时读取

**Description**: 验证 Read 环节在设备未连接时返回错误。

**Preconditions**:
- VirtualDriver 已创建但未调用 connect()

**Test Steps**:
1. 创建执行上下文
2. 创建 Read 环节
3. 在未连接的 VirtualDriver 上执行 Read 环节
4. 验证返回错误

**Expected Results**:
- 执行失败，返回 Err
- 错误类型为 DriverError::NotConnected 或等效的引擎错误

**Priority**: P0

---

#### TC-S2-009-018: Control 环节 — 向 VirtualDriver 写入数据

**Description**: 验证 Control 环节能向 RW 模式的 VirtualDriver 写入值。

**Preconditions**:
- VirtualDriver 已创建并连接，配置为 RW 访问类型，DataType::Number

**Test Steps**:
1. 创建执行上下文
2. 创建 Control 环节，point_id 为某 UUID，value = PointValue::Number(75.0)
3. 执行 Control 环节
4. 使用 VirtualDriver.read_point() 验证写入的值

**Expected Results**:
- 执行成功，返回 Ok
- 通过 read_point 读取到的值为 PointValue::Number(75.0)
- 执行日志记录写入操作

**Priority**: P0

---

#### TC-S2-009-019: Control 环节 — 向 RO 设备写入

**Description**: 验证 Control 环节向只读设备写入时返回错误。

**Preconditions**:
- VirtualDriver 已创建并连接，配置为 RO 访问类型

**Test Steps**:
1. 创建执行上下文
2. 创建 Control 环节
3. 执行 Control 环节
4. 验证返回错误

**Expected Results**:
- 执行失败，返回 Err
- 错误类型为 DriverError::ReadOnlyPoint 或等效的引擎错误

**Priority**: P0

---

#### TC-S2-009-020: Control 环节 — 写入不同类型值

**Description**: 验证 Control 环节能向不同数据类型的测点写入对应类型的值。

**Preconditions**: 无

**Test Steps**:
1. 创建 VirtualDriver 实例 A，配置为 RW 类型，DataType::Number；创建 Control 环节，value = PointValue::Number(1.5)；执行并验证写入成功
2. 创建 VirtualDriver 实例 B，配置为 RW 类型，DataType::Integer；创建 Control 环节，value = PointValue::Integer(42)；执行并验证写入成功
3. 创建 VirtualDriver 实例 C，配置为 RW 类型，DataType::Boolean；创建 Control 环节，value = PointValue::Boolean(true)；执行并验证写入成功
4. 创建 VirtualDriver 实例 D，配置为 RW 类型，DataType::String；创建 Control 环节，value = PointValue::String("test")；执行并验证写入成功

**Expected Results**:
- 每次写入都成功
- 每个 VirtualDriver 实例读取到的值与写入值一致
- 每次执行都记录日志

**Priority**: P1

---

#### TC-S2-009-021: Delay 环节 — 短延迟执行

**Description**: 验证 Delay 环节能正确等待指定时长（使用短延迟 10ms 测试）。

**Preconditions**: 无

**Test Steps**:
1. 创建 Delay 环节，duration_ms = 10
2. 记录执行开始时间
3. 执行 Delay 环节
4. 记录执行结束时间
5. 计算实际等待时间

**Expected Results**:
- 执行成功
- 实际等待时间 >= 10ms
- 实际等待时间 < 50ms（允许合理误差）

**Priority**: P0

---

#### TC-S2-009-022: Delay 环节 — 零延迟

**Description**: 验证 Delay 环节处理 duration_ms = 0 的情况。

**Preconditions**: 无

**Test Steps**:
1. 创建 Delay 环节，duration_ms = 0
2. 执行 Delay 环节
3. 验证执行结果

**Expected Results**:
- 执行成功
- 几乎不等待（< 5ms）

**Priority**: P2

---

#### TC-S2-009-023: Delay 环节 — 负数延迟

**Description**: 验证 Delay 环节处理负数 duration_ms 的行为。

**Preconditions**: 无

**Test Steps**:
1. 尝试创建 duration_ms = -100 的 Delay 环节
2. 验证解析或执行结果

**Expected Results**:
- 解析阶段或执行阶段返回错误
- 错误信息指出 duration_ms 不能为负数

**Priority**: P1

---

#### TC-S2-009-024: End 环节 — 标记执行完成

**Description**: 验证 End 环节正确标记执行完成。

**Preconditions**: 无

**Test Steps**:
1. 创建执行上下文
2. 创建 End 环节
3. 执行 End 环节
4. 验证执行上下文状态

**Expected Results**:
- 执行成功，返回 Ok
- 执行上下文标记为 Completed
- 返回信号指示过程应终止

**Priority**: P0

---

#### TC-S2-009-025: Control 环节 — 向 WO 设备写入

**Description**: 验证 Control 环节能向只写（WO）模式的 VirtualDriver 写入值。

**Preconditions**:
- VirtualDriver 已创建并连接，配置为 WO 访问类型，DataType::Number

**Test Steps**:
1. 创建执行上下文
2. 创建 Control 环节，point_id 为某 UUID，value = PointValue::Number(50.0)
3. 执行 Control 环节
4. 验证执行结果

**Expected Results**:
- 执行成功，返回 Ok
- 写入操作被接受（不抛出 ReadOnlyPoint 错误）
- 执行日志记录写入操作

**Priority**: P1

---

### 三、线性过程执行测试

#### TC-S2-009-026: 执行 Start -> End 简单过程

**Description**: 验证引擎能执行最简单的 Start->End 过程。

**Preconditions**: 无

**Test Steps**:
1. 构造包含 Start 和 End 两个步骤的过程定义
2. 创建执行引擎实例
3. 执行该过程
4. 验证执行结果

**Expected Results**:
- 执行成功
- 两个步骤都执行完毕
- 执行日志包含两条记录
- 最终状态为完成

**Priority**: P0

---

#### TC-S2-009-027: 执行完整 Start -> Read -> Control -> Delay -> Read -> End 过程

**Description**: 验证引擎能执行包含所有环节类型的完整过程（验收标准核心场景）。

**Preconditions**:
- VirtualDriver 已创建并连接，配置为 RW 类型，Fixed 模式

**Test Steps**:
1. 构造包含以下步骤的过程定义：
   - Start: 开始试验
   - Read: 读取初始值到 "initial_value"
   - Control: 写入控制值 50.0
   - Delay: 等待 10ms
   - Read: 读取控制后的值到 "controlled_value"
   - End: 结束试验
2. 创建执行引擎，传入 VirtualDriver
3. 执行该过程
4. 验证执行结果和执行上下文

**Expected Results**:
- 所有步骤按顺序执行成功
- 执行上下文中 "initial_value" 和 "controlled_value" 都有值
- 执行日志包含 6 条记录
- 最终状态为完成
- 满足验收标准 1 和 2

**Priority**: P0

---

#### TC-S2-009-028: 执行含多个 Read 步骤的过程

**Description**: 验证引擎能正确执行包含多个 Read 步骤的过程。

**Preconditions**:
- VirtualDriver 已创建并连接，Fixed 模式，fixed_value = PointValue::Number(25.0)

**Test Steps**:
1. 构造过程定义：Start -> Read(temperature) -> Read(humidity) -> Read(pressure) -> End
2. 每个 Read 步骤使用相同的 point_id（因为 VirtualDriver 对同一 point_id 返回相同值）
3. 执行过程
4. 验证执行上下文中三个变量都有值

**Expected Results**:
- 所有步骤执行成功
- 执行上下文中 temperature、humidity、pressure 三个变量都有值
- 每个变量值均为 PointValue::Number(25.0)
- 执行日志包含 5 条记录

**Priority**: P1

---

#### TC-S2-009-029: 执行含多个 Control 步骤的过程

**Description**: 验证引擎能正确执行包含多个 Control 步骤的过程。

**Preconditions**:
- VirtualDriver 已创建并连接，RW 类型

**Test Steps**:
1. 构造过程定义：Start -> Control(value=10) -> Control(value=20) -> Control(value=30) -> End
2. 使用不同的 point_id 用于每个 Control 步骤
3. 执行过程
4. 验证每个 point_id 对应的值

**Expected Results**:
- 所有步骤执行成功
- 每个 point_id 的值与 Control 步骤中定义的 value 一致
- 执行日志包含 5 条记录

**Priority**: P1

---

#### TC-S2-009-030: 执行单步骤过程（仅 Start）

**Description**: 验证引擎能执行仅包含一个 Start 步骤的过程。

**Preconditions**: 无

**Test Steps**:
1. 构造仅包含 Start 步骤的过程定义
2. 执行该过程
3. 验证执行结果

**Expected Results**:
- 执行成功
- Start 步骤执行完毕
- 执行日志包含 1 条记录
- 最终状态为 Completed（所有步骤已执行）

**Priority**: P1

---

#### TC-S2-009-031: 执行空过程

**Description**: 验证引擎处理空步骤列表的过程。

**Preconditions**: 无

**Test Steps**:
1. 构造 steps 为空数组的过程定义
2. 执行该过程
3. 验证执行结果

**Expected Results**:
- 执行成功（空过程视为立即完成）
- 执行日志为空或包含一条"空过程"记录
- 不报错

**Priority**: P1

---

#### TC-S2-009-032: 环节执行顺序验证

**Description**: 验证引擎严格按照步骤定义的顺序执行。

**Preconditions**: 无

**Test Steps**:
1. 构造过程定义：Start -> Delay(10ms) -> Delay(10ms) -> Delay(10ms) -> End
2. 执行过程
3. 检查执行日志中步骤的执行顺序
4. 验证总执行时间 >= 30ms

**Expected Results**:
- 步骤按定义顺序执行
- 执行日志中步骤顺序与定义一致
- 总执行时间 >= 30ms

**Priority**: P0

---

### 四、执行上下文测试

#### TC-S2-009-033: 上下文变量存储与读取

**Description**: 验证执行上下文能正确存储和读取变量。

**Preconditions**: 无

**Test Steps**:
1. 创建执行上下文
2. 通过 Read 环节或手动方式存入变量 "var1" = PointValue::Number(100.0)
3. 存入变量 "var2" = PointValue::String("hello")
4. 从上下文读取 "var1" 和 "var2"
5. 验证值正确

**Expected Results**:
- "var1" 的值为 PointValue::Number(100.0)
- "var2" 的值为 PointValue::String("hello")
- 变量名区分大小写

**Priority**: P0

---

#### TC-S2-009-034: 上下文变量覆盖

**Description**: 验证同一变量名被多次写入时的行为。

**Preconditions**: 无

**Test Steps**:
1. 创建执行上下文
2. 存入变量 "x" = PointValue::Number(1.0)
3. 再次存入变量 "x" = PointValue::Number(2.0)
4. 读取 "x" 的值

**Expected Results**:
- "x" 的值为 PointValue::Number(2.0)（后写入覆盖先写入）

**Priority**: P1

---

#### TC-S2-009-035: 上下文隔离性

**Description**: 验证不同执行之间的上下文是隔离的。

**Preconditions**: 无

**Test Steps**:
1. 创建第一个执行上下文，执行 Start->Read 过程，存入变量 "data"
2. 创建第二个执行上下文，执行 Start->Read 过程
3. 验证第二个上下文中不存在第一个上下文的 "data" 变量

**Expected Results**:
- 两个执行上下文相互独立
- 第二个上下文中没有 "data" 变量
- 每次执行都从干净的状态开始

**Priority**: P0

---

#### TC-S2-009-036: 读取不存在的上下文变量

**Description**: 验证读取不存在的上下文变量时的行为。

**Preconditions**: 无

**Test Steps**:
1. 创建执行上下文
2. 尝试读取不存在的变量 "nonexistent"
3. 验证返回结果

**Expected Results**:
- 返回 None 或等效的"变量不存在"结果
- 不引发 panic 或未处理异常

**Priority**: P1

---

### 五、环节执行日志测试

#### TC-S2-009-037: 每个环节记录执行日志

**Description**: 验证每个环节执行时都记录日志（验收标准 3）。

**Preconditions**: 无

**Test Steps**:
1. 构造包含 Start、Read、Delay、End 四个步骤的过程定义
2. 执行该过程
3. 获取执行日志
4. 验证日志条目数量

**Expected Results**:
- 日志包含 4 条记录（每个步骤一条）
- 满足验收标准 3

**Priority**: P0

---

#### TC-S2-009-038: 日志包含必要字段

**Description**: 验证每条日志记录包含步骤 ID、类型、开始时间、结束时间、状态。

**Preconditions**: 无

**Test Steps**:
1. 执行包含 Start、Read、Delay、End 的过程
2. 获取执行日志
3. 检查每条日志记录的字段

**Expected Results**:
- 每条日志包含：
  - step_id: 步骤 ID
  - step_type: 步骤类型
  - step_name: 步骤名称
  - start_time: 开始时间戳
  - end_time: 结束时间戳
  - status: 执行状态（Success/Failed）
  - duration_ms: 执行耗时（毫秒）

**Priority**: P0

---

#### TC-S2-009-039: 失败步骤记录错误信息

**Description**: 验证执行失败的步骤在日志中记录错误信息。

**Preconditions**:
- VirtualDriver 已创建但未连接

**Test Steps**:
1. 构造过程定义：Start -> Read(point_id=X, target_var="val") -> End
2. 在未连接的 VirtualDriver 上执行
3. 获取执行日志
4. 检查 Read 步骤的日志记录

**Expected Results**:
- Read 步骤的日志状态为 Failed
- 日志包含错误信息（如 "Device not connected"）
- Start 步骤的日志状态为 Success

**Priority**: P0

---

#### TC-S2-009-040: 日志时间戳顺序正确

**Description**: 验证日志中各步骤的时间戳按执行顺序排列。

**Preconditions**: 无

**Test Steps**:
1. 执行包含 Start -> Delay(10ms) -> Delay(10ms) -> End 的过程
2. 获取执行日志
3. 验证每条日志的 start_time 递增

**Expected Results**:
- 日志按执行顺序排列
- 每条日志的 start_time >= 前一条日志的 end_time
- 时间戳单调递增

**Priority**: P1

---

#### TC-S2-009-041: 执行完成后可检索完整日志

**Description**: 验证执行完成后可获取完整的执行日志。

**Preconditions**: 无

**Test Steps**:
1. 执行完整过程（Start -> Read -> Control -> Delay -> End）
2. 执行完成后调用日志获取方法
3. 验证返回的日志完整性

**Expected Results**:
- 可获取所有步骤的日志
- 日志数量与步骤数量一致
- 日志数据完整无丢失

**Priority**: P0

---

### 六、错误处理测试

#### TC-S2-009-042: 缺失 type 字段

**Description**: 验证步骤定义中完全缺少 `type` 字段时返回解析错误。

**Preconditions**: 无

**Test Steps**:
1. 构造步骤 JSON，包含 id 和 name 字段，但缺少 type 字段：`{"id": "step-1", "name": "无类型步骤"}`
2. 将其放入过程定义中并尝试解析
3. 验证返回错误

**Expected Results**:
- 解析失败，返回 Err
- 错误信息指出缺少 type 字段

**Priority**: P0

---

#### TC-S2-009-043: 错误传播 — 引擎停止执行并返回错误

**Description**: 验证过程中某步骤失败时，引擎立即停止执行后续步骤并返回错误。

**Preconditions**:
- VirtualDriver 已创建但未连接

**Test Steps**:
1. 构造过程定义：Start -> Read(point_id=X, target_var="val") -> Control(point_id=Y, value=10.0) -> End
2. 在未连接的 VirtualDriver 上执行该过程
3. 验证引擎的返回值
4. 验证 Control 和 End 步骤未执行

**Expected Results**:
- 引擎返回 Err，错误类型为 Read 步骤产生的错误
- Control 和 End 步骤未执行（可通过日志验证）
- 错误信息明确描述失败原因

**Priority**: P0

---

#### TC-S2-009-044: Control 环节设备写入失败

**Description**: 验证 Control 环节在设备写入失败时的错误处理。

**Preconditions**:
- VirtualDriver 已创建并连接，配置为 RO 类型

**Test Steps**:
1. 构造过程定义：Start -> Control -> End
2. 在只读设备上执行
3. 验证错误处理

**Expected Results**:
- 执行在 Control 步骤失败
- 错误类型为 ReadOnlyPoint 或等效错误
- 后续步骤（End）不执行

**Priority**: P0

---

#### TC-S2-009-045: 缺失 point_id 的 Read/Control 步骤

**Description**: 验证执行时 Read/Control 步骤缺少 point_id 的处理。

**Preconditions**: 无

**Test Steps**:
1. 通过代码直接构造 Read 步骤结构体（绕过 JSON 解析），不设置 point_id
2. 尝试执行该步骤
3. 验证错误处理

**Expected Results**:
- 执行失败
- 错误信息指出缺少 point_id
- 此测试验证防御性编程：即使绕过解析层，执行层也能捕获缺失字段

**Priority**: P1

---

#### TC-S2-009-046: Delay 环节 — 大延迟执行

**Description**: 验证 Delay 环节能正确处理较大的延迟值（100ms）。

**Preconditions**: 无

**Test Steps**:
1. 创建 Delay 环节，duration_ms = 100
2. 记录执行开始时间
3. 执行 Delay 环节
4. 记录执行结束时间
5. 计算实际等待时间

**Expected Results**:
- 执行成功
- 实际等待时间 >= 100ms
- 实际等待时间 < 200ms（允许合理误差）

**Priority**: P1

---

#### TC-S2-009-047: 过程中间步骤失败后的上下文状态和日志

**Description**: 验证过程中间步骤失败后，执行上下文的状态和日志记录的正确性。

**Preconditions**:
- VirtualDriver 已创建但未连接

**Test Steps**:
1. 构造过程定义：Start -> Read(point_id=X, target_var="val") -> Control(point_id=Y, value=10.0) -> End
2. 在未连接的 VirtualDriver 上执行
3. 检查执行上下文的 status 字段
4. 检查执行日志的内容

**Expected Results**:
- 执行上下文 status 为 Failed
- 日志中包含 2 条记录：Start（Success）和 Read（Failed）
- Read 步骤的日志包含错误信息
- Control 和 End 步骤无日志记录
- 执行上下文中未存入 "val" 变量（Read 失败）

**Priority**: P0

---

### 七、ExecutionListener 回调机制测试

#### TC-S2-009-048: ExecutionListener — step_started 通知

**Description**: 验证引擎在每个环节开始执行时调用 listener.step_started。

**Preconditions**: 无

**Test Steps**:
1. 实现一个 MockExecutionListener，记录所有回调调用
2. 构造过程定义：Start -> Read -> End
3. 创建执行引擎，传入 MockExecutionListener
4. 执行该过程
5. 验证 MockExecutionListener 收到的 step_started 调用

**Expected Results**:
- step_started 被调用 3 次（每个步骤一次）
- 调用顺序与步骤定义顺序一致
- 每次调用传入的 StepDefinition 与对应步骤匹配

**Priority**: P0

---

#### TC-S2-009-049: ExecutionListener — step_completed 通知

**Description**: 验证引擎在每个环节成功完成时调用 listener.step_completed。

**Preconditions**:
- VirtualDriver 已创建并连接，Fixed 模式

**Test Steps**:
1. 实现一个 MockExecutionListener，记录所有回调调用
2. 构造过程定义：Start -> Delay(10ms) -> End
3. 创建执行引擎，传入 MockExecutionListener
4. 执行该过程
5. 验证 MockExecutionListener 收到的 step_completed 调用

**Expected Results**:
- step_completed 被调用 3 次（每个步骤一次）
- 调用顺序与步骤定义顺序一致
- 每次调用传入的 StepResult 状态为 Success

**Priority**: P0

---

#### TC-S2-009-050: ExecutionListener — step_failed 通知

**Description**: 验证引擎在环节执行失败时调用 listener.step_failed。

**Preconditions**:
- VirtualDriver 已创建但未连接

**Test Steps**:
1. 实现一个 MockExecutionListener，记录所有回调调用
2. 构造过程定义：Start -> Read(point_id=X, target_var="val") -> End
3. 创建执行引擎，传入 MockExecutionListener
4. 执行该过程
5. 验证 MockExecutionListener 收到的回调

**Expected Results**:
- step_started 被调用 2 次（Start 和 Read）
- step_completed 被调用 1 次（Start）
- step_failed 被调用 1 次（Read），包含正确的错误信息
- step_completed 不被 Read 步骤调用
- End 步骤不触发任何回调（未执行）

**Priority**: P0

---

#### TC-S2-009-051: ExecutionListener — process_completed 通知

**Description**: 验证引擎在过程执行完成时调用 listener.process_completed。

**Preconditions**: 无

**Test Steps**:
1. 实现一个 MockExecutionListener，记录所有回调调用
2. 构造过程定义：Start -> End
3. 创建执行引擎，传入 MockExecutionListener
4. 执行该过程
5. 验证 process_completed 被调用

**Expected Results**:
- process_completed 被调用恰好 1 次
- 传入的 ProcessResult 状态为 Completed
- process_completed 在所有 step_completed 之后调用

**Priority**: P0

---

#### TC-S2-009-052: ExecutionListener — 过程失败时 process_completed 通知

**Description**: 验证引擎在过程执行失败时也调用 listener.process_completed。

**Preconditions**:
- VirtualDriver 已创建但未连接

**Test Steps**:
1. 实现一个 MockExecutionListener，记录所有回调调用
2. 构造过程定义：Start -> Read -> End
3. 创建执行引擎，传入 MockExecutionListener
4. 执行该过程
5. 验证 process_completed 被调用

**Expected Results**:
- process_completed 被调用恰好 1 次
- 传入的 ProcessResult 状态为 Failed
- process_completed 在 step_failed 之后调用

**Priority**: P0

---

#### TC-S2-009-053: ExecutionListener — 无监听器时引擎正常执行

**Description**: 验证引擎在不提供 ExecutionListener 时仍能正常执行。

**Preconditions**:
- VirtualDriver 已创建并连接

**Test Steps**:
1. 构造过程定义：Start -> Read -> End
2. 创建执行引擎，不传入任何 ExecutionListener（使用 None）
3. 执行该过程
4. 验证执行结果

**Expected Results**:
- 执行成功
- 所有步骤正常执行
- 不触发 panic 或未处理异常
- 执行日志正常记录

**Priority**: P0

---

### 八、集成测试

#### TC-S2-009-054: 引擎与 VirtualDriver 集成 — 数据读写

**Description**: 验证执行引擎通过 VirtualDriver 正确读写数据。

**Preconditions**:
- VirtualDriver 已创建并连接，RW 类型，Fixed 模式

**Test Steps**:
1. 构造过程定义：Start -> Read(存入 "before") -> Control(写入 80.0) -> Read(存入 "after") -> End
2. 执行引擎，传入 VirtualDriver
3. 验证 "before" 和 "after" 的值
4. 验证 Control 写入的值

**Expected Results**:
- "before" 的值为 Fixed 模式的固定值
- "after" 的值为 Control 写入的 80.0（因为 VirtualDriver 对已写入的 RW 点返回写入值）
- 数据流正确

**Priority**: P0

---

#### TC-S2-009-055: 引擎与 Method 模型集成 — 从 process_definition 解析执行

**Description**: 验证引擎能从 Method 实体的 process_definition 字段解析并执行过程。

**Preconditions**:
- 数据库中已存储一个 Method 实体
- VirtualDriver 已创建并连接

**Test Steps**:
1. 创建 Method 实体，process_definition 包含完整的过程定义 JSON
2. 从 Method.process_definition 解析步骤
3. 执行引擎
4. 验证执行结果

**Expected Results**:
- 从 process_definition 正确解析步骤
- 引擎成功执行所有步骤
- 执行结果正确

**Priority**: P0

---

## 测试执行计划

| 测试用例 | 优先级 | 类型 | 预估时间 |
|----------|--------|------|----------|
| TC-S2-009-001 | P0 | 单元测试 | 5 min |
| TC-S2-009-002 | P0 | 单元测试 | 5 min |
| TC-S2-009-003 | P1 | 单元测试 | 5 min |
| TC-S2-009-004 | P0 | 单元测试 | 5 min |
| TC-S2-009-005 | P0 | 单元测试 | 5 min |
| TC-S2-009-006 | P0 | 单元测试 | 5 min |
| TC-S2-009-007 | P0 | 单元测试 | 5 min |
| TC-S2-009-008 | P0 | 单元测试 | 5 min |
| TC-S2-009-009 | P1 | 单元测试 | 5 min |
| TC-S2-009-010 | P1 | 单元测试 | 5 min |
| TC-S2-009-011 | P1 | 单元测试 | 5 min |
| TC-S2-009-012 | P1 | 单元测试 | 5 min |
| TC-S2-009-013 | P0 | 单元测试 | 5 min |
| TC-S2-009-014 | P2 | 单元测试 | 5 min |
| TC-S2-009-015 | P0 | 集成测试 | 10 min |
| TC-S2-009-016 | P1 | 集成测试 | 5 min |
| TC-S2-009-017 | P0 | 集成测试 | 5 min |
| TC-S2-009-018 | P0 | 集成测试 | 10 min |
| TC-S2-009-019 | P0 | 集成测试 | 5 min |
| TC-S2-009-020 | P1 | 集成测试 | 10 min |
| TC-S2-009-021 | P0 | 单元测试 | 5 min |
| TC-S2-009-022 | P2 | 单元测试 | 5 min |
| TC-S2-009-023 | P1 | 单元测试 | 5 min |
| TC-S2-009-024 | P0 | 单元测试 | 5 min |
| TC-S2-009-025 | P1 | 集成测试 | 10 min |
| TC-S2-009-026 | P0 | 集成测试 | 10 min |
| TC-S2-009-027 | P0 | 集成测试 | 15 min |
| TC-S2-009-028 | P1 | 集成测试 | 10 min |
| TC-S2-009-029 | P1 | 集成测试 | 10 min |
| TC-S2-009-030 | P1 | 集成测试 | 5 min |
| TC-S2-009-031 | P1 | 集成测试 | 5 min |
| TC-S2-009-032 | P0 | 集成测试 | 10 min |
| TC-S2-009-033 | P0 | 单元测试 | 5 min |
| TC-S2-009-034 | P1 | 单元测试 | 5 min |
| TC-S2-009-035 | P0 | 单元测试 | 5 min |
| TC-S2-009-036 | P1 | 单元测试 | 5 min |
| TC-S2-009-037 | P0 | 单元测试 | 5 min |
| TC-S2-009-038 | P0 | 单元测试 | 5 min |
| TC-S2-009-039 | P0 | 单元测试 | 10 min |
| TC-S2-009-040 | P1 | 单元测试 | 5 min |
| TC-S2-009-041 | P0 | 单元测试 | 5 min |
| TC-S2-009-042 | P0 | 单元测试 | 5 min |
| TC-S2-009-043 | P0 | 集成测试 | 10 min |
| TC-S2-009-044 | P0 | 集成测试 | 10 min |
| TC-S2-009-045 | P1 | 单元测试 | 5 min |
| TC-S2-009-046 | P1 | 单元测试 | 5 min |
| TC-S2-009-047 | P0 | 集成测试 | 10 min |
| TC-S2-009-048 | P0 | 单元测试 | 10 min |
| TC-S2-009-049 | P0 | 单元测试 | 10 min |
| TC-S2-009-050 | P0 | 单元测试 | 10 min |
| TC-S2-009-051 | P0 | 单元测试 | 10 min |
| TC-S2-009-052 | P0 | 单元测试 | 10 min |
| TC-S2-009-053 | P0 | 单元测试 | 5 min |
| TC-S2-009-054 | P0 | 集成测试 | 10 min |
| TC-S2-009-055 | P0 | 集成测试 | 10 min |

**总计**: 55 个测试用例
- P0: 35 个
- P1: 17 个
- P2: 3 个

---

## 验收标准映射

| 验收标准 | 覆盖测试用例 |
|----------|-------------|
| 可执行包含 Start-Read-Delay-Control-End 的简单过程 | TC-027, TC-026, TC-032 |
| Read 环节读取虚拟设备数据 | TC-015, TC-016, TC-017, TC-054 |
| 每个环节执行记录日志 | TC-037, TC-038, TC-039, TC-041 |

---

## 环节类型覆盖矩阵

| 环节类型 | 解析测试 | 执行器测试 | 过程执行测试 | 日志测试 | 错误测试 |
|----------|---------|-----------|-------------|---------|---------|
| Start | TC-001,002,003 | TC-013,014 | TC-026,027,028,029,030,032 | TC-037,038,041 | TC-042,043,047 |
| Read | TC-001,004,005,011 | TC-015,016,017 | TC-027,028,032 | TC-037,038,039 | TC-043,045,047 |
| Control | TC-001,006,011 | TC-018,019,020,025 | TC-027,029,032 | TC-037,038,039 | TC-044,045,047 |
| Delay | TC-001,007,009,011 | TC-021,022,023 | TC-027,032 | TC-037,038,040 | TC-046 |
| End | TC-001,002,003 | TC-024 | TC-026,027,030,032 | TC-037,038,041 | TC-047 |

---

## 测试环境要求

1. **Rust 测试环境**: cargo test 可正常运行
2. **内存 SQLite**: 用于集成测试的数据库
3. **VirtualDriver**: 支持多种配置模式（Fixed、Random、RW、RO、WO）
4. **时间精度**: 系统时钟精度满足毫秒级延迟测试
5. **异步运行时**: 测试需使用 `#[tokio::test]` 运行（引擎内部使用 tokio::time::sleep）

---

## 修订记录

| 版本 | 日期 | 修订内容 | 修订人 |
|------|------|---------|--------|
| 1.0 | 2026-04-02 | 初始版本 | sw-mike |
| 2.0 | 2026-04-02 | 根据 sw-tom 评审意见修订：(1) TC-046/048/049 改为 ExecutionListener 回调测试，StateMachine 集成移至 S2-011；(2) TC-040 改为测试缺失 type 字段；(3) TC-019 改为使用独立 VirtualDriver 实例；(4) TC-013 明确幂等性预期行为；(5) TC-044 替换为大延迟测试；(6) TC-041/045 合并为错误传播+上下文状态两个独立测试；(7) 调整 P0/P1 优先级；(8) 新增 TC-012 重复步骤 ID 测试；(9) 新增 TC-025 WO 点测试；(10) 新增执行上下文结构定义 | sw-mike |

---

**Author**: sw-mike
**Reviewer**: sw-tom
**Status**: 待复审
