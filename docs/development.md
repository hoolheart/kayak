# Kayak 开发指南

## 项目结构

```
kayak/
├── kayak-backend/          # Rust后端
│   ├── src/
│   │   ├── api/           # API handlers and routes
│   │   ├── auth/          # Authentication
│   │   ├── core/          # Core utilities
│   │   ├── db/           # Database layer
│   │   ├── models/        # Data models
│   │   └── services/     # Business services
│   ├── migrations/        # SQL migrations
│   └── Cargo.toml
├── kayak-frontend/        # Flutter前端
│   ├── lib/
│   │   ├── core/         # Core utilities
│   │   ├── features/      # Feature modules
│   │   └── shared/       # Shared widgets
│   └── pubspec.yaml
├── docs/                  # 文档
├── scripts/               # 脚本
└── docker-compose.yml
```

## 技术栈

### 后端 (Rust)

- **框架**: Axum 0.7+
- **数据库**: SQLite (sqlx)
- **认证**: JWT (jsonwebtoken)
- **密码哈希**: bcrypt
- **序列化**: serde

### 前端 (Flutter)

- **框架**: Flutter 3.16+
- **状态管理**: Riverpod
- **路由**: go_router
- **HTTP**: Dio
- **本地存储**: shared_preferences, flutter_secure_storage

## 环境要求

- Rust 1.75+
- Flutter 3.16+
- SQLite3

## 开发设置

### 1. 克隆项目

```bash
git clone https://github.com/hoolheart/kayak.git
cd kayak
```

### 2. 设置后端

```bash
cd kayak-backend

# 创建数据目录
mkdir -p ../data

# 运行开发服务器
cargo run
```

后端会在 http://localhost:8080 运行。

### 3. 设置前端

```bash
cd kayak-frontend

# 获取依赖
flutter pub get

# 运行开发服务器
flutter run
```

前端会在 http://localhost:8081 运行（默认）。

### 4. 环境变量

后端环境变量：

```bash
# 数据目录
export KAYAK_DATA_DIR=./data

# 数据库URL
export DATABASE_URL=sqlite:///path/to/kayak.db

# 日志级别
export KAYAK_LOG_LEVEL=debug

# 后端端口
export KAYAK_SERVER_PORT=8080
```

## 代码规范

### Rust

- 使用 `cargo fmt` 格式化代码
- 使用 `cargo clippy` 进行代码检查
- 遵循标准 Rust 命名约定

```bash
# 格式化
cargo fmt

# 检查
cargo clippy
```

### Flutter

- 使用 `dart format` 格式化代码
- 遵循 Effective Dart 指南

```bash
# 格式化
dart format .

# 分析
flutter analyze
```

## 测试

### Rust 测试

```bash
cd kayak-backend

# 运行所有测试
cargo test

# 运行特定测试
cargo test <test_name>

# 查看测试覆盖率
cargo tarpaulin
```

### Flutter 测试

```bash
cd kayak-frontend

# 运行所有测试
flutter test

# 运行特定测试
flutter test test/unit_test.dart

# 生成覆盖率报告
gen_coverage
```

## 数据库迁移

迁移文件位于 `kayak-backend/migrations/`。

迁移命名规范：`YYYYMMDDHHMMSS_description.sql`

创建新迁移：
```bash
# 创建迁移文件
touch kayak-backend/migrations/$(date +%Y%m%d%H%M%S)_new_feature.sql
```

## 添加新功能

### 1. 后端 API

1. 在 `src/models/` 添加数据模型
2. 在 `src/db/repository/` 添加数据仓库
3. 在 `src/services/` 添加业务服务
4. 在 `src/api/handlers/` 添加处理器
5. 在 `src/api/routes.rs` 注册路由

### 2. 前端 Feature

1. 在 `lib/features/` 创建功能目录
2. 添加 `models/` - 数据模型
3. 添加 `services/` - API 服务
4. 添加 `providers/` - Riverpod 状态管理
5. 添加 `screens/` - 页面
6. 添加 `widgets/` - 组件

### 3. 数据库迁移

创建新的 SQL 迁移文件。

## 调试

### 后端调试

```bash
# 启用调试日志
export KAYAK_LOG_LEVEL=debug

# 启用 Rust 回溯
export RUST_BACKTRACE=1

# 运行
cargo run
```

### 前端调试

```bash
# 启用调试模式
flutter run --debug

# Dart 观察模式
flutter run --observe
```

## 构建发布

### 后端发布

```bash
cd kayak-backend
cargo build --release
```

### 前端发布

```bash
cd kayak-frontend

# Web
flutter build web --release

# Linux桌面
flutter build linux --release

# Windows桌面
flutter build windows --release

# macOS桌面
flutter build macos --release
```

## Docker

### 构建镜像

```bash
# 单容器镜像
docker build -t kayak:single -f Dockerfile.single .

# 多容器镜像
docker-compose build
```

### 运行

```bash
# 单容器
docker run -d -p 8080:8080 kayak:single

# Docker Compose
docker-compose up -d
```

## 常见问题

### 编译错误

确保安装了正确版本的 Rust 和 Flutter：

```bash
rustc --version  # 应该 >= 1.75
flutter --version  # 应该 >= 3.16
```

### 数据库错误

删除数据库重新初始化：

```bash
rm kayak-backend/kayak.db
cargo run
```

### 前端依赖问题

```bash
cd kayak-frontend
flutter clean
flutter pub get
```
