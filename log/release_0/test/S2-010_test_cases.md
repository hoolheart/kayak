# S2-010 Test Cases: 表达式引擎基础

**Task ID**: S2-010
**Task Name**: 表达式引擎基础
**Test Version**: 1.1
**Date**: 2026-04-02

---

## 测试概述

本文档定义表达式引擎基础的测试用例，覆盖以下方面：
1. 算术运算表达式（+、-、*、/、%）
2. 条件表达式（比较运算符 >、<、>=、<=、==、!=；逻辑运算符 &&、||、!）
3. 变量替换（从 ExecutionContext 和参数表读取变量）
4. 运算符优先级与括号
5. 类型转换与类型安全
6. 错误处理
7. 与执行引擎的集成

---

## 类型转换策略（已决策）

本节定义表达式引擎的类型转换行为，作为测试用例的预期依据。

### 核心规则

| 转换方向 | 规则 | 示例 | 结果 |
|----------|------|------|------|
| Integer → Number | 始终提升 | `Integer(42)` 在算术运算中 | `Number(42.0)` |
| Boolean → Number | 允许（IEEE 754 语义） | `true + 1` | `Number(2.0)` |
| Boolean → Number | 允许 | `false + 1` | `Number(1.0)` |
| Number → Boolean | **禁止**（需显式比较） | `!5.0` | `TypeError` |
| Number → Boolean | 需比较 | `5.0 > 0` | `Boolean(true)` |
| Integer/Number → Boolean | 需比较 | `x > 0` 或 `x == 0` | `Boolean` |

### 设计理由

1. **Integer → Number 始终提升**：简化实现，统一使用 f64 进行算术运算。`PointValue::Integer` 仅用于存储，表达式求值时统一转换为 f64。

2. **Boolean → Number 允许**：符合 IEEE 754 传统，C/Go/JavaScript 等语言均支持。`true → 1.0`，`false → 0.0`。`PointValue::Boolean` 具有 `to_f64()` 方法，返回 `1.0` 或 `0.0`。

3. **Number → Boolean 禁止**：理由如下：
   - 语义模糊：`!5.0` 是 "5.0 是 false 吗？" 还是 "5.0 是 truthy 吗？"
   - 需要显式比较：`x > 0` 比 `!x` 更清晰
   - 避免隐式类型转换带来的 bugs

4. **浮点溢出/NaN**：遵循 IEEE 754 标准
   - `1e308 * 10` → `Infinity`
   - `0.0 / 0.0` → `NaN`
   - `NaN` 参与运算 → 传播 `NaN`

---

## 表达式引擎接口定义（预期）

表达式引擎提供以下核心接口：

```rust
/// 表达式求值结果
pub enum EvalResult {
    Number(f64),
    Boolean(bool),
    String(String),
}

/// 表达式引擎
pub struct ExpressionEngine {
    // 内部实现
}

impl ExpressionEngine {
    /// 创建新的表达式引擎实例
    pub fn new() -> Self;

    /// 求值表达式，使用给定的变量上下文
    /// 
    /// # Arguments
    /// * `expression` - 表达式字符串
    /// * `context` - 变量映射（变量名 -> PointValue）
    /// 
    /// # Returns
    /// * `Ok(EvalResult)` - 求值成功
    /// * `Err(ExpressionError)` - 求值失败
    pub fn eval(
        &self,
        expression: &str,
        context: &HashMap<String, PointValue>,
    ) -> Result<EvalResult, ExpressionError>;
}

/// 表达式求值错误
pub enum ExpressionError {
    /// 语法错误
    SyntaxError(String),
    /// 变量未定义
    UndefinedVariable(String),
    /// 类型错误
    TypeError(String),
    /// 除零错误
    DivisionByZero,
    /// 空表达式
    EmptyExpression,
    /// 内部错误
    InternalError(String),
}
```

### 支持的运算符

| 类别 | 运算符 | 说明 | 示例 |
|------|--------|------|------|
| 算术 | `+` | 加法 | `2 + 3` |
| 算术 | `-` | 减法 | `10 - 4` |
| 算术 | `*` | 乘法 | `3 * 5` |
| 算术 | `/` | 除法 | `10 / 2` |
| 算术 | `%` | 取模 | `10 % 3` |
| 比较 | `>` | 大于 | `x > 10` |
| 比较 | `<` | 小于 | `x < 10` |
| 比较 | `>=` | 大于等于 | `x >= 10` |
| 比较 | `<=` | 小于等于 | `x <= 10` |
| 比较 | `==` | 等于 | `x == 10` |
| 比较 | `!=` | 不等于 | `x != 10` |
| 逻辑 | `&&` | 逻辑与 | `a > 0 && b < 100` |
| 逻辑 | `||` | 逻辑或 | `a > 0 || b < 100` |
| 逻辑 | `!` | 逻辑非 | `!is_error` |
| 分组 | `()` | 括号分组 | `(2 + 3) * 4` |

### 变量来源

| 来源 | 说明 | 示例 |
|------|------|------|
| ExecutionContext.variables | Read 环节存入的变量 | `temperature`, `pressure` |
| 方法参数表 | 试验方法配置的参数 | `setpoint`, `max_temp` |
| 测点当前值 | 设备测点实时值（通过上下文注入） | `current_temp` |

