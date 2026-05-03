# Kayak - 科学研究支持软件

[![CI](https://github.com/hoolheart/kayak/actions/workflows/ci.yml/badge.svg)](https://github.com/hoolheart/kayak/actions/workflows/ci.yml)
[![Rust](https://img.shields.io/badge/Rust-1.75%2B-orange.svg)](https://rust-lang.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.16%2B-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Kayak 是一款面向科学研究活动的综合支持平台，提供试验仪器管理、实验过程设计、数据采集与分析的一站式解决方案。

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
- **框架**: Flutter 3.16+
- **状态管理**: Riverpod
- **路由**: go_router
- **UI组件**: Material Design 3 (#1976D2)
- **图表**: fl_chart
- **部署**: Web (localhost:8080), Desktop (Windows/macOS/Linux)

## 项目结构

```
kayak/
├── arch.md                         # 架构设计文档
├── docker-compose.yml              # Docker 编排配置
├── Dockerfile.single               # 单容器 Dockerfile
├── scripts/                        # 启动/停止脚本
│   ├── start-web.sh                # Web 部署启动脚本 (推荐)
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
├── kayak-frontend/                 # Flutter 前端
│   ├── lib/
│   │   ├── screens/                # 页面
│   │   ├── widgets/                # 组件
│   │   ├── services/               # API 服务
│   │   └── providers/              # 状态管理
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

## API 端点

启动后端服务后，访问 http://localhost:8080/api/docs 查看 Swagger API 文档。

主要 API 端点：

- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/register` - 用户注册
- `GET /api/v1/auth/me` - 获取当前用户信息
- `GET /api/v1/workbenches` - 获取工作台列表
- `POST /api/v1/devices/{id}/connect` - 连接设备
- `GET /api/v1/devices/{id}/points` - 获取设备测点
- `GET /api/v1/points/{id}/value` - 读取测点实时值
- `POST /api/v1/experiments` - 创建试验
- `WS /ws` - WebSocket 实时通信

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

### Release 0 (v0.1.0) - 已完成
- [x] 基础架构设计
- [x] 用户认证系统
- [x] 工作台与虚拟设备管理
- [x] 试验过程基础框架
- [x] 数据管理基础 (HDF5 + SQLite)
- [x] WebSocket 实时通信
- [x] Docker 部署支持

### Release 1 (v0.2.0) - 已完成
- [x] Modbus TCP 协议驱动
- [x] Modbus RTU 协议驱动
- [x] 连接池管理 (Semaphore + VecDeque)
- [x] Modbus TCP 模拟设备 CLI
- [x] Flutter Web 前端
- [x] Material Design 3 UI

### Release 2 (计划中)
- [ ] CAN 协议支持
- [ ] 可视化试验方法编辑器
- [ ] 数据可视化分析
- [ ] Python 客户端库

### Release 3 (计划中)
- [ ] VISA 协议支持
- [ ] 高级数据分析
- [ ] 团队协作功能
- [ ] 云端部署支持

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
