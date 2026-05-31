# TASK-001 测试用例 — 项目初始化与依赖配置

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-05-31
> **状态**: Draft — 待 sw-tom 审查
> **关联任务**: TASK-001（项目初始化与依赖配置）
> **参考文档**: [tasks.md](../tasks.md), [architecture_proposal.md](../design/architecture_proposal.md)

---

## 测试范围

TASK-001 交付物覆盖：

| # | 交付物 | 验证方式 |
|---|--------|----------|
| 1 | `kayak-frontend/` 目录结构 | 文件系统检查 |
| 2 | `pubspec.yaml` — 依赖版本正确 | diff 对比 + pub get |
| 3 | `pubspec.lock` — `flutter pub get` 生成 | 文件存在 + 依赖树完整性 |
| 4 | `analysis_options.yaml` — 严格 lint 规则 | diff 对比 + analyze |
| 5 | `lib/main.dart` — ProviderScope + KayakApp | AST/内容检查 |
| 6 | `lib/app.dart` — MaterialApp.router | AST/内容检查 |
| 7 | `.github/workflows/ci.yml` — CI 前端部分适配 | 内容检查 |
| 8 | `flutter pub get` 无错误 + `flutter analyze` 零警告 | 命令执行 |

---

## 一、配置验证测试

---

### TC-001: flutter pub get 成功解析所有依赖

| 属性 | 内容 |
|------|------|
| **ID** | TC-001 |
| **优先级** | **P0 — CRITICAL**（阻塞所有后续任务） |
| **类别** | 配置验证 / 依赖解析 |
| **关联验收标准** | `flutter pub get` 无错误 |

**前置条件**：
- `kayak-frontend/pubspec.yaml` 已创建
- `pubspec.yaml` 中所有依赖版本已填写
- `kayak-frontend/` 是从零初始化的项目，或旧 `pubspec.lock` 已删除
- `flutter` SDK >= 3.19 已安装并可用

**测试步骤**：

1. 进入 `kayak-frontend/` 目录
2. 确保不存在旧的 `pubspec.lock`（如果存在，删除后重新测试）
3. 执行 `flutter pub get`
4. 检查命令退出码（exit code）
5. 检查 stdout/stderr 是否有错误信息
6. 验证生成 `pubspec.lock` 文件
7. 打开 `pubspec.lock` 验证每个依赖项均已解析

**预期结果**：
- ✅ `flutter pub get` exit code = 0
- ✅ stderr 无错误输出
- ✅ 无 "version solving failed" 或 "dependency conflict" 信息
- ✅ `pubspec.lock` 文件生成
- ✅ `pubspec.lock` 中包含所有 14 个直接依赖的解析条目

**失败判定**：
- ❌ exit code ≠ 0
- ❌ 出现任何版本的冲突解决失败
- ❌ 某依赖被标记 "not found"
- ❌ `pubspec.lock` 未生成或不完整

---

### TC-002: pubspec.yaml 依赖版本验证

| 属性 | 内容 |
|------|------|
| **ID** | TC-002 |
| **优先级** | **P0 — CRITICAL**（版本不对齐会引发连锁问题） |
| **类别** | 配置验证 / 版本一致性 |
| **关联验收标准** | 所有依赖版本严格按上表 |

**前置条件**：
- `kayak-frontend/pubspec.yaml` 已创建

**测试步骤**：

1. 打开 `kayak-frontend/pubspec.yaml`
2. 逐一对比以下依赖的指定版本：

| # | 依赖 | 期望版本约束 | 说明 |
|---|------|-------------|------|
| 1 | `flutter_riverpod` | `^3.3.1` | 核心状态管理 |
| 2 | `riverpod_annotation` | `^3.0.0` | 代码生成注解 |
| 3 | `go_router` | `^17.2.3` | 声明式路由 |
| 4 | `dio` | `^5.9.2` | HTTP 客户端 |
| 5 | `web_socket_channel` | `^3.0.3` | WebSocket 客户端 |
| 6 | `flutter_secure_storage` | `^10.3.1` | 安全存储 |
| 7 | `shared_preferences` | `^2.5.5` | 键值存储 |
| 8 | `freezed_annotation` | `^3.0.0` | 数据类注解 |
| 9 | `json_annotation` | `^4.12.0` | JSON 注解 |
| 10 | `fl_chart` | `^1.2.0` | 图表库 |
| 11 | `intl` | `^0.20.2` | 国际化 |
| 12 | `flutter_localizations` | SDK（无版本号） | Flutter SDK 自带 |
| 13 | `build_runner` | `^2.4.15` | dev 代码生成 |
| 14 | `json_serializable` | `^6.9.4` | dev JSON 生成 |
| 15 | `riverpod_generator` | `^3.0.0` | dev Provider 生成 |
| 16 | `freezed` | `^3.2.5` | dev 数据类生成 |
| 17 | `mocktail` | `^1.0.4` | dev 测试 mock |
| 18 | `flutter_lints` | `^5.0.0` | dev lint 规则 |
| 19 | `flutter_test` | SDK（无版本号） | Flutter SDK 自带 |