---

## 测试用例

### 一、算术运算表达式测试

#### TC-S2-010-001: 基本加法运算

**Description**: 验证表达式引擎能正确计算两个数的加法。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"2 + 3"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(5.0)`

**Priority**: P0

---

#### TC-S2-010-002: 基本减法运算

**Description**: 验证表达式引擎能正确计算两个数的减法。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 - 4"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(6.0)`

**Priority**: P0

---

#### TC-S2-010-003: 基本乘法运算

**Description**: 验证表达式引擎能正确计算两个数的乘法。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"3 * 5"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(15.0)`

**Priority**: P0

---

#### TC-S2-010-004: 基本除法运算

**Description**: 验证表达式引擎能正确计算两个数的除法。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 / 2"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(5.0)`

**Priority**: P0

---

#### TC-S2-010-005: 运算符优先级 — 乘法优先于加法

**Description**: 验证表达式引擎遵循标准运算符优先级，乘法优先于加法。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"2 + 3 * 4"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(14.0)`（先算 3*4=12，再加 2）
- 不是 20（即不是从左到右简单计算）

**Priority**: P0

---

#### TC-S2-010-006: 运算符优先级 — 除法优先于减法

**Description**: 验证除法优先于减法。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"20 - 8 / 2"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(16.0)`（先算 8/2=4，再 20-4）

**Priority**: P0

---

#### TC-S2-010-007: 括号改变优先级

**Description**: 验证括号能改变运算符优先级。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"(2 + 3) * 4"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(20.0)`（先算括号内 2+3=5，再乘 4）

**Priority**: P0

---

#### TC-S2-010-008: 嵌套括号

**Description**: 验证表达式引擎支持多层嵌套括号。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"((2 + 3) * (4 - 1)) / 3"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(5.0)`（(5 * 3) / 3 = 5）

**Priority**: P1

---

#### TC-S2-010-009: 负数运算

**Description**: 验证表达式引擎能正确处理负数。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"-5 + 3"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(-2.0)`

**Priority**: P0

---

#### TC-S2-010-010: 浮点数运算

**Description**: 验证表达式引擎能正确处理浮点数运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"3.14 * 2"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(6.28)`（允许浮点误差 ±0.0001）

**Priority**: P0

---

#### TC-S2-010-011: 混合整数与浮点数运算

**Description**: 验证表达式引擎能正确处理整数与浮点数混合运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"3 + 2.5"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(5.5)`

**Priority**: P0

---

#### TC-S2-010-012: 复杂算术表达式

**Description**: 验证表达式引擎能正确计算包含多种运算符的复杂表达式。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 + 2 * 3 - 4 / 2"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(14.0)`（10 + 6 - 2 = 14）

**Priority**: P1

---

#### TC-S2-010-013: 除法运算 — 浮点结果

**Description**: 验证除法运算返回浮点结果（非整数除法）。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"7 / 2"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(3.5)`

**Priority**: P0

---

#### TC-S2-010-014: 取模运算 — 基本用法

**Description**: 验证取模运算符正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 % 3"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(1.0)`

**Priority**: P0

---

#### TC-S2-010-015: 取模运算 — 负数操作数

**Description**: 验证取模运算对负数操作数的处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"-7 % 3"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(-1.0)` 或 `EvalResult::Number(2.0)`
- 注：取决于实现（Rust 语义为 `-7 % 3 = -1`）

**Priority**: P1

---

#### TC-S2-010-016: 取模运算 — 除零错误

**Description**: 验证取模运算除零时的错误处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 % 0"`
3. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::DivisionByZero`

**Priority**: P0

---

### 二、比较表达式测试

#### TC-S2-010-017: 大于运算

**Description**: 验证大于运算符正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 > 5"`
3. 验证结果
4. 求值表达式 `"5 > 10"`
5. 验证结果

**Expected Results**:
- `"10 > 5"` 返回 `EvalResult::Boolean(true)`
- `"5 > 10"` 返回 `EvalResult::Boolean(false)`

**Priority**: P0

---

#### TC-S2-010-018: 小于运算

**Description**: 验证小于运算符正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"5 < 10"`
3. 验证结果
4. 求值表达式 `"10 < 5"`
5. 验证结果

**Expected Results**:
- `"5 < 10"` 返回 `EvalResult::Boolean(true)`
- `"10 < 5"` 返回 `EvalResult::Boolean(false)`

**Priority**: P0

---

#### TC-S2-010-019: 大于等于运算

**Description**: 验证大于等于运算符正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 >= 10"`
3. 验证结果
4. 求值表达式 `"10 >= 5"`
5. 验证结果
6. 求值表达式 `"5 >= 10"`
7. 验证结果

**Expected Results**:
- `"10 >= 10"` 返回 `EvalResult::Boolean(true)`
- `"10 >= 5"` 返回 `EvalResult::Boolean(true)`
- `"5 >= 10"` 返回 `EvalResult::Boolean(false)`

**Priority**: P0

---

#### TC-S2-010-020: 小于等于运算

**Description**: 验证小于等于运算符正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 <= 10"`
3. 验证结果
4. 求值表达式 `"5 <= 10"`
5. 验证结果
6. 求值表达式 `"10 <= 5"`
7. 验证结果

