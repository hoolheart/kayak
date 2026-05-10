# Release 2 产品需求文档 (PRD)

**版本**: 2.0  
**日期**: 2026-05-10  
**状态**: Draft — 待评审  
**范围**: Sprint 1-2 (共2周)  
**基于**: Release 1 验收报告 + 可行性评估报告 v1.0

---

## 1. 版本概述

### 1.1 版本目标

Release 2 的核心目标有两个：
1. **数据分析可视化**：实现时序数据绘图工具，让用户能够可视化查看试验采集的数据
2. **团队协作与程序化访问**：实现团队管理功能和 Python SDK，支持多用户协作和程序化数据访问

### 1.2 与 Release 1 的关系

Release 1 已完成平台基础框架：
- ✅ 用户认证与授权（JWT + bcrypt）
- ✅ 工作台/设备/测点管理（Virtual + Modbus TCP/RTU）
- ✅ 试验方法编辑与执行引擎
- ✅ 数据采集与 HDF5 存储
- ✅ Material Design 3 全新 UI
- ✅ Web 模式部署
- ✅ 设备连接/断开管理

Release 2 在此基础上扩展：
- 🆕 **时序数据绘图工具**（多曲线、缩放、平移、光标测量）
- 🆕 **团队管理功能**（创建、邀请、角色分配、资源共享）
- 🆕 **团队管理 UI**（团队设置、成员管理、团队切换）
- 🆕 **Python SDK**（REST API 封装、认证、数据下载、pandas/numpy 集成）
- 🆕 **分析页面**（`/analysis` 路由，图表展示与交互）

### 1.3 版本范围决策

| 模块 | 包含 | 说明 |
|------|------|------|
| 时序数据绘图工具 | ✅ | Sprint 1 核心，含后端 HDF5 查询 API |
| 团队管理后端 | ✅ | Sprint 2 核心，Team/TeamMember CRUD + 邀请机制 |
| 团队管理前端 | ✅ | Sprint 2 核心，团队设置/成员管理/团队切换 |
| Python SDK 核心 | ✅ | Sprint 2 并行，HTTP 封装 + 认证 + 数据接口 |
| Python SDK 数据下载 | ✅ | Sprint 2，HDF5 → pandas/numpy |
| 可视化流程图编辑器 | ❌ | 移至 Release 3（技术风险高，2周内容不下） |
| CAN/VISA/MQTT 协议驱动 | ❌ | 移至 Release 3+（模拟设备工作量翻倍） |
| 频谱分析/数据处理 | ❌ | 移至 Release 3（依赖时序绘图基础） |
| 细粒度权限控制 | ❌ | 移至 Release 3（依赖团队管理） |
| 部署扩展/性能优化 | ❌ | 移至 Release 3+ |

### 1.4 用户价值主张

> **Release 2 让用户能够：在浏览器中查看试验数据的时序曲线图，创建团队并与同事共享工作台和方法，以及使用 Python 脚本批量下载和分析试验数据。**

---

## 2. 功能需求

### 2.1 时序数据绘图工具 (R2-ANALYSIS-001)

#### 2.1.1 功能描述

实现试验数据的时序可视化组件，支持从 HDF5 存储中读取历史数据并以图表形式展示。用户可以选择试验、设备和测点，查看对应的时序曲线。

#### 2.1.2 后端 API — HDF5 时序数据查询

**POST /api/v1/experiments/{id}/data/query**

查询指定试验的数据，支持按设备、测点、时间范围过滤。使用 POST 请求以支持复杂查询参数（含数组 `point_ids`）。

请求体：
```json
{
  "device_id": "uuid",
  "point_ids": ["uuid1", "uuid2"],
  "start_time": "2026-05-01T00:00:00Z",
  "end_time": "2026-05-01T23:59:59Z",
  "downsample": 1000
}
```

