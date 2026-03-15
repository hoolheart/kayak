# Kayak 科研项目 - 技术可行性评估报告

**版本**: 1.0  
**日期**: 2024-03-15  
**评估人员**: AI技术顾问  
**项目状态**: 可行性评估阶段

---

## 1. 执行摘要

### 1.1 评估结论

**总体可行性：✅ 可行**

"Kayak"科研项目采用Flutter（前端）+ Rust（后端）的技术栈在技术层面完全可行。该组合能够支持所有指定的功能需求和部署方式，且具备良好的性能、安全性和跨平台能力。

### 1.2 关键发现

| 评估维度 | 结论 | 风险等级 |
|----------|------|----------|
| 技术栈可行性 | 完全可行 | 低 |
| 架构复杂度 | 中等偏高 | 中 |
| 开发周期 | 约24-30个sprints（48-60周） | 中 |
| 技术挑战 | 可管理 | 中 |

### 1.3 建议策略

- **分多Release交付**：建议分3个主要Release逐步交付功能
- **优先桌面端**：初期聚焦桌面完整部署，Web版延后
- **尽早原型验证**：建议先构建仪器控制的原型验证

---

## 2. 技术可行性详细分析

### 2.1 前端技术栈（Flutter）

#### 2.1.1 可行性评估：✅ 高度可行

**支持论证：**

| 需求 | Flutter支持情况 | 状态 |
|------|----------------|------|
| 桌面端（Windows/macOS/Linux） | Flutter 3.x桌面支持已稳定，多个商业应用验证 | ✅ 成熟 |
| Material Design 3 | 原生支持，内置浅色/深色主题 | ✅ 完善 |
| 多语言支持 | flutter_localizations + intl包，支持i18n | ✅ 完善 |
| 数据可视化 | fl_chart、graphic、syncfusion_flutter_charts | ✅ 丰富 |
| 复杂表单编辑 | 原生Widget + reactive_forms/flutter_form_builder | ✅ 成熟 |
| 文件操作 | file_selector、path_provider支持跨平台 | ✅ 完善 |
| Web编译 | Flutter Web支持，但有性能限制 | ⚠️ 可用 |

**推荐依赖库：**

```yaml
dependencies:
  # UI框架
  flutter:
    sdk: flutter
  
  # Material Design 3
  material_design_icons_flutter: ^7.0.0
  
  # 状态管理
  flutter_bloc: ^8.1.0
  
  # 路由
  go_router: ^10.0.0
  
  # HTTP/WebSocket通信
  dio: ^5.3.0
  web_socket_channel: ^2.4.0
  
  # 数据可视化
  fl_chart: ^0.64.0
  graphic: ^2.2.0
  
  # 国际化
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.0
  
  # 文件操作
  file_selector: ^1.0.0
  path_provider: ^2.1.0
  
  # HDF5文件浏览（需调研）
  # hdf5_viewer: ^x.x.x
  
  # 代码编辑器（脚本编辑）
  flutter_code_editor: ^0.3.0
  
  # 权限管理
  flutter_secure_storage: ^9.0.0
```

#### 2.1.2 技术挑战

1. **Flutter Web性能限制**：图表渲染和数据密集型操作可能较慢
2. **HDF5文件浏览**：Flutter端需要专门实现或嵌入原生组件
3. **桌面原生功能**：部分系统级操作可能需要平台通道

#### 2.1.3 缓解方案

- Web版聚焦数据展示，复杂计算移至后端
- 使用table_view或自定义组件实现HDF5浏览器
- 封装rustdesk或tauri辅助原生功能

---

### 2.2 后端技术栈（Rust）

#### 2.2.1 可行性评估：✅ 高度可行

**支持论证：**

| 需求 | Rust生态支持 | 推荐库 | 状态 |
|------|-------------|--------|------|
| Web服务 | HTTP服务器 | Axum / Actix-web | ✅ 成熟 |
| 异步处理 | 异步运行时 | Tokio | ✅ 行业标杆 |
| HDF5读写 | 科学数据 | hdf5-rust / hdf5-metno | ✅ 可用 |
| SQLite | 关系型数据库 | sqlx / rusqlite | ✅ 成熟 |
| Modbus通信 | 工业协议 | tokio-modbus | ✅ 可用 |
| CAN通信 | 车辆/工业 | socketcan | ✅ 可用 |
| VISA通信 | 测试仪器 | 需FFI绑定（visa-rs） | ⚠️ 需开发 |
| WebSocket | 实时通信 | tokio-tungstenite | ✅ 成熟 |
| 认证授权 | JWT/Session | jsonwebtoken / tower-sessions | ✅ 成熟 |
| 序列化 | 数据传输 | serde | ✅ 行业标杆 |

**推荐依赖配置（Cargo.toml）：**

```toml
[dependencies]
# 异步运行时
tokio = { version = "1.32", features = ["full"] }
tokio-util = { version = "0.7", features = ["codec"] }

# Web框架
axum = { version = "0.7", features = ["ws"] }
tower = { version = "0.4", features = ["full"] }
tower-http = { version = "0.5", features = ["cors", "trace", "fs"] }

# 序列化
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# 数据库
sqlx = { version = "0.7", features = ["runtime-tokio", "sqlite", "migrate"] }

# HDF5
hdf5 = { version = "0.8", optional = true }
# 备选：hdf5-metno = "0.9"

# 认证
jsonwebtoken = "9.0"
argon2 = "0.5"

# 仪器协议
tokio-modbus = { version = "0.9", optional = true }
socketcan = { version = "3.0", optional = true }

# VISA（NI-VISA FFI绑定 - 需自行实现）
# visa-rs = { path = "../visa-rs", optional = true }

# 工具
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1.4", features = ["v4", "serde"] }
thiserror = "1.0"
anyhow = "1.0"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

# 配置
dotenvy = "0.15"
config = "0.14"

[features]
default = ["modbus", "can"]
modbus = ["tokio-modbus"]
can = ["socketcan"]
visa = []  # 需要NI-VISA驱动
```

