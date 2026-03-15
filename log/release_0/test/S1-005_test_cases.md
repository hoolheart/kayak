# S1-005: 后端单元测试框架搭建 - 测试用例文档

**文档版本**: 1.0  
**创建日期**: 2026-03-15  
**最后更新**: 2026-03-15  
**测试负责人**: QA团队  
**关联任务**: S1-005 后端单元测试框架搭建

---

## 1. 文档概述

### 1.1 测试目标
本文档定义了后端单元测试框架搭建任务的所有测试用例，确保测试框架配置正确、测试覆盖率达标、辅助工具可用，以及所有Repository层的功能正常工作。

### 1.2 验收标准映射

| 验收标准 | 覆盖测试用例 |
|---------|-------------|
| 运行`cargo test`执行所有单元测试 | TC-001 ~ TC-005 |
| 测试覆盖率>80% | TC-COVER-001 ~ TC-COVER-003 |
| 提供测试辅助函数和mock工具 | TC-MOCK-001 ~ TC-MOCK-005, TC-FIXTURE-001 ~ TC-FIXTURE-004 |

---

## 2. 测试框架配置测试

### TC-001: Cargo Test基础配置验证
**优先级**: P0 (Critical)  
**测试类型**: 配置验证  
**执行方式**: 手动

#### 前置条件
- 项目代码已checkout到feature分支
- Rust环境已安装 (版本 >= 1.75)
- 位于项目根目录 `/home/hzhou/workspace/kayak/kayak-backend`

#### 测试步骤
1. 执行命令检查cargo test是否可用:
   ```bash
   cargo test --help
   ```
2. 执行测试编译验证:
   ```bash
   cargo test --no-run
   ```
3. 执行所有单元测试:
   ```bash
   cargo test
   ```

#### 预期结果
1. `cargo test --help` 显示帮助信息，无错误
2. `cargo test --no-run` 编译成功，无编译错误
3. `cargo test` 执行成功，显示测试运行统计信息

#### 通过标准
- 所有命令执行成功，返回码为0
- 测试框架配置正确

---

### TC-002: 测试依赖配置验证
**优先级**: P0 (Critical)  
**测试类型**: 配置验证  
**执行方式**: 自动

#### 前置条件
- Cargo.toml文件存在且配置正确

#### 测试步骤
1. 验证dev-dependencies配置:
   ```bash
   grep -A 5 "\[dev-dependencies\]" Cargo.toml
   ```
2. 验证测试依赖是否安装:
   ```bash
   cargo tree -d
   ```

#### 预期结果
1. Cargo.toml包含以下dev-dependencies:
   - tokio-test = "0.4"
   - reqwest (features: ["json"])
2. 依赖树显示测试依赖已正确解析

#### 通过标准
- 所有必需的测试依赖都已配置
- 依赖版本符合要求

---

### TC-003: 异步测试运行时验证
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 前置条件
- 测试框架已配置

#### 测试步骤
1. 创建临时异步测试:
   ```rust
   #[tokio::test]
   async fn test_async_runtime() {
       let result = tokio::time::timeout(
           Duration::from_secs(1),
           async { "success" }
       ).await;
       assert!(result.is_ok());
   }
   ```
2. 运行测试:
   ```bash
   cargo test test_async_runtime
   ```

#### 预期结果
- 异步测试成功执行
- 测试输出显示 `test test_async_runtime ... ok`

#### 通过标准
- Tokio异步运行时正确配置
- 异步测试可以正常执行

---

### TC-004: 测试模块隔离验证
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 前置条件
- 存在多个测试模块

#### 测试步骤
1. 运行特定模块的测试:
   ```bash
   cargo test user_repo::tests
   ```
2. 验证测试模块隔离:
   ```bash
   cargo test -- --test-threads=1
   ```

#### 预期结果
1. 可以单独运行特定模块的测试
2. 单线程模式下所有测试通过
3. 多线程模式下所有测试通过

#### 通过标准
- 测试模块正确隔离
- 无并发冲突

---

### TC-005: 测试编译优化配置验证
**优先级**: P2 (Medium)  
**测试类型**: 配置验证  
**执行方式**: 手动

#### 测试步骤
1. 检查Cargo.toml中的profile配置:
   ```bash
   grep -A 10 "\[profile.dev\]" Cargo.toml
   ```
2. 运行debug模式测试:
   ```bash
   cargo test
   ```

#### 预期结果
1. profile.dev配置包含:
   - opt-level = 0
   - debug = true
2. 测试在debug模式下编译并运行成功

#### 通过标准
- 开发配置优化测试编译速度
- 调试信息完整

---

## 3. 测试覆盖率验证测试

