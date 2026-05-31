# TASK-007 详细设计 — 可复用组件库

> **作者**: sw-tom (Developer)
> **日期**: 2026-05-31
> **状态**: 已完成
> **关联任务**: TASK-007
> **参考文档**: [tasks.md](../tasks.md), [reusable_components_spec.md](../ui/specifications/reusable_components_spec.md), [test_cases.md](../test/TASK-007_test_cases.md)

---

## 1. 概述

本任务实现 6 个可复用 Flutter Widget，用于统一应用的加载、错误、空状态、确认对话框和操作反馈的交互体验。

所有组件遵循 Material Design 3 设计系统，通过 `Theme.of(context)` 获取颜色和主题，通过 `AppLocalizations.of(context)` 获取国际化文本，支持 Light/Dark 主题和响应式布局。

### 组件列表

| # | 组件 | 文件路径 | 核心功能 |
|---|------|---------|----------|
| 1 | ErrorView | `lib/widgets/error_view.dart` | 错误图标 + 标题 + 描述 + 重试按钮 |
| 2 | EmptyView | `lib/widgets/empty_view.dart` | 空状态图标 + 标题 + 描述 + 可选操作按钮 |
| 3 | Skeleton | `lib/widgets/skeleton.dart` | shimmer 动画骨架屏（列表/卡片/文本） |
| 4 | ConfirmDialog | `lib/widgets/confirm_dialog.dart` | 确认对话框（取消/确认，支持危险操作，响应式） |
| 5 | Toast | `lib/widgets/toast.dart` | 操作反馈（Success/Error/Warning/Info/Loading） |
| 6 | AsyncValueWidget | `lib/widgets/async_value_widget.dart` | 统一三态/四态分发组件 |

---

## 2. 组件依赖关系

```
AsyncValueWidget
├── Loading  → Skeleton (默认 loadingBuilder)
├── Error    → ErrorView (默认 errorBuilder)
├── Empty    → EmptyView (默认 emptyBuilder)
└── Data     → dataBuilder (业务组件)

ConfirmDialog
└── Material 内置 Dialog + showDialog()

Toast
├── OverlayEntry (全局覆盖层)
└── AnimationController (进入/离开动画)

Skeleton
└── AnimatedBuilder (shimmer 动画)
```

---

## 3. 详细设计

### 3.1 ErrorView `lib/widgets/error_view.dart`

#### 接口定义

```dart
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    this.description,
    this.onRetry,
    this.isLoading = false,
    this.showRetry = true,
    this.compact = false,
  });

  final String title;
  final String? description;
  final VoidCallback? onRetry;
  final bool isLoading;
  final bool showRetry;
  final bool compact;
}
```

#### 布局结构

```
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(error_outline_outlined, size: iconSize),    // 48/40/32px 响应式
    SizedBox(height: spaceLg),                        // 24px
    Text(title, style: titleMedium),                  // Title Medium
    if (description != null) ...[
      SizedBox(height: spaceSm),                      // 8px
      Text(description, style: bodyMedium, maxWidth: 360),
    ],
    if (showRetry && onRetry != null) ...[
      SizedBox(height: spaceLg),                      // 24px
      _RetryButton(isLoading: isLoading, onRetry: onRetry),
    ],
  ],
)
```

#### 状态流转

```
[Error 发生]
    │
    ▼
ErrorView 渲染
    │
    ├── onRetry != null → 显示重试按钮
    │       │
    │       ├── isLoading = false → FilledButton("重试")
    │       │       │
    │       │       └── 点击 → onRetry()
    │       │
    │       └── isLoading = true → CircularProgressIndicator + 禁用
    │
    └── showRetry = false → 隐藏按钮区域
```

#### 响应式

| 断点 | 图标尺寸 | 内边距 | 最小高度 |
|------|----------|--------|----------|
| < 600px (Mobile) | 40px | 24px | 160px |
| 600-1024px (Tablet) | 48px | 32px | 200px |
| > 1024px (Desktop) | 48px | 32px | 240px |
| compact=true | 32px | 16px | 120px |

