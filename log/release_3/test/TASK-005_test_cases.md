# TASK-005 测试用例 — 主题系统（Material 3）

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待 sw-tom 审查
> **关联任务**: TASK-005（主题系统，Material 3）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md)

---

## 测试范围

TASK-005 需交付以下文件：

| # | 文件 | 功能 | 测试覆盖 |
|---|------|------|:------:|
| 1 | `lib/theme/colors.dart` | 自定义颜色常量定义 | TC-015 ~ TC-016 |
| 2 | `lib/theme/typography.dart` | 文字样式配置（等宽字体） | TC-017 ~ TC-018 |
| 3 | `lib/theme/app_theme.dart` | `lightTheme()` + `darkTheme()` + `ThemeData` 配置 | TC-001 ~ TC-004, TC-010 ~ TC-013 |
| 4 | `lib/providers/settings_provider.dart` | ThemeNotifier（Riverpod 3.x Notifier） | TC-005 ~ TC-009, TC-019 ~ TC-024 |

---

## 主题规范速查

### 颜色定义

| 属性 | 值 | 说明 |
|------|------|------|
| Seed Color | `#1976D2` (Color 0xFF1976D2) | 科技蓝，主色调 |
| 生成方式 | `ColorScheme.fromSeed(seedColor: ..., brightness: ...)` | Material 3 自动生成完整调色板 |
| Light Brightness | `Brightness.light` | 浅色模式 |
| Dark Brightness | `Brightness.dark` | 深色模式 |

### ThemeMode 枚举

| 值 | 含义 | 说明 |
|------|------|------|
| `ThemeMode.system` | 跟随系统 | **默认值**，自动匹配操作系统浅色/深色设置 |
| `ThemeMode.light` | 浅色模式 | 始终使用 `lightTheme` |
| `ThemeMode.dark` | 深色模式 | 始终使用 `darkTheme` |

### 依赖关系

| 依赖 | 版本 | 用途 |
|------|------|------|
| `shared_preferences` | ^2.5.5 | 持久化主题偏好 |
| `flutter_riverpod` | ^3.3.1 | ThemeNotifier 状态管理 |
| `riverpod_annotation` | ^4.0.0 | Notifier 注解（如使用代码生成） |

---

## 一、主题配置测试（3 项）

---

### TC-001: lightTheme 使用 Material 3 且配置完整

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL**（应用视觉基础） |
| **类别** | 主题配置 / Material 3 |
| **关联验收标准** | 所有 Material 3 组件使用统一色板 |

**前置条件**：
- `lib/theme/app_theme.dart` 已实现
- `AppTheme.lightTheme` getter 存在

**测试步骤**：

1. 获取 `AppTheme.lightTheme` 返回的 `ThemeData` 实例
2. 验证 `themeData.useMaterial3` 为 `true`
3. 验证 `themeData.colorScheme` 不为 null
4. 验证 `themeData.colorScheme.brightness` 为 `Brightness.light`
5. 验证 `themeData.brightness` 为 `Brightness.light`
6. 验证主题包含以下关键组件主题（非 null）：
   - `themeData.appBarTheme`
   - `themeData.cardTheme`
   - `themeData.elevatedButtonTheme`
   - `themeData.inputDecorationTheme`
   - `themeData.navigationRailTheme`
   - `themeData.bottomNavigationBarTheme`

**代码验证参考**：
```dart
test('lightTheme uses Material 3 and has light brightness', () {
  final theme = AppTheme.lightTheme;
  expect(theme.useMaterial3, isTrue);
  expect(theme.brightness, equals(Brightness.light));
  expect(theme.colorScheme.brightness, equals(Brightness.light));
});
```

**预期结果**：
- ✅ `useMaterial3` = `true`
- ✅ 所有 `brightness` 属性为 `Brightness.light`
- ✅ 核心组件主题非 null（AppBar、Card、Button、Input）
- ✅ `colorScheme` 由 `ColorScheme.fromSeed()` 生成

**失败判定**：
- ❌ `useMaterial3` 为 `false` 或未设置
- ❌ `brightness` 为 `Brightness.dark`（期望浅色）
- ❌ 任一核心组件主题为 null
- ❌ `colorScheme` 来源不是 `fromSeed()`

---

### TC-002: darkTheme 使用 Material 3 且配置完整

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P0 — CRITICAL**（深色模式基础） |
| **类别** | 主题配置 / Material 3 |
| **关联验收标准** | 深色模式下所有组件使用统一色板 |

**前置条件**：
- `AppTheme.darkTheme` getter 存在

**测试步骤**：

1. 获取 `AppTheme.darkTheme` 返回的 `ThemeData` 实例
2. 验证 `themeData.useMaterial3` 为 `true`
3. 验证 `themeData.colorScheme` 不为 null
4. 验证 `themeData.colorScheme.brightness` 为 `Brightness.dark`
5. 验证 `themeData.brightness` 为 `Brightness.dark`
6. 验证包含与 TC-001 相同的关键组件主题

**代码验证参考**：
```dart
test('darkTheme uses Material 3 and has dark brightness', () {
  final theme = AppTheme.darkTheme;
  expect(theme.useMaterial3, isTrue);
  expect(theme.brightness, equals(Brightness.dark));
  expect(theme.colorScheme.brightness, equals(Brightness.dark));
});
```

**预期结果**：
- ✅ `useMaterial3` = `true`
- ✅ 所有 `brightness` 属性为 `Brightness.dark`
- ✅ 核心组件主题非 null
- ✅ `colorScheme` 由 `ColorScheme.fromSeed()` 生成

**失败判定**：
- ❌ `brightness` 为 `Brightness.light`（期望深色）
- ❌ 深色主题缺少关键组件主题

---

### TC-003: 主色调 Seed Color 为 #1976D2

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P0 — CRITICAL**（品牌色一致性） |
| **类别** | 主题配置 / 颜色 |
| **关联验收标准** | 浅色/深色统一色板 |

**前置条件**：
- `AppTheme.lightTheme` 和 `AppTheme.darkTheme` 均可用

**测试步骤**：

1. 获取 `AppTheme.lightTheme.colorScheme`
2. 验证 `colorScheme.primary` 的主色调来源于 seed `#1976D2`
3. 获取 `AppTheme.darkTheme.colorScheme`
4. 验证深色模式下 `colorScheme.primary` 也是基于同一 seed color 生成的调色板
5. 对比两个 ColorScheme 的 `primary` 值：
   - 浅色模式 `primary` 应为较深的蓝色调（适合白色背景上的亮色元素）
   - 深色模式 `primary` 应为较亮的蓝色调（适合深色背景上的亮色元素）

**Seed Color 来源验证**：
```dart
test('both themes are generated from seed color #1976D2', () {
  const seedColor = Color(0xFF1976D2);

  final lightScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );
  final darkScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );

  final lightTheme = AppTheme.lightTheme;
  final darkTheme = AppTheme.darkTheme;

  // primary 应与基于同一 seed 生成的相同
  expect(lightTheme.colorScheme.primary, equals(lightScheme.primary));
  expect(darkTheme.colorScheme.primary, equals(darkScheme.primary));
});
```

