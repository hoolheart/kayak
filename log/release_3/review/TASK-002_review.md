# Code Review Report - TASK-002: 数据模型定义

## Review Information

| 属性 | 内容 |
|------|------|
| **Reviewer** | sw-jerry (Software Architect) |
| **Date** | 2026-05-31 |
| **Branch** | Release 3 / Sprint 1 |
| **审查文件** | 9 model files + generated outputs |
| **关联设计** | `log/release_3/design/TASK-002_design.md` |

---

## Summary

| 属性 | 内容 |
|------|------|
| **Status** | **NEEDS_FIX** (6 issues: 2 Blocker + 2 Critical + 2 Major) |
| **Total Issues** | 6 |
| **Blocker** | 2 |
| **Critical** | 2 |
| **Major** | 2 |
| **Minor** | 0 |
| **Info** | 0 |
| **flutter analyze** | ✅ 零警告 (post build_runner) |

---

## 审查范围

| # | 文件 | 主要类/模型 |
|---|------|-----------|
| 1 | `lib/models/common.dart` | `ApiResponse<T>`, `PaginatedResponse<T>`, `AuthTokens` |
| 2 | `lib/models/user.dart` | `User` |
| 3 | `lib/models/workbench.dart` | `Workbench`, `CreateWorkbenchRequest` |
| 4 | `lib/models/device.dart` | `Device`, `DeviceTreeNode` |
| 5 | `lib/models/point.dart` | `Point`, `PointValue` |
| 6 | `lib/models/method.dart` | `Method`, `MethodParameter` |
| 7 | `lib/models/experiment.dart` | `Experiment`, `ExperimentStatus`, `ExperimentMessage` |
| 8 | `lib/models/team.dart` | `Team` |
| 9 | `lib/models/protocol.dart` | `ProtocolConfig` (sealed union) |

---

## 审查要点逐一检查

### 1. freezed 3.2.5 sealed class 语法 ✅

所有模型正确使用 `@freezed sealed class` 语法。factory constructor + mixin 模式正确。JSON 反序列化工厂函数签名正确。

### 2. json_annotation 4.12.0 字段映射 ✅

`@JsonKey(name: 'snake_case')` 注解正确应用于所有需要 snake_case → camelCase 转换的字段。日期字段全部使用 `DateTime` 类型。

### 3. build_runner 生成 ✅

初步生成成功，无错误输出。但模型字段类型存在问题 (见 Issues)。

### 4. 枚举类型 ✅ (部分)

`ExperimentStatus` 枚举定义正确。但 `Device.protocolType` 和 `Point.dataType`/`Point.accessType` 使用了 `String` 而非强类型枚举 (见 Issue M1, M2)。

---

## Issues Found

### [Blocker] Issue B1: `PaginatedResponse.hasNext`/`hasPrev` 应为 `bool?` 而非 `bool`

- **Location**: `lib/models/common.dart`, `PaginatedResponse` 类
- **Description**: `hasNext` 和 `hasPrev` 字段声明为 `@JsonKey(name: 'has_next') bool hasNext` 和 `@JsonKey(name: 'has_prev') bool hasPrev`，但后端 API 部分列表接口可能不返回 `has_next`/`has_prev` 字段（当后端不使用分页游标时）。使用非可空 `bool` 会导致 JSON 反序列化在字段缺失时抛出 `TypeError`。
- **Impact**: 调用后端某些端点时（如列表返回不带分页信息），应用会崩溃。
- **Recommendation**: 改为 `bool?` 并保持 `@JsonKey` 映射不变：
  ```dart
  @JsonKey(name: 'has_next') bool? hasNext,
  @JsonKey(name: 'has_prev') bool? hasPrev,
  ```
- **Status**: OPEN

---

### [Blocker] Issue B2: `CreateWorkbenchRequest` 缺少 `ownerType` 和 `ownerId` 字段

