# S1-003: SQLite数据库Schema设计 - 测试用例文档

**任务ID**: S1-003  
**任务名称**: SQLite数据库Schema设计  
**创建日期**: 2026-03-15  
**测试负责人**: QA Team  
**版本**: 1.0

---

## 1. 测试概述

### 1.1 测试目标
验证数据库Schema设计是否符合PRD要求，确保：
- 所有表结构通过sqlx migrate成功创建
- 表之间关系正确建立
- 字段类型、约束符合设计要求
- 每个表包含created_at和updated_at字段

### 1.2 测试范围
| 范围项 | 说明 |
|--------|------|
| **包含** | 用户表、工作台表、设备表、测点表、数据文件元信息表的Schema验证 |
| **包含** | sqlx迁移脚本验证 |
| **包含** | ER图文档完整性验证 |
| **不包含** | 业务逻辑测试（在后续API测试中进行） |
| **不包含** | 性能测试（在集成测试阶段进行） |

### 1.3 验收标准映射
| 验收标准 | 测试用例ID |
|----------|-----------|
| 1. 所有表结构通过sqlx migrate创建成功 | TC-S1-003-001 ~ TC-S1-003-003 |
| 2. 提供完整的ER图文档 | TC-S1-003-004 |
| 3. 每个表包含创建时间、更新时间字段 | TC-S1-003-005 |

---

## 2. 数据库Schema规范

### 2.1 表清单

| 序号 | 表名 | 中文名 | 说明 |
|------|------|--------|------|
| 1 | `users` | 用户表 | 存储用户基本信息 |
| 2 | `workbenches` | 工作台表 | 存储工作台配置 |
| 3 | `devices` | 设备表 | 存储设备信息，支持嵌套 |
| 4 | `points` | 测点表 | 存储设备测点定义 |
| 5 | `data_files` | 数据文件元信息表 | 存储HDF5文件元数据 |

### 2.2 字段命名规范
- 表名使用小写复数形式
- 字段名使用snake_case
- 主键统一使用`id` (TEXT类型，UUID格式)
- 外键格式：`{关联表名}_id`
- 时间戳字段：`created_at`, `updated_at`

### 2.3 字段类型规范
| Rust类型 | SQLite类型 | 说明 |
|----------|------------|------|
| String | TEXT | 字符串 |
| i64 | INTEGER | 整型 |
| f64 | REAL | 浮点型 |
| bool | INTEGER (0/1) | 布尔型 |
| DateTime | TEXT (ISO 8601) | 时间戳 |
| Enum | TEXT | 枚举类型 |
| UUID | TEXT | UUID字符串 |

---

## 3. 测试用例详情

### 3.1 迁移脚本测试

#### TC-S1-003-001: sqlx迁移工具安装验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-001 |
| **测试项** | sqlx-cli工具安装 |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 环境验证 |

**前置条件**
1. Rust开发环境已安装 (>= 1.75)
2. Cargo可用

**测试步骤**
```bash
# 1. 安装sqlx-cli工具
cargo install sqlx-cli --no-default-features --features native-tls,sqlite

# 2. 验证安装
sqlx --version

# 3. 检查数据库目录存在
ls -la kayak-backend/migrations/
```

**预期结果**
1. sqlx-cli安装成功，无报错
2. `sqlx --version` 返回版本号（如 0.7.x）
3. migrations目录存在且包含迁移文件

**通过标准**
- sqlx命令行工具可用
- 版本 >= 0.7.0

---

#### TC-S1-003-002: 数据库迁移执行验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-002 |
| **测试项** | 执行所有数据库迁移 |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 功能验证 |

**前置条件**
1. TC-S1-003-001 通过
2. 干净的数据库文件（或新创建）
3. 后端项目已克隆到本地

**测试步骤**
```bash
# 1. 进入后端目录
cd kayak-backend

# 2. 创建/初始化数据库
touch kayak.db
export DATABASE_URL="sqlite:kayak.db"

# 3. 执行迁移
sqlx migrate run

# 4. 验证迁移状态
sqlx migrate info

# 5. 检查数据库文件大小（确认数据写入）
ls -lh kayak.db
```

**预期结果**
1. `sqlx migrate run` 执行成功，无错误
2. `sqlx migrate info` 显示所有迁移已应用（Applied）
3. 数据库文件大小 > 0 bytes
4. 命令输出类似：
   ```
   Applied 20240315000001/create_users_table.sql (22.34ms)
   Applied 20240315000002/create_workbenches_table.sql (15.21ms)
   ...
   ```

**通过标准**
- 所有迁移脚本成功执行
- 数据库文件创建且有内容
- 无SQL语法错误

---

#### TC-S1-003-003: 迁移回滚验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-003 |
| **测试项** | 迁移回滚功能验证 |
| **优先级** | P1 - 重要 |
| **测试类型** | 功能验证 |

**前置条件**
1. TC-S1-003-002 通过
2. 数据库已应用所有迁移

**测试步骤**
```bash
# 1. 回滚最近一次迁移
sqlx migrate revert

# 2. 检查迁移状态
sqlx migrate info

# 3. 重新应用迁移
sqlx migrate run

# 4. 验证表结构恢复
sqlite3 kayak.db ".schema"
```

**预期结果**
1. `sqlx migrate revert` 成功执行
2. 被回滚的迁移标记为未应用
3. 重新应用后所有表恢复正常
4. 回滚后相关表被删除或结构恢复

**通过标准**
- 回滚操作成功
- 可以重新应用迁移
- 数据库状态一致性保持

---

### 3.2 表结构验证测试

#### TC-S1-003-004: 用户表(users)结构验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-004 |
| **测试项** | 用户表字段和约束验证 |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 结构验证 |

**前置条件**
1. TC-S1-003-002 通过
2. 数据库迁移已执行

