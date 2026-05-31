# TASK-001 详细设计 — 项目初始化与依赖配置

> **作者**: sw-tom (Software Developer)
> **日期**: 2026-05-31
> **状态**: Final — 实现完成

> **版本调整说明**: 因 `riverpod_annotation ^3.0.0` 和 `riverpod_generator ^3.0.0` 与 `freezed ^3.2.5` 存在 `analyzer` 版本冲突（详见 §3.2），实际 pubspec.yaml 使用 `riverpod_annotation ^4.0.0` 和 `riverpod_generator ^4.0.0`。测试用例 TC-002 期望版本需同步更新。
> **关联任务**: TASK-001（项目初始化与依赖配置）
> **参考文档**: [tasks.md](../tasks.md), [architecture_proposal.md](architecture_proposal.md), [test_cases.md](../test/TASK-001_test_cases.md)

---

## 1. 设计目标

从零创建 `kayak-frontend/` 项目骨架，配置所有依赖为最新稳定版本，建立严格 lint 规则，为后续开发提供稳健的基础。

### 验收标准
1. `flutter pub get` 无错误
2. `flutter analyze --fatal-infos` 零警告
3. 目录结构匹配架构设计 §4
4. 所有依赖版本严格按版本表

---

## 2. 环境要求

| 工具 | 要求 | 当前环境 |
|------|------|:--------:|
| Flutter SDK | >= 3.19.0 | 3.44.0 ✅ |
| Dart SDK | >= 3.3.0 < 4.0.0 | 3.12.0 ✅ |
| 目标平台 | Web（默认）、Linux | - |

---

## 3. pubspec.yaml 设计

### 3.1 版本策略

所有依赖使用指定最新稳定版本，不使用 `any` 或宽松约束。

| 类别 | 依赖 | 版本约束 | 解析版本 | 用途 |
|------|------|:--------:|:--------:|------|
| **State** | flutter_riverpod | `^3.3.1` | `3.3.2-dev.2` | 核心状态管理（Notifier API） |
| **State** | riverpod_annotation | `^4.0.0` | `4.0.3-dev.2` | Provider 代码生成注解 |
| **Route** | go_router | `^17.2.3` | `17.2.3` | 声明式路由 |
| **HTTP** | dio | `^5.9.2` | `5.9.2` | HTTP 客户端（拦截器链） |
| **WS** | web_socket_channel | `^3.0.3` | `3.0.3` | WebSocket 客户端 |
| **Store** | flutter_secure_storage | `^10.3.1` | `10.3.1` | 安全 Token 存储 |
| **Store** | shared_preferences | `^2.5.5` | `2.5.5` | 轻量配置持久化 |
| **Codec** | freezed_annotation | `^3.0.0` | `3.1.0` | 不可变数据类注解 |
| **Codec** | json_annotation | `^4.12.0` | `4.12.0` | JSON 序列化注解 |
| **Chart** | fl_chart | `^1.2.0` | `1.2.0` | 数据可视化图表 |
| **i18n** | intl | `^0.20.2` | `0.20.2` | 国际化消息格式化 |
| **i18n** | flutter_localizations | SDK | SDK | Flutter 内置本地化 |
| **Dev** | build_runner | `^2.4.15` | `2.15.0` | 代码生成引擎 |
| **Dev** | json_serializable | `^6.9.4` | `6.14.0` | JSON 序列化生成 |
| **Dev** | riverpod_generator | `^4.0.0` | `4.0.4-dev.3` | Provider 代码生成 |
| **Dev** | freezed | `^3.2.5` | `3.2.6-dev.1` | 数据类代码生成 |
| **Dev** | mocktail | `^1.0.4` | `1.0.5` | 单元测试 Mock |
| **Dev** | flutter_lints | `^5.0.0` | `5.0.0` | Lint 规则集 |
| **Dev** | flutter_test | SDK | SDK | Flutter 内置测试 |

### 3.2 版本兼容性说明

**版本调整**：原始 spec 中的 `riverpod_annotation ^3.0.0` 和 `riverpod_generator ^3.0.0` 与
`freezed ^3.2.5` 存在 `analyzer` 版本冲突：

