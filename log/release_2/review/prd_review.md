# PRD 评审报告 — Release 2 产品需求文档

**评审人**: sw-jerry (软件架构师)  
**评审日期**: 2026-05-10  
**评审文档**: `log/release_2/prd.md`  
**参考文档**:
- `log/release_2/feasibility_assessment.md` (范围基线)
- `log/release_1/prd.md` (向后兼容基准)
- `arch.md` v1.2 (项目架构文档)

---

## 1. 总体评审结论

**评审结论**: 🔶 **有条件通过** — 存在 3 项必须修复的问题，修复后可批准。

PRD 整体质量良好，范围控制严格，与可行性评估报告保持一致，技术方案基本可行。但在数据库 Schema 兼容性、API 设计规范和响应格式一致性方面存在需要纠正的问题。

---

## 2. 详细评审意见

### 2.1 必须修复（阻塞性问题）

#### ⚠️ 问题 M1: GET 请求使用 JSON Body 传参 — 违反 HTTP 规范

- **位置**: `prd.md` 第 2.1.2 节 — 后端 API: HDF5 时序数据查询
- **问题描述**:
  ```
  GET /api/v1/experiments/{id}/data
  ```
  该 API 使用 JSON Body 传递过滤参数（`device_id`, `point_ids`, `start_time`, `end_time`, `downsample`）。根据 HTTP/1.1 RFC 7231，GET 请求的语义是安全且幂等的请求资源表示，**不应携带请求体（request body）**。虽然某些客户端/服务器技术支持 GET body，但这会导致：
  1. 与标准 HTTP 缓存机制冲突（缓存键基于 URL + Query，不包含 Body）
  2. 部分代理服务器/负载均衡器会丢弃 GET body
  3. 与 OpenAPI/Swagger 等工具的标准生成规则冲突
  4. 与项目现有 API 风格不一致（arch.md 中所有 GET 请求均使用查询参数或路径参数）

- **影响**: 高 — API 设计不规范，可能导致前端 HTTP 客户端（dio/httpx）默认行为不兼容

- **修改建议**（二选一）：
  - **方案 A（推荐）**: 改为 POST 请求
    ```
    POST /api/v1/experiments/{id}/data/query
    Body: { "device_id": "...", "point_ids": [...], ... }
    ```
    因请求参数较复杂（含数组 `point_ids`），POST + JSON Body 是合理选择，且可扩展性更好。
  - **方案 B**: 继续使用 GET，但将所有参数转为查询参数
    ```
    GET /api/v1/experiments/{id}/data?device_id=...&point_ids=...&start_time=...&end_time=...&downsample=1000
    ```
    需注意 `point_ids` 数组在查询参数中的编码方式（如 `point_ids=uuid1&point_ids=uuid2` 或 `point_ids=uuid1,uuid2`）。

---

#### ⚠️ 问题 M2: 数据库 Schema 变更与现有架构冲突

- **位置**: `prd.md` 第 6.1 节 — 数据库变更（修改表部分）
- **问题描述**:
  PRD 建议执行以下 Migration：
  ```sql
  ALTER TABLE workbenches ADD COLUMN owner_type TEXT NOT NULL DEFAULT 'user' 
      CHECK (owner_type IN ('user', 'team'));
  ALTER TABLE workbenches ADD COLUMN owner_team_id UUID REFERENCES teams(id);
  ```
  
  但根据 `arch.md` v1.2 第 5.1.2 节（Release 1 实时 Schema），`workbenches` 表**已经存在**以下字段：
  ```sql
  CREATE TABLE workbenches (
      ...
      owner_type VARCHAR(20) NOT NULL CHECK (owner_type IN ('user', 'team')),
      owner_id UUID NOT NULL,
      ...
  );
  ```
  
  同理，`methods` 和 `data_files` 表也已具备 `owner_type` + `owner_id` 字段组合。
  
  这会导致：
  1. **Migration 执行失败**: `ALTER TABLE ... ADD COLUMN owner_type` 会因字段已存在而报错
  2. **设计冗余**: PRD 引入 `owner_team_id` 与现有 `owner_id` 字段语义冲突。现有架构使用 `owner_type` + `owner_id` 的**多态外键**设计（`owner_type` 标识类型，`owner_id` 指向具体用户或团队ID），这是 Release 1 已实现的方案
  3. **数据一致性风险**: 若同时维护 `owner_id` 和 `owner_team_id`，可能出现两者不一致的情况

