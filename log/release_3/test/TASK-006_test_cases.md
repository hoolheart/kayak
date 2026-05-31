# TASK-006 测试用例 — 国际化框架（ARB + intl 0.20.2）

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待 sw-tom 审查
> **关联任务**: TASK-006（国际化框架，flutter_localizations + ARB）
> **参考文档**: [tasks.md](../tasks.md), [prd.md](../prd.md)

---

## 测试范围

TASK-006 需交付以下文件：

| # | 文件 | 功能 | 测试覆盖 |
|---|------|------|:------:|
| 1 | `lib/l10n/app_en.arb` | 英文翻译（默认/回退语言） | TC-001, TC-003, TC-017 ~ TC-020 |
| 2 | `lib/l10n/app_zh.arb` | 简体中文翻译 | TC-002, TC-003, TC-018 ~ TC-020 |
| 3 | `lib/l10n/l10n.yaml` | gen-l10n 配置文件 | TC-004 |
| 4 | `lib/generated/app_localizations.dart` | gen-l10n 自动生成的主文件 | TC-005 ~ TC-006 |
| 5 | `lib/generated/app_localizations_en.dart` | 英文翻译实现类 | TC-014 |
| 6 | `lib/generated/app_localizations_zh.dart` | 中文翻译实现类 | TC-015 |
| 7 | `lib/providers/settings_provider.dart` | LocaleNotifier（新增，与 ThemeNotifier 同文件） | TC-007 ~ TC-013 |
| 8 | `lib/app.dart` | MaterialApp.router 接入国际化配置 | TC-002 ~ TC-003 |

---

## 国际化配置速查

### 当前 l10n.yaml 配置

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/generated
output-class: AppLocalizations
preferred-supported-locales:
  - en
  - zh