**预期表结构**
```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,                    -- UUID主键
    email TEXT NOT NULL UNIQUE,             -- 邮箱，唯一
    password_hash TEXT NOT NULL,            -- bcrypt密码哈希
    username TEXT,                          -- 用户名
    avatar_url TEXT,                        -- 头像URL
    status TEXT DEFAULT 'active',           -- 状态: active, inactive, banned
    created_at TEXT NOT NULL,               -- 创建时间(ISO 8601)
    updated_at TEXT NOT NULL                -- 更新时间(ISO 8601)
);
```

**测试步骤**
```bash
# 1. 检查表是否存在
sqlite3 kayak.db "SELECT name FROM sqlite_master WHERE type='table' AND name='users';"

# 2. 查看表结构
sqlite3 kayak.db ".schema users"

# 3. 验证字段信息
sqlite3 kayak.db "PRAGMA table_info(users);"

# 4. 验证索引
sqlite3 kayak.db "PRAGMA index_list(users);"

# 5. 插入测试数据
sqlite3 kayak.db "INSERT INTO users (id, email, password_hash, username, created_at, updated_at) 
VALUES ('test-uuid-001', 'test@example.com', 'hashed_password', 'TestUser', 
        '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 6. 查询验证
sqlite3 kayak.db "SELECT * FROM users WHERE id='test-uuid-001';"

# 7. 清理测试数据
sqlite3 kayak.db "DELETE FROM users WHERE id='test-uuid-001';"
```

**验证清单**
| 检查项 | 期望 | 状态 |
|--------|------|------|
| 表存在 | users表存在 | ⬜ |
| 主键 | id字段为PRIMARY KEY | ⬜ |
| 必填字段 | email, password_hash, created_at, updated_at为NOT NULL | ⬜ |
| 唯一约束 | email字段有UNIQUE约束 | ⬜ |
| 默认值 | status字段默认值为'active' | ⬜ |
| 时间戳 | created_at和updated_at字段存在 | ⬜ |
| 数据插入 | 可以成功插入有效数据 | ⬜ |
| 重复邮箱 | 插入重复邮箱应报错 | ⬜ |
| 空邮箱 | 插入空邮箱应报错 | ⬜ |

**通过标准**
- 所有验证项通过
- 数据操作符合约束预期

---

#### TC-S1-003-005: 工作台表(workbenches)结构验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-005 |
| **测试项** | 工作台表字段和约束验证 |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 结构验证 |

**前置条件**
1. TC-S1-003-002 通过

**预期表结构**
```sql
CREATE TABLE workbenches (
    id TEXT PRIMARY KEY,                    -- UUID主键
    name TEXT NOT NULL,                     -- 工作台名称
    description TEXT,                       -- 描述
    owner_id TEXT NOT NULL,                 -- 所属用户ID
    owner_type TEXT DEFAULT 'user',         -- 所有者类型: user, team
    status TEXT DEFAULT 'active',           -- 状态: active, archived, deleted
    created_at TEXT NOT NULL,               -- 创建时间
    updated_at TEXT NOT NULL,               -- 更新时间
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 索引
CREATE INDEX idx_workbenches_owner ON workbenches(owner_id, owner_type);
```

**测试步骤**
```bash
# 1. 检查表结构
sqlite3 kayak.db ".schema workbenches"

# 2. 验证字段
sqlite3 kayak.db "PRAGMA table_info(workbenches);"

# 3. 验证外键约束
sqlite3 kayak.db "PRAGMA foreign_key_list(workbenches);"

# 4. 验证索引
sqlite3 kayak.db "PRAGMA index_list(workbenches);"

# 5. 外键功能测试
sqlite3 kayak.db "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
VALUES ('owner-001', 'owner@test.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

sqlite3 kayak.db "INSERT INTO workbenches (id, name, owner_id, created_at, updated_at) 
VALUES ('wb-001', 'Test Workbench', 'owner-001', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 6. 测试级联删除（删除用户后工作台是否删除）
sqlite3 kayak.db "DELETE FROM users WHERE id='owner-001';"
sqlite3 kayak.db "SELECT * FROM workbenches WHERE id='wb-001';"  -- 应无结果
```

**验证清单**
| 检查项 | 期望 | 状态 |
|--------|------|------|
| 表存在 | workbenches表存在 | ⬜ |
| 外键约束 | owner_id外键指向users(id) | ⬜ |
| 级联删除 | 用户删除时工作台级联删除 | ⬜ |
| 必填字段 | name, owner_id, created_at, updated_at为NOT NULL | ⬜ |
| 时间戳 | created_at和updated_at字段存在 | ⬜ |
| 索引 | owner_id和owner_type上有索引 | ⬜ |
| 无效外键 | 插入不存在的owner_id应报错 | ⬜ |

**通过标准**
- 所有验证项通过
- 外键约束工作正常
- 级联删除正确执行

---

#### TC-S1-003-006: 设备表(devices)结构验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-006 |
| **测试项** | 设备表字段和约束验证（含嵌套支持） |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 结构验证 |

**前置条件**
1. TC-S1-003-002 通过
2. TC-S1-003-005 通过

**预期表结构**
```sql
CREATE TABLE devices (
    id TEXT PRIMARY KEY,                    -- UUID主键
    workbench_id TEXT NOT NULL,             -- 所属工作台ID
    parent_id TEXT,                         -- 父设备ID（支持嵌套）
    name TEXT NOT NULL,                     -- 设备名称
    protocol_type TEXT NOT NULL,            -- 协议类型: Virtual, ModbusTCP, etc.
    protocol_params TEXT,                   -- 协议参数（JSON格式）
    address TEXT,                           -- 设备地址
    serial_number TEXT,                     -- SN码
    manufacturer TEXT,                      -- 制造商
    description TEXT,                       -- 描述
    status TEXT DEFAULT 'offline',          -- 状态: online, offline, error
    created_at TEXT NOT NULL,               -- 创建时间
    updated_at TEXT NOT NULL,               -- 更新时间
    FOREIGN KEY (workbench_id) REFERENCES workbenches(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES devices(id) ON DELETE CASCADE
);

-- 索引
CREATE INDEX idx_devices_workbench ON devices(workbench_id);
CREATE INDEX idx_devices_parent ON devices(parent_id);
```