---

### 3.2 EmptyView `lib/widgets/empty_view.dart`

#### 接口定义

```dart
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.description,
    this.actionButton,
    this.icon,
    this.compact = false,
  });

  final String title;
  final String? description;
  final Widget? actionButton;
  final IconData? icon;
  final bool compact;
}
```

#### 布局结构

```
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(folder_open_outlined / custom, size: iconSize, opacity: 0.6),
    SizedBox(height: spaceLg),
    Text(title, style: titleMedium),
    if (description != null) ...[
      SizedBox(height: spaceSm),
      Text(description, style: bodyMedium, maxWidth: 360),
    ],
    if (actionButton != null) ...[
      SizedBox(height: spaceLg),
      actionButton!,
    ],
  ],
)
```

#### 响应式

| 断点 | 图标尺寸 | 内边距 | 最小高度 |
|------|----------|--------|----------|
| < 600px | 40px | 24px | 160px |
| >= 600px | 48px | 32px | 200px |
| compact=true | 40px | 16px | 120px |

---

### 3.3 Skeleton `lib/widgets/skeleton.dart`

#### 接口定义

```dart
enum SkeletonType { list, card, text, avatar }

class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.type = SkeletonType.list,
    this.count,
  });

  final SkeletonType type;
  final int? count;  // null = 响应式默认值
}
```

#### Shimmer 动画实现

使用 `AnimatedBuilder` + `AnimationController` 实现水平方向的光泽扫过效果：

```
┌──────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │  ← Surface Variant at 50%
│ ░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░ │  ← Shimmer 高光区域从左到右移动
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
└──────────────────────────────────────────────────────┘
      ← 1.5s 循环, linear 缓动 →
```

Shimmer 使用 `ShaderMask` + `LinearGradient` 实现，由 `_ShimmerPainter` 管理动画状态。

#### ListSkeleton 结构

```
每项:
┌──────────────────────────────────────────┐
│ (circle)  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓       │  ← 头像(40px) + 标题(16px, 60%)
│           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 描述行1(14px, 100%)
│           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓             │  ← 描述行2(14px, 70%)
├──────────────────────────────────────────┤
│ ... 重复项                                │
└──────────────────────────────────────────┘
```

#### CardSkeleton 结构

```
┌─────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 图片区域 (16:9)
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│                                 │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓       │  ← 标题
│                                 │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← 描述行1
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    │  ← 描述行2
└─────────────────────────────────┘
```

#### TextSkeleton 结构

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ← 行1 (100%)
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ← 行2 (100%)
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓         ← 行3 (70%)
```

#### 响应式（默认列表项数）

| 断点 | 列表项数 | 网格列数 |
|------|----------|----------|
| < 600px | 3 | 1 |
| 600-1024px | 4 | 2 |
| > 1024px | 5 | 3-4 |

---

### 3.4 ConfirmDialog `lib/widgets/confirm_dialog.dart`

#### 接口定义

```dart
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    this.description,
    required this.onConfirm,
    this.onCancel,
    this.confirmLabel,
    this.cancelLabel,
    this.isDanger = false,
    this.dismissible = true,
  });

  /// 便捷方法：显示确认对话框
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? description,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String? confirmLabel,
    String? cancelLabel,
    bool isDanger = false,
    bool dismissible = true,
  });

  // ...字段
}
```

#### 响应式布局

**桌面端 (> 600px)**: 居中 Dialog，缩放淡入动画
```
┌────────────────────────────────────┐
│   Title Medium                      │
│   Body Medium (On Surface Variant)  │
│                                    │
│         [取消]  [确认]              │  ← 右对齐
└────────────────────────────────────┘
```

**移动端 (< 600px)**: 底部 Sheet，贴底滑入
```
┌────────────────────────────────────┐
│   Title Medium                      │
│   Body Medium (On Surface Variant)  │
│                                    │
│       [取消]     [确认]             │  ← 居中分布
└────────────────────────────────────┘
         ← 100% 宽度 →
