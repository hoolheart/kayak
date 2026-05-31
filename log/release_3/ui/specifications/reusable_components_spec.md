# TASK-007: 可复用组件库 — 设计规格文档

## 文档信息

- **任务**: TASK-007 — 可复用组件库
- **目标平台**: Flutter Web（桌面优先，兼容平板、移动端）
- **设计系统**: Material Design 3
- **版本**: v1.0
- **日期**: 2025-05-31
- **状态**: 设计稿完成，等待评审

---

## 目录

1. [设计令牌速查](#设计令牌速查)
2. [ErrorView — 错误视图](#1-errorview--错误视图)
3. [EmptyView — 空状态视图](#2-emptyview--空状态视图)
4. [Skeleton — 骨架屏](#3-skeleton--骨架屏)
5. [ConfirmDialog — 确认对话框](#4-confirmdialog--确认对话框)
6. [Toast — 操作反馈](#5-toast--操作反馈)
7. [AsyncValueWidget — 统一三态组件](#6-asyncvaluewidget--统一三态组件)
8. [组件使用速查表](#组件使用速查表)

---

## 设计令牌速查

> 完整令牌定义见 `M1_auth_spec.md`。以下为本文档高频使用的令牌摘要。

### 颜色（Light / Dark）

| 语义 | Light | Dark |
|------|-------|------|
| Primary | `#1976D2` | `#90CAF9` |
| On Primary | `#FFFFFF` | `#003258` |
| Error | `#BA1A1A` | `#FFB4AB` |
| On Error | `#FFFFFF` | `#690005` |
| Error Container | `#FFDAD6` | `#93000A` |
| On Error Container | `#410002` | `#FFDAD6` |
| Success | `#2E7D32` | `#81C784` |
| Warning | `#ED6C02` | `#FFB74D` |
| Background | `#FDFCFF` | `#1A1C1E` |
| On Background | `#1A1C1E` | `#E2E2E6` |
| Surface | `#FFFFFF` | `#1A1C1E` |
| On Surface | `#1A1C1E` | `#E2E2E6` |
| On Surface Variant | `#43474E` | `#C4C6CF` |
| Outline | `#74777F` | `#8E9099` |
| Surface Variant | `#EFF3FA` | `#43474E` |

### 间距

| 令牌 | 值 |
|------|-----|
| spaceXs | 4px |
| spaceSm | 8px |
| spaceMd | 16px |
| spaceLg | 24px |
| spaceXl | 32px |
| spaceXxl | 48px |

### 排版

| 令牌 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| titleMedium | 16px | 500 | 24px | 组件标题 |
| bodyLarge | 16px | 400 | 24px | 正文描述 |
| bodyMedium | 14px | 400 | 20px | 次要描述、按钮文字 |
| labelLarge | 14px | 500 | 20px | 按钮文字 |
| labelMedium | 12px | 500 | 16px | 辅助标签 |

### 圆角

| 令牌 | 值 | 用途 |
|------|-----|------|
| radiusSmall | 4px | 小元素 |
| radiusMedium | 8px | 卡片、按钮、输入框 |
| radiusLarge | 12px | 对话框 |
| radiusXlarge | 16px | 大卡片 |

---

## 1. ErrorView — 错误视图

### 用途与使用场景

用于数据加载失败、网络请求失败、操作异常时的占位展示。统一所有错误状态的视觉表现，降低用户焦虑，提供明确的恢复路径。

**典型场景：**
- 列表/表格数据加载失败
- 表单提交后服务端返回 4xx/5xx
- 网络断开或超时
- 权限不足导致的内容不可访问

### 视觉规格

```
┌─────────────────────────────────┐
│                                 │
│           [Icon]                │
│        error_outline            │
│           48×48px               │
│                                 │
│      无法加载数据                │  ← Title Medium
│                                 │
│   网络连接异常，请检查网络       │  ← Body Medium
│        后点击重试               │      On Surface Variant
│                                 │
│      ┌──────────────┐           │
│      │    重试      │           │  ← Filled Button
│      └──────────────┘           │
│                                 │
└─────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 布局 | 垂直居中，Flex Column |
| 最小高度 | 200px（桌面）/ 160px（移动） |
| 内边距 | spaceXl (32px) |
| 图标 | `Icons.error_outline_outlined` |
| 图标尺寸 | 48×48px（桌面）/ 40×40px（移动） |
| 图标颜色 | On Surface Variant |
| 标题 | Title Medium, On Background |
| 标题上边距 | spaceLg (24px) |
| 描述 | Body Medium, On Surface Variant |
| 描述上边距 | spaceSm (8px) |
| 描述最大宽度 | 360px（防止长文本过度拉伸） |
| 按钮上边距 | spaceLg (24px) |
| 按钮样式 | Filled Button，高度 40px |
| 按钮最小宽度 | 120px |
| 按钮圆角 | radiusMedium (8px) |

### 交互状态

| 状态 | 视觉表现 | 触发条件 |
|------|----------|----------|
| **默认** | 图标 + 标题 + 描述 + 重试按钮 | 错误发生 |
| **Hover（按钮）** | 按钮背景加深，elevation1 | 鼠标悬停重试按钮 |
| **Pressed（按钮）** | 按钮 scale(0.98)，elevation2 | 点击重试按钮 |
| **加载中** | 按钮文字替换为 CircularProgressIndicator (20px)，禁用状态 | 点击重试后等待响应 |
| **无重试按钮** | 仅显示图标 + 标题 + 描述，隐藏按钮区域 | `showRetry = false` |

### 响应式考虑

| 断点 | 图标尺寸 | 内边距 | 最小高度 |
|------|----------|--------|----------|
| Mobile (< 600px) | 40px | 24px | 160px |
| Tablet (600-1024px) | 48px | 32px | 200px |
| Desktop (> 1024px) | 48px | 32px | 240px |

### 变体

- **紧凑型（Compact）**: 用于卡片内部或小区域错误，图标 32px，无按钮或改用 TextButton "重试"
- **全屏型（Fullscreen）**: 用于页面级错误，垂直居中于视口，图标 64px，描述下方增加 "返回首页" 次要操作

---

## 2. EmptyView — 空状态视图

### 用途与使用场景

用于数据为空、列表无结果、首次使用无内容的占位展示。通过友好的视觉和明确的引导，帮助用户理解当前状态并知晓下一步操作。

**典型场景：**
- 工作台列表为空（新用户首次进入）
- 搜索无结果
- 筛选条件过于严格导致无匹配项
- 通知/消息列表为空

### 视觉规格

```
┌─────────────────────────────────┐
│                                 │
│           [Icon]                │
│        folder_open_outlined     │
│           48×48px               │
│                                 │
│        暂无工作台                │  ← Title Medium
│                                 │
│    点击下方的按钮创建            │  ← Body Medium
│       您的第一个工作台          │      On Surface Variant
│                                 │
│      ┌──────────────┐           │
│      │  创建工作台  │           │  ← Filled Button
│      └──────────────┘           │
│                                 │
└─────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 布局 | 垂直居中，Flex Column |
| 最小高度 | 200px（桌面）/ 160px（移动） |
| 内边距 | spaceXl (32px) |
| 图标 | 可配置，默认 `Icons.folder_open_outlined` |
| 图标尺寸 | 48×48px（桌面）/ 40×40px（移动） |
| 图标颜色 | On Surface Variant at 60% |
| 标题 | Title Medium, On Background |
| 标题上边距 | spaceLg (24px) |
| 描述 | Body Medium, On Surface Variant |
| 描述上边距 | spaceSm (8px) |
| 描述最大宽度 | 360px |
| 操作按钮上边距 | spaceLg (24px) |
| 操作按钮样式 | Filled Button 或 Text Button（根据场景） |
| 操作按钮高度 | 40px |

### 交互状态

| 状态 | 视觉表现 | 触发条件 |
|------|----------|----------|
| **默认** | 图标 + 标题 + 描述 + 操作按钮 | 数据为空且允许操作 |
| **无操作** | 图标 + 标题 + 描述，隐藏按钮 | `actionButton = null` |
| **Hover（按钮）** | 按钮背景加深，elevation1 | 鼠标悬停操作按钮 |
| **Pressed（按钮）** | 按钮 scale(0.98)，elevation2 | 点击操作按钮 |
| **加载中** | 按钮替换为加载指示器，描述变更为"加载中..." | 执行操作后的等待状态 |

### 响应式考虑

| 断点 | 图标尺寸 | 内边距 | 最小高度 |
|------|----------|--------|----------|
| Mobile (< 600px) | 40px | 24px | 160px |
| Tablet (600-1024px) | 48px | 32px | 200px |
| Desktop (> 1024px) | 48px | 32px | 240px |

### 配置参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| icon | IconData | 否 | 自定义图标，默认 `folder_open_outlined` |
| title | String | 是 | 空状态标题 |
| description | String | 否 | 补充说明 |
| actionButton | Widget? | 否 | 操作按钮，null 时不显示 |
| compact | bool | 否 | 紧凑型模式，用于小区域 |

---

## 3. Skeleton — 骨架屏

### 用途与使用场景

用于内容加载过程中的占位展示，通过动画减轻用户等待焦虑，维持页面结构感知。比空白或纯转圈加载体验更佳。

**典型场景：**
- 列表首次加载
- 分页加载下一页时的新内容区域
- 卡片内容异步加载
- 仪表盘数据加载

### 视觉规格

#### 列表骨架

```
┌──────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 头像 + 标题行
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 描述行 1
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓              │  ← 描述行 2 (70%)
│                                          │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 重复项
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓              │
│                                          │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 重复项
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓              │
└──────────────────────────────────────────┘
```

#### 卡片骨架

```
┌─────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 图片区域 (16:9)
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│                                 │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓       │  ← 标题
│                                 │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 描述行 1
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    │  ← 描述行 2
│                                 │
│     ▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓   │  ← 底部信息
└─────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 背景色 | Surface Variant at 50% |
| 动画颜色 | 从 Surface Variant 渐变到 Surface Variant at 80%，再返回 |
| 圆角 | radiusSmall (4px) 用于小元素，radiusMedium (8px) 用于卡片/图片 |
| 项间距 | spaceMd (16px) |
| 行间距 | spaceSm (8px) |
| 头像占位 | 圆形，40×40px |
| 标题行高度 | 16px，宽度 40-60% |
| 描述行高度 | 14px，宽度 70-100% |
| 图片占位 | 16:9 比例，圆角 8px |
| 动画时长 | 1.5s 循环 |
| 动画类型 | 水平方向 shimmer（光泽扫过效果） |

### 交互状态

| 状态 | 视觉表现 | 触发条件 |
|------|----------|----------|
| **动画中** | shimmer 光泽从左到右扫过 | 数据加载中 |
| **静态** | 无动画，纯色占位 | `prefers-reduced-motion` 开启 |
| **完成淡出** | 骨架屏淡出 (200ms)，内容淡入 (200ms) | 数据加载完成 |
| **列表项数量** | 显示 3-5 个占位项（按场景配置） | 默认 |
| **卡片数量** | 显示网格数量的占位（如 2×2） | 网格布局时 |

### 响应式考虑

| 断点 | 列表项数 | 网格列数 | 行高 |
|------|----------|----------|------|
| Mobile (< 600px) | 3 项 | 1 列 | 标准 |
| Tablet (600-1024px) | 4 项 | 2 列 | 标准 |
| Desktop (> 1024px) | 5 项 | 3-4 列 | 标准 |

### 变体

- **ListSkeleton**: 列表项占位，每项包含头像 + 2-3 行文字
- **CardSkeleton**: 卡片占位，包含图片区域 + 标题 + 描述 + 底部信息
- **TextSkeleton**: 纯文本占位，1-3 行，可配置宽度百分比
- **AvatarSkeleton**: 圆形/圆角矩形头像占位，可配置尺寸
- **DashboardSkeleton**: 混合布局，包含统计数字卡片 + 图表区域 + 列表

---

## 4. ConfirmDialog — 确认对话框

### 用途与使用场景

用于需要用户二次确认的操作，防止误操作导致不可逆后果。覆盖在当前内容之上，阻断用户操作直到做出选择。

**典型场景：**
- 删除工作台/实验/设备
- 退出未保存的编辑
- 批量操作确认
- 敏感操作授权

### 视觉规格

```
┌──────────────────────────────────────┐
│                                      │
│   删除工作台？                        │  ← Title Medium
│                                      │
│   此操作将永久删除"材料测试"         │  ← Body Medium
│   工作台及其所有数据。               │      On Surface Variant
│   该操作不可撤销。                   │
│                                      │
│   ┌──────────┐  ┌──────────┐        │
│   │   取消   │  │   删除   │        │  ← Text + Filled Button
│   └──────────┘  └──────────┘        │      (危险操作：红色)
│                                      │
└──────────────────────────────────────┘
         ░░░░░░░░░░░░░░░░░░░░          ← 遮罩层 (Scrim)
```

| 属性 | 值 |
|------|-----|
| 容器 | Card，圆角 radiusLarge (12px) |
| 背景 | Surface |
| 最小宽度 | 280px（移动）/ 320px（桌面） |
| 最大宽度 | 560px |
| 内边距 | spaceXl (32px) 顶部/左右，spaceLg (24px) 底部 |
| 标题 | Title Medium, On Background |
| 描述上边距 | spaceSm (8px) |
| 描述 | Body Medium, On Surface Variant |
| 按钮区域上边距 | spaceXl (32px) |
| 按钮区域对齐 | 右对齐（桌面）/ 居中对距（移动） |
| 按钮间距 | spaceSm (8px) |
| 遮罩层 | Background at 60% opacity |
| 遮罩层点击 | 关闭对话框（可配置） |
| 进入动画 | 遮罩淡入 150ms + 对话框从底部滑入 200ms（移动）/ 缩放淡入 200ms（桌面） |
| 离开动画 | 反向退出，150ms |

### 按钮规格

| 按钮 | 样式 | 颜色 | 说明 |
|------|------|------|------|
| 取消 | Text Button | Primary | 左侧/次要位置 |
| 确认 | Filled Button | Primary（普通）/ Error（危险） | 右侧/主要位置 |

### 交互状态

| 状态 | 视觉表现 | 触发条件 |
|------|----------|----------|
| **默认** | 标准对话框，取消(蓝) + 确认(蓝/红) | 对话框弹出 |
| **Hover（按钮）** | 对应按钮背景变化 | 鼠标悬停 |
| **Pressed（按钮）** | 按钮 scale(0.98) | 点击按钮 |
| **遮罩点击** | 对话框离开动画 | 点击遮罩层（如果 `dismissible = true`） |
| **键盘 Esc** | 等同于点击取消 | 按下 Escape 键 |
| **键盘 Enter** | 等同于点击确认（如果确认按钮聚焦） | 按下 Enter 键 |

### 响应式考虑

| 断点 | 对话框位置 | 宽度 | 动画 |
|------|-----------|------|------|
| Mobile (< 600px) | 底部 Sheet，贴底 | 100% | 底部滑入 |
| Tablet/Desktop (> 600px) | 屏幕中央 | min 320px, max 560px | 缩放淡入 |

### 变体

- **危险确认**: 确认按钮使用 Error 色背景，增加 `Icons.warning` 图标前缀
- **信息确认**: 无危险操作，确认按钮使用 Primary 色
- **无取消**: 仅显示确认按钮，用于必须执行的操作（如会话过期重新登录）

---

## 5. Toast — 操作反馈

### 用途与使用场景

用于操作结果的轻量级反馈，自动消失不干扰用户当前操作。替代 AlertDialog 用于非阻断性通知。

**典型场景：**
- 保存成功/失败
- 删除成功/失败
- 复制到剪贴板
- 网络重连
- 表单验证通过/不通过

### 视觉规格

```
   ┌───────────────────────────────────────────┐
   │ ✓  工作台创建成功                          │  ← Success
   └───────────────────────────────────────────┘

   ┌───────────────────────────────────────────┐
   │ ✕  删除失败，请稍后重试                    │  ← Error
   └───────────────────────────────────────────┘

   ┌───────────────────────────────────────────┐
   │ ⟳  正在保存...                             │  ← Loading
   └───────────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 容器 | 圆角卡片，radiusMedium (8px) |
| 高度 | 最小 48px，自适应内容 |
| 最小宽度 | 200px |
| 最大宽度 | 桌面 400px / 移动 100% - 32px |
| 内边距 | 水平 spaceMd (16px)，垂直 spaceSm (12px) |
| 位置 | 桌面：右上角，距边缘 24px / 移动：底部居中，距底 32px |
| 阴影 | elevation2 |
| 图标尺寸 | 20×20px |
| 图标右边距 | spaceSm (8px) |
| 文字 | Body Medium |

### 类型规格

| 类型 | 背景色 | 文字/图标色 | 图标 | 自动消失 |
|------|--------|-------------|------|----------|
| **Success** | Success at 12% + Success 边框 1px | Success | `Icons.check_circle` | 3 秒 |
| **Error** | Error Container | On Error Container | `Icons.error_outline` | 5 秒 |
| **Warning** | Warning at 12% + Warning 边框 1px | Warning | `Icons.warning_amber` | 4 秒 |
| **Info** | Primary at 12% + Primary 边框 1px | Primary | `Icons.info_outline` | 3 秒 |
| **Loading** | Surface Variant | On Surface | `Icons.sync` (旋转) | 手动关闭或加载完成 |

### 交互状态

| 状态 | 视觉表现 | 触发条件 |
|------|----------|----------|
| **进入** | 从位置外滑入 + 淡入，300ms，ease-out | Toast 触发 |
| **停留** | 静态显示，进度条递减（可选） | 显示期间 |
| **离开** | 向上/向下滑出 + 淡出，200ms，ease-in | 超时或手动关闭 |
| **Hover** | 暂停自动消失计时器 | 鼠标悬停 |
| **堆叠** | 多个 Toast 垂直间距 8px，最多 3 个 | 连续触发 |

### 响应式考虑

| 断点 | 位置 | 最大宽度 | 圆角（底部） |
|------|------|----------|-------------|
| Mobile (< 600px) | 底部固定 | 100% | 0（贴底时）或 8px（悬浮时） |
| Tablet/Desktop (> 600px) | 右上角 | 400px | 8px |

### 行为规则

- **最大数量**: 同时最多显示 3 个，新的顶替最早的
- **去重**: 相同消息的 Toast 不重复显示，重置计时器
- **操作后反馈**: 成功 Toast 在操作完成后显示，Loading Toast 在操作开始时显示
- **持续时间**: Success/Info 3s, Warning 4s, Error 5s, Loading 直到手动关闭

---

## 6. AsyncValueWidget — 统一三态组件

### 用途与使用场景

统一封装异步数据加载的三种状态（Loading / Data / Error）和空数据状态，消除页面中重复的状态判断逻辑，保证用户体验一致性。

**典型场景：**
- 任何基于 Riverpod `AsyncValue` 的数据展示
- 列表/表格/详情页的数据加载
- 替换页面中散落的 `if (loading) ... else if (error) ...` 逻辑

### 视觉规格

`AsyncValueWidget` 本身无固定视觉表现，它是状态分发器，根据状态渲染对应的子组件：

```
AsyncValueWidget(
  value: asyncValue,
  
  // Loading 状态 → 显示 Skeleton
  ┌─────────────────────────────┐
  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← Skeleton (默认)
  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    │
  └─────────────────────────────┘
  
  // Data 状态 → 显示内容
  ┌─────────────────────────────┐
  │                             │
  │      [实际内容渲染]          │  ← dataBuilder(data)
  │                             │
  └─────────────────────────────┘
  
  // Error 状态 → 显示 ErrorView
  ┌─────────────────────────────┐
  │                             │
  │         [ErrorView]         │  ← 错误图标 + 重试
  │                             │
  └─────────────────────────────┘
  
  // Empty 状态 → 显示 EmptyView
  ┌─────────────────────────────┐
  │                             │
  │         [EmptyView]         │  ← 空状态 + 操作引导
  │                             │
  └─────────────────────────────┘
)
```

### 配置参数

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| value | AsyncValue<T> | 是 | — | 异步数据状态 |
| dataBuilder | Widget Function(T) | 是 | — | 数据就绪时渲染 |
| loadingBuilder | Widget? | 否 | Skeleton | 加载中渲染 |
| errorBuilder | Widget Function(Object, StackTrace?)? | 否 | ErrorView | 错误时渲染 |
| emptyBuilder | Widget? | 否 | EmptyView | 数据为空时渲染 |
| emptyCondition | bool Function(T)? | 否 | null | 自定义空数据判断 |
| onRetry | void Function()? | 否 | null | 重试回调（传给 ErrorView） |
| skipLoadingOnRefresh | bool | 否 | true | 刷新时是否保留旧数据显示 Skeleton |

### 交互状态

| 状态 | 视觉表现 | 触发条件 |
|------|----------|----------|
| **Loading** | 显示 loadingBuilder（默认 Skeleton） | `AsyncValue.loading` |
| **Data（有内容）** | 显示 dataBuilder(data) | `AsyncValue.data` 且数据非空 |
| **Data（空内容）** | 显示 emptyBuilder（默认 EmptyView） | `AsyncValue.data` 且数据为空 |
| **Error** | 显示 errorBuilder（默认 ErrorView）+ 重试按钮 | `AsyncValue.error` |
| **Refresh（保留数据）** | 显示 dataBuilder + 顶部线性进度条 | 刷新中且 `skipLoadingOnRefresh = true` |
| **Refresh（不保留）** | 显示 Skeleton | 刷新中且 `skipLoadingOnRefresh = false` |

### 响应式考虑

`AsyncValueWidget` 的响应式由其内部各状态组件（Skeleton/ErrorView/EmptyView/dataBuilder）各自处理，组件本身只负责状态分发和容器尺寸适配。

### 使用模式

```dart
// 基础用法
AsyncValueWidget(
  value: ref.watch(workspacesProvider),
  dataBuilder: (workspaces) => WorkspaceList(workspaces: workspaces),
  onRetry: () => ref.invalidate(workspacesProvider),
)

// 自定义加载
AsyncValueWidget(
  value: ref.watch(dashboardProvider),
  loadingBuilder: DashboardSkeleton(),
  dataBuilder: (data) => DashboardView(data: data),
)

// 自定义空状态和错误状态
AsyncValueWidget(
  value: ref.watch(notificationsProvider),
  dataBuilder: (notifications) => NotificationList(notifications),
  emptyBuilder: EmptyView(
    icon: Icons.notifications_none,
    title: '暂无通知',
    description: '当有新活动时，通知会显示在这里',
  ),
  errorBuilder: (err, st) => ErrorView(
    title: '加载通知失败',
    description: '请检查网络连接',
    onRetry: () => ref.invalidate(notificationsProvider),
  ),
)
```

---

## 组件使用速查表

| 场景 | 推荐组件 | 替代方案 |
|------|----------|----------|
| 数据加载失败 | ErrorView | — |
| 列表/内容为空 | EmptyView | — |
| 首次加载等待 | Skeleton | CircularProgressIndicator（仅小型区域） |
| 删除/危险操作确认 | ConfirmDialog | — |
| 保存/操作成功反馈 | Toast (Success) | — |
| 保存/操作失败反馈 | Toast (Error) | ErrorView（页面级） |
| 异步数据统一处理 | AsyncValueWidget | 手动 if/else |
| 网络断开提示 | Toast (Error) + ErrorView | — |
| 批量操作进行中 | Toast (Loading) | 页面级加载遮罩 |

---

## 无障碍要求

### 通用要求

- **ErrorView**: 屏幕阅读器朗读 "错误：{标题}，{描述}，可点击重试"
- **EmptyView**: 屏幕阅读器朗读 "{标题}，{描述}，{按钮文字（如有）}"
- **Skeleton**: `aria-busy="true"`，屏幕阅读器朗读 "内容加载中"（不朗读骨架内容）
- **ConfirmDialog**: 焦点自动移至对话框，限制 Tab 在对话框内，关闭后焦点返回触发元素
- **Toast**: `aria-live="polite"`，屏幕阅读器朗读 Toast 内容

### 键盘导航

- **ConfirmDialog**: Tab 在按钮间循环，Enter 确认，Esc 取消
- **ErrorView**: Tab 可聚焦重试按钮，Enter 触发重试
- **EmptyView**: Tab 可聚焦操作按钮，Enter 触发操作

### 动效

- **prefers-reduced-motion**:
  - Skeleton: 禁用 shimmer 动画，显示静态占位色
  - Toast: 禁用滑入/滑出动画，直接显示/隐藏
  - ConfirmDialog: 禁用缩放/滑入动画，直接显示
  - ErrorView/EmptyView: 禁用所有过渡动画

---

## 设计 QA 检查项

### 通用检查

- [ ] 所有组件颜色与 Design Token 完全一致
- [ ] Light/Dark 主题切换颜色正确
- [ ] 组件间距符合 8px 网格系统
- [ ] 圆角一致（按组件规范）
- [ ] 阴影层级正确
- [ ] 动画时长和缓动符合规范

### 组件级检查

- [ ] ErrorView: 重试按钮点击后进入加载状态
- [ ] ErrorView: 紧凑型变体在小区域内显示正常
- [ ] EmptyView: 操作按钮可选，无按钮时布局不塌陷
- [ ] Skeleton: shimmer 动画流畅，不卡顿
- [ ] Skeleton: `prefers-reduced-motion` 下显示静态占位
- [ ] ConfirmDialog: 移动端底部 Sheet 动画正常
- [ ] ConfirmDialog: 危险操作确认按钮为红色
- [ ] ConfirmDialog: 遮罩层点击可关闭（如配置）
- [ ] Toast: 3 秒后自动消失（Success）
- [ ] Toast: 悬停时暂停计时器
- [ ] Toast: 最多同时显示 3 个
- [ ] AsyncValueWidget: 四种状态切换无闪烁
- [ ] AsyncValueWidget: 刷新时保留旧数据（如配置）

### 响应式检查

- [ ] Mobile (< 600px): 所有组件布局正确
- [ ] Tablet (600-1024px): 所有组件布局正确
- [ ] Desktop (> 1024px): 所有组件布局正确

### 无障碍检查

- [ ] 屏幕阅读器正确朗读所有组件
- [ ] 键盘可完全操作 ErrorView/EmptyView/ConfirmDialog
- [ ] `prefers-reduced-motion` 下所有动画禁用
- [ ] 对比度符合 WCAG AA

---

## 附录

### A. 组件依赖关系

```
AsyncValueWidget
├── Loading → Skeleton (列表/卡片/文本变体)
├── Error → ErrorView
├── Empty → EmptyView
└── Data → dataBuilder (业务组件)

ConfirmDialog
├── 遮罩层 (Scrim)
├── 内容区域 (Card)
└── 按钮组 (TextButton + FilledButton)

Toast
├── 图标 + 文字 (Row)
└── 自动消失计时器
```

### B. 图标清单

| 图标 | 用途 | 尺寸 | 颜色 |
|------|------|------|------|
| error_outline_outlined | ErrorView 默认图标 | 48px | On Surface Variant |
| folder_open_outlined | EmptyView 默认图标 | 48px | On Surface Variant |
| warning_amber | ConfirmDialog 危险操作前缀 | 20px | Error |
| check_circle | Toast 成功 | 20px | Success |
| error_outline | Toast 错误 | 20px | Error |
| warning_amber | Toast 警告 | 20px | Warning |
| info_outline | Toast 信息 | 20px | Primary |
| sync | Toast 加载中（旋转） | 20px | On Surface |

### C. 动画参数汇总

| 动画 | 时长 | 缓动 | 组件 |
|------|------|------|------|
| Skeleton shimmer | 1.5s 循环 | linear | Skeleton |
| Toast 进入 | 300ms | ease-out | Toast |
| Toast 离开 | 200ms | ease-in | Toast |
| Dialog 进入（桌面） | 200ms | ease-out | ConfirmDialog |
| Dialog 进入（移动） | 200ms | ease-out | ConfirmDialog |
| Dialog 离开 | 150ms | ease-in | ConfirmDialog |
| 状态切换淡入淡出 | 200ms | ease-in-out | AsyncValueWidget |

---

**文档结束**

如有任何实现问题，请联系 sw-anna 进行设计澄清。