**Expected Results**:
- `"10 <= 10"` 返回 `EvalResult::Boolean(true)`
- `"5 <= 10"` 返回 `EvalResult::Boolean(true)`
- `"10 <= 5"` 返回 `EvalResult::Boolean(false)`

**Priority**: P0

---

#### TC-S2-010-021: 等于运算

**Description**: 验证等于运算符正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"5 == 5"`
3. 验证结果
4. 求值表达式 `"5 == 6"`
5. 验证结果

**Expected Results**:
- `"5 == 5"` 返回 `EvalResult::Boolean(true)`
- `"5 == 6"` 返回 `EvalResult::Boolean(false)`

**Priority**: P0

---

#### TC-S2-010-022: 不等于运算

**Description**: 验证不等于运算符正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"5 != 6"`
3. 验证结果
4. 求值表达式 `"5 != 5"`
5. 验证结果

**Expected Results**:
- `"5 != 6"` 返回 `EvalResult::Boolean(true)`
- `"5 != 5"` 返回 `EvalResult::Boolean(false)`

**Priority**: P0

---

#### TC-S2-010-023: 浮点数比较

**Description**: 验证浮点数比较运算正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"3.14 > 3.0"`
3. 验证结果
4. 求值表达式 `"2.5 <= 2.5"`
5. 验证结果

**Expected Results**:
- `"3.14 > 3.0"` 返回 `EvalResult::Boolean(true)`
- `"2.5 <= 2.5"` 返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

### 三、逻辑表达式测试

#### TC-S2-010-024: 逻辑与（AND）— 两个条件都为真

**Description**: 验证逻辑与运算符在两个条件都为真时返回 true。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"true && true"`
3. 验证结果

**Expected Results**:
- 返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

#### TC-S2-010-025: 逻辑与（AND）— 至少一个条件为假

**Description**: 验证逻辑与运算符在至少一个条件为假时返回 false。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"true && false"`
3. 验证结果
4. 求值表达式 `"false && true"`
5. 验证结果
6. 求值表达式 `"false && false"`
7. 验证结果

**Expected Results**:
- 所有情况均返回 `EvalResult::Boolean(false)`

**Priority**: P0

---

#### TC-S2-010-026: 逻辑或（OR）— 至少一个条件为真

**Description**: 验证逻辑或运算符在至少一个条件为真时返回 true。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"true || false"`
3. 验证结果
4. 求值表达式 `"false || true"`
5. 验证结果
6. 求值表达式 `"true || true"`
7. 验证结果

**Expected Results**:
- 所有情况均返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

#### TC-S2-010-027: 逻辑或（OR）— 两个条件都为假

**Description**: 验证逻辑或运算符在两个条件都为假时返回 false。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"false || false"`
3. 验证结果

**Expected Results**:
- 返回 `EvalResult::Boolean(false)`

**Priority**: P0

---

#### TC-S2-010-028: 逻辑非（NOT）

**Description**: 验证逻辑非运算符正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"!true"`
3. 验证结果
4. 求值表达式 `"!false"`
5. 验证结果

**Expected Results**:
- `"!true"` 返回 `EvalResult::Boolean(false)`
- `"!false"` 返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

#### TC-S2-010-029: 组合逻辑表达式 — 比较与逻辑运算

**Description**: 验证比较运算与逻辑运算组合使用。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 > 5 && 3 < 8"`
3. 验证结果
4. 求值表达式 `"10 > 5 && 3 > 8"`
5. 验证结果
6. 求值表达式 `"10 < 5 || 3 < 8"`
7. 验证结果

**Expected Results**:
- `"10 > 5 && 3 < 8"` 返回 `EvalResult::Boolean(true)`
- `"10 > 5 && 3 > 8"` 返回 `EvalResult::Boolean(false)`
- `"10 < 5 || 3 < 8"` 返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

#### TC-S2-010-030: 复杂逻辑表达式 — 多条件组合

**Description**: 验证包含多个逻辑运算符的复杂表达式。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"(10 > 5 && 3 < 8) || false"`
3. 验证结果
4. 求值表达式 `"!(10 > 5 && 3 > 8)"`
5. 验证结果

**Expected Results**:
- `"(10 > 5 && 3 < 8) || false"` 返回 `EvalResult::Boolean(true)`
- `"!(10 > 5 && 3 > 8)"` 返回 `EvalResult::Boolean(true)`（内部为 false，取反为 true）

**Priority**: P1

---

#### TC-S2-010-031: 逻辑运算符优先级

**Description**: 验证逻辑运算符优先级：NOT > AND > OR。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"true || false && false"`
3. 验证结果

**Expected Results**:
- 返回 `EvalResult::Boolean(true)`（AND 优先：`false && false = false`，然后 `true || false = true`）
- 如果从左到右计算则结果为 false，验证引擎遵循正确优先级

**Priority**: P1

---

### 四、变量替换测试

#### TC-S2-010-032: 简单变量引用

**Description**: 验证表达式引擎能正确替换并求值单个变量。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"x": PointValue::Integer(42)}`
3. 求值表达式 `"x"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(42.0)`
- 注：Integer 类型始终提升为 Number(f64)，见类型转换策略

**Priority**: P0

---

#### TC-S2-010-033: 负数值变量参与运算

**Description**: 验证包含负数值的变量能正确参与运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"x": PointValue::Number(-5.0)}`
3. 求值表达式 `"x * 2"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(-10.0)`

