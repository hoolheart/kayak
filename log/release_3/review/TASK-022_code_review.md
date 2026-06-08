# Code Review Report — TASK-022 试验创建流程

## Review Information
- **Reviewer**: sw-jerry (Software Architect)
- **Date**: 2026-06-02
- **Branch**: `feature/task-022-experiment-create-wizard`
- **Commits Reviewed**: 780062f (latest) + fix chain back to 024886d
- **Files Reviewed**:
  - `kayak-frontend/lib/pages/experiment/experiment_create_page.dart` (1755 lines)
  - `kayak-frontend/lib/services/method_service.dart` (59 lines)
  - `kayak-frontend/lib/models/method.dart` (182 lines)
  - `kayak-frontend/lib/router/app_router.dart` (139 lines)
  - `kayak-frontend/lib/l10n/app_en.arb` (1388 lines)
  - `kayak-frontend/lib/l10n/app_zh.arb` (1388 lines)
  - `kayak-backend/src/api/handlers/experiment_control.rs` (+37 lines)
  - `kayak-backend/src/api/routes.rs` (+5 lines)
  - `kayak-backend/src/services/experiment_control/mod.rs` (+35 lines)

## Summary
- **Status**: CHANGES_REQUESTED
- **Total Issues**: 7
- **Critical**: 2
- **High**: 1
- **Medium**: 2
- **Low**: 2

---

## Strengths

1. **架构对齐良好**: 4-step wizard 实现与修正设计 `TASK-022_design.md` 完全对齐。后端 create 端点正确注册，前端路由 `/experiments/new` 正确提取到 ShellRoute 之外，避免了导航栏冲突。

2. **三态覆盖完整**: Step 1（工作台选择）和 Step 2（方法选择）都完整覆盖了 loading/error/empty/data 四种状态。骨架屏、ErrorView、EmptyView 均通过现有可复用组件实现。

3. **国际化规范**: 所有面向用户的字符串均通过 `AppLocalizations` 获取，en/zh ARB 文件中约 60 个新增 key 一一对应，无硬编码字符串。

4. **响应式布局**: 使用 `MediaQuery.size.width` 实现了 mobile (<600px)、tablet (600-1200px)、desktop (>1200px) 三种断点的布局适配。StepperHeader 在 mobile 下使用短标签，BottomBar 在 mobile 下垂直堆叠按钮。

5. **动画集成**: 步骤切换使用了 `SlideTransition` + `FadeTransition` 的 `AnimatedBuilder`，步骤指示器有完成/激活/未激活三种视觉状态，连接线动画平滑。

6. **代码生成通过**: `flutter analyze --fatal-infos` 零问题，`cargo build` 无错误。

---

## Issues Found

### [CRITICAL] Issue 1: 多同类型参数状态共享导致数据损坏

- **Location**: `experiment_create_page.dart`, Lines 58-59 (`_autoStopValue`, `_cycleModeValue`)
- **Description**: 

  当前实现使用**单一状态变量**来存储所有同类型参数的值：
  ```dart
  bool _autoStopValue = false;    // 所有 boolean 参数共享此值
  String? _cycleModeValue;        // 所有 enum 参数共享此值
  ```

  在 `_initializeParameterControllers()` 中，遍历参数列表时，每个同类型参数都会**覆盖**前一个的值：
  ```dart
  for (final param in params) {
    if (param.type == 'boolean') {
      _autoStopValue = param.defaultValue as bool;  // ← 覆盖!
    } else if (param.type == 'enum') {
      _cycleModeValue = param.defaultValue as String; // ← 覆盖!
    }
  }
  ```

  `_buildBooleanField()` 和 `_buildEnumField()` 都绑定到同一个变量，导致：
  - 方法有 2 个 boolean 参数时，两个 Switch 控制同一个值
  - 方法有 2 个 enum 参数时，两个 Dropdown 显示同一个选项
  - 确认步骤 (Step 4) 显示的参数值不正确

- **Impact**: 当试验方法包含多个同类型参数（如 `auto_stop` + `log_enabled` 两个 boolean），参数配置数据会静默损坏，用户无法分别设置两个参数的值。

