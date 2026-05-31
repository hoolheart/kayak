# TASK-007 测试用例 — 可复用组件库

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待 sw-tom 审查
> **关联任务**: TASK-007（可复用组件库）
> **参考文档**: [tasks.md](../tasks.md), [reusable_components_spec.md](../ui/specifications/reusable_components_spec.md)

---

## 测试范围

TASK-007 需交付以下 6 个可复用组件：

| # | 组件 | 文件路径 | 功能 |
|---|------|---------|------|
| 1 | ErrorView | `lib/widgets/error_view.dart` | 错误图标 + 描述 + 重试按钮 |
| 2 | EmptyView | `lib/widgets/empty_view.dart` | 空状态图标 + 提示 + 可选操作按钮 |
| 3 | Skeleton | `lib/widgets/skeleton.dart` | 骨架屏占位形状（列表/卡片） |
| 4 | ConfirmDialog | `lib/widgets/confirm_dialog.dart` | 确认对话框（取消/确认按钮） |
| 5 | Toast | `lib/widgets/toast.dart` | 操作反馈（成功/失败/加载） |
| 6 | AsyncValueWidget | `lib/widgets/async_value_widget.dart` | 统一三态分发组件 |

---

## 测试用例汇总表

| ID | 组件 | 描述 | 截图 | 优先级 |
|----|------|------|:---:|:------:|
| TC-001 | ErrorView | 显示错误消息和重试按钮 | ✅ | P0 |
| TC-002 | ErrorView | 点击重试按钮触发 onRetry 回调 | — | P0 |
| TC-003 | ErrorView | 重试按钮进入加载状态（loading 反馈） | ✅ | P1 |
| TC-004 | ErrorView | showRetry=false 时隐藏重试按钮 | ✅ | P1 |
| TC-005 | ErrorView | 紧凑型（compact）变体渲染 | ✅ | P2 |
| TC-006 | ErrorView | 无描述文本时仅显示标题和图标 | — | P2 |
| TC-007 | EmptyView | 显示空状态图标 + 标题 + 描述 + 操作按钮 | ✅ | P0 |
| TC-008 | EmptyView | actionButton=null 时隐藏操作按钮 | ✅ | P1 |
| TC-009 | EmptyView | 点击操作按钮触发 onAction 回调 | — | P0 |
| TC-010 | EmptyView | 自定义图标（非默认 folder_open）渲染 | ✅ | P2 |
| TC-011 | EmptyView | 紧凑型（compact）变体渲染 | ✅ | P2 |
| TC-012 | Skeleton | ListSkeleton 渲染多个列表项骨架 | ✅ | P0 |
| TC-013 | Skeleton | CardSkeleton 渲染卡片骨架 | ✅ | P0 |
| TC-014 | Skeleton | TextSkeleton 渲染 1-3 行文本占位 | ✅ | P1 |
| TC-015 | Skeleton | Skeleton shimmer 动画流畅运行 | — | P1 |
| TC-016 | Skeleton | 不同断点下列表骨架项数适配 | ✅ | P2 |
| TC-017 | ConfirmDialog | 显示标题 + 描述 + 取消/确认按钮 | ✅ | P0 |
| TC-018 | ConfirmDialog | 点击取消按钮触发 onCancel 并关闭 | — | P0 |
| TC-019 | ConfirmDialog | 点击确认按钮触发 onConfirm 并关闭 | — | P0 |
| TC-020 | ConfirmDialog | 危险操作（isDanger=true）确认按钮为红色 | ✅ | P1 |
| TC-021 | ConfirmDialog | 移动端（< 600px）底部 Sheet 样式 | ✅ | P2 |
| TC-022 | ConfirmDialog | 键盘 Esc 触发取消，Enter 触发确认 | — | P2 |
| TC-023 | Toast | Success 类型：绿色背景 + 对勾图标 + 3秒自消 | ✅ | P0 |
| TC-024 | Toast | Error 类型：红色背景 + 错误图标 + 5秒自消 | ✅ | P0 |
| TC-025 | Toast | Warning 类型：橙色背景 + 警告图标 + 4秒自消 | ✅ | P1 |
| TC-026 | Toast | Info 类型：蓝色背景 + 信息图标 + 3秒自消 | ✅ | P1 |
| TC-027 | Toast | Loading 类型：旋转图标 + 不自动消失 | ✅ | P1 |
| TC-028 | Toast | 多个 Toast 堆叠（最多 3 个，新的顶替最早的）| ✅ | P2 |
| TC-029 | AsyncValueWidget | Loading 状态 → 渲染 Skeleton | ✅ | P0 |
| TC-030 | AsyncValueWidget | Data 状态 → 渲染 dataBuilder 内容 | ✅ | P0 |
| TC-031 | AsyncValueWidget | Error 状态 → 渲染 ErrorView + onRetry | ✅ | P0 |
| TC-032 | AsyncValueWidget | Empty 状态 → 渲染 EmptyView | ✅ | P1 |
| TC-033 | AsyncValueWidget | skipLoadingOnRefresh=true 时刷新保留旧数据 | — | P1 |
| TC-034 | AsyncValueWidget | 自定义 loadingBuilder / errorBuilder / emptyBuilder | ✅ | P2 |

---

## 一、ErrorView 测试用例（6 项）

---

### TC-001: 显示错误消息和重试按钮

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 正常渲染 |
| **截图** | ✅ ErrorView 默认状态（带重试按钮） |

**前置条件**：
- `ErrorView` 组件已实现
- 组件接收 `title`、`description`、`onRetry` 参数

**测试步骤**：

1. 使用测试数据渲染 `ErrorView`：
   - `title`: `"无法加载数据"`
   - `description`: `"网络连接异常，请检查网络后点击重试"`
   - `onRetry`: 提供的回调函数