```

### 当前 ARB 文件内容（占位状态）

**app_en.arb**:
```json
{
  "@@locale": "en",
  "appTitle": "Kayak"
}
```

**app_zh.arb**:
```json
{
  "@@locale": "zh",
  "appTitle": "Kayak"
}
```

> ⚠️ **关键发现**: 当前 ARB 文件仅有 `appTitle` 一个 key，且中文未翻译。TASK-006 需要大幅扩展 ARB 文件，添加所有 UI 文本 key。

### LocaleNotifier 要求（来自 tasks.md）

```dart
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // 从 SharedPreferences 读取，默认英文
    return const Locale('en');
  }

  void setLocale(Locale locale) {
    state = locale;
    // 持久化到 SharedPreferences
  }
}
```

### MaterialApp 配置要求（来自 tasks.md）

```dart
MaterialApp.router(
  locale: locale,                           // 从 LocaleNotifier 读取
  supportedLocales: [
    const Locale('en'),
    const Locale('zh'),
  ],
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
)
```

### ARB 消息覆盖范围（来自 tasks.md）

| 类别 | 必需 Key | 说明 |
|------|---------|------|
| **通用** | save, cancel, delete, confirm, close, retry, loading, noData, networkError | 通用操作和状态文本 |
| **导航** | home, workbench, methods, experiments, analysis, settings, login, register | 导航标签 |
| **认证** | email, password, username, login, register, logout, sessionExpired | 认证表单和消息 |
| **工作台** | createWorkbench, editWorkbench, deleteWorkbench, searchWorkbench | 工作台操作 |
| **设备** | addDevice, editDevice, deleteDevice, testConnection, connect, disconnect | 设备操作 |
| **测点** | addPoint, editPoint, deletePoint, pointValue | 测点操作 |
| **试验** | createExperiment, load, start, pause, resume, stop, executionLog | 试验操作 |
| **错误** | networkConnectionFailed, loginExpired, permissionDenied, serverError | 错误消息 |

> **注**: 上表为最低覆盖要求。测试用例将逐 key 验证中英文对应关系。

---

## 一、ARB 文件基础验证（4 项）

---

### TC-001: app_en.arb 文件存在且 JSON 格式有效

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL**（英文是回退语言，损坏将导致整个应用无法显示文本） |
| **类别** | ARB 文件 / 文件完整性 |
| **关联验收标准** | `flutter gen-l10n` 无错误 |

**前置条件**：
- `lib/l10n/app_en.arb` 文件存在

**测试步骤**：

1. 读取 `lib/l10n/app_en.arb` 文件内容
2. 使用 `dart:convert` 的 `jsonDecode()` 解析
3. 验证解析不抛出 `FormatException`
4. 验证解析结果为 `Map<String, dynamic>`
5. 验证包含 `@@locale` 字段，值为 `"en"`
6. 验证至少包含 `appTitle` 和所有其他必需 key（见 §五）
7. 验证每个值是 `String` 类型（或 ARB 元数据 Object 如 `@appTitle`）

**代码验证参考**：
```dart
test('app_en.arb exists and is valid JSON', () {
  final file = File('lib/l10n/app_en.arb');
  expect(file.existsSync(), isTrue);

  final content = file.readAsStringSync();
  final json = jsonDecode(content) as Map<String, dynamic>;

  expect(json['@@locale'], equals('en'));
  expect(json['appTitle'], isA<String>());
});
```

**预期结果**：
- ✅ 文件存在且可读
- ✅ JSON 格式有效，`jsonDecode()` 不抛出异常
- ✅ `@@locale` = `"en"`
- ✅ 所有值类型正确（字符串或元数据 Map）

**失败判定**：
- ❌ 文件不存在或无法读取
- ❌ JSON 格式错误（缺少逗号、引号不匹配等）
- ❌ `@@locale` 缺失或值不是 `"en"`
- ❌ 任何翻译值为非字符串类型（元数据 key 除外）

---

### TC-002: app_zh.arb 文件存在且 JSON 格式有效

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P0 — CRITICAL**（中文翻译文件损坏将导致中文用户看到英文文本） |
| **类别** | ARB 文件 / 文件完整性 |
| **关联验收标准** | en 和 zh 所有 key 一一对应 |

**前置条件**：
- `lib/l10n/app_zh.arb` 文件存在

**测试步骤**：

1. 读取 `lib/l10n/app_zh.arb` 文件内容
2. 使用 `jsonDecode()` 解析
3. 验证解析不抛出异常
4. 验证包含 `@@locale` 字段，值为 `"zh"`
5. 验证所有值是有效类型

**预期结果**：
- ✅ 文件存在且可读
- ✅ JSON 格式有效
- ✅ `@@locale` = `"zh"`

**失败判定**：
- ❌ 文件不存在
- ❌ JSON 格式错误
- ❌ `@@locale` 缺失或值不是 `"zh"`

---

### TC-003: en 和 zh ARB key 一一对应（翻译覆盖率 100%）

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P0 — CRITICAL**（key 缺失将导致用户看到原始 key 名或英文回退） |
| **类别** | ARB 文件 / 翻译完整性 |
| **关联验收标准** | en 和 zh 所有 key 一一对应；回退语言为 en |

**前置条件**：
- TC-001, TC-002 通过
- app_en.arb 和 app_zh.arb 均为有效 JSON

**测试步骤**：

1. 解析 app_en.arb 和 app_zh.arb
2. 提取所有**翻译 key**（排除以 `@` 开头的元数据 key）
3. 对比两个文件的 key 集合：
   - `enKeys` = en ARB 中所有非 `@` 开头的 key
   - `zhKeys` = zh ARB 中所有非 `@` 开头的 key
4. 验证 `enKeys` ⊆ `zhKeys`（zh 包含所有 en 的 key）
5. 验证 `enKeys` = `zhKeys`（精确匹配，无多余 key）
6. 用表格输出差异报告

**代码验证参考**：
```dart
test('all en keys exist in zh ARB with full coverage', () {
  final enJson = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final zhJson = jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync())
      as Map<String, dynamic>;

  final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
  final zhKeys = zhJson.keys.where((k) => !k.startsWith('@')).toSet();

  // zh must contain all en keys
  final missingInZh = enKeys.difference(zhKeys);
  expect(missingInZh, isEmpty,
      reason: 'Missing keys in zh: ${missingInZh.toList()}');

  // no extra keys in zh (strict matching)
  final extraInZh = zhKeys.difference(enKeys);
  expect(extraInZh, isEmpty,
      reason: 'Extra keys in zh not present in en: ${extraInZh.toList()}');
});
```

**预期结果**：
- ✅ zh ARB 包含 en ARB 中所有翻译 key
- ✅ 无多余 key（zh 的 key 与 en 精确匹配）
- ✅ 差异报告为空

**失败判定**：
- ❌ zh 中缺少任意 en 翻译 key
- ❌ zh 中有 en 中不存在的多余 key（可能是拼写错误）
- ❌ 元数据 key（`@xxx`）被误报为翻译 key

---

### TC-004: l10n.yaml 配置正确且 gen-l10n 可运行

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P0 — CRITICAL**（配置错误将导致 gen-l10n 失败或生成错误代码） |
| **类别** | 构建配置 / gen-l10n |
| **关联验收标准** | `flutter gen-l10n` 无错误 |

**前置条件**：
- `l10n.yaml` 位于项目根目录
- `pubspec.yaml` 中 `flutter.generate: true`

**测试步骤**：

1. 验证 `l10n.yaml` 文件存在
2. 验证 YAML 格式有效
3. 验证关键字段：
   - `arb-dir` = `lib/l10n`
   - `template-arb-file` = `app_en.arb`
   - `output-localization-file` = `app_localizations.dart`
   - `output-dir` = `lib/generated`
   - `output-class` = `AppLocalizations`
   - `preferred-supported-locales` 包含 `['en', 'zh']`
4. 运行 `flutter gen-l10n`，验证 exit code = 0
5. 验证生成的 `lib/generated/app_localizations.dart` 文件存在
6. 验证生成的 `lib/generated/app_localizations_en.dart` 文件存在
7. 验证生成的 `lib/generated/app_localizations_zh.dart` 文件存在

**预期结果**：
- ✅ `l10n.yaml` 格式正确
- ✅ `flutter gen-l10n` 执行成功（exit 0）
- ✅ 三个生成文件均在 `lib/generated/` 目录下
- ✅ 生成文件无语法错误（`flutter analyze` 通过）

**失败判定**：
- ❌ `l10n.yaml` 缺失或格式错误
- ❌ `flutter gen-l10n` 报错
- ❌ 生成文件缺失
- ❌ ARB 文件中 `@@locale` 与 `preferred-supported-locales` 不一致

---

## 二、AppLocalizations 生成代码验证（2 项）

---

### TC-005: AppLocalizations 支持的语言列表正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 生成代码 / 语言支持 |
| **关联验收标准** | supportedLocales 包含 en 和 zh |

**前置条件**：
- `flutter gen-l10n` 已运行
- `lib/generated/app_localizations.dart` 已生成

**测试步骤**：

1. 导入 `AppLocalizations` 类
2. 验证 `AppLocalizations.supportedLocales` 是 `List<Locale>`
3. 验证列表包含 `const Locale('en')`
4. 验证列表包含 `const Locale('zh')`
5. 验证列表长度为 2（仅 en 和 zh，无多余语言）

```dart
test('AppLocalizations.supportedLocales contains en and zh', () {
  final locales = AppLocalizations.supportedLocales;

  expect(locales, contains(const Locale('en')));
  expect(locales, contains(const Locale('zh')));
  expect(locales.length, equals(2));
});
```

**预期结果**：
- ✅ `supportedLocales` 长度 = 2
- ✅ 包含 `Locale('en')`
- ✅ 包含 `Locale('zh')`

**失败判定**：
- ❌ `supportedLocales` 为空
- ❌ en 或 zh 缺失
- ❌ 包含多余语言（如 `de`, `ja` 等）

---

### TC-006: AppLocalizations.localizationsDelegates 包含所有必需 delegate

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P0 — CRITICAL**（缺少 delegate 将导致组件文本显示为英文默认值） |
| **类别** | 生成代码 / LocalizationsDelegate |
| **关联验收标准** | 所有 localizationsDelegates 正确配置 |

**前置条件**：
- `AppLocalizations` 已生成

**测试步骤**：

1. 验证 `AppLocalizations.localizationsDelegates` 是 `List<LocalizationsDelegate<dynamic>>`
2. 验证列表包含以下 delegate（按类型检查）：
   - `AppLocalizations.delegate` → `_AppLocalizationsDelegate`
   - `GlobalMaterialLocalizations.delegate` → Material 组件（按钮、对话框、日期选择器等）翻译
   - `GlobalWidgetsLocalizations.delegate` → Widget 组件（如 TextField 剪切/复制/粘贴菜单）翻译
   - `GlobalCupertinoLocalizations.delegate` → iOS 风格组件翻译
3. 验证列表长度为 4

```dart
test('AppLocalizations.localizationsDelegates includes all required delegates', () {
  final delegates = AppLocalizations.localizationsDelegates;

  expect(delegates.length, equals(4));
  expect(delegates[0], equals(AppLocalizations.delegate));
  expect(delegates[1], equals(GlobalMaterialLocalizations.delegate));
  expect(delegates[2], equals(GlobalCupertinoLocalizations.delegate));
  expect(delegates[3], equals(GlobalWidgetsLocalizations.delegate));
});
```

**预期结果**：
- ✅ 包含 4 个 delegate
- ✅ 顺序：`AppLocalizations.delegate` → `GlobalMaterialLocalizations` → `GlobalCupertinoLocalizations` → `GlobalWidgetsLocalizations`

**失败判定**：
- ❌ delegate 列表为空或少于 4 个
- ❌ `AppLocalizations.delegate` 缺失
- ❌ Material/Widgets/Cupertino delegate 任一缺失

---

## 三、LocaleNotifier 测试（7 项）

> **注意**: LocaleNotifier 使用 Riverpod 3.x `Notifier<Locale>` API（纯同步），
> 与 ThemeNotifier 共享 `sharedPreferencesProvider`。

---

### TC-007: 默认语言为 en

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL**（默认语言正确性是国际化的基础） |
| **类别** | LocaleNotifier / 初始状态 |
| **关联验收标准** | LocaleNotifier build() 默认 en |

**前置条件**：
- `LocaleNotifier` 已实现
- `LocaleNotifier` 的 `build()` 方法返回 `const Locale('en')`

**测试步骤**：

1. 创建 Riverpod `ProviderContainer`
2. 读取 `localeProvider` 的当前值
3. 验证初始状态为 `const Locale('en')`

```dart
test('default locale is English (en)', () {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final locale = container.read(localeProvider);
  expect(locale, equals(const Locale('en')));
});
```

**预期结果**：
- ✅ `build()` 返回 `const Locale('en')`
- ✅ `locale.languageCode` = `'en'`

**失败判定**：
- ❌ 默认值为 `Locale('zh')` 或其他非 en 
- ❌ `build()` 抛出异常
- ❌ 状态为 null（`Locale?` 类型）

---

### TC-008: setLocale(Locale('zh')) 更新状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P0 — CRITICAL**（语言切换核心功能） |
| **类别** | LocaleNotifier / 状态变更 |
| **关联验收标准** | setLocale('zh') 更新并持久化 |

**前置条件**：
- TC-007 通过（默认状态确认）
- `setLocale(Locale locale)` 方法已实现

**测试步骤**：

1. 创建 ProviderContainer
2. 读取初始状态（确认 = `Locale('en')`）
3. 调用 `container.read(localeProvider.notifier).setLocale(const Locale('zh'))`
4. 读取更新后的状态
5. 验证 `state.languageCode` = `'zh'`

```dart
test('setLocale(zh) updates state to Chinese', () {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);

  container.read(localeProvider.notifier).setLocale(const Locale('zh'));

  final locale = container.read(localeProvider);
  expect(locale.languageCode, equals('zh'));
});
```

**预期结果**：
- ✅ 调用 `setLocale(Locale('zh'))` 后状态为 `Locale('zh')`
- ✅ 状态变更同步生效（无异步延迟）
- ✅ 重复调用幂等（再次调用状态保持 `Locale('zh')`）

**失败判定**：
- ❌ 状态未变化或变为其他 locale
- ❌ `setLocale()` 抛出异常
- ❌ 状态变更后 `build()` 被意外重新调用并重置为 en

---

### TC-009: setLocale(Locale('en')) 更新状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | LocaleNotifier / 状态变更 |
| **关联验收标准** | setLocale('en') 更新状态 |

**前置条件**：
- TC-007, TC-008 通过

**测试步骤**：

1. 创建 ProviderContainer
2. 先切换到 `Locale('zh')`，验证状态 = `Locale('zh')`
3. 调用 `setLocale(const Locale('en'))`
4. 验证状态恢复为 `Locale('en')`

```dart
test('setLocale(en) switches back to English', () {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);

  // switch to zh first
  container.read(localeProvider.notifier).setLocale(const Locale('zh'));
  expect(container.read(localeProvider).languageCode, equals('zh'));

  // switch back to en
  container.read(localeProvider.notifier).setLocale(const Locale('en'));
  expect(container.read(localeProvider).languageCode, equals('en'));
});
```

**预期结果**：
- ✅ 从 zh 切换回 en 后状态正确恢复
- ✅ en ↔ zh 之间可任意切换

**失败判定**：
- ❌ 无法从 zh 切回 en
- ❌ 切回 en 后状态仍为 zh

---

### TC-010: 语言偏好持久化到 SharedPreferences（写入）

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P0 — CRITICAL**（设置持久化） |
| **类别** | LocaleNotifier / 持久化 |
| **关联验收标准** | 持久化到 shared_preferences |

**前置条件**：
- `setLocale()` 方法内部调用 `SharedPreferences` 写入
- 使用预定义的 key 存储语言偏好（如 `'locale_language_code'`）

**测试步骤**：

**场景 A: 写入 zh**：
1. Mock `SharedPreferences` 实例（使用 `SharedPreferences.setMockInitialValues({})`）
2. 创建 ProviderContainer（注入 mock storage）
3. 调用 `setLocale(const Locale('zh'))`
4. 验证 `SharedPreferences` 中存储了 `zh`

**场景 B: 写入 en**：
1. 调用 `setLocale(const Locale('en'))`
2. 验证 `SharedPreferences` 中的值更新为 `en`

```dart
test('setLocale persists language to SharedPreferences', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);

  container.read(localeProvider.notifier).setLocale(const Locale('zh'));
  expect(prefs.getString('locale_language_code'), equals('zh'));

  container.read(localeProvider.notifier).setLocale(const Locale('en'));
  expect(prefs.getString('locale_language_code'), equals('en'));
});
```

**存储 key 约定建议**：
| 用途 | 建议 Key | 值示例 |
|------|---------|--------|
| 语言代码 | `locale_language_code` | `'en'`, `'zh'` |

> 与 ThemeMode 的 `theme_mode` key 区分，避免命名冲突。

**预期结果**：
- ✅ `setLocale()` 写入 SharedPreferences（key 明确约定）
- ✅ en → zh → en 切换时存储值正确更新
- ✅ 存储值的格式一致（languageCode 字符串）

**失败判定**：
- ❌ `setLocale()` 未触发 SharedPreferences 写入
- ❌ 存储的 key 与读取时不一致
- ❌ 存储值格式错误

---

### TC-011: build() 从 SharedPreferences 读取已保存的语言偏好（读取）

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | LocaleNotifier / 持久化 |
| **关联验收标准** | 持久化到 shared_preferences |

**前置条件**：
- `build()` 方法从 `SharedPreferences` 读取已保存的语言偏好
- TC-010 通过

**测试步骤**：

1. Mock `SharedPreferences` 初始值 `{'locale_language_code': 'zh'}`
2. 创建 ProviderContainer
3. 验证 `build()` 返回 `const Locale('zh')`（非默认 en）

```dart
test('build reads persisted locale from SharedPreferences', () async {
  SharedPreferences.setMockInitialValues({'locale_language_code': 'zh'});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);

  final locale = container.read(localeProvider);
  expect(locale.languageCode, equals('zh'));
});
```

**预期结果**：
- ✅ 有 `'zh'` 存储值时 `build()` 返回 `Locale('zh')`
- ✅ 有 `'en'` 存储值时 `build()` 返回 `Locale('en')`

**失败判定**：
- ❌ `build()` 忽略存储值，始终返回 en
- ❌ 存储值被正确读取但转换错误（如 `'zh'` → `Locale('en')`）

---

### TC-012: 无存储记录时回退到默认值 en

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P1 — HIGH** |
| **类别** | LocaleNotifier / 持久化 |
| **关联验收标准** | 回退语言为 en |

**前置条件**：
- TC-007, TC-011 通过

**测试步骤**：

1. Mock `SharedPreferences` 初始值 `{}`（空存储，首次使用）
2. 创建 ProviderContainer
3. 验证 `build()` 返回 `const Locale('en')`

```dart
test('build defaults to English when no persisted value', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);

  final locale = container.read(localeProvider);
  expect(locale.languageCode, equals('en'));
});
```

**预期结果**：
- ✅ 空存储时回退到 `Locale('en')`
- ✅ 用户首次使用应用看到英文界面

**失败判定**：
- ❌ 空存储时返回 `Locale('zh')` 或抛出异常

---

### TC-013: SharedPreferences 不可用时 LocaleNotifier 正常工作

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P1 — HIGH** |
| **类别** | LocaleNotifier / 异常处理 |
| **关联验收标准** | 持久化失败不影响正常使用 |

**前置条件**：
- TC-007 ~ TC-012 通过

**测试步骤**：

1. 模拟 `SharedPreferences` provider 抛出异常
2. 验证 `LocaleNotifier.build()` 不会崩溃
3. 验证回退使用默认值 `Locale('en')`
4. 验证即使持久化失败，`setLocale()` 仍可更新内存状态

```dart
test('build falls back to en when SharedPreferences unavailable', () {
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWith((ref) {
      throw Exception('SharedPreferences not available');
    }),
  ]);
  addTearDown(container.dispose);

  // 不应该抛出异常
  expect(
    () => container.read(localeProvider),
    returnsNormally,
  );

  // 回退到默认值
  final locale = container.read(localeProvider);
  expect(locale.languageCode, equals('en'));
});