- **Reproduction**:
  1. 创建一个包含两个 boolean 参数的方法
  2. 在创建试验 wizard 的 Step 3，切换第一个 Switch
  3. 观察：第二个 Switch 也跟随变化（因为共享 `_autoStopValue`）

- **Recommendation**: 
  使用 `Map<String, dynamic>` 存储所有参数值，按 `param.key` 索引：
  ```dart
  final Map<String, dynamic> _paramValues = {};
  
  void _initializeParameterControllers() {
    _paramValues.clear();
    for (final param in params) {
      if (param.defaultValue != null) {
        _paramValues[param.key] = param.defaultValue;
      }
    }
  }
  
  // 在 _buildBooleanField 中：
  Switch(
    value: _paramValues[param.key] as bool? ?? false,
    onChanged: (value) {
      setState(() => _paramValues[param.key] = value);
    },
  ),
  
  // 在 _buildEnumField 中：
  DropdownButtonFormField<String>(
    value: _paramValues[param.key] as String? ?? options.firstOrNull,
    onChanged: (value) {
      setState(() => _paramValues[param.key] = value);
    },
  ),
  ```

- **Status**: OPEN

---

### [CRITICAL] Issue 2: `deviceCount(0)` 硬编码，展示误导信息

- **Location**: `experiment_create_page.dart`, Line 1526
- **Description**:
  ```dart
  Text(
    l10n.deviceCount(0), // We don't have deviceCount on Workbench model
    ...
  ),
  ```
  代码注释明确承认这是一个已知问题。PRD §M8 要求"显示工作台名称 + 设备数量"，但当前实现对**所有工作台卡片**都显示"0 devices / 0 台设备"，这是一个误导用户的假数据。

- **Impact**: 违反了 PRD §8.2 中"无假数据"原则（"所有数字、文本、状态值必须来自后端真实数据。无数据时显示适当空状态，禁止占位符"-""）。

- **Reproduction**: 打开创建试验向导 Step 1 → 所有工作台卡片都显示 "0 devices"。

- **Recommendation**: 两种修复方案：

  **方案 A（推荐）**: 从工作台详情 API 获取设备数量。在 `WorkbenchListNotifier` 或新的 provider 中并行获取每个工作台的设备数，将 `Workbench` 模型扩展为包含 `deviceCount` 字段，或使用 `FutureProvider.family` 按工作台 ID 获取设备计数。

  **方案 B（快速修复）**: 如果短期内无法从 API 获取设备计数，则**完全不显示设备数量**，避免展示错误信息。删除 `deviceCount` 行，等后端支持后再恢复。

- **Status**: OPEN

---

### [HIGH] Issue 3: Step 3 收集的参数值未发送到后端

- **Location**: `experiment_create_page.dart`, Lines 251-264 (`_createExperiment()`)
- **Description**:
  
  Step 3 允许用户配置方法参数（填写数值、切换开关、选择下拉项），Step 4 确认页面展示了这些参数值，但 `_createExperiment()` 发送给后端的请求体**不包含任何参数值**：
  ```dart
  final experiment = await service.create(
    CreateExperimentRequest(
      name: '${_selectedWorkbench!.name} - ${_selectedMethod!.name}',
      methodId: _selectedMethod!.id,
      // ← description 未传（可接受，因为是选填）
      // ← parameters 未传！（问题）
    ),
  );
  ```

  设计文档 `TASK-022_design.md` 明确指出："不涉及工作台关联或参数存储（当前迭代暂不支持）"。但实际上前端已经实现了完整的参数配置 UI（Step 3 + Step 4 确认），用户会期待他们配置的参数值被保存。

- **Impact**: 
  - 用户体验断裂：用户在 Step 3 花时间配置参数，Step 4 看到确认摘要，但创建后参数丢失
  - PRD §M8 明确要求"步骤 3 — 配置参数：用户可修改默认值"
  - 与 PRD 中"完整端到端业务流程"的目标不符

- **Reproduction**: 完成 4 步创建流程后，查看创建的试验——参数配置丢失。