2. 验证以下元素渲染：
   - 错误图标（`Icons.error_outline_outlined`，48×48px）
   - 标题文本（`titleMedium` 样式）
   - 描述文本（`bodyMedium` 样式，颜色 `onSurfaceVariant`）
   - "重试"按钮（Filled Button，最小宽度 120px）
3. 验证布局垂直居中，间距正确（图标→标题 24px，标题→描述 8px，描述→按钮 24px）
4. **截图**: ErrorView 默认状态

**预期结果**：
- ✅ 四个元素全部渲染
- ✅ 文本内容正确
- ✅ 文字通过 l10n 获取（非硬编码）
- ✅ 按钮可点击状态

**失败判定**：
- ❌ 任一无素缺失
- ❌ 文本硬编码（未使用 l10n）
- ❌ 图标尺寸/颜色与设计规范不一致

---

### TC-002: 点击重试按钮触发 onRetry 回调

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 交互测试 |
| **截图** | — |

**前置条件**：
- TC-001 通过

**测试步骤**：

1. 创建一个回调追踪器（如 `bool retryCalled = false`）
2. 渲染 `ErrorView`，`onRetry: () => retryCalled = true`
3. 查找"重试"按钮并点击
4. 验证 `retryCalled` 变为 `true`

```dart
testWidgets('TC-002: onRetry callback triggered on retry button tap', (tester) async {
  bool retryCalled = false;

  await tester.pumpWidget(wrapWithMaterial(
    ErrorView(
      title: 'Test Error',
      onRetry: () => retryCalled = true,
    ),
  ));

  await tester.tap(find.text('重试'));
  expect(retryCalled, isTrue);
});
```

**预期结果**：
- ✅ 点击"重试"按钮后 `onRetry` 回调被执行
- ✅ 回调仅执行一次（非多次触发）

**失败判定**：
- ❌ 点击按钮后 `onRetry` 未被调用
- ❌ `onRetry` 回调抛出异常未处理

---

### TC-003: 重试按钮进入加载状态（loading 反馈）

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P1 — HIGH** |
| **类别** | 交互测试 / 状态变更 |
| **截图** | ✅ ErrorView 加载状态（按钮显示 loading 指示器） |

**前置条件**：
- TC-001, TC-002 通过
- `ErrorView` 支持 `isLoading` 参数（或内部管理 loading 状态）

**测试步骤**：

1. 渲染 `ErrorView` 并设置 `isLoading = true`
2. 验证"重试"按钮文字变为加载指示器（`CircularProgressIndicator` 20px）
3. 验证按钮处于禁用状态（不可点击）
4. 验证图标和描述文本仍然可见
5. **截图**: ErrorView 加载状态

**预期结果**：
- ✅ 按钮显示 loading 动画
- ✅ 按钮不可点击
- ✅ 错误信息仍可读

**失败判定**：
- ❌ loading 状态下按钮仍可点击
- ❌ loading 指示器尺寸不正确
- ❌ loading 状态下错误信息消失

---

### TC-004: showRetry=false 时隐藏重试按钮

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P1 — HIGH** |
| **类别** | 正常渲染 / 变体 |
| **截图** | ✅ ErrorView 无重试按钮变体 |

**前置条件**：
- `ErrorView` 支持 `showRetry` 参数（默认 `true`）

**测试步骤**：

1. 渲染 `ErrorView` 并设置 `showRetry = false`
2. 验证"重试"按钮不存在于 Widget 树中
3. 验证图标、标题、描述仍然正常渲染
4. 验证布局不坍塌（仍居中显示）
5. **截图**: ErrorView 无重试按钮状态

**预期结果**：
- ✅ 无按钮渲染
- ✅ 布局保持居中，无额外空白
- ✅ 其他元素不受影响

**失败判定**：
- ❌ `showRetry = false` 时按钮仍显示
- ❌ 隐藏按钮后布局错乱

---

### TC-005: 紧凑型（compact）变体渲染

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 响应式 / 变体 |
| **截图** | ✅ ErrorView 紧凑型变体 |

**前置条件**：
- `ErrorView` 支持 `compact` 参数

**测试步骤**：

1. 渲染 `ErrorView(compact: true)` 
2. 验证图标缩小为 32px
3. 验证最小高度 ≤ 160px
4. 验证间距缩小（内边距 24px）
5. 验证仍包含图标、标题
6. **截图**: ErrorView 紧凑型

**预期结果**：
- ✅ 图标为 32px（非桌面默认 48px）
- ✅ 整体布局更紧凑
- ✅ 适配小区域（如卡片内部）

**失败判定**：
- ❌ compact 模式下图标/间距与默认模式无差异
- ❌ 布局溢出或截断

---

### TC-006: 无描述文本时仅显示标题和图标

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 边界 / 变体 |
| **截图** | — |

**前置条件**：
- `ErrorView` 的 `description` 参数为可选

**测试步骤**：

1. 渲染 `ErrorView(title: 'Error', description: null, onRetry: () {})`
2. 验证标题正常渲染
3. 验证描述区域不存在或为空
4. 验证按钮仍可正常渲染
5. 验证无描述时布局不坍塌（标题到按钮间距合理）

**预期结果**：
- ✅ 无描述时标题和按钮正常渲染
- ✅ 无多余空白区域
- ✅ 整体布局保持居中

**失败判定**：
- ❌ `description = null` 时崩溃
- ❌ 描述区域留下了不合理的空白占位

---

## 二、EmptyView 测试用例（5 项）

---

### TC-007: 显示空状态图标 + 标题 + 描述 + 操作按钮

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 正常渲染 |
| **截图** | ✅ EmptyView 默认状态 |

**前置条件**：
- `EmptyView` 组件已实现

**测试步骤**：

1. 渲染 `EmptyView`：
   - `title`: `"暂无工作台"`
   - `description`: `"点击下方的按钮创建您的第一个工作台"`
   - `actionButton`: `ElevatedButton(onPressed: () {}, child: Text('创建工作台'))`