#### 2.2.2 仪器协议支持详细分析

**Modbus支持：**
- 库：tokio-modbus（支持RTU/TCP）
- 状态：维护良好，功能完整
- 风险：低

**CAN总线支持：**
- 库：socketcan（Linux原生）
- Windows支持：需canal或模拟层
- 状态：Linux成熟，Windows需适配
- 风险：中

**VISA支持：**
- 现状：没有成熟的纯Rust VISA库
- 方案：
  1. 使用NI-VISA C库，通过Rust FFI绑定
  2. 使用pyvisa通过Python客户端库桥接
  3. 为常见仪器（Keysight、Tektronix）实现原生驱动
- 推荐：方案1（性能最优）+ 方案3（常用仪器优先）
- 风险：中高（需要额外开发工作）

#### 2.2.3 架构模式建议

```
┌─────────────────────────────────────────────────────────────┐
│                        Rust Backend                         │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   API Layer  │  │   Business   │  │  Instrument      │  │
│  │  (Axum)      │  │    Logic     │  │   Plugins        │  │
│  │              │  │              │  │                  │  │
│  │ - REST API   │  │ - Experiment │  │ - Modbus Driver  │  │
│  │ - WebSocket  │  │   Control    │  │ - CAN Driver     │  │
│  │ - Auth       │  │ - Data Flow  │  │ - VISA Driver    │  │
│  └──────────────┘  └──────────────┘  │ - Custom Drivers │  │
│          │                 │         └──────────────────┘  │
│          └─────────────────┘                   │             │
│                     │                          │             │
│  ┌──────────────────┴──────────┐  ┌────────────┴──────────┐  │
│  │       Data Layer            │  │   Hardware Abstraction │  │
│  │  ┌─────────┐  ┌─────────┐  │  │   Layer               │  │
│  │  │ SQLite  │  │  HDF5   │  │  │  ┌─────────────────┐  │  │
│  │  │ (Meta)  │  │ (Data)  │  │  │  │ Hardware Bridge │  │  │
│  │  └─────────┘  └─────────┘  │  │  │ - Serial Port   │  │  │
│  └─────────────────────────────┘  │  │ - TCP/UDP       │  │  │
│                                    │  │ - USB/GPIB      │  │  │
│                                    │  └─────────────────┘  │  │
│                                    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

### 2.3 数据库架构评估

#### 2.3.1 推荐方案：✅ HDF5 + SQLite混合存储

**架构设计：**

```
┌─────────────────────────────────────────────────────────────┐
│                     数据管理架构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐    ┌─────────────────────┐        │
│  │   SQLite (元数据)    │    │    HDF5 (科学数据)   │        │
│  │                     │    │                     │        │
│  │ - 用户/团队信息     │    │ - 实验时序数据      │        │
│  │ - 仪器配置         │    │ - 波形数据          │        │
│  │ - 实验定义/脚本    │◄───►│ - 大体积测量数据    │        │
│  │ - 数据文件索引     │    │ - 多维数组数据      │        │
│  │ - 权限配置         │    │ - 压缩存储          │        │
│  │ - 运行日志         │    │ - 分块存储          │        │
│  └─────────────────────┘    └─────────────────────┘        │
│           │                           │                     │
│           │    ┌────────────────┐    │                     │
│           └───►│ 关联：文件路径  │◄───┘                     │
│                │ + 元数据引用   │                          │
│                └────────────────┘                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**方案优势：**

| 维度 | SQLite优势 | HDF5优势 |
|------|-----------|----------|
| **数据结构** | 关系型，适合配置数据 | 分层结构，适合科学数据 |
| **查询能力** | SQL查询，灵活强大 | 基于路径访问，高效读取 |
| **事务支持** | ACID完整支持 | 有限支持 |
| **压缩** | 无原生支持 | 多种压缩算法 |
| **大数据** | 不推荐大对象 | 专为TB级数据设计 |
| **版本兼容** | 稳定 | 需考虑版本兼容性 |

**数据流设计：**

```
实验运行
    │
    ▼
┌─────────────────┐
│  Experiment     │
│  Controller     │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐  ┌─────────────┐
│SQLite │  │   HDF5      │
│(写入: │  │  (写入:     │
│ 状态  │  │  测点数据)  │
│ 元数据│  │             │
│ 索引) │  │             │
└───────┘  └─────────────┘
         │
         ▼
┌─────────────────┐
│  Data Service   │
│  (查询/分析)    │
└─────────────────┘
```

#### 2.3.2 数据库Schema概览

**SQLite 核心表：**

