# TASK-022 测试用例 — 试验创建流程 UI

> **任务**: 试验创建流程 UI (`/experiments/new`)  
> **依赖**: TASK-021（试验列表页面）、TASK-012（WorkbenchService）、TASK-020（ExperimentService）  
> **PRD 章节**: M8 §创建试验流程验收标准  
> **设计参考**: TASK-022 需求定义（4 步向导：选择工作台 → 选择方法 → 配置参数 → 创建）  
> **作者**: sw-mike（Software Tester）  
> **日期**: 2026-06-02  
> **版本**: 1.0  
> **总计**: 55 项测试用例

---

## 目录

1. [页面加载与步骤导航 (TC-022-01 ~ TC-022-07)](#1-页面加载与步骤导航)
2. [步骤 1 — 选择工作台 (TC-022-08 ~ TC-022-16)](#2-步骤-1--选择工作台)
3. [步骤 2 — 选择方法 (TC-022-17 ~ TC-022-24)](#3-步骤-2--选择方法)
4. [步骤 3 — 配置参数 (TC-022-25 ~ TC-022-33)](#4-步骤-3--配置参数)
5. [步骤 4 — 创建提交 (TC-022-34 ~ TC-022-39)](#5-步骤-4--创建提交)
6. [步骤流转与导航 (TC-022-40 ~ TC-022-43)](#6-步骤流转与导航)
7. [响应式布局 (TC-022-44 ~ TC-022-46)](#7-响应式布局)
8. [国际化与主题适配 (TC-022-47 ~ TC-022-49)](#8-国际化与主题适配)
9. [错误处理与边界条件 (TC-022-50 ~ TC-022-55)](#9-错误处理与边界条件)

---

## 测试环境

- **Flutter SDK**: 3.19+
- **目标平台**: Web（Chrome/Firefox/Safari）
- **测试框架**: `flutter_test`, `mocktail`
- **状态管理**: `flutter_riverpod` 3.3.1
- **Provider 依赖**: `workbenchListProvider`, `methodListProvider`, `experimentCreateProvider`

---

## 通用前置条件

| 项目 | 内容 |
|------|------|
| **认证** | 用户已登录（Token 有效） |
| **路由** | 当前位于 `/experiments/new` |
| **依赖 Provider** | `workbenchListProvider`, `methodListProvider` 已注册 |
| **依赖 Service** | `WorkbenchService.list()`, `MethodService.list()`, `ExperimentService.create()` 可 mock |
| **l10n** | `AppLocalizations` 已加载，支持 en/zh |

---

## 1. 页面加载与步骤导航

### TC-022-01: 页面初始加载显示步骤指示器

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-01 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 创建试验流程；PRD 3.2: 步骤指示 |

**前置条件**:
- 用户已登录
- 导航到 `/experiments/new`

**测试步骤**:
1. 渲染 `ExperimentCreatePage`
2. 等待 widget 树稳定

**预期结果**:
- [ ] 页面顶部显示步骤指示器（Stepper 或 Progress Indicator）
- [ ] 显示 4 个步骤标签："选择工作台"、"选择方法"、"配置参数"、"确认创建"
- [ ] 当前激活步骤为第 1 步（"选择工作台"）
- [ ] 步骤指示器通过 l10n 获取文本（非硬编码）
- [ ] 步骤 2/3/4 显示为未激活状态（灰色或禁用样式）
- [ ] 页面主体区域显示步骤 1 的内容
- [ ] 控制台无异常

---

### TC-022-02: 步骤指示器步骤数正确

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-02 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 四步创建向导 |

**前置条件**:
- 页面已加载

**测试步骤**:
1. 检查步骤指示器中的步骤数量

**预期结果**:
- [ ] 步骤总数为 4 个
- [ ] 步骤顺序严格为：工作台 → 方法 → 参数 → 创建
- [ ] 无多余的步骤或缺失的步骤
- [ ] 步骤编号从 1 开始

---

### TC-022-03: 当前步骤高亮显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-03 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 视觉反馈 |

**前置条件**:
- 页面已加载，当前在步骤 1

**测试步骤**:
1. 检查当前步骤的视觉样式
2. 检查未激活步骤的视觉样式

**预期结果**:
- [ ] 当前步骤（步骤 1）有突出高亮（如主色背景、粗体文字、放大图标）
- [ ] 已完成的步骤（无）显示为完成状态（如勾选图标、主色）
- [ ] 未激活步骤显示为禁用状态（灰色、细体文字）
- [ ] 步骤之间的连接线样式正确（已完成段主色，未完成段灰色）

---

### TC-022-04: 页面标题和返回按钮

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-04 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 附录 A: 路由；PRD 3.2: 导航 |

**前置条件**:
- 页面在 `AppShell` 内渲染

**测试步骤**:
1. 检查页面标题
2. 检查返回按钮

**预期结果**:
- [ ] 页面标题为"创建试验"（中文）/ "Create Experiment"（英文）
- [ ] 显示返回按钮或"← 返回列表"链接
- [ ] 点击返回按钮导航到 `/experiments`
- [ ] NavigationRail / BottomNavigationBar 的"试验"标签处于激活状态

---

### TC-022-05: 页面加载时自动请求工作台列表

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-05 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8: 步骤 1；TASK-012: WorkbenchProvider |

**前置条件**:
- `workbenchListProvider` 已配置
- mock `WorkbenchService.list()`

**测试步骤**:
1. 渲染 `ExperimentCreatePage`
2. 验证 `WorkbenchService.list()` 被调用

**预期结果**:
- [ ] 页面渲染时自动调用 `WorkbenchService.list()`
- [ ] 调用参数：无特殊筛选，获取所有工作台
- [ ] Provider 状态从 `AsyncLoading` 变为 `AsyncData` 或 `AsyncError`
- [ ] 不重复请求（build 时不多次调用）

---

### TC-022-06: 步骤指示器支持点击跳转（已完成步骤）

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-06 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 用户体验；PRD M8: 步骤导航 |

**前置条件**:
- 用户已完成步骤 1 和步骤 2（已选择工作台和方法）
- 当前在步骤 3

**测试步骤**:
1. 点击步骤指示器中的"步骤 1 — 选择工作台"
2. 点击步骤指示器中的"步骤 2 — 选择方法"

**预期结果**:
- [ ] 点击已完成的步骤 1，页面跳转到工作台选择界面
- [ ] 已选择的工作台保持选中状态
- [ ] 点击已完成的步骤 2，页面跳转到方法选择界面
- [ ] 已选择的方法保持选中状态
- [ ] 未完成的步骤（步骤 4）不可点击

---

### TC-022-07: 步骤指示器完成状态更新

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-07 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 视觉反馈 |

**前置条件**:
- 初始状态：所有步骤未完成

**测试步骤**:
1. 选择工作台 → 进入步骤 2
2. 选择方法 → 进入步骤 3

**预期结果**:
- [ ] 选择工作台后，步骤 1 显示为完成状态（勾选图标）
- [ ] 进入步骤 2 后，步骤 2 显示为激活状态
- [ ] 选择方法后，步骤 2 显示为完成状态
- [ ] 进入步骤 3 后，步骤 3 显示为激活状态
- [ ] 步骤 1 和 2 之间的连接线变为主色

---

## 2. 步骤 1 — 选择工作台

### TC-022-08: 工作台列表加载中显示骨架屏

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-08 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 1 加载状态；PRD 8.2: 三态覆盖 |

**前置条件**:
- `workbenchListProvider` 返回 `AsyncLoading()`

**测试步骤**:
1. 渲染 `ExperimentCreatePage`
2. 等待 widget 树稳定

**预期结果**:
- [ ] 步骤 1 区域显示 `SkeletonList` 骨架屏组件
- [ ] 骨架屏包含工作台卡片占位（至少 3 个）
- [ ] 每个占位包含名称行和设备数量行的占位
- [ ] 骨架屏有 shimmer/渐变动画效果
- [ ] 无真实工作台卡片显示
- [ ] 步骤 2/3/4 区域不显示或显示禁用占位
- [ ] 控制台无异常

**测试数据**:
```dart
when(() => mockWorkbenchService.list()).thenAnswer(
  (_) async => Future.delayed(const Duration(seconds: 5), () => []),
);
```

---

### TC-022-09: 工作台列表加载完成显示数据

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-09 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 1 数据展示 |

**前置条件**:
- `workbenchListProvider` 返回 `AsyncData([...workbenches])`，包含 3 条记录

**测试步骤**:
1. 渲染 `ExperimentCreatePage`
2. 等待异步数据加载完成

**预期结果**:
- [ ] 骨架屏消失
- [ ] 显示工作台卡片/列表项
- [ ] 每个工作台显示：名称、设备数量
- [ ] 显示 3 个工作台卡片
- [ ] 卡片布局整齐，间距一致

**测试数据**:
```dart
// 使用附录 A 的测试数据工厂（包含完整字段）
final workbenches = WorkbenchTestData.list();
```

---

### TC-022-10: 工作台列表空状态显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-10 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 1 空状态；PRD 8.2: 三态覆盖 |

**前置条件**:
- `workbenchListProvider` 返回 `AsyncData([])`（空列表）

**测试步骤**:
1. 渲染 `ExperimentCreatePage`
2. 等待异步数据加载完成

**预期结果**:
- [ ] 显示 `EmptyView` 空状态组件
- [ ] 显示空状态图标（如 `Icons.build_outlined` 或工作台相关图标）
- [ ] 显示提示文本："您还没有工作台"（中文）/ "No workbenches yet"（英文）
- [ ] 显示"创建第一个工作台"按钮或引导链接
- [ ] 点击"创建第一个工作台"导航到 `/workbenches`
- [ ] 无工作台卡片、无骨架屏、无错误提示

---

### TC-022-11: 工作台列表加载错误状态

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-11 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 1 错误状态；PRD 8.2: 三态覆盖 |

**前置条件**:
- `workbenchListProvider` 返回 `AsyncError('网络连接超时', stackTrace)`

**测试步骤**:
1. 渲染 `ExperimentCreatePage`
2. 等待异步操作完成

**预期结果**:
- [ ] 显示 `ErrorView` 错误状态组件
- [ ] 显示错误图标
- [ ] 显示用户友好错误消息（非技术栈跟踪）
- [ ] 显示"重新加载"按钮
- [ ] 点击"重新加载"按钮触发 Provider 的 `refresh()` 方法
- [ ] 无工作台卡片、无骨架屏

---

### TC-022-12: 选择工作台高亮显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-12 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 选中的工作台高亮 |

**前置条件**:
- 工作台列表已加载完成，有 3 个工作台

**测试步骤**:
1. 点击第 1 个工作台卡片

**预期结果**:
- [ ] 被点击的工作台卡片显示高亮样式（如主色边框、主色背景、阴影加深）
- [ ] 未选中的工作台卡片保持默认样式
- [ ] 选中的工作台内部或旁边显示勾选图标（✓）
- [ ] 高亮样式与 Material 3 主题一致

---

### TC-022-13: 切换工作台选择

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-13 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 工作台选择 |

**前置条件**:
- 工作台列表已加载
- 已选择第 1 个工作台

**测试步骤**:
1. 点击第 2 个工作台卡片

**预期结果**:
- [ ] 第 2 个工作台卡片显示高亮样式
- [ ] 第 1 个工作台卡片恢复默认样式（取消高亮）
- [ ] 只允许多选中的一个工作台被选中（单选）
- [ ] 选择状态正确更新到状态管理中

---

### TC-022-14: 工作台显示设备数量

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-14 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 显示工作台名称 + 设备数量 |

**前置条件**:
- 工作台列表已加载

**测试步骤**:
1. 检查每个工作台卡片的显示内容

**预期结果**:
- [ ] 每个工作台卡片显示工作台名称
- [ ] 每个工作台卡片显示设备数量（如"5 台设备" / "5 devices"）
- [ ] 设备数量为 0 时显示"0 台设备" / "0 devices"
- [ ] 设备数量文本通过 l10n 获取
- [ ] 名称和设备数量布局清晰，不重叠

---

### TC-022-15: 工作台卡片点击反馈

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-15 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 交互反馈 |

**前置条件**:
- 工作台列表已加载

**测试步骤**:
1. 鼠标悬停在工作台卡片上
2. 点击工作台卡片

**预期结果**:
- [ ] 悬停时卡片有视觉反馈（阴影变化、背景色微调）
- [ ] 鼠标指针变为手型
- [ ] 点击时有涟漪效果（Material 3）
- [ ] 点击后卡片立即高亮

---

### TC-022-16: 工作台名称超长截断

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-16 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 8.2: 边界条件 |

**前置条件**:
- 工作台列表包含超长名称的工作台

**测试步骤**:
1. 检查超长名称的显示

**预期结果**:
- [ ] 超长名称截断显示（带省略号...）
- [ ] 截断不破坏布局（无溢出错误）
- [ ] 设备数量信息仍然可见

**测试数据**:
```dart
final workbench = WorkbenchTestData.longNameBench();
```

---

## 3. 步骤 2 — 选择方法

### TC-022-17: 进入步骤 2 自动加载方法列表

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-17 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8: 步骤 2；TASK-022: MethodService |

**前置条件**:
- 已完成步骤 1（已选择工作台）
- `methodListProvider` 已配置
- mock `MethodService.list()`

**测试步骤**:
1. 完成步骤 1，进入步骤 2
2. 验证 `MethodService.list()` 被调用

**预期结果**:
- [ ] 进入步骤 2 后自动调用 `MethodService.list()`
- [ ] 步骤 2 区域显示加载状态（骨架屏或 CircularProgressIndicator）
- [ ] Provider 状态从 `AsyncLoading` 变为 `AsyncData` 或 `AsyncError`
- [ ] 不重复请求

---

### TC-022-18: 方法列表加载完成显示数据

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-18 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 2 数据展示 |

**前置条件**:
- `methodListProvider` 返回 `AsyncData([...methods])`，包含 3 条记录
- 已完成步骤 1

**测试步骤**:
1. 进入步骤 2
2. 等待异步数据加载完成

**预期结果**:
- [ ] 骨架屏/加载指示器消失
- [ ] 显示方法卡片/列表项
- [ ] 每个方法显示：方法名、描述摘要
- [ ] 显示 3 个方法卡片
- [ ] 卡片布局整齐，间距一致

**测试数据**:
```dart
final methods = [
  Method(
    id: 'method-001',
    name: '标准热循环',
    description: '按照标准温度循环曲线进行测试',
    parameters: [...],
  ),
  Method(
    id: 'method-002',
    name: '恒定压力测试',
    description: '在恒定压力下持续监测设备状态',
    parameters: [...],
  ),
  Method(
    id: 'method-003',
    name: '振动耐久测试',
    description: '模拟振动环境进行耐久性测试',
    parameters: [...],
  ),
];
```

---

### TC-022-19: 方法列表空状态

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-19 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 2 空状态 |

**前置条件**:
- `methodListProvider` 返回 `AsyncData([])`
- 已完成步骤 1

**测试步骤**:
1. 进入步骤 2
2. 等待加载完成

**预期结果**:
- [ ] 显示空状态提示："暂无可用方法"（中文）/ "No methods available"（英文）
- [ ] 显示提示信息："请先创建试验方法"
- [ ] 提供"前往方法管理"链接或按钮 → `/methods`
- [ ] 无方法卡片显示

---

### TC-022-20: 方法列表加载错误

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-20 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 2 错误状态 |

**前置条件**:
- `methodListProvider` 返回 `AsyncError('加载失败', stackTrace)`
- 已完成步骤 1

**测试步骤**:
1. 进入步骤 2

**预期结果**:
- [ ] 显示 `ErrorView` 错误状态组件
- [ ] 显示用户友好错误消息
- [ ] 显示"重新加载"按钮
- [ ] 点击"重新加载"重新请求方法列表

---

### TC-022-21: 选择方法高亮显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-21 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 选中的方法高亮 |

**前置条件**:
- 方法列表已加载完成
- 已完成步骤 1

**测试步骤**:
1. 点击第 1 个方法卡片

**预期结果**:
- [ ] 被点击的方法卡片显示高亮样式（主色边框/背景）
- [ ] 未选中的方法卡片保持默认样式
- [ ] 选中的方法显示勾选图标
- [ ] 高亮样式与主题一致

---

### TC-022-22: 切换方法选择

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-22 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 方法选择 |

**前置条件**:
- 方法列表已加载
- 已选择第 1 个方法

**测试步骤**:
1. 点击第 2 个方法卡片

**预期结果**:
- [ ] 第 2 个方法卡片显示高亮样式
- [ ] 第 1 个方法卡片恢复默认样式
- [ ] 只允许多选中的一个方法被选中
- [ ] 选择状态正确更新

---

### TC-022-23: 方法描述摘要显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-23 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 显示方法名 + 描述摘要 |

**前置条件**:
- 方法列表已加载

**测试步骤**:
1. 检查每个方法卡片的显示内容

**预期结果**:
- [ ] 每个方法卡片显示方法名称
- [ ] 每个方法卡片显示描述摘要
- [ ] 描述摘要最多显示 2 行（超出截断带省略号）
- [ ] 名称为空时显示"未命名方法"或 ID

---

### TC-022-24: 方法描述超长截断

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-24 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 8.2: 边界条件 |

**前置条件**:
- 方法列表包含超长描述的方法

**测试步骤**:
1. 检查超长描述的显示

**预期结果**:
- [ ] 超长描述截断显示（最多 2 行，带省略号）
- [ ] 截断不破坏卡片布局
- [ ] 方法名称仍然清晰可见

**测试数据**:
```dart
Method(
  id: 'method-long',
  name: '复杂测试方法',
  description: '这是一个非常长的方法描述，用于测试超长文本在方法卡片中的显示效果。该方法涉及多个复杂的测试步骤和参数配置，需要在专业环境下执行。',
),
```

---

## 4. 步骤 3 — 配置参数

### TC-022-25: 进入步骤 3 动态生成参数表单

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-25 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 3 动态表单；TASK-022: 参数动态生成 |

**前置条件**:
- 已完成步骤 1 和 2（已选择工作台和方法）
- 所选方法包含参数定义

**测试步骤**:
1. 选择工作台
2. 选择方法（含参数）
3. 进入步骤 3

**预期结果**:
- [ ] 步骤 3 区域显示参数配置表单
- [ ] 表单根据所选方法的 `parameters` 列表动态生成字段
- [ ] 每个参数显示：参数名、类型、单位、描述、输入框
- [ ] 参数名通过 l10n 或方法定义显示
- [ ] 表单布局整齐，字段间距一致

**测试数据**:
```dart
final methodWithParams = Method(
  id: 'method-001',
  name: '标准热循环',
  parameters: [
    MethodParameter(
      name: 'targetTemperature',
      label: '目标温度',
      type: ParameterType.number,
      unit: '°C',
      description: '测试目标温度',
      defaultValue: 85.0,
      min: -40.0,
      max: 150.0,
    ),
    MethodParameter(
      name: 'duration',
      label: '持续时间',
      type: ParameterType.integer,
      unit: '分钟',
      description: '单个循环持续时间',
      defaultValue: 30,
      min: 1,
      max: 1440,
    ),
    MethodParameter(
      name: 'enableAutoStop',
      label: '自动停止',
      type: ParameterType.boolean,
      description: '达到条件后自动停止测试',
      defaultValue: true,
      required: false,
    ),
    MethodParameter(
      name: 'cycleMode',
      label: '循环模式',
      type: ParameterType.enum_,
      description: '温度循环模式',
      defaultValue: 'standard',
      options: ['standard', 'rapid', 'gradual'],
      required: true,
    ),
  ],
);
```

---

### TC-022-26: 参数表单默认值预填

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-26 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 默认值预填 |

**前置条件**:
- 已进入步骤 3
- 方法参数包含 `defaultValue`

**测试步骤**:
1. 检查每个参数输入框的初始值

**预期结果**:
- [ ] 数值类型参数：输入框显示默认值（如 `85.0`）
- [ ] 整数类型参数：输入框显示默认值（如 `30`）
- [ ] 字符串类型参数：输入框显示默认字符串
- [ ] 布尔类型参数：开关/复选框显示默认状态
- [ ] 枚举类型参数：下拉框显示默认选项
- [ ] 所有默认值与 `MethodParameter.defaultValue` 一致

---

### TC-022-27: 参数表单字段标签和辅助信息

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-27 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 参数名、类型、单位、描述 |

**前置条件**:
- 已进入步骤 3

**测试步骤**:
1. 检查每个参数字段的显示信息

**预期结果**:
- [ ] 每个字段显示参数标签（label）
- [ ] 每个字段显示单位（如 `°C`、`分钟`）
- [ ] 每个字段显示描述文本（作为 helper text 或 tooltip）
- [ ] 标签通过 l10n 获取或直接使用方法定义
- [ ] 单位和描述文本样式与 Material 3 一致（灰色、小字号）

---

### TC-022-28: 参数数值范围验证

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-28 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 参数验证（范围检查） |

**前置条件**:
- 已进入步骤 3
- 参数定义包含 `min` 和 `max`

**测试步骤**:
1. 输入低于最小值的数值（如目标温度输入 `-50`）
2. 输入高于最大值的数值（如目标温度输入 `200`）
3. 输入范围内的数值（如目标温度输入 `100`）

**预期结果**:
| 场景 | 预期行为 |
|------|----------|
| 低于最小值 | 显示验证错误："不能小于 -40°C" |
| 高于最大值 | 显示验证错误："不能大于 150°C" |
| 范围内 | 验证通过，无错误提示 |

- [ ] 验证错误文本通过 l10n 获取
- [ ] 验证错误在输入框下方显示（Material 3 错误样式）
- [ ] 有验证错误时表单标记为无效

---

### TC-022-29: 参数类型验证

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-29 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 参数验证（类型匹配） |

**前置条件**:
- 已进入步骤 3

**测试步骤**:
1. 在数值类型字段输入非数值文本（如 `abc`）
2. 在整数类型字段输入小数（如 `30.5`）
3. 在字符串类型字段输入任意文本

**预期结果**:
| 场景 | 预期行为 |
|------|----------|
| 数值字段输入文本 | 输入框拒绝非数字字符 或 显示类型错误 |
| 整数字段输入小数 | 显示验证错误："必须为整数" |
| 字符串字段输入文本 | 验证通过 |

- [ ] 数值输入框使用 `TextInputType.number` 或 `TextInputType.numberWithOptions`
- [ ] 类型验证错误提示友好

---

### TC-022-30: 参数值为空验证

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-30 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 参数验证 |

**前置条件**:
- 已进入步骤 3
- 参数为必填（无默认值且 required=true）

**测试步骤**:
1. 清空必填参数的输入框
2. 尝试进入步骤 4 或点击创建

**预期结果**:
- [ ] 显示验证错误："此字段为必填项"
- [ ] 必填参数输入框有红色边框/错误样式
- [ ] 创建按钮保持禁用状态（如果验证失败）
- [ ] 错误提示通过 l10n 获取

---

### TC-022-31: 修改参数值

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-31 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 用户可修改默认值 |

**前置条件**:
- 已进入步骤 3

**测试步骤**:
1. 在目标温度字段输入新值 `100`
2. 在持续时间字段输入新值 `60`

**预期结果**:
- [ ] 输入框显示新值
- [ ] 状态管理中的参数值同步更新
- [ ] 新值在有效范围内，无验证错误
- [ ] 切换到其他步骤后返回，修改的值保持

---

### TC-022-32: 无参数方法进入步骤 3

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-32 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 边界条件 |

**前置条件**:
- 选择的方法 `parameters` 为空列表

**测试步骤**:
1. 选择无参数的方法
2. 进入步骤 3

**预期结果**:
- [ ] 步骤 3 显示提示："该方法无需配置参数"
- [ ] 不跳过步骤 3，仍需点击"下一步"进入步骤 4
- [ ] 不显示空表单或错误
- [ ] 步骤 4 显示"创建"按钮（无需参数，创建按钮可用）

---

### TC-022-33: 参数表单响应式布局

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-33 |
| **优先级** | P1 |
| **类型** | Widget Test / Screenshot Test |
| **关联需求** | PRD 10.1: 响应式 |

**前置条件**:
- 已进入步骤 3
- 有多个参数

**测试步骤**:
1. 在大屏（1920px）下检查表单布局
2. 在中屏（900px）下检查表单布局
3. 在小屏（375px）下检查表单布局

**预期结果**:
| 屏幕 | 布局 |
|------|------|
| 大屏 (>1200px) | 参数字段双列或三列排列，或单列宽布局 |
| 中屏 (600-1200px) | 参数字段单列排列 |
| 小屏 (<600px) | 参数字段单列，标签在输入框上方 |

- [ ] 所有屏幕下表单可完整显示，无水平滚动
- [ ] 输入框宽度适应屏幕
- [ ] 标签和描述文本可读

---

## 5. 步骤 4 — 创建提交

### TC-022-34: 创建按钮在工作台和方法未选择时禁用

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-34 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 创建按钮禁用条件 |

**前置条件**:
- 刚进入页面，未选择工作台和方法

**测试步骤**:
1. 检查步骤 4 或页面底部的"创建"按钮状态

**预期结果**:
- [ ] "创建"按钮显示为禁用状态（灰色、不可点击）
- [ ] 按钮文本为"创建试验"（中文）/ "Create Experiment"（英文）
- [ ] 点击禁用按钮无响应
- [ ] 按钮有视觉提示说明为何禁用（如 tooltip："请先选择工作台和方法"）

---

### TC-022-35: 创建按钮仅选工作台时禁用

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-35 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 创建按钮禁用条件 |

**前置条件**:
- 已选择工作台
- 未选择方法

**测试步骤**:
1. 在步骤 1 选择工作台
2. 检查"创建"按钮状态

**预期结果**:
- [ ] "创建"按钮仍为禁用状态
- [ ] 按钮不可点击
- [ ] 提示用户需要选择方法

---

### TC-022-36: 创建按钮工作台和方法都选择后启用

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-36 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 创建按钮启用条件 |

**前置条件**:
- 已选择工作台
- 已选择方法

**测试步骤**:
1. 在步骤 1 选择工作台
2. 在步骤 2 选择方法
3. 检查"创建"按钮状态

**预期结果**:
- [ ] "创建"按钮变为可用状态（主色背景、可点击）
- [ ] 按钮视觉样式从禁用变为启用
- [ ] 鼠标悬停时按钮有悬停效果
- [ ] 点击按钮触发创建操作

---

### TC-022-37: 创建按钮在参数验证失败时禁用

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-37 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 参数验证 |

**前置条件**:
- 已选择工作台和方法
- 步骤 3 中有必填参数未填写或验证失败

**测试步骤**:
1. 清空必填参数的输入框
2. 检查"创建"按钮状态

**预期结果**:
- [ ] "创建"按钮为禁用状态
- [ ] 即使工作台和方法已选择，参数验证失败也禁用创建
- [ ] 参数验证通过后按钮自动启用

---

### TC-022-38: 创建成功跳转控制台

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-38 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD M8: 创建成功跳转 |

**前置条件**:
- 已选择工作台和方法
- 参数已配置（或无需参数）
- mock `ExperimentService.create()` 返回新创建的试验

**测试步骤**:
1. 点击"创建"按钮
2. 等待创建完成

**预期结果**:
- [ ] 创建请求发送：`POST /api/v1/experiments`
- [ ] 请求参数包含：`workbenchId`, `methodId`, `parameters`（键值对）
- [ ] 按钮显示 loading 状态（CircularProgressIndicator 或禁用 + loading）
- [ ] 创建成功后显示 Toast："试验创建成功"
- [ ] 导航到 `/experiments/{newExperimentId}`
- [ ] 新试验的 ID 来自 `ExperimentService.create()` 返回值

**测试数据**:
```dart
when(() => mockExperimentService.create(any())).thenAnswer(
  (_) async => Experiment(
    id: 'exp-new-001',
    name: '温度实验室 - 标准热循环',
    workbenchId: 'wb-001',
    methodId: 'method-001',
    status: ExperimentStatus.idle,
    createdAt: DateTime.now(),
  ),
);
```

---

### TC-022-39: 创建失败显示错误

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-39 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 创建失败处理；PRD 3.2: 错误反馈 |

**前置条件**:
- mock `ExperimentService.create()` 抛出异常

**测试步骤**:
1. 点击"创建"按钮
2. 等待请求完成

**预期结果**:
- [ ] 创建请求发送
- [ ] 按钮显示 loading 状态
- [ ] 请求失败后按钮恢复可用状态
- [ ] 显示错误 Toast："创建试验失败：具体原因"
- [ ] 页面不跳转，保持在创建页面
- [ ] 已选择的值和参数保持不变
- [ ] 无页面崩溃

---

## 6. 步骤流转与导航

### TC-022-40: 下一步按钮在工作台选择后启用

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-40 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤流转 |

**前置条件**:
- 在步骤 1

**测试步骤**:
1. 未选择工作台时检查"下一步"按钮
2. 选择工作台后检查"下一步"按钮

**预期结果**:
| 场景 | 下一步按钮 |
|------|-----------|
| 未选择工作台 | 禁用（灰色） |
| 已选择工作台 | 启用（主色） |

- [ ] 点击启用的"下一步"进入步骤 2
- [ ] 步骤指示器更新（步骤 1 完成，步骤 2 激活）

---

### TC-022-41: 下一步按钮在方法选择后启用

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-41 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤流转 |

**前置条件**:
- 在步骤 2

**测试步骤**:
1. 未选择方法时检查"下一步"按钮
2. 选择方法后检查"下一步"按钮

**预期结果**:
| 场景 | 下一步按钮 |
|------|-----------|
| 未选择方法 | 禁用（灰色） |
| 已选择方法 | 启用（主色） |

- [ ] 点击启用的"下一步"进入步骤 3

---

### TC-022-42: 上一步按钮返回上一页

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-42 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤导航 |

**前置条件**:
- 当前在步骤 2 或步骤 3

**测试步骤**:
1. 在步骤 2 点击"上一步"
2. 在步骤 3 点击"上一步"

**预期结果**:
- [ ] 步骤 2 点击"上一步"返回到步骤 1
- [ ] 步骤 3 点击"上一步"返回到步骤 2
- [ ] 返回后之前的选择保持（工作台仍选中、方法仍选中）
- [ ] 步骤指示器更新（当前步骤高亮）
- [ ] 每个步骤（除步骤 1）都显示"上一步"按钮

---

### TC-022-43: 步骤 3 的下一步/创建逻辑

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-43 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD M8: 步骤 3 → 步骤 4 |

**前置条件**:
- 在步骤 3
- 已配置参数（或无需参数）

**测试步骤**:
1. 检查步骤 3 的导航按钮
2. 点击"下一步"进入步骤 4
3. 检查步骤 4 的"创建"按钮

**预期结果**:
- [ ] 步骤 3 显示"下一步"按钮（进入步骤 4 确认预览页）
- [ ] 无参数方法在步骤 3 显示提示，但仍需点击"下一步"进入步骤 4
- [ ] 步骤 4 显示"创建"按钮
- [ ] 参数验证通过后方可点击"下一步"
- [ ] 步骤 4 显示确认预览信息（工作台、方法、参数摘要）

---

## 7. 响应式布局

### TC-022-44: 大屏（>1200px）步骤布局

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-44 |
| **优先级** | P0 |
| **类型** | Widget Test / Screenshot Test |
| **关联需求** | PRD 10.1: 响应式断点 |

**前置条件**:
- 视口宽度 > 1200px

**测试步骤**:
1. 在 1920x1080 视口下渲染页面

**预期结果**:
- [ ] 步骤指示器水平排列在页面顶部
- [ ] 步骤内容区域宽度适中，不拉伸过宽
- [ ] 工作台/方法卡片网格布局（2-3 列）
- [ ] 参数表单单列或双列布局
- [ ] 导航按钮在内容区域下方或右侧
- [ ] 左侧 NavigationRail 常驻显示

---

### TC-022-45: 中屏（600-1200px）步骤布局

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-45 |
| **优先级** | P0 |
| **类型** | Widget Test / Screenshot Test |
| **关联需求** | PRD 10.1: 响应式断点 |

**前置条件**:
- 视口宽度 = 900px

**测试步骤**:
1. 在 900px 宽度下渲染页面

**预期结果**:
- [ ] 步骤指示器水平排列但步骤标签可能简化为数字
- [ ] 工作台/方法卡片 2 列布局
- [ ] 参数表单单列布局
- [ ] 导航按钮全宽或居中
- [ ] NavigationRail 可折叠

---

### TC-022-46: 小屏（<600px）步骤布局

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-46 |
| **优先级** | P0 |
| **类型** | Widget Test / Screenshot Test |
| **关联需求** | PRD 10.1: 响应式断点；PRD 10.2: 移动端适配 |

**前置条件**:
- 视口宽度 = 375px

**测试步骤**:
1. 在 375px 宽度下渲染页面

**预期结果**:
- [ ] 步骤指示器简化为数字或进度条
- [ ] 工作台/方法卡片单列布局
- [ ] 参数表单单列，标签在输入框上方
- [ ] 导航按钮全宽堆叠（上一步/下一步垂直排列）
- [ ] BottomNavigationBar 底部导航
- [ ] 文本可读，触摸目标最小 48x48dp
- [ ] 无水平滚动

---

## 8. 国际化与主题适配

### TC-022-47: 中文界面文本正确

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-47 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 9: 国际化；PRD 11.3-39: 无硬编码文本 |

**前置条件**:
- 语言设置为中文（`Locale('zh')`）

**测试步骤**:
1. 在中文环境下渲染页面
2. 检查所有步骤的文本

**预期结果**:
- [ ] 页面标题："创建试验"
- [ ] 步骤 1 标签："选择工作台"
- [ ] 步骤 2 标签："选择方法"
- [ ] 步骤 3 标签："配置参数"
- [ ] 步骤 4 标签："确认创建"
- [ ] 按钮："下一步"、"上一步"、"创建试验"
- [ ] 空状态文本中文
- [ ] 错误消息中文
- [ ] 无硬编码英文文本（ARB key 缺失除外）

---

### TC-022-48: 英文界面文本正确

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-48 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 9: 国际化 |

**前置条件**:
- 语言设置为英文（`Locale('en')`）

**测试步骤**:
1. 在英文环境下渲染页面

**预期结果**:
- [ ] 页面标题："Create Experiment"
- [ ] 步骤标签："Select Workbench", "Select Method", "Configure Parameters", "Confirm"
- [ ] 按钮："Next", "Back", "Create Experiment"
- [ ] 空状态文本英文
- [ ] 错误消息英文

---

### TC-022-49: 浅色/深色主题适配

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-49 |
| **优先级** | P0 |
| **类型** | Screenshot Test |
| **关联需求** | PRD 3.3: 双主题；PRD 11.3-43: 主题正确 |

**前置条件**:
- 分别在浅色和深色主题下渲染

**测试步骤**:
1. 浅色主题下渲染页面（各步骤状态）
2. 深色主题下渲染页面（各步骤状态）

**预期结果**:
- [ ] 浅色主题：卡片背景浅色，文字深色，选中高亮使用主色
- [ ] 深色主题：卡片背景深色，文字浅色，选中高亮适配深色
- [ ] 步骤指示器在两种主题下均清晰可见
- [ ] 输入框在两种主题下均有清晰的边框/背景
- [ ] 禁用按钮在两种主题下均有明显的禁用样式
- [ ] 无颜色反转错误

---

## 9. 错误处理与边界条件

### TC-022-50: 网络错误后重试加载工作台

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-50 |
| **优先级** | P0 |
| **类型** | Widget Test / Integration Test |
| **关联需求** | PRD 3.2: 错误处理；PRD 8.2: 重试 |

**前置条件**:
- 首次加载工作台失败，重试成功

**测试步骤**:
1. mock `WorkbenchService.list()` 第一次抛出异常
2. 点击"重新加载"
3. mock `WorkbenchService.list()` 第二次返回成功数据

**预期结果**:
- [ ] 首次加载显示 ErrorView
- [ ] 错误消息友好："加载工作台列表失败，请稍后重试"
- [ ] 点击"重新加载"触发 Provider 刷新
- [ ] 第二次加载显示工作台列表
- [ ] 骨架屏在重试时短暂显示

---

### TC-022-51: 工作台数据字段缺失

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-51 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 8.2: 无假数据；PRD 3.2: 错误处理 |

**前置条件**:
- 后端返回字段不完整的工作台数据

**测试步骤**:
1. 渲染包含字段缺失数据的页面

**预期结果**:
| 缺失字段 | 预期显示 |
|----------|----------|
| `name` = null | 显示"未命名工作台"或空字符串 |
| `deviceCount` = null | 显示"—"或"0 台设备" |
| `description` = null | 不显示描述行 |

- [ ] 页面不崩溃
- [ ] 无 `null` 字符串显示
- [ ] 缺失字段不影响其他字段显示

---

### TC-022-52: 方法数据字段缺失

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-52 |
| **优先级** | P1 |
| **类型** | Widget Test |
| **关联需求** | PRD 8.2: 无假数据 |

**前置条件**:
- 后端返回字段不完整的方法数据

**测试步骤**:
1. 渲染包含字段缺失的方法数据

**预期结果**:
| 缺失字段 | 预期显示 |
|----------|----------|
| `name` = null | 显示方法 ID 或"未命名方法" |
| `description` = null | 不显示描述摘要 |
| `parameters` = null | 步骤 3 显示"无参数"或跳过 |

- [ ] 页面不崩溃
- [ ] 方法仍可被选择和创建

---

### TC-022-53: 创建过程中网络断开

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-53 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 网络错误处理 |

**前置条件**:
- 已选择工作台和方法
- mock `ExperimentService.create()` 模拟网络断开（DioExceptionType.connectionError）

**测试步骤**:
1. 点击"创建"按钮

**预期结果**:
- [ ] 按钮 loading 状态消失
- [ ] 显示错误 Toast："网络连接失败，请检查网络后重试"
- [ ] 页面保持在创建流程
- [ ] 所有已选择的值保持不变
- [ ] 可再次点击"创建"重试

---

### TC-022-54: 创建过程中服务器 500 错误

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-54 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 服务器错误处理 |

**前置条件**:
- mock `ExperimentService.create()` 返回 500 错误

**测试步骤**:
1. 点击"创建"按钮

**预期结果**:
- [ ] 按钮 loading 状态消失
- [ ] 显示错误 Toast："服务器错误，请稍后重试"
- [ ] 页面保持在创建流程
- [ ] 已选择的值保持不变
- [ ] 无页面崩溃

---

### TC-022-55: 快速连续点击创建按钮防重复

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-022-55 |
| **优先级** | P0 |
| **类型** | Widget Test |
| **关联需求** | PRD 3.2: 操作有反馈；PRD 11.3-42: 防止重复提交 |

**前置条件**:
- 已选择工作台和方法
- 创建按钮可用

**测试步骤**:
1. 快速连续点击"创建"按钮 3 次

**预期结果**:
- [ ] 只有第一次点击有效
- [ ] 后续点击被忽略（按钮 loading 状态阻止）
- [ ] 只发送一次创建请求
- [ ] 防止重复创建多个相同试验

---

## 附录 A：测试数据工厂

```dart
/// 工作台测试数据工厂
class WorkbenchTestData {
  static Workbench temperatureLab() => Workbench(
    id: 'wb-001',
    name: '温度实验室',
    description: '用于温度相关测试',
    deviceCount: 5,
    status: WorkbenchStatus.active,
    createdAt: DateTime(2026, 5, 1),
  );

  static Workbench workbench1() => temperatureLab();

  static Workbench vibrationBench() => Workbench(
    id: 'wb-002',
    name: '振动测试台',
    description: '用于振动耐久测试',
    deviceCount: 3,
    status: WorkbenchStatus.active,
    createdAt: DateTime(2026, 5, 2),
  );

  static Workbench emptyBench() => Workbench(
    id: 'wb-003',
    name: '压力测试区',
    description: null,
    deviceCount: 0,
    status: WorkbenchStatus.active,
    createdAt: DateTime(2026, 5, 3),
  );

  static Workbench longNameBench() => Workbench(
    id: 'wb-long',
    name: '这是一个非常长的工作台名称，用于测试超长文本的截断显示效果',
    deviceCount: 2,
    status: WorkbenchStatus.active,
    createdAt: DateTime(2026, 5, 4),
  );

  static List<Workbench> list() => [
    temperatureLab(),
    vibrationBench(),
    emptyBench(),
  ];
}

/// 方法测试数据工厂
class MethodTestData {
  static Method standardThermalCycle() => Method(
    id: 'method-001',
    name: '标准热循环',
    description: '按照标准温度循环曲线进行测试',
    parameters: [
      MethodParameter(
        name: 'targetTemperature',
        label: '目标温度',
        type: ParameterType.number,
        unit: '°C',
        description: '测试目标温度',
        defaultValue: 85.0,
        min: -40.0,
        max: 150.0,
        required: true,
      ),
      MethodParameter(
        name: 'duration',
        label: '持续时间',
        type: ParameterType.integer,
        unit: '分钟',
        description: '单个循环持续时间',
        defaultValue: 30,
        min: 1,
        max: 1440,
        required: true,
      ),
      MethodParameter(
        name: 'cycleCount',
        label: '循环次数',
        type: ParameterType.integer,
        unit: '次',
        description: '总循环次数',
        defaultValue: 10,
        min: 1,
        max: 1000,
        required: false,
      ),
      MethodParameter(
        name: 'enableAutoStop',
        label: '自动停止',
        type: ParameterType.boolean,
        description: '达到条件后自动停止测试',
        defaultValue: true,
        required: false,
      ),
      MethodParameter(
        name: 'cycleMode',
        label: '循环模式',
        type: ParameterType.enum_,
        description: '温度循环模式',
        defaultValue: 'standard',
        options: ['standard', 'rapid', 'gradual'],
        required: true,
      ),
    ],
  );

  static Method constantPressure() => Method(
    id: 'method-002',
    name: '恒定压力测试',
    description: '在恒定压力下持续监测设备状态',
    parameters: [
      MethodParameter(
        name: 'pressure',
        label: '压力值',
        type: ParameterType.number,
        unit: 'MPa',
        description: '恒定压力值',
        defaultValue: 2.5,
        min: 0.1,
        max: 10.0,
        required: true,
      ),
    ],
  );

  static Method noParamsMethod() => Method(
    id: 'method-003',
    name: '简单测试',
    description: '无需配置参数的简单测试',
    parameters: [],
  );

  static Method longDescriptionMethod() => Method(
    id: 'method-long',
    name: '复杂测试方法',
    description: '这是一个非常长的方法描述，用于测试超长文本在方法卡片中的显示效果。该方法涉及多个复杂的测试步骤和参数配置，需要在专业环境下执行。',
    parameters: [],
  );

  static List<Method> list() => [
    standardThermalCycle(),
    constantPressure(),
    noParamsMethod(),
  ];
}

/// 试验创建请求测试数据
class ExperimentCreateTestData {
  static Map<String, dynamic> validRequest() => {
    'workbenchId': 'wb-001',
    'methodId': 'method-001',
    'parameters': {
      'targetTemperature': 85.0,
      'duration': 30,
      'cycleCount': 10,
    },
  };

  static Map<String, dynamic> modifiedParamsRequest() => {
    'workbenchId': 'wb-001',
    'methodId': 'method-001',
    'parameters': {
      'targetTemperature': 100.0,
      'duration': 60,
      'cycleCount': 5,
    },
  };
}
```

---

## 附录 B：Widget 测试基础设施

```dart
/// 试验创建页面测试基类
class ExperimentCreatePageTestBase {
  late MockWorkbenchService mockWorkbenchService;
  late MockMethodService mockMethodService;
  late MockExperimentService mockExperimentService;
  late ProviderContainer container;

  setUp(() {
    mockWorkbenchService = MockWorkbenchService();
    mockMethodService = MockMethodService();
    mockExperimentService = MockExperimentService();
    container = ProviderContainer(
      overrides: [
        workbenchServiceProvider.overrideWithValue(mockWorkbenchService),
        methodServiceProvider.overrideWithValue(mockMethodService),
        experimentServiceProvider.overrideWithValue(mockExperimentService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  /// 构建测试中的页面
  Widget buildTestWidget({Locale locale = const Locale('zh')}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/experiments/new',
          routes: [
            GoRoute(
              path: '/experiments/new',
              builder: (context, state) => const ExperimentCreatePage(),
            ),
            GoRoute(
              path: '/experiments',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/experiments/:id',
              builder: (context, state) => SizedBox(
                key: ValueKey('experiment-${state.pathParameters['id']}'),
              ),
            ),
            GoRoute(
              path: '/workbenches',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/methods',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
      ),
    );
  }

  /// 模拟工作台列表加载
  void mockWorkbenchList(List<Workbench> workbenches) {
    when(() => mockWorkbenchService.list()).thenAnswer(
      (_) async => workbenches,
    );
  }

  /// 模拟工作台列表错误
  void mockWorkbenchListError(Object error) {
    when(() => mockWorkbenchService.list()).thenThrow(error);
  }

  /// 模拟方法列表加载
  void mockMethodList(List<Method> methods) {
    when(() => mockMethodService.list()).thenAnswer(
      (_) async => methods,
    );
  }

  /// 模拟方法列表错误
  void mockMethodListError(Object error) {
    when(() => mockMethodService.list()).thenThrow(error);
  }

  /// 模拟试验创建成功
  void mockCreateSuccess(Experiment experiment) {
    when(() => mockExperimentService.create(any())).thenAnswer(
      (_) async => experiment,
    );
  }

  /// 模拟试验创建失败
  void mockCreateError(Object error) {
    when(() => mockExperimentService.create(any())).thenThrow(error);
  }
}
```

---

## 附录 C：截图检查清单

| # | 截图场景 | 分辨率 | 主题 | 语言 |
|---|----------|--------|------|------|
| 1 | 步骤 1 — 加载中（骨架屏） | 1920x1080 | 浅色 | 中文 |
| 2 | 步骤 1 — 有工作台数据 | 1920x1080 | 浅色 | 中文 |
| 3 | 步骤 1 — 空状态 | 1920x1080 | 浅色 | 中文 |
| 4 | 步骤 1 — 错误状态 | 1920x1080 | 浅色 | 中文 |
| 5 | 步骤 1 — 已选择工作台 | 1920x1080 | 浅色 | 中文 |
| 6 | 步骤 2 — 加载中 | 1920x1080 | 浅色 | 中文 |
| 7 | 步骤 2 — 有方法数据 | 1920x1080 | 浅色 | 中文 |
| 8 | 步骤 2 — 空状态 | 1920x1080 | 浅色 | 中文 |
| 9 | 步骤 2 — 已选择方法 | 1920x1080 | 浅色 | 中文 |
| 10 | 步骤 3 — 参数表单 | 1920x1080 | 浅色 | 中文 |
| 11 | 步骤 3 — 参数验证错误 | 1920x1080 | 浅色 | 中文 |
| 12 | 步骤 3 — 无参数方法 | 1920x1080 | 浅色 | 中文 |
| 13 | 步骤 4 — 创建按钮禁用 | 1920x1080 | 浅色 | 中文 |
| 14 | 步骤 4 — 创建按钮启用 | 1920x1080 | 浅色 | 中文 |
| 15 | 创建成功 Toast | 1920x1080 | 浅色 | 中文 |
| 16 | 移动端 — 步骤 1 | 375x667 | 浅色 | 中文 |
| 17 | 移动端 — 步骤 2 | 375x667 | 浅色 | 中文 |
| 18 | 移动端 — 步骤 3 | 375x667 | 浅色 | 中文 |
| 19 | 深色主题 — 步骤 1 | 1920x1080 | 深色 | 中文 |
| 20 | 深色主题 — 步骤 3 | 1920x1080 | 深色 | 中文 |
| 21 | 英文界面 — 步骤 1 | 1920x1080 | 浅色 | 英文 |
| 22 | 英文界面 — 步骤 3 | 1920x1080 | 浅色 | 英文 |

---

## 附录 D：参数类型测试矩阵

| 参数类型 | 输入控件 | 验证规则 | 测试用例 |
|----------|----------|----------|----------|
| `number` (double) | `TextFormField` (number) | min/max, 数值格式 | TC-022-28, TC-022-29 |
| `integer` (int) | `TextFormField` (number) | min/max, 整数格式 | TC-022-28, TC-022-29 |
| `string` | `TextFormField` (text) | 长度限制（如有） | TC-022-31 |
| `boolean` | `Switch` / `Checkbox` | 无 | TC-022-26 |
| `enum` | `DropdownButtonFormField` | 选项必须在列表中 | TC-022-26 |

---

## 修订记录

| 日期 | 版本 | 修订人 | 修订说明 |
|------|------|--------|----------|
| 2026-06-02 | v1.0 | sw-mike | 初始版本，55 项测试用例，覆盖 4 步创建向导的全部流程：步骤导航、工作台选择、方法选择、参数配置、创建提交、响应式布局、国际化、错误处理 |

---

**状态**: 待评审  
**下一步**: 提交给 sw-tom 进行技术评审

---

修订状态: ✅ 完成，请 sw-tom 重新评审

## 终审结论
**评审人**: sw-tom
**日期**: 2026-06-02

**结论**: ✅ APPROVED

**评审摘要**：
- 测试覆盖全面（55 项 P0/P1 用例），覆盖完整创建流程的 9 个维度
- 4 项阻塞问题均已修复：测试覆盖范围（✅）、数据工厂（✅）、基础设施（✅）、错误处理（✅）
- 附录 A~C 提供了可复用的测试基础设施和数据工厂，与现有代码库模式一致（`UncontrolledProviderScope` + `MockTail` + `go_router`）
- 附带说明：方法 4 个测试数据工厂中引用的模型字段（如 `deviceCount`、`WorkbenchStatus`、`MethodParameter` 的增强属性）将在实现 TASK-022 时同步更新。——这些是 TDD 规范接口，非测试用例缺陷。