- **Location**: `lib/models/workbench.dart`, `CreateWorkbenchRequest` 类
- **Description**: 创建请求模型缺少 `owner_type` 和 `owner_id` 字段，与后端 `POST /workbenches` 端点期望的请求体不匹配。后端 API 创建需要这些字段指定所属用户或团队。
- **Impact**: 创建工作台 API 调用将因请求体字段缺失而失败（后端返回 422）。
- **Recommendation**: 添加必需的 `ownerType` 和 `ownerId` 字段：
  ```dart
  @JsonKey(name: 'owner_type') required String ownerType,
  @JsonKey(name: 'owner_id') required String ownerId,
  ```
- **Status**: OPEN

---

### [Critical] Issue C1: `ApiResponse<T>.data` 应为 `required T data`

- **Location**: `lib/models/common.dart`, `ApiResponse<T>` 类
- **Description**: `data` 字段声明为 `T data` 而非 `required T data`。当 `ApiResponse` 表示成功响应时（状态码为 `success` 或 `ok`），`data` 字段始终由后端返回且为非空。当前声明允许构造时省略 `data`，破坏了类型安全。
- **Impact**: 编译时类型检查被削弱——代码可能访问未初始化的 `data` 而不被静态分析捕获。
- **Recommendation**: 改为 `required T data`：
  ```dart
  @freezed
  sealed class ApiResponse<T> with _$ApiResponse<T> {
    const factory ApiResponse({
      required int code,
      @JsonKey(fromJson: _messageFromJson) required String message,
      @JsonKey(fromJson: _dataFromJson) required T data,
    }) = _ApiResponse;
  }
  ```
- **Status**: OPEN

---

### [Critical] Issue C2: `AuthTokens` 缺少 `user` 字段

- **Location**: `lib/models/common.dart`, `AuthTokens` 类
- **Description**: 后端 `POST /auth/login` 和 `POST /auth/refresh` 的 `TokenResponse` 始终包含 `user: User` 对象。`AuthTokens` 模型仅包含 `accessToken`、`refreshToken` 和 `tokenType`，缺少 `user` 字段。应用登录后需要立即使用 `User` 信息填充 UI（如侧边栏用户名、个人资料页），缺少此字段导致需要额外的 `GET /auth/me` 调用。
- **Impact**: 额外网络请求增加登录延迟。应用无法在一次 API 调用后获得完整的认证状态。
- **Recommendation**: 添加 `required User user` 字段并导入 `User` 模型：
  ```dart
  import 'user.dart';

  @freezed
  sealed class AuthTokens with _$AuthTokens {
    const factory AuthTokens({
      @JsonKey(name: 'access_token') required String accessToken,
      @JsonKey(name: 'refresh_token') required String refreshToken,
      @JsonKey(name: 'token_type') required String tokenType,
      required User user,
    }) = _AuthTokens;
  }
  ```
- **Status**: OPEN

---

### [Major] Issue M1: `Device.protocolType` 和 `DeviceTreeNode.protocolType` 应为 `ProtocolType` 枚举而非 `String`

- **Location**: `lib/models/device.dart`, `Device` 和 `DeviceTreeNode` 类
- **Description**: `protocolType` 字段声明为 `@JsonKey(name: 'protocol_type') required String protocolType`。后端使用 serde 派生定义的枚举（`virtual`, `modbus_tcp`, `modbus_rtu`, `can`, `visa`, `mqtt`），应使用强类型 `ProtocolType` 枚举与之对齐。使用 `String` 会丢失编译时类型检查，允许任意字符串值传播到 UI 逻辑。
- **Impact**: 运行时可能遇到未预期的协议类型字符串（如拼写错误、新增协议类型），导致 switch/match 语句丢漏分支。与后端枚举的序列化/反序列化不对齐。
- **Recommendation**: 定义 `ProtocolType` 枚举（带 `@JsonValue` 注解）并替换 `String` 字段：
  ```dart
  enum ProtocolType {
    @JsonValue('virtual') virtual,
    @JsonValue('modbus_tcp') modbusTcp,
    @JsonValue('modbus_rtu') modbusRtu,
    @JsonValue('can') can,
    @JsonValue('visa') visa,
    @JsonValue('mqtt') mqtt,
  }

  // 在 Device 和 DeviceTreeNode 中：
  required ProtocolType protocolType,
  ```