**测试步骤**
```bash
# 1. 检查表结构
sqlite3 kayak.db ".schema devices"

# 2. 验证自引用外键（嵌套支持）
sqlite3 kayak.db "PRAGMA foreign_key_list(devices);"

# 3. 准备测试数据
sqlite3 kayak.db "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
VALUES ('user-dev', 'dev@test.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

sqlite3 kayak.db "INSERT INTO workbenches (id, name, owner_id, created_at, updated_at) 
VALUES ('wb-dev', 'Dev Workbench', 'user-dev', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 4. 创建设备层级结构
sqlite3 kayak.db "INSERT INTO devices (id, workbench_id, name, protocol_type, created_at, updated_at) 
VALUES ('dev-parent', 'wb-dev', 'Parent Device', 'Virtual', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

sqlite3 kayak.db "INSERT INTO devices (id, workbench_id, parent_id, name, protocol_type, created_at, updated_at) 
VALUES ('dev-child', 'wb-dev', 'dev-parent', 'Child Device', 'Virtual', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 5. 验证层级查询
sqlite3 kayak.db "SELECT d.*, p.name as parent_name 
FROM devices d 
LEFT JOIN devices p ON d.parent_id = p.id 
WHERE d.workbench_id='wb-dev';"

# 6. 测试级联删除
sqlite3 kayak.db "DELETE FROM workbenches WHERE id='wb-dev';"
sqlite3 kayak.db "SELECT * FROM devices WHERE workbench_id='wb-dev';"  -- 应无结果
```

**验证清单**
| 检查项 | 期望 | 状态 |
|--------|------|------|
| 表存在 | devices表存在 | ⬜ |
| 外键约束 | workbench_id外键指向workbenches(id) | ⬜ |
| 自引用外键 | parent_id可指向devices(id) | ⬜ |
| 嵌套支持 | 可以创建父子设备关系 | ⬜ |
| 级联删除 | 工作台删除时设备级联删除 | ⬜ |
| 时间戳 | created_at和updated_at字段存在 | ⬜ |
| 协议类型 | protocol_type字段存在 | ⬜ |

**通过标准**
- 所有验证项通过
- 嵌套结构支持正常
- 级联删除正确执行

---

#### TC-S1-003-007: 测点表(points)结构验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-007 |
| **测试项** | 测点表字段和约束验证 |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 结构验证 |

**前置条件**
1. TC-S1-003-002 通过
2. TC-S1-003-006 通过

**预期表结构**
```sql
CREATE TABLE points (
    id TEXT PRIMARY KEY,                    -- UUID主键
    device_id TEXT NOT NULL,                -- 所属设备ID
    name TEXT NOT NULL,                     -- 测点名称
    data_type TEXT NOT NULL,                -- 数据类型: Number, Integer, String, Boolean
    access_type TEXT NOT NULL,              -- 访问类型: RO, WO, RW
    unit TEXT,                              -- 单位
    description TEXT,                       -- 描述
    min_value REAL,                         -- 最小值（可选）
    max_value REAL,                         -- 最大值（可选）
    default_value TEXT,                     -- 默认值（JSON格式存储）
    status TEXT DEFAULT 'active',           -- 状态: active, inactive
    created_at TEXT NOT NULL,               -- 创建时间
    updated_at TEXT NOT NULL,               -- 更新时间
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
);

-- 索引
CREATE INDEX idx_points_device ON points(device_id);
```

**测试步骤**
```bash
# 1. 检查表结构
sqlite3 kayak.db ".schema points"

# 2. 验证字段和约束
sqlite3 kayak.db "PRAGMA table_info(points);"
sqlite3 kayak.db "PRAGMA foreign_key_list(points);"

# 3. 准备测试数据
sqlite3 kayak.db "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
VALUES ('user-pt', 'pt@test.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

sqlite3 kayak.db "INSERT INTO workbenches (id, name, owner_id, created_at, updated_at) 
VALUES ('wb-pt', 'Point Test WB', 'user-pt', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

sqlite3 kayak.db "INSERT INTO devices (id, workbench_id, name, protocol_type, created_at, updated_at) 
VALUES ('dev-pt', 'wb-pt', 'Test Device', 'Virtual', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 4. 创建各类测点
sqlite3 kayak.db "INSERT INTO points (id, device_id, name, data_type, access_type, unit, created_at, updated_at) 
VALUES ('pt-001', 'dev-pt', 'Temperature', 'Number', 'RO', '°C', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

sqlite3 kayak.db "INSERT INTO points (id, device_id, name, data_type, access_type, access_type, created_at, updated_at) 
VALUES ('pt-002', 'dev-pt', 'SetPoint', 'Number', 'RW', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 5. 验证不同access_type
sqlite3 kayak.db "SELECT * FROM points WHERE device_id='dev-pt';"

# 6. 验证级联删除
sqlite3 kayak.db "DELETE FROM devices WHERE id='dev-pt';"
sqlite3 kayak.db "SELECT * FROM points WHERE device_id='dev-pt';"  -- 应无结果
```

**验证清单**
| 检查项 | 期望 | 状态 |
|--------|------|------|
| 表存在 | points表存在 | ⬜ |
| 外键约束 | device_id外键指向devices(id) | ⬜ |
| 数据类型 | data_type字段枚举值正确 | ⬜ |
| 访问类型 | access_type支持RO/WO/RW | ⬜ |
| 级联删除 | 设备删除时测点级联删除 | ⬜ |
| 时间戳 | created_at和updated_at字段存在 | ⬜ |