### TC-COVER-001: 覆盖率工具集成验证
**优先级**: P0 (Critical)  
**测试类型**: 配置验证  
**执行方式**: 手动

#### 前置条件
- 已安装tarpaulin或其他覆盖率工具:
  ```bash
  cargo install cargo-tarpaulin
  ```

#### 测试步骤
1. 验证覆盖率工具安装:
   ```bash
   cargo tarpaulin --version
   ```
2. 运行覆盖率测试:
   ```bash
   cargo tarpaulin --out Html --output-dir coverage
   ```

#### 预期结果
1. 显示tarpaulin版本信息
2. 生成覆盖率报告文件 `coverage/tarpaulin-report.html`

#### 通过标准
- 覆盖率工具正常工作
- 报告成功生成

---

### TC-COVER-002: 总体覆盖率验证
**优先级**: P0 (Critical)  
**测试类型**: 覆盖率验证  
**执行方式**: 自动

#### 测试步骤
1. 运行全量测试并生成覆盖率:
   ```bash
   cargo tarpaulin --ignore-tests --exclude-files '*/tests/*' --timeout 120
   ```
2. 解析覆盖率输出

#### 预期结果
- 覆盖率报告中显示总体覆盖率 >= 80%
- 输出示例:
  ```
  Coverage: 85.32%
  ```

#### 通过标准
- 总体代码覆盖率 >= 80%
- 核心业务模块覆盖率达到目标

---

### TC-COVER-003: 关键模块覆盖率验证
**优先级**: P1 (High)  **测试类型**: 覆盖率验证  
**执行方式**: 自动

#### 测试步骤
1. 生成详细覆盖率报告:
   ```bash
   cargo tarpaulin --ignore-tests --out Html --output-dir coverage
   ```
2. 检查各模块覆盖率:
   - `src/db/repository/` - Repository层
   - `src/core/error.rs` - 错误处理
   - `src/models/entities/` - 实体模型

#### 预期结果
| 模块 | 最低覆盖率 | 目标覆盖率 |
|-----|----------|----------|
| db/repository | 80% | 90% |
| core/error | 85% | 95% |
| models/entities | 75% | 85% |

#### 通过标准
- 所有关键模块达到最低覆盖率要求

---

## 4. Mock工具测试

### TC-MOCK-001: 数据库连接Mock验证
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 验证内存数据库测试工具:
   ```rust
   // tests/test_utils/mod.rs
   pub async fn create_test_db() -> DbPool {
       let db_id = Uuid::new_v4().to_string();
       init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
           .await
           .expect("Failed to create test database")
   }
   ```
2. 运行使用mock数据库的测试

#### 预期结果
- 每个测试获得独立的内存数据库
- 测试数据相互隔离
- 测试执行成功

#### 通过标准
- Mock数据库工具可用
- 测试数据完全隔离

---

### TC-MOCK-002: Repository Mock验证
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建Repository mock:
   ```rust
   #[cfg(test)]
   pub struct MockUserRepository {
       users: Arc<Mutex<Vec<User>>>,
   }
   
   #[cfg(test)]
   impl MockUserRepository {
       pub fn new() -> Self {
           Self {
               users: Arc::new(Mutex::new(Vec::new())),
           }
       }
   }
   ```
2. 使用mock进行服务层测试

#### 预期结果
- Mock Repository可以模拟数据库操作
- 服务层测试不依赖真实数据库

#### 通过标准
- Mock工具可用
- 支持CRUD操作模拟

---

### TC-MOCK-003: HTTP请求Mock验证
**优先级**: P2 (Medium)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 验证HTTP mock工具:
   ```rust
   use mockito::{mock, server_url};
   
   #[tokio::test]
   async fn test_http_mock() {
       let _m = mock("GET", "/test")
           .with_status(200)
           .with_body(r#"{"status": "ok"}"#)
           .create();
       
       let response = reqwest::get(&format!("{}/test", server_url()))
           .await
           .unwrap();
       assert_eq!(response.status(), 200);
   }
   ```

#### 预期结果
- HTTP mock可以拦截请求
- 返回预设的响应

#### 通过标准
- HTTP mock工具集成成功

---

### TC-MOCK-004: 时间Mock验证
**优先级**: P2 (Medium)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 验证时间mock:
   ```rust
   use chrono::{DateTime, Utc, TimeZone};
   
   #[test]
   fn test_time_mock() {
       let fixed_time = Utc.with_ymd_and_hms(2024, 1, 1, 0, 0, 0).unwrap();
       // 验证实体创建时间可以被控制和验证
   }
   ```

#### 预期结果
- 可以在测试中固定时间值
- 时间相关断言可重复

#### 通过标准
- 时间mock工具可用

---