3. 使用 `dart pub deps --json` 或 `flutter pub deps` 验证解析版本确实 ≥ 指定版本

**预期结果**：
- ✅ 每个 `dependencies` 条目版本约束与上表完全一致
- ✅ 每个 `dev_dependencies` 条目版本约束与上表完全一致
- ✅ `flutter_localizations` 和 `flutter_test` 使用 `sdk: flutter`（无版本号）
- ✅ 不包含上表之外的未授权依赖（如 `dartz`、`multiple_result`、`material_design_icons_flutter` 等）
- ✅ 不包含旧版依赖残留（如 `riverpod: ^2.x`、`dio: ^5.4.x` 等）

**失败判定**：
- ❌ 任一依赖版本约束与上表不匹配（含主版本号/次版本号偏差）
- ❌ 存在上表未列出的非必要依赖
- ❌ `flutter_localizations` / `flutter_test` 错误地指定了版本号

---

### TC-003: analysis_options.yaml 存在且配置正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-003 |
| **优先级** | **P0 — HIGH**（lint 配置是代码质量的基础墙） |
| **类别** | 配置验证 / 代码质量 |
| **关联验收标准** | `flutter analyze --fatal-infos` 零警告 |

**前置条件**：
- `kayak-frontend/analysis_options.yaml` 已创建

**测试步骤**：

1. 打开 `kayak-frontend/analysis_options.yaml`
2. 验证以下**必须存在的配置项**：

| 配置项 | 期望值 | 说明 |
|--------|--------|------|
| `include` | `package:flutter_lints/flutter.yaml` | 继承 Flutter 官方 lint 规则 |
| `analyzer.exclude` | 至少包含 `**/*.g.dart`, `**/*.freezed.dart`, `lib/generated/**` | 排除生成文件 |
| `analyzer.language.strict-casts` | `true` | 严格类型转换检查 |
| `analyzer.language.strict-raw-types` | `true` | 严格原始类型检查 |
| `linter.rules.require_trailing_commas` | `true` | 强制末尾逗号 |
| `linter.rules.prefer_single_quotes` | `true` | 单引号风格 |
| `linter.rules.prefer_const_constructors` | `true` | 强制 const |
| `linter.rules.avoid_print` | `true` | 禁止 print |
| `linter.rules.public_member_api_docs` | `false` | 不强制公开 API 文档 |

3. 可选但推荐的配置项：
   - `sort_child_properties_last`
   - `use_super_parameters`
   - `use_key_in_widget_constructors`
   - `avoid_dynamic_calls`
   - `unnecessary_string_interpolations`

**预期结果**：
- ✅ 文件存在且是有效的 YAML
- ✅ `include: package:flutter_lints/flutter.yaml` 存在
- ✅ `analyzer.exclude` 至少排除生成文件
- ✅ `strict-casts: true`
- ✅ `strict-raw-types: true`
- ✅ 关键 lint 规则已启用

**失败判定**：
- ❌ 文件不存在
- ❌ `include` 行缺失或拼写错误
- ❌ `strict-casts` 不为 `true`
- ❌ YAML 语法错误导致无法解析
- ❌ 排除规则错误导致生成文件被分析

---

## 二、目录结构验证

---

### TC-004: 所有必需目录存在且按功能分组

| 属性 | 内容 |
|------|------|
| **ID** | TC-004 |
| **优先级** | **P0 — HIGH**（目录结构对后续开发有约束力） |
| **类别** | 目录结构验证 |
| **关联验收标准** | 目录结构匹配架构设计 §4 |

**前置条件**：
- `kayak-frontend/` 项目已初始化

**测试步骤**：

1. 列出 `kayak-frontend/lib/` 下的所有子目录
2. 逐一检查以下目录是否存在：