**预期结果**：
- ✅ `lightTheme.colorScheme.primary` 来自 seed `#1976D2`
- ✅ `darkTheme.colorScheme.primary` 来自 seed `#1976D2`
- ✅ 两个主题的 `primary` 色调来自同一 seed color
- ✅ `primary` 颜色不是硬编码的固定值（由 `fromSeed` 动态生成，可能因 Flutter 版本微调）

**失败判定**：
- ❌ 浅色或深色主题使用了不同于 `#1976D2` 的 seed color
- ❌ `primary` 颜色与 seed color 无关（可能使用了 `ColorScheme.light()` 而非 `fromSeed()`）
- ❌ `primary` 被硬编码为固定值

---

### TC-004: ColorScheme 正确生成完整调色板

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 主题配置 / ColorScheme |
| **关联验收标准** | Material 3 全部组件使用统一色板 |

**前置条件**：
- TC-001, TC-002 通过

**测试步骤**：

使用以下检查列表验证 `ColorScheme` 的完整性（浅色和深色分别测试）：

**浅色模式 ColorScheme 验证**：

| 属性 | 检查项 | 期望 |
|------|--------|------|
| `primary` | 不透明颜色 | 基于 seed 的有效 Color |
| `onPrimary` | 与 primary 有足够对比度 | 非透明，alpha = 255 |
| `primaryContainer` | 容器色调 | 非 null |
| `onPrimaryContainer` | 容器文本色 | 非 null |
| `secondary` | 辅助色 | 非 null |
| `onSecondary` | 辅助色文本 | 非 null |
| `surface` | 表面色（浅色应为浅色调） | 明度较高（HSL lightness > 80%） |
| `onSurface` | 表面文本色 | 深色可读 |
| `error` | 错误色 | 红色调 |
| `outline` | 边框色 | 非 null |
| `surfaceContainerHighest` | Material 3 Surface Container | 非 null |

**深色模式 ColorScheme 验证**：

| 属性 | 检查项 | 期望 |
|------|--------|------|
| `surface` | 表面色（深色应为深色调） | 明度较低（HSL lightness < 30%） |
| `onSurface` | 表面文本色 | 浅色可读 |
| `primary` | 亮度适应 | 深色模式下比浅色模式更亮 |

**可访问性验证**：
```dart
test('ColorScheme has sufficient contrast for accessibility', () {
  final lightScheme = AppTheme.lightTheme.colorScheme;
  final darkScheme = AppTheme.darkTheme.colorScheme;

  // light: onSurface 在 surface 上可读（深色文字在浅色背景）
  expect(
    ThemeData.estimateBrightnessForColor(lightScheme.onSurface),
    equals(Brightness.dark),
  );

  // dark: onSurface 在 surface 上可读（浅色文字在深色背景）
  expect(
    ThemeData.estimateBrightnessForColor(darkScheme.onSurface),
    equals(Brightness.light),
  );
});
```

**预期结果**：
- ✅ 所有 Material 3 ColorScheme 关键属性非 null
- ✅ 浅色模式 `surface` 为浅色调（明度高）
- ✅ 深色模式 `surface` 为深色调（明度低）
- ✅ `onSurface` 与 `surface` 有足够的视觉对比度
- ✅ `error` 颜色为红色调
- ✅ `primary` 颜色与 seed `#1976D2` 关联

**失败判定**：
- ❌ 任一关键 ColorScheme 属性为 null
- ❌ 浅色模式下 `surface` 为深色（或深色模式下为浅色）
- ❌ `onSurface` 与 `surface` 对比度不足（相同亮度方向）
- ❌ 浅色和深色的生成方式不同（一个用 `fromSeed` 另一个用 `fromSwatch`）
- ❌ 使用已弃用的 `ColorScheme.light()` / `ColorScheme.dark()` 构造函数

---

## 二、主题 Notifier 测试（ThemeNotifier）（5 项）

> **注意**: ThemeNotifier 使用 Riverpod 3.x `Notifier<ThemeMode>` API（纯同步），
> 与 AsyncNotifier 不同，其 `build()` 和 `state` 操作均为同步。

---

### TC-005: 默认主题为 ThemeMode.system

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P0 — CRITICAL**（默认行为正确性） |
| **类别** | ThemeNotifier / 初始状态 |
| **关联验收标准** | 主题默认跟随系统 |

**前置条件**：
- `ThemeNotifier` 已实现
- `ThemeNotifier` 的 `build()` 方法返回 `ThemeMode.system`
- 使用 ProviderContainer 进行隔离测试

**测试步骤**：

1. 创建 Riverpod `ProviderContainer`
2. 读取 `themeModeProvider` 的当前值
3. 验证初始状态为 `ThemeMode.system`

```dart
test('default theme is ThemeMode.system', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final themeMode = container.read(themeModeProvider);

  expect(themeMode, equals(ThemeMode.system));
});
```

**预期结果**：
- ✅ `build()` 返回 `ThemeMode.system`
- ✅ 首次读取时状态为 `ThemeMode.system`
- ✅ 后续读取返回相同值（除非状态被修改）

**失败判定**：
- ❌ 默认值为 `ThemeMode.light` 或 `ThemeMode.dark`
- ❌ `build()` 抛出异常
- ❌ 状态为 null（`ThemeMode?` 类型）

---

### TC-006: setTheme(ThemeMode.light) 更新状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P0 — CRITICAL**（主题切换核心功能） |
| **类别** | ThemeNotifier / 状态变更 |
| **关联验收标准** | 切换即时生效 |

**前置条件**：
- TC-005 通过（默认状态确认）
- `setTheme(ThemeMode mode)` 方法已实现

**测试步骤**：

1. 创建 ProviderContainer
2. 读取初始状态（确认 = `ThemeMode.system`）
3. 调用 `container.read(themeModeProvider.notifier).setTheme(ThemeMode.light)`
4. 读取更新后的状态
5. 验证状态为 `ThemeMode.light`

```dart
test('setTheme(light) updates state to light', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);

  expect(container.read(themeModeProvider), equals(ThemeMode.light));
});
```

**预期结果**：
- ✅ 调用 `setTheme(ThemeMode.light)` 后状态为 `ThemeMode.light`
- ✅ 状态变更同步生效（即时，无异步延迟）
- ✅ 重复调用 `setTheme(ThemeMode.light)` 时状态保持 `ThemeMode.light`（幂等性）

**失败判定**：
- ❌ 状态未变化或变为其他模式
- ❌ `setTheme()` 抛出异常
- ❌ 状态变更后 `build()` 被意外重新调用并重置为 system

---

### TC-007: setTheme(ThemeMode.dark) 更新状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | ThemeNotifier / 状态变更 |
| **关联验收标准** | 切换即时生效 |

**前置条件**：
- TC-005 通过

**测试步骤**：

1. 创建 ProviderContainer
2. 调用 `setTheme(ThemeMode.dark)`
3. 验证状态为 `ThemeMode.dark`
4. 从 `ThemeMode.dark` 再次切换到 `ThemeMode.light`
5. 验证状态为 `ThemeMode.light`