2. 验证渲染：
   - 默认图标（`Icons.folder_open_outlined`，48×48px，60% opacity）
   - 标题文本（`titleMedium`）
   - 描述文本（`bodyMedium`，`onSurfaceVariant`）
   - 操作按钮
3. 验证垂直居中布局，间距正确
4. **截图**: EmptyView 默认状态

**预期结果**：
- ✅ 四个元素全部渲染
- ✅ 文本通过 l10n 获取
- ✅ 图标透明度为 60%

**失败判定**：
- ❌ 任一无素缺失
- ❌ 文本硬编码
- ❌ 图标不透明（应为 60%）

---

### TC-008: actionButton=null 时隐藏操作按钮

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P1 — HIGH** |
| **类别** | 正常渲染 / 变体 |
| **截图** | ✅ EmptyView 无操作按钮变体 |

**前置条件**：
- `actionButton` 为可选参数（默认 `null`）

**测试步骤**：

1. 渲染 `EmptyView(title: '暂无通知', actionButton: null)`
2. 验证操作按钮不存在
3. 验证图标和标题仍然正确渲染
4. 验证布局不坍塌
5. **截图**: EmptyView 无操作按钮

**预期结果**：
- ✅ 无按钮渲染
- ✅ 布局居中且无额外空白

**失败判定**：
- ❌ `actionButton = null` 时崩溃
- ❌ 留下按钮占位空白

---

### TC-009: 点击操作按钮触发 onAction 回调

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 交互测试 |
| **截图** | — |

**前置条件**：
- TC-007 通过

**测试步骤**：

1. 创建回调追踪器
2. 渲染 `EmptyView` 并传入自定义 `actionButton`
3. 点击操作按钮
4. 验证回调被执行

```dart
testWidgets('TC-009: action button callback triggered', (tester) async {
  bool actionCalled = false;

  await tester.pumpWidget(wrapWithMaterial(
    EmptyView(
      title: 'No items',
      actionButton: ElevatedButton(
        onPressed: () => actionCalled = true,
        child: const Text('Create'),
      ),
    ),
  ));

  await tester.tap(find.text('Create'));
  expect(actionCalled, isTrue);
});
```

**预期结果**：
- ✅ 点击操作按钮后回调执行

**失败判定**：
- ❌ 按钮不可点击
- ❌ 回调未触发

---

### TC-010: 自定义图标渲染

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 正常渲染 / 变体 |
| **截图** | ✅ EmptyView 自定义图标 |

**前置条件**：
- `EmptyView` 的 `icon` 参数为可选

**测试步骤**：

1. 渲染 `EmptyView(icon: Icons.inbox_outlined, title: 'No messages')`
2. 验证渲染的图标是 `Icons.inbox_outlined`（非默认 `folder_open_outlined`）
3. 验证图标尺寸仍为 48px
4. **截图**: EmptyView 自定义图标 `inbox_outlined`

**预期结果**：
- ✅ 自定义图标正确渲染
- ✅ 默认图标被替换

**失败判定**：
- ❌ 自定义图标未生效（仍显示默认图标）
- ❌ 自定义图标尺寸异常

---

### TC-011: 紧凑型（compact）变体渲染

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 响应式 / 变体 |
| **截图** | ✅ EmptyView 紧凑型变体 |

**前置条件**：
- `EmptyView` 支持 `compact` 参数

**测试步骤**：

1. 渲染 `EmptyView(compact: true, title: 'No data')`
2. 验证图标缩小为 40px
3. 验证最小高度 ≤ 160px
4. 验证间距缩小
5. **截图**: EmptyView 紧凑型

**预期结果**：
- ✅ 图标为 40px
- ✅ 整体布局更紧凑

**失败判定**：
- ❌ compact 模式下图标/间距无变化
- ❌ 布局溢出

---

## 三、Skeleton 测试用例（5 项）

---

### TC-012: ListSkeleton 渲染多个列表项骨架

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 正常渲染 |
| **截图** | ✅ SkeletonList 默认渲染（3-5 项占位） |

**前置条件**：
- `SkeletonList` 组件已实现

**测试步骤**：

1. 渲染 `SkeletonList(itemCount: 4)`
2. 验证渲染 4 个列表项骨架
3. 每项包含：
   - 圆形头像占位（40×40px）
   - 标题行占位（16px 高，40-60% 宽）
   - 描述行占位（14px 高，70-100% 宽，1-2 行）
4. 验证 shimmer 动画运行
5. 验证背景色为 `SurfaceVariant` at 50%
6. **截图**: SkeletonList 4 项

**预期结果**：
- ✅ 渲染指定数量的列表项
- ✅ 每个项包含头像 + 标题行 + 描述行
- ✅ shimmer 动画流动

**失败判定**：
- ❌ 列表项数量不匹配
- ❌ 骨架形状不正确
- ❌ 无 shimmer 动画

---

### TC-013: CardSkeleton 渲染卡片骨架

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 正常渲染 |
| **截图** | ✅ SkeletonCard 默认渲染 |

**前置条件**：
- `SkeletonCard` 组件已实现

**测试步骤**：

1. 渲染 `SkeletonCard()`
2. 验证卡片结构：
   - 图片占位区域（16:9 比例，圆角 8px）
   - 标题占位行（16px 高，60% 宽）
   - 描述占位行（14px 高，2 行，宽度不同）
   - 底部信息占位
3. 验证 shimmer 动画
4. **截图**: SkeletonCard

**预期结果**：
- ✅ 卡片结构符合设计规范
- ✅ 图片区域为 16:9 比例
- ✅ shimmer 动画流畅

**失败判定**：
- ❌ 卡片结构缺失
- ❌ 图片区域比例非 16:9
- ❌ 无动画

---

### TC-014: TextSkeleton 渲染 1-3 行文本占位

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P1 — HIGH** |
| **类别** | 正常渲染 / 变体 |
| **截图** | ✅ TextSkeleton 3 行文本占位 |