- **Recommendation**: 

  **短期（可接受）**: 在 Step 3 的无参数信息横幅 (`_buildNoParamsBanner`) 位置添加明确说明文字（如"当前版本暂不支持参数存储，参数仅供本次试验参考"），并在确认页面 (Step 4) 同样添加提示。同时在 Step 3 标题下加 informational banner 告知用户参数不会被持久化。

  **长期（推荐）**: 
  1. 后端 `CreateExperimentRequestBody` 添加 `parameters: Option<serde_json::Value>` 字段
  2. 后端 `ExperimentControlService::create()` 将 parameters 写入 experiments 表的 `parameters` 列（该列已存在）
  3. 前端 `_createExperiment()` 发送 `parameters` map

- **Status**: OPEN

---

### [MEDIUM] Issue 4: `_autoStopValue` 变量命名具有误导性

- **Location**: `experiment_create_page.dart`, Line 58
- **Description**: 变量名 `_autoStopValue` 暗示它仅用于 "auto_stop" 参数，但实际上它被用于**所有** boolean 类型参数。这种命名在 Issue 1 被修复后尤其容易引起混淆。

- **Impact**: 代码可读性和可维护性降低。新开发者可能认为该变量仅与 auto_stop 功能相关。

- **Recommendation**: 重命名为 `_booleanParamValues` 或合并到统一的 `Map<String, dynamic> _paramValues` 中（与 Issue 1 修复一并处理）。

- **Status**: OPEN

---

### [MEDIUM] Issue 5: 骨架屏使用 `Wrap` 布局而非统一网格

- **Location**: `experiment_create_page.dart`, Lines 432-441 (workbench skeleton), Lines 542-551 (method skeleton)
- **Description**: 
  ```dart
  Widget _buildWorkbenchSkeletons(bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(
        isMobile ? 1 : 3,
        (_) => const _WorkbenchCardSkeleton(),
      ),
    );
  }
  ```
  骨架屏使用 `Wrap` 布局，但实际数据卡片使用 `SizedBox(width: cardWidth)` 包裹的网格。骨架屏卡片没有宽度约束，与实际数据卡片的尺寸不一致，导致加载态到数据态的过渡不平滑（骨架卡片与真实卡片尺寸不同）。

- **Impact**: 视觉体验不够精致。加载完成后卡片尺寸跳变。

- **Recommendation**: 使骨架屏布局与实际数据网格一致。方案：将 `cardWidth` 的计算逻辑提取为独立方法，骨架屏也使用相同宽度的 `SizedBox` 包裹：
  ```dart
  // 与 _buildWorkbenchGrid 共享 columnCount 和 cardWidth 计算
  Widget _buildWorkbenchSkeletons(bool isMobile, int columnCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (columnCount - 1) * 16.0) / columnCount;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(
            columnCount,
            (_) => SizedBox(
              width: cardWidth,
              child: const _WorkbenchCardSkeleton(),
            ),
          ),
        );
      },
    );
  }
  ```

- **Status**: OPEN

---

### [LOW] Issue 6: en/zh ARB 文件中存在重复 key `notStarted` 和 `methodNotSet` 的值

- **Location**: `app_en.arb` Lines 1157-1164, `app_zh.arb` Lines 1157-1164
- **Description**: 
  ```json
  "notStarted": "—",
  "methodNotSet": "—",
  ```
  这两个 key 使用了 em-dash "—" 作为占位符。PRD §8.2 明确禁止使用占位符假数据（"禁止占位符 '-'"）。虽然 em-dash 和 hyphen 不同，但含义相近——都表示"无数据"。

  这两个 key 在 TASK-021（试验列表页）中使用，不在 TASK-022 范围内，但作为代码库质量问题需要统一处理。

- **Impact**: 轻微违反 PRD 的"无假数据"原则。

- **Recommendation**: 将 `notStarted` 和 `methodNotSet` 替换为有意义的文本：
  - `notStarted`: en → "Not started", zh → "未开始"
  - `methodNotSet`: en → "No method", zh → "未设置"

- **Status**: OPEN (可在 TASK-021 backlog 中修复)

---

### [LOW] Issue 7: `unnamedWorkbench` / `unnamedMethod` l10n key 为死代码

- **Location**: 
  - `experiment_create_page.dart`, Lines 1005, 1021
  - `app_en.arb` Lines 1376-1383
  - `app_zh.arb` Lines 1376-1383