| 包 | 需要 analyzer 版本 |
|---|---|
| `freezed >=3.2.5` | `>=9.0.0 <11.0.0` 或 `^12.0.0` |
| `riverpod_generator >=3.0.0 <4.0.1` | `>=7.0.0 <9.0.0` |
| `riverpod_annotation >=3.0.0` | `riverpod 3.0.x`（与 flutter_riverpod 3.3.x 不兼容） |

**解决方法**：
- `riverpod_annotation` 升级至 `^4.0.0`（使用 `riverpod 3.3.x` 系列，兼容 `flutter_riverpod ^3.3.1`）
- `riverpod_generator` 升级至 `^4.0.0`（使用 `analyzer 12.x`，兼容 `freezed ^3.2.5`）

### 3.2 排除的旧依赖

以下依赖**不再包含**（从旧 pubspec.yaml 中移除）：

| 依赖 | 理由 |
|------|------|
| `flutter_adaptive_scaffold` | 不使用第三方响应式库 |
| `adaptive_breakpoints` | 使用内置 LayoutBuilder |
| `connectivity_plus` | 不需要网络状态监听（Dio 错误处理已覆盖） |
| `window_manager` | 桌面平台不在当前 Scope |
| `dartz` | 过度抽象，社区替代考量 |
| `freezed` (dependencies) | 只应在 dev_dependencies 中 |
| `path` | 未使用 |
| `logger` | 未使用 |
| `multiple_result` | Riverpod AsyncValue 已处理三态 |
| `mockito` | 用 mocktail 替代（更简洁） |
| `go_router_builder` | 不使用类型安全路由生成 |
| `golden_toolkit` | golden 测试在 Release 3 暂不引入 |
| `connectivity_plus` | 不在当前 Scope |

### 3.3 静态资源配置

```yaml
flutter:
  uses-material-design: true
  generate: true
```

注释掉 `assets/` 配置——TASK-001 阶段没有静态资源，以避免 `flutter analyze` 因目录不存在而报警。

---

## 4. 目录结构设计

### 4.1 lib/ 目录树

```
kayak-frontend/lib/
├── main.dart              # 应用入口：ProviderScope + KayakApp
├── app.dart               # 应用根：MaterialApp 配置
├── models/                # 数据模型（freezed sealed class）
├── services/              # 通信层（HTTP/WS 封装）
├── providers/             # 状态管理层（Riverpod Notifier）
├── pages/                 # UI 页面层
│   ├── auth/              # 认证页面
│   ├── dashboard/         # 仪表盘页面
│   ├── workbench/         # 工作台页面
│   ├── device/            # 设备页面
│   ├── point/             # 测点页面
│   ├── method/            # 方法页面
│   ├── experiment/        # 试验页面
│   ├── analysis/          # 分析页面
│   └── settings/          # 设置页面
├── widgets/               # 可复用组件
├── theme/                 # 主题配置
├── router/                # 路由配置
├── l10n/                  # 国际化 ARB 文件
└── utils/                 # 工具函数
```

### 4.2 设计原则

| 原则 | 说明 |
|------|------|
| **功能分组** | pages/ 下按功能域分组（auth, workbench...） |
| **sanke_case** | 目录命名使用 snake_case |
| **扁平化** | lib/ 一级只有 main.dart 和 app.dart |
| **空目录** | 所有子目录创建 .gitkeep 占位（Dart 不需要，但确保 git 追踪） |

---

## 5. analysis_options.yaml 设计

### 5.1 规则分类

| 类别 | 关键规则 | 目的 |
|------|----------|------|
| **继承** | `package:flutter_lints/flutter.yaml` | Flutter 官方规则 |
| **排除** | `**/*.g.dart`, `**/*.freezed.dart`, `lib/generated/**` | 跳过生成文件 |
| **严格** | `strict-casts: true`, `strict-raw-types: true` | 类型安全 |
| **风格** | `prefer_single_quotes`, `require_trailing_commas` | 代码风格统一 |
| **质量** | `avoid_print`, `prefer_const_constructors` | 代码质量 |
| **可选** | `public_member_api_docs: false` | 不强制文档 |