**前置条件**：
- `TextSkeleton` 组件已实现

**测试步骤**：

1. 渲染 `TextSkeleton(lines: 3)`
2. 验证渲染 3 行文本骨架
3. 每行高度 14px，最后一行宽度为 70%
4. 行间距 `spaceSm`（8px）
5. 渲染 `TextSkeleton(lines: 1)` → 验证为 1 行
6. **截图**: TextSkeleton 3 行

**预期结果**：
- ✅ 行数匹配参数值
- ✅ 最后一行宽度为 70%
- ✅ 行间距正确

**失败判定**：
- ❌ 行数不匹配
- ❌ 所有行宽度相同（应为递减）

---

### TC-015: Skeleton shimmer 动画流畅运行

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P1 — HIGH** |
| **类别** | 交互 / 动画 |
| **截图** | — |

**前置条件**：
- Skeleton 组件包含 shimmer 动画

**测试步骤**：

1. 渲染 `SkeletonList(itemCount: 3)`
2. `pump()` 一帧，记录初始颜色/位置
3. `pump(Duration(milliseconds: 375))` — 动画 1/4
4. 验证颜色/位置发生变化（shimmer 在移动）
5. `pump(Duration(milliseconds: 750))` — 动画 1/2
6. 验证 shimmer 进度前进
7. 验证动画循环（1.5s 周期）

**预期结果**：
- ✅ 每帧 shimmer 位置变化
- ✅ 动画周期 1.5s
- ✅ 动画是线性的（linear）

**失败判定**：
- ❌ 多次 pump 后无视觉变化（动画未运行）
- ❌ 动画周期异常

---

### TC-016: 不同断点下列表骨架项数适配

| 属性 | 内容 |
|------|------|
| **ID** | TC-016 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 响应式 |
| **截图** | ✅ SkeletonList Mobile (3 项) / Desktop (5 项) |

**前置条件**：
- `SkeletonList` 根据屏幕宽度调整默认项数

**测试步骤**：

1. 设置屏幕宽度为 400px（Mobile）
   - 渲染 `SkeletonList()`，验证默认项数为 3
2. 设置屏幕宽度为 800px（Tablet）
   - 渲染 `SkeletonList()`，验证默认项数为 4
3. 设置屏幕宽度为 1200px（Desktop）
   - 渲染 `SkeletonList()`，验证默认项数为 5
4. **截图**: Mobile (3 项) 和 Desktop (5 项)

**预期结果**：
- ✅ Mobile (< 600px) → 3 项
- ✅ Tablet (600-1024px) → 4 项
- ✅ Desktop (> 1024px) → 5 项

**失败判定**：
- ❌ 所有断点下项数相同
- ❌ 项数不随宽度变化

---

## 四、ConfirmDialog 测试用例（6 项）

---

### TC-017: 显示标题 + 描述 + 取消/确认按钮

| 属性 | 内容 |
|------|------|
| **ID** | TC-017 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 正常渲染 |
| **截图** | ✅ ConfirmDialog 桌面端默认状态 |

**前置条件**：
- `ConfirmDialog` 组件已实现

**测试步骤**：

1. 触发显示确认对话框：
   - `title`: `"删除工作台？"`
   - `description`: `"此操作将永久删除'材料测试'工作台及其所有数据。该操作不可撤销。"`
   - `confirmLabel`: `"删除"`
   - `cancelLabel`: `"取消"`
2. 验证对话框内容：
   - 标题（`titleMedium`）
   - 描述文本（`bodyMedium`，`onSurfaceVariant`）
   - "取消"按钮（Text Button，Primary 色）
   - "删除"按钮（Filled Button）
3. 验证遮罩层存在（半透明背景）
4. 验证对话框居中，圆角 `radiusLarge`（12px）
5. **截图**: ConfirmDialog 桌面端

**预期结果**：
- ✅ 对话框内容完整
- ✅ 两个按钮都可见且可点击
- ✅ 遮罩层覆盖整个屏幕
- ✅ 文本通过 l10n 获取

**失败判定**：
- ❌ 按钮缺失
- ❌ 遮罩层缺失（用户可以操作背后内容）
- ❌ 文本硬编码

---

### TC-018: 点击取消按钮触发 onCancel 并关闭

| 属性 | 内容 |
|------|------|
| **ID** | TC-018 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 交互测试 |
| **截图** | — |

**前置条件**：
- TC-017 通过

**测试步骤**：

1. 创建回调追踪：`bool cancelled = false`
2. 渲染对话框，`onCancel: () => cancelled = true`
3. 查找"取消"按钮并点击
4. 验证 `cancelled` 变为 `true`
5. 验证对话框从 Widget 树中移除（`pumpAndSettle()` 后）

```dart
testWidgets('TC-018: cancel button triggers onCancel and closes dialog', (tester) async {
  bool cancelled = false;
  bool dialogClosed = false;

  await tester.pumpWidget(wrapWithMaterial(
    Builder(builder: (context) => ElevatedButton(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => ConfirmDialog(
          title: 'Delete?',
          description: 'This action is irreversible.',
          onConfirm: () {},
          onCancel: () {
            cancelled = true;
            dialogClosed = true;
          },
        ),
      ),
      child: const Text('Open'),
    )),
  ));

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('取消'));
  await tester.pumpAndSettle();

  expect(cancelled, isTrue);
  expect(find.text('Delete?'), findsNothing);
});
```

**预期结果**：
- ✅ `onCancel` 回调执行
- ✅ 对话框关闭

**失败判定**：
- ❌ 点击取消后回调未执行
- ❌ 对话框未关闭

---

### TC-019: 点击确认按钮触发 onConfirm 并关闭

| 属性 | 内容 |
|------|------|
| **ID** | TC-019 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 交互测试 |
| **截图** | — |

**前置条件**：
- TC-017 通过

**测试步骤**：