响应格式（遵循项目标准 ApiResponse 格式）：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "experiment_id": "uuid",
    "device_id": "uuid",
    "points": [
      {
        "point_id": "uuid",
        "point_name": "Temperature",
        "unit": "°C",
        "data_type": "float32",
        "timestamps": [1714521600000, 1714521601000],
        "values": [25.3, 25.4]
      }
    ],
    "total_samples": 86400,
    "returned_samples": 1000
  },
  "timestamp": "2026-05-10T12:00:00Z"
}
```

**时间戳格式**：使用 Unix 时间戳（毫秒），减少序列化开销，与 fl_chart 的 `double` X 轴数据类型兼容。

**数据降采样策略**：
- 当数据点超过 `downsample` 参数时，后端使用 LTTB（Largest Triangle Three Buckets）算法进行降采样
- 默认 `downsample` = 1000，最大支持 10000
- 降采样在 Rust 后端完成，减少前端渲染压力
- **LTTB 实现**：Rust 生态中无可用的成熟 LTTB crate，需自行实现（预估额外 2-4h 工作量）

#### 2.1.3 前端图表组件功能

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 单曲线显示 | P0 | 基础时序折线图，X轴时间，Y轴数值 |
| 多曲线叠加 | P0 | 同时显示 ≥4 条曲线，不同颜色 |
| 图例交互 | P0 | 点击图例隐藏/显示对应曲线 |
| 鼠标滚轮缩放 | P0 | X轴时间范围缩放，Y轴自适应 |
| 拖拽平移 | P0 | 按住左键左右平移时间轴 |
| 十字光标 | P0 | 跟随鼠标，显示当前时间点的所有曲线值 |
| 数据提示框 | P0 | 悬停显示 (timestamp, value, point_name) |
| 差值测量 | P1 | 选择两个点，显示 Δt 和 Δvalue |
| 视图复位 | P1 | 一键恢复初始视图范围 |
| 导出图片 | P2 | 将当前图表保存为 PNG |

#### 2.1.4 图表技术方案

- **图表库**: `fl_chart` (Flutter 图表库，已验证 Web 支持)
- **数据加载**: 基于时间范围的分段加载。首次加载时，后端根据图表视口自动计算合适的时间范围（如最近 1 小时或最近 1000 点，取较大者），返回降采样后的数据。当用户通过缩放/平移操作将视口移出已加载时间范围时，前端根据新的时间窗口触发增量加载请求
- **性能目标**: 10,000 数据点流畅交互，100,000 数据点通过降采样后流畅交互
- **主题适配**: 自动适配深色/浅色主题

#### 2.1.5 分析页面布局

```
┌─────────────────────────────────────────────────────────────┐
│  AppBar: 分析工作台 │ 团队选择器 │ 用户头像                    │
├──────────────┬──────────────────────────────────────────────┤
│              │                                              │
│  控制面板    │           图表展示区                         │
│  ┌────────┐  │  ┌──────────────────────────────────────┐   │
│  │ 试验选择 │  │  │                                      │   │
│  │ 设备选择 │  │  │      时序折线图 (fl_chart)            │   │
│  │ 测点选择 │  │  │                                      │   │
│  │ 时间范围 │  │  │   ┌──┐    ┌──┐    ┌──┐    ┌──┐      │   │
│  │ 降采样   │  │  │   │图│    │图│    │图│    │图│      │   │
│  │ 刷新    │  │  │   │例│    │例│    │例│    │例│      │   │
│  └────────┘  │  │   └──┘    └──┘    └──┘    └──┘      │   │
│              │  └──────────────────────────────────────┘   │
│              │                                              │
│              │  ┌──────────────────────────────────────┐   │
│              │  │  数据表格（可选显示原始数据）          │   │
│              │  └──────────────────────────────────────┘   │
│              │                                              │
└──────────────┴──────────────────────────────────────────────┘
```

---

### 2.2 团队管理功能 (R2-TEAM-001)

#### 2.2.1 功能描述

实现团队创建、成员邀请、角色分配和资源共享机制。用户可以在个人工作台和团队工作台之间切换，团队内的资源（工作台、方法、数据）对成员可见。

#### 2.2.2 数据模型

**Team 实体**：
```rust
struct Team {
    id: Uuid,
    name: String,
    description: Option<String>,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
```

**TeamMember 实体**：
```rust
struct TeamMember {
    id: Uuid,
    team_id: Uuid,
    user_id: Uuid,
    role: TeamRole,          // Owner / Admin / Member
    invited_by: Option<Uuid>,
    joined_at: DateTime<Utc>,
}

enum TeamRole {
    Owner,   // 拥有者：可删除团队、转移所有权
    Admin,   // 管理员：可邀请/移除成员、管理团队资源
    Member,  // 成员：可查看和使用团队资源
}
```

**团队所有者查询**：通过 `TeamMember` 表中 `role = 'Owner'` 的记录查询，避免数据冗余。

**资源共享模型**：
- 现有 `workbenches`, `methods`, `data_files` 表已具备 `owner_type` (`'user' | 'team'`) 和 `owner_id` 字段（Release 1 已实现的多态外键设计）
- 当 `owner_type = 'team'` 时，`owner_id` 指向团队 ID
- `experiments` 表保留现有 `user_id` 作为执行者审计字段，新增 `owner_type` + `owner_id` 作为资源所有者（与 workbenches/methods 对齐）
- 保留现有数据兼容性：所有现有数据的 `owner_type` 为 `'user'`

#### 2.2.3 后端 API

**团队 CRUD**：
- `POST /api/v1/teams` — 创建团队（自动将创建者设为 Owner）
  - 响应标准格式：`{ code: 201, message: "Team created", data: { team: {...}, invitation: null }, timestamp: "..." }`
- `GET /api/v1/teams` — 获取当前用户所属团队列表
- `GET /api/v1/teams/{id}` — 获取团队详情（含成员列表）
- `PUT /api/v1/teams/{id}` — 更新团队信息（Owner/Admin）
- `DELETE /api/v1/teams/{id}` — 删除团队（仅 Owner）
  - **删除策略**：若团队下存在任何资源（工作台、方法、试验），返回 `409 Conflict`，提示用户先转移或删除资源
  - 错误响应：`{ code: 409, message: "Team has associated resources", data: { resource_counts: { workbenches: 3, methods: 2, experiments: 5 } }, timestamp: "..." }`

**成员管理**：
- `POST /api/v1/teams/{id}/invitations` — 邀请成员（Admin/Owner）
  - 请求体：`{ "email": "user@example.com", "role": "Member" }`
  - 生成 7 天有效期的邀请码（32 字符 Base64URL 随机字符串，熵 ≥ 192 bit，一次性使用）
- `POST /api/v1/teams/invitations/{code}/accept` — 接受邀请
- `DELETE /api/v1/teams/{id}/members/{user_id}` — 移除成员（Admin/Owner，不能移除 Owner）
- `DELETE /api/v1/teams/{id}/members/me` — 成员主动退出团队
  - 约束：团队 Owner 不能退出，必须先转移所有权或删除团队
- `PUT /api/v1/teams/{id}/members/{user_id}/role` — 修改成员角色（Owner）

**团队资源**：
- `GET /api/v1/workbenches?scope=team&team_id={id}` — 查询团队工作台
- 现有工作台创建 API 使用 `owner_type` 和 `owner_id` 参数（`owner_id` 在 `owner_type='team'` 时为团队 ID）

**所有新增 API 响应格式**：统一遵循项目标准 `ApiResponse` 格式：`{ code, message, data, timestamp }`

#### 2.2.4 邀请机制

- 邀请通过邮件发送（Phase 1: 仅生成邀请码，前端显示复制链接；Phase 2: 集成邮件服务）
- 邀请码 7 天有效，一次性使用
- 被邀请用户必须已注册，未注册用户需先注册

#### 2.2.5 权限检查

- 新增 `RequireTeamRole` Axum extractor
- API 中间件自动检查用户是否属于目标团队，以及是否有足够角色权限
- 团队资源的访问权限继承自团队成员身份

---

### 2.3 团队管理 UI (R2-TEAM-003)

#### 2.3.1 功能描述

实现团队管理相关的前端页面和组件，集成到现有导航结构中。

#### 2.3.2 页面清单

| 页面 | 路由 | 功能 |
|------|------|------|
| 团队列表 | `/teams` | 显示用户所属的所有团队，支持创建新团队 |
| 团队详情/设置 | `/teams/{id}` | 团队信息编辑、成员列表、邀请功能 |
| 成员管理 | `/teams/{id}/members` | 成员列表、角色修改、移除成员 |

#### 2.3.3 全局组件

**团队选择器**（AppBar 中）：
- DropdownButton 显示当前选中的团队/个人
- 选项：`个人工作台` + 用户所属的所有团队列表
- 切换团队后，所有页面（工作台、方法、数据）自动过滤为当前团队资源
- **状态管理策略**：切换团队时，若当前页面资源不在新团队范围内（如正在查看团队 A 的工作台详情，切换到团队 B），前端自动重定向到该模块的列表页（如 `/workbenches`），避免显示"资源不存在"错误

**资源创建对话框**：
- 新增 `owner_type` 选择：`个人` / `团队`
- 选择 `团队` 时，默认使用当前选中的团队

---

### 2.4 Python SDK (R2-PYTHON-001 / R2-PYTHON-002)

#### 2.4.1 功能描述

开发 Python 客户端库，提供对 Kayak REST API 的封装，支持用户认证、仪器数据读取、试验数据下载和本地分析。

#### 2.4.2 SDK 架构与目录位置

Python SDK 在现有 `kayak-python-client/` 目录基础上重构，替换维护模式下的旧代码。

```
kayak-python-client/
├── kayak/
│   ├── __init__.py
│   ├── client.py        # KayakClient 主类
│   ├── auth.py          # 认证管理（Token 自动刷新）
│   ├── exceptions.py    # 异常体系
│   ├── models.py        # 数据模型（Pydantic）
│   ├── devices.py       # 设备/测点接口
│   ├── experiments.py   # 试验管理接口
│   ├── data.py          # 数据下载与转换
│   └── utils.py         # 工具函数
├── tests/
│   ├── test_client.py
│   ├── test_auth.py
│   └── test_data.py
├── examples/
│   └── basic_usage.py
├── pyproject.toml
└── README.md
```

#### 2.4.3 核心 API

**KayakClient**：
```python
from kayak import KayakClient

client = KayakClient(base_url="http://localhost:8080")
client.login("admin@kayak.local", "Admin123")

# 设备管理
devices = client.devices.list()
device = client.devices.get("uuid")
point_value = client.devices.read_point("device_uuid", "point_uuid")

# 试验管理
experiments = client.experiments.list(status="running")
exp = client.experiments.get("uuid")

# 数据下载
data = client.data.download("experiment_uuid", format="hdf5")
df = data.to_dataframe()  # pandas DataFrame
arr = data.to_numpy()     # numpy ndarray
```

**认证管理**：
- 自动 Token 刷新（在 Token 过期前 5 分钟自动刷新）
- 支持上下文管理器：`with KayakClient(...) as client:`

**数据转换**：
- `to_dataframe()`: 返回 `pandas.DataFrame`，列 = 测点名称，行 = 时间戳
- `to_numpy()`: 返回 `numpy.ndarray`
- `save(path)`: 保存 HDF5 文件到本地路径

#### 2.4.4 异常体系

```python
class KayakError(Exception): pass
class AuthenticationError(KayakError): pass
class ConnectionError(KayakError): pass
class NotFoundError(KayakError): pass
class ServerError(KayakError): pass
```

#### 2.4.5 依赖要求

- Python >= 3.9
- `httpx` >= 0.25.0（HTTP 客户端）
- `h5py` >= 3.8.0（HDF5 读写）
- `pandas` >= 2.0.0（可选，用于 `to_dataframe()`）
- `numpy` >= 1.24.0（可选，用于 `to_numpy()`）

---

## 3. 非功能需求

### 3.1 性能需求

| 指标 | 要求 | 说明 |
|------|------|------|
| 图表初始加载 | < 2s | 1000 数据点从后端到渲染 |
| 图表交互响应 | < 100ms | 缩放/平移/光标移动 |
| HDF5 数据查询 | < 3s | 10万样本降采样后返回 |
| 团队列表加载 | < 500ms | 含成员数量统计 |
| Python SDK 首次调用 | < 1s | 认证 + 首个 API 请求 |

### 3.2 可靠性需求

| 指标 | 要求 | 说明 |
|------|------|------|
| 图表数据加载失败 | 友好提示 | 显示错误信息和重试按钮 |
| 团队切换 | 状态保持 | 切换团队后当前页面状态不丢失 |
| Python SDK Token 过期 | 自动刷新 | 在 401 响应后自动刷新并重试 |
| HDF5 并发读取 | 无冲突 | 试验结束后标记 HDF5 文件为"可安全读取"；读取时使用文件级只读打开。若试验进行中需读取，采用文件快照副本策略（临时复制后读取） |

### 3.3 兼容性需求

| 指标 | 要求 | 说明 |
|------|------|------|
| 浏览器支持 | Chrome/Edge/Firefox/Safari 最新2个版本 | Web 部署目标 |
| 屏幕分辨率 | >= 1280px 宽度 | 桌面优先 |
| Python 版本 | 3.9 / 3.10 / 3.11 / 3.12 | SDK 支持 |
| 向后兼容 | 现有 API 不变 | Release 1 功能不受影响 |

### 3.4 安全需求

| 指标 | 要求 | 说明 |
|------|------|------|
| 团队资源隔离 | 严格 | 用户只能访问自己团队和个人资源 |
| 邀请码过期 | 7天 | 防止长期有效邀请被滥用 |
| 角色权限检查 | 服务端强制 | 所有团队相关 API 都需校验角色 |
| Python SDK HTTPS | 支持 | 支持 `https://` 基础 URL |

---

## 4. API 接口汇总

### 4.1 新增后端 API

所有新增 API 的响应格式统一遵循项目标准 `ApiResponse`：`{ code, message, data, timestamp }`。

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| POST | `/api/v1/experiments/{id}/data/query` | 获取试验时序数据 | JWT |
| POST | `/api/v1/teams` | 创建团队 | JWT |
| GET | `/api/v1/teams` | 获取用户团队列表 | JWT |
| GET | `/api/v1/teams/{id}` | 获取团队详情 | JWT |
| PUT | `/api/v1/teams/{id}` | 更新团队信息 | JWT + Admin |
| DELETE | `/api/v1/teams/{id}` | 删除团队 | JWT + Owner |
| POST | `/api/v1/teams/{id}/invitations` | 邀请成员 | JWT + Admin |
| POST | `/api/v1/teams/invitations/{code}/accept` | 接受邀请 | JWT |
| DELETE | `/api/v1/teams/{id}/members/{user_id}` | 移除成员 | JWT + Admin |
| DELETE | `/api/v1/teams/{id}/members/me` | 成员主动退出 | JWT |
| PUT | `/api/v1/teams/{id}/members/{user_id}/role` | 修改角色 | JWT + Owner |

### 4.2 扩展现有 API

| 方法 | 路径 | 变更 |
|------|------|------|
| GET | `/api/v1/workbenches` | 新增 `scope` 和 `team_id` 查询参数 |
| POST | `/api/v1/workbenches` | 请求体新增 `owner_type` 和 `owner_team_id` |

---

## 5. UI/UX 需求

### 5.1 新增页面

| 页面 | 设计来源 | 说明 |
|------|----------|------|
| 分析页面 (`/analysis`) | sw-anna Figma | 时序数据可视化主页面 |
| 团队列表 (`/teams`) | sw-anna Figma | 团队管理入口 |
| 团队详情 (`/teams/{id}`) | sw-anna Figma | 团队设置和成员管理 |

### 5.2 全局组件变更

| 组件 | 变更 |
|------|------|
| AppBar | 新增团队选择器 Dropdown |
| 工作台创建对话框 | 新增 `个人/团队` 归属选择 |
| 侧边导航 | 新增 `分析` 入口 |

### 5.3 设计约束

- 所有新增页面遵循 Release 1 的 Material Design 3 设计规范
- 颜色系统使用现有 `color_schemes.dart`
- 图表深色/浅色主题自动适配
- 响应式布局：>= 1280px 桌面布局，>= 768px 平板布局

---

## 6. 数据架构

### 6.1 数据库变更

**新增表**：
```sql
-- teams 表
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 团队名称唯一性：用户范围内唯一（基于 TeamMember 中 Owner 的用户 ID）
-- 实际约束通过应用层实现（创建时检查该用户是否已有同名团队）

-- team_members 表
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('Owner', 'Admin', 'Member')),
    invited_by UUID REFERENCES users(id),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- team_invitations 表
CREATE TABLE team_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Member',
    code TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**修改表**：
```sql
-- workbenches / methods / data_files 表已具备 owner_type + owner_id 字段（Release 1）
-- 仅需为 experiments 表补充 owner_type + owner_id，与现有表模式对齐
ALTER TABLE experiments ADD COLUMN owner_type TEXT NOT NULL DEFAULT 'user' 
    CHECK (owner_type IN ('user', 'team'));
ALTER TABLE experiments ADD COLUMN owner_id UUID NOT NULL DEFAULT user_id;
-- 注：existing data 的 owner_id 默认填充为 user_id，确保向后兼容
```

### 6.2 HDF5 数据读取

- 使用 `hdf5-rs` crate 读取试验数据文件
- 支持按时间范围切片读取
- 降采样算法：LTTB（Largest Triangle Three Buckets）
- 文件路径：`data/experiments/{experiment_id}.h5`

---

## 7. 部署与运维

### 7.1 启动脚本

每个 Sprint 完结时提供启动脚本：
- `scripts/start-r2s1.sh` — Sprint 1：启动后端 + 前端，检查依赖，打印访问地址
- `scripts/start-r2s2.sh` — Sprint 2：同上，额外检查 Python 环境
- `scripts/stop-r2s1.sh` / `scripts/stop-r2s2.sh` — 优雅停止

### 7.2 编译验证

每个 Sprint 完结时必须通过：
- `cargo clippy --all-targets --all-features -- -D warnings` — 零错误零警告
- `flutter build web --release` — 成功，无错误
- `flutter analyze --fatal-infos` — 无问题
- `pytest` (Python SDK) — 全部通过（Sprint 2）

---

## 8. 验收标准

### 8.1 功能验收

| 验收项 | 标准 | 验证方式 |
|--------|------|----------|
| 时序数据查询 API | POST /data/query 支持按设备/测点/时间范围查询 | 单元测试 + API 测试 |
| 时序图表显示 | 单/多曲线正确渲染 | 前端 Widget 测试 + 手动验证 |
| 图表交互 | 缩放/平移/光标/图例正常 | 手动验证 |
| 团队创建 | 用户可创建团队并自动成为 Owner | 端到端测试 |
| 成员邀请 | 可生成邀请码，被邀请者可加入 | 端到端测试 |
| 团队切换 | AppBar 团队选择器切换后资源过滤正确 | 手动验证 |
| 资源共享 | 团队工作台对成员可见 | 端到端测试 |
| Python SDK 认证 | 可登录、Token 自动刷新 | pytest |
| Python SDK 数据下载 | 可下载 HDF5 并转为 DataFrame | pytest |

### 8.2 质量验收

| 验收项 | 标准 |
|--------|------|
| 后端编译 | `cargo clippy -D warnings` 通过 |
| 后端测试 | `cargo test` 全部通过，覆盖率 > 80% |
| 前端编译 | `flutter build web` 无错误 |
| 前端分析 | `flutter analyze` 无问题 |
| Python SDK 测试 | `pytest` 全部通过，覆盖率 > 80% |
| 启动脚本 | 可一键启动和停止 |

---

## 9. 风险与假设

### 9.1 风险

| 风险ID | 描述 | 缓解策略 |
|--------|------|----------|
| R2-RISK-01 | fl_chart Web 性能不佳 | 准备降级方案：使用自定义 CustomPainter |
| R2-RISK-02 | HDF5 并发读写冲突 | 试验结束后标记 HDF5 为"可安全读取"；读取时使用只读打开。若需读取进行中的试验，使用文件快照副本 |
| R2-RISK-03 | Python SDK h5py 安装困难 | 提供 conda 环境文件和 pip 安装说明 |
| R2-RISK-04 | 团队管理数据迁移问题 | Migration 保留现有数据，新增字段默认填充 |

### 9.2 假设

- Release 1 所有功能在 main 分支上稳定可用
- `fl_chart` 库在 Flutter Web 上性能满足需求
- 用户 Python 环境为 3.9+
- HDF5 文件格式与 Release 1 兼容

---

**文档结束**

*本 PRD 基于 `log/release_2/feasibility_assessment.md` 的范围建议编制。任何范围变更需同步更新可行性评估报告。*