**Priority**: P0

---

#### TC-S2-010-034: 变量参与算术运算

**Description**: 验证变量能正确参与算术运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"x": PointValue::Integer(10), "y": PointValue::Integer(20)}`
3. 求值表达式 `"x + y"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(30.0)`

**Priority**: P0

---

#### TC-S2-010-035: 变量参与比较运算

**Description**: 验证变量能正确参与比较运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"temperature": PointValue::Number(120.5), "threshold": PointValue::Number(100.0)}`
3. 求值表达式 `"temperature > threshold"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

#### TC-S2-010-036: 变量参与复杂表达式

**Description**: 验证变量能参与包含算术和比较运算的复杂表达式。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：
   - `"temperature": PointValue::Number(150.0)`
   - `"max_temp": PointValue::Number(200.0)`
   - `"offset": PointValue::Number(10.0)`
3. 求值表达式 `"temperature + offset < max_temp"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`（150 + 10 = 160 < 200）

**Priority**: P0

---

#### TC-S2-010-037: 变量参与逻辑表达式

**Description**: 验证布尔变量能正确参与逻辑运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：
   - `"is_running": PointValue::Boolean(true)`
   - `"is_error": PointValue::Boolean(false)`
3. 求值表达式 `"is_running && !is_error"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

#### TC-S2-010-038: 变量与常量混合运算

**Description**: 验证表达式中变量与常量混合使用。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"setpoint": PointValue::Number(50.0)}`
3. 求值表达式 `"setpoint * 2 + 10"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(110.0)`

**Priority**: P0

---

#### TC-S2-010-039: 多变量算术表达式

**Description**: 验证包含多个变量的算术表达式。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：
   - `"temperature": PointValue::Number(25.0)`
   - `"offset": PointValue::Number(2.5)`
   - `"scale": PointValue::Number(1.8)`
3. 求值表达式 `"(temperature + offset) * scale"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(49.5)`（(25 + 2.5) * 1.8 = 49.5）

**Priority**: P1

---

#### TC-S2-010-040: 变量名区分大小写

**Description**: 验证变量名区分大小写。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"Temperature": PointValue::Number(100.0)}`
3. 求值表达式 `"temperature"`（小写 t）
4. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::UndefinedVariable("temperature")`
- 变量名严格区分大小写

**Priority**: P1

---

#### TC-S2-010-041: 变量名冲突 — 前缀匹配

**Description**: 验证变量名不会因前缀匹配而混淆。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：
   - `"temp": PointValue::Number(25.0)`
   - `"temperature": PointValue::Number(100.0)`
3. 求值表达式 `"temp + 1"`
4. 验证结果
5. 求值表达式 `"temperature + 1"`
6. 验证结果

**Expected Results**:
- `"temp + 1"` 返回 `EvalResult::Number(26.0)`
- `"temperature + 1"` 返回 `EvalResult::Number(101.0)`
- 两个变量互不干扰

**Priority**: P1

---

#### TC-S2-010-042: 未定义变量 — 返回错误

**Description**: 验证引用未定义变量时返回明确的错误。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建空的变量上下文
3. 求值表达式 `"undefined_var + 1"`
4. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::UndefinedVariable("undefined_var")`
- 错误信息包含未定义的变量名

**Priority**: P0

---

#### TC-S2-010-043: 部分变量未定义

**Description**: 验证表达式中部分变量未定义时的错误处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"x": PointValue::Integer(10)}`
3. 求值表达式 `"x + y"`（y 未定义）
4. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::UndefinedVariable("y")`

**Priority**: P0

---

### 五、类型转换与类型安全测试

#### TC-S2-010-044: Integer 到 Number 的隐式转换

**Description**: 验证 Integer 类型在与 Number 运算时能正确转换。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"a": PointValue::Integer(3)}`
3. 求值表达式 `"a + 2.5"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(5.5)`

**Priority**: P0

---

#### TC-S2-010-045: Boolean 到 Number 的转换（算术运算）

**Description**: 验证 Boolean 类型在算术运算中能转换为 Number（true→1.0, false→0.0）。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"flag": PointValue::Boolean(true)}`
3. 求值表达式 `"flag + 1"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(2.0)`（true → 1.0，1.0 + 1 = 2.0）

**Priority**: P0

---

#### TC-S2-010-046: Boolean 常量在算术运算

**Description**: 验证 Boolean 常量（true/false）在算术运算中的行为。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"true + 1"`
3. 验证结果
4. 求值表达式 `"false + 1"`
5. 验证结果

**Expected Results**:
- `"true + 1"` 返回 `EvalResult::Number(2.0)`
- `"false + 1"` 返回 `EvalResult::Number(1.0)`

**Priority**: P0

---

#### TC-S2-010-047: Number 到 Boolean 的转换（逻辑非）— 错误

**Description**: 验证 Number 类型不能直接用于逻辑非运算（需显式比较）。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"x": PointValue::Number(5.0)}`
3. 求值表达式 `"!x"`
4. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::TypeError("Number cannot be used in logical operations")`
- 注：Number→Boolean 需要显式比较，如 `x > 0`

**Priority**: P0

---

#### TC-S2-010-048: Number 到 Boolean 的显式比较

**Description**: 验证 Number 类型需要显式比较才能用于逻辑运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"x": PointValue::Number(5.0)}`
3. 求值表达式 `"x > 0"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`
- 正确的用法：`x > 0` 而不是 `!x`