- **影响**: 高 — Migration 无法执行，且会破坏现有数据模型设计

- **修改建议**:
  1. **删除**为 `workbenches`/`methods`/`data_files` 添加 `owner_type` 的 ALTER 语句（这些字段已存在）
  2. **删除** `owner_team_id` 字段设计，继续使用现有 `owner_id` + `owner_type` 多态外键模式
  3. 为 `experiments` 表补充说明：当前 `experiments` 表仅有 `user_id` 字段，若需支持团队实验，应统一添加 `owner_type` + `owner_id`（与现有表模式对齐），或保留 `user_id` 作为执行者，新增 `owner_type`/`owner_id` 作为资源所有者
  4. 在 Migration 脚本中确保 `owner_type` 默认值和约束与现有数据兼容（现有数据在 Release 1 中应已全部为 `'user'`）

---

#### ⚠️ 问题 M3: API 响应格式与项目标准不一致

- **位置**: `prd.md` 第 2.1.2 节 — 响应格式
- **问题描述**:
  PRD 中定义的响应格式：
  ```json
  {
    "experiment_id": "uuid",
    "device_id": "uuid",
    "points": [...],
    "total_samples": 86400,
    "returned_samples": 1000
  }
  ```
  
  但 `arch.md` 第 6.1.1 节明确定义了项目的标准响应格式：
  ```json
  {
    "code": 200,
    "message": "success",
    "data": { ... },
    "timestamp": "2024-03-15T10:30:00Z"
  }
  ```
  
  PRD 的响应格式缺少 `code`/`message`/`timestamp` 包裹层，与 Release 1 所有已有 API 的响应风格不一致。这会导致：
  1. 前端需要为这一个 API 编写特殊的响应解析逻辑
  2. 破坏 API 一致性原则
  3. 与 `arch.md` 中定义的 `ApiResponse` 结构体不匹配

- **影响**: 高 — 破坏前后端 API 契约一致性

- **修改建议**:
  将响应格式调整为项目标准：
  ```json
  {
    "code": 200,
    "message": "success",
    "data": {
      "experiment_id": "uuid",
      "device_id": "uuid",
      "points": [...],
      "total_samples": 86400,
      "returned_samples": 1000
    },
    "timestamp": "2026-05-10T12:00:00Z"
  }
  ```
  
  同时，建议在整个 PRD 第 4 节（API 接口汇总）中，统一明确所有新增/扩展 API 的响应格式遵循 `arch.md` 标准。

---

### 2.2 建议修改（非阻塞，但强烈建议）

#### 💡 问题 S1: 时序数据"分页加载"描述不清晰

- **位置**: `prd.md` 第 2.1.4 节 — 图表技术方案
- **问题描述**:
  > "数据加载：分页加载，首次加载最近 1000 点，滚动到边界时预加载"
  
  "分页加载"和"滚动到边界时预加载"的表述更适合列表/表格场景。时序数据是连续的时间序列，用户在图表上进行的是**缩放**和**平移**操作，而非"滚动"。这里的"边界"概念不明确：是指时间范围的边界？还是数据点的索引边界？

- **影响**: 中 — 可能导致前端实现与设计意图不符

- **修改建议**:
  明确描述为基于**时间范围**的分段加载策略：
  > "数据加载：基于时间范围分段加载。首次加载时，后端根据图表视口自动计算合适的时间范围（如最近 1 小时或最近 1000 点，取较大者），返回降采样后的数据。当用户通过缩放/平移操作将视口移出已加载时间范围时，前端根据新的时间窗口触发增量加载请求。"