```dart
test('setTheme(dark) updates state to dark', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
  expect(container.read(themeModeProvider), equals(ThemeMode.dark));

  // switch back
  container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
  expect(container.read(themeModeProvider), equals(ThemeMode.light));
});
```

**预期结果**：
- ✅ 状态正确变更为 `ThemeMode.dark`
- ✅ 可以在三种模式间任意切换
- ✅ 每次切换均为同步操作

**失败判定**：
- ❌ 切换到 dark 后状态仍为 system 或 light
- ❌ 从 dark 切回 light 失败

---

### TC-008: setTheme(ThemeMode.system) 更新状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | ThemeNotifier / 状态变更 |
| **关联验收标准** | 三模式切换完整（浅色/深色/跟随系统） |

**前置条件**：
- TC-005 ~ TC-007 通过

**测试步骤**：

1. 创建 ProviderContainer
2. 切换到 `ThemeMode.dark`
3. 验证状态 = `ThemeMode.dark`
4. 切换到 `ThemeMode.system`
5. 验证状态 = `ThemeMode.system`
6. 全流程：system → light → dark → system，验证每一步状态正确

```dart
test('setTheme(system) updates state to system', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  // full cycle test
  expect(container.read(themeModeProvider), equals(ThemeMode.system));

  container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
  expect(container.read(themeModeProvider), equals(ThemeMode.light));

  container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
  expect(container.read(themeModeProvider), equals(ThemeMode.dark));

  container.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
  expect(container.read(themeModeProvider), equals(ThemeMode.system));
});
```

**预期结果**：
- ✅ 三模式（system ↔ light ↔ dark）可任意切换
- ✅ 每次切换状态正确
- ✅ 不出现状态不一致（如 dark 模式下同步返回 system）

**失败判定**：
- ❌ 全流程中任一环节状态错误
- ❌ system 模式切换失败

---

### TC-009: 主题状态持久化到 shared_preferences

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P0 — CRITICAL**（设置持久化） |
| **类别** | ThemeNotifier / 持久化 |
| **关联验收标准** | 持久化到 shared_preferences |

**前置条件**：
- `shared_preferences` 2.5.5 已在 pubspec.yaml 中声明
- `setTheme()` 方法内部调用 `SharedPreferences` 写入
- `build()` 方法内部从 `SharedPreferences` 读取已保存的偏好
- **注意**: 单元测试中 shared_preferences 需要初始化 mock

**测试步骤**：

**场景 A: 写入验证**：
1. Mock `SharedPreferences` 实例（使用 `SharedPreferences.setMockInitialValues({})`）
2. 创建 ProviderContainer（注入 mock storage）
3. 调用 `setTheme(ThemeMode.light)`
4. 验证 `SharedPreferences` 中 key `'theme_mode'` 的值为 `'light'`（或对应的序列化格式）
5. 调用 `setTheme(ThemeMode.dark)`
6. 验证 key 的值更新为 `'dark'`

**场景 B: 读取验证**：
1. Mock `SharedPreferences` 初始值 `{'theme_mode': 'dark'}`
2. 创建 ProviderContainer
3. 验证 `build()` 返回 `ThemeMode.dark`（而非默认 system）

**场景 C: 无存储记录时回退默认值**：
1. Mock `SharedPreferences` 初始值 `{}`（空存储）
2. 创建 ProviderContainer
3. 验证 `build()` 返回 `ThemeMode.system`

```dart
test('setTheme persists choice to SharedPreferences', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);

  container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
  expect(prefs.getString('theme_mode'), equals('light'));

  container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
  expect(prefs.getString('theme_mode'), equals('dark'));
});

test('build reads persisted theme from SharedPreferences', () async {
  SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);

  expect(container.read(themeModeProvider), equals(ThemeMode.dark));
});

test('build defaults to system when no persisted value', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);

  expect(container.read(themeModeProvider), equals(ThemeMode.system));
});
```

**ThemeMode 序列化方式**（需在实现中定义）：
| ThemeMode 值 | 存储字符串 | 说明 |
|-------------|----------|------|
| `ThemeMode.system` | `'system'` | 默认值 |
| `ThemeMode.light` | `'light'` | |
| `ThemeMode.dark` | `'dark'` | |

**预期结果**：
- ✅ `setTheme()` 写入 SharedPreferences（使用 key `'theme_mode'` 或约定 key）
- ✅ `build()` 从 SharedPreferences 读取已保存值
- ✅ 无存储记录时回退 `ThemeMode.system`
- ✅ 存储的值格式一致（如字符串 `'system'` / `'light'` / `'dark'` 或 int index）

**失败判定**：
- ❌ `setTheme()` 未触发 SharedPreferences 写入
- ❌ `build()` 未从 SharedPreferences 读取（始终返回 system）
- ❌ 存储的 key 名称不匹配读写两端
- ❌ 存储值格式错误导致反序列化失败
- ❌ SharedPreferences 未初始化时崩溃

---

## 三、Widget 主题测试（6 项）

> 这些测试需要搭建 Widget 测试环境（`MaterialApp` + 主题注入）。

---

### TC-010: 浅色模式下 AppBar 背景色符合 Material 3 规范

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | Widget 主题 / AppBar |
| **关联验收标准** | 浅色/深色/跟随系统三模式切换 |

**前置条件**：
- `AppTheme.lightTheme` 已实现
- Widget 测试环境中可构建带主题的 `MaterialApp`

**测试步骤**：

1. 使用 `AppTheme.lightTheme` 构建 `MaterialApp`
2. 在 AppBar 中使用 `pumpWidget` 渲染
3. 验证 AppBar 的背景色

```dart
testWidgets('AppBar background color in light mode', (tester) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: const SizedBox(),
    ),
  ));

  final appBar = tester.widget<AppBar>(find.byType(AppBar));
  final colorScheme = AppTheme.lightTheme.colorScheme;

  // AppBar 背景色应来自 ColorScheme
  // Material 3 默认情况下，AppBar 使用 surface 颜色
  // 如果使用 surfaceTintColor，则验证其存在
  expect(appBar.backgroundColor, isNotNull);

  // 验证 AppBar 的颜色与 ColorScheme 关联
  // 具体颜色取决于 `ColorScheme.fromSeed` 生成结果
  // 以下验证 AppBar 实际使用的是 ColorScheme 中的颜色而非自定义硬编码色
});
```

**预期结果**：
- ✅ AppBar `backgroundColor` 不是透明或 null
- ✅ AppBar 背景色与 `lightTheme.colorScheme.surface` 或 `primaryContainer` 关联
- ✅ AppBar 的 `foregroundColor`（文字/图标颜色）与 `onSurface` 或 `onPrimaryContainer` 一致
- ✅ 不与深色模式背景色相同（浅色背景）

**失败判定**：
- ❌ AppBar 使用硬编码颜色（非来自 ColorScheme）
- ❌ AppBar 背景色在浅色模式下为深色
- ❌ AppBar 不可见（文字与背景颜色相同）

---

### TC-011: 深色模式下 AppBar 背景色符合 Material 3 规范

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | Widget 主题 / AppBar |
| **关联验收标准** | 深色模式下组件颜色正确 |