```sql
-- 团队/用户管理
CREATE TABLE teams (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id TEXT PRIMARY KEY,
    team_id TEXT REFERENCES teams(id),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT CHECK(role IN ('admin', 'user', 'viewer')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 仪器管理（工作台-设备-测点）
CREATE TABLE workspaces (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    team_id TEXT REFERENCES teams(id),
    config JSON
);

CREATE TABLE devices (
    id TEXT PRIMARY KEY,
    workspace_id TEXT REFERENCES workspaces(id),
    parent_device_id TEXT REFERENCES devices(id), -- 支持嵌套
    name TEXT NOT NULL,
    device_type TEXT, -- 'modbus', 'can', 'visa', 'virtual'
    protocol_config JSON,
    connection_string TEXT,
    is_active BOOLEAN DEFAULT false
);

CREATE TABLE measurement_points (
    id TEXT PRIMARY KEY,
    device_id TEXT REFERENCES devices(id),
    name TEXT NOT NULL,
    unit TEXT,
    data_type TEXT, -- 'float', 'int', 'bool', 'string'
    sampling_rate REAL,
    config JSON
);

-- 实验定义
CREATE TABLE experiments (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    workspace_id TEXT REFERENCES workspaces(id),
    script_content TEXT, -- 试验方法脚本
    parameters JSON, -- 参数定义
    created_by TEXT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 实验运行实例
CREATE TABLE experiment_runs (
    id TEXT PRIMARY KEY,
    experiment_id TEXT REFERENCES experiments(id),
    status TEXT CHECK(status IN ('pending', 'running', 'paused', 'completed', 'failed')),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    hdf5_file_path TEXT, -- 关联HDF5文件
    metadata JSON
);

-- 数据文件索引（关联HDF5）
CREATE TABLE data_files (
    id TEXT PRIMARY KEY,
    run_id TEXT REFERENCES experiment_runs(id),
    file_path TEXT NOT NULL,
    file_size_bytes INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**HDF5 文件结构：**

```
experiment_run_001.h5
├── /metadata
│   ├── experiment_id
│   ├── start_time
│   ├── parameters (JSON)
│   └── device_configurations
│
├── /devices
│   ├── /device_001
│   │   ├── /measurement_point_001
│   │   │   ├── data (Dataset: [时间戳, 值])
│   │   │   └── attributes (单位, 类型等)
│   │   └── /measurement_point_002
│   │       └── ...
│   └── /device_002
│       └── ...
│
└── /events
    └── event_log (Dataset: [时间戳, 事件类型, 描述])
```

---

### 2.4 部署方案评估

#### 2.4.1 四种部署方式可行性分析

| 部署方式 | 复杂度 | 风险 | 适用场景 | 优先级 |
|----------|--------|------|----------|--------|
| **桌面完整部署** | 中 | 低 | 实验室本地使用 | P0 |
| **单容器Web部署** | 中 | 低 | 小型团队、快速演示 | P1 |
| **前后端分离双容器** | 中高 | 中 | 生产环境、团队协作 | P1 |
| **混合部署** | 高 | 中高 | 特殊网络环境 | P2 |

#### 2.4.2 部署架构详图

**方案A：桌面完整部署**

```
┌─────────────────────────────────────────────┐
│           桌面应用 (Windows/macOS/Linux)    │
│  ┌─────────────────────────────────────┐   │
│  │        Flutter Desktop App          │   │
│  │   (UI + 本地状态管理)               │   │
│  └───────────────┬─────────────────────┘   │
│                  │ HTTP/WebSocket          │
│  ┌───────────────▼─────────────────────┐   │
│  │      Rust Embedded Server           │   │
│  │  (内置Axum服务，本地监听)           │   │
│  └───────────────┬─────────────────────┘   │
│                  │                         │
│      ┌───────────┼───────────┐             │
│      ▼           ▼           ▼             │
│  ┌────────┐  ┌────────┐  ┌─────────────┐  │
│  │SQLite  │  │HDF5    │  │Instrument   │  │
│  │(本地)  │  │(本地)  │  │Drivers      │  │
│  └────────┘  └────────┘  └─────────────┘  │
└─────────────────────────────────────────────┘
```

**方案B：单容器Web部署**

```
┌─────────────────────────────────────────────┐
│              Docker Container               │
│  ┌─────────────────────────────────────┐   │
│  │      Flutter Web (Compiled)         │   │
│  │   (静态文件 + Nginx)                │   │
│  └───────────────┬─────────────────────┘   │
│                  │ (内部HTTP)              │
│  ┌───────────────▼─────────────────────┐   │
│  │         Rust Backend                │   │
│  └───────────────┬─────────────────────┘   │
│                  │                         │
│      ┌───────────┼───────────┐             │
│      ▼           ▼           ▼             │
│  ┌────────┐  ┌────────┐  ┌─────────────┐  │
│  │SQLite  │  │HDF5    │  │Instrument   │  │
│  │(容器内)│  │(容器卷)│  │(USB/Network)│  │
│  └────────┘  └────────┘  └─────────────┘  │
└─────────────────────────────────────────────┘
```

**方案C：前后端分离双容器**

```
┌─────────────────┐      ┌───────────────────────────────────┐
│   Nginx容器     │      │         Rust Backend容器          │
│ ┌─────────────┐ │      │  ┌─────────────────────────────┐  │
│ │Flutter Web  │◄├──────┼──┤  Axum Server               │  │
│ │静态文件     │ │HTTP  │  └──────────────┬──────────────┘  │
│ └─────────────┘ │      │                 │                 │
└─────────────────┘      │    ┌────────────┼────────────┐    │
                         │    ▼            ▼            ▼    │
                         │ ┌────────┐  ┌────────┐  ┌────────┐│
                         │ │SQLite  │  │HDF5    │  │Hardware││
                         │ │(容器内)│  │(容器卷)│  │Bridge  ││
                         │ └────────┘  └────────┘  └────────┘│
                         └───────────────────────────────────┘
                                        │
                                   (物理主机)
                                        │
                                    USB/Network
                                        │
                                 ┌──────┴──────┐
                                 │  仪器设备   │
                                 └─────────────┘