---

#### 💡 问题 S2: 团队资源删除策略未定义

- **位置**: `prd.md` 第 2.2.2 节 / 第 2.2.3 节
- **问题描述**:
  PRD 定义了团队的创建、更新、删除 API，但未说明删除团队时对团队资源（工作台、方法、试验、数据文件）的处理策略。如果团队下有资源，直接删除团队会因外键约束失败（如 `devices.workbench_id → workbenches.id` 的 ON DELETE CASCADE 链）。

- **影响**: 中 — 可能导致 DELETE /api/v1/teams/{id} 实现时出现未定义行为

- **修改建议**:
  在 PRD 中明确以下策略之一：
  1. **级联删除**（高风险）：删除团队时，自动删除所有团队资源。需在 PRD 中明确并增加确认对话框的 UI 需求
  2. **禁止删除非空团队**（推荐）：若团队下存在任何资源，删除 API 返回 `409 Conflict`，提示用户先转移或删除资源
  3. **资源转移**：删除团队前，将所有资源转移给团队所有者（Owner）的个人账户
  
  **推荐方案 2**，并在 API 文档中补充错误响应：
  ```json
  {
    "code": 409,
    "message": "Team has associated resources",
    "data": {
      "resource_counts": {
        "workbenches": 3,
        "methods": 2,
        "experiments": 5
      }
    }
  }
  ```

---

#### 💡 问题 S3: 缺少成员主动离开团队的功能

- **位置**: `prd.md` 第 2.2.3 节 — 成员管理 API
- **问题描述**:
  PRD 定义了管理员/所有者移除成员的 API（`DELETE /api/v1/teams/{id}/members/{user_id}`），但未定义**成员主动退出团队**的 API。这是团队协作系统的基本功能。

- **影响**: 中 — 功能不完整

- **修改建议**:
  补充以下 API：
  ```
  DELETE /api/v1/teams/{id}/members/me
  ```
  - 认证用户主动退出指定团队
  - 约束：团队所有者（Owner）不能退出，必须先转移所有权或删除团队
  - 响应：204 No Content 或标准成功响应

---

#### 💡 问题 S4: 时间戳数组的性能与格式问题

- **位置**: `prd.md` 第 2.1.2 节 — 响应格式
- **问题描述**:
  响应中的 `timestamps` 字段使用 ISO 8601 字符串数组：
  ```json
  "timestamps": ["2026-05-01T00:00:00Z", "2026-05-01T00:00:01Z"]
  ```
  
  对于 10,000 个数据点，时间戳字符串的序列化/反序列化开销显著：
  - 每个 ISO 8601 字符串约 24-25 字节（含引号）
  - 10,000 个时间戳 ≈ 240KB JSON 文本
  - 若改用 Unix 时间戳（毫秒，64位整数），10,000 个仅需 ~80KB
  - 前端 fl_chart 通常使用 `DateTime` 或 `double`（毫秒纪元）作为 X 轴数据，字符串还需额外解析

- **影响**: 中 — 大数据量时增加不必要的网络传输和 CPU 开销

- **修改建议**:
  将时间戳格式改为 **Unix 时间戳（毫秒）**，与 fl_chart 的 `FlSpot(x, y)` 中 `x` 通常使用 `double`（时间毫秒）的实践一致：
  ```json
  {
    "point_id": "uuid",
    "point_name": "Temperature",
    "unit": "°C",
    "data_type": "float32",
    "timestamps": [1714521600000, 1714521601000],
    "values": [25.3, 25.4]
  }
  ```
  
  若业务上需要可读时间，可在响应元数据中增加 `timezone` 字段，由前端本地化格式化。

---

#### 💡 问题 S5: 团队所有者设计的冗余与一致性问题