1. 创建回调追踪：`bool confirmed = false`
2. 渲染对话框，`onConfirm: () => confirmed = true`
3. 查找确认按钮并点击
4. 验证 `confirmed` 变为 `true`
5. 验证对话框关闭

**预期结果**：
- ✅ `onConfirm` 回调执行
- ✅ 对话框关闭

**失败判定**：
- ❌ 点击确认后回调未执行
- ❌ 确认后对话框未关闭

---

### TC-020: 危险操作（isDanger=true）确认按钮为红色

| 属性 | 内容 |
|------|------|
| **ID** | TC-020 |
| **优先级** | **P1 — HIGH** |
| **类别** | 正常渲染 / 变体 |
| **截图** | ✅ ConfirmDialog 危险操作变体（红色确认按钮） |

**前置条件**：
- `ConfirmDialog` 支持 `isDanger` 参数

**测试步骤**：

1. 渲染 `ConfirmDialog(isDanger: true, title: 'Delete', ...)`
2. 验证确认按钮使用 Error 色（`#BA1A1A` 或 ColorScheme 的 error 色）
3. 验证取消按钮仍为普通样式
4. 可能显示警告图标（`Icons.warning_amber`）
5. **截图**: ConfirmDialog 危险操作（红色按钮）

**预期结果**：
- ✅ 确认按钮背景为红色/Error 色
- ✅ 取消按钮不受影响
- ✅ 视觉上明显区分危险操作

**失败判定**：
- ❌ `isDanger=true` 时确认按钮颜色不变
- ❌ 取消按钮也变成了红色

---

### TC-021: 移动端（< 600px）底部 Sheet 样式

| 属性 | 内容 |
|------|------|
| **ID** | TC-021 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 响应式 |
| **截图** | ✅ ConfirmDialog 移动端底部 Sheet |

**前置条件**：
- `ConfirmDialog` 响应式适配移动端

**测试步骤**：

1. 设置屏幕宽度为 400px（Mobile）
2. 渲染确认对话框
3. 验证对话框在屏幕底部（非居中）：`bottomSheet` 样式
4. 验证宽度为 100%
5. 验证底部圆角可能为 0（贴底）
6. 验证动画为底部滑入而非缩放淡入
7. **截图**: ConfirmDialog 移动端底部 Sheet

**预期结果**：
- ✅ 移动端对话框贴底显示
- ✅ 宽度为屏幕宽度
- ✅ 动画为底部滑入

**失败判定**：
- ❌ 移动端对话框仍居中显示（桌面端行为）
- ❌ 宽度未适配（仍然为固定 320-560px）
- ❌ 动画未切换

---

### TC-022: 键盘 Esc 触发取消，Enter 触发确认

| 属性 | 内容 |
|------|------|
| **ID** | TC-022 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 交互 / 无障碍 |
| **截图** | — |

**前置条件**：
- `ConfirmDialog` 支持键盘导航

**测试步骤**：

**场景 A: Esc 取消**：
1. 渲染确认对话框
2. 模拟按下 Escape 键
3. 验证 `onCancel` 被调用（或对话框关闭）
4. 验证 `onConfirm` **未**被调用

**场景 B: Enter 确认**（如果确认按钮聚焦）：
1. 渲染确认对话框
2. 确认按钮获得焦点
3. 模拟按下 Enter 键
4. 验证 `onConfirm` 被调用

**预期结果**：
- ✅ Esc → 取消/关闭
- ✅ Enter（确认聚焦时）→ 确认
- ✅ Tab 键在按钮间循环

**失败判定**：
- ❌ Esc 无响应
- ❌ Enter 触发了取消而非确认

---

## 五、Toast 测试用例（6 项）

---

### TC-023: Success 类型：绿色背景 + 对勾图标 + 3秒自消

| 属性 | 内容 |
|------|------|
| **ID** | TC-023 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 正常渲染 |
| **截图** | ✅ Toast Success 类型 |

**前置条件**：
- `showSuccess(message)` 或 `Toast` 组件已实现

**测试步骤**：

1. 调用 `showSuccess('工作台创建成功')`
2. 验证 Toast 渲染：
   - 背景色：Success at 12% + Success 边框
   - 图标：`Icons.check_circle`，20px，Success 色
   - 文字："工作台创建成功"，`bodyMedium`
3. 验证 Toast 位置：右上角（桌面）/ 底部居中（移动）
4. 等待 3 秒后验证 Toast 自动消失
5. **截图**: Toast Success

```dart
testWidgets('TC-023: Toast Success auto-dismisses after 3 seconds', (tester) async {
  await tester.pumpWidget(wrapWithMaterial(
    Scaffold(body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showSuccess(context, 'Success message'),
        child: const Text('Show'),
      ),
    )),
  ));

  await tester.tap(find.text('Show'));
  await tester.pump(); // Toast appears
  expect(find.text('Success message'), findsOneWidget);

  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  expect(find.text('Success message'), findsNothing);
});
```

**预期结果**：
- ✅ Toast 显示 3 秒后自动消失
- ✅ 绿色背景 + 对勾图标
- ✅ 位置正确

**失败判定**：
- ❌ Toast 不自动消失
- ❌ 图标/颜色不正确
- ❌ 消失时间偏差过大

---

### TC-024: Error 类型：红色背景 + 错误图标 + 5秒自消

| 属性 | 内容 |
|------|------|
| **ID** | TC-024 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 正常渲染 / 类型 |
| **截图** | ✅ Toast Error 类型 |

**前置条件**：
- `showError(message)` 已实现

**测试步骤**：

1. 调用 `showError('删除失败，请稍后重试')`
2. 验证：
   - 背景色：Error Container
   - 图标：`Icons.error_outline`，20px，On Error Container 色
   - 文字：红色
3. 等待 5 秒后验证消失
4. **截图**: Toast Error

**预期结果**：
- ✅ 红色背景
- ✅ 5 秒后消失（比 Success 长，给用户更多时间阅读错误）