```

**方案D：混合部署**

```
┌─────────────────┐      ┌───────────────────────────────────┐
│ Flutter Desktop │      │      Rust Backend容器             │
│   (本地运行)    │◄─────┼────► (远程/本地Docker)            │
└─────────────────┘      └───────────────────────────────────┘
   (WebSocket/HTTP)              │
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
               ┌────────┐   ┌────────┐   ┌────────────┐
               │SQLite  │   │HDF5    │   │Instrument  │
               │(容器内)│   │(网络卷)│   │Connection  │
               └────────┘   └────────┘   └────────────┘
```

#### 2.4.3 容器化配置建议

**Dockerfile - 后端：**

```dockerfile
# 多阶段构建
FROM rust:1.75-slim as builder

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release

# 运行镜像
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    libhdf5-103 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/release/kayak-backend /app/

VOLUME ["/app/data", "/app/hdf5"]
EXPOSE 3000

CMD ["./kayak-backend"]
```

**docker-compose.yml - 双容器部署：**

```yaml
version: '3.8'

services:
  backend:
    build: ./kayak-backend
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
      - ./hdf5:/app/hdf5
      - /dev:/dev  # 仪器设备访问
    environment:
      - DATABASE_URL=sqlite:///app/data/kayak.db
      - HDF5_PATH=/app/hdf5
      - RUST_LOG=info
    privileged: true  # 串口/USB访问需要
    restart: unless-stopped

  frontend:
    build: ./kayak-frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    environment:
      - API_URL=http://backend:3000
    restart: unless-stopped
```

---

## 3. 架构复杂度评估

### 3.1 复杂度矩阵

| 模块 | 业务复杂度 | 技术复杂度 | 集成复杂度 | 综合评级 |
|------|-----------|-----------|-----------|----------|
| 用户权限管理 | 中 | 低 | 低 | ⭐⭐ |
| 仪器管理 | 高 | 高 | 高 | ⭐⭐⭐⭐⭐ |
| 试验方法编辑 | 中高 | 中高 | 中 | ⭐⭐⭐⭐ |
| 试验过程控制 | 高 | 高 | 高 | ⭐⭐⭐⭐⭐ |
| 数据存储（HDF5+SQLite） | 中 | 中 | 中 | ⭐⭐⭐ |
| 数据可视化 | 中 | 中 | 低 | ⭐⭐⭐ |
| LaTeX图表导出 | 低 | 中 | 中 | ⭐⭐⭐ |
| 多语言支持 | 低 | 低 | 低 | ⭐⭐ |
| Material Design主题 | 低 | 低 | 低 | ⭐ |
| 多部署方式支持 | 中 | 高 | 高 | ⭐⭐⭐⭐ |

**复杂度等级说明：**
- ⭐：简单（<1 sprint）
- ⭐⭐：较简单（1-2 sprints）
- ⭐⭐⭐：中等（2-3 sprints）
- ⭐⭐⭐⭐：较复杂（3-5 sprints）
- ⭐⭐⭐⭐⭐：复杂（5+ sprints）

### 3.2 关键架构决策点

**决策1：仪器驱动架构模式**
- 推荐：插件化架构 + 驱动注册表
- 理由：支持第三方扩展，便于测试
- 复杂度影响：高

**决策2：实验控制状态机**
- 推荐：基于状态模式的状态机（tokio::sync::mpsc）
- 状态：Pending → Running → Paused/Running → Completed/Failed
- 复杂度影响：高

**决策3：前后端通信协议**
- 推荐：REST API + WebSocket（实时数据推送）
- 理由：WebSocket适合实时仪器数据流
- 复杂度影响：中

**决策4：HDF5并发访问**
- 推荐：单写多读模式，后台批处理队列
- 理由：HDF5不支持并发写入
- 复杂度影响：中

---

## 4. 开发任务拆解与周期估算

### 4.1 任务分解结构（WBS）

```
Kayak项目
├── 1. 基础设施 (4 sprints)
│   ├── 1.1 项目脚手架搭建
│   ├── 1.2 开发环境配置
│   ├── 1.3 CI/CD流水线
│   └── 1.4 代码规范与文档模板
│
├── 2. 数据库与存储 (4 sprints)
│   ├── 2.1 SQLite Schema设计与迁移
│   ├── 2.2 HDF5文件操作封装
│   ├── 2.3 数据访问层（Repository模式）
│   └── 2.4 数据备份与恢复机制
│
├── 3. 后端核心 (10 sprints)
│   ├── 3.1 Web服务框架搭建
│   ├── 3.2 认证授权模块
│   ├── 3.3 用户/团队管理API
│   ├── 3.4 仪器管理API
│   ├── 3.5 Modbus驱动实现
│   ├── 3.6 CAN驱动实现
│   ├── 3.7 VISA驱动框架
│   ├── 3.8 试验方法引擎
│   ├── 3.9 试验控制服务
│   └── 3.10 数据分析服务
│
├── 4. 前端核心 (10 sprints)
│   ├── 4.1 Flutter项目结构
│   ├── 4.2 主题与国际化
│   ├── 4.3 状态管理架构
│   ├── 4.4 登录与用户界面
│   ├── 4.5 仪器管理界面
│   ├── 4.6 试验方法编辑器
│   ├── 4.7 试验控制台
│   ├── 4.8 数据浏览器（HDF5）
│   ├── 4.9 数据可视化图表
│   └── 4.10 报表与导出界面
│
├── 5. 部署与运维 (4 sprints)
│   ├── 5.1 桌面打包（Windows/macOS/Linux）
│   ├── 5.2 容器化（Docker）
│   ├── 5.3 部署脚本与配置
│   └── 5.4 监控与日志
│
├── 6. Python客户端库 (3 sprints)
│   ├── 6.1 Python包结构
│   ├── 6.2 API绑定
│   ├── 6.3 数据分析工具封装
│   └── 6.4 LaTeX图表生成
│
└── 7. 测试与优化 (3 sprints)
    ├── 7.1 单元测试覆盖
    ├── 7.2 集成测试
    ├── 7.3 性能优化
    └── 7.4 文档完善