### TC-MOCK-005: UUID Mock验证
**优先级**: P2 (Medium)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 验证UUID生成mock:
   ```rust
   #[test]
   fn test_uuid_mock() {
       let test_uuid = Uuid::parse_str("550e8400-e29b-41d4-a716-446655440000").unwrap();
       // 使用固定UUID进行测试
   }
   ```

#### 预期结果
- 可以在测试中使用预定义UUID
- UUID解析和生成正确

#### 通过标准
- UUID工具在测试中正常工作

---

## 5. Fixtures辅助函数测试

### TC-FIXTURE-001: 测试数据工厂验证
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 验证用户工厂函数:
   ```rust
   // tests/fixtures/users.rs
   pub fn create_test_user() -> User {
       User::new(
           "test@example.com".to_string(),
           "hashed_password".to_string(),
           Some("Test User".to_string()),
       )
   }
   ```
2. 使用工厂创建测试数据

#### 预期结果
- 工厂函数返回有效的测试数据
- 数据符合实体约束

#### 通过标准
- 数据工厂可用
- 生成的数据有效

---

### TC-FIXTURE-002: 数据库种子数据验证
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 验证种子数据加载:
   ```rust
   pub async fn seed_test_data(pool: &DbPool) -> TestData {
       let user = create_user(pool, "seed@example.com").await;
       let workbench = create_workbench(pool, user.id).await;
       TestData { user, workbench }
   }
   ```

#### 预期结果
- 种子数据正确插入数据库
- 关联数据完整性正确

#### 通过标准
- 种子数据加载成功
- 数据关系正确

---

### TC-FIXTURE-003: 测试数据库清理验证
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 验证清理函数:
   ```rust
   pub async fn cleanup_test_db(pool: &DbPool) {
       sqlx::query("DELETE FROM users").execute(pool).await.ok();
       sqlx::query("DELETE FROM workbenches").execute(pool).await.ok();
   }
   ```

#### 预期结果
- 测试数据被正确清理
- 不影响其他测试

#### 通过标准
- 清理函数可用
- 测试隔离性保证

---

### TC-FIXTURE-004: 测试配置加载验证
**优先级**: P2 (Medium)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 验证测试配置:
   ```rust
   pub fn load_test_config() -> AppConfig {
       AppConfig {
           database_url: "sqlite::memory:".to_string(),
           log_level: "debug".to_string(),
           // ...
       }
   }
   ```

#### 预期结果
- 测试配置正确加载
- 环境变量正确覆盖

#### 通过标准
- 配置加载成功

---

## 6. Repository层单元测试

### TC-REPO-USER-001: UserRepository - 创建用户
**优先级**: P0 (Critical)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 前置条件
- 数据库连接池可用
- users表已创建

#### 测试步骤
1. 创建UserRepository实例
2. 调用create方法:
   ```rust
   let req = CreateUserRequest {
       email: "test@example.com".to_string(),
       password_hash: "hash".to_string(),
       username: Some("Test".to_string()),
   };
   let user = repo.create(req).await.unwrap();
   ```
3. 验证返回结果

#### 预期结果
- 用户成功创建
- 返回的用户包含:
  - 有效的UUID
  - 正确的email
  - 自动生成的created_at/updated_at

#### 通过标准
- 创建成功
- 数据完整性正确

---

### TC-REPO-USER-002: UserRepository - 根据ID查找用户
**优先级**: P0 (Critical)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建测试用户
2. 调用find_by_id:
   ```rust
   let found = repo.find_by_id(user.id).await.unwrap();
   ```
3. 验证返回结果

#### 预期结果
- 找到用户时返回Some(User)
- 未找到时返回None
- 用户数据与创建时一致

#### 通过标准
- 查找逻辑正确
- 数据映射正确

---

### TC-REPO-USER-003: UserRepository - 根据邮箱查找用户
**优先级**: P0 (Critical)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建测试用户
2. 调用find_by_email:
   ```rust
   let found = repo.find_by_email("test@example.com").await.unwrap();
   ```

#### 预期结果
- 找到用户时返回Some(User)
- 未找到时返回None

#### 通过标准
- 邮箱查找功能正常

---

### TC-REPO-USER-004: UserRepository - 查找所有用户
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建多个测试用户
2. 调用find_all:
   ```rust
   let users = repo.find_all().await.unwrap();
   ```

#### 预期结果
- 返回所有用户列表
- 按created_at降序排列

#### 通过标准
- 列表查询正确
- 排序正确

---

### TC-REPO-USER-005: UserRepository - 更新用户
**优先级**: P0 (Critical)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建测试用户
2. 调用update:
   ```rust
   let req = UpdateUserRequest {
       username: Some("Updated".to_string()),
       ..Default::default()
   };
   let updated = repo.update(user.id, req).await.unwrap();
   ```