**通过标准**
- 所有验证项通过
- 支持RO/WO/RW三种访问类型
- 级联删除正确执行

---

#### TC-S1-003-008: 数据文件元信息表(data_files)结构验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-008 |
| **测试项** | 数据文件元信息表字段和约束验证 |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 结构验证 |

**前置条件**
1. TC-S1-003-002 通过

**预期表结构**
```sql
CREATE TABLE data_files (
    id TEXT PRIMARY KEY,                    -- UUID主键
    file_path TEXT NOT NULL,                -- 文件路径
    file_hash TEXT NOT NULL,                -- 文件哈希（用于完整性校验）
    experiment_id TEXT,                     -- 关联试验ID（可选）
    source_type TEXT,                       -- 来源类型: experiment, analysis, import
    owner_type TEXT DEFAULT 'user',         -- 所有者类型: user, team
    owner_id TEXT NOT NULL,                 -- 所有者ID
    data_size_bytes INTEGER,                -- 文件大小（字节）
    record_count INTEGER,                   -- 记录数量
    status TEXT DEFAULT 'active',           -- 状态: active, archived, deleted
    created_at TEXT NOT NULL,               -- 创建时间
    updated_at TEXT NOT NULL,               -- 更新时间
    FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- 索引
CREATE INDEX idx_data_files_owner ON data_files(owner_id, owner_type);
CREATE INDEX idx_data_files_experiment ON data_files(experiment_id);
```

**测试步骤**
```bash
# 1. 检查表结构
sqlite3 kayak.db ".schema data_files"

# 2. 验证字段
sqlite3 kayak.db "PRAGMA table_info(data_files);"

# 3. 准备测试数据
sqlite3 kayak.db "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
VALUES ('user-df', 'df@test.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 4. 插入数据文件记录
sqlite3 kayak.db "INSERT INTO data_files (id, file_path, file_hash, owner_id, data_size_bytes, record_count, created_at, updated_at) 
VALUES ('df-001', '/data/exp_001.h5', 'sha256:abc123...', 'user-df', 1024000, 10000, '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 5. 验证查询
sqlite3 kayak.db "SELECT * FROM data_files WHERE owner_id='user-df';"

# 6. 测试status枚举
sqlite3 kayak.db "UPDATE data_files SET status='archived' WHERE id='df-001';"
sqlite3 kayak.db "SELECT status FROM data_files WHERE id='df-001';"  -- 应显示archived
```

**验证清单**
| 检查项 | 期望 | 状态 |
|--------|------|------|
| 表存在 | data_files表存在 | ⬜ |
| 必填字段 | file_path, file_hash, owner_id, created_at, updated_at为NOT NULL | ⬜ |
| 文件哈希 | file_hash字段存在 | ⬜ |
| 文件大小 | data_size_bytes字段为INTEGER | ⬜ |
| 来源类型 | source_type字段支持多值 | ⬜ |
| 时间戳 | created_at和updated_at字段存在 | ⬜ |

**通过标准**
- 所有验证项通过
- 元信息记录可正常创建和更新

---

### 3.3 时间戳字段验证

#### TC-S1-003-009: 所有表时间戳字段验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-009 |
| **测试项** | 验证所有表包含created_at和updated_at字段 |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 合规性验证 |

**前置条件**
1. TC-S1-003-002 通过
2. 所有表已创建

**测试步骤**
```bash
# 自动化验证脚本
cat > /tmp/verify_timestamps.sql << 'EOF'
-- 检查所有表的时间戳字段
SELECT 
    m.name as table_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM pragma_table_info(m.name) WHERE name = 'created_at'
    ) THEN 'YES' ELSE 'NO' END as has_created_at,
    CASE WHEN EXISTS (
        SELECT 1 FROM pragma_table_info(m.name) WHERE name = 'updated_at'
    ) THEN 'YES' ELSE 'NO' END as has_updated_at
FROM sqlite_master m
WHERE type = 'table'
AND name NOT LIKE 'sqlite_%'
AND name NOT LIKE '_sqlx_%'
ORDER BY m.name;
EOF

sqlite3 kayak.db < /tmp/verify_timestamps.sql
```

**预期结果**
| 表名 | created_at | updated_at |
|------|-----------|-----------|
| users | YES | YES |
| workbenches | YES | YES |
| devices | YES | YES |
| points | YES | YES |
| data_files | YES | YES |

**通过标准**
- 所有业务表都包含created_at和updated_at字段
- 两个字段类型为TEXT（存储ISO 8601格式）
- 字段为NOT NULL

---

#### TC-S1-003-010: 时间戳自动更新触发器验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-010 |
| **测试项** | 验证updated_at自动更新机制 |
| **优先级** | P1 - 重要 |
| **测试类型** | 功能验证 |

**前置条件**
1. TC-S1-003-009 通过
2. 触发器已创建

**预期触发器**
```sql
-- 每个表应该有类似的触发器
CREATE TRIGGER update_users_timestamp 
AFTER UPDATE ON users
BEGIN
    UPDATE users SET updated_at = datetime('now') WHERE id = NEW.id;
END;
```

**测试步骤**
```bash
# 1. 查看触发器列表
sqlite3 kayak.db "SELECT name, tbl_name FROM sqlite_master WHERE type='trigger';"

# 2. 测试触发器功能
sqlite3 kayak.db "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
VALUES ('trigger-test', 'trigger@test.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');"

# 记录更新时间
OLD_TIME=$(sqlite3 kayak.db "SELECT updated_at FROM users WHERE id='trigger-test';")
echo "Before update: $OLD_TIME"

# 等待1秒并更新
sleep 1
sqlite3 kayak.db "UPDATE users SET username='UpdatedName' WHERE id='trigger-test';"

# 检查更新时间是否变化
NEW_TIME=$(sqlite3 kayak.db "SELECT updated_at FROM users WHERE id='trigger-test';")
echo "After update: $NEW_TIME"

# 3. 比较时间戳
if [ "$OLD_TIME" != "$NEW_TIME" ]; then
    echo "✓ Trigger is working - updated_at changed"
else
    echo "✗ Trigger NOT working - updated_at unchanged"
fi
```