**前置条件**：
- `AppTheme.darkTheme` 已实现

**测试步骤**：

1. 使用 `AppTheme.darkTheme` 构建 `MaterialApp`
2. 渲染 AppBar widget
3. 验证背景色为深色调（来自 dark ColorScheme）

**预期结果**：
- ✅ AppBar 背景色为深色调（来自 `darkTheme.colorScheme.surface` 或 `primaryContainer` 在深色下的变体）
- ✅ AppBar 文字/图标颜色为浅色调（高对比度）
- ✅ 与浅色模式 AppBar 颜色有明显区别

**失败判定**：
- ❌ 深色模式下 AppBar 使用浅色背景
- ❌ 文字颜色与深色背景不可区分
- ❌ 与浅色模式完全相同的背景色

---

### TC-012: 浅色模式下 Card 颜色正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | Widget 主题 / Card |
| **关联验收标准** | 浅色模式所有组件颜色正确 |

**前置条件**：
- `AppTheme.lightTheme` 已实现

**测试步骤**：

1. 使用 `AppTheme.lightTheme` 构建 `MaterialApp`
2. 渲染 Card widget
3. 验证 Card 的颜色

```dart
testWidgets('Card color in light mode', (tester) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: Card(child: const Text('Card content')),
    ),
  ));

  final card = tester.widget<Card>(find.byType(Card));
  final colorScheme = AppTheme.lightTheme.colorScheme;

  // Card 默认使用 surface 色或 surfaceContainerLow
  expect(card.color, isNotNull);
  // 浅色模式 Card 应为浅色调（HSL lightness > 60%）
});
```

**预期结果**：
- ✅ Card `color` 来自 `lightTheme.cardTheme.color` 或默认使用 `colorScheme.surface`
- ✅ Card 的 `elevation` 或 `shadowColor` 产生适当的阴影效果
- ✅ Card 颜色为浅色调（与浅色背景有明显区分但不太深）

**失败判定**：
- ❌ Card 颜色为深色（在浅色模式下）
- ❌ Card 与背景完全相同（无法区分）
- ❌ Card 没有 elevation/shadow 产生平面视觉

---

### TC-013: 深色模式下 Card 颜色正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | Widget 主题 / Card |
| **关联验收标准** | 深色模式所有组件颜色正确 |

**前置条件**：
- `AppTheme.darkTheme` 已实现

**测试步骤**：

1. 使用 `AppTheme.darkTheme` 构建 `MaterialApp`
2. 渲染 Card widget
3. 验证 Card 颜色为深色调（但比背景略亮，形成层次感）

**Material 3 深色模式 Card 规范**：
- 深色模式下，Card 使用 `surfaceContainerLow` 或 `surfaceContainer`（比 `surface` 稍亮）
- `elevation` 在深色模式下通过颜色亮度变化体现（非阴影）
- Card 的 `shape` 保持与浅色模式一致

**预期结果**：
- ✅ Card 颜色为深色调，但比 Scaffold 背景稍亮
- ✅ 不使用纯黑色（`Color(0xFF000000)`）
- ✅ 与浅色模式 Card 颜色明显不同

**失败判定**：
- ❌ 深色模式下 Card 为浅色/白色
- ❌ Card 颜色与背景完全相同（无层次感）
- ❌ Card 与浅色模式 Card 颜色完全一致

---

### TC-014: system 模式跟随系统主题变化

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P1 — HIGH** |
| **类别** | Widget 主题 / 系统适配 |
| **关联验收标准** | 跟随系统主题自动切换 |

**前置条件**：
- `ThemeMode.system` 通过 `MaterialApp` 的 `themeMode` 参数正确传递
- Widget 测试环境中可通过 `MediaQuery` 的 `platformBrightness` 模拟系统亮度

**测试步骤**：

**场景 A: 系统为浅色模式**：
1. 设置 `MediaQuery` 的 `platformBrightness` = `Brightness.light`
2. 构建 `MaterialApp(themeMode: ThemeMode.system, theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme)`
3. 验证实际使用的主题为 `AppTheme.lightTheme`

**场景 B: 系统为深色模式**：
1. 设置 `MediaQuery` 的 `platformBrightness` = `Brightness.dark`
2. 验证实际使用的主题切换为 `AppTheme.darkTheme`

```dart
testWidgets('system mode follows platform brightness', (tester) async {
  // 场景 A: 系统浅色 → 应用浅色主题
  await tester.pumpWidget(
    MaterialApp(
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          // 验证使用的主题为浅色
          return Text(theme.brightness == Brightness.light ? 'light' : 'dark');
        },
      ),
    ),
  );

  // 默认情况下测试环境的 platformBrightness 跟随系统
  // 可以在测试中通过 MediaQuery widget 覆盖
});

testWidgets('system mode responds to dark platform brightness', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(platformBrightness: Brightness.dark),
      child: MaterialApp(
        themeMode: ThemeMode.system,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return Text(theme.brightness == Brightness.dark ? 'dark' : 'light');
          },
        ),
      ),
    ),
  );

  expect(find.text('dark'), findsOneWidget);
});
```

**预期结果**：
- ✅ `ThemeMode.system` + `platformBrightness.light` = 使用 `lightTheme`
- ✅ `ThemeMode.system` + `platformBrightness.dark` = 使用 `darkTheme`
- ✅ 系统亮度切换时应用主题即时跟随（无需重启）
- ✅ `ThemeMode.light`/`ThemeMode.dark` 不受 `platformBrightness` 影响（固定主题）

**失败判定**：
- ❌ system 模式下始终使用 lightTheme（忽略系统设置）
- ❌ system 模式下始终使用 darkTheme
- ❌ 固定模式（light/dark）也跟随系统变化
- ❌ 系统亮度变化时不更新

---

### TC-014-extra: ThemeMode 在 MaterialApp 中正确传递

| 属性 | 内容 |
|------|------|
| **ID** | TC-014-extra |
| **优先级** | **P0 — CRITICAL** |
| **类别** | Widget 主题 / MaterialApp 集成 |
| **关联验收标准** | 主题切换即时生效 |

**前置条件**：
- ThemeNotifier 已实现
- `MaterialApp.router` 配置中读取 `themeModeProvider`

**测试步骤**：

1. 构建完整的 Widget 测试（`ProviderScope` + `MaterialApp.router`）
2. 注入 `ThemeMode.system` 初始状态
3. 验证 `Theme.of(context).brightness` 为 `Brightness.light`（测试环境默认）
4. 通过 Provider 切换到 `ThemeMode.dark`
5. `pumpAndSettle()` 后验证 `Theme.of(context).brightness` 变为 `Brightness.dark`
6. 切换到 `ThemeMode.light`
7. 验证恢复为 `Brightness.light`

**预期结果**：
- ✅ `MaterialApp.router` 正确读取 `themeModeProvider` 状态并传递 `themeMode` 参数
- ✅ 主题切换使整个 Widget 树更新主题

**失败判定**：
- ❌ `MaterialApp` 的 `themeMode` 被硬编码为固定值
- ❌ Provider 状态变更后主题不更新
- ❌ 路由切换导致主题状态丢失

---