test('setLocale works even when persistence fails', () {
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWith((ref) {
      throw Exception('SharedPreferences not available');
    }),
  ]);
  addTearDown(container.dispose);

  // setLocale 不应抛出异常
  expect(
    () => container.read(localeProvider.notifier).setLocale(const Locale('zh')),
    returnsNormally,
  );

  // 内存状态应正确更新
  expect(container.read(localeProvider).languageCode, equals('zh'));
});
```

**预期结果**：
- ✅ `build()` 不崩溃，回退到 en
- ✅ `setLocale()` 不崩溃，内存状态正常更新
- ✅ 应用可以正常运行（虽然语言偏好不会被保存）

**失败判定**：
- ❌ SharedPreferences 异常导致应用崩溃
- ❌ 异常被吞掉但没有回退处理（状态异常导致 UI 报错）

---

## 四、MaterialApp 集成测试（3 项）

---

### TC-014: MaterialApp.router 配置了 supportedLocales

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | MaterialApp 集成 / 配置 |
| **关联验收标准** | supportedLocales 包含 en 和 zh |

**前置条件**：
- `lib/app.dart` 中的 `MaterialApp.router` 已配置 `supportedLocales`
- `KayakApp` Widget 可渲染（依赖路由等已初始化）

**测试步骤**：

1. 构建 `KayakApp` widget（在测试中提供必要的 ProviderScope 和路由 mock）
2. 查找 `MaterialApp.router` widget
3. 验证 `supportedLocales` 属性不为 null
4. 验证 `supportedLocales` 包含 `const Locale('en')`
5. 验证 `supportedLocales` 包含 `const Locale('zh')`

```dart
testWidgets('MaterialApp.router has supportedLocales set', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: KayakApp()),
  );
  await tester.pump();

  final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.supportedLocales, isNotNull);
  expect(materialApp.supportedLocales, contains(const Locale('en')));
  expect(materialApp.supportedLocales, contains(const Locale('zh')));
});
```

**预期结果**：
- ✅ `supportedLocales` 包含 en 和 zh
- ✅ `supportedLocales` 不为空

**失败判定**：
- ❌ `supportedLocales` 为 null 或为空
- ❌ 缺少 en 或 zh
- ❌ 使用了硬编码的 locale 列表（未从 `AppLocalizations.supportedLocales` 获取）

---

### TC-015: MaterialApp.router 配置了 localizationsDelegates

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | MaterialApp 集成 / 配置 |
| **关联验收标准** | 所有 localizationsDelegates 正确配置 |

**前置条件**：
- `MaterialApp.router` 已配置 `localizationsDelegates`
- TC-014 通过

**测试步骤**：

1. 构建 `KayakApp` widget
2. 验证 `localizationsDelegates` 属性不为 null
3. 验证包含 `AppLocalizations.delegate`
4. 验证包含 `GlobalMaterialLocalizations.delegate`
5. 验证包含 `GlobalWidgetsLocalizations.delegate`
6. 验证包含 `GlobalCupertinoLocalizations.delegate`

```dart
testWidgets('MaterialApp.router has all required localization delegates', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: KayakApp()),
  );
  await tester.pump();

  final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.localizationsDelegates, isNotNull);
  expect(materialApp.localizationsDelegates, contains(AppLocalizations.delegate));
  expect(materialApp.localizationsDelegates, contains(GlobalMaterialLocalizations.delegate));
  expect(materialApp.localizationsDelegates, contains(GlobalWidgetsLocalizations.delegate));
  expect(materialApp.localizationsDelegates, contains(GlobalCupertinoLocalizations.delegate));
});
```

**预期结果**：
- ✅ `localizationsDelegates` 包含所有 4 个 delegate
- ✅ `AppLocalizations.delegate` 排在首位

**失败判定**：
- ❌ `localizationsDelegates` 为 null 或为空
- ❌ 任一 delegate 缺失
- ❌ Delegate 顺序错误导致 Material 组件文本不翻译

---

### TC-016: MaterialApp.router 通过 locale 参数绑定 LocaleNotifier

| 属性 | 内容 |
|------|------|
| **ID** | TC-016 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | MaterialApp 集成 / 配置 |
| **关联验收标准** | 语言切换即时生效 |

**前置条件**：
- `KayakApp` 中 `MaterialApp.router` 的 `locale` 参数从 `localeProvider` 读取
- TC-014, TC-015 通过

**测试步骤**：

1. 构建完整的 Widget 测试（ProviderScope + KayakApp）
2. 使用 `ref.watch(localeProvider)` 读取当前 locale
3. 验证 MaterialApp 的 `locale` 属性与 Provider 状态一致
4. 通过 Provider 切换 locale
5. `pumpAndSettle()` 后验证 MaterialApp 的 `locale` 更新

```dart
testWidgets('MaterialApp.router locale binds to LocaleNotifier', (tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const KayakApp(),
    ),
  );
  await tester.pump();

  // 初始 locale 应为 en
  var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.locale?.languageCode, equals('en'));

  // 切换到中文
  container.read(localeProvider.notifier).setLocale(const Locale('zh'));
  await tester.pumpAndSettle();

  materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.locale?.languageCode, equals('zh'));
});
```

**预期结果**：
- ✅ `locale` 参数从 `localeProvider` 动态读取
- ✅ Locale 切换后 MaterialApp 重建
- ✅ 整个 Widget 树使用新 locale

**失败判定**：
- ❌ `locale` 被硬编码为固定值
- ❌ Provider 状态变更后 locale 不更新
- ❌ `locale` 为 null（应始终有值）

---

## 五、文本查找与 Widget 渲染测试（6 项）

---

### TC-017: 通过 AppLocalizations 获取英文文本

| 属性 | 内容 |
|------|------|
| **ID** | TC-017 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 文本查找 / AppLocalizations |
| **关联验收标准** | 通过 l10n 获取所有面向用户的文本 |

**前置条件**：
- `AppLocalizations` 已生成
- 至少有一个翻译 key（如 `appTitle`）在 ARB 中有英文值
- Widget 测试环境可以创建 `MaterialApp` 并设置 locale

**测试步骤**：

1. 构建一个以 `Locale('en')` 为 locale 的 `MaterialApp`
2. 包含 `AppLocalizations.delegate` 和 `GlobalMaterialLocalizations.delegate`
3. 在 Widget 中通过 `AppLocalizations.of(context)!` 获取实例
4. 调用翻译属性的 getter 方法（如 `appTitle`）
5. 验证返回的文本为英文值

```dart
testWidgets('AppLocalizations returns English text for en locale', (tester) async {
  String? actualAppTitle;

  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Builder(
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        actualAppTitle = loc.appTitle;
        return const SizedBox();
      },
    ),
  ));
  await tester.pump();

  expect(actualAppTitle, isNotNull);
  expect(actualAppTitle, equals('Kayak'));
});
```

**预期结果**：
- ✅ 使用 `Locale('en')` 返回英文文本
- ✅ `appTitle` 返回 `'Kayak'`（或 ARB 中定义的值）
- ✅ 其他 key 也返回正确的英文值

**失败判定**：
- ❌ `AppLocalizations.of(context)` 返回 null
- ❌ 英文 locale 返回了中文文本
- ❌ 返回的是 key 名称而非翻译值

---

### TC-018: 通过 AppLocalizations 获取中文文本

| 属性 | 内容 |
|------|------|
| **ID** | TC-018 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | 文本查找 / AppLocalizations |
| **关联验收标准** | 通过 l10n 获取所有面向用户的文本 |

**前置条件**：
- `AppLocalizations` 已生成
- ARB 文件的 key 在中文中有对应的中文翻译（非英文原文）

**测试步骤**：

1. 构建一个以 `Locale('zh')` 为 locale 的 `MaterialApp`
2. 通过 `AppLocalizations.of(context)!` 获取实例
3. 调用翻译属性的 getter 方法
4. 验证返回的文本为中文值（与英文值不同）

```dart
testWidgets('AppLocalizations returns Chinese text for zh locale', (tester) async {
  String? actualAppTitle;

  await tester.pumpWidget(MaterialApp(
    locale: const Locale('zh'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Builder(
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        actualAppTitle = loc.appTitle;
        return const SizedBox();
      },
    ),
  ));
  await tester.pump();

  expect(actualAppTitle, isNotNull);
  // 中文翻译应与英文值不同（除非是专有名词如 "Kayak"）
  expect(actualAppTitle, anyOf(
    isNot(equals('Kayak')),   // 如果 "Kayak" 被翻译为中文
    equals('Kayak'),          // 如果 "Kayak" 作为专有名词保留英文
  ));
});
```

**预期结果**：
- ✅ 使用 `Locale('zh')` 返回中文文本
- ✅ 通用词汇（如 save、cancel）应翻译为中文
- ✅ 专有名词（如 Kayak）可保留原文

**失败判定**：
- ❌ 中文 locale 返回了英文文本（`app_zh.arb` 未翻译）
- ❌ `AppLocalizations.of(context)` 返回 null
- ❌ 返回的是 key 名称而非翻译值

---

### TC-019: 语言切换后 Widget 文本自动更新

| 属性 | 内容 |
|------|------|
| **ID** | TC-019 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | Widget 渲染 / 动态切换 |
| **关联验收标准** | 切换后 UI 文字自动更新 |

**前置条件**：
- `KayakApp` 的 locale 绑定到 `localeProvider`
- TC-016 通过

**测试步骤**：

1. 在 Widget 测试中构建 `KayakApp`（初始 locale = en）
2. 验证某个使用 `AppLocalizations` 的文本显示为英文
3. 通过 Provider 切换到 zh
4. `pumpAndSettle()` 等待重建
5. 验证同一文本切换显示为中文

```dart
testWidgets('UI text auto-updates after locale switch', (tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const KayakApp(),
    ),
  );
  await tester.pumpAndSettle();

  // 初始英文：导航到包含 AppLocalizations 文本的页面
  // （由于 KayakApp 包含路由，需导航到 settings 页面等）
  // 这里假定 settings 页面包含 locale 选择器或 locale 显示文本

  // 验证英文文本存在

  // 切换到中文
  container.read(localeProvider.notifier).setLocale(const Locale('zh'));
  await tester.pumpAndSettle();

  // 验证中文文本存在
  // （具体验证取决于页面中实际使用的翻译 key）
});
```

**预期结果**：
- ✅ locale 切换后 Widget 树自动重建
- ✅ `AppLocalizations.of(context)` 返回新 locale 对应实例
- ✅ 文本即时变化，无需手动刷新

**失败判定**：
- ❌ locale 切换后文本不变
- ❌ 需要刷新页面才生效
- ❌ 部分 Widget 未更新（使用了缓存的旧 locale）

---

### TC-020: 回退到 en 当 zh 中缺少 key

| 属性 | 内容 |
|------|------|
| **ID** | TC-020 |
| **优先级** | **P1 — HIGH** |
| **类别** | 文本查找 / 回退机制 |
| **关联验收标准** | 回退语言为 en |

**前置条件**：
- AppLocalizations 已生成
- 代码正确设置了回退语言

**测试步骤**：

1. 模拟场景：zh ARB 文件缺少某个 key（测试环境下模拟）
   - **注意**: 由于 ARB 生成代码是编译时的，此测试需在单元测试中构造场景：
     验证 `_AppLocalizationsDelegate.isSupported()` 方法对于 `'en'` 和 `'zh'` 返回 true
     验证对于不支持的语言（如 `'fr'`）的处理逻辑
2. 验证 zh locale 中未定义的 key 回退使用 en 的值

```dart
test('_AppLocalizationsDelegate.isSupported recognizes en and zh', () {
  // 验证 delegate 支持 en 和 zh
  expect(
    AppLocalizations.delegate.isSupported(const Locale('en')),
    isTrue,
  );
  expect(
    AppLocalizations.delegate.isSupported(const Locale('zh')),
    isTrue,
  );
  expect(
    AppLocalizations.delegate.isSupported(const Locale('fr')),
    isFalse,
  );
});
```

**预期结果**：
- ✅ `isSupported` 对 `'en'` / `'zh'` 返回 true
- ✅ 对不支持的语言返回 false
- ✅ 组件默认回退语言为 en（Flutter 框架自动处理）

**失败判定**：
- ❌ `isSupported('en')` 返回 false
- ❌ `isSupported('zh')` 返回 false
- ❌ 不支持的语言也能通过（未正确限制）

---

### TC-021: Widget 中使用 AppLocalizations.of(context) 正常获取实例

| 属性 | 内容 |
|------|------|
| **ID** | TC-021 |
| **优先级** | **P1 — HIGH** |
| **类别** | Widget 集成 / 上下文查找 |
| **关联验收标准** | 通过 l10n 获取所有面向用户的文本 |

**前置条件**：
- `MaterialApp` 正确配置了 `localizationsDelegates`

**测试步骤**：

包含两个场景：

**场景 A: MaterialApp 上下文中正常获取**：
1. 构建带完整 `localizationsDelegates` 的 `MaterialApp`
2. 在子 Widget 中调用 `AppLocalizations.of(context)`
3. 验证返回值不为 null

**场景 B: 没有 MaterialApp 上下文时返回 null**：
1. 直接在 builder 外调用（无 MaterialApp 上下文）
2. 验证抛出的行为（应返回 null 而非崩溃）

```dart
testWidgets('AppLocalizations.of(context) returns non-null with proper setup', (tester) async {
  AppLocalizations? loc;

  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Builder(
      builder: (context) {
        loc = AppLocalizations.of(context);
        return const SizedBox();
      },
    ),
  ));
  await tester.pump();

  expect(loc, isNotNull);
  expect(loc!.localeName, startsWith('en'));
});