| # | 目录路径 | 用途 | 是否必需 |
|---|----------|------|:-------:|
| 1 | `lib/models/` | 数据模型（freezed） | ✅ 必需 |
| 2 | `lib/services/` | HTTP/WS 通信层 | ✅ 必需 |
| 3 | `lib/providers/` | Riverpod State 管理层 | ✅ 必需 |
| 4 | `lib/pages/` | 页面组件 | ✅ 必需 |
| 5 | `lib/widgets/` | 可复用组件 | ✅ 必需 |
| 6 | `lib/theme/` | 主题定义 | ✅ 必需 |
| 7 | `lib/router/` | 路由配置 | ✅ 必需 |
| 8 | `lib/l10n/` | 国际化 ARB 文件 | ✅ 必需 |
| 9 | `lib/utils/` | 工具函数 | ✅ 必需 |

3. 验证 `lib/pages/` 下有按功能分组的子目录占位：
   - `pages/auth/`
   - `pages/dashboard/`
   - `pages/workbench/`
   - `pages/device/`
   - `pages/point/`
   - `pages/method/`
   - `pages/experiment/`
   - `pages/settings/`

4. 枚举所有文件，确保 `lib/` 下没有**散落**的一级文件（除了 `main.dart` 和 `app.dart`）

**预期结果**：
- ✅ 9 个必需目录全部存在
- ✅ 每个目录在 `lib/` 下有明确的 `models/`, `services/`, `providers/`, `pages/`, `widgets/`, `theme/`, `router/`, `l10n/`, `utils/` 含义
- ✅ `lib/` 一级只有 `main.dart` 和 `app.dart` 两个 Dart 文件（以及子目录）
- ✅ `pages/` 下有功能子目录（至少包含占位符如 `.gitkeep` 或未来会用到的空目录）
- ✅ 目录命名使用 `snake_case`（Dart/Flutter 惯例，如 `l10n` 而非 `L10n`）

**失败判定**：
- ❌ 任一必需目录缺失
- ❌ 业务代码散落在 `lib/` 根级别（`main.dart` 和 `app.dart` 除外）
- ❌ `pages/` 下无功能分组子目录

---

### TC-005: main.dart 存在且包含 ProviderScope

| 属性 | 内容 |
|------|------|
| **ID** | TC-005 |
| **优先级** | **P0 — HIGH**（应用入口，不可为空） |
| **类别** | 目录结构验证 / 代码骨架 |
| **关联验收标准** | `lib/main.dart` 存在且是有效的最小入口 |

**前置条件**：
- `kayak-frontend/lib/main.dart` 已创建

**测试步骤**：

1. 打开 `lib/main.dart` 内容
2. 检查以下代码要素：

```dart
// ✅ 必须包含：
// (1) flutter/material.dart 导入
import 'package:flutter/material.dart';

// (2) flutter_riverpod 导入
import 'package:flutter_riverpod/flutter_riverpod.dart';

// (3) app.dart 导入
import 'app.dart';

// (4) main() 函数
void main() {
  // runApp 包裹在 ProviderScope 中
  runApp(
    const ProviderScope(
      child: KayakApp(),
    ),
  );
}
```

3. 验证要点：
   - `ProviderScope` 包裹了 `KayakApp`
   - `KayakApp` 从 `app.dart` 导入
   - `main()` 是顶层函数
   - 文件不含任何业务逻辑或复杂初始化代码

**预期结果**：
- ✅ `main.dart` 文件存在
- ✅ `main()` 函数存在
- ✅ `ProviderScope` 包裹 `KayakApp`
- ✅ 导入 `flutter_riverpod`
- ✅ `KayakApp` 从 `app.dart` 导入（不是 `package:kayak_frontend/app.dart` 路径，而是相对路径 `'app.dart'`）
- ✅ 无业务逻辑代码、无异步初始化（此阶段为最小骨架）

**失败判定**：
- ❌ 文件不存在
- ❌ 缺少 `ProviderScope`
- ❌ 缺少 `runApp()`
- ❌ 出现编译期无法解析的导入
- ❌ 骨架代码中包含业务逻辑

---

### TC-006: app.dart 存在且包含 MaterialApp.router

| 属性 | 内容 |
|------|------|
| **ID** | TC-006 |
| **优先级** | **P0 — HIGH**（应用根组件，不可为空） |
| **类别** | 目录结构验证 / 代码骨架 |
| **关联验收标准** | `lib/app.dart` 存在且是有效的 MaterialApp.router 骨架 |