- **位置**: `prd.md` 第 2.2.2 节 — Team 实体 / TeamMember 实体
- **问题描述**:
  - `Team` 表有 `owner_id` 字段（"创建者 User ID"）
  - `TeamMember` 表有 `role` 字段，包含 `Owner` 枚举值
  
  这造成了**数据冗余**：团队所有者的信息同时存储在两个地方。若两者不一致（如数据库直接修改、`owner_id` 未更新但 `TeamMember.role` 已变更），会导致权限判断错误。

- **影响**: 中 — 潜在的数据不一致风险

- **修改建议**（二选一）：
  - **方案 A（推荐）**: 删除 `Team.owner_id` 字段，团队所有者通过 `TeamMember` 表中 `role = 'Owner'` 的记录查询。这是更规范的多对多关系设计
  - **方案 B**: 保留 `Team.owner_id`，但增加数据库约束/触发器确保与 `TeamMember` 表中 Owner 记录一致，并在 PRD 中明确同步机制

---

#### 💡 问题 S6: LTTB 降采样算法实现来源未明确

- **位置**: `prd.md` 第 2.1.2 节 / 第 6.2 节
- **问题描述**:
  PRD 指定使用 LTTB（Largest Triangle Three Buckets）算法进行降采样，但未说明该算法是自行实现还是使用第三方 Rust crate。Rust 生态中 LTTB 的实现选择有限，可能需要自行实现或移植。

- **影响**: 低 — 可能导致 Sprint 1 工时低估

- **修改建议**:
  在 PRD 中明确：
  1. 优先调研 Rust 生态中是否有可用的 LTTB crate（如 `lttb` crate，但需验证维护状态）
  2. 若无可用的 crate，需自行实现（预估额外 2-4h 工作量）
  3. 提供 LTTB 算法的参考资料或伪代码

---

#### 💡 问题 S7: 团队名称唯一性约束范围未明确

- **位置**: `prd.md` 第 6.1 节 — teams 表
- **问题描述**:
  `teams` 表的 `name` 字段没有 `UNIQUE` 约束。可行性评估的 Sprint 2 任务清单中提到"团队名称唯一性校验"，但未说明是**全局唯一**还是**用户范围内唯一**。

- **影响**: 低 — 可能导致命名冲突

- **修改建议**:
  明确约束范围：
  - **推荐**: 用户范围内唯一（一个用户不能创建两个同名团队），不同用户可拥有同名团队
  - 在数据库层面添加部分唯一索引：
    ```sql
    CREATE UNIQUE INDEX idx_teams_name_owner ON teams(name, owner_id);
    ```
  - 若使用方案 A（删除 owner_id），则改为基于 TeamMember 中 Owner 的用户 ID 的约束

---

#### 💡 问题 S8: Python SDK 与现有目录的关系未明确

- **位置**: `prd.md` 第 2.4.2 节 — SDK 架构
- **问题描述**:
  PRD 中 Python SDK 的目录结构显示为独立的 `kayak-sdk/` 目录，但 `arch.md` 第 9.1 节显示项目中已存在 `kayak-python-client/` 目录（标记为"维护模式"）。PRD 未说明是替换现有目录、在现有目录上重构，还是新建独立仓库。

- **影响**: 低 — 可能导致项目结构混乱

- **修改建议**:
  在 PRD 中明确：
  1. Python SDK 的开发位置（`kayak-python-client/` 还是新的 `kayak-sdk/`）
  2. 与现有 `kayak-python-client/` 的关系（废弃/迁移/并行）
  3. 是否作为独立 PyPI 包发布，还是作为 monorepo 子包管理

---

### 2.3 疑问（需要澄清）

#### ❓ 问题 Q1: 团队切换时的页面状态管理策略

- **位置**: `prd.md` 第 2.3.3 节 — 团队选择器
- **问题描述**:
  > "切换团队后，所有页面（工作台、方法、数据）自动过滤为当前团队资源"
  
  若用户正在查看团队 A 的某个工作台详情页（如 `/workbenches/{workbench_a_id}`），此时切换到团队 B，该工作台 ID 对团队 B 不可见。前端应如何处理？
  - 强制导航到工作台列表页？
  - 显示"资源不存在"错误？
  - 保留页面但显示空状态？