**Priority**: P0

---

#### TC-S2-010-049: 字符串相等比较

**Description**: 验证字符串类型的相等比较。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：
   - `"status": PointValue::String("running")`
   - `"expected": PointValue::String("running")`
3. 求值表达式 `"status == expected"`
4. 验证结果
5. 创建变量上下文：`{"status": PointValue::String("running"), "expected": PointValue::String("stopped")}`
6. 求值表达式 `"status == expected"`
7. 验证结果

**Expected Results**:
- 第一次求值返回 `EvalResult::Boolean(true)`
- 第二次求值返回 `EvalResult::Boolean(false)`

**Priority**: P1

---

#### TC-S2-010-050: 类型不匹配 — 字符串与数字运算

**Description**: 验证字符串与数字进行算术运算时的错误处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"name": PointValue::String("hello")}`
3. 求值表达式 `"name + 5"`
4. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::TypeError`
- 错误信息描述类型不匹配（String 与 Number 不能相加）

**Priority**: P0

---

#### TC-S2-010-051: 字符串连接运算

**Description**: 验证字符串连接运算（+ 运算符对两个字符串）。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：
   - `"greeting": PointValue::String("hello")`
   - `"name": PointValue::String("world")`
3. 求值表达式 `"greeting + " " + name"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::String("hello world")`
- 注：字符串连接需要显式实现，不是所有表达式引擎都支持

**Priority**: P1

---

#### TC-S2-010-052: Number 类型变量参与比较

**Description**: 验证 Number 类型的 PointValue 能正确参与比较运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"value": PointValue::Number(3.14)}`
3. 求值表达式 `"value > 3.0"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

#### TC-S2-010-053: Integer 类型变量参与比较

**Description**: 验证 Integer 类型的 PointValue 能正确参与比较运算。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"count": PointValue::Integer(10)}`
3. 求值表达式 `"count >= 10"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`

**Priority**: P0

---

### 六、错误处理测试

#### TC-S2-010-054: 无效语法 — 连续运算符

**Description**: 验证表达式引擎对无效语法（连续运算符）的错误处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"2 + * 3"`
3. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::SyntaxError`
- 错误信息描述语法错误

**Priority**: P0

---

#### TC-S2-010-055: 无效语法 — 缺少操作数

**Description**: 验证表达式引擎对缺少操作数的错误处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"2 +"`
3. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::SyntaxError`

**Priority**: P0

---

#### TC-S2-010-056: 无效语法 — 括号不匹配

**Description**: 验证表达式引擎对括号不匹配的错误处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"(2 + 3"`
3. 验证结果
4. 求值表达式 `"2 + 3)"`
5. 验证结果

**Expected Results**:
- 两种情况均返回 `ExpressionError::SyntaxError`

**Priority**: P0

---

#### TC-S2-010-057: 除零错误

**Description**: 验证表达式引擎对除零操作的处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 / 0"`
3. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::DivisionByZero`
- 不引发 panic 或未处理异常

**Priority**: P0

---

#### TC-S2-010-058: 除零错误 — 变量为零

**Description**: 验证当变量值为零时的除零处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"zero": PointValue::Number(0.0)}`
3. 求值表达式 `"10 / zero"`
4. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::DivisionByZero`

**Priority**: P0

---

#### TC-S2-010-059: 空表达式

**Description**: 验证表达式引擎对空字符串的处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `""`
3. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::EmptyExpression`

**Priority**: P1

---

#### TC-S2-010-060: 仅空白字符的表达式

**Description**: 验证表达式引擎对仅包含空白字符的处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"   "`
3. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::EmptyExpression` 或 `ExpressionError::SyntaxError`

**Priority**: P2

---

#### TC-S2-010-061: 不支持的函数调用

**Description**: 验证表达式引擎对不支持的函数调用的处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"sin(45)"`
3. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::SyntaxError` 或等效错误
- Release 0 不支持数学函数，应明确报错

**Priority**: P1

---

#### TC-S2-010-062: 除零错误 — 表达式结果为零

**Description**: 验证当除法分母的表达式结果为零时的处理。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"10 / (5 - 5)"`
3. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::DivisionByZero`

**Priority**: P1

---

### 七、浮点溢出与特殊值测试

#### TC-S2-010-063: f64 溢出 — 乘法

**Description**: 验证表达式引擎能正确处理 f64 溢出（返回 Infinity）。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"1e308 * 10"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(inf)`（IEEE 754 正溢出）
- 结果应为 `f64::INFINITY`

**Priority**: P1

---

#### TC-S2-010-064: f64 溢出 — 除法

**Description**: 验证表达式引擎能正确处理 f64 溢出（返回 Infinity）。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"1e200 / 1e-100"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(inf)` 或极大数值（取决于实现）

**Priority**: P1

---

#### TC-S2-010-065: NaN 产生 — 0.0 / 0.0