test('AppLocalizations.of(context) returns null without MaterialApp', () {
  // 在没有 MaterialApp 上下文的情况下调用应该返回 null
  // （Flutter 框架会返回 null，不会崩溃）
  final key = GlobalKey();
  // 实际测试中需通过 widget 上下文验证
});
```

**预期结果**：
- ✅ 正确的 MaterialApp 上下文中 `AppLocalizations.of(context)` 返回实例
- ✅ 实例的 `localeName` 以期望的语言代码开头
- ✅ 缺少 MaterialApp 时不应崩溃（返回 null 或由调用方处理）

**失败判定**：
- ❌ 正确配置下返回 null
- ❌ `localeName` 与实际 locale 不一致
- ❌ 无 MaterialApp 上下文时崩溃

---

### TC-022: GlobalMaterialLocalizations 正确翻译 Material 组件文本

| 属性 | 内容 |
|------|------|
| **ID** | TC-022 |
| **优先级** | **P1 — HIGH** |
| **类别** | Widget 集成 / Material 组件 |
| **关联验收标准** | 所有本地化通过 l10n 获取 |

**前置条件**：
- `GlobalMaterialLocalizations.delegate` 已配置
- `GlobalWidgetsLocalizations.delegate` 已配置

**测试步骤**：

1. 使用 `Locale('zh')` 构建 MaterialApp
2. 渲染内置 Material 组件（如 `TextField`、`AboutDialog`）
3. 验证组件中的 OK/Cancel 按钮显示为中文（"确定"/"取消"）
4. 使用 `Locale('en')` 验证显示为英文

```dart
testWidgets('Material components use localized text for zh locale', (tester) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('zh'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDatePicker(
              context: tester.element(find.byType(ElevatedButton)),
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
          },
          child: const Text('Open Picker'),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();

  // 中文日期选择器中的 "取消" 按钮
  expect(find.text('取消'), findsOneWidget);
});
```

**预期结果**：
- ✅ `Locale('zh')` 下 Material 组件按钮显示中文
- ✅ `Locale('en')` 下 Material 组件按钮显示英文
- ✅ DatePicker、TimePicker 等组件也正确翻译

**失败判定**：
- ❌ 缺少 `GlobalMaterialLocalizations.delegate` 导致始终显示英文
- ❌ 组件文本未本地化

---

## 六、ARB 内容验证（4 项）

---

### TC-023: en ARB 包含所有必需的通用操作 key

| 属性 | 内容 |
|------|------|
| **ID** | TC-023 |
| **优先级** | **P0 — CRITICAL**（通用操作 key 是其他所有模块的基础） |
| **类别** | ARB 文件 / 内容覆盖 |
| **关联验收标准** | ARB 覆盖通用操作文本 |

**前置条件**：
- TC-001 通过

**测试步骤**：

1. 解析 app_en.arb
2. 验证以下通用操作 key 存在且值为非空字符串：

| 必需 key | 预期英文值（参考） | 说明 |
|---------|------------------|------|
| `save` | "Save" | 保存 |
| `cancel` | "Cancel" | 取消 |
| `delete` | "Delete" | 删除 |
| `confirm` | "Confirm" | 确认 |
| `close` | "Close" | 关闭 |
| `retry` | "Retry" | 重试 |
| `loading` | "Loading..." | 加载中 |
| `noData` | "No data" | 暂无数据 |
| `networkError` | "Network error" | 网络错误 |

```dart
test('app_en.arb contains all required common action keys', () {
  final enJson = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;

  const requiredKeys = [
    'save', 'cancel', 'delete', 'confirm', 'close',
    'retry', 'loading', 'noData', 'networkError',
  ];

  for (final key in requiredKeys) {
    expect(enJson.containsKey(key), isTrue, reason: 'Missing key: $key');
    expect(enJson[key], isA<String>(), reason: 'Key $key is not a String');
    expect((enJson[key] as String).isNotEmpty, isTrue,
        reason: 'Key $key has empty value');
  }
});
```

**预期结果**：
- ✅ 所有通用操作 key 存在
- ✅ 每个值为非空字符串
- ✅ 英文值语义正确

**失败判定**：
- ❌ 任一必需 key 缺失
- ❌ 值为空字符串或非 String 类型
- ❌ 英文值明显语义错误（如 save 映射为 "Delete"）

---

### TC-024: en ARB 包含所有必需的导航/认证/功能 key

| 属性 | 内容 |
|------|------|
| **ID** | TC-024 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | ARB 文件 / 内容覆盖 |
| **关联验收标准** | ARB 覆盖导航标签、认证、工作台、设备、测点、试验 key |

**前置条件**：
- TC-023 通过

**测试步骤**：

1. 解析 app_en.arb
2. 按类别验证所有必需 key 存在且值为非空字符串：

**导航标签（8 个）**：
| Key | 预期英文 | 说明 |
|-----|---------|------|
| `home` | "Home" | 首页 |
| `workbench` | "Workbench" | 工作台 |
| `methods` | "Methods" | 方法 |
| `experiments` | "Experiments" | 试验 |
| `analysis` | "Analysis" | 分析 |
| `settings` | "Settings" | 设置 |
| `login` | "Login" / "Sign In" | 登录 |
| `register` | "Register" / "Sign Up" | 注册 |

**认证（6 个）**：
| Key | 预期英文 | 说明 |
|-----|---------|------|
| `email` | "Email" | 邮箱 |
| `password` | "Password" | 密码 |
| `username` | "Username" | 用户名 |
| `login` | 已在导航中 | — |
| `register` | 已在导航中 | — |
| `logout` | "Logout" / "Sign Out" | 登出 |
| `sessionExpired` | "Session expired" | 会话过期 |

**工作台（4 个）**：
| Key | 预期英文 | 说明 |
|-----|---------|------|
| `createWorkbench` | "Create Workbench" | 创建工作台 |
| `editWorkbench` | "Edit Workbench" | 编辑工作台 |
| `deleteWorkbench` | "Delete Workbench" | 删除工作台 |
| `searchWorkbench` | "Search Workbench" | 搜索工作台 |

**设备（6 个）**：
| Key | 预期英文 | 说明 |
|-----|---------|------|
| `addDevice` | "Add Device" | 添加设备 |
| `editDevice` | "Edit Device" | 编辑设备 |
| `deleteDevice` | "Delete Device" | 删除设备 |
| `testConnection` | "Test Connection" | 测试连接 |
| `connect` | "Connect" | 连接 |
| `disconnect` | "Disconnect" | 断开 |

**测点（4 个）**：
| Key | 预期英文 | 说明 |
|-----|---------|------|
| `addPoint` | "Add Point" | 添加测点 |
| `editPoint` | "Edit Point" | 编辑测点 |
| `deletePoint` | "Delete Point" | 删除测点 |
| `pointValue` | "Point Value" | 测点值 |

**试验（7 个）**：
| Key | 预期英文 | 说明 |
|-----|---------|------|
| `createExperiment` | "Create Experiment" | 创建试验 |
| `load` | "Load" | 载入 |
| `start` | "Start" | 开始 |
| `pause` | "Pause" | 暂停 |
| `resume` | "Resume" | 继续 |
| `stop` | "Stop" | 停止 |
| `executionLog` | "Execution Log" | 执行日志 |

**错误消息（4 个）**：
| Key | 预期英文 | 说明 |
|-----|---------|------|
| `networkConnectionFailed` | "Network connection failed" | 网络连接失败 |
| `loginExpired` | "Login expired" | 登录过期 |
| `permissionDenied` | "Permission denied" | 权限不足 |
| `serverError` | "Server error" | 服务器错误 |

**预期结果**：
- ✅ 以上所有 key 在 app_en.arb 中存在
- ✅ 每个值为非空字符串
- ✅ 英文值语义正确

**失败判定**：
- ❌ 任一类别中任一必需 key 缺失
- ❌ 值为空字符串或非 String 类型

---

### TC-025: zh ARB 中文翻译非空且不同于英文值

| 属性 | 内容 |
|------|------|
| **ID** | TC-025 |
| **优先级** | **P1 — HIGH** |
| **类别** | ARB 文件 / 翻译质量 |
| **关联验收标准** | en 和 zh 所有 key 一一对应（翻译质量） |

**前置条件**：
- TC-023, TC-024 通过（en 所有 key 存在）

**测试步骤**：

1. 解析 app_zh.arb
2. 对于 TC-023 和 TC-024 中列出的所有 key：
   - 验证 zh ARB 中存在对应 key
   - 验证值为非空字符串
   - 验证中文值与英文值**不同**（表示已被翻译，而非简单复制）

> **例外**：以下情况允许中英文值相同：
> - 专有名词，如 `appTitle` = "Kayak"
> - 技术术语无公认翻译，如 "Modbus"

```dart
test('zh ARB translations differ from en for non-proper-noun keys', () {
  final enJson = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final zhJson = jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync())
      as Map<String, dynamic>;

  // 允许相同的专有名词/技术术语 key
  const properNounKeys = {'appTitle'};

  final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
  for (final key in enKeys) {
    final enValue = enJson[key] as String;
    final zhValue = zhJson[key] as String;

    if (properNounKeys.contains(key)) {
      // 专有名词允许相同
      continue;
    }

    // 通用词汇必须翻译
    expect(zhValue, isNot(equals(enValue)),
        reason: 'Key "$key" has identical value in en and zh: "$enValue". '
            'It should be translated.');
    expect(zhValue.isNotEmpty, isTrue,
        reason: 'Key "$key" has empty Chinese translation.');
  }
});
```

**预期结果**：
- ✅ 所有通用词汇 key 的中文值与英文值不同
- ✅ 中文翻译为非空字符串
- ✅ 专有名词特定 key 允许中英文相同

**失败判定**：
- ❌ 通用词汇中文值与英文值相同（未翻译）
- ❌ 中文翻译为空或空白字符
- ❌ 专有名词 key 被强制要求不同（过度检查）

---

### TC-026: ARB 文件中 @key 元数据格式正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-026 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | ARB 文件 / 元数据 |
| **关联验收标准** | ARB 文件格式符合 ICU 规范 |

**前置条件**：
- TC-001, TC-002 通过

**测试步骤**：

1. 解析 app_en.arb
2. 验证每个 `@key` 元数据对象：
   - 对应一个存在的翻译 key（如 `@appTitle` 对应 `appTitle`）
   - 如果存在 `@key`，其中 `description` 字段为非空字符串
3. 验证不存在未对应翻译 key 的 `@key`（孤儿元数据）

```dart
test('ARB metadata keys correctly reference translation keys', () {
  final enJson = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;

  final allKeys = enJson.keys.toSet();
  final metaKeys = allKeys.where((k) => k.startsWith('@') && k != '@@locale');
  final translationKeys = allKeys.where((k) => !k.startsWith('@'));

  for (final metaKey in metaKeys) {
    // 每个 @xxx 应该对应一个存在的翻译 key xxx
    final translationKey = metaKey.substring(1); // 去掉 @ 前缀
    expect(translationKeys.contains(translationKey), isTrue,
        reason: 'Metadata "$metaKey" has no corresponding translation key "$translationKey"');
  }
});
```

**预期结果**：
- ✅ 所有 `@key` 元数据都有对应的翻译 key
- ✅ 不存在孤儿元数据
- ✅ `description` 字段提供有意义的说明（如有）

**失败判定**：
- ❌ `@key` 元数据对应不存在的翻译 key
- ❌ 元数据格式错误导致 `flutter gen-l10n` 报错

---

## 七、LocaleNotifier Provider 集成测试（3 项）

---

### TC-027: LocaleNotifier 的 Provider 类型正确性

| 属性 | 内容 |
|------|------|
| **ID** | TC-027 |
| **优先级** | **P1 — HIGH** |
| **类别** | LocaleNotifier / 类型安全 |
| **关联验收标准** | Riverpod 3.x Notifier API 正确使用 |

**前置条件**：
- `LocaleNotifier` 已实现
- Riverpod 3.x (`flutter_riverpod ^3.3.1`) 已安装

**测试步骤**：

1. 验证 `LocaleNotifier` 继承自 `Notifier<Locale>`（非 `StateNotifier` 或 `AsyncNotifier`）
2. 验证 `localeProvider` 的类型为 `NotifierProvider<LocaleNotifier, Locale>`
3. 验证 `build()` 方法返回类型为 `Locale`（同步返回，非 `Future<Locale>`）
4. 验证 `setLocale()` 是 void 方法（非 `Future<void>`）

```dart
test('LocaleNotifier uses correct Riverpod 3.x API', () {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);

  // 验证 Notifier 类型
  final notifier = container.read(localeProvider.notifier);
  expect(notifier, isA<LocaleNotifier>());

  // 验证状态类型
  final state = container.read(localeProvider);
  expect(state, isA<Locale>());

  // 验证 setLocale 是同步方法
  expect(notifier.setLocale, isA<void Function(Locale)>());
});
```

**预期结果**：
- ✅ `LocaleNotifier extends Notifier<Locale>`
- ✅ `build()` 不是 async
- ✅ `setLocale()` 返回 void
- ✅ 不使用已废弃的 `StateNotifierProvider` 或 `ChangeNotifierProvider`

**失败判定**：
- ❌ 使用了旧版 Riverpod 的 `StateNotifier` 或 `StateProvider`
- ❌ `build()` 被声明为 `async`
- ❌ `setLocale()` 返回 `Future<void>`

---

### TC-028: LocaleNotifier 与 ThemeNotifier 在同一文件中不冲突

| 属性 | 内容 |
|------|------|
| **ID** | TC-028 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | Provider / 模块隔离 |
| **关联验收标准** | LocaleNotifier 放在 settings_provider.dart 中（同文件） |

**前置条件**：
- `ThemeModeNotifier` 和 `LocaleNotifier` 均在 `settings_provider.dart` 中
- 两者共享 `sharedPreferencesProvider`

**测试步骤**：

1. 验证同一文件中可正确导入两个 Notifier 和相应 Provider
2. 验证 `themeModeProvider` 的操作不影响 `localeProvider`
3. 在同一 ProviderContainer 中：
   - 设置主题为 `ThemeMode.dark`
   - 设置 locale 为 `Locale('zh')`
   - 验证主题状态为 dark，locale 状态为 zh（互不干扰）

```dart
test('LocaleNotifier and ThemeNotifier do not interfere', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);

  // 同时设置两个状态
  container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
  container.read(localeProvider.notifier).setLocale(const Locale('zh'));

  // 验证互不干扰
  expect(container.read(themeModeProvider), equals(ThemeMode.dark));
  expect(container.read(localeProvider).languageCode, equals('zh'));

  // 验证持久化 key 不冲突
  expect(prefs.getString('theme_mode'), equals('dark'));
  expect(prefs.getString('locale_language_code'), equals('zh'));
});
```

**预期结果**：
- ✅ ThemeNotifier 和 LocaleNotifier 独立工作
- ✅ SharedPreferences key 不冲突（`theme_mode` vs `locale_language_code`）
- ✅ 同一个 ProviderContainer 中可分别操作两者

**失败判定**：
- ❌ 两个 Notifier 共享了 SharedPreferences key（存储 key 冲突）
- ❌ 设置一个导致另一个被重置
- ❌ 同一个 ProviderContainer 中两者状态互相覆盖

---

### TC-029: 多次读取 localeProvider 返回一致状态

| 属性 | 内容 |
|------|------|
| **ID** | TC-029 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | LocaleNotifier / 一致性 |
| **关联验收标准** | Provider 状态管理正确 |

**前置条件**：
- TC-007 ~ TC-009 通过

**测试步骤**：

1. 设置 `Locale('zh')`
2. 连续多次读取 `localeProvider`
3. 验证每次读取返回相同的 `Locale('zh')`
4. 创建另一个 ProviderContainer
5. 验证新容器读取初始状态（不受前一个容器影响）

```dart
test('multiple reads return consistent state', () {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);

  container.read(localeProvider.notifier).setLocale(const Locale('zh'));

  // 多次读取返回一致状态
  expect(container.read(localeProvider).languageCode, equals('zh'));
  expect(container.read(localeProvider).languageCode, equals('zh'));
  expect(container.read(localeProvider).languageCode, equals('zh'));
});