- **建议**: 在 PRD 或相关 UI 设计文档中明确状态切换的导航策略。推荐方案：切换团队后，若当前页面资源不在新团队范围内，则重定向到该模块的列表页（如 `/workbenches`）。

---

#### ❓ 问题 Q2: 邀请码的生成机制与安全性

- **位置**: `prd.md` 第 2.2.4 节 — 邀请机制
- **问题描述**:
  PRD 提到"生成 7 天有效期的邀请码"，但未说明：
  1. 邀请码的格式（UUID？随机字符串？）
  2. 长度和熵（安全性）
  3. 是否支持一次性使用（使用后失效）
  4. 过期后的清理机制

- **建议**: 明确邀请码为加密安全的随机字符串（如 32 字符 Base64URL，熵 ≥ 192 bit），一次性使用，过期后由定时任务或懒清理机制删除。

---

#### ❓ 问题 Q3: HDF5 并发读取的具体实现方案

- **位置**: `prd.md` 第 3.2 节 — 可靠性需求
- **问题描述**:
  PRD 提到"后端读取时不阻塞写入（使用 HDF5 SWMR 模式或快照副本）"，但：
  1. `hdf5-rs` crate 对 SWMR（Single-Writer-Multiple-Reader）模式的支持情况未确认
  2. "快照副本"方案会临时复制 HDF5 文件，对大文件（GB 级）性能影响大
  3. 试验执行过程中 HDF5 文件可能处于打开写入状态，直接读取可能失败

- **建议**: 在详细设计阶段明确实现方案。推荐调研 `hdf5-rs` 的 SWMR 支持；如不支持，可考虑在试验结束后标记 HDF5 文件为"可安全读取"，或采用"写入时复制（Copy-on-Write）"的读取策略。

---

#### ❓ 问题 Q4: `experiments` 表的团队归属改造

- **位置**: `prd.md` 第 6.1 节 — 修改表
- **问题描述**:
  PRD 提到"为 methods 和 experiments 添加类似字段（如需要）"，但 `experiments` 表当前结构使用 `user_id` 字段（见 `arch.md` 第 5.1.2 节），语义是"执行试验的用户"。若试验需要支持团队归属，需要明确：
  1. `user_id` 是否保留（作为执行者记录）？
  2. 是新增 `owner_type`/`owner_id` 字段，还是将 `user_id` 泛化为 `owner_id`？

- **建议**: 保留 `user_id` 作为执行者审计字段，新增 `owner_type` + `owner_id` 作为资源所有者字段（与 workbenches/methods 对齐）。

---

## 3. 范围合规性评审

| 检查项 | 结果 | 说明 |
|--------|------|------|
| 与可行性评估范围一致 | ✅ 通过 | 仅包含时序绘图 + 团队管理 + Python SDK，正确排除了可视化编辑器、协议驱动、频谱分析等 |
| 未超出 2 Sprint 容量 | ✅ 通过 | Sprint 1 (10 任务 ~50h) + Sprint 2 (14 任务 ~72h)，与可行性评估的容量估算一致 |
| P1 任务无遗漏 | ✅ 通过 | 可行性评估建议纳入 R2 的 P1 任务（时序绘图、团队管理）均已包含 |
| 范围蔓延控制 | ✅ 通过 | 明确将可视化编辑器、协议驱动、频谱分析等移至 R3，并在 PRD 第 1.3 节清晰列出 |

---

## 4. 技术可行性评审

| 检查项 | 结果 | 说明 |
|--------|------|------|
| fl_chart 技术方案 | ✅ 可行 | 已纳入 arch.md 技术栈（v0.66），Web 支持已验证。风险已识别（R2-RISK-01）并准备降级方案 |
| HDF5 查询 API 设计 | ⚠️ 有条件可行 | 核心设计合理（时间范围过滤 + 降采样），但 GET body 问题必须修复（问题 M1） |
| 团队管理数据模型 | ⚠️ 有条件可行 | 关系设计合理，但与现有 schema 冲突必须解决（问题 M2、S5） |
| 数据库 Migration | ❌ 有风险 | 现有 `owner_type` 字段已存在，PRD 中的 ALTER 语句会失败（问题 M2） |
| LTTB 降采样 | ⚠️ 需确认 | Rust 生态支持情况需调研，可能需自行实现（问题 S6） |
| Python SDK 架构 | ✅ 可行 | 架构清晰，依赖合理（httpx + h5py + pandas/numpy 可选） |