**Description**: 验证表达式引擎产生 NaN 的场景。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"0.0 / 0.0"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(NaN)`（IEEE 754 规定 0.0/0.0 = NaN）
- 结果应为 `f64::NAN`

**Priority**: P1

---

#### TC-S2-010-066: NaN 传播

**Description**: 验证 NaN 在后续运算中的传播行为。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"nan": PointValue::Number(f64::NAN)}`
3. 求值表达式 `"nan + 5.0"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(NaN)`（NaN 参与运算结果仍为 NaN）

**Priority**: P1

---

#### TC-S2-010-067: 负数除法结果

**Description**: 验证负数除法的正确性。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"-10 / 3"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(-3.333...)`（允许浮点误差）

**Priority**: P0

---

### 八、变量名验证测试

#### TC-S2-010-068: 下划线变量名

**Description**: 验证包含下划线的变量名正确工作。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"temp_1": PointValue::Number(25.0)}`
3. 求值表达式 `"temp_1 * 2"`
4. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Number(50.0)`

**Priority**: P1

---

#### TC-S2-010-069: 变量名以数字开头 — 应报错

**Description**: 验证变量名不能以数字开头。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"1var": PointValue::Number(10.0)}`
3. 求值表达式 `"1var + 1"`
4. 验证结果

**Expected Results**:
- 求值失败，返回 `ExpressionError::SyntaxError`（变量名 "1var" 语法无效）
- 或返回 `ExpressionError::UndefinedVariable`（取决于解析器实现）

**Priority**: P2

---

### 九、集成测试

#### TC-S2-010-070: 表达式引擎与 ExecutionContext 集成

**Description**: 验证表达式引擎能从 ExecutionContext 的 variables 中读取变量并求值。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExecutionContext 实例
2. 通过 `set_variable` 存入：
   - `"temperature" = PointValue::Number(85.5)`
   - `"pressure" = PointValue::Number(101.3)`
3. 使用 ExecutionContext.variables 作为变量上下文
4. 求值表达式 `"temperature > 80 && pressure < 110"`
5. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`
- 表达式引擎正确读取 ExecutionContext 中的变量

**Priority**: P0

---

#### TC-S2-010-071: 表达式引擎 — 模拟步骤条件判断

**Description**: 验证表达式引擎能用于模拟步骤条件判断场景（如 Read 后判断是否继续）。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExecutionContext 实例
2. 存入变量 `"temperature" = PointValue::Number(120.0)`
3. 存入变量 `"max_temp" = PointValue::Number(100.0)`
4. 求值条件表达式 `"temperature > max_temp"`
5. 根据结果模拟分支逻辑

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`
- 条件判断逻辑能基于表达式结果执行不同分支

**Priority**: P0

---

#### TC-S2-010-072: 表达式引擎 — 多类型 PointValue 混合使用

**Description**: 验证表达式引擎能处理包含多种 PointValue 类型的变量上下文。

**Preconditions**: 无

**Test Steps**:
1. 创建变量上下文：
   - `"temp" = PointValue::Number(25.5)`
   - `"count" = PointValue::Integer(10)`
   - `"active" = PointValue::Boolean(true)`
   - `"status" = PointValue::String("normal")`
2. 求值表达式 `"temp > 20 && count > 5 && active"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`
- 所有类型的变量都能正确参与表达式求值

**Priority**: P1

---

#### TC-S2-010-073: 表达式引擎 — 实际试验场景（温度控制）

**Description**: 验证表达式引擎在典型试验场景中的使用：判断温度是否超过安全阈值。

**Preconditions**: 无

**Test Steps**:
1. 创建变量上下文模拟试验数据：
   - `"current_temp" = PointValue::Number(150.0)`
   - `"safe_temp" = PointValue::Number(120.0)`
   - `"heater_on" = PointValue::Boolean(true)`
2. 求值安全条件表达式：`"current_temp > safe_temp && heater_on"`
3. 验证结果

**Expected Results**:
- 求值成功，返回 `EvalResult::Boolean(true)`（温度超限且加热器仍在运行，需要触发安全逻辑）

**Priority**: P0

---

#### TC-S2-010-074: 表达式引擎 — 实际试验场景（压力监控）

**Description**: 验证表达式引擎在压力监控场景中的使用。

**Preconditions**: 无

**Test Steps**:
1. 创建变量上下文：
   - `"pressure" = PointValue::Number(95.0)`
   - `"min_pressure" = PointValue::Number(80.0)`
   - `"max_pressure" = PointValue::Number(100.0)`
2. 求值范围检查表达式：`"pressure >= min_pressure && pressure <= max_pressure"`
3. 验证结果
4. 修改 `"pressure" = PointValue::Number(105.0)`
5. 再次求值
6. 验证结果

**Expected Results**:
- 第一次求值返回 `EvalResult::Boolean(true)`（95 在 [80, 100] 范围内）
- 第二次求值返回 `EvalResult::Boolean(false)`（105 超出范围）

**Priority**: P0

---

#### TC-S2-010-075: 表达式引擎 — 重复求值一致性

**Description**: 验证同一表达式在相同上下文下的多次求值结果一致。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 创建变量上下文：`{"a": PointValue::Number(3.0), "b": PointValue::Number(4.0)}`
3. 求值表达式 `"a * b + 1"` 共 10 次
4. 验证每次结果相同