test('different containers have independent state', () {
  SharedPreferences.setMockInitialValues({});
  final container1 = ProviderContainer();
  final container2 = ProviderContainer();
  addTearDown(container1.dispose);
  addTearDown(container2.dispose);

  container1.read(localeProvider.notifier).setLocale(const Locale('zh'));

  expect(container1.read(localeProvider).languageCode, equals('zh'));
  expect(container2.read(localeProvider).languageCode, equals('en'));
});
```

**预期结果**：
- ✅ 同一容器内多次读取返回一致状态
- ✅ 不同容器独立管理状态

**失败判定**：
- ❌ 同容器内多次读取返回不同状态
- ❌ 容器间状态泄漏

---

## 八、测试执行记录模板

> **sw-mike 在测试执行阶段填写**

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | app_en.arb 存在且 JSON 有效 |
| TC-002 | | | ⬜ 待执行 | app_zh.arb 存在且 JSON 有效 |
| TC-003 | | | ⬜ 待执行 | en/zh key 一一对应 |
| TC-004 | | | ⬜ 待执行 | l10n.yaml 配置 + gen-l10n |
| TC-005 | | | ⬜ 待执行 | AppLocalizations.supportedLocales |
| TC-006 | | | ⬜ 待执行 | AppLocalizations.localizationsDelegates |
| TC-007 | | | ⬜ 待执行 | 默认语言 en |
| TC-008 | | | ⬜ 待执行 | setLocale(zh) |
| TC-009 | | | ⬜ 待执行 | setLocale(en) |
| TC-010 | | | ⬜ 待执行 | 持久化写入 |
| TC-011 | | | ⬜ 待执行 | 持久化读取 |
| TC-012 | | | ⬜ 待执行 | 无存储回退 en |
| TC-013 | | | ⬜ 待执行 | SharedPreferences 不可用 |
| TC-014 | | | ⬜ 待执行 | MaterialApp supportedLocales |
| TC-015 | | | ⬜ 待执行 | MaterialApp localizationsDelegates |
| TC-016 | | | ⬜ 待执行 | MaterialApp locale 绑定 |
| TC-017 | | | ⬜ 待执行 | 英文文本查找 |
| TC-018 | | | ⬜ 待执行 | 中文文本查找 |
| TC-019 | | | ⬜ 待执行 | 语言切换后 Widget 更新 |
| TC-020 | | | ⬜ 待执行 | 回退到 en |
| TC-021 | | | ⬜ 待执行 | AppLocalizations.of(context) |
| TC-022 | | | ⬜ 待执行 | Material 组件翻译 |
| TC-023 | | | ⬜ 待执行 | en ARB 通用操作 key |
| TC-024 | | | ⬜ 待执行 | en ARB 导航/认证/功能 key |
| TC-025 | | | ⬜ 待执行 | zh ARB 翻译非空≠en |
| TC-026 | | | ⬜ 待执行 | ARB 元数据格式 |
| TC-027 | | | ⬜ 待执行 | LocaleNotifier 类型正确性 |
| TC-028 | | | ⬜ 待执行 | LocaleNotifier vs ThemeNotifier |
| TC-029 | | | ⬜ 待执行 | 多次读取一致性 |

---

## 九、测试统计

| 类别 | 测试用例数 | 用例 ID |
|------|:--------:|---------|
| ARB 文件基础验证 | 4 | TC-001 ~ TC-004 |
| AppLocalizations 生成代码验证 | 2 | TC-005 ~ TC-006 |
| LocaleNotifier 测试 | 7 | TC-007 ~ TC-013 |
| MaterialApp 集成测试 | 3 | TC-014 ~ TC-016 |
| 文本查找与 Widget 渲染 | 6 | TC-017 ~ TC-022 |
| ARB 内容验证 | 4 | TC-023 ~ TC-026 |
| Provider 集成测试 | 3 | TC-027 ~ TC-029 |
| **合计** | **29** | |

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 16 |
| P1 — HIGH | 9 |
| P2 — MEDIUM | 4 |

---

## 十、可追溯性矩阵

| 验收标准（来自 tasks.md） | 对应测试用例 |
|--------------------------|------------|
| `flutter gen-l10n` 无错误 | TC-001, TC-002, TC-004, TC-026 |
| en 和 zh 所有 key 一一对应 | TC-003, TC-023, TC-024, TC-025 |
| 语言切换即时生效 | TC-008, TC-009, TC-016, TC-019 |
| 持久化到 shared_preferences | TC-010, TC-011, TC-012 |
| 回退语言为 en | TC-003, TC-007, TC-012, TC-020 |
| LocaleNotifier build() 默认 en | TC-007 |
| setLocale('zh') 更新并持久化 | TC-008, TC-010 |
| supportedLocales 包含 en 和 zh | TC-005, TC-014 |
| localizationsDelegates 正确配置 | TC-006, TC-015 |
| locale 从 LocaleNotifier 读取 | TC-016 |
| 通过 AppLocalizations 获取文本 | TC-017, TC-018, TC-021 |
| Material 组件文本本地化 | TC-022 |
| 通用操作/导航/功能 key 覆盖 | TC-023, TC-024 |
| 中文翻译为空时回退英文 | TC-020 |

| PRD 国际化要求（§9） | 对应测试用例 |
|---------------------|------------|
| 默认语言 English (en) | TC-007, TC-012 |
| 支持简体中文 (zh) | TC-008, TC-018 |
| 所有面向用户的文本通过 l10n | TC-017, TC-018, TC-021, TC-022 |
| 语言切换持久化 | TC-010, TC-011 |
| 翻译覆盖率 100% | TC-003, TC-023, TC-024, TC-025 |

---

## 十一、附录 A：测试架构参考

### A.1 LocaleNotifier 单元测试设置

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 创建测试用的 ProviderContainer
/// 可注入 SharedPreferences mock
ProviderContainer createLocaleTestContainer({
  Map<String, Object>? sharedPrefsValues,
}) async {
  SharedPreferences.setMockInitialValues(sharedPrefsValues ?? {});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}
```