```

### 4.2 Sprint计划

**假设条件：**
- 团队规模：4-6人（2后端 + 2前端 + 1全栈 + 1测试/运维）
- Sprint周期：2周
- 每个Sprint最多20个任务
- 包含buffer（15%风险储备）

#### Release 1：核心基础设施 + 基础仪器管理 (Sprint 1-8, 16周)

| Sprint | 主题 | 主要任务 | 产出 |
|--------|------|----------|------|
| 1 | 项目启动 | 脚手架搭建、代码规范、Git工作流 | 可编译的空项目 |
| 2 | 数据层基础 | SQLite Schema、迁移工具、基础Repository | 数据层可用 |
| 3 | 后端框架 | Axum服务、中间件、错误处理 | 基础API服务 |
| 4 | 认证授权 | JWT认证、用户/团队API、权限基础 | 登录系统可用 |
| 5 | 前端基础 | Flutter结构、主题、国际化框架 | 前端框架可用 |
| 6 | 仪器管理（上） | 设备模型API、Modbus驱动原型 | 可配置虚拟设备 |
| 7 | 仪器管理（下） | 前端仪器界面、设备树展示 | 完整仪器管理 |
| 8 | 桌面部署 | 桌面打包、嵌入式后端 | Release 1交付 |

**Release 1 验收标准：**
- [ ] 完整的用户/团队管理
- [ ] 仪器三层结构管理（工作台-设备-测点）
- [ ] Modbus协议支持（基础读写）
- [ ] 桌面应用可运行（Windows/macOS/Linux）
- [ ] 浅色/深色主题切换
- [ ] 中英文双语支持

#### Release 2：试验控制 + 数据管理 (Sprint 9-18, 20周)

| Sprint | 主题 | 主要任务 | 产出 |
|--------|------|----------|------|
| 9 | 试验方法引擎 | 脚本解析器、参数系统 | 基础脚本执行 |
| 10 | 试验控制台 | 状态机、启动/暂停/停止 | 可控试验流程 |
| 11 | HDF5集成 | HDF5写入、文件结构、元数据关联 | 数据存储可用 |
| 12 | 实时数据流 | WebSocket推送、前端实时图表 | 实时数据显示 |
| 13 | 试验方法编辑器 | 可视化编辑、脚本编辑、参数配置 | 完整编辑功能 |
| 14 | CAN驱动 | CAN协议实现、测试 | CAN设备支持 |
| 15 | 数据浏览器 | HDF5文件浏览、数据查询 | 可查看历史数据 |
| 16 | 数据分析基础 | 数据导出、基础统计 | 基础分析功能 |
| 17 | 容器化部署 | Docker配置、Web版编译 | 容器部署可用 |
| 18 | Release 2集成 | 集成测试、Bug修复、文档 | Release 2交付 |

**Release 2 验收标准：**
- [ ] 完整的试验方法定义与编辑
- [ ] 试验过程控制（启动/暂停/停止）
- [ ] HDF5数据存储与元数据管理
- [ ] 实时数据可视化
- [ ] Modbus + CAN双协议支持
- [ ] 容器化部署（单容器/双容器）

#### Release 3：高级功能 + 生态集成 (Sprint 19-26, 16周)

| Sprint | 主题 | 主要任务 | 产出 |
|--------|------|----------|------|
| 19 | VISA驱动 | VISA FFI绑定、常用仪器支持 | VISA设备可用 |
| 20 | Python客户端 | Python SDK、API封装 | Python库可用 |
| 21 | LaTeX导出 | 图表生成、模板系统 | LaTeX导出功能 |
| 22 | 高级分析 | 多维度分析、对比分析 | 高级分析功能 |
| 23 | 混合部署 | 混合部署配置、网络适配 | 混合部署可用 |
| 24 | 性能优化 | 大数据优化、内存优化 | 性能达标 |
| 25 | 法文支持 | 法文翻译、本地化测试 | 三语完整支持 |
| 26 | 最终集成 | 系统测试、性能测试、文档完善 | Release 3交付 |

**Release 3 验收标准：**
- [ ] VISA协议支持（GPIB/USB/以太网）
- [ ] Python客户端库完整功能
- [ ] LaTeX图表导出
- [ ] 混合部署方案
- [ ] 性能优化达标（支持1k+测点）
- [ ] 完整的英/中/法三语支持

### 4.3 总体开发周期估算

```
总Sprints：26个（52周）
总任务数：约180-200个任务
团队规模：4-6人

时间线：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Month:  1   2   3   4   5   6   7   8   9   10  11  12  13
        ├──────R1──────┤
                        ├──────────R2──────────┤
                                                ├──────R3──────┤