**通过标准**
- 所有表都有对应的update触发器
- 更新记录时updated_at自动更新
- 时间戳变化符合预期

---

### 3.4 ER图文档验证

#### TC-S1-003-011: ER图文档完整性验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-011 |
| **测试项** | 验证ER图文档的完整性和准确性 |
| **优先级** | P0 - 阻塞性 |
| **测试类型** | 文档验证 |

**前置条件**
1. ER图文档已创建

**预期文档位置**
```
kayak-backend/docs/
├── er-diagram.md          # ER图文档
├── er-diagram.png         # 图形化ER图（可选）
└── schema.sql             # 完整Schema SQL
```

**测试步骤**
```bash
# 1. 检查文档存在
ls -la kayak-backend/docs/er-diagram.md
ls -la kayak-backend/docs/schema.sql

# 2. 验证文档内容
cat kayak-backend/docs/er-diagram.md

# 3. 对比文档与实际Schema
# 提取文档中提到的表名
# 对比数据库中的实际表名
```

**ER图文档验证清单**
| 检查项 | 期望 | 状态 |
|--------|------|------|
| 文档存在 | er-diagram.md文件存在 | ⬜ |
| 完整Schema | schema.sql文件存在 | ⬜ |
| 所有表 | 文档包含全部5个表 | ⬜ |
| 表关系 | 文档正确描述表间关系 | ⬜ |
| 字段清单 | 每个表有完整字段列表 | ⬜ |
| 外键关系 | 外键约束正确标注 | ⬜ |
| 图形化 | 包含ER图可视化（可选） | ⬜ |

**通过标准**
- 文档完整且与实现一致
- 所有表和关系都有描述

---

### 3.5 约束和索引验证

#### TC-S1-003-012: 数据库约束完整性验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-012 |
| **测试项** | 验证所有约束（主键、外键、唯一、非空、检查） |
| **优先级** | P1 - 重要 |
| **测试类型** | 约束验证 |

**测试步骤**
```bash
# 自动化约束验证脚本
cat > /tmp/verify_constraints.sql << 'EOF'
-- 主键约束验证
SELECT 
    'PRIMARY KEY' as constraint_type,
    m.name as table_name,
    p.name as column_name
FROM sqlite_master m
JOIN pragma_table_info(m.name) p ON p.pk = 1
WHERE m.type = 'table'
AND m.name IN ('users', 'workbenches', 'devices', 'points', 'data_files')
ORDER BY m.name;

-- 外键约束验证
SELECT 
    'FOREIGN KEY' as constraint_type,
    m.name as table_name,
    p.*
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) p
WHERE m.type = 'table'
ORDER BY m.name, p.id;
EOF

sqlite3 kayak.db < /tmp/verify_constraints.sql
```

**预期约束**
| 表名 | 约束类型 | 字段 | 引用表 | 引用字段 | 级联 |
|------|---------|------|--------|---------|------|
| users | PK | id | - | - | - |
| users | UQ | email | - | - | - |
| workbenches | PK | id | - | - | - |
| workbenches | FK | owner_id | users | id | CASCADE |
| devices | PK | id | - | - | - |
| devices | FK | workbench_id | workbenches | id | CASCADE |
| devices | FK | parent_id | devices | id | CASCADE |
| points | PK | id | - | - | - |
| points | FK | device_id | devices | id | CASCADE |
| data_files | PK | id | - | - | - |
| data_files | FK | owner_id | users | id | - |

**通过标准**
- 所有表都有主键
- 外键约束正确配置
- 唯一约束生效

---

#### TC-S1-003-013: 索引性能验证

| 项目 | 内容 |
|------|------|
| **测试ID** | TC-S1-003-013 |
| **测试项** | 验证索引创建和性能 |
| **优先级** | P1 - 重要 |
| **测试类型** | 性能验证 |

**测试步骤**
```bash
# 1. 查看所有索引
sqlite3 kayak.db "SELECT sql FROM sqlite_master WHERE type='index';"

# 2. 验证索引使用情况
sqlite3 kayak.db "EXPLAIN QUERY PLAN SELECT * FROM workbenches WHERE owner_id='test';"

# 3. 性能对比测试（有索引 vs 无索引）
# 插入大量测试数据
sqlite3 kayak.db "
WITH RECURSIVE cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM cnt WHERE x < 1000
)
INSERT INTO users (id, email, password_hash, created_at, updated_at)
SELECT 
    'perf-' || x,
    'perf' || x || '@test.com',
    'hash',
    '2026-03-15T10:00:00Z',
    '2026-03-15T10:00:00Z'
FROM cnt;
"

# 4. 测试查询性能
time sqlite3 kayak.db "SELECT * FROM users WHERE email='perf500@test.com';"
```

**预期索引**
| 索引名 | 表名 | 字段 | 用途 |
|--------|------|------|------|
| idx_users_email | users | email | 登录查询 |
| idx_workbenches_owner | workbenches | owner_id, owner_type | 用户工作台列表 |
| idx_devices_workbench | devices | workbench_id | 工作台设备查询 |
| idx_devices_parent | devices | parent_id | 设备嵌套查询 |
| idx_points_device | points | device_id | 设备测点查询 |
| idx_data_files_owner | data_files | owner_id, owner_type | 用户文件列表 |
| idx_data_files_experiment | data_files | experiment_id | 试验文件查询 |

**通过标准**
- 所有预期索引存在
- 查询使用索引（通过EXPLAIN验证）
- 索引提升查询性能

---