#### 预期结果
- 更新成功返回Some(User)
- 未找到用户返回None
- 更新字段正确修改

#### 通过标准
- 更新逻辑正确
- 部分更新支持

---

### TC-REPO-USER-006: UserRepository - 删除用户
**优先级**: P0 (Critical)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建测试用户
2. 调用delete:
   ```rust
   let deleted = repo.delete(user.id).await.unwrap();
   ```
3. 验证删除结果

#### 预期结果
- 返回影响的行数(1表示成功)
- 再次查找返回None

#### 通过标准
- 删除功能正常
- 数据正确移除

---

### TC-REPO-WB-001: WorkbenchRepository - CRUD完整流程
**优先级**: P0 (Critical)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建workbench
2. 查找by_id
3. 查找by_owner
4. 更新workbench
5. 删除workbench

#### 预期结果
- 完整CRUD流程成功
- 数据一致性保持

#### 通过标准
- 所有操作成功

---

### TC-REPO-DEV-001: DeviceRepository - 创建设备及关联查询
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建workbench
2. 创建设备(关联workbench)
3. 查询workbench下所有设备
4. 更新设备状态
5. 删除设备

#### 预期结果
- 设备创建成功
- 关联查询正确
- 级联操作正常

#### 通过标准
- 设备CRUD完整
- 关联关系正确

---

### TC-REPO-PT-001: PointRepository - 测点CRUD
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建设备
2. 创建测点(关联设备)
3. 查询设备下所有测点
4. 更新测点范围值
5. 删除测点

#### 预期结果
- 测点CRUD功能正常
- 数值范围限制正确

#### 通过标准
- 测点管理功能完整

---

### TC-REPO-DF-001: DataFileRepository - 数据文件管理
**优先级**: P1 (High)  
**测试类型**: 功能验证  
**执行方式**: 自动

#### 测试步骤
1. 创建数据文件记录
2. 按source_type查询
3. 更新文件状态
4. 归档操作
5. 删除操作

#### 预期结果
- 文件元数据管理正确
- 状态流转正确

#### 通过标准
- 数据文件管理完整

---

## 7. 测试执行汇总

### 7.1 测试环境要求

```bash
# Rust版本
rustc --version  # >= 1.75.0

# 覆盖率工具
cargo install cargo-tarpaulin

# 测试依赖
cargo fetch
```

### 7.2 测试执行命令

```bash
# 1. 运行所有测试
cargo test

# 2. 运行特定模块测试
cargo test user_repo::tests
cargo test workbench_repo::tests
cargo test device_repo::tests
cargo test point_repo::tests
cargo test data_file_repo::tests

# 3. 生成覆盖率报告
cargo tarpaulin --ignore-tests --out Html --output-dir coverage

# 4. 运行带输出的测试
cargo test -- --nocapture

# 5. 单线程运行
cargo test -- --test-threads=1
```

### 7.3 测试通过标准

| 检查项 | 标准 |
|-------|-----|
| 单元测试通过率 | 100% |
| 代码覆盖率 | >= 80% |
| 编译警告 | 0 |
| 测试执行时间 | < 60秒 |

---

## 8. 附录

### 8.1 测试文件组织结构

```
kayak-backend/
├── src/
│   └── ...
├── tests/
│   ├── fixtures/           # 测试数据工厂
│   │   ├── mod.rs
│   │   ├── users.rs
│   │   ├── workbenches.rs
│   │   ├── devices.rs
│   │   ├── points.rs
│   │   └── data_files.rs
│   ├── mocks/              # Mock实现
│   │   ├── mod.rs
│   │   ├── db_mock.rs
│   │   └── repo_mock.rs
│   ├── utils/              # 测试工具
│   │   ├── mod.rs
│   │   └── db_helper.rs
│   ├── integration/        # 集成测试
│   │   └── mod.rs
│   └── lib.rs
└── Cargo.toml
```

### 8.2 测试数据约定

1. **邮箱格式**: `test-{uuid}@example.com`
2. **密码哈希**: 使用固定测试值 `test_hash`
3. **UUID**: 使用 `Uuid::new_v4()` 或预定义测试UUID
4. **时间**: 使用 `Utc::now()` 或固定测试时间

### 8.3 相关文档

- [Cargo Test文档](https://doc.rust-lang.org/cargo/commands/cargo-test.html)
- [Tarpaulin文档](https://github.com/xd009642/tarpaulin)
- [Tokio测试](https://docs.rs/tokio-test/latest/tokio_test/)

---

## 9. 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|-----|------|---------|-----|
| 1.0 | 2026-03-15 | 初始版本创建 | QA团队 |

---

**文档结束**