**Expected Results**:
- 10 次求值结果均为 `EvalResult::Number(13.0)`
- 无随机性或状态泄漏

**Priority**: P1

---

#### TC-S2-010-076: 表达式引擎 — 浮点精度验证

**Description**: 验证浮点数运算的精度在可接受范围内。

**Preconditions**: 无

**Test Steps**:
1. 创建 ExpressionEngine 实例
2. 求值表达式 `"0.1 + 0.2"`
3. 验证结果

**Expected Results**:
- 返回 `EvalResult::Number(0.3)`（允许浮点误差 ±0.0001）
- 注意：IEEE 754 浮点运算中 0.1 + 0.2 可能不完全等于 0.3，应在容差范围内

**Priority**: P1

---

## 测试执行计划

| 测试用例 | 优先级 | 类型 | 预估时间 |
|----------|--------|------|----------|
| TC-S2-010-001 | P0 | 单元测试 | 5 min |
| TC-S2-010-002 | P0 | 单元测试 | 5 min |
| TC-S2-010-003 | P0 | 单元测试 | 5 min |
| TC-S2-010-004 | P0 | 单元测试 | 5 min |
| TC-S2-010-005 | P0 | 单元测试 | 5 min |
| TC-S2-010-006 | P0 | 单元测试 | 5 min |
| TC-S2-010-007 | P0 | 单元测试 | 5 min |
| TC-S2-010-008 | P1 | 单元测试 | 5 min |
| TC-S2-010-009 | P0 | 单元测试 | 5 min |
| TC-S2-010-010 | P0 | 单元测试 | 5 min |
| TC-S2-010-011 | P0 | 单元测试 | 5 min |
| TC-S2-010-012 | P1 | 单元测试 | 5 min |
| TC-S2-010-013 | P0 | 单元测试 | 5 min |
| TC-S2-010-014 | P0 | 单元测试 | 5 min |
| TC-S2-010-015 | P1 | 单元测试 | 5 min |
| TC-S2-010-016 | P0 | 单元测试 | 5 min |
| TC-S2-010-017 | P0 | 单元测试 | 5 min |
| TC-S2-010-018 | P0 | 单元测试 | 5 min |
| TC-S2-010-019 | P0 | 单元测试 | 5 min |
| TC-S2-010-020 | P0 | 单元测试 | 5 min |
| TC-S2-010-021 | P0 | 单元测试 | 5 min |
| TC-S2-010-022 | P0 | 单元测试 | 5 min |
| TC-S2-010-023 | P0 | 单元测试 | 5 min |
| TC-S2-010-024 | P0 | 单元测试 | 5 min |
| TC-S2-010-025 | P0 | 单元测试 | 5 min |
| TC-S2-010-026 | P0 | 单元测试 | 5 min |
| TC-S2-010-027 | P0 | 单元测试 | 5 min |
| TC-S2-010-028 | P0 | 单元测试 | 5 min |
| TC-S2-010-029 | P0 | 单元测试 | 5 min |
| TC-S2-010-030 | P1 | 单元测试 | 5 min |
| TC-S2-010-031 | P1 | 单元测试 | 5 min |
| TC-S2-010-032 | P0 | 单元测试 | 5 min |
| TC-S2-010-033 | P0 | 单元测试 | 5 min |
| TC-S2-010-034 | P0 | 单元测试 | 5 min |
| TC-S2-010-035 | P0 | 单元测试 | 5 min |
| TC-S2-010-036 | P0 | 单元测试 | 5 min |
| TC-S2-010-037 | P0 | 单元测试 | 5 min |
| TC-S2-010-038 | P0 | 单元测试 | 5 min |
| TC-S2-010-039 | P1 | 单元测试 | 5 min |
| TC-S2-010-040 | P1 | 单元测试 | 5 min |
| TC-S2-010-041 | P1 | 单元测试 | 5 min |
| TC-S2-010-042 | P0 | 单元测试 | 5 min |
| TC-S2-010-043 | P0 | 单元测试 | 5 min |
| TC-S2-010-044 | P0 | 单元测试 | 5 min |
| TC-S2-010-045 | P0 | 单元测试 | 5 min |
| TC-S2-010-046 | P0 | 单元测试 | 5 min |
| TC-S2-010-047 | P0 | 单元测试 | 5 min |
| TC-S2-010-048 | P0 | 单元测试 | 5 min |
| TC-S2-010-049 | P1 | 单元测试 | 5 min |
| TC-S2-010-050 | P0 | 单元测试 | 5 min |
| TC-S2-010-051 | P1 | 单元测试 | 5 min |
| TC-S2-010-052 | P0 | 单元测试 | 5 min |
| TC-S2-010-053 | P0 | 单元测试 | 5 min |
| TC-S2-010-054 | P0 | 单元测试 | 5 min |
| TC-S2-010-055 | P0 | 单元测试 | 5 min |
| TC-S2-010-056 | P0 | 单元测试 | 5 min |
| TC-S2-010-057 | P0 | 单元测试 | 5 min |
| TC-S2-010-058 | P0 | 单元测试 | 5 min |
| TC-S2-010-059 | P1 | 单元测试 | 5 min |
| TC-S2-010-060 | P2 | 单元测试 | 5 min |
| TC-S2-010-061 | P1 | 单元测试 | 5 min |
| TC-S2-010-062 | P1 | 单元测试 | 5 min |
| TC-S2-010-063 | P1 | 单元测试 | 5 min |
| TC-S2-010-064 | P1 | 单元测试 | 5 min |
| TC-S2-010-065 | P1 | 单元测试 | 5 min |
| TC-S2-010-066 | P1 | 单元测试 | 5 min |
| TC-S2-010-067 | P0 | 单元测试 | 5 min |
| TC-S2-010-068 | P1 | 单元测试 | 5 min |
| TC-S2-010-069 | P2 | 单元测试 | 5 min |
| TC-S2-010-070 | P0 | 集成测试 | 10 min |
| TC-S2-010-071 | P0 | 集成测试 | 10 min |
| TC-S2-010-072 | P1 | 集成测试 | 10 min |
| TC-S2-010-073 | P0 | 集成测试 | 10 min |
| TC-S2-010-074 | P0 | 集成测试 | 10 min |
| TC-S2-010-075 | P1 | 单元测试 | 5 min |
| TC-S2-010-076 | P1 | 单元测试 | 5 min |