Sprints: 1-2 3-4 5-6 7-8 9-10 11-12 13-14 15-16 17-18 19-20 21-22 23-24 25-26
```

**关键里程碑：**

| 里程碑 | 日期 | 说明 |
|--------|------|------|
| M1：技术验证 | Sprint 4末 | 技术架构验证完成，核心流程跑通 |
| M2：Alpha版本 | Sprint 8末 | Release 1完成，核心功能可用 |
| M3：Beta版本 | Sprint 14末 | Release 2完成，功能基本完整 |
| M4：RC版本 | Sprint 18末 | Release 2稳定，进入Release 3 |
| M5：正式发布 | Sprint 26末 | Release 3完成，正式交付 |

---

## 5. 技术风险识别与缓解

### 5.1 风险矩阵

| 风险ID | 风险描述 | 可能性 | 影响度 | 风险等级 | 缓解措施 |
|--------|----------|--------|--------|----------|----------|
| R1 | VISA驱动开发复杂度高 | 高 | 高 | 🔴 高 | 优先调研；准备备选方案（Python桥接） |
| R2 | Flutter Web性能不足 | 中 | 中 | 🟡 中 | 限制Web版功能；聚焦桌面端 |
| R3 | HDF5并发写入问题 | 中 | 高 | 🟡 中 | 设计单写多读架构；批处理队列 |
| R4 | 仪器协议兼容性 | 高 | 中 | 🟡 中 | 插件化架构；优先级排序 |
| R5 | CAN总线Windows支持 | 中 | 中 | 🟡 中 | 调研Windows CAN方案；可能仅限Linux |
| R6 | 团队Rust经验不足 | 中 | 高 | 🟡 中 | 提前培训；代码审查；Rust专家咨询 |
| R7 | 开发周期超出预期 | 中 | 高 | 🟡 中 | 分Release交付；功能优先级排序 |
| R8 | 数据完整性/安全性 | 低 | 高 | 🟢 低 | 完善的测试；事务机制；备份策略 |

### 5.2 主要技术挑战详解

#### 挑战1：VISA仪器通信（高风险）

**问题描述：**
- 测试仪器领域大量使用VISA（Virtual Instrument Software Architecture）
- 没有成熟的纯Rust VISA库
- NI-VISA是闭源商业软件，绑定复杂

**缓解方案：**

1. **分阶段实现：**
   - Sprint 1-8：使用虚拟设备完成核心功能
   - Sprint 9-16：实现Modbus + CAN（更成熟）
   - Sprint 17-20：调研VISA实现
   - Sprint 21-26：VISA驱动开发

2. **技术选型：**
   ```
   方案A：Rust FFI绑定NI-VISA（推荐）
   - 性能最佳
   - 功能完整
   - 工作量：2-3 sprints
   
   方案B：通过Python客户端库使用PyVISA
   - 实现最快
   - 依赖Python环境
   - 工作量：1 sprint
   
   方案C：实现常用仪器原生驱动
   - Keysight、Tektronix等
   - 不依赖VISA
   - 工作量：按仪器数量递增
   ```

3. **建议：** 优先方案A，准备方案B作为备选

#### 挑战2：实时数据流处理

**问题描述：**
- 科研仪器数据采样率可能很高（kHz级）
- 需要实时推送到前端展示
- HDF5写入可能阻塞数据流

**缓解方案：**

```rust
// 推荐架构：多生产者单消费者（MPSC）

// 数据流架构
Instrument Driver ──► Data Acquisition ──► Ring Buffer ──► HDF5 Writer
                              │                           │
                              ▼                           ▼
                         WebSocket Push             Async Batch Write
                              │
                              ▼
                       Flutter Frontend

// 关键技术点
1. 使用tokio::sync::mpsc进行无锁队列
2. Ring Buffer防止内存无限增长
3. 独立线程/任务处理HDF5写入
4. WebSocket二进制消息减少序列化开销
```

#### 挑战3：HDF5并发访问

**问题描述：**
- HDF5库不支持多进程并发写入同一文件
- 实验数据可能需要实时写入 + 后台分析读取

**缓解方案：**

```
方案：分离写入和读取流程

写入流程（单线程）：
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Instrument  │───►│ Data Queue  │───►│ HDF5 Writer │
│ Data Stream │    │ (MPSC)      │    │ (单写线程)   │
└─────────────┘    └─────────────┘    └─────────────┘

读取流程：
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ User Query  │───►│ File Copy   │───►│ Read Copy   │
│             │    │ (Snapshot)  │    │ (只读)      │
└─────────────┘    └─────────────┘    └─────────────┘
```

### 5.3 技术债务管理

| 债务项 | Sprint | 说明 |
|--------|--------|------|
| 虚拟仪器实现 | 1-4 | 用于早期开发，后期需替换为真实驱动 |
| Web版功能限制 | 5-8 | Web版暂不支持文件操作，后续优化 |
| 硬编码配置 | 9-12 | 部分配置硬编码，后续移至配置文件 |
| 简化权限模型 | 13-16 | 初期仅支持角色权限，后续支持细粒度 |

---

## 6. 技术选型建议

### 6.1 核心技术栈

| 层级 | 技术选型 | 版本 | 选型理由 |
|------|----------|------|----------|
| **前端框架** | Flutter | 3.16+ | 跨平台桌面成熟，Material 3完整支持 |
| **前端状态** | flutter_bloc | 8.1+ | 成熟的状态管理，适合复杂应用 |
| **前端路由** | go_router | 12.0+ | Flutter团队维护，声明式路由 |
| **后端框架** | Axum | 0.7+ | 基于tokio，性能优异，生态活跃 |
| **异步运行时** | Tokio | 1.35+ | Rust异步标准，生态最完善 |
| **数据库** | SQLite | 3.40+ | 嵌入式，零配置，单文件 |
| **ORM/查询** | sqlx | 0.7+ | 编译时SQL检查，异步支持 |
| **HDF5** | hdf5-rust | 0.8+ | HDF5官方绑定，功能完整 |
| **认证** | jsonwebtoken | 9.0+ | JWT标准实现 |
| **密码** | argon2 | 0.5+ | 现代密码哈希算法 |
| **配置** | config + dotenvy | 0.14/0.15 | 分层配置管理 |
| **日志** | tracing | 0.1+ | 结构化日志，异步友好 |

### 6.2 仪器通信库

| 协议 | 库 | 状态 | 备注 |
|------|-----|------|------|
| Modbus RTU/TCP | tokio-modbus | ✅ 成熟 | 异步支持完善 |
| CAN (Linux) | socketcan | ✅ 成熟 | Linux原生支持 |
| CAN (Windows) | canal/socketcan-rs | ⚠️ 需验证 | Windows支持待验证 |
| VISA | visa-rs (自建) | ⚠️ 需开发 | FFI绑定NI-VISA |
| Serial | tokio-serial | ✅ 成熟 | 串口通信 |
| TCP/UDP | tokio::net | ✅ 成熟 | 标准库 |

### 6.3 Flutter依赖推荐

```yaml
# pubspec.yaml 核心依赖