**前置条件**：
- `kayak-frontend/lib/app.dart` 已创建

**测试步骤**：

1. 打开 `lib/app.dart` 内容
2. 检查以下代码要素：

```dart
// ✅ 必须包含：
// (1) flutter/material.dart 导入
import 'package:flutter/material.dart';

// (2) go_router 导入
// (3) GoRouter 路由配置引用
// (4) MaterialApp.router 使用（不是 MaterialApp）
// (5) routerConfig 参数指向 GoRouter 实例
```

3. 验证要点：
   - 类名 `KayakApp`（匹配 main.dart 中的引用）
   - 继承 `StatelessWidget` 或 `ConsumerWidget`
   - `build` 方法返回 `MaterialApp.router`
   - `routerConfig` 参数存在
   - 至少包含 `title` 字段（如 "Kayak"）

**预期结果**：
- ✅ `app.dart` 文件存在
- ✅ `KayakApp` 类存在，继承 `StatelessWidget` 或 `ConsumerWidget`
- ✅ 使用 `MaterialApp.router`（不是 `MaterialApp`）
- ✅ `routerConfig` 参数被赋值
- ✅ 引用来自 `Router` 模块（`lib/router/app_router.dart` 或类似路径）

**失败判定**：
- ❌ 文件不存在
- ❌ 使用 `MaterialApp` 而非 `MaterialApp.router`
- ❌ `KayakApp` 类名与 `main.dart` 不匹配
- ❌ `routerConfig` 未赋值或引用不存在的路由

---

## 三、静态分析验证

---

### TC-007: flutter analyze 零错误

| 属性 | 内容 |
|------|------|
| **ID** | TC-007 |
| **优先级** | **P0 — CRITICAL**（错误 = 代码有问题） |
| **类别** | 静态分析 |
| **关联验收标准** | `flutter analyze` 零错误 |

**前置条件**：
- TC-001 通过（`flutter pub get` 成功）
- `lib/main.dart` 和 `lib/app.dart` 已创建
- 所有目录结构已创建

**测试步骤**：

1. 进入 `kayak-frontend/` 目录
2. 执行 `flutter analyze`
3. 检查退出码
4. 解析输出，统计：
   - `error` 级别诊断数量
   - `warning` 级别诊断数量
   - `info` 级别诊断数量
5. 对每个 `error` 记录文件名、行号、错误描述

**预期结果**：
- ✅ exit code = 0
- ✅ `No issues found!` 或仅存在 `info` 级别诊断
- ✅ `error` 数量 = 0
- ✅ 所有 `info` 诊断均有合理来源（如 `prefer_const_constructors` 可后续修复）

**失败判定**：
- ❌ 存在任何 `error` 级别诊断
- ❌ 存在导致编译失败的语法错误
- ❌ 类型错误（如 import 路径错误导致类型无法解析）

---

### TC-008: flutter analyze 零警告

| 属性 | 内容 |
|------|------|
| **ID** | TC-008 |
| **优先级** | **P0 — HIGH**（警告 = 潜在问题） |
| **类别** | 静态分析 |
| **关联验收标准** | `flutter analyze` 零警告 |

**前置条件**：
- TC-007 通过（零错误）
- `analysis_options.yaml` lint 规则已启用

**测试步骤**：

1. 进入 `kayak-frontend/` 目录
2. 执行 `flutter analyze` 并解析输出
3. 统计 `warning` 级别诊断数量
4. 对每个 `warning` 记录详细信息
5. 特别注意以下 lint 警告：
   - `unused_import` — 未使用的导入
   - `unused_local_variable` — 未使用的变量（如果骨架代码中有）
   - `avoid_print` — print 语句
   - `prefer_const_constructors` — 未使用 const

**预期结果**：
- ✅ `warning` 数量 = 0
- ✅ 无 `unused_import` 警告
- ✅ 无 `avoid_print` 警告

**失败判定**：
- ❌ 存在任何 `warning` 级别诊断
- ❌ 存在已启用 lint 规则的违反条目

---

### TC-009: flutter analyze --fatal-infos 通过

| 属性 | 内容 |
|------|------|
| **ID** | TC-009 |
| **优先级** | **P0 — CRITICAL**（任务硬性验收标准） |
| **类别** | 静态分析 / 严格模式 |
| **关联验收标准** | `flutter analyze --fatal-infos` 零警告 |