```

#### 状态流转

```
show() 被调用
    │
    ▼
检测屏幕宽度
    │
    ├── < 600px → showModalBottomSheet()
    │       │
    │       └── 底部 Sheet 渲染
    │
    └── >= 600px → showDialog()
            │
            └── AlertDialog 渲染
    
点击操作:
    ├── 取消 → onCancel() → Navigator.pop()
    ├── 确认 → onConfirm() → Navigator.pop()
    ├── 遮罩 → dismissible ? Navigator.pop() : 忽略
    └── Esc  → dismissible ? Navigator.pop() : 忽略
```

---

### 3.5 Toast `lib/widgets/toast.dart`

#### 接口定义

```dart
enum ToastType { success, error, warning, info, loading }

class ToastItem {
  final String id;
  final String message;
  final ToastType type;
  final DateTime createdAt;
  // ...
}

class ToastOverlay extends StatefulWidget {
  // 管理 Overlay 中的 Toast 条目
}

/// 静态便捷方法
class Toast {
  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration? duration,
  });
}
```

#### 类型规格

| 类型 | 背景色 | 图标 | 持续时间 |
|------|--------|------|----------|
| Success | Success at 12% + 边框 | `Icons.check_circle` | 3s |
| Error | Error Container | `Icons.error_outline` | 5s |
| Warning | Warning at 12% + 边框 | `Icons.warning_amber` | 4s |
| Info | Primary at 12% + 边框 | `Icons.info_outline` | 3s |
| Loading | Surface Variant | `Icons.sync` (旋转) | 手动关闭 |

#### 布局与定位

**桌面端 (> 600px)**: 右上角固定
```
┌──── ──────────────────────────────────┐
│ ← 24px →  [✓] 工作台创建成功          │
└────────────────────────────────────────┘
            ↑ max-width: 400px
```

**移动端 (< 600px)**: 底部居中
```
            ┌──────────────────┐
            │ [✓] 操作成功     │
            └──────────────────┘
            ↑ max-width: 100% - 32px
```

#### 堆叠管理

```
Overlay 中的 Toast 队列:
┌── Toast 3 (最新) ──────────────────┐  ← 最多 3 个
├── Toast 2 ─────────────────────────┤
├── Toast 1 ─────────────────────────┤  ← 第 4 个顶替此位置
└────────────────────────────────────┘
```

使用 `OverlayEntry` + `StatefulWidget` 管理 Toast 生命周期：
- 每个 Toast 是一个独立的 `_ToastEntry` Widget
- 通过 `UniqueKey()` 标识
- 队列管理：添加时检查数量，超过 3 个移除最早的
- 动画：进入 300ms ease-out，离开 200ms ease-in

---

### 3.6 AsyncValueWidget `lib/widgets/async_value_widget.dart`

#### 接口定义

```dart
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.emptyCondition,
    this.onRetry,
    this.skipLoadingOnRefresh = true,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) dataBuilder;
  final Widget? loadingBuilder;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final Widget? emptyBuilder;
  final bool Function(T data)? emptyCondition;
  final VoidCallback? onRetry;
  final bool skipLoadingOnRefresh;
}
```

#### 状态分发逻辑

```
AsyncValue<T>
    │
    ├── isRefreshing && skipLoadingOnRefresh
    │       │
    │       ├── hasValue → 显示旧数据 + 顶部进度条
    │       └── !hasValue → 显示 loadingBuilder
    │
    ├── isLoading → loadingBuilder (默认 Skeleton)
    │
    ├── hasError → errorBuilder (默认 ErrorView + onRetry)
    │
    └── hasValue → dataBuilder (数据)
            │
            └── emptyCondition != null && emptyCondition(data) == true
                    │
                    └── → emptyBuilder (默认 EmptyView)