## 4. 自动化测试脚本

### 4.1 完整验证脚本

创建自动化测试脚本 `test_schema.sh`：

```bash
#!/bin/bash
# S1-003 Database Schema Validation Script
# Created: 2026-03-15

set -e

# 配置
DB_URL="${DATABASE_URL:-sqlite:kayak.db}"
DB_FILE="${DB_URL#sqlite:}"
PASSED=0
FAILED=0

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_result="$3"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_cmd"; then
        echo -e "${GREEN}PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        ((FAILED++))
    fi
}

# 检查数据库存在
check_database() {
    if [ ! -f "$DB_FILE" ]; then
        echo -e "${RED}Error: Database file not found: $DB_FILE${NC}"
        exit 1
    fi
}

# 主测试流程
main() {
    echo "========================================"
    echo "S1-003 Database Schema Validation"
    echo "Date: 2026-03-15"
    echo "Database: $DB_FILE"
    echo "========================================"
    echo ""
    
    check_database
    
    # TC-S1-003-004: 用户表验证
    run_test "Users table exists" \
        "sqlite3 $DB_FILE \"SELECT 1 FROM sqlite_master WHERE type='table' AND name='users';\" | grep -q 1" \
        "1"
    
    run_test "Users table has id PK" \
        "sqlite3 $DB_FILE 'PRAGMA table_info(users);' | grep -q 'id.*1.*1'" \
        "0"
    
    run_test "Users table has email unique" \
        "sqlite3 $DB_FILE 'SELECT sql FROM sqlite_master WHERE type=\"index\" AND name LIKE \"%users%email%\";' | grep -q unique" \
        "0"
    
    run_test "Users table has timestamps" \
        "sqlite3 $DB_FILE 'PRAGMA table_info(users);' | grep -q 'created_at' && sqlite3 $DB_FILE 'PRAGMA table_info(users);' | grep -q 'updated_at'" \
        "0"
    
    # TC-S1-003-005: 工作台表验证
    run_test "Workbenches table exists" \
        "sqlite3 $DB_FILE \"SELECT 1 FROM sqlite_master WHERE type='table' AND name='workbenches';\" | grep -q 1" \
        "1"
    
    run_test "Workbenches has owner_id FK" \
        "sqlite3 $DB_FILE 'PRAGMA foreign_key_list(workbenches);' | grep -q 'owner_id'" \
        "0"
    
    # TC-S1-003-006: 设备表验证
    run_test "Devices table exists" \
        "sqlite3 $DB_FILE \"SELECT 1 FROM sqlite_master WHERE type='table' AND name='devices';\" | grep -q 1" \
        "1"
    
    run_test "Devices has parent_id (nested support)" \
        "sqlite3 $DB_FILE 'PRAGMA table_info(devices);' | grep -q 'parent_id'" \
        "0"
    
    run_test "Devices has protocol_type" \
        "sqlite3 $DB_FILE 'PRAGMA table_info(devices);' | grep -q 'protocol_type'" \
        "0"
    
    # TC-S1-003-007: 测点表验证
    run_test "Points table exists" \
        "sqlite3 $DB_FILE \"SELECT 1 FROM sqlite_master WHERE type='table' AND name='points';\" | grep -q 1" \
        "1"
    
    run_test "Points has data_type" \
        "sqlite3 $DB_FILE 'PRAGMA table_info(points);' | grep -q 'data_type'" \
        "0"
    
    run_test "Points has access_type" \
        "sqlite3 $DB_FILE 'PRAGMA table_info(points);' | grep -q 'access_type'" \
        "0"
    
    # TC-S1-003-008: 数据文件表验证
    run_test "Data_files table exists" \
        "sqlite3 $DB_FILE \"SELECT 1 FROM sqlite_master WHERE type='table' AND name='data_files';\" | grep -q 1" \
        "1"
    
    run_test "Data_files has file_hash" \
        "sqlite3 $DB_FILE 'PRAGMA table_info(data_files);' | grep -q 'file_hash'" \
        "0"
    
    # TC-S1-003-009: 时间戳验证
    run_test "All tables have created_at" \
        "for table in users workbenches devices points data_files; do sqlite3 $DB_FILE \"PRAGMA table_info(\$table);\" | grep -q 'created_at' || exit 1; done" \
        "0"
    
    run_test "All tables have updated_at" \
        "for table in users workbenches devices points data_files; do sqlite3 $DB_FILE \"PRAGMA table_info(\$table);\" | grep -q 'updated_at' || exit 1; done" \
        "0"
    
    # 数据操作测试
    echo ""
    echo "Running data operation tests..."
    
    # 插入测试数据
    sqlite3 $DB_FILE "DELETE FROM users WHERE id LIKE 'test%';" 2>/dev/null || true
    
    sqlite3 $DB_FILE "
    INSERT INTO users (id, email, password_hash, created_at, updated_at) 
    VALUES ('test-user-001', 'test001@example.com', 'bcrypt_hash_here', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z');
    " 2>/dev/null
    
    run_test "Can insert user data" \
        "sqlite3 $DB_FILE \"SELECT 1 FROM users WHERE id='test-user-001';\" | grep -q 1" \
        "1"
    
    # 清理
    sqlite3 $DB_FILE "DELETE FROM users WHERE id LIKE 'test%';" 2>/dev/null || true
    
    # 总结
    echo ""
    echo "========================================"
    echo "Test Summary:"
    echo -e "  ${GREEN}Passed: $PASSED${NC}"
    echo -e "  ${RED}Failed: $FAILED${NC}"
    echo "========================================"
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# 执行主函数
main "$@"
```

**使用方式**:
```bash
chmod +x test_schema.sh
./test_schema.sh
```

### 4.2 Rust集成测试代码

在 `kayak-backend/tests/schema_test.rs` 中创建：