**失败判定**：
- ❌ 颜色为绿色（错误使用了 Success 样式）
- ❌ 消失时间不是 5 秒

---

### TC-025: Warning 类型：橙色背景 + 警告图标 + 4秒自消

| 属性 | 内容 |
|------|------|
| **ID** | TC-025 |
| **优先级** | **P1 — HIGH** |
| **类别** | 正常渲染 / 类型 |
| **截图** | ✅ Toast Warning 类型 |

**前置条件**：
- `showWarning(message)` 或等效 API 已实现

**测试步骤**：

1. 显示 Warning Toast
2. 验证橙色背景（Warning at 12% + 边框）
3. 验证图标 `Icons.warning_amber`，橙色
4. 等待 4 秒后消失
5. **截图**: Toast Warning

**预期结果**：
- ✅ 橙色主题
- ✅ 4 秒消失

**失败判定**：
- ❌ 颜色错误
- ❌ 图标错误

---

### TC-026: Info 类型：蓝色背景 + 信息图标 + 3秒自消

| 属性 | 内容 |
|------|------|
| **ID** | TC-026 |
| **优先级** | **P1 — HIGH** |
| **类别** | 正常渲染 / 类型 |
| **截图** | ✅ Toast Info 类型 |

**前置条件**：
- `showInfo(message)` 或等效 API 已实现

**测试步骤**：

1. 显示 Info Toast
2. 验证蓝色背景（Primary at 12% + 边框）
3. 验证图标 `Icons.info_outline`，Primary 色
4. 等待 3 秒后消失
5. **截图**: Toast Info

**预期结果**：
- ✅ 蓝色主题
- ✅ 3 秒消失

**失败判定**：
- ❌ 颜色错误
- ❌ 图标错误

---

### TC-027: Loading 类型：旋转图标 + 不自动消失

| 属性 | 内容 |
|------|------|
| **ID** | TC-027 |
| **优先级** | **P1 — HIGH** |
| **类别** | 正常渲染 / 类型 |
| **截图** | ✅ Toast Loading 类型（旋转图标） |

**前置条件**：
- `showLoading(message)` 或等效 API 已实现

**测试步骤**：

1. 显示 Loading Toast：`showLoading('正在保存...')`
2. 验证：
   - 背景色：Surface Variant
   - 图标：`Icons.sync`，20px，**旋转动画**
   - 文字："正在保存..."
3. 等待 6 秒后验证 Toast **仍然存在**（不自动消失）
4. 手动关闭后验证 Toast 消失
5. **截图**: Toast Loading

**预期结果**：
- ✅ 旋转图标动画
- ✅ 不自动消失（需手动关闭）
- ✅ 背景为 Surface Variant（非彩色）

**失败判定**：
- ❌ Loading Toast 自动消失
- ❌ 图标不旋转
- ❌ 颜色使用了彩色背景

---

### TC-028: 多个 Toast 堆叠（最多 3 个，新的顶替最早的）

| 属性 | 内容 |
|------|------|
| **ID** | TC-028 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 交互 / 堆叠 |
| **截图** | ✅ 3 个 Toast 堆叠显示 |

**前置条件**：
- Toast 支持堆叠

**测试步骤**：

1. 连续触发 4 个 Toast（如 Success → Info → Warning → Error）
2. 验证同时最多显示 3 个
3. 验证第 4 个替代最早的（第 1 个消失）
4. 验证堆叠间距为 8px
5. 验证 Toast 顺序正确（最新的在最前面/最上面）
6. **截图**: 3 个 Toast 堆叠

**预期结果**：
- ✅ 最多 3 个同时显示
- ✅ 第 4 个顶替第 1 个
- ✅ 间距正确

**失败判定**：
- ❌ 允许超过 3 个同时显示
- ❌ 堆叠顺序错乱
- ❌ 间距不正确导致重叠

---

## 六、AsyncValueWidget 测试用例（6 项）

---

### TC-029: Loading 状态 → 渲染 Skeleton

| 属性 | 内容 |
|------|------|
| **ID** | TC-029 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 状态分发 / Loading |
| **截图** | ✅ AsyncValueWidget Loading 状态 |

**前置条件**：
- `AsyncValueWidget<T>` 已实现
- `AsyncValue<T>.loading()` 触发 loadingBuilder

**测试步骤**：

1. 传入 `AsyncValue<int>.loading()` 的 `AsyncValueWidget`
2. 验证渲染 Skeleton（默认 loadingBuilder）
3. 验证 dataBuilder 的 Widget **未**渲染
4. 验证 errorBuilder / emptyBuilder 的 Widget **未**渲染
5. **截图**: AsyncValueWidget Loading

```dart
testWidgets('TC-029: AsyncValueWidget renders Skeleton on loading', (tester) async {
  await tester.pumpWidget(wrapWithMaterial(
    AsyncValueWidget<int>(
      value: const AsyncValue.loading(),
      dataBuilder: (data) => Text('Data: $data'),
    ),
  ));
  await tester.pump();

  // 不应渲染 dataBuilder
  expect(find.text('Data:'), findsNothing);
  // 应渲染 Skeleton（默认 loadingBuilder）
  // 验证骨架屏占位存在
});
```

**预期结果**：
- ✅ 显示 Skeleton
- ✅ 不显示 dataBuilder 内容
- ✅ 不显示 errorBuilder / emptyBuilder

**失败判定**：
- ❌ Loading 状态下渲染了 dataBuilder
- ❌ 渲染了 errorBuilder（交叉状态）
- ❌ 无任何渲染（空白）

---

### TC-030: Data 状态 → 渲染 dataBuilder 内容

| 属性 | 内容 |
|------|------|
| **ID** | TC-030 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 状态分发 / Data |
| **截图** | ✅ AsyncValueWidget Data 状态 |

**前置条件**：
- TC-029 通过

**测试步骤**：