dependencies:
  flutter:
    sdk: flutter
  
  # 基础
  cupertino_icons: ^1.0.6
  material_design_icons_flutter: ^7.0.0
  
  # 状态管理
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  equatable: ^2.0.5
  
  # 路由
  go_router: ^12.1.1
  
  # 网络
  dio: ^5.4.0
  retrofit: ^4.0.3
  web_socket_channel: ^2.4.0
  
  # 数据
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1
  
  # 本地存储
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  hive: ^2.2.3
  
  # 文件操作
  file_selector: ^1.0.3
  path_provider: ^2.1.1
  
  # 数据可视化
  fl_chart: ^0.66.0
  graphic: ^2.2.0
  syncfusion_flutter_charts: ^23.2.7
  
  # UI组件
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0
  data_table_2: ^2.5.9
  flutter_staggered_grid_view: ^0.7.0
  
  # 代码编辑
  flutter_code_editor: ^0.3.1
  highlight: ^0.7.0
  
  # 国际化
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.1
  intl_utils: ^2.8.7
  
  # 工具
  collection: ^1.18.0
  async: ^2.11.0
  rxdart: ^0.27.7
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  freezed: ^2.4.6
  retrofit_generator: ^8.0.6
  mockito: ^5.4.4
  bloc_test: ^9.1.5
```

### 6.4 Rust依赖推荐

```toml
# Cargo.toml 核心依赖

[dependencies]
# 异步
async-trait = "0.1"
futures = "0.3"
futures-util = "0.3"

# Tokio生态
tokio = { version = "1.35", features = ["full"] }
tokio-stream = "0.1"
tokio-util = { version = "0.7", features = ["codec", "time"] }

# Web框架
axum = { version = "0.7", features = ["ws", "multipart"] }
tower = { version = "0.4", features = ["full"] }
tower-http = { version = "0.5", features = ["cors", "trace", "fs", "timeout"] }
tower-sessions = "0.10"

# 序列化
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
serde_with = "3.4"

# 数据库
sqlx = { version = "0.7", features = ["runtime-tokio", "sqlite", "migrate", "chrono", "uuid"] }

# HDF5
hdf5 = "0.8"
hdf5-sys = "0.8"

# 认证
jsonwebtoken = "9.0"
argon2 = "0.5"

# 仪器通信
tokio-modbus = { version = "0.9", features = ["tcp", "rtu"], optional = true }
socketcan = { version = "3.0", optional = true }
tokio-serial = { version = "5.4", optional = true }

# WebSocket
tokio-tungstenite = "0.21"

# 配置
config = "0.14"
dotenvy = "0.15"

# 日志
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
tracing-appender = "0.2"

# 错误处理
thiserror = "1.0"
anyhow = "1.0"

# 工具
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1.6", features = ["v4", "v7", "serde"] }
ulid = { version = "1.1", features = ["serde"] }
once_cell = "1.19"
regex = "1.10"

# 测试
mockall = { version = "0.12", optional = true }

[dev-dependencies]
mockall = "0.12"
tokio-test = "0.4"
reqwest = { version = "0.11", features = ["json"] }

