# Kayak - 科学研究支持软件

[![CI](https://github.com/hoolheart/kayak/actions/workflows/ci.yml/badge.svg)](https://github.com/hoolheart/kayak/actions/workflows/ci.yml)
[![Rust](https://img.shields.io/badge/Rust-1.75%2B-orange.svg)](https://rust-lang.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Kayak 是一款面向科学研究活动的综合支持平台，提供试验仪器管理、实验过程设计、数据采集与分析的一站式解决方案。

## Release 3 功能特性 — 前端全面重写

Kayak 前端基于 Flutter 从零重新开发，采用 Material Design 3 设计语言、Riverpod 状态管理和 go_router 路由系统，打造数据驱动、体验流畅的 Web 前端。

### 设备管理 (M5)
- **设备树组件**：树形结构展示设备层级关系，支持展开/折叠
- **状态指示**：节点显示状态圆点（绿/灰/红）和协议类型图标
- **三协议支持**：添加设备时可选 **Virtual / Modbus TCP / Modbus RTU**，动态切换配置表单
- **协议配置**：
  - Virtual：模式（Random/Fixed/Sine/Ramp）、数据类型、范围、更新间隔
  - Modbus TCP：主机地址、端口、从站 ID、超时时间
  - Modbus RTU：串口列表、波特率、数据位、停止位、校验位、从站 ID、超时时间
- **设备详情面板**：显示设备信息、协议参数摘要、连接状态
- **设备 CRUD**：编辑、删除（二次确认）操作
- **连接测试**：支持 Modbus 设备连接诊断

### 测点管理 (M6)
- **测点列表**：表格形式展示（名称/类型/访问权限/单位/当前值/操作），集成于设备详情面板
- **实时数值**：定期刷新当前值，支持手动刷新，状态指示（正常/超时/异常）
- **添加/编辑测点**：名称、数据类型（Number/Integer/Boolean/String）、访问权限（RO/WO/RW）、单位、范围、描述
- **Modbus 寄存器配置**：寄存器类型（Coil/Discrete Input/Holding Register/Input Register）、起始地址、数据格式
- **删除确认**：二次确认对话框，防止误操作
- **国际化**：48 个新增 ARB key，中英文全覆盖
- **响应式布局**：桌面端双面板表格、移动端卡片适配

### 已完成的 P0 前端模块
- **M1 认证与身份管理**：登录/注册页面、会话持久化、Token 自动刷新
- **M4 工作台管理**：工作台列表/创建/编辑/删除、详情页设备区
- **M5 设备管理**：（见上）
- **M6 测点管理**：（见上）

## Release 2 功能特性

### 时序数据可视化分析
- **交互式时序图表**（基于 fl_chart）
- 支持单/多曲线同时显示，独立图例控制
- 缩放、平移、光标测量等交互功能
- 深色/浅色主题自适应
- LTTB 降采样算法，高效处理大数据量

### 团队管理
- **团队 CRUD** 管理（创建、编辑、删除）
- **成员邀请机制**：邮件邀请 + 32 字符安全邀请码
- **RBAC 权限控制**：Owner / Admin / Member 三级角色
- **资源隔离**：团队资源与个人资源分离，支持 `scope` 过滤
- AppBar 团队选择器，快速切换工作上下文

### Python SDK
- **程序化访问**：完整的 REST API 封装
- **自动认证**：Token 自动刷新（过期前 5 分钟）
- **数据下载**：试验数据 HDF5 文件下载
- **数据转换**：HDF5 → pandas DataFrame / numpy ndarray
- **线程安全**：支持并发使用

## Release 1 功能特性

### Modbus 协议驱动
- **Modbus TCP** 完整支持，涵盖线圈、离散输入、保持寄存器、输入寄存器的读写操作
- **Modbus RTU** 串行协议支持，通过 RS-232/RS-485 连接物理设备
- 统一的协议抽象层，易于扩展至 CAN、VISA 等协议

### 连接池
- 基于 **Semaphore + VecDeque** 的高效连接池实现
- 支持连接复用和健康检查，提升高并发场景下的稳定性
- 自动连接恢复和资源回收机制

### Modbus TCP 模拟设备 CLI
- 内置 `modbus-simulator` 命令行工具，无需物理设备即可开发测试
- 可配置的虚拟寄存器（线圈、保持寄存器、离散输入、输入寄存器）
- 支持动态更新模拟数据，方便集成测试

### Flutter Web 前端
- 基于 **Flutter/Dart** 构建的跨平台 Web 前端 (localhost:8080)
- **Material Design 3** 设计语言，主色 #1976D2
- 响应式布局，适配桌面端和移动端浏览器
- 统一的工作台-设备-测点管理界面
- 实时数据仪表盘与可视化

### 基础功能 (Release 0 保留)
- 用户认证（JWT Token 管理）
- 工作台 CRUD 管理
- 设备与测点管理（含虚拟设备）
- 试验方法与执行引擎
- HDF5 + SQLite 双存储架构
- WebSocket 实时数据推送

## 快速开始

### Web 部署 (开发模式)

```bash
# 1. 克隆仓库
git clone https://github.com/hoolheart/kayak.git
cd kayak

# 2. 一键启动 (构建前后端 + 启动服务)
./scripts/start-web.sh
```

浏览器访问 **http://localhost:8080** 即可使用。

### 启动 Modbus TCP 模拟器 (开发/测试用)

```bash
cd kayak-backend
cargo run --bin modbus-simulator
# 默认监听 0.0.0.0:5020
```

### Docker 部署

```bash
# 单容器部署
docker-compose up -d

# 访问 http://localhost:8080
```

### 停止服务

```bash
./scripts/stop.sh
```

## Python SDK 使用

```python
from kayak import KayakClient

# 使用上下文管理器
with KayakClient('http://localhost:8080', 'admin@kayak.local', 'Admin123') as client:
    # 列出试验
    experiments = client.experiments.list()
    print(f"Found {len(experiments)} experiments")

    # 下载试验数据
    data = client.experiments.download_data(experiments[0].id)
    data.save('/tmp/experiment_data.h5')

    # 转换为 pandas DataFrame
    df = data.to_dataframe()
    print(df.head())
```

更多示例见 `kayak-python-client/examples/basic_usage.py`。

## 默认管理员账户

首次启动时会自动创建默认管理员账户：

- **邮箱**: `admin@kayak.local`
- **密码**: `Admin123`

> ⚠️ 首次登录后请及时修改密码！

## 技术栈

### 后端
- **语言**: Rust 1.75+
- **Web框架**: Axum
- **数据库**: SQLite（可升级至 PostgreSQL/MySQL）
- **数据存储**: HDF5
- **异步运行时**: Tokio
- **协议**: Modbus TCP/RTU, Virtual (可扩展)

### 前端
- **框架**: Flutter 3.19+
- **状态管理**: Riverpod 3.3+
- **路由**: go_router 17.2+
- **UI组件**: Material Design 3 (#1976D2)
- **图表**: fl_chart 1.2+
- **序列化**: freezed + json_serializable
- **HTTP**: Dio 5.9+
- **国际化**: ARB + intl 0.20+
- **部署**: Web (localhost:8080, 默认), Desktop (Windows/macOS/Linux)

## 项目结构

```
kayak/
├── arch.md                         # 架构设计文档
├── docker-compose.yml              # Docker 编排配置
├── Dockerfile.single               # 单容器 Dockerfile
├── scripts/                        # 启动/停止脚本
│   ├── start-web.sh                # Web 部署启动脚本 (推荐)
│   ├── start-r2s2.sh               # Sprint 2 开发环境启动
│   ├── stop-r2s2.sh                # Sprint 2 开发环境停止
│   ├── start-desktop.sh            # 桌面部署启动脚本
│   ├── stop.sh                     # 停止脚本
│   ├── ci-check.sh                 # CI 本地检查
│   └── generate-coverage.sh        # 覆盖率生成
├── kayak-backend/                  # Rust 后端
│   ├── src/
│   │   ├── api/                    # API 处理器和路由
│   │   ├── services/               # 业务服务
│   │   ├── models/                 # 数据模型
│   │   ├── drivers/                # 设备驱动
│   │   │   ├── modbus/             # Modbus TCP/RTU 协议驱动
│   │   │   │   ├── tcp.rs          # Modbus TCP 实现
│   │   │   │   ├── rtu.rs          # Modbus RTU 实现
│   │   │   │   ├── pool.rs         # 连接池 (Semaphore + VecDeque)
│   │   │   │   ├── pdu.rs          # 协议数据单元
│   │   │   │   └── types.rs        # Modbus 数据类型
│   │   │   └── virtual.rs          # 虚拟设备驱动
│   │   ├── db/                     # 数据库访问
│   │   └── bin/                    # CLI 工具
│   │       └── modbus-simulator/   # Modbus TCP 模拟设备
│   └── Cargo.toml
├── kayak-frontend/                 # Flutter 前端 (全面重写，v3.0)
│   ├── lib/
│   │   ├── app.dart                # 应用入口
│   │   ├── main.dart               # 启动入口
│   │   ├── generated/              # 代码生成输出
│   │   ├── l10n/                   # 国际化 (ARB 文件)
│   │   ├── models/                 # 数据模型 (freezed)
│   │   │   ├── device.dart         # 设备模型
│   │   │   ├── point.dart          # 测点模型
│   │   │   ├── protocol.dart       # 协议配置模型
│   │   │   ├── workbench.dart      # 工作台模型
│   │   │   ├── team.dart           # 团队模型
│   │   │   ├── experiment.dart     # 试验模型
│   │   │   ├── method.dart         # 方法模型
│   │   │   ├── user.dart           # 用户模型
│   │   │   └── common.dart         # 通用类型
│   │   ├── pages/                  # 页面
│   │   │   ├── auth/               # 登录、注册
│   │   │   ├── dashboard/          # 首页仪表盘
│   │   │   ├── workbench/          # 工作台列表、详情
│   │   │   ├── device/             # 设备管理
│   │   │   ├── point/              # 测点管理 (列表/表单/数值)
│   │   │   ├── experiment/         # 试验列表/创建/控制台
│   │   │   ├── method/             # 方法列表/编辑
│   │   │   ├── analysis/           # 数据分析
│   │   │   ├── settings/           # 设置页
│   │   │   └── not_found_page.dart
│   │   ├── widgets/                # 可复用组件
│   │   │   ├── device_tree.dart    # 设备树组件
│   │   │   ├── device_config_dialog.dart  # 设备配置对话框 (三协议)
│   │   │   ├── app_shell.dart      # 应用外壳 (侧边栏/导航)
│   │   │   ├── async_value_widget.dart    # 异步状态组件
│   │   │   ├── confirm_dialog.dart # 通用确认对话框
│   │   │   ├── empty_view.dart     # 空状态视图
│   │   │   ├── error_view.dart     # 错误视图
│   │   │   ├── skeleton.dart       # 骨架屏
│   │   │   └── toast.dart          # Toast 通知
│   │   ├── router/
│   │   │   └── app_router.dart     # go_router 路由定义
│   │   ├── services/               # API 服务层
│   │   │   ├── api_client.dart     # Dio HTTP 客户端
│   │   │   ├── auth_service.dart   # 认证服务
│   │   │   ├── device_service.dart # 设备服务
│   │   │   ├── point_service.dart  # 测点服务
│   │   │   ├── workbench_service.dart     # 工作台服务
│   │   │   ├── auth_interceptor.dart      # 认证拦截器
│   │   │   ├── error_interceptor.dart     # 错误拦截器
│   │   │   └── token_storage.dart  # Token 存储
│   │   ├── providers/              # Riverpod 状态管理
│   │   │   ├── auth_provider.dart
│   │   │   ├── device_provider.dart
│   │   │   ├── point_provider.dart
│   │   │   ├── workbench_provider.dart
│   │   │   ├── settings_provider.dart
│   │   │   └── services.dart       # 服务注册
│   │   ├── theme/                  # Material Design 3 主题
│   │   └── utils/                  # 工具函数
│   └── pubspec.yaml
├── kayak-python-client/            # Python 客户端库
├── docs/                           # 文档
│   ├── api.md                      # API 文档
│   ├── deployment.md               # 部署指南
│   ├── development.md              # 开发指南
│   └── releases/                   # 发布说明
│       ├── v0.1.0.md               # Release 0
│       └── v0.2.0.md               # Release 1
└── data/                           # 数据存储目录 (运行时生成)
```

## 前端路由

| 路径 | 页面 | 说明 | 模块 |
|------|------|------|:----:|
| `/login` | 登录页 | 邮箱+密码登录 | M1 |
| `/register` | 注册页 | 邮箱+密码+用户名注册 | M1 |
| `/dashboard` | 首页仪表盘 | 欢迎信息 + 快捷入口 + 统计 | M2 |
| `/workbenches` | 工作台列表 | 卡片网格 + 搜索 + 创建入口 | M4 |
| `/workbenches/{id}` | 工作台详情 | 左侧设备树 + 右侧设备详情/测点面板 | M5+M6 |
| `/methods` | 方法列表 | 方法卡片 + 搜索 + 创建入口 | M7 |
| `/methods/{id}/edit` | 方法编辑 | JSON 定义 + 参数表管理 | M7 |
| `/experiments` | 试验列表 | 表格展示 + 状态/时间筛选 | M8 |
| `/experiments/new` | 创建试验 | 三步流程（工作台→方法→参数） | M8 |
| `/experiments/{id}` | 试验控制台 | 控制面板 + 日志监控（WebSocket） | M8 |
| `/analysis` | 数据分析 | 时序图表 + 多曲线叠加 + 降采样 | M9 |
| `/settings` | 设置页 | 主题/语言切换 + 关于信息 | M10 |

> 设备管理（M5）和测点管理（M6）集成于工作台详情页 `/workbenches/{id}`，作为设备的双面板管理界面。

## API 端点

启动后端服务后，访问 http://localhost:8080/api/docs 查看 Swagger API 文档。

主要 API 端点：

| 分类 | 端点 | 方法 | 说明 |
|------|------|:----:|------|
| **认证** | `/api/v1/auth/login` | POST | 用户登录 |
| | `/api/v1/auth/register` | POST | 用户注册 |
| | `/api/v1/auth/refresh` | POST | 刷新 Token |
| | `/api/v1/auth/me` | GET | 获取当前用户信息 |
| **用户** | `/api/v1/users/me` | GET | 获取用户资料 |
| | `/api/v1/users/me` | PUT | 更新用户资料 |
| | `/api/v1/users/me/password` | POST | 修改密码 |
| **工作台** | `/api/v1/workbenches` | GET | 工作台列表 |
| | `/api/v1/workbenches` | POST | 创建工作台 |
| | `/api/v1/workbenches/{id}` | GET | 工作台详情 |
| | `/api/v1/workbenches/{id}` | PUT | 更新工作台 |
| | `/api/v1/workbenches/{id}` | DELETE | 删除工作台 |
| **设备** | `/api/v1/workbenches/{wb_id}/devices` | GET | 工作台下设备列表 |
| | `/api/v1/workbenches/{wb_id}/devices` | POST | 添加设备 |
| | `/api/v1/devices/{id}` | GET | 设备详情 |
| | `/api/v1/devices/{id}` | PUT | 更新设备 |
| | `/api/v1/devices/{id}` | DELETE | 删除设备 |
| | `/api/v1/devices/{id}/test-connection` | POST | 测试连接 |
| | `/api/v1/devices/{id}/connect` | POST | 连接设备 |
| | `/api/v1/devices/{id}/disconnect` | POST | 断开设备 |
| | `/api/v1/devices/{id}/status` | GET | 获取设备状态 |
| **测点** | `/api/v1/devices/{dev_id}/points` | GET | 测点列表 |
| | `/api/v1/devices/{dev_id}/points` | POST | 添加测点 |
| | `/api/v1/points/{id}` | GET | 测点详情 |
| | `/api/v1/points/{id}` | PUT | 更新测点 |
| | `/api/v1/points/{id}` | DELETE | 删除测点 |
| | `/api/v1/points/{id}/value` | GET | 读取测点实时值 |
| | `/api/v1/points/{id}/value` | PUT | 写入测点值 |
| **试验** | `/api/v1/experiments` | GET | 试验列表 |
| | `/api/v1/experiments/{id}` | GET | 试验详情 |
| | `/api/v1/experiments/{id}/data/query` | POST | 查询试验时序数据 |
| | `/api/v1/experiments/{id}/data-file` | GET | 下载数据文件 |
| **试验控制** | `/api/v1/experiments/{id}/load` | POST | 载入试验 |
| | `/api/v1/experiments/{id}/start` | POST | 开始试验 |
| | `/api/v1/experiments/{id}/pause` | POST | 暂停试验 |
| | `/api/v1/experiments/{id}/resume` | POST | 继续试验 |
| | `/api/v1/experiments/{id}/stop` | POST | 停止试验 |
| | `/api/v1/experiments/{id}/status` | GET | 试验状态 |
| | `/api/v1/experiments/{id}/history` | GET | 状态变更历史 |
| **方法** | `/api/v1/methods` | GET | 方法列表 |
| | `/api/v1/methods` | POST | 创建方法 |
| | `/api/v1/methods/{id}` | GET | 方法详情 |
| | `/api/v1/methods/{id}` | PUT | 更新方法 |
| | `/api/v1/methods/{id}` | DELETE | 删除方法 |
| | `/api/v1/methods/validate` | POST | 验证方法 |
| **团队** | `/api/v1/teams` | GET | 获取团队列表 |
| | `/api/v1/teams` | POST | 创建团队 |
| | `/api/v1/teams/{id}` | GET | 获取团队详情 |
| | `/api/v1/teams/{id}` | PUT | 更新团队 |
| | `/api/v1/teams/{id}` | DELETE | 删除团队 |
| | `/api/v1/teams/{id}/members` | GET | 获取团队成员 |
| | `/api/v1/teams/{id}/invitations` | POST | 邀请成员 |
| | `/api/v1/invitations/{code}/accept` | POST | 接受邀请 |
| **协议** | `/api/v1/protocols` | GET | 支持的协议列表 |
| | `/api/v1/system/serial-ports` | GET | 系统可用串口列表 |
| **WebSocket** | `/ws/experiments/{id}` | WS | 试验状态+日志实时推送 |

详细 API 文档请参考 [docs/api.md](docs/api.md)。

## 部署架构

### 单容器 Web 部署 (推荐)
```
┌─────────────────────────────────────────┐
│              Docker Container            │
│  ┌──────────────┐   ┌─────────────────┐ │
│  │   Flutter    │   │   Rust/Axum     │ │
│  │   Web UI     │──│   API Server     │ │
│  │   :8080      │   │                 │ │
│  └──────────────┘   └─────────────────┘ │
│                              │           │
│                       ┌──────┴──────┐   │
│                       │  SQLite +   │   │
│                       │    HDF5     │   │
│                       └─────────────┘   │
└─────────────────────────────────────────┘
```

```bash
docker-compose up -d
```

更多部署方式请参考 [docs/deployment.md](docs/deployment.md)。

## 开发指南

### 后端开发

```bash
cd kayak-backend

# 运行测试
cargo test

# 运行开发服务器
cargo run

# 代码格式化
cargo fmt

# 静态检查
cargo clippy
```

### 前端开发

```bash
cd kayak-frontend

# 获取依赖
flutter pub get

# 运行 Web 应用
flutter run -d chrome

# 构建 Web 版本
flutter build web

# 运行测试
flutter test
```

### Modbus 模拟器 (开发测试)

```bash
cd kayak-backend

# 启动 Modbus TCP 模拟设备 (默认端口 5020)
cargo run --bin modbus-simulator

# 自定义端口
cargo run --bin modbus-simulator -- --port 5021
```

## CI/CD

本项目使用 GitHub Actions 实现持续集成和持续部署：

### 工作流
- **CI 工作流** (`.github/workflows/ci.yml`): 每次推送和 PR 时自动运行
  - 代码格式化检查 (rustfmt, dart format)
  - 静态代码分析 (clippy, flutter analyze)
  - 单元测试执行 (cargo test, flutter test)
  - 代码覆盖率报告 (cargo-tarpaulin, lcov)
  - 构建验证 (Release 构建)

### 本地验证

```bash
# 运行所有 CI 检查
./scripts/ci-check.sh

# 生成覆盖率报告
./scripts/generate-coverage.sh all
./scripts/generate-coverage.sh backend
./scripts/generate-coverage.sh frontend
```

## 路线图

### Release 3 (前端全面重写) — Sprint 1~4 已完成 (19/27 任务)
- [x] Sprint 1 — 基础设施：项目初始化、数据模型、API Client、路由、主题、国际化、组件库
- [x] Sprint 2 — M1 认证与身份管理：登录/注册页面、会话持久化、Token 自动刷新
- [x] Sprint 3 — M4 工作台管理：工作台列表/创建/编辑/删除、详情页
- [x] Sprint 4 — M5 设备管理 + M6 测点管理：设备树、三协议配置、测点列表、实时数值
- [ ] Sprint 5 — M8 试验执行控制台：试验列表、创建流程、控制台（WebSocket 实时通信）
- [ ] Sprint 6 — P1 模块：首页仪表盘、方法管理、数据分析、设置页

### Release 2 (v0.x) - 已完成
- [x] Modbus TCP 协议驱动
- [x] Modbus RTU 协议驱动
- [x] 连接池管理 (Semaphore + VecDeque)
- [x] Modbus TCP 模拟设备 CLI
- [x] 时序数据可视化分析
- [x] 团队管理（CRUD、邀请、RBAC）
- [x] Python 客户端库

### Release 1 (v0.2.0) - 已完成
- [x] Modbus TCP 协议驱动
- [x] Modbus RTU 协议驱动
- [x] 连接池管理 (Semaphore + VecDeque)
- [x] Modbus TCP 模拟设备 CLI
- [x] Flutter Web 前端 (v1)
- [x] Material Design 3 UI

### Release 0 (v0.1.0) - 已完成
- [x] 基础架构设计
- [x] 用户认证系统
- [x] 工作台与虚拟设备管理
- [x] 试验过程基础框架
- [x] 数据管理基础 (HDF5 + SQLite)
- [x] WebSocket 实时通信
- [x] Docker 部署支持

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系我们

- 项目主页: https://github.com/hoolheart/kayak
- 问题反馈: https://github.com/hoolheart/kayak/issues
- 发布说明: [docs/releases/](docs/releases/)

---

**注意**: 本项目处于早期开发阶段，API 和功能可能会发生变化。
