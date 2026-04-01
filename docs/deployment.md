# Kayak 部署指南

## 目录

- [快速开始](#快速开始)
- [部署方式](#部署方式)
  - [方式一：Docker单容器部署](#方式一docker单容器部署)
  - [方式二：Docker Compose部署](#方式二docker-compose部署)
  - [方式三：本地开发模式](#方式三本地开发模式)
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
# 使用Docker（推荐）
docker-compose up -d

# 或使用本地构建
./scripts/start-web.sh
```

### 3. 访问应用

打开浏览器访问 http://localhost:8080

---

## 部署方式

### 方式一：Docker单容器部署

单容器部署包含前端（Web）和后端，适合小型部署。

#### 构建Docker镜像

```bash
docker build -t kayak:single -f Dockerfile.single .
```

#### 运行容器

```bash
docker run -d \
  --name kayak-single \
  -p 8080:8080 \
  -v $(pwd)/data:/app/data \
  -e KAYAK_DATA_DIR=/app/data \
  kayak:single
```

#### 验证部署

```bash
# 检查容器状态
docker ps

# 检查健康状态
curl http://localhost:8080/health
```

---

### 方式二：Docker Compose部署

Docker Compose允许更灵活的配置，包括分离前端和后端服务。

#### 启动服务

```bash
docker-compose up -d
```

#### 查看日志

```bash
docker-compose logs -f
```

#### 停止服务

```bash
docker-compose down
```

#### 重新构建

```bash
docker-compose up -d --build
```

---

### 方式三：本地开发模式

需要安装：
- Rust 1.75+
- Flutter 3.16+

#### 启动后端和前端（开发模式）

```bash
./scripts/start-web.sh
```

#### 仅构建

```bash
./scripts/start-web.sh --build-only
```

#### 使用Docker部署

```bash
./scripts/start-web.sh --docker
```

---

## 桌面应用

Flutter桌面应用支持Windows、macOS和Linux。

### 构建桌面应用

```bash
cd kayak-frontend

# 构建Linux桌面应用
flutter build linux --release

# 构建Windows桌面应用
flutter build windows --release

# 构建macOS桌面应用
flutter build macos --release
```

构建产物位于 `build/linux/release/bundle/`（Linux）。

### 运行桌面应用

```bash
# Linux
./build/linux/release/bundle/kayak

# 需要配置后端地址
KAYAK_API_URL=http://localhost:8080 ./build/linux/release/bundle/kayak
```

---

## 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `KAYAK_DATA_DIR` | `/app/data` | 数据存储目录 |
| `DATABASE_URL` | `sqlite:///app/data/kayak.db` | 数据库连接URL |
| `KAYAK_LOG_LEVEL` | `info` | 日志级别（trace, debug, info, warn, error） |
| `KAYAK_SERVE_STATIC` | `/app/web` | 静态文件目录（前端Web构建） |

### 开发环境变量示例

```bash
export KAYAK_DATA_DIR=./data
export DATABASE_URL=sqlite:///$(pwd)/data/kayak.db
export KAYAK_LOG_LEVEL=debug
export RUST_BACKTRACE=1
```

---

## 故障排除

### 端口被占用

```bash
# 查找占用端口的进程
lsof -i :8080

# 或
netstat -tulpn | grep 8080

# 停止占用进程或更改端口
```

### 数据库初始化失败

```bash
# 删除旧数据库重新初始化
rm -rf data/kayak.db
# 重启服务
```

### 前端资源加载失败

```bash
# 检查静态文件是否存在
ls -la web/

# 重新构建前端
cd kayak-frontend
flutter build web --release
```

### Docker构建失败

```bash
# 清理Docker构建缓存
docker builder prune

# 重新构建
docker build --no-cache -t kayak:single -f Dockerfile.single .
```

---

## 目录结构

```
kayak/
├── data/              # 数据存储目录
│   └── kayak.db       # SQLite数据库文件
├── logs/              # 日志目录
├── kayak-backend/     # 后端源代码
├── kayak-frontend/    # 前端源代码
├── scripts/           # 启动脚本
├── docker-compose.yml  # Docker编排配置
├── Dockerfile.single   # 单容器Dockerfile
└── README.md          # 项目说明
```

---

## 更多信息

- 项目文档：https://github.com/hoolheart/kayak
- 问题反馈：https://github.com/hoolheart/kayak/issues