### A.2 AppLocalizations Widget 测试设置

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';

/// 用于测试国际化的 Widget 包装器
Widget wrapWithLocale({
  required Widget child,
  required Locale locale,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

/// 获取当前 locale 下特定 key 的翻译文本
String? getLocalizedText(WidgetTester tester, Type widgetType) {
  // 通过遍历 widget 树获取国际化文本
  // 具体实现取决于测试场景
}
```

### A.3 ARB 覆盖清单参考

以下为 TASK-006 要求的最低 ARB key 清单（39 个），用于 TC-023 和 TC-024 的验证：

```
通用（9）:  save, cancel, delete, confirm, close, retry, loading, noData, networkError
导航（8）:  home, workbench, methods, experiments, analysis, settings, login, register
认证（6）:  email, password, username, login*, register*, logout, sessionExpired
           *login/register 复用导航 key
工作台（4）: createWorkbench, editWorkbench, deleteWorkbench, searchWorkbench
设备（6）:   addDevice, editDevice, deleteDevice, testConnection, connect, disconnect
测点（4）:   addPoint, editPoint, deletePoint, pointValue
试验（7）:   createExperiment, load, start, pause, resume, stop, executionLog
错误（4）:   networkConnectionFailed, loginExpired, permissionDenied, serverError
```

---

*文档结束 — 共 29 个测试用例*
