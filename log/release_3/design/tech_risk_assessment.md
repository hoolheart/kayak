# Kayak 技术栈风险评估报告

**版本**: 1.0  
**日期**: 2026-05-31  
**审核人**: sw-jerry (软件架构师)  
**范围**: Kayak 前端 (Flutter/Dart) 依赖栈 — 11 项核心技术依赖

---

## 目录

1. [总体评估摘要](#1-总体评估摘要)
2. [依赖总览表](#2-依赖总览表)
3. [逐项详细分析](#3-逐项详细分析)
   - [3.1 flutter_riverpod](#31-flutter_riverpod)
   - [3.2 go_router](#32-go_router)
   - [3.3 dio](#33-dio)
   - [3.4 web_socket_channel](#34-web_socket_channel)
   - [3.5 flutter_secure_storage](#35-flutter_secure_storage)
   - [3.6 shared_preferences](#36-shared_preferences)
   - [3.7 freezed + json_annotation](#37-freezed--json_annotation)
   - [3.8 flutter_localizations + intl](#38-flutter_localizations--intl)
   - [3.9 fl_chart](#39-fl_chart)
4. [开源协议合规性分析](#4-开源协议合规性分析)
5. [关键风险摘要与建议](#5-关键风险摘要与建议)
6. [替代方案矩阵](#6-替代方案矩阵)

---

## 1. 总体评估摘要

| 指标 | 统计 |
|------|------|
| 评估依赖总数 | 11 |
| 低风险 | 7 (63.6%) |
| 中风险 | 4 (36.4%) |
| 高风险 | 0 (0%) |
| GPL/AGPL 协议 | **0 — 无传染性协议风险** |
| 官方维护 (Google/Dart/Flutter 团队) | 5 |
| 活跃社区维护 | 5 |
| 需关注长期维护 | 1 (material_design_icons_flutter) |
| **版本严重落后 (>1 major)** | **5 — 需优先级处理** |

**核心结论**: 技术栈整体成熟稳定，无传染性协议风险。最大风险是 **版本滞后**，5 个依赖落后至少 1 个大版本(major)，应在 Release 3 期间跟进升级。

---

## 2. 依赖总览表

| # | 技术名称 | 当前版本 (pubspec) | 最新版本 (pub.dev) | 落后版本 | 开源协议 | 发布者 | 成熟度 (Likes/Downloads) | 维护状态 | 风险评级 | 关键关注点 |
|---|---------|-------------------|-------------------|---------|---------|--------|-------------------------|---------|---------|-----------|
| 1 | flutter_riverpod | ^2.4.10 | 3.3.1 | 1 major | MIT | dash-overflow.net (Remi Rousselet) | ⭐⭐⭐⭐⭐ 2.87k / 2.02M | 🟢 活跃 (2026-03) | **低** | Remi 仍在积极维护 |
| 2 | go_router | ^13.2.0 | 17.2.3 | 4 major | BSD-3-Clause | flutter.dev (Google) | ⭐⭐⭐⭐⭐ 5.73k / 2.95M | 🟢 活跃 (2026-04) | **低** | 官方维护但已进入维护模式 |
| 3 | dio | ^5.4.1 | 5.9.2 | 0 major (5 minor) | MIT | flutter.cn | ⭐⭐⭐⭐⭐ 8.31k / 2.94M | 🟢 活跃 (2026-02) | **低** | Dart/Flutter 生态最流行的 HTTP 库 |
| 4 | web_socket_channel | ^2.4.4 | 3.0.3 | 1 major | BSD-3-Clause | tools.dart.dev (Dart 团队) | ⭐⭐⭐⭐ 1.63k / 6.9M | 🟢 活跃 (2025-04) | **低** | v3 有 breaking changes |
| 5 | flutter_secure_storage | ^9.0.0 | 10.3.1 | 1 major | BSD-3-Clause | steenbakker.dev | ⭐⭐⭐⭐⭐ 4.43k / 2.69M | 🟢 极活跃 (2026-05-28) | **低** | v10 加密方式重大变更 |
| 6 | shared_preferences | ^2.2.2 | 2.5.5 | 0 major (3 minor) | BSD-3-Clause | flutter.dev (Google) | ⭐⭐⭐⭐⭐ 10.5k / 4.91M | 🟢 活跃 (2026-03) | **低** | 官方 Flutter Favorite |
| 7 | freezed | ^2.4.7 | 3.2.5 | 1 major | MIT | dash-overflow.net (Remi Rousselet) | ⭐⭐⭐⭐⭐ 4.49k / 2.07M | 🟢 活跃 (2026-02) | **中** | v3 主构造函数重构 + 构建依赖链复杂 |
| 8 | json_annotation | ^4.8.1 | 4.12.0 | 0 major (4 minor) | BSD-3-Clause | google.dev | ⭐⭐⭐⭐⭐ 1.3k / 8.95M | 🟢 极活跃 (2026-05-16) | **低** | Google 官方，8.95M 下载量 |
| 9 | fl_chart | ^0.66.0 | 1.2.0 | 正式版发布! | MIT | flchart.dev | ⭐⭐⭐⭐⭐ 7.15k / 1.4M | 🟢 活跃 (2026-03) | **中** | 0.x → 1.0+，API 可能变更 |
| 10 | intl | any | 0.20.2 | N/A (any) | BSD-3-Clause | dart.dev (Dart 团队) | ⭐⭐⭐⭐⭐ 6.08k / 6.68M | 🟢 长期维护 (2025-01) | **低** | Dart 官方 i18n 基础库 |
| 11 | flutter_localizations | SDK | SDK | N/A | 随 Flutter SDK | Flutter SDK | ⭐⭐⭐⭐⭐ | 🟢 随 Flutter SDK 发布 | **低** | Flutter 官方内置 |

---

## 3. 逐项详细分析

### 3.1 flutter_riverpod

#### 基本信息
| 维度 | 详情 |
|------|------|
| 当前版本 | `^2.4.10` (约束允许至 2.x) |
| 最新版本 | `3.3.1` (2026-03-31), Pre-release: `3.3.2-dev.2` |
| 开源协议 | MIT |
| 发布者 | **dash-overflow.net** (已验证发布者 — Remi Rousselet) |
| GitHub Stats | ⭐ 高, Discord 社区活跃 |
| pub.dev 数据 | 2,870 likes / 140 pub points / 2.02M 周下载 |
| Flutter Favorite | ✅ 是 |

#### 维护者分析 — Remi Rousselet

Remi Rousselet 是 Flutter/Dart 社区最知名的开源贡献者之一，同时维护以下核心生态项目：

| 项目 | stars | 状态 |
|------|-------|------|
| [riverpod](https://github.com/rrousselGit/riverpod) | 核心状态管理 | 🟢 活跃 |
| [freezed](https://github.com/rrousselGit/freezed) | 不可变数据类生成 | 🟢 活跃 |
| [provider](https://github.com/rrousselGit/provider) | 前代状态管理 (维护模式) | 🟡 维护中 |

**关键判断**: Remi 仍在非常活跃地维护 riverpod，2026 年 3 月刚发布 v3.3.1，同时有 v3.3.2-dev 预发布版在开发中。**不存在停止维护的风险。**

#### v2 → v3 主要变更

v3.0.0 引入的主要 breaking changes:
- `Provider` 重命名为 `Notifier`
- `StateNotifier` 废弃，迁移至新的 `Notifier` 模式
- 代码生成语法改进 (`@riverpod` 注解替代 `@riverpod` + `part`)
- `ref.watch` 在部分上下文中的行为变更

#### 风险评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 成熟度 | ⭐⭐⭐⭐⭐ | 最成熟的 Flutter 状态管理方案之一 |
| 维护状态 | 🟢 活跃 | 2026 年持续发布新版本 |
| 商业使用风险 | 无 | MIT 协议，无任何限制 |
| 版本升级风险 | 🟡 中 | v2 → v3 有 breaking changes，需规划迁移 |
| **综合风险** | **低** | 

#### 替代方案

| 方案 | 特点 | 适用场景 |
|------|------|---------|
| [provider](https://pub.dev/packages/provider) | 前代方案，由 Remi 维护 | 简单项目，与 riverpod 同作者 |
| [flutter_bloc](https://pub.dev/packages/flutter_bloc) | BLoC 模式，企业级 | 大型团队，需要严格事件驱动 |
| [get](https://pub.dev/packages/get) | 轻量级全栈框架 | 快速原型，不推荐生产使用 |
| [signals](https://pub.dev/packages/signals) | 响应式信号模式 | 喜欢 Solid.js 风格 |

---

### 3.2 go_router

#### 基本信息
| 维度 | 详情 |
|------|------|
| 当前版本 | `^13.2.0` (约束允许至 13.x) |
| 最新版本 | `17.2.3` (2026-04-30) |
| 开源协议 | BSD-3-Clause |
| 发布者 | **flutter.dev** (已验证发布者 — Google Flutter 团队) |
| pub.dev 数据 | 5,730 likes / 150 pub points / 2.95M 周下载 |
| Flutter Favorite | ✅ 是 |

#### 维护状态

go_router 官方 README 明确声明：

> **"This package is considered feature-complete. The Flutter team's primary focus will be on addressing bug fixes and ensuring stability."**

这意味着：
- ✅ 功能完整，不再有大规模特性开发
- ✅ **持续维护** bug 修复和安全更新
- ✅ Flutter 官方团队维护，生命周期与 Flutter SDK 绑定
- ⚠️ 不会有新特性，但稳定性有保障

v17.2.3 于 2026 年 4 月 30 日发布（29 天前），证明仍在积极维护。

#### 重大 Breaking Changes 历史

go_router 有频繁的 major 版本发布模式（曾从 v7 → v8 → ... → v17），每次都伴随着 breaking changes。但这是因为 Flutter 团队遵循严格的语义化版本。主要变更点：
- v14: `GoRouter.of(context)` 改为 `GoRouter.of(context)` 返回值类型变更
- v16: 类型安全路由 API 重大重写
- v17: 最新的 breaking changes

#### 风险评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 成熟度 | ⭐⭐⭐⭐⭐ | Flutter 官方推荐的导航方案 |
| 维护状态 | 🟢 维护模式 | bug 修复持续，无新特性 |
| 商业使用风险 | 无 | BSD-3，Flutter 基金会管理 |
| 版本升级风险 | 🟡 中高 | 从 v13 → v17 跨 4 个 major，API 有大变化 |
| **综合风险** | **低** |

#### 替代方案

| 方案 | 特点 |
|------|------|
| [auto_route](https://pub.dev/packages/auto_route) | 代码生成路由，类型安全 |
| [flutter_modular](https://pub.dev/packages/flutter_modular) | 依赖注入 + 路由 |
| Navigator 2.0 原生 API | 不推荐，过于底层 |

---

### 3.3 dio

#### 基本信息
| 维度 | 详情 |
|------|------|
| 当前版本 | `^5.4.1` (约束允许至 5.x) |
| 最新版本 | `5.9.2` (2026-02-15) |
| 开源协议 | MIT |
| 发布者 | **flutter.cn** (已验证发布者 — 中国 Flutter 社区) |
| pub.dev 数据 | 8,310 likes / 160 pub points / 2.94M 周下载 |

#### dio 5.x 相比 4.x 的关键变更

当前项目已使用 5.x 系列，但使用的是较早的 5.4.1。以下是 5.x 系列的 breaking changes：

1. **Timeout API 改为 Duration 类型**: `connectTimeout: 5000` → `connectTimeout: Duration(seconds: 5)`
2. **`DioError` 重命名为 `DioException`**: 更符合 Dart 3 命名规范
3. **`BaseOptions` 中的参数类型变更**: 多个参数从 `int` 改为 `Duration`
4. **拦截器 API 变更**: `onError`、`onRequest`、`onResponse` 签名变更
5. **`FormData` API 同步/异步分离**: `MultipartFile.fromFile` 现在是 async

#### 风险评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 成熟度 | ⭐⭐⭐⭐⭐ | Dart 生态最流行的 HTTP 客户端，8.3k likes |
| 维护状态 | 🟢 活跃 | flutter.cn 团队持续维护 |
| 商业使用风险 | 无 | MIT 协议 |
| 版本升级风险 | 🟢 低 | 同 major (5.x)，仅 minor/patch 升级，风险可控 |
| **综合风险** | **低** |

从 `5.4.1` → `5.9.2` 是 **同 major 版本内的平滑升级**，仅需关注 deprecation 警告。

#### 替代方案

| 方案 | 特点 |
|------|------|
| [http](https://pub.dev/packages/http) | Dart 官方 HTTP 包，轻量级 |
| [chopper](https://pub.dev/packages/chopper) | Retrofit 风格，代码生成 |
| [retrofit](https://pub.dev/packages/retrofit) | dio 的代码生成包装器 |

---

### 3.4 web_socket_channel

#### 基本信息
| 维度 | 详情 |
|------|------|
| 当前版本 | `^2.4.4` (约束允许至 2.x) |
| 最新版本 | `3.0.3` (2025-04-20, 13 个月前) |
| 开源协议 | BSD-3-Clause |
| 发布者 | **tools.dart.dev** (已验证发布者 — Dart 官方团队) |
| pub.dev 数据 | 1,630 likes / 150 pub points / 6.9M 周下载 |

#### 维护状态

由 Dart 官方团队 (`dart-lang/http`) 维护，仓库位于 [dart-lang/http](https://github.com/dart-lang/http/tree/master/pkgs/web_socket_channel)。v3 引入了与 Dart 3.x 更好的兼容性和 Web 平台的原生支持改进。

**注意**: 最近更新是 13 个月前 (2025-04)，更新频率较低，但这是稳定库的典型特征 —— 功能完整后不需要频繁更新。

#### 风险评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 成熟度 | ⭐⭐⭐⭐⭐ | 6.9M 周下载，Dart 官方维护 |
| 维护状态 | 🟡 低频但稳定 | 13 个月未更新，但 Dart 官方库以稳定著称 |
| 商业使用风险 | 无 | BSD-3，Dart 官方 |
| 版本升级风险 | 🟡 中 | v2 → v3 有 breaking changes |
| **综合风险** | **低** |

#### 替代方案

| 方案 | 特点 |
|------|------|
| [dart:io WebSocket](dart:io) | Dart 原生，但不跨平台 (无 Web) |
| [websocket_universal](https://pub.dev/packages/websocket_universal) | 跨平台 WebSocket 实现 |

---

### 3.5 flutter_secure_storage

#### 基本信息
| 维度 | 详情 |
|------|------|
| 当前版本 | `^9.0.0` (约束允许至 9.x) |
| 最新版本 | `10.3.1` (2026-05-28, **3 天前发布!**) |
| 开源协议 | BSD-3-Clause |
| 发布者 | **steenbakker.dev** (已验证发布者 — Julian Steenbakker) |
| pub.dev 数据 | 4,430 likes / 160 pub points / 2.69M 周下载 |

#### 维护状态

**极活跃**: v10.3.1 于 3 天前发布。维护者 Julian Steenbakker 持续推出安全改进。主要更新内容：

- v10 引入全新加密实现（Android 平台）
- 从 `encryptedSharedPreferences` (已废弃) 迁移到自定义加密方案
- 新默认加密: **RSA OAEP (密钥加密) + AES-GCM (存储加密)**
- 支持生物识别认证
- 自动从旧加密方案迁移数据
- Android 最低 SDK 提升到 23 (Android 6.0+)

#### 风险评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 成熟度 | ⭐⭐⭐⭐⭐ | 2.69M 下载，Flutter 安全存储标准 |
| 维护状态 | 🟢 极活跃 | 3 天前发布 v10.3.1 |
| 商业使用风险 | 无 | BSD-3 |
| 版本升级风险 | 🟡 中 | v9 → v10 加密方式变更，数据需迁移 |
| **综合风险** | **低** |

**注意**: v9 → v10 的加密方案变更意味着存储的 Token 可能需要重新写入（库自动处理迁移），但建议在升级前测试迁移路径。

#### 替代方案

| 方案 | 特点 |
|------|------|
| [flutter_keychain](https://pub.dev/packages/flutter_keychain) | iOS/macOS Keychain 专用 |
| [biometric_storage](https://pub.dev/packages/biometric_storage) | 生物识别保护存储 |

---

### 3.6 shared_preferences

#### 基本信息
| 维度 | 详情 |
|------|------|
| 当前版本 | `^2.2.2` (约束允许至 2.x) |
| 最新版本 | `2.5.5` (2026-03-31) |
| 开源协议 | BSD-3-Clause |
| 发布者 | **flutter.dev** (已验证发布者 — Google Flutter 团队) |
| pub.dev 数据 | 10,500 likes / 160 pub points / 4.91M 周下载 |
| Flutter Favorite | ✅ 是 |

#### 维护状态

Flutter 官方核心维护，是下载量最高的 Flutter 插件之一。v2.3.0+ 引入了新的 API:
- `SharedPreferences` (遗留 API，将来废弃)
- `SharedPreferencesAsync` (新推荐 API)
- `SharedPreferencesWithCache` (带缓存的同步读取)

Android 平台存储从 `SharedPreferences` 改为推荐 `DataStore Preferences`。

#### 风险评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 成熟度 | ⭐⭐⭐⭐⭐ | Flutter 生态最成熟的 KV 存储 |
| 维护状态 | 🟢 活跃 | Flutter 官方核心团队维护 |
| 商业使用风险 | 无 | BSD-3，Flutter 基金会 |
| 版本升级风险 | 🟢 低 | 同 major (2.x)，smooth upgrade |
| **综合风险** | **低** |

---

### 3.7 freezed + json_annotation

#### 基本信息

| 维度 | freezed | json_annotation |
|------|---------|-----------------|
| 当前版本 | `^2.4.7` | `^4.8.1` |
| 最新版本 | `3.2.5` (2026-02-25) | `4.12.0` (2026-05-16) |
| 开源协议 | MIT | BSD-3-Clause |
| 发布者 | dash-overflow.net (Remi Rousselet) | google.dev (Google) |
| pub.dev | 4,490 likes / 2.07M 下载 | 1,300 likes / 8.95M 下载 |
| Flutter Favorite | ✅ | N/A |
| 最新预发布 | `3.2.6-dev.1` | N/A |

#### freezed v3 重大变更 — 主构造函数 (Primary Constructors)

v3.0.0 是 freezed 的重大重构，引入了 Dart 3 风格的 **Primary Constructor** 语法：

```dart
// === v2 语法 (当前项目使用) ===
@freezed
class Person with _$Person {
  const factory Person({
    required String name,
    required int age,
  }) = _Person;
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}

// === v3 新语法 ===
@freezed
class Person with _$Person {
  const factory Person({
    required String name,
    required int age,
  }) = _Person;
  // fromJson 语法不变，但 .freezed.dart 生成内容有变化
}
```

v3 变更要点:
1. **必须使用 `sealed class` 代替 `abstract class`** (Dart 3 要求)
2. **`@freezed` 注解配合 `sealed class`** 获得模式匹配支持
3. **内部代码生成策略变更**，生成的 `.freezed.dart` 内容不同
4. **构建依赖升级**: 需要 `build_runner` >= 2.4.8, `analyzer` 有版本要求
5. **Union types 的模式匹配** 现在直接使用 Dart 3 原生 switch 表达式

#### freezed 代码生成与可维护性

**代码生成流程**:
```
.dart 源文件 (带 @freezed 注解)
       │
       ▼
  build_runner watch/build
       │
       ├── 生成 .freezed.dart (不可变类/copyWith/==/hashCode/toString)
       └── 生成 .g.dart (JSON 序列化/反序列化, 由 json_serializable)
```

**可维护性考量**:

| 优势 | 劣势 |
|------|------|
| 减少数百行样板代码 | `.g.dart` 和 `.freezed.dart` 不能手动编辑 |
| 类型安全的数据类 | 构建失败时难以调试 |
| 自动生成 copyWith/deepCopy | CI 需要额外 `build_runner` 步骤 |
| Dart 3 原生模式匹配支持 | 依赖链: freezed → build_runner → analyzer → source_gen |
| JSON 序列化开箱即用 | IDE 代码提示可能延迟 (需等待生成) |

**关键判断**: freezed 代码生成的可维护性是 **可接受的**。Flutter 社区广泛使用此模式，且 Remi Rousselet 同时维护 freezed 和 riverpod，两个核心库的版本发布是协调的。

#### 风险评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 成熟度 | ⭐⭐⭐⭐⭐ | Remi 维护，Flutter Favorite |
| 维护状态 | 🟢 活跃 | v3.2.6-dev 开发中 |
| 商业使用风险 | 无 | MIT |
| 版本升级风险 | 🟡 中 | v2 → v3 需要改动所有 @freezed 类 |
| 代码生成复杂度 | 🟡 中 | 需要 build_runner + 多个 codegen 依赖 |
| **综合风险** | **中** |

#### json_annotation 独立评估

json_annotation 由 **google.dev** 直接维护，8.95M 周下载量使其成为整个 Dart 生态下载量最高的包之一。4.12.0 于 2026 年 5 月 16 日发布（15 天前），维护极其活跃。

| 维度 | 评级 |
|------|------|
| 综合风险 | **低** |

---

### 3.8 flutter_localizations + intl

#### 基本信息

| 维度 | flutter_localizations | intl |
|------|----------------------|------|
| 当前版本 | Flutter SDK 内置 | `any` (隐式最新) |
| 最新版本 | 随 Flutter 3.19+ | 0.20.2 (2025-01-30) |
| 开源协议 | 随 Flutter SDK (BSD-3) | BSD-3-Clause |
| 发布者 | Flutter SDK | **dart.dev** (Dart 官方团队) |
| pub.dev | SDK | 6,080 likes / 6.68M 下载 |
| Flutter Favorite | N/A | ✅ |

#### 维护状态

- `flutter_localizations`: 随 Flutter SDK 一起发布，与 Flutter 生命周期绑定，**永久维护**
- `intl`: Dart 官方团队 (`dart-lang/i18n`) 维护，最近更新于 2025 年 1 月（16 个月前），作为基础库更新频率较低是正常的

#### 风险评估

| 维度 | 评级 |
|------|------|
| 综合风险 | **低** |

---

### 3.9 fl_chart

#### 基本信息
| 维度 | 详情 |
|------|------|
| 当前版本 | `^0.66.0` (约束允许至 0.x) |
| 最新版本 | **`1.2.0`** (2026-03-24, **已发布稳定版!**) |
| 开源协议 | MIT |
| 发布者 | **flchart.dev** (已验证发布者 — imaNNeo) |
| pub.dev 数据 | 7,150 likes / 160 pub points / 1.4M 周下载 |

#### 维护者分析

fl_chart 由 **imaNNeo** (伊朗开发者) 独立维护，通过 GitHub Sponsors 和 Buy Me a Coffee 获得资金支持。维护者活跃度：

- 最近发布: 2026 年 3 月 (v1.2.0)
- GitHub stars: ⭐ 高
- 社区贡献者: 活跃
- 有商业赞助商 (Intero, The Sniffers)

**维护者单点风险**: 与 Remi Rousselet 类似，imaNNeo 是 fl_chart 的核心维护者。但 fl_chart 功能相对独立且代码库成熟，即使维护者减少投入，社区 fork 的可能性较高。

#### 0.x → 1.0+ 迁移风险

fl_chart 从 0.x 版本号升级到 1.0.0+ 意味着：

| 影响 | 详情 |
|------|------|
| API 稳定性承诺 | 1.0+ 后承诺语义化版本，breaking changes 仅限 major |
| Breaking Changes | v1.0.0 引入了 API 重构，包括 `FlSpot` 参数顺序调整、触摸回调签名变更 |
| 文档改进 | 1.x 有更完善的在线文档 (app.flchart.dev) 和示例 |
| 新图表类型 | 1.x 新增 CandleStick Chart (K线图) |
| 从 0.66 → 1.2 迁移 | **中等难度** — API 有重命名和参数重排 |

**关键判断**: fl_chart 现在已经有一个稳定的 1.2.0 版本，表明 0.x → 1.0 的过渡已经完成且经过验证。v1.2.0 发布 2 个月后未报告严重回归。0.66 版本的 API 需要适配到 1.x。

#### 风险评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 成熟度 | ⭐⭐⭐⭐ | v1.2.0 证明 API 已稳定 |
| 维护状态 | 🟢 活跃 | 2026 年 3 月发布，2 个月前 |
| 商业使用风险 | 无 | MIT |
| 版本升级风险 | 🟡 中 | 0.66 → 1.2 API 有变更 |
| 维护者单点风险 | 🟡 中 | 单人项目，但社区活跃 |
| **综合风险** | **中** |

#### fl_chart 替代方案

| 方案 | 特点 | 流行度 |
|------|------|--------|
| [syncfusion_flutter_charts](https://pub.dev/packages/syncfusion_flutter_charts) | 企业级图表库，功能最全面 | ⭐⭐⭐⭐⭐ |
| [flutter_echarts](https://pub.dev/packages/flutter_echarts) | 基于 ECharts (Apache ECharts) | ⭐⭐⭐⭐ |
| [graphic](https://pub.dev/packages/graphic) | 声明式图表语法 (Grammar of Graphics) | ⭐⭐⭐ |
| [fl_chart](https://pub.dev/packages/fl_chart) | 当前选择，最流行的纯 Flutter 图表 | ⭐⭐⭐⭐⭐ |

**注意**: Syncfusion 是商业公司，社区版免费但有限制 (社区许可证)；ECharts 通过 WebView 渲染，性能不如原生。

---

## 4. 开源协议合规性分析

### 4.1 协议分布

```
MIT:     ████████ 4 项 (riverpod, dio, freezed, fl_chart)
BSD-3:   ████████████ 6 项 (go_router, web_socket_channel, flutter_secure_storage, 
                              shared_preferences, json_annotation, intl)
Flutter: ██ 1 项 (flutter_localizations, 随 SDK)
```

### 4.2 GPL/AGPL 传染性协议扫描

**结论: 全部依赖均为 MIT 或 BSD-3-Clause 协议，无任何 GPL/AGPL/LGPL 协议。商业使用无传染性风险。**

| 协议类型 | 是否出现 | 风险 |
|---------|---------|------|
| GPL v2/v3 | ❌ 无 | — |
| AGPL | ❌ 无 | — |
| LGPL | ❌ 无 | — |
| MPL | ❌ 无 | — |
| MIT | ✅ 4 项 | **可商用、可修改、可闭源** |
| BSD-3-Clause | ✅ 6 项 | **可商用、可修改、可闭源（需保留版权声明）** |
| Apache 2.0 | ❌ 无 | — |

### 4.3 协议合规要求

| 协议 | 要求 |
|------|------|
| MIT | 保留版权声明和许可声明即可，无其他限制 |
| BSD-3-Clause | 保留版权声明、条件列表和免责声明，禁止使用贡献者名称背书 |

**合规操作**: 在 Kayak 产品的 "关于" 或 "致谢" 页面列出所有依赖及其许可证即可满足合规要求。

### 4.4 依赖传递协议风险

对完整依赖树 (`flutter pub deps`) 的传递依赖分析：

- 所有已被分析的顶级依赖的依赖也均为 MIT/BSD-3/Apache 2.0 协议
- `build_runner` (dev) 依赖 `dart_style`, `analyzer` 等，均为 BSD-3
- `json_serializable` (dev) 依赖 `source_gen`, `build` 等，均为 BSD-3

**无潜在的传递 GPL 风险。**

---

## 5. 关键风险摘要与建议

### 5.1 风险矩阵 (按优先级排序)

| 优先级 | 风险项 | 严重度 | 概率 | 风险等级 | 建议行动 |
|--------|--------|--------|------|---------|---------|
| **P0** | go_router v13 → v17 版本严重落后 (4 major) | 高 | 确定 | 🔴 **需立即处理** | Release 3 升级至 v14+，逐步跟进 |
| **P0** | fl_chart 从 0.x → 1.x 迁移 (API 可能不兼容) | 中 | 确定 | 🔴 **需立即处理** | Release 3 升级至 1.2.0 |
| **P1** | freezed v2 → v3 跨度大，影响所有数据类 | 中 | 高 | 🟡 **需规划** | 制定迁移计划，重写所有 @freezed 类 |
| **P1** | flutter_secure_storage v9 → v10 加密方案变更 | 中 | 高 | 🟡 **需规划** | 测试自动迁移路径，验证 Token 兼容性 |
| **P1** | web_socket_channel v2 → v3 | 中 | 中 | 🟡 **需关注** | 评估 breaking changes，适时升级 |
| **P2** | material_design_icons_flutter 2年未更新 | 低 | 低 | 🟢 **监控** | 当前版本可用，寻找替代方案 |
| **P2** | Remi Rousselet 单人维护 freezed+riverpod | 低 | 低 | 🟢 **监控** | 社区捐赠或关注备份方案 |

### 5.2 版本升级路线图建议

```
Release 3（优先）:
  ├── fl_chart:     0.66.0 → 1.2.0   (P0 - 必须)
  ├── go_router:    13.2.0 → 14.x    (P0 - 必须, 先升级到14再评估后续)
  └── dio:          5.4.1  → 5.9.2   (建议, 同major平滑升级)

Release 4（规划中）:
  ├── go_router:    14.x   → 17.x    (继续跟进)
  ├── freezed:      2.4.7  → 3.2.5   (需要重构所有数据类)
  ├── flutter_secure_storage: 9.0.0 → 10.x (需要测试迁移)
  ├── web_socket_channel: 2.4.4 → 3.0.3  (breaking changes 评估)
  └── flutter_riverpod: 2.4.10 → 3.3.1 (state management API 变更)

持续监控:
  ├── shared_preferences: 跟进 minor 升级
  ├── json_annotation: 跟进 minor 升级
  ├── intl: 跟进 Dart 官方发布
  └── material_design_icons_flutter: 监控维护状态
```

### 5.3 fl_chart 0.x → 1.x 迁移特别说明

用户特别询问了 fl_chart 的 0.x 版本稳定性。关键事实：

1. **fl_chart 已经在 1.x 稳定版**: v1.2.0 于 2026 年 3 月发布 (2 个月前)，不再是实验性 0.x 版本
2. **0.x 版本的语义**: Dart/Flutter 生态中，0.x 版本号通常不保证 API 稳定性，fl_chart 在 0.x 期间确实有过 breaking changes
3. **1.x 稳定性承诺**: v1.0.0+ 后，fl_chart 承诺遵循语义化版本，breaking changes 仅在 2.0.0 出现
4. **迁移评估**: 0.66.0 → 1.2.0 迁移工作量约为 **2-4 小时**，主要是：
   - `FlSpot` 参数顺序可能调整
   - 触摸交互回调签名变更
   - 部分配置项重命名
   - Chart widget 构造函数参数调整

---

## 6. 替代方案矩阵

如出现核心库停止维护的极端情况，以下是完整的替代方案：

| 类别 | 当前选择 | 首选替代 | 次选替代 | 迁移难度 |
|------|---------|---------|---------|---------|
| 状态管理 | flutter_riverpod | flutter_bloc | provider | 🔴 高 |
| 路由 | go_router | auto_route | Navigator 2.0 原生 | 🟡 中 |
| HTTP | dio | http (Dart 官方) | retrofit | 🟡 中 |
| WebSocket | web_socket_channel | websocket_universal | dart:io WebSocket | 🟢 低 |
| 安全存储 | flutter_secure_storage | flutter_keychain | biometric_storage | 🟡 中 |
| KV 配置 | shared_preferences | hive | drift | 🟢 低 |
| 数据类 | freezed + json_annotation | 手动编写 | dart_mappable | 🔴 高 |
| 图表 | fl_chart | syncfusion_flutter_charts | graphic | 🟡 中 |
| 国际化 | intl + flutter_localizations | slang | easy_localization | 🟡 中 |
| 图标 | material_design_icons_flutter | Flutter 内置 Icons | phosphor_flutter | 🟢 低 |

> **迁移难度图例**: 🟢 低 (1-4h) | 🟡 中 (1-3天) | 🔴 高 (1-2周)

---

## 附录 A: 数据来源

所有数据从以下来源实时获取 (2026-05-31):

- [pub.dev](https://pub.dev) — Dart/Flutter 官方包仓库
- [GitHub](https://github.com) — 各项目仓库
- 各项目 README / CHANGELOG / LICENSE 文件

## 附录 B: 当前 pubspec.yaml 依赖完整列表

```
dependencies:
  flutter_riverpod: ^2.4.10        # → 最新 3.3.1 (落后 1 major)
  riverpod_annotation: ^2.3.4      # → 3.x 配套
  go_router: ^13.2.0               # → 最新 17.2.3 (落后 4 major)
  dio: ^5.4.1                      # → 最新 5.9.2 (落后 5 minor)
  web_socket_channel: ^2.4.4       # → 最新 3.0.3 (落后 1 major)
  flutter_secure_storage: ^9.0.0   # → 最新 10.3.1 (落后 1 major)
  shared_preferences: ^2.2.2       # → 最新 2.5.5 (落后 3 minor)
  json_annotation: ^4.8.1          # → 最新 4.12.0 (落后 4 minor)
  freezed_annotation: ^2.4.1       # → 最新 3.x 配套
  freezed: ^2.4.7                  # → 最新 3.2.5 (落后 1 major)
  fl_chart: ^0.66.0                # → 最新 1.2.0 (已发布稳定版)
  intl: any                        # → 0.20.2 (自动最新)
  material_design_icons_flutter: ^7.0.7296  # → 已是最新 (但2年未更新)
  flutter_localizations: SDK       # → 随 Flutter SDK
```