```

#### 刷新保留数据

当 `skipLoadingOnRefresh = true` 且 `AsyncValue` 处于刷新状态时：
1. `hasValue` 为 true → 保留现有 dataBuilder 内容
2. 在顶部叠加 `LinearProgressIndicator`（刷新指示器）
3. `hasValue` 为 false → 显示 loadingBuilder（无旧数据可保留）

---

## 4. 国际化字符串

使用现有 ARB 文件中的字符串：

| 字符串 | 用途 | EN | ZH |
|--------|------|----|-----|
| `retry` | ErrorView 重试按钮 | Retry | 重试 |
| `loading` | Skeleton 语义标签 | Loading... | 加载中... |
| `noData` | EmptyView 默认空状态 | No data available | 暂无数据 |
| `confirm` | ConfirmDialog 确认按钮 | Confirm | 确认 |
| `cancel` | ConfirmDialog 取消按钮 | Cancel | 取消 |
| `delete` | ConfirmDialog 危险操作确认 | Delete | 删除 |

---

## 5. 测试策略

所有组件使用 `flutter_test` 进行 Widget 测试：

### 测试模式

```dart
// 测试包装器
Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
```

### 各组件测试要点

| 组件 | 测试要点 | 覆盖数 |
|------|---------|:-----:|
| ErrorView | 默认渲染、onRetry 回调、isLoading 状态、showRetry=false、compact、无描述 | 6 |
| EmptyView | 默认渲染、无操作按钮、onAction 回调、自定义图标、compact | 5 |
| Skeleton | List/Card/Text 渲染、shimmer 动画、响应式项数 | 5 |
| ConfirmDialog | 渲染、取消/确认回调、危险操作、移动端 Sheet、键盘导航 | 6 |
| Toast | 4 类型渲染、自动消失、Loading 持久、堆叠 | 6 |
| AsyncValueWidget | Loading/Data/Error/Empty 四态、刷新保留、自定义 builder | 6 |
| **合计** | | **34** |

---

## 6. 验收标准

1. ✅ 所有 6 个组件在 loading/error/data/empty 状态下正确渲染
2. ✅ 所有文本通过 `AppLocalizations.of(context)` 获取（无硬编码）
3. ✅ Skeleton 与目标内容尺寸一致
4. ✅ Widget 测试覆盖所有状态（34 个测试用例）
5. ✅ ConfirmDialog 按钮回调正常
6. ✅ Toast 显示并自动消失
7. ✅ AsyncValueWidget 四态切换
8. ✅ `flutter analyze --fatal-infos` 零警告
9. ✅ `flutter test` 所有测试通过

---

## 7. 组件 UDT（Unit Dependency Table）

| 组件 | 依赖 | 内部子组件 |
|------|------|-----------|
| ErrorView | Material, AppLocalizations | _RetryButton |
| EmptyView | Material, AppLocalizations | — |
| Skeleton | Material, AnimationController | _ShimmerPainter, _SkeletonItem |
| ConfirmDialog | Material, AppLocalizations | _DialogContent |
| Toast | Material, Overlay, AnimationController | _ToastEntry, _ToastManagerState |
| AsyncValueWidget | flutter_riverpod (AsyncValue), Material | ErrorView, EmptyView, Skeleton |

---

## 8. 实现注意事项

1. **`const` 构造函数**: 所有 Widget 必须使用 `const` 构造函数
2. **主题一致性**: 所有颜色通过 `Theme.of(context).colorScheme` 获取，不硬编码
3. **国际化**: 所有用户可见文本通过 `AppLocalizations.of(context)` 获取
4. **响应式**: 使用 `MediaQuery.of(context).size.width` 或 `LayoutBuilder` 实现断点适配
5. **可测试性**: 组件应暴露足够的参数以便测试各种状态
6. **性能**: Skeleton 动画使用 `AnimatedBuilder`，避免不必要重建
7. **Loading Toast**: 使用 `sync` 图标并添加旋转动画，不自动消失
8. **Toast 堆叠**: 使用单例 OverlayEntry 管理器，最大 3 个

---

*设计文档结束 — 对应 TASK-007 的 6 个可复用组件*