```rust
//! Database Schema Validation Tests
//! 
//! Test ID: TC-S1-003
//! Created: 2026-03-15

use sqlx::{sqlite::SqlitePoolOptions, Pool, Sqlite};

/// Database schema validation test suite
#[cfg(test)]
mod schema_tests {
    use super::*;

    async fn setup_test_db() -> Pool<Sqlite> {
        // 使用内存数据库进行测试
        let pool = SqlitePoolOptions::new()
            .connect("sqlite::memory:")
            .await
            .expect("Failed to create test database");
        
        // 运行迁移
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .expect("Failed to run migrations");
        
        pool
    }

    #[tokio::test]
    async fn test_users_table_structure() {
        let pool = setup_test_db().await;
        
        // 验证表存在
        let row: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='users'"
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        
        assert_eq!(row.0, 1, "users table should exist");
        
        // 验证可以插入数据
        let result = sqlx::query(
            "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
             VALUES ('test-001', 'test@example.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await;
        
        assert!(result.is_ok(), "Should be able to insert user data");
        
        // 验证唯一约束
        let result = sqlx::query(
            "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
             VALUES ('test-002', 'test@example.com', 'hash2', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await;
        
        assert!(result.is_err(), "Should fail on duplicate email");
    }

    #[tokio::test]
    async fn test_workbenches_foreign_key() {
        let pool = setup_test_db().await;
        
        // 插入用户
        sqlx::query(
            "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
             VALUES ('owner-001', 'owner@test.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await
        .unwrap();
        
        // 验证外键约束
        let result = sqlx::query(
            "INSERT INTO workbenches (id, name, owner_id, created_at, updated_at) 
             VALUES ('wb-001', 'Test Workbench', 'non-existent', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await;
        
        assert!(result.is_err(), "Should fail on invalid owner_id");
        
        // 验证有效外键
        let result = sqlx::query(
            "INSERT INTO workbenches (id, name, owner_id, created_at, updated_at) 
             VALUES ('wb-002', 'Test Workbench', 'owner-001', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await;
        
        assert!(result.is_ok(), "Should succeed with valid owner_id");
    }

    #[tokio::test]
    async fn test_devices_nested_structure() {
        let pool = setup_test_db().await;
        
        // 设置基础数据
        sqlx::query(
            "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
             VALUES ('user-nest', 'nest@test.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await
        .unwrap();
        
        sqlx::query(
            "INSERT INTO workbenches (id, name, owner_id, created_at, updated_at) 
             VALUES ('wb-nest', 'Nested WB', 'user-nest', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await
        .unwrap();
        
        // 创建父设备
        sqlx::query(
            "INSERT INTO devices (id, workbench_id, name, protocol_type, created_at, updated_at) 
             VALUES ('dev-parent', 'wb-nest', 'Parent Device', 'Virtual', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await
        .unwrap();
        
        // 创建子设备
        let result = sqlx::query(
            "INSERT INTO devices (id, workbench_id, parent_id, name, protocol_type, created_at, updated_at) 
             VALUES ('dev-child', 'wb-nest', 'dev-parent', 'Child Device', 'Virtual', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(&pool)
        .await;
        
        assert!(result.is_ok(), "Should support nested devices");
    }

    #[tokio::test]
    async fn test_all_tables_have_timestamps() {
        let pool = setup_test_db().await;
        
        let tables = vec!["users", "workbenches", "devices", "points", "data_files"];
        
        for table in tables {
            let has_created: (i64,) = sqlx::query_as(&format!(
                "SELECT COUNT(*) FROM pragma_table_info('{}') WHERE name='created_at'",
                table
            ))
            .fetch_one(&pool)
            .await
            .unwrap();
            
            let has_updated: (i64,) = sqlx::query_as(&format!(
                "SELECT COUNT(*) FROM pragma_table_info('{}') WHERE name='updated_at'",
                table
            ))
            .fetch_one(&pool)
            .await
            .unwrap();
            
            assert_eq!(has_created.0, 1, "{} should have created_at", table);
            assert_eq!(has_updated.0, 1, "{} should have updated_at", table);
        }
    }

    #[tokio::test]
    async fn test_points_access_types() {
        let pool = setup_test_db().await;
        
        // 设置测试数据
        setup_device_hierarchy(&pool).await;
        
        // 测试不同access_type
        for access_type in ["RO", "WO", "RW"] {
            let result = sqlx::query(&format!(
                "INSERT INTO points (id, device_id, name, data_type, access_type, created_at, updated_at) 
                 VALUES ('pt-{0}', 'dev-test', 'Point {0}', 'Number', '{0}', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')",
                access_type
            ))
            .execute(&pool)
            .await;
            
            assert!(result.is_ok(), "Should support access_type: {}", access_type);
        }
    }

    async fn setup_device_hierarchy(pool: &Pool<Sqlite>) {
        sqlx::query(
            "INSERT INTO users (id, email, password_hash, created_at, updated_at) 
             VALUES ('user-pt', 'pt@test.com', 'hash', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(pool)
        .await
        .unwrap();
        
        sqlx::query(
            "INSERT INTO workbenches (id, name, owner_id, created_at, updated_at) 
             VALUES ('wb-pt', 'Points WB', 'user-pt', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(pool)
        .await
        .unwrap();
        
        sqlx::query(
            "INSERT INTO devices (id, workbench_id, name, protocol_type, created_at, updated_at) 
             VALUES ('dev-test', 'wb-pt', 'Test Device', 'Virtual', '2026-03-15T10:00:00Z', '2026-03-15T10:00:00Z')"
        )
        .execute(pool)
        .await
        .unwrap();
    }
}
```

---

## 5. 测试执行计划

### 5.1 测试环境要求

| 项目 | 要求 |
|------|------|
| **Rust版本** | >= 1.75 |
| **sqlx-cli** | >= 0.7.0 |
| **SQLite** | >= 3.35.0（支持RETURNING子句） |
| **测试数据库** | 内存数据库或临时文件 |