- **Status**: OPEN

---

### [Major] Issue M2: `Point.dataType` 和 `Point.accessType` 应为强类型枚举而非 `String`

- **Location**: `lib/models/point.dart`, `Point` 类
- **Description**: 
  - `dataType` 字段声明为 `@JsonKey(name: 'data_type') required String dataType`，而后端使用 `number`/`integer`/`string`/`boolean` 枚举值。
  - `accessType` 字段声明为 `@JsonKey(name: 'access_type') required String accessType`，而后端使用 `ro`/`wo`/`rw` 枚举值。
  
  两个字段应使用对应的 Dart 枚举类型以保证类型安全。
- **Impact**: 编译时无法检测无效的 dataType/accessType 值。UI 层的 switch 语句（如根据 dataType 显示不同的值渲染组件）可能遗漏分支。
- **Recommendation**: 定义 `DataType` 和 `AccessType` 枚举并替换 `String` 字段：
  ```dart
  enum DataType {
    @JsonValue('number') number,
    @JsonValue('integer') integer,
    @JsonValue('string') string,
    @JsonValue('boolean') boolean,
  }

  enum AccessType {
    @JsonValue('ro') ro,
    @JsonValue('wo') wo,
    @JsonValue('rw') rw,
  }
  ```
- **Status**: OPEN

---

## Architecture Compliance

| 检查项 | 状态 | 说明 |
|--------|:---:|------|
| freezed 3.2.5 sealed class 语法 | ✅ | 所有模型正确使用 |
| json_annotation 4.12.0 @JsonKey | ✅ | snake_case mapping 正确 |
| 字段与后端 API 对齐 | ⚠️ | 4 个模型与后端不一致 (B1, B2, C2, M1, M2) |
| 枚举类型使用 | ⚠️ | protocolType/dataType/accessType 应改为枚举 (M1, M2) |
| 必填字段标记 | ⚠️ | ApiResponse.data 未标记 required (C1) |
| build_runner 生成无错误 | ✅ | 18 个生成文件，0 错误 |
| DDD 模型层分离 | ✅ | models/ 目录正确隔离，无跨层依赖 |

---

## Quality Checks

| 检查项 | 结果 |
|--------|:---:|
| `flutter analyze --fatal-infos` 零警告 | ✅ PASS |
| `build_runner build` 无错误 | ✅ 18 outputs, 0 errors |
| 代码风格 (`analysis_options.yaml`) | ✅ PASS |
| 模型覆盖 task spec (9 模型文件) | ✅ 全部 9 个模型文件已创建 |
| 日期字段使用 DateTime | ✅ |
| `@JsonKey` snake_case → camelCase | ✅ |

---

## Approval

| 条件 | 状态 |
|------|:---:|
| **Blocker 问题全部修复** (B1, B2) | ❌ 待修复 |
| **Critical 问题全部修复** (C1, C2) | ❌ 待修复 |
| **Major 问题全部修复** (M1, M2) | ❌ 待修复 |
| **Approved for TASK-003** | **❌ NEEDS_FIX** |

---

## 结论

**NEEDS_FIX** — 6 个问题需修复后方可进入下一任务 (TASK-003)。

整体模型结构设计合理，freezed 3.2.5 sealed class 语法使用正确，build_runner 生成无错误。但数据模型与后端 API 契约存在多处不对齐：

**建议修复顺序**：
1. **B1, B2** (Blocker) — 字段可选性和缺失必填字段，直接阻塞序列化正确性 — 最高优先
2. **C1, C2** (Critical) — 类型安全缺失，影响编译时检查和登录流程效率
3. **M1, M2** (Major) — 强类型枚举替换，提升类型安全性和与后端对齐程度

修复范围小、风险低，预计 1-2 小时内可完成。修复后需重新运行 `build_runner build` 生成代码。

---

**Next Step**: sw-tom 修复所有 6 个问题后提交 re-review。