## 四、颜色常量测试（2 项）

---

### TC-015: 颜色常量文件定义正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P1 — HIGH** |
| **类别** | 主题配置 / 颜色常量 |
| **关联验收标准** | 自定义颜色通过颜色常量管理 |

**前置条件**：
- `lib/theme/colors.dart` 已实现

**测试步骤**：

1. 导入 `lib/theme/colors.dart`
2. 验证文件中的颜色常量定义：
   - 所有颜色使用 `const Color(0xAARRGGBB)` 格式
   - 不存在运行时计算的动态颜色

```dart
test('colors.dart defines valid const Color values', () {
  // 验证主色常量
  expect(AppColors.primary, isA<Color>());
  expect(AppColors.primary, equals(const Color(0xFF1976D2)));

  // 验证所有颜色常量都是 const 可用的
  const colors = [
    AppColors.primary,
    // ... 其他颜色常量
  ];
  expect(colors.every((c) => c is Color), isTrue);
});
```

**预期结果**：
- ✅ 颜色使用 `const Color(...)` 定义
- ✅ 主色 `#1976D2` 定义为常量
- ✅ 所有颜色值有效（alpha + RGB 格式）
- ✅ 命名清晰（英文，语义化如 `primary`, `errorRed`, `successGreen` 等）

**失败判定**：
- ❌ 颜色定义在非 const 上下文中
- ❌ 主色常量缺失或值错误
- ❌ 颜色值格式不正确（如缺少 alpha 通道）

---

### TC-016: 颜色常量不与 ColorScheme 冲突

| 属性 | 内容 |
|------|------|
| **ID** | TC-016 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 主题配置 / 颜色常量 |
| **关联验收标准** | 自定义颜色作为 ColorScheme 的补充而非替代 |

**前置条件**：
- TC-015 通过
- `AppTheme.lightTheme` 和 `AppTheme.darkTheme` 均已定义

**测试步骤**：

1. 验证 `AppColors` 中的颜色不与 `ColorScheme` 中的颜色重复定义
2. 自定义颜色应服务于特定用途（如状态指示器颜色、日志级别颜色）：
   - 成功绿: 不同于 `ColorScheme.primary`
   - 警告橙: 不同于 `ColorScheme.error`
   - 信息蓝: 可能与 `ColorScheme.primary` 相关但语义独立

**预期结果**：
- ✅ 自定义颜色有明确的非 ColorScheme 覆盖的用途说明
- ✅ 不在 ColorScheme 可以覆盖的地方使用自定义颜色
- ✅ 自定义颜色在浅色/深色模式下均有适当的值（不因主题而不可见）

**失败判定**：
- ❌ 自定义颜色重复了 ColorScheme 中已有的语义
- ❌ 自定义颜色在某主题模式下不可见
- ❌ 自定义颜色用于组件主题而非 ColorScheme（违背 Material 3 设计）

---

## 五、文字样式测试（2 项）

---

### TC-017: 等宽字体配置正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-017 |
| **优先级** | **P1 — HIGH** |
| **类别** | 主题配置 / 文字样式 |
| **关联验收标准** | 等宽字体用于代码/日志区域 |

**前置条件**：
- `lib/theme/typography.dart` 已实现

**测试步骤**：

1. 获取 typography 配置中的等宽字体 TextStyle
2. 验证 `fontFamily` 包含等宽字体（如 `'RobotoMono'`, `'FiraCode'`, `'monospace'` 等）
3. 验证 `fontFamilyFallback` 包含通用回退字体（如 `'monospace'`）

```dart
test('typography defines monospace font family', () {
  final monoStyle = AppTypography.monospace;

  // 等宽字体名称 — 可能是具体字体或 'monospace' 作为通用回退
  expect(monoStyle.fontFamily, anyOf(
    equals('RobotoMono'),
    equals('FiraCode'),
    equals('monospace'),
    equals('JetBrainsMono'),
  ));
});

test('typography monospace has fallback', () {
  final monoStyle = AppTypography.monospace;
  // 至少有一个回退字体
  expect(monoStyle.fontFamilyFallback, isNotEmpty);
  expect(monoStyle.fontFamilyFallback, contains('monospace'));
});
```

**预期结果**：
- ✅ 等宽字体 `fontFamily` 设置正确
- ✅ 有通用 `'monospace'` 回退字体系
- ✅ 等文字体 `TextStyle` 不可变（const）

**失败判定**：
- ❌ 等宽字体未设置或设置为非等宽字体
- ❌ 没有回退字体（设备不支持特定字体时显示方块）
- ❌ 等宽字体仅通过 `TextStyle` 默认值（未显式配置）

---

### TC-018: 文字样式在主题中正确集成

| 属性 | 内容 |
|------|------|
| **ID** | TC-018 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 主题配置 / 文字样式 |
| **关联验收标准** | 文字样式通过主题 `textTheme` 统一管理 |

**前置条件**：
- TC-017 通过
- `AppTheme.lightTheme` 和 `AppTheme.darkTheme` 均已定义

**测试步骤**：

1. 验证 `lightTheme.textTheme` 包含自定义文字样式
2. 验证 `darkTheme.textTheme` 包含自定义文字样式
3. 验证自定义文字样式（如 monospace）在 `textTheme` 中存在：
   - 可能在自定义命名槽位中（如 `displayLarge`、`bodyLarge` 等）
   - 或通过 `TextTheme` 的某个属性挂载

**预期结果**：
- ✅ 文字样式集成到 `ThemeData.textTheme`
- ✅ 浅色和深色模式下文字颜色随主题自适应

**失败判定**：
- ❌ 文字样式定义但未集成到 ThemeData
- ❌ 深色模式下文字颜色未适应（仍为深色，导致不可见）

---

## 六、ThemeNotifier 边界与异常测试（6 项）

---

### TC-019: SharedPreferences 不可用时回退到默认值

| 属性 | 内容 |
|------|------|
| **ID** | TC-019 |
| **优先级** | **P1 — HIGH** |
| **类别** | ThemeNotifier / 异常处理 |
| **关联验收标准** | 持久化失败不影响正常使用 |

**前置条件**：
- TC-005 ~ TC-009 通过

**测试步骤**：

1. 模拟 `SharedPreferences.getInstance()` 抛出异常
2. 验证 `ThemeNotifier.build()` 不会崩溃
3. 验证回退使用默认值 `ThemeMode.system`

```dart
test('build falls back to system when SharedPreferences unavailable', () {
  // 通过 override Provider 来模拟 SharedPreferences 不可用
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWith((ref) {
      throw Exception('SharedPreferences not available');
    }),
  ]);
  addTearDown(container.dispose);

  // 不应该抛出异常
  expect(
    () => container.read(themeModeProvider),
    returnsNormally,
  );

  // 回退到默认值
  final mode = container.read(themeModeProvider);
  expect(mode, equals(ThemeMode.system));
});
```

**预期结果**：
- ✅ `build()` 不崩溃
- ✅ 回退到 `ThemeMode.system`
- ✅ 后续的 `setTheme()` 调用仍正常工作（即使写入也失败，状态在内存中更新）