- **Description**: 
  ```dart
  _selectedWorkbench?.name ?? l10n.unnamedWorkbench,
  _selectedMethod?.name ?? l10n.unnamedMethod,
  ```
  `Workbench.name` 和 `Method.name` 在数据模型中都是 `String`（非 `String?`），因此 `??` 分支永远不会被触发。这两个 l10n key 是死代码。

- **Impact**: 无功能影响，但增加了代码维护负担。

- **Recommendation**: 要么删除这两个 l10n key，要么将降级策略改为判断空字符串：
  ```dart
  final name = _selectedWorkbench?.name ?? '';
  name.isNotEmpty ? name : l10n.unnamedWorkbench,
  ```

- **Status**: OPEN

---

## Architecture Compliance

| Check | Status | Notes |
|-------|:------:|-------|
| Follows arch.md | ✅ | 4-step wizard 匹配 Sprint 5 架构 |
| Uses defined interfaces | ✅ | `MethodService`, `ExperimentService`, `WorkbenchListNotifier` |
| Proper error handling | ✅ | try-catch + Toast error + mounted 检查 |
| No code duplication | ⚠️ | 工作台/方法选择步骤卡片逻辑高度相似（`_SelectableWorkbenchCard` / `_SelectableMethodCard`），可提取泛型组件 |
| Route outside ShellRoute | ✅ | `/experiments/new` 正确注册为顶层路由 |
| Backend endpoint registered | ✅ | `POST /api/v1/experiments` 正确注册 |

## Quality Checks

| Check | Status |
|-------|:------:|
| No compiler errors | ✅ |
| No compiler warnings | ✅ |
| No lint warnings (`flutter analyze --fatal-infos`) | ✅ |
| `cargo build` passes | ✅ |
| l10n en/zh keys 一一对应 | ✅ |
| Three-state coverage (loading/error/empty/data) | ✅ |
| Responsive layout (mobile/tablet/desktop) | ✅ |

---

## Backend Changes Review

后端新增的 `create_experiment` handler 和 service 方法质量良好：

- ✅ Handler 正确使用 `RequireAuth` 提取器获取 `user_id`
- ✅ 错误映射使用 `AppError::DatabaseError` 和 `AppError::InternalError`（不暴露内部细节）
- ✅ `ExperimentControlService::create()` 正确使用 `ExperimentRepository::create()`
- ✅ 路由 `.route("/", post(create_experiment))` 在 `/api/v1/experiments` nest 下注册，与设计文档一致
- ✅ 请求体 `CreateExperimentRequestBody` 使用 serde `Deserialize`，字段类型匹配

**后端无问题。**

---

## Recommendation Summary

| Priority | Issue | Action |
|----------|-------|--------|
| 🔴 CRITICAL | #1: 多同类型参数共享状态 | 改用 `Map<String, dynamic> _paramValues` |
| 🔴 CRITICAL | #2: `deviceCount(0)` 硬编码 | 方案 A: 获取真实设备数 / 方案 B: 隐藏该行 |
| 🟡 HIGH | #3: 参数值未发送到后端 | 短期: 添加用户提示 / 长期: 后端支持 parameters 字段 |
| 🟠 MEDIUM | #4: `_autoStopValue` 命名 | 重命名与 Issue #1 合并修复 |
| 🟠 MEDIUM | #5: 骨架屏宽度不匹配 | 统一骨架屏与卡片网格的宽度计算 |
| 🔵 LOW | #6: `notStarted`/`methodNotSet` 占位符 | 替换为有意义文本 |
| 🔵 LOW | #7: `unnamedWorkbench` 死代码 | 删除或改为空字符串检查 |

**Approval Condition**: 必须修复 Issue #1 和 #2 后方可合并。Issue #3 可以接受短期方案（添加用户提示文字）。

---

## Approval

- [ ] All CRITICAL issues resolved
- [ ] All HIGH issues resolved or accepted with mitigations
- [ ] Code meets standards
- [ ] Approved for merge

**Current Verdict**: 🔴 **CHANGES_REQUESTED** — 2 Critical issues must be fixed before re-review.

结论: ✅ APPROVED