[features]
default = ["modbus"]
modbus = ["tokio-modbus"]
can = ["socketcan"]
serial = ["tokio-serial"]
```

---

## 7. Release策略建议

### 7.1 分Release策略：✅ 强烈建议

**理由：**
1. **功能复杂度高**：7大功能模块，180+任务
2. **技术风险分散**：仪器驱动等高风险功能延后
3. **用户反馈循环**：早期Release获取用户反馈
4. **团队学习曲线**：Rust/Flutter需要时间积累经验

### 7.2 Release详细规划

#### Release 1：核心基础设施（MVP）

**目标：** 可运行的基础版本，支持虚拟设备

**核心功能：**
- 用户/团队管理
- 工作台-设备-测点三层管理
- 虚拟设备支持（模拟数据）
- 基础试验流程（开始/停止）
- HDF5数据存储
- 桌面端部署

**不包含：**
- 真实仪器协议（仅虚拟设备）
- Web部署
- Python客户端
- LaTeX导出
- 法文支持

**验收标准：**
- 可创建用户、团队
- 可配置虚拟设备
- 可运行简单试验
- 数据可存储到HDF5
- 桌面应用可安装运行

#### Release 2：试验控制 + 数据管理

**目标：** 完整的试验控制能力和数据管理

**新增功能：**
- Modbus协议支持
- CAN协议支持
- 试验方法编辑器
- 实时数据可视化
- 数据浏览器
- 容器化部署

**不包含：**
- VISA协议
- Python客户端
- LaTeX导出
- 法文支持

**验收标准：**
- 支持Modbus设备连接
- 支持CAN设备连接
- 可编辑试验方法
- 可实时查看数据
- 可浏览历史数据
- 可通过Docker部署

#### Release 3：生态集成 + 高级功能

**目标：** 完整的科研工具链支持

**新增功能：**
- VISA协议支持
- Python客户端库
- LaTeX图表导出
- 混合部署
- 法文支持
- 性能优化

**验收标准：**
- 支持VISA仪器
- Python SDK可用
- 可导出LaTeX图表
- 支持混合部署
- 三语完整支持
- 性能达标（1k+测点）

### 7.3 Release时间线

```
2024                    2025                    2026
─────────────────────────────────────────────────────────►
Sprint: 1  4  8  12  16  20  24  26
        │  │  │   │   │   │   │   │
        ▼  ▼  ▼   ▼   ▼   ▼   ▼   ▼
       [===R1===]
                  [=====R2=====]
                                [===R3===]
                                
Milestone:
        M1 M2 M3  M4  M5
        
Time:   Apr    Aug    Dec    Apr
```

---

## 8. 总结与建议

### 8.1 可行性结论

| 维度 | 结论 | 说明 |
|------|------|------|
| **技术可行性** | ✅ 高度可行 | Flutter + Rust技术栈成熟，生态完善 |
| **架构可行性** | ✅ 可行 | 分层架构清晰，技术选型合理 |
| **部署可行性** | ✅ 可行 | 四种部署方式均可实现 |
| **时间可行性** | ⚠️ 需规划 | 26 sprints（52周）周期较长，需分Release |
| **团队可行性** | ⚠️ 需准备 | 需要Rust经验或学习期 |

### 8.2 关键成功因素

1. **团队能力建设**
   - 至少1名有Rust经验的开发者
   - Flutter开发者需熟悉桌面端开发
   - 建议Sprint 1-2进行技术培训和原型验证

2. **风险管理**
   - VISA驱动作为最高风险项，需提前调研
   - 准备技术备选方案（特别是仪器通信）
   - 建立技术债务追踪机制

3. **用户参与**
   - Release 1后开始用户测试
   - 建立反馈循环，及时调整优先级
   - 早期用户参与可减少后期返工

4. **质量保证**
   - 建立CI/CD流水线
   - 关键模块（数据存储、仪器控制）需高测试覆盖
   - 定期进行性能测试

### 8.3 下一步行动建议

**立即行动（Sprint 0，2周）：**

1. **技术验证**
   - 搭建最小可行原型
   - 验证Modbus通信
   - 验证HDF5读写
   - 验证Flutter桌面打包

2. **团队准备**
   - 确定团队成员
   - 制定Rust学习计划
   - 准备开发环境

3. **详细设计**
   - 完成数据库Schema设计
   - 完成API接口设计
   - 完成UI原型设计

**短期目标（Sprint 1-4）：**
- 完成项目脚手架
- 实现基础数据层
- 搭建前后端通信
- 完成用户认证

---

## 附录

### A. 技术选型对比

**前端框架对比：**

| 框架 | 优势 | 劣势 | 推荐度 |
|------|------|------|--------|
| Flutter | 跨平台成熟，单一代码库，Material 3 | Web性能限制，包体积大 | ⭐⭐⭐⭐⭐ |
| Tauri | 轻量，Web技术栈 | 复杂UI开发成本高 | ⭐⭐⭐ |
| Electron | 生态丰富 | 资源占用高，启动慢 | ⭐⭐ |
| Qt (Python) | 桌面端强大 | 许可限制，Python性能 | ⭐⭐⭐ |

**后端框架对比：**

| 框架 | 优势 | 劣势 | 推荐度 |
|------|------|------|--------|
| Axum | 基于tokio，性能优异，类型安全 | 相对年轻 | ⭐⭐⭐⭐⭐ |
| Actix-web | 成熟，功能丰富 | 部分unsafe代码 | ⭐⭐⭐⭐ |
| Rocket | 易用，类型安全 | 异步支持相对新 | ⭐⭐⭐ |
| Go/Gin | 简单，编译快 | 非Rust，内存安全弱 | ⭐⭐⭐ |

### B. 参考资源

**Flutter桌面开发：**
- [Flutter Desktop Documentation](https://docs.flutter.dev/desktop)
- [Flutter Gallery](https://gallery.flutter.dev/)

**Rust异步编程：**
- [Tokio Documentation](https://tokio.rs/)
- [Rust Async Book](https://rust-lang.github.io/async-book/)

**HDF5资源：**
- [hdf5-rust GitHub](https://github.com/aldanor/hdf5-rust)
- [HDF5官方文档](https://portal.hdfgroup.org/display/HDF5/HDF5)

**仪器通信：**
- [Modbus协议规范](https://modbus.org/)
- [NI-VISA文档](https://www.ni.com/en-us/support/documentation/supplemental/06/ni-visa-documentation.html)

---

**报告完成日期**: 2024-03-15  
**评估人员**: AI技术顾问  
**版本**: 1.0

---

*本报告基于当前技术栈（截至2024年3月）的公开信息进行评估，技术选型建议需结合实际团队经验和项目约束进行最终决策。*