**失败判定**：
- ❌ SharedPreferences 异常导致应用崩溃
- ❌ 异常被吞掉但没有回退处理（状态异常）
- ❌ `setTheme()` 因无法持久化而抛出异常

---

### TC-020: 快速连续 setTheme 调用不产生竞态

| 属性 | 内容 |
|------|------|
| **ID** | TC-020 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | ThemeNotifier / 并发安全 |
| **关联验收标准** | 主题切换稳定可靠 |

**前置条件**：
- TC-005 ~ TC-009 通过（Note: ThemeNotifier 是同步 Notifier，无异步竞态）

**测试步骤**：

1. 快速连续调用 `setTheme()`：
   ```dart
   container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
   container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
   container.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
   ```
2. 验证最终状态为最后一次调用的值（`ThemeMode.system`）
3. 验证 SharedPreferences 中的值为 `'system'`（最后一次写入的值）

**预期结果**：
- ✅ 最终状态为最后一次 `setTheme()` 调用的值
- ✅ 没有状态不一致（如显示 light 但存储为 dark）
- ✅ 由于 ThemeNotifier 是同步 Notifier（非 AsyncNotifier），所有调用串行执行，无竞态问题

**失败判定**：
- ❌ 连续调用导致 crash
- ❌ 最终状态不是最后一次调用的值
- ❌ 存储值与内存状态不一致

---

### TC-021: 非法/未知 ThemeMode 值的容错处理

| 属性 | 内容 |
|------|------|
| **ID** | TC-021 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | ThemeNotifier / 容错 |
| **关联验收标准** | 持久化数据损坏时不影响应用 |

**前置条件**：
- TC-009 通过

**测试步骤**：

**场景 A: 存储了无效的字符串值**：
1. Mock `SharedPreferences` 初始值 `{'theme_mode': 'invalid_value'}`
2. 验证 `build()` 回退到 `ThemeMode.system`

**场景 B: 存储了不支持的值（如旧版本格式）**：
1. Mock `SharedPreferences` 初始值 `{'theme_mode': 'SYSTEM'}`（大写）
2. 验证正确解析（大小写不敏感）或回退到 system

**场景 C: 存储了非字符串值**：
1. Mock `SharedPreferences` 初始值 `{'theme_mode': 42}`（int）
2. 验证类型转换错误被正确处理

```dart
test('build handles invalid stored theme value gracefully', () {
  SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
  // 验证回退到默认值而非崩溃
});
```

**预期结果**：
- ✅ 不可识别的存储值回退到 `ThemeMode.system`
- ✅ 不抛出未捕获异常
- ✅ 应用可正常使用

**失败判定**：
- ❌ 无效存储值导致崩溃
- ❌ 无效值被静默接受导致未定义行为

---

### TC-022: ThemeNotifier 的 Provider 类型正确性

| 属性 | 内容 |
|------|------|
| **ID** | TC-022 |
| **优先级** | **P1 — HIGH** |
| **类别** | ThemeNotifier / 类型安全 |
| **关联验收标准** | Riverpod 3.x Notifier API 正确使用 |

**前置条件**：
- `ThemeNotifier` 已实现
- Riverpod 3.x (`flutter_riverpod ^3.3.1`) 已安装

**测试步骤**：

1. 验证 `ThemeNotifier` 继承自 `Notifier<ThemeMode>`（非 `StateNotifier` 或 `AsyncNotifier`）
2. 验证 `themeModeProvider` 的类型为 `NotifierProvider<ThemeNotifier, ThemeMode>` 或 `AutoDisposeNotifierProvider<...>`
3. 验证 `build()` 方法返回类型为 `ThemeMode`
4. 验证通过 `container.read(themeModeProvider.notifier).setTheme(...)` 方式调用

```dart
test('ThemeNotifier uses correct Riverpod 3.x API', () {
  // 类型检查：必须是 Notifier<ThemeMode>
  expect(ThemeNotifier.new, isA<Notifier<ThemeMode> Function()>());

  final container = ProviderContainer();
  addTearDown(container.dispose);

  // 验证 Provider 可正常读写
  final notifier = container.read(themeModeProvider.notifier);
  expect(notifier, isA<ThemeNotifier>());

  // 验证状态类型
  final state = container.read(themeModeProvider);
  expect(state, isA<ThemeMode>());
});
```

**预期结果**：
- ✅ `ThemeNotifier extends Notifier<ThemeMode>`
- ✅ Provider 声明为 `NotifierProvider<ThemeNotifier, ThemeMode>`
- ✅ `build()` 不是 async（同步返回）
- ✅ `setTheme()` 是 void 方法（不是 Future）
- ✅ 不使用已废弃的 `StateNotifierProvider` 或 `ChangeNotifierProvider`

**失败判定**：
- ❌ 使用了旧版 Riverpod 的 `StateNotifier` 或 `StateProvider`
- ❌ `build()` 被声明为 `async`
- ❌ `setTheme()` 返回 `Future<void>`（不必要的异步）

---

### TC-023: 多次读取 themeModeProvider 返回一致状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-023 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | ThemeNotifier / 一致性 |
| **关联验收标准** | Provider 状态管理正确 |

**前置条件**：
- TC-005 ~ TC-008 通过

**测试步骤**：

1. 设置 `ThemeMode.light`
2. 连续多次读取 `themeModeProvider`
3. 验证每次读取返回相同的 `ThemeMode.light`
4. 创建另一个 ProviderContainer
5. 验证新容器读取初始状态（不受前一个容器影响）

**预期结果**：
- ✅ 同一容器内多次读取返回一致状态
- ✅ 不同容器独立管理状态

**失败判定**：
- ❌ 同容器内多次读取返回不同状态
- ❌ 容器间状态泄漏

---

### TC-024: 主题切换后 Widget 树正确重建

| 属性 | 内容 |
|------|------|
| **ID** | TC-024 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | ThemeNotifier / Widget 集成 |
| **关联验收标准** | 主题切换即时生效 |

**前置条件**：
- `MaterialApp.router` 配置了 `themeMode` 从 Provider 读取
- `AppTheme.lightTheme` 和 `AppTheme.darkTheme` 已实现

**测试步骤**：

1. 构建完整 Widget 测试（ProviderScope + MaterialApp.router）
2. 初始状态为 `ThemeMode.light`
3. 验证 `Theme.of(context).brightness` = `Brightness.light`
4. 通过 Provider 切换为 `ThemeMode.dark`
5. `pumpAndSettle()` 等待重建
6. 验证 `Theme.of(context).brightness` = `Brightness.dark`

```dart
testWidgets('theme switch rebuilds widget tree correctly', (tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        themeMode: container.read(themeModeProvider),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );

  // 初始浅色
  final initialBrightness = Theme.of(
    tester.element(find.byType(MaterialApp)),
  ).brightness;
  expect(initialBrightness, equals(Brightness.light));

  // 切换深色
  container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
  await tester.pumpAndSettle();

  final updatedBrightness = Theme.of(
    tester.element(find.byType(MaterialApp)),
  ).brightness;
  expect(updatedBrightness, equals(Brightness.dark));
});
```