### 5.2 严格模式说明

```yaml
analyzer:
  language:
    strict-casts: true     # 禁止隐式类型转换
    strict-raw-types: true # 禁止原始类型参数
```

这两个选项确保类型安全，在重构时非常有价值。

---

## 6. 骨架代码设计

### 6.1 main.dart

```dart
void main() {
  runApp(const ProviderScope(child: KayakApp()));
}
```

最小入口设计：
- `ProviderScope` 包裹 `KayakApp` —— 为后续 Riverpod Provider 做好准备
- `KayakApp` 从 `app.dart` 导入（相对路径）
- 不含任何业务逻辑或异步初始化

### 6.2 app.dart

```dart
class KayakApp extends ConsumerWidget {
  MaterialApp build(...) {
    return MaterialApp(
      title: 'Kayak',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const Scaffold(body: Center(child: Text('Kayak'))),
    );
  }
}
```

最小应用骨架：
- 继承 `ConsumerWidget` —— 为后续 Provider 消费做准备（而非 `StatelessWidget`）
- 使用 `MaterialApp`（不含 router——TASK-004 会替换为 `MaterialApp.router`）
- 浅色/深色主题骨架
- `debugShowCheckedModeBanner: false`

---

## 7. CI/CD 兼容性

当前 CI 配置（`.github/workflows/ci.yml`）需要确认前端 job 与新依赖版本兼容：

| CI Job | 需要适配 | 说明 |
|--------|:--------:|------|
| `flutter pub get` | ✅ | 新依赖版本解析 |
| `dart format` | ✅ | `l10n.yaml` 配置 |
| `flutter analyze --fatal-infos` | ✅ | 严格 lint 规则 |
| `flutter build web` | ✅ | Web 构建 |

CI 配置中的 `flutter_lints` 引用同步更新到 `^5.0.0`。

---

## 8. 测试用例覆盖矩阵

| TC ID | 描述 | 验证方式 | 设计参考 |
|-------|------|:--------:|----------|
| TC-001 | flutter pub get 成功 | 执行命令 | §3 pubspec.yaml |
| TC-002 | 依赖版本验证 | diff 对比 | §3.1 版本表 |
| TC-003 | analysis_options.yaml 配置 | 内容检查 | §5 规则分类 |
| TC-004 | 目录结构验证 | 文件系统检查 | §4 目录树 |
| TC-005 | main.dart ProviderScope | 内容检查 | §6.1 |
| TC-006 | app.dart MaterialApp | 内容检查 | §6.2 |
| TC-007 | flutter analyze 零错误 | 执行命令 | §5 严格模式 |
| TC-008 | flutter analyze 零警告 | 执行命令 | §5 规则 |
| TC-009 | flutter analyze --fatal-infos | 执行命令 | §5 |
| TC-010 | flutter build web | 执行命令 | §3 pubspec.yaml |
| TC-011 | Git 工作区干净 | git status | 仅 kayak-frontend 变更 |
| TC-012 | CI 前端适配 | 内容检查 | §7 |
| TC-013 | pub get 幂等 | 重复执行 | §3 |
| TC-014 | 版本错误测试 | 负向测试 | §3.1 |
| TC-015 | 文件缺失测试 | 负向测试 | §6 |

---

## 9. 风险与缓解

| 风险 | 概率 | 影响 | 缓解方案 |
|------|:----:|:----:|----------|
| 版本不兼容（如 flutter_riverpod 3.x + riverpod_generator 3.x） | 低 | 高 | 使用 flutter pub get 验证，版本号来自 pub.dev 最新稳定 |
| `flutter_lints ^5.0.0` 规则过于严格 | 低 | 中 | 遵循规则修复代码，零警告政策 |
| `flutter_secure_storage 10.x` 需要系统库 | 低 | 中 | CI 已安装 `libsecret-1-dev` |
| build_runner 版本冲突 | 低 | 中 | dev_dependencies 版本锁定 |