1. 传入 `AsyncValue.data(42)` 的 `AsyncValueWidget`
2. 验证渲染 dataBuilder 生成的 Widget
3. 验证数据值正确传递（如显示 "Data: 42"）
4. 验证 Skeleton **未**渲染
5. **截图**: AsyncValueWidget Data

**预期结果**：
- ✅ 显示 dataBuilder 内容
- ✅ 不显示 Skeleton / ErrorView / EmptyView

**失败判定**：
- ❌ Data 状态下渲染了 Skeleton
- ❌ 数据未正确传递给 dataBuilder

---

### TC-031: Error 状态 → 渲染 ErrorView + onRetry

| 属性 | 内容 |
|------|------|
| **ID** | TC-031 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 状态分发 / Error |
| **截图** | ✅ AsyncValueWidget Error 状态 |

**前置条件**：
- TC-029 通过

**测试步骤**：

1. 传入 `AsyncValue.error(Exception('Network failed'), StackTrace.current)` 的 `AsyncValueWidget`
2. 传入 `onRetry` 回调
3. 验证渲染 ErrorView（默认 errorBuilder）
4. 验证 ErrorView 显示错误信息
5. 点击"重试"按钮 → 验证 `onRetry` 被调用
6. **截图**: AsyncValueWidget Error

**预期结果**：
- ✅ 显示 ErrorView
- ✅ 错误信息传递给 ErrorView
- ✅ "重试"按钮调用 `onRetry`

**失败判定**：
- ❌ Error 状态下不显示 ErrorView
- ❌ `onRetry` 未传递或未触发
- ❌ 错误信息未显示

---

### TC-032: Empty 状态 → 渲染 EmptyView

| 属性 | 内容 |
|------|------|
| **ID** | TC-032 |
| **优先级** | **P1 — HIGH** |
| **类别** | 状态分发 / Empty |
| **截图** | ✅ AsyncValueWidget Empty 状态 |

**前置条件**：
- `AsyncValueWidget` 支持空数据判断
- `emptyCondition` 参数或内置空检测

**测试步骤**：

1. 传入 `AsyncValue.data(<String>[])` 的空列表
2. 传入 `emptyCondition`：`(list) => list.isEmpty`
3. 验证渲染 EmptyView（默认 emptyBuilder）
4. 验证 EmptyView 显示空状态提示
5. **截图**: AsyncValueWidget Empty

**预期结果**：
- ✅ 空数据时显示 EmptyView
- ✅ 不显示 dataBuilder 内容
- ✅ emptyCondition 被正确评估

**失败判定**：
- ❌ 空数据时仍渲染 dataBuilder
- ❌ emptyCondition 未生效
- ❌ EmptyView 使用了错误的标题

---

### TC-033: skipLoadingOnRefresh=true 时刷新保留旧数据

| 属性 | 内容 |
|------|------|
| **ID** | TC-033 |
| **优先级** | **P1 — HIGH** |
| **类别** | 状态分发 / 刷新 |
| **截图** | — |

**前置条件**：
- `AsyncValueWidget` 支持 `skipLoadingOnRefresh` 参数

**测试步骤**：

1. 初始状态：`AsyncValue.data(oldData)` 已渲染
2. 切换到刷新状态：`AsyncValue.loading()` 但 `skipLoadingOnRefresh = true`
3. 验证旧的 `dataBuilder` 内容仍然显示（不替换为 Skeleton）
4. 验证顶部显示线性进度条（刷新指示器）
5. 验证 `skipLoadingOnRefresh = false` 时刷新区显示 Skeleton

**预期结果**：
- ✅ 保留旧数据时，dataBuilder 内容可见
- ✅ 顶部有进度条指示刷新中
- ✅ 不显示完整 Skeleton

**失败判定**：
- ❌ 刷新时旧数据消失（完全替换为 Skeleton）
- ❌ 无任何刷新指示器

---

### TC-034: 自定义 loadingBuilder / errorBuilder / emptyBuilder

| 属性 | 内容 |
|------|------|
| **ID** | TC-034 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 状态分发 / 自定义 |
| **截图** | ✅ 自定义 loadingBuilder（DashboardSkeleton） |

**前置条件**：
- TC-029 ~ TC-032 通过

**测试步骤**：

1. **自定义 Loading**: 传入 `loadingBuilder: CircularProgressIndicator()`
   - 验证 Loading 状态下渲染转圈图标（非默认 Skeleton）
2. **自定义 Error**: 传入 `errorBuilder: (e, s) => Text('Custom: $e')`
   - 验证 Error 状态下渲染自定义错误文本
3. **自定义 Empty**: 传入 `emptyBuilder: Text('Nothing here')`
   - 验证 Empty 状态下渲染自定义文本
4. **截图**: 自定义 loadingBuilder 状态

**预期结果**：
- ✅ 自定义 builder 覆盖默认 builder
- ✅ 正确显示自定义 Widget
- ✅ 其他状态不受影响

**失败判定**：
- ❌ 自定义 builder 被忽略（仍使用默认）
- ❌ 自定义 builder 传入的参数类型不正确

---

## 测试执行记录模板