**预期结果**：
- ✅ 主题模式切换后 `Theme.of(context)` 即时反映新主题
- ✅ 所有 Widget 重新渲染应用新主题颜色
- ✅ 不需要手动调用 `setState` 或刷新页面

**失败判定**：
- ❌ 切换后 Widget 树未重建（主题未变化）
- ❌ 需要手动刷新页面才生效
- ❌ 部分 Widget 仍使用旧主题

---

## 七、组件主题覆盖验证（4 项）

---

### TC-025: ElevatedButton 主题在浅色模式下正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-025 |
| **优先级** | **P1 — HIGH** |
| **类别** | 组件主题 / Button |
| **关联验收标准** | 按钮样式统一定义、浅色显示正确 |

**前置条件**：
- `AppTheme.lightTheme` 已实现
- ElevatedButton 主题已配置

**测试步骤**：

1. 使用浅色主题渲染 ElevatedButton
2. 验证按钮的 `backgroundColor` 来自 ColorScheme
3. 验证按钮文字颜色与背景有足够对比度
4. 验证按钮的 `shape` 符合 Material 3 规范（圆角）

**预期结果**：
- ✅ 按钮背景色来自 `colorScheme.primary` 或其容器色
- ✅ 按钮文字可见（非透明或与背景相同）
- ✅ 按钮有适当的圆角和 padding

---

### TC-026: ElevatedButton 主题在深色模式下正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-026 |
| **优先级** | **P1 — HIGH** |
| **类别** | 组件主题 / Button |
| **关联验收标准** | 深色模式按钮显示正确 |

**测试步骤**：

1. 使用深色主题渲染 ElevatedButton
2. 验证按钮在深色背景下可见
3. 验证文字与背景有足够对比度

**预期结果**：
- ✅ 按钮颜色适配深色背景（浅色按钮或深色容器色）
- ✅ 文字高对比度可读

---

### TC-027: InputDecoration 主题在浅色/深色模式下正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-027 |
| **优先级** | **P1 — HIGH** |
| **类别** | 组件主题 / TextField |
| **关联验收标准** | 输入框样式统一定义 |

**前置条件**：
- `AppTheme.lightTheme` 和 `darkTheme` 的 `inputDecorationTheme` 已配置

**测试步骤**：

1. 渲染 TextField 组件
2. 验证边框颜色（`border` / `enabledBorder`）来自 ColorScheme
3. 验证聚焦边框颜色（`focusedBorder`）与 primary 颜色相关
4. 分别在浅色和深色模式下测试

**预期结果**：
- ✅ 启用状态边框可见且颜色合适
- ✅ 聚焦状态有明确的视觉反馈（蓝色边框）
- ✅ 文字颜色随主题切换
- ✅ label/hint 文字颜色在两种主题下均可读

**失败判定**：
- ❌ 输入框边框与背景相同（不可见）
- ❌ 聚焦和非聚焦状态无视觉区分
- ❌ 提示文字在深色模式下不可见

---

### TC-028: NavigationRail / BottomNavigationBar 主题正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-028 |
| **优先级** | **P2 — MEDIUM**（与 TASK-004 AppShell 相关） |
| **类别** | 组件主题 / Navigation |
| **关联验收标准** | AppBar、NavigationRail、BottomNavigationBar 主题 |

**前置条件**：
- `AppTheme.lightTheme` 的 `navigationRailTheme` 和 `bottomNavigationBarTheme` 已配置

**测试步骤**：

1. 渲染 NavigationRail 在浅色主题中
2. 验证选中项指示器颜色来自 `colorScheme.primary` 或 `secondary`
3. 渲染 NavigationRail 在深色主题中
4. 同样验证颜色正确
5. 对 BottomNavigationBar 执行相同测试

**预期结果**：
- ✅ NavigationRail 的 `indicatorColor` 与主题协调
- ✅ 选中/未选中标签可见
- ✅ 深色模式下导航栏颜色适配

---

## 八、测试执行记录模板

> **sw-mike 在测试执行阶段填写**

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | lightTheme Material 3 配置 |
| TC-002 | | | ⬜ 待执行 | darkTheme Material 3 配置 |
| TC-003 | | | ⬜ 待执行 | 主色调 Seed Color |
| TC-004 | | | ⬜ 待执行 | ColorScheme 完整性 |
| TC-005 | | | ⬜ 待执行 | 默认主题 system |
| TC-006 | | | ⬜ 待执行 | setTheme(light) |
| TC-007 | | | ⬜ 待执行 | setTheme(dark) |
| TC-008 | | | ⬜ 待执行 | setTheme(system) |
| TC-009 | | | ⬜ 待执行 | SharedPreferences 持久化 |
| TC-010 | | | ⬜ 待执行 | 浅色 AppBar |
| TC-011 | | | ⬜ 待执行 | 深色 AppBar |
| TC-012 | | | ⬜ 待执行 | 浅色 Card |
| TC-013 | | | ⬜ 待执行 | 深色 Card |
| TC-014 | | | ⬜ 待执行 | system 模式跟随系统 |
| TC-014-extra | | | ⬜ 待执行 | ThemeMode 在 MaterialApp 传递 |
| TC-015 | | | ⬜ 待执行 | 颜色常量定义 |
| TC-016 | | | ⬜ 待执行 | 颜色常量不冲突 |
| TC-017 | | | ⬜ 待执行 | 等宽字体配置 |
| TC-018 | | | ⬜ 待执行 | 文字样式主题集成 |
| TC-019 | | | ⬜ 待执行 | SharedPreferences 不可用回退 |
| TC-020 | | | ⬜ 待执行 | 快速连续 setTheme |
| TC-021 | | | ⬜ 待执行 | 非法 ThemeMode 容错 |
| TC-022 | | | ⬜ 待执行 | Riverpod 3.x API 类型正确性 |
| TC-023 | | | ⬜ 待执行 | 多次读取一致性 |
| TC-024 | | | ⬜ 待执行 | Widget 树重建验证 |
| TC-025 | | | ⬜ 待执行 | ElevatedButton 浅色主题 |
| TC-026 | | | ⬜ 待执行 | ElevatedButton 深色主题 |
| TC-027 | | | ⬜ 待执行 | InputDecoration 主题 |
| TC-028 | | | ⬜ 待执行 | NavigationRail/BNB 主题 |

---

## 九、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| 主题配置测试 | 4 | TC-001 ~ TC-004 |
| 主题 Notifier 测试 | 5 | TC-005 ~ TC-009 |
| Widget 主题测试 | 5 | TC-010 ~ TC-014, TC-014-extra |
| 颜色常量测试 | 2 | TC-015 ~ TC-016 |
| 文字样式测试 | 2 | TC-017 ~ TC-018 |
| ThemeNotifier 边界与异常测试 | 6 | TC-019 ~ TC-024 |
| 组件主题覆盖验证 | 4 | TC-025 ~ TC-028 |
| **合计** | **28** | |

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 13 |
| P1 — HIGH | 9 |
| P2 — MEDIUM | 6 |

---

## 十、可追溯性矩阵