**总计**: 76 个测试用例
- P0: 44 个
- P1: 27 个
- P2: 5 个

---

## 验收标准映射

| 验收标准 | 覆盖测试用例 |
|----------|-------------|
| 1. 支持算术运算表达式 | TC-001 ~ TC-016, TC-030, TC-032, TC-033, TC-036, TC-038, TC-039, TC-044, TC-046, TC-052, TC-053, TC-067, TC-076 |
| 2. 支持条件表达式 | TC-017 ~ TC-031, TC-035, TC-036, TC-037, TC-042, TC-043, TC-047, TC-048, TC-049, TC-050 |
| 3. 变量替换正确执行 | TC-032 ~ TC-043, TC-044 ~ TC-053, TC-058, TC-070 ~ TC-075 |

---

## 运算符覆盖矩阵

| 运算符 | 测试用例 |
|--------|---------|
| `+` | TC-001, TC-005, TC-007, TC-009, TC-011, TC-012, TC-030, TC-034, TC-036, TC-038, TC-039, TC-044, TC-045, TC-046, TC-050, TC-051, TC-075 |
| `-` | TC-002, TC-006, TC-008, TC-009, TC-012, TC-062 |
| `*` | TC-003, TC-005, TC-007, TC-008, TC-010, TC-012, TC-033, TC-038, TC-039, TC-063, TC-075 |
| `/` | TC-004, TC-006, TC-008, TC-012, TC-013, TC-057, TC-058, TC-062, TC-067 |
| `%` | TC-014, TC-015, TC-016 |
| `>` | TC-017, TC-023, TC-029, TC-030, TC-035, TC-036, TC-048, TC-052, TC-070, TC-071, TC-073 |
| `<` | TC-018, TC-023, TC-029, TC-030, TC-036, TC-070 |
| `>=` | TC-019, TC-053, TC-074 |
| `<=` | TC-020, TC-023, TC-074 |
| `==` | TC-021, TC-049 |
| `!=` | TC-022 |
| `&&` | TC-024, TC-025, TC-029, TC-030, TC-031, TC-037, TC-070, TC-072, TC-073, TC-074 |
| `||` | TC-026, TC-027, TC-029, TC-030, TC-031 |
| `!` | TC-028, TC-037, TC-047 |
| `()` | TC-007, TC-008, TC-030, TC-039, TC-062 |

---

## 错误类型覆盖矩阵

| 错误类型 | 测试用例 |
|----------|---------|
| SyntaxError | TC-054, TC-055, TC-056, TC-060, TC-061, TC-069 |
| UndefinedVariable | TC-040, TC-042, TC-043 |
| TypeError | TC-047, TC-050 |
| DivisionByZero | TC-016, TC-057, TC-058, TC-062 |
| EmptyExpression | TC-059, TC-060 |

---

## 测试环境要求

1. **Rust 测试环境**: `cargo test` 可正常运行
2. **表达式库**: 如使用 `evalexpr` crate，需确保版本兼容
3. **浮点精度**: 浮点数比较测试需使用容差（epsilon = 0.0001）
4. **异步运行时**: 如表达式引擎集成到异步执行流程，测试需使用 `#[tokio::test]`

---

## 修订记录

| 版本 | 日期 | 修订内容 | 修订人 |
|------|------|---------|--------|
| 1.0 | 2026-04-02 | 初始版本，65 个测试用例，覆盖全部 3 个验收标准 | sw-mike |
| 1.1 | 2026-04-02 | 修订版本：<br>1. TC-041/TC-055: 移除条件断言，确立类型转换策略（Boolean→Number允许，Number→Boolean需显式比较）<br>2. TC-065: 移除（依赖S2-011）<br>3. 新增取模测试（TC-014/015/016）<br>4. 新增f64溢出/NaN测试（TC-063~TC-066）<br>5. 新增负数值变量测试（TC-033）<br>6. 新增变量名验证测试（TC-068/069）<br>7. 新增字符串连接测试（TC-051）<br>8. TC-029: 明确Integer→Number提升策略<br>9. 更新类型转换策略文档 | sw-mike |

---

**Author**: sw-mike
**Reviewer**: sw-tom
**Status**: 待复审
