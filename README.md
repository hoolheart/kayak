# Kayak - 科学研究支持软件

[![CI](https://github.com/your-org/kayak/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/kayak/actions/workflows/ci.yml)
[![Rust](https://img.shields.io/badge/Rust-1.75%2B-orange.svg)](https://www.rust-lang.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.16%2B-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Kayak 是一款面向科学研究活动的综合支持平台，提供试验仪器管理、实验过程设计、数据采集与分析的一站式解决方案。

## 功能特性

### 仪器管理
- 工作台-设备-测点三层结构管理
- 支持设备嵌套和协议插件扩展
- 虚拟设备支持，便于开发和测试
- RESTful API 提供完整的元数据访问

### 试验方法编辑
- 基于脚本的试验过程定义
- 支持多种环节类型（读取、控制、延迟、判断等）
- 可配置参数表，支持静态和动态配置
- 过程嵌套支持

### 试验过程控制
- 完整的试验状态管理（启动、暂停、继续、停止）
- 实时数据监控和日志记录
- HDF5 格式数据自动存储
- WebSocket 实时推送

### 数据管理
- HDF5 + SQLite 双存储架构
- 时序数据高效存储和查询
- 数据文件权限管理
- CSV 导出支持

### 部署灵活性
- **桌面部署**: 独立应用程序（Windows/macOS/Linux）
- **单容器部署**: Docker 单容器 Web 应用
- **分离部署**: 前后端分离的双容器部署
- **混合部署**: 桌面前端 + 容器后端

## 技术栈

### 后端
- **语言**: Rust 1.75+
- **Web框架**: Axum
- **数据库**: SQLite（可升级至 PostgreSQL/MySQL）
- **数据存储**: HDF5
- **异步运行时**: Tokio

### 前端
- **框架**: Flutter 3.16+
- **状态管理**: Riverpod
- **路由**: go_router
- **UI组件**: Material Design 3
- **图表**: fl_chart

## 快速开始

### 环境要求

- **Rust**: 1.75 或更高版本 ([安装指南](https://rustup.rs/))
- **Flutter**: 3.16 或更高版本 ([安装指南](https://flutter.dev/docs/get-started/install))
- **Docker**: （可选，用于容器部署）

### 桌面部署

```bash
# 1. 克隆仓库
git clone https://github.com/your-org/kayak.git
cd kayak

# 2. 启动桌面应用（自动构建前后端）
./scripts/start-desktop.sh
```

### Web 部署

```bash
# 开发模式启动
./scripts/start-web.sh

# 或使用 Docker
./scripts/start-web.sh --docker
```

### 停止服务

```bash
./scripts/stop.sh
```

## 项目结构

```
kayak/
├── arch.md                    # 架构设计文档
├── docker-compose.yml         # Docker 编排配置
├── scripts/                   # 启动/停止脚本
│   ├── start-desktop.sh       # 桌面部署启动脚本
│   ├── start-web.sh           # Web部署启动脚本
│   └── stop.sh                # 停止脚本
├── kayak-backend/             # Rust 后端
│   ├── src/
│   │   ├── api/               # API 处理器和路由
│   │   ├── services/          # 业务服务
│   │   ├── models/            # 数据模型
│   │   ├── drivers/           # 设备驱动
│   │   └── db/                # 数据库访问
│   └── Cargo.toml
├── kayak-frontend/            # Flutter 前端
│   ├── lib/
│   │   ├── screens/           # 页面
│   │   ├── widgets/           # 组件
│   │   ├── services/          # API 服务
│   │   └── providers/         # 状态管理
│   └── pubspec.yaml
├── kayak-python-client/       # Python 客户端库
│   └── kayak/
└── log/release_0/             # 项目文档
    ├── prd.md                 # 产品需求文档
    ├── tasks.md               # 任务分解
    └── arch.md                # 架构设计文档
```

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

# 运行桌面应用
flutter run -d linux

# 构建 Web 版本
flutter build web

# 运行测试
flutter test
```

## API 文档

启动后端服务后，访问 http://localhost:8080/api/docs 查看 Swagger API 文档。

主要 API 端点：

- `POST /api/v1/auth/login` - 用户登录
- `GET /api/v1/workbenches` - 获取工作台列表
- `GET /api/v1/devices/{id}/points` - 获取设备测点
- `POST /api/v1/experiments` - 创建试验
- `WS /ws` - WebSocket 实时通信

## 部署架构

### 1. 桌面完整部署
```
┌─────────────────────────────────────┐
│           Desktop App               │
│  ┌──────────────┐  ┌──────────────┐ │
│  │   Flutter    │  │   Rust       │ │
│  │   Frontend   │──│   Backend    │ │
│  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────┘
```

### 2. 单容器 Web 部署
```bash
docker-compose up -d
```

### 3. 前后端分离部署
```bash
docker-compose -f docker-compose.separate.yml up -d
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
在提交代码前，建议运行本地 CI 检查脚本：

```bash
# 运行所有 CI 检查
./scripts/ci-check.sh

# 生成覆盖率报告
./scripts/generate-coverage.sh all
./scripts/generate-coverage.sh backend
./scripts/generate-coverage.sh frontend
```

### 分支保护
- `main` 分支受到保护，必须通过 Pull Request 合并
- 所有 CI 检查必须通过才能合并
- 需要代码审查批准

## 路线图

### Release 0 (当前)
- [x] 基础架构设计
- [ ] 用户认证系统
- [ ] 工作台与虚拟设备管理
- [ ] 试验过程基础框架
- [ ] 数据管理基础

### Release 1
- [ ] Modbus/CAN 协议支持
- [ ] 可视化试验方法编辑器
- [ ] 数据可视化分析

### Release 2
- [ ] VISA 协议支持
- [ ] Python 客户端库
- [ ] LaTeX 图表导出

### Release 3
- [ ] 高级数据分析
- [ ] 团队协作功能
- [ ] 云端部署支持

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系我们

- 项目主页: https://github.com/your-org/kayak
- 问题反馈: https://github.com/your-org/kayak/issues
- 文档: https://kayak.readthedocs.io

---

**注意**: 本项目处于早期开发阶段，API 和功能可能会发生变化。