**前置条件**：
- TC-007 通过（零错误）
- TC-008 通过（零警告）

**测试步骤**：

1. 进入 `kayak-frontend/` 目录
2. 执行 `flutter analyze --fatal-infos`
3. 检查退出码
4. 如果失败，记录所有 `info` 级别诊断（`--fatal-infos` 将 info 提升为 error）
5. 分析每个 info 诊断是否合理：
   - 如果来自 `prefer_const_constructors` 等风格建议 → 应修复
   - 如果来自第三方库的已知 info → 可能是误报

**预期结果**：
- ✅ exit code = 0
- ✅ 无任何诊断导致失败
- ✅ `--fatal-infos` 将 info 提升后仍通过

**失败判定**：
- ❌ exit code ≠ 0
- ❌ 存在任何 `info` 级别诊断被提升为错误（即使只是风格建议）

---

## 四、构建验证

---

### TC-010: flutter build web 构建成功

| 属性 | 内容 |
|------|------|
| **ID** | TC-010 |
| **优先级** | **P1 — MEDIUM**（核心验证，但可后续修复） |
| **类别** | 构建验证 |
| **关联验收标准** | Web 是默认部署目标，构建必须成功 |

**前置条件**：
- TC-001 通过（`flutter pub get` 成功）
- TC-007 通过（`flutter analyze` 零错误）
- `lib/main.dart` 和 `lib/app.dart` 完整

**测试步骤**：

1. 进入 `kayak-frontend/` 目录
2. 执行 `flutter build web`（或 `flutter build web --release`）
3. 检查退出码
4. 检查 `build/web/` 目录是否存在产物
5. 验证关键输出文件：
   - `build/web/index.html` — 入口 HTML
   - `build/web/main.dart.js` — 编译后的 JS
   - `build/web/flutter.js` — Flutter Web 引擎
   - `build/web/assets/` — 静态资源

6. **可选（如果 Linux 桌面环境可用）**：
   - 执行 `flutter build linux --release`
   - 检查 `build/linux/` 产物

**预期结果**：
- ✅ exit code = 0
- ✅ `build/web/` 目录包含完整 Web 产物
- ✅ `build/web/index.html` 存在且格式正确
- ✅ `build/web/main.dart.js` 文件大小 > 0
- ✅ 无 "Compilation failed" 或类似错误

**失败判定**：
- ❌ exit code ≠ 0
- ❌ 构建产物目录为空或不完整
- ❌ JavaScript 编译阶段报错

---

## 五、补充测试用例（边界 & 负向）

---

### TC-011: Git 工作区干净（仅本任务文件变更）

| 属性 | 内容 |
|------|------|
| **ID** | TC-011 |
| **优先级** | **P1 — MEDIUM** |
| **类别** | Git / 版本控制 |

**前置条件**：
- TASK-001 已全部实现

**测试步骤**：

1. 执行 `git status` 在仓库根目录
2. 检查变更文件列表
3. 确认所有变更均在 `kayak-frontend/` 和 `.github/workflows/` 目录下
4. 确认没有意外删除或修改的文件

**预期结果**：
- ✅ 变更仅限于本任务相关的文件
- ✅ 没有删除不应删除的文件
- ✅ 没有修改 `kayak-backend/` 或其他模块的文件

---

### TC-012: .github/workflows/ci.yml 前端适配

| 属性 | 内容 |
|------|------|
| **ID** | TC-012 |
| **优先级** | **P1 — MEDIUM** |
| **类别** | CI/CD |

**前置条件**：
- `.github/workflows/ci.yml` 存在

**测试步骤**：

1. 读取 `.github/workflows/ci.yml`
2. 验证前端相关 job 的配置：
   - `flutter pub get` 步骤在新依赖下可执行
   - `dart format` 步骤引用的分析配置路径正确
   - `flutter analyze` 步骤包含 `--fatal-infos`
   - `flutter build web` 步骤存在
   - 前端 job 中的 `flutter_lints` 版本引用与 `pubspec.yaml` 一致

**预期结果**：
- ✅ CI 配置中存在前端 job
- ✅ 前端 job 的步骤与新依赖版本兼容
- ✅ 无硬编码的旧依赖版本号

---

### TC-013: flutter pub get 重复执行幂等验证

