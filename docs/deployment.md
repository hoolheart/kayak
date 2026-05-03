# Kayak 部署指南

## 目录

- [快速开始](#快速开始)
- [部署方式](#部署方式)
  - [方式一：一键 Web 部署（推荐）](#方式一一键-web-部署推荐)
  - [方式二：Docker 单容器部署](#方式二docker-单容器部署)
  - [方式三：Docker Compose 部署](#方式三docker-compose-部署)
  - [方式四：分离部署（开发模式）](#方式四分离部署开发模式)
- [Modbus 模拟器](#modbus-模拟器开发测试)
- [桌面应用](#桌面应用)
- [环境变量](#环境变量)
- [故障排除](#故障排除)

---

## 快速开始

### 1. 下载最新版本

```bash
git clone https://github.com/hoolheart/kayak.git
cd kayak
```

### 2. 启动服务

```bash
# 推荐：一键启动（自动构建前后端）
./scripts/start-web.sh
```

### 3. 访问应用

打开浏览器访问 **http://localhost:8080**

### 4. 默认管理员账户

首次启动时会自动创建默认管理员账户：

- **邮箱**: `admin@kayak.local`
- **密码**: `Admin123`

> ⚠️ 首次登录后请及时修改密码！

### 5. 启动 Modbus 模拟器（可选）

如果需要测试 Modbus 功能但无物理设备：

```bash
cd kayak-backend
cargo run --bin modbus-simulator
# 默认监听 0.0.0.0:5020
```

---

## 部署方式

### 方式一：一键 Web 部署（推荐）

适用于开发环境和快速体验。脚本自动完成前端 Flutter Web 构建 + 后端 Rust 编译 + 服务启动。

```bash
./scripts/start-web.sh
```

**执行过程**：
1. 检查 Rust 和 Flutter 环境
2. 使用 `cargo build --release` 编译后端
3. 使用 `flutter build web --release` 构建前端
4. 后端以静态文件服务模式启动，同时提供 API
5. 自动绑定 `localhost:8080`

**参数选项**：

| 参数 | 说明 |
|------|------|
| `--build-only` | 仅构建，不启动服务 |
| `--docker` | 使用 Docker Compose 部署 |
| `--help` | 显示帮助信息 |

### 方式二：Docker 单容器部署

单容器包含前端（Web）和后端，适合小型部署和生产环境。

#### 构建 Docker 镜像

```bash
docker build -t kayak:latest -f Dockerfile.single .
```

#### 运行容器

```bash
docker run -d \
  --name kayak \
  -p 8080:8080 \
  -v $(pwd)/data:/app/data \
  -e KAYAK_DATA_DIR=/app/data \
  kayak:latest
```

#### 验证部署

```bash
# 检查容器状态
docker ps

# 检查健康状态
curl http://localhost:8080/health
```

### 方式三：Docker Compose 部署

支持更灵活的配置和多服务编排。

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 重新构建
docker-compose up -d --build

# 停止服务
docker-compose down
```

### 方式四：分离部署（开发模式）

前后端分别启动，适用于前端开发时的热重载场景。

```bash
# 终端 1 — 启动后端
cd kayak-backend
export KAYAK_DATA_DIR=../data
export KAYAK_LOG_LEVEL=debug
export DATABASE_URL="sqlite://$(realpath ../data)/kayak.db"
cargo run

# 终端 2 — 启动前端（热重载模式）
cd kayak-frontend
flutter run -d chrome --web-port 8081
```

前端会连接 `http://localhost:8080` 后端 API（需配置 CORS 或代理）。

---

## Modbus 模拟器（开发测试）

Kayak 内置了 Modbus TCP 模拟设备，无需物理 PLC 即可测试协议功能。

### 启动模拟器

```bash
cd kayak-backend
cargo run --bin modbus-simulator
```

输出示例：
```
Modbus TCP Simulator starting on 0.0.0.0:5020
Simulated device ready with unit_id=1
  Coils: 0-99
  Discrete Inputs: 0-99
  Holding Registers: 0-99
  Input Registers: 0-99
```

### 自定义端口

```bash
cargo run --bin modbus-simulator -- --port 5021
```

### 在 Kayak 中连接模拟器

创建 Modbus TCP 设备时，使用如下配置：

```json
{
  "name": "Simulated PLC",
  "protocol_type": "modbus-tcp",
  "protocol_params": {
    "host": "127.0.0.1",
    "port": 5020,
    "unit_id": 1
  }
}
```

---

## 桌面应用

Flutter 桌面应用支持 Windows、macOS 和 Linux。

### 构建桌面应用

```bash
cd kayak-frontend

# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

构建产物位于 `build/<platform>/release/bundle/`。

### 运行桌面应用

```bash
# Linux
./build/linux/release/bundle/kayak

# macOS
open build/macos/Release/Kayak.app
```

### 桌面应用连接后端

```bash
# 指定后端地址
KAYAK_API_URL=http://localhost:8080 ./build/linux/release/bundle/kayak
```

桌面应用默认连接 `http://localhost:8080`，可通过环境变量 `KAYAK_API_URL` 指定远程后端。

---

## 环境变量

### 后端环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `KAYAK_DATA_DIR` | `./data` | 数据存储目录（SQLite DB、HDF5 文件） |
| `DATABASE_URL` | `sqlite://./data/kayak.db` | 数据库连接 URL |
| `KAYAK_LOG_LEVEL` | `info` | 日志级别：`trace`, `debug`, `info`, `warn`, `error` |
| `KAYAK_SERVE_STATIC` | (空) | 静态文件目录（前端 Web 构建产物路径） |
| `RUST_BACKTRACE` | `0` | 设置为 `1` 开启完整错误回溯 |

### 前端环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `KAYAK_API_URL` | `http://localhost:8080` | 后端 API 地址 |

### 开发环境示例

```bash
export KAYAK_DATA_DIR=./data
export DATABASE_URL="sqlite://$(pwd)/data/kayak.db"
export KAYAK_LOG_LEVEL=debug
export KAYAK_SERVE_STATIC="./kayak-frontend/build/web"
export RUST_BACKTRACE=1
```

---

## 故障排除

### 端口被占用

```bash
# 查找占用 8080 端口的进程
lsof -i :8080

# 终止进程
kill -9 <PID>
```

### 数据库初始化失败

```bash
# 删除旧数据库重新初始化
rm -rf data/kayak.db
# 重启服务
./scripts/start-web.sh
```

### 前端资源加载失败或显示旧版本

```bash
# 清理 Flutter 构建缓存
cd kayak-frontend
flutter clean
flutter build web --release

# 确保后端指向正确的前端目录
export KAYAK_SERVE_STATIC="./kayak-frontend/build/web"
```

### Modbus 模拟器无法连接

```bash
# 检查模拟器是否在运行
lsof -i :5020

# 检查防火墙设置
# macOS: 系统偏好设置 > 安全性与隐私 > 防火墙

# 启动模拟器
cd kayak-backend
cargo run --bin modbus-simulator
```

### Docker 构建失败

```bash
# 清理 Docker 构建缓存
docker builder prune

# 重新构建（不使用缓存）
docker build --no-cache -t kayak:latest -f Dockerfile.single .
```

### Rust 编译太慢

```bash
# 开发时使用 debug 模式（更快的编译，但运行较慢）
cargo run

# 仅为发布部署使用 release 模式
cargo build --release
```

### macOS 编译 HDF5 失败

```bash
# 安装 HDF5 库
brew install hdf5

# 设置环境变量
export HDF5_DIR=$(brew --prefix hdf5)
```

---

## 目录结构

```
kayak/
├── data/                         # 数据存储目录（运行时生成）
│   ├── kayak.db                  # SQLite 数据库文件
│   └── experiments/              # HDF5 试验数据文件
├── logs/                         # 日志目录
├── kayak-backend/                # Rust 后端源码
├── kayak-frontend/               # Flutter 前端源码
├── scripts/                      # 启动/停止脚本
│   ├── start-web.sh              # Web 部署一键启动（推荐）
│   ├── start-desktop.sh          # 桌面应用启动
│   └── stop.sh                   # 停止所有服务
├── docs/                         # 项目文档
├── docker-compose.yml            # Docker Compose 编排
├── Dockerfile.single             # 单容器 Dockerfile
└── README.md                     # 项目说明
```

---

## 更多信息

- [API 文档](api.md)
- [开发指南](development.md)
- [发布说明](releases/)
- 项目主页：https://github.com/hoolheart/kayak
- 问题反馈：https://github.com/hoolheart/kayak/issues