---

## 5. API 设计质量评审

| 检查项 | 结果 | 说明 |
|--------|------|------|
| RESTful 规范一致性 | ❌ 有问题 | GET body 违反规范（问题 M1） |
| 与现有 API 风格一致 | ❌ 有问题 | 响应格式缺少标准包裹层（问题 M3） |
| 路由冲突检查 | ✅ 通过 | 所有新增路由与 arch.md 中已有路由无冲突 |
| 认证/授权中间件 | ✅ 通过 | `RequireTeamRole` extractor 设计符合现有 `RequireAuth` 风格 |
| 错误处理完整性 | ⚠️ 需补充 | 未定义错误响应格式，建议补充标准错误码（如 403 Forbidden 的角色不足、409 Conflict 的团队非空等） |

---

## 6. 完整性与兼容性评审

| 检查项 | 结果 | 说明 |
|--------|------|------|
| 关键功能点覆盖 | ✅ 完整 | 时序绘图、团队管理、Python SDK 三大模块功能点覆盖全面 |
| 非功能需求 | ✅ 完整 | 性能、可靠性、兼容性、安全需求均已定义 |
| 验收标准可验证 | ✅ 可验证 | 验收标准明确，包含验证方式（单元测试/手动验证/pytest） |
| 向后兼容性 | ⚠️ 有风险 | 现有 API 不变更的承诺正确，但数据库 Migration 设计会破坏 Release 1 的 schema（问题 M2） |
| 前端路由冲突 | ✅ 无冲突 | `/analysis`、`/teams`、`/teams/{id}`、`/teams/{id}/members` 均不与现有路由冲突 |

---

## 7. 批准条件

本 PRD 在以下问题修复后可正式批准：

1. **修复问题 M1**: 将 `GET /api/v1/experiments/{id}/data` 改为 POST，或改为使用查询参数的 GET
2. **修复问题 M2**: 修正数据库 Migration 设计，兼容现有 `owner_type` + `owner_id` 的 schema，删除 `owner_team_id` 设计
3. **修复问题 M3**: 统一新增 API 的响应格式为项目标准格式（code/message/data/timestamp）

**建议修复**（强烈建议但不阻塞批准）：
- 问题 S1: 澄清时序数据加载策略描述
- 问题 S2: 定义团队资源删除策略
- 问题 S3: 补充成员主动退出团队 API
- 问题 S4: 考虑使用时间戳数值格式替代 ISO 字符串
- 问题 S5: 统一团队所有者数据模型设计

---

## 8. 批准理由（条件满足后）

一旦上述 3 项必须修复的问题解决，本 PRD 可批准的理由：

1. **范围控制严格**: 正确执行了可行性评估的建议，将高风险、高工时的任务（可视化编辑器、协议驱动）果断移至 Release 3，确保 2 周内可交付高质量产出
2. **技术方案可行**: 时序数据绘图（fl_chart + LTTB 降采样）、团队管理（标准 RBAC 模型）、Python SDK（httpx + h5py）均为成熟技术方案
3. **用户价值明确**: 三大功能模块（数据分析可视化、团队协作、程序化访问）形成完整的用户价值闭环
4. **与现有架构兼容**: 新增 API 和前端路由与 Release 1 无冲突，可在现有架构上平滑扩展
5. **风险识别充分**: 已识别 fl_chart Web 性能、HDF5 并发读写、数据迁移等关键风险，并制定了缓解策略

---

**评审人签名**: sw-jerry  
**日期**: 2026-05-10