| 属性 | 内容 |
|------|------|
| **ID** | TC-013 |
| **优先级** | **P2 — LOW** |
| **类别** | 稳定性 / 幂等性 |

**前置条件**：
- TC-001 已通过

**测试步骤**：

1. 进入 `kayak-frontend/` 目录
2. 删除 `pubspec.lock`
3. 执行 `flutter pub get`（第一次）
4. 再次执行 `flutter pub get`（第二次）
5. 比较两次的结果（exit code、输出）

**预期结果**：
- ✅ 两次执行 exit code 均为 0
- ✅ 第二次执行无重新解析依赖（lock 文件已存在）
- ✅ 无 "Running pub upgrade" 类意外升级

---

### TC-014: 常见错误 — 依赖版本号不正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-014 |
| **优先级** | **P2 — LOW**（负向测试） |
| **类别** | 错误处理 |

**前置条件**：
- 测试环境允许临时修改 `pubspec.yaml`

**测试步骤**：

1. 备份当前 `pubspec.yaml`
2. 将 `flutter_riverpod` 改为 `^4.0.0`（不存在的版本）
3. 删除 `pubspec.lock`
4. 执行 `flutter pub get`
5. 记录错误输出
6. 恢复原始 `pubspec.yaml` 并重新 `flutter pub get`

**预期结果**：
- ❌ `flutter pub get` 失败（exit code ≠ 0）
- ✅ 错误信息明确指出 `flutter_riverpod` 版本冲突
- ✅ 恢复正确版本后 `flutter pub get` 重新成功

---

### TC-015: 常见错误 — 缺失必需的文件

| 属性 | 内容 |
|------|------|
| **ID** | TC-015 |
| **优先级** | **P2 — LOW**（负向测试） |
| **类别** | 错误处理 |

**前置条件**：
- 测试环境允许临时删除文件

**测试步骤**：

1. 临时移除 `lib/main.dart`
2. 执行 `flutter analyze`
3. 记录错误输出
4. 恢复 `lib/main.dart`
5. 验证 `flutter analyze` 恢复通过

**预期结果**：
- ❌ `flutter analyze` 报告错误（发现 `app.dart` 中引用的类缺失或入口文件不存在场景）

---

## 六、测试执行记录模板

> **测试工程师在测试执行阶段填写**

| 测试用例 | 执行人 | 执行日期 | 结果 | 备注 |
|----------|--------|----------|------|------|
| TC-001 | | | ⬜ 待执行 | |
| TC-002 | | | ⬜ 待执行 | |
| TC-003 | | | ⬜ 待执行 | |
| TC-004 | | | ⬜ 待执行 | |
| TC-005 | | | ⬜ 待执行 | |
| TC-006 | | | ⬜ 待执行 | |
| TC-007 | | | ⬜ 待执行 | |
| TC-008 | | | ⬜ 待执行 | |
| TC-009 | | | ⬜ 待执行 | |
| TC-010 | | | ⬜ 待执行 | |
| TC-011 | | | ⬜ 待执行 | |
| TC-012 | | | ⬜ 待执行 | |
| TC-013 | | | ⬜ 待执行 | |
| TC-014 | | | ⬜ 待执行 | |
| TC-015 | | | ⬜ 待执行 | |

---

## 七、测试统计

| 类别 | 测试用例数 | 说明 |
|------|:--------:|------|
| 配置验证 | 3 | TC-001 ~ TC-003 |
| 目录结构 | 3 | TC-004 ~ TC-006 |
| 静态分析 | 3 | TC-007 ~ TC-009 |
| 构建验证 | 1 | TC-010 |
| 补充测试 | 5 | TC-011 ~ TC-015 |
| **合计** | **15** | |

| 优先级分布 | 数量 |
|-----------|:---:|
| P0 — CRITICAL | 5 |
| P0 — HIGH | 5 |
| P1 — MEDIUM | 3 |
| P2 — LOW | 2 |

---

## 八、可追溯性矩阵

| 验收标准 | 对应测试用例 |
|----------|------------|
| `flutter pub get` 无错误 | TC-001 |
| 所有依赖版本严格按上表 | TC-002 |
| 目录结构匹配架构设计 §4 | TC-004 |
| `flutter analyze --fatal-infos` 零警告 | TC-007, TC-008, TC-009 |
| `flutter build web` 构建成功 | TC-010 |
| CI 流水线前端适配 | TC-012 |
| Git 工作区干净 | TC-011 |