### 5.2 执行顺序

```
第一阶段：迁移验证
├── TC-S1-003-001: sqlx工具安装
├── TC-S1-003-002: 迁移执行
└── TC-S1-003-003: 迁移回滚

第二阶段：结构验证
├── TC-S1-003-004: 用户表
├── TC-S1-003-005: 工作台表
├── TC-S1-003-006: 设备表
├── TC-S1-003-007: 测点表
└── TC-S1-003-008: 数据文件表

第三阶段：合规性验证
├── TC-S1-003-009: 时间戳字段存在性
├── TC-S1-003-010: 时间戳自动更新
└── TC-S1-003-011: ER图文档

第四阶段：高级验证
├── TC-S1-003-012: 约束完整性
└── TC-S1-003-013: 索引性能
```

### 5.3 测试通过标准

| 标准 | 要求 |
|------|------|
| **P0测试** | 100%通过，无失败 |
| **P1测试** | 90%以上通过 |
| **所有表** | 必须包含created_at和updated_at |
| **外键约束** | 100%正确配置 |
| **文档** | ER图文档与实现一致 |

---

## 6. 缺陷跟踪模板

### 6.1 缺陷报告格式

```markdown
**缺陷ID**: BUG-S1-003-001
**关联测试**: TC-S1-003-004
**严重程度**: [Critical/High/Medium/Low]
**状态**: [New/In Progress/Fixed/Verified]

**描述**:
[缺陷的详细描述]

**复现步骤**:
1. [步骤1]
2. [步骤2]
3. [步骤3]

**预期结果**:
[应该发生什么]

**实际结果**:
[实际发生什么]

**环境信息**:
- OS: [操作系统]
- Rust版本: [版本号]
- sqlx版本: [版本号]
- SQLite版本: [版本号]

**附件**:
- [错误截图/日志文件]
```

---

## 7. 文档历史

| 版本 | 日期 | 修改人 | 修改说明 |
|------|------|--------|----------|
| 1.0 | 2026-03-15 | QA Team | 初始版本创建 |

---

## 8. 附录

### 8.1 参考文档

1. [PRD v1.0](/home/hzhou/workspace/kayak/log/release_0/prd.md)
2. [SQLx Documentation](https://docs.rs/sqlx/)
3. [SQLite Schema](https://www.sqlite.org/schematab.html)

### 8.2 常用命令

```bash
# 查看数据库结构
sqlite3 kayak.db ".schema"

# 查看表结构
sqlite3 kayak.db ".schema table_name"

# 查看表信息
sqlite3 kayak.db "PRAGMA table_info(table_name);"

# 查看外键
sqlite3 kayak.db "PRAGMA foreign_key_list(table_name);"

# 查看索引
sqlite3 kayak.db "PRAGMA index_list(table_name);"

# 导出完整Schema
sqlite3 kayak.db ".schema" > schema_dump.sql

# 运行迁移
sqlx migrate run

# 回滚迁移
sqlx migrate revert

# 检查迁移状态
sqlx migrate info
```

### 8.3 预期完整Schema SQL

```sql
-- 完整的数据库Schema（参考实现）
-- 由sqlx migrate生成

-- users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    username TEXT,
    avatar_url TEXT,
    status TEXT DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- workbenches table
CREATE TABLE workbenches (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    owner_id TEXT NOT NULL,
    owner_type TEXT DEFAULT 'user',
    status TEXT DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- devices table
CREATE TABLE devices (
    id TEXT PRIMARY KEY,
    workbench_id TEXT NOT NULL,
    parent_id TEXT,
    name TEXT NOT NULL,
    protocol_type TEXT NOT NULL,
    protocol_params TEXT,
    address TEXT,
    serial_number TEXT,
    manufacturer TEXT,
    description TEXT,
    status TEXT DEFAULT 'offline',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (workbench_id) REFERENCES workbenches(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES devices(id) ON DELETE CASCADE
);

-- points table
CREATE TABLE points (
    id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    name TEXT NOT NULL,
    data_type TEXT NOT NULL,
    access_type TEXT NOT NULL,
    unit TEXT,
    description TEXT,
    min_value REAL,
    max_value REAL,
    default_value TEXT,
    status TEXT DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
);

-- data_files table
CREATE TABLE data_files (
    id TEXT PRIMARY KEY,
    file_path TEXT NOT NULL,
    file_hash TEXT NOT NULL,
    experiment_id TEXT,
    source_type TEXT,
    owner_type TEXT DEFAULT 'user',
    owner_id TEXT NOT NULL,
    data_size_bytes INTEGER,
    record_count INTEGER,
    status TEXT DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_workbenches_owner ON workbenches(owner_id, owner_type);
CREATE INDEX idx_devices_workbench ON devices(workbench_id);
CREATE INDEX idx_devices_parent ON devices(parent_id);
CREATE INDEX idx_points_device ON points(device_id);
CREATE INDEX idx_data_files_owner ON data_files(owner_id, owner_type);
CREATE INDEX idx_data_files_experiment ON data_files(experiment_id);

-- Update triggers for timestamps
CREATE TRIGGER update_users_timestamp 
AFTER UPDATE ON users
BEGIN
    UPDATE users SET updated_at = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER update_workbenches_timestamp 
AFTER UPDATE ON workbenches
BEGIN
    UPDATE workbenches SET updated_at = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER update_devices_timestamp 
AFTER UPDATE ON devices
BEGIN
    UPDATE devices SET updated_at = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER update_points_timestamp 
AFTER UPDATE ON points
BEGIN
    UPDATE points SET updated_at = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER update_data_files_timestamp 
AFTER UPDATE ON data_files
BEGIN
    UPDATE data_files SET updated_at = datetime('now') WHERE id = NEW.id;
END;
```

---

**文档结束**