> **sw-mike 在测试执行阶段填写**

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | ErrorView 默认渲染 |
| TC-002 | | | ⬜ 待执行 | ErrorView onRetry 回调 |
| TC-003 | | | ⬜ 待执行 | ErrorView 加载状态 |
| TC-004 | | | ⬜ 待执行 | ErrorView 无重试按钮 |
| TC-005 | | | ⬜ 待执行 | ErrorView 紧凑型 |
| TC-006 | | | ⬜ 待执行 | ErrorView 无描述 |
| TC-007 | | | ⬜ 待执行 | EmptyView 默认渲染 |
| TC-008 | | | ⬜ 待执行 | EmptyView 无操作按钮 |
| TC-009 | | | ⬜ 待执行 | EmptyView onAction 回调 |
| TC-010 | | | ⬜ 待执行 | EmptyView 自定义图标 |
| TC-011 | | | ⬜ 待执行 | EmptyView 紧凑型 |
| TC-012 | | | ⬜ 待执行 | SkeletonList 渲染 |
| TC-013 | | | ⬜ 待执行 | SkeletonCard 渲染 |
| TC-014 | | | ⬜ 待执行 | TextSkeleton 渲染 |
| TC-015 | | | ⬜ 待执行 | Skeleton shimmer 动画 |
| TC-016 | | | ⬜ 待执行 | Skeleton 响应式适配 |
| TC-017 | | | ⬜ 待执行 | ConfirmDialog 默认渲染 |
| TC-018 | | | ⬜ 待执行 | ConfirmDialog 取消回调 |
| TC-019 | | | ⬜ 待执行 | ConfirmDialog 确认回调 |
| TC-020 | | | ⬜ 待执行 | ConfirmDialog 危险操作 |
| TC-021 | | | ⬜ 待执行 | ConfirmDialog 移动端 |
| TC-022 | | | ⬜ 待执行 | ConfirmDialog 键盘导航 |
| TC-023 | | | ⬜ 待执行 | Toast Success |
| TC-024 | | | ⬜ 待执行 | Toast Error |
| TC-025 | | | ⬜ 待执行 | Toast Warning |
| TC-026 | | | ⬜ 待执行 | Toast Info |
| TC-027 | | | ⬜ 待执行 | Toast Loading |
| TC-028 | | | ⬜ 待执行 | Toast 堆叠 |
| TC-029 | | | ⬜ 待执行 | AsyncValueWidget Loading |
| TC-030 | | | ⬜ 待执行 | AsyncValueWidget Data |
| TC-031 | | | ⬜ 待执行 | AsyncValueWidget Error |
| TC-032 | | | ⬜ 待执行 | AsyncValueWidget Empty |
| TC-033 | | | ⬜ 待执行 | AsyncValueWidget 刷新保留 |
| TC-034 | | | ⬜ 待执行 | AsyncValueWidget 自定义 |

---

## 测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| ErrorView | 6 | TC-001 ~ TC-006 |
| EmptyView | 5 | TC-007 ~ TC-011 |
| Skeleton | 5 | TC-012 ~ TC-016 |
| ConfirmDialog | 6 | TC-017 ~ TC-022 |
| Toast | 6 | TC-023 ~ TC-028 |
| AsyncValueWidget | 6 | TC-029 ~ TC-034 |
| **合计** | **34** | |

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 14 |
| P1 — HIGH | 13 |
| P2 — MEDIUM | 7 |

---

## 截图要求汇总

| 组件 | 截图数 | 截图内容 |
|------|:---:|------|
| **ErrorView** | 3 | 默认状态、Loading 状态、紧凑型 |
| **EmptyView** | 3 | 默认状态、无按钮、紧凑型 |
| **Skeleton** | 4 | ListSkeleton、CardSkeleton、TextSkeleton、响应式对比 |
| **ConfirmDialog** | 3 | 桌面端默认、危险操作、移动端 Sheet |
| **Toast** | 5 | Success / Error / Warning / Info / Loading |
| **AsyncValueWidget** | 4 | Loading / Data / Error / Empty |
| **合计** | **22** | |

---

## 验收标准可追溯性

| 验收标准（来自 tasks.md） | 对应测试用例 |
|--------------------------|------------|
| 所有组件在 loading/error/data/empty 状态下正确渲染 | TC-001, TC-007, TC-012, TC-029~TC-032 |
| 所有文本通过 l10n 获取（无硬编码） | TC-001, TC-007, TC-017 |
| 骨架屏与目标内容尺寸一致 | TC-012, TC-013, TC-014 |
| Widget 测试覆盖所有状态 | 全部 34 个 TC |
| 截图：每组件每种状态至少 1 张 | 22 张截图（见截图要求汇总） |
| ConfirmDialog 按钮回调 | TC-018, TC-019 |
| Skeleton 渲染尺寸正确 | TC-012~TC-014 |
| Toast 显示并自动消失 | TC-023~TC-027 |
| AsyncValueWidget 四态切换 | TC-029~TC-032 |

---

## 组件设计规范速查（测试参考）

### 颜色

| 语义 | Light | Dark | 用在哪里 |
|------|-------|------|---------|
| Error | `#BA1A1A` | `#FFB4AB` | Toast Error、ConfirmDialog danger |
| Error Container | `#FFDAD6` | `#93000A` | Toast Error 背景 |
| Success | `#2E7D32` | `#81C784` | Toast Success |
| Warning | `#ED6C02` | `#FFB74D` | Toast Warning |
| Primary | `#1976D2` | `#90CAF9` | Toast Info |
| On Surface Variant | `#43474E` | `#C4C6CF` | ErrorView/EmptyView 图标和描述 |
| Surface Variant | `#EFF3FA` | `#43474E` | Skeleton 背景、Toast Loading 背景 |

### 图标

| 图标 | 尺寸 | 组件 |
|------|------|------|
| `error_outline_outlined` | 48px / 40px (compact) | ErrorView |
| `folder_open_outlined` | 48px / 40px (compact) | EmptyView |
| `check_circle` | 20px | Toast Success |
| `error_outline` | 20px | Toast Error |
| `warning_amber` | 20px | Toast Warning, ConfirmDialog danger |
| `info_outline` | 20px | Toast Info |
| `sync` (旋转) | 20px | Toast Loading |

### 动画

| 动画 | 时长 | 缓动 | 组件 |
|------|------|------|------|
| Skeleton shimmer | 1.5s 循环 | linear | Skeleton |
| Toast 进入 | 300ms | ease-out | Toast |
| Toast 离开 | 200ms | ease-in | Toast |
| Dialog 进入 | 200ms | ease-out | ConfirmDialog |
| Dialog 离开 | 150ms | ease-in | ConfirmDialog |

---

*文档结束 — 共 34 个测试用例，需 22 张截图*