| 验收标准（来自 tasks.md） | 对应测试用例 |
|--------------------------|------------|
| 浅色/深色/跟随系统三模式切换 | TC-001, TC-002, TC-005, TC-006, TC-007, TC-008 |
| 切换即时生效 | TC-006, TC-007, TC-008, TC-020, TC-024 |
| 所有 Material 3 组件使用统一色板 | TC-001, TC-002, TC-003, TC-004, TC-010 ~ TC-013 |
| 持久化到 shared_preferences | TC-009, TC-019 |
| 主色 #1976D2 | TC-003 |
| ThemeNotifier 使用 NotifierProvider 管理 | TC-022, TC-023 |
| 等宽字体用于代码/日志区域 | TC-017 |
| `ColorScheme.fromSeed` 生成完整调色板 | TC-003, TC-004 |
| AppBar、NavigationRail、BottomNavigationBar 主题 | TC-010, TC-011, TC-028 |
| 按钮样式、输入框样式、卡片样式统一定义 | TC-012, TC-013, TC-025, TC-026, TC-027 |

| PRD 验收标准（§11.3） | 对应测试用例 |
|----------------------|------------|
| #32 用户可以切换浅色/深色主题 | TC-005 ~ TC-009, TC-024 |
| #34 主题切换立即生效并持久化 | TC-009, TC-024 |
| #43 浅色/深色主题在所有页面上显示正确 | TC-010 ~ TC-013, TC-025 ~ TC-028 |

---

## 十一、附录 A：测试架构参考

### A.1 ThemeNotifier 单元测试设置

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 创建测试用的 ProviderContainer
/// 可注入 SharedPreferences mock
ProviderContainer createTestContainer({
  Map<String, Object>? sharedPrefsValues,
}) {
  SharedPreferences.setMockInitialValues(sharedPrefsValues ?? {});
  // 注意：shared_preferences 需要预先通过 setMockInitialValues 设置
  // 并在 Provider 中正确 overrides
  final container = ProviderContainer();
  return container;
}

/// 验证 ThemeMode 枚举值与存储字符串的双向转换
void verifyThemeModeSerialization() {
  // 定义序列化函数（应与实现一致）
  String themeModeToString(ThemeMode mode) => mode.name;
  // ThemeMode.system.name => 'system'
  // ThemeMode.light.name => 'light'
  // ThemeMode.dark.name  => 'dark'

  // 定义反序列化函数
  ThemeMode stringToThemeMode(String? value) {
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  // 验证
  expect(themeModeToString(ThemeMode.system), 'system');
  expect(themeModeToString(ThemeMode.light), 'light');
  expect(themeModeToString(ThemeMode.dark), 'dark');
  expect(stringToThemeMode('system'), ThemeMode.system);
  expect(stringToThemeMode('light'), ThemeMode.light);
  expect(stringToThemeMode('dark'), ThemeMode.dark);
  expect(stringToThemeMode('invalid'), ThemeMode.system);
  expect(stringToThemeMode(null), ThemeMode.system);
}
```

### A.2 Widget 主题测试设置

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 用于测试主题的 Widget 包装器
Widget wrapWithTheme({
  required Widget child,
  required ThemeData theme,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    theme: theme,
    darkTheme: theme, // 简化：深色 = 浅色（或使用真实 darkTheme）
    themeMode: themeMode,
    home: Scaffold(body: child),
  );
}

/// 验证组件的背景色来自 ColorScheme
void expectColorFromScheme(Color actual, Color expected) {
  expect(actual, equals(expected));
}

/// 获取组件背景色的辅助函数
Color? getBackgroundColor(WidgetTester tester, Type widgetType) {
  final widget = tester.widget(widgetType);
  if (widget is AppBar) return widget.backgroundColor;
  if (widget is Card) return widget.color;
  if (widget is ElevatedButton) {
    final style = widget.style;
    if (style != null) {
      // ButtonStyle 的 backgroundColor 是 MaterialStateProperty
      return style.backgroundColor?.resolve({});
    }
  }
  return null;
}
```

### A.3 ThemeMode 测试完整流程

```dart
testWidgets('full theme cycle test', (tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        themeMode: container.read(themeModeProvider),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: createTestRouter(),
      ),
    ),
  );

  // 阶段 1: 初始 system（测试环境默认 light）
  Brightness getBrightness() =>
      Theme.of(tester.element(find.byType(MaterialApp))).brightness;

  expect(getBrightness(), equals(Brightness.light));

  // 阶段 2: 强制 light
  container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
  await tester.pumpAndSettle();
  expect(getBrightness(), equals(Brightness.light));

  // 阶段 3: 强制 dark
  container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
  await tester.pumpAndSettle();
  expect(getBrightness(), equals(Brightness.dark));

  // 阶段 4: 回到 system
  container.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
  await tester.pumpAndSettle();
  expect(getBrightness(), equals(Brightness.light)); // 测试环境默认 light
});
```

### A.4 测试文件组织

```
kayak-frontend/test/
├── theme/
│   ├── app_theme_test.dart              # TC-001 ~ TC-004, TC-015 ~ TC-016
│   ├── colors_test.dart                 # TC-015 ~ TC-016
│   ├── typography_test.dart             # TC-017 ~ TC-018
│   ├── theme_notifier_test.dart         # TC-005 ~ TC-009, TC-019 ~ TC-023
│   └── theme_integration_test.dart      # TC-010 ~ TC-014, TC-024 ~ TC-028
└── helpers/
    └── theme_test_helpers.dart          # 主题测试辅助函数
```

---

## 十二、附录 B：注意事项

### B.1 Material 3 ColorScheme.fromSeed 特性

- `ColorScheme.fromSeed()` 生成的调色板因 Flutter 版本不同可能略有差异
- 测试应验证**结构性正确**（brightness、useMaterial3、关键属性非 null），而非断言精确颜色值
- 如需断言精确颜色，使用自定义 ColorScheme 构造函数而非 `fromSeed()`

### B.2 Riverpod 3.x Notifier vs 旧版 StateNotifier

| 特性 | StateNotifier (v1/v2) | Notifier (v3) | ThemeNotifier 选择 |
|------|----------------------|---------------|-------------------|
| 类型 | class extends StateNotifier\<T\> | class extends Notifier\<T\> | ✅ Notifier\<ThemeMode\> |
| build() | 无 | 必须实现 `T build()` | ✅ 返回 `ThemeMode.system` |
| ref 访问 | 需要 `Ref` 参数 | 内置 `ref` 属性 | ✅ 读取 SharedPreferences |
| Provider 声明 | `StateNotifierProvider` | `NotifierProvider` | ✅ `NotifierProvider` |

### B.3 shared_preferences 测试限制

- `SharedPreferences.setMockInitialValues()` 必须在读取前调用
- 在 Widget 测试中使用 `SharedPreferences` 需要先 mock
- 单元测试中推荐使用 Provider 的 `overrideWithValue` 注入 mock 实例
- 如果 ThemeNotifier 的 `build()` 中同步调用 `SharedPreferences.getInstance()`，需要使用 mock

---

**文档状态**: ✅ 已完成，待 sw-tom 审查
**用例总数**: 28
**下一步**: sw-tom 审查测试用例 → sw-tom 实现 TASK-005 → sw-mike 执行测试
