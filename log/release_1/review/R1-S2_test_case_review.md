# R1-S2 测试用例审查报告

## 文档信息

| 项目 | 内容 |
|------|------|
| 审查人 | sw-tom |
| 审查日期 | 2026-05-03 |
| 审查范围 | R1-S2-004, R1-S2-005, R1-S2-011 测试用例 |
| 版本 | 1.0 |
| 状态 | 审查完成 |

---

## 审查概要

| 文档 | 用例数 | 结论 | 通过条件 |
|------|:---:|:---:|------|
| R1-S2-004 (协议列表+串口) | 34 | ⚠️ **需修改** | 先实现 API 端点，修正响应结构断言 |
| R1-S2-005 (连接测试) | 37 | ⚠️ **需修改** | 先实现端点，Modbus 用例标记为条件性执行 |
| R1-S2-011 (连接/断开管理) | 43 | ⚠️ **需修改** | 先扩展 DeviceService trait + 路由，Modbus 用例条件性执行 |

> **核心问题**: 三份测试用例的覆盖率和设计质量均属**优秀**，但三个被测 API 组均**尚未在 routes.rs 中注册路由**。测试用例可作为 TDD 的依据，但当前无法执行。

---

## 1. R1-S2-004 审查 — 协议列表与串口扫描 API (34 用例)

### 1.1 总体评价

用例设计**全面且高质量**，覆盖了正常路径、数据结构完整性、config_schema 验证、认证测试、错误处理、性能边界。**结构设计评分: 9/10**。

### 1.2 发现的问题

#### 🔴 阻塞级问题 (必须修复才能执行)

**ISSUE-004-1: API 端点未实现**
- `GET /api/v1/protocols` 和 `GET /api/v1/system/serial-ports` 在 `kayak-backend/src/api/routes.rs` 中**不存在**
- 相关 handler 也未创建（无 `protocols.rs`、`serial_ports.rs`）
- **影响**: PT-001~013, SP-001~010 → 全部 23 个核心用例**无法执行**
- **建议**: 在 `api/handlers/` 下创建 handler，在 `routes.rs` 中注册路由

**ISSUE-004-2: config_schema 格式与后端代码不一致**
- 测试期望的 config_schema 是**带元数据的 schema 格式**(type, label, description, required, default, values...)
- 实际后端配置是**简单 Rust struct** (`VirtualConfig`, `ModbusTcpConfig`, `ModbusRtuConfig`)，没有 schema 元层
- 测试文档 7.1 节假设了完整的 schema 结构，但后端没有对应的 schema 生成逻辑
- **影响**: PT-004~007（config_schema 完整性测试）→ 预期结果需与实现对齐
- **建议**: 需确认 sw-jerry 的设计意图——是返回 struct 的 JSON Schema 还是直接序列化 struct。如果是 schema 格式，需要新增 `ProtocolSchema` 类型并在 handler 中生成

**ISSUE-004-3: PT-008 响应结构断言与实际 ApiResponse 不一致**
- PT-008 预期: 根对象"仅包含 `code` 和 `data` 两个 key"
- 实际 `ApiResponse::success()` 包含: `code`, `message`, `data`, `timestamp` (4个字段)
- **建议**: 修改预期为"必须包含 `code` 和 `data`，可选包含 `message` 和 `timestamp`"

#### 🟡 高优先级问题

**ISSUE-004-4: modbus_rtu config_schema 缺少 connection_pool_size 预期**
- 测试期望 RTU `config_schema` 包含 `port, baud_rate, data_bits, stop_bits, parity, slave_id, timeout_ms`
- 但 Modbus RTU 不像 TCP 那样使用连接池，`connection_pool_size` 仅适用 TCP
- **确认**: 测试预期**正确**，RTU 不应有 connection_pool_size

**ISSUE-004-5: SP-004 路径格式正则不够全面**
- Linux 预期: `/dev/tty(USB|ACM|S)\d+`
- 遗漏: `/dev/ttyAMA0`, `/dev/ttyO0`(OMAP), `/dev/rfcomm0`(蓝牙串口), `/dev/pts/*`(伪终端)
- **建议**: 改为 `path 非空且以 /dev/ 或 COM 开头` 的宽泛断言，或在备注注明约束范围

**ISSUE-004-6: connection_pool_size 在后端未实现**
- 测试 PT-005 期望 `config_schema` 包含 `connection_pool_size`
- 后端 `ModbusTcpConfig` struct (tcp.rs:26-35) **不包含此字段**（只有 host, port, slave_id, timeout_ms）
- **影响**: PT-005 预期结果需去掉此字段，或后端需添加

#### 🟢 低优先级问题

**ISSUE-004-7: 测试 PT-012/PT-013 与 SP-008/SP-009 重复**
- 认证测试在同一文档中对两个端点分别写了一遍
- 如果认证中间件是统一的（RequireAuth），这属于重复覆盖
- **建议**: 保留（不同端点路径可能被路由排除），但可合并为参数化测试

**ISSUE-004-8: 性能阈值可能过严**
- PT-011: p95 < 100ms。首次查询需要加载协议定义，若从文件/数据库读取可能超过 100ms
- SP-010: p95 < 500ms。在 macOS 上枚举串口（IOKit 调用）可能需要 ≥500ms
- **建议**: 在 CI 环境中设置宽松阈值（≤500ms / ≤2000ms），开发环境可严格

### 1.3 前端兼容性验证

| 项目 | 测试要求 | 前端 model | 一致性 |
|------|---------|-----------|:---:|
| ProtocolInfo.id | String 非空 | `json['id'] as String` | ✅ |
| ProtocolInfo.name | String 非空 | fallback: `''` | ✅ |
| ProtocolInfo.description | String 非空 | fallback: `''` | ✅ |
| ProtocolInfo.config_schema | Map, 非 null | fallback: `{}` | ✅ |
| SerialPort.path | String 非空 | `json['path'] as String` | ✅ |
| SerialPort.description | String | fallback: `''` | ✅ |

### 1.4 补充建议

| 建议 | 说明 |
|------|------|
| 增加协议列表**空数组场景** | 如果后端支持动态协议注册，测试无协议时的空数组返回 |
| 增加 `config_schema` 深层嵌套场景 | 如 VirtualConfig 的 `fixed_value` 可能是嵌套 object |
| 增加 i18n 测试 | 中文 description 断言（BP-003 存在但仅测 UTF-8 编码，未测内容正确性） |

---

## 2. R1-S2-005 审查 — 设备连接测试 API (37 用例)

### 2.1 总体评价

用例设计**考虑周全**，覆盖了三种协议的连接成功/失败场景、错误处理、安全测试、边界测试。附录 A 发现的 `success` vs `connected` 字段不一致是重要的前端对齐问题。**结构设计评分: 8.5/10**。

### 2.2 发现的问题

#### 🔴 阻塞级问题

**ISSUE-005-1: API 端点未实现**
- `POST /api/v1/devices/{id}/test-connection` 在 `routes.rs` 中**不存在**
- `DeviceService` trait (service.rs:18-49) **不包含 test_connection 方法**
- **影响**: 全部 37 个用例 → **无法执行**

**ISSUE-005-2: Modbus TCP/RTU 驱动未集成到 DriverWrapper**
- `DriverWrapper` (wrapper.rs:23-32) 仅包含 `AnyDriver::Virtual` 变体
- `DriverFactory::create()` 对 ModbusTcp/ModbusRtu 返回 `ConfigError("Protocol ... not yet implemented")`
- 即使 TC-MTCP01 有模拟器运行，也无法创建驱动
- **影响**: TC-MTCP01~07 (7用例), TC-MRTU01~07 (7用例) → **无条件性执行**

**ISSUE-005-3: Virtual 设备仅在创建时注册到 DeviceManager**
- `DeviceServiceImpl::create_device` (service.rs:223-235) 仅当 `ProtocolType::Virtual` 时注册
- `test-connection` 需要通过 DeviceManager 获取驱动，Modbus 设备无驱动可用
- **影响**: 即使实现端点，Modbus 测试也无法执行

**ISSUE-005-4: 响应字段名与前端 model 不匹配** (⚠️ 高影响)
- API 返回: `data.connected` (bool) + `data.message` (成功) 或 `data.error` (失败)
- 前端 `ConnectionTestResult.fromJson`: 读取 `json['success']` (不是 `connected`) 和 `json['message']`
- 前端 model **没有** `connected` 字段，用的是 `success`
- **影响**: 即使测试通过，前端也无法正确解析响应
- **建议**: 统一为 `success`(bool) + `message`(string) + `latency_ms`(int)，或修改前端 model

#### 🟡 高优先级问题

**ISSUE-005-5: TC-V03 fixed_value 测试数据格式问题**
- 测试数据: `"fixed_value": { "Number": 42.0 }`（PointValue 枚举序列化格式）
- 但 VirtualConfig 使用 `config_schema` 中的 `fixedValue` 字段（裸 double）
- **点**: 前端 `VirtualConfig.fixedValue` 是 `double?`，devices 配置可能用 snake_case JSON (`fixed_value`)
- **影响**: TC-V03 和 TC-V02 的测试数据格式与前端 model 不一致
- **建议**: 明确 protocol_params 中使用 snake_case 还是前端 camelCase，并统一测试数据

**ISSUE-005-6: TC-ERR02 (超时边界) 预期结果未确定**
- 测试备注: "需与 sw-tom 确认行为后确定"
- **sw-tom 确认**: VirtualDriver.connect() 为**同步内存操作**，无视超时参数。对于 Virtual 设备传入 timeout_ms=0 应**仍然返回 connected=true**
- **建议**: 更新预期为 "HTTP 200, connected=true" 并注明此测试仅验证 Virtual 协议的超时无关性

**ISSUE-005-7: TC-V05 状态更新依赖不明确**
- 预期 "连接测试后设备 status 变为 online"
- 当前 `DeviceService` 的 `test_connection` 方法不存在，无法确认是否会更新设备状态
- `DeviceServiceImpl` 没有 `update_device_status` 相关的持久化逻辑
- **建议**: 明确 `test-connection` 是否需要更新数据库中的设备状态（PRD 建议为"测试不持久化状态"）

#### 🟢 低优先级问题

**ISSUE-005-8: TC-BND04 并发数过低**
- 仅 5 并发 → 无法有效暴露锁竞争问题
- **建议**: 提升到 20~50 并发以有意义地测试 RwLock 竞争

**ISSUE-005-9: 缺少 PUT/DELETE 方法测试**
- ER 测试覆盖了错误的 POST 方法，但未测试 PUT/DELETE
- **建议**: 补充 PUT 和 DELETE 请求的 405 测试

**ISSUE-005-10: 缺少 Websocket/流式场景**
- 连接测试过程中是否影响现有 WS 连接？未覆盖
- **建议**: 可选补充（优先级低）

### 2.3 前端兼容性验证

| 项目 | 测试要求 | 前端 model | 一致性 |
|------|---------|-----------|:---:|
| response.data.connected | bool | `json['success']` (bool) | **❌ 不一致** |
| response.data.message | string (成功) | `json['message']` | ✅ |
| response.data.error | string (失败) | 不读取 | ⚠️ 前端仅读 message |
| response.data.latency_ms | int | `json['latency_ms']` | ✅ |

### 2.4 补充建议

| 建议 | 说明 |
|------|------|
| 增加 **API 响应时间上限测试** | 类似 004 的 PT-011，对 test-connection 做响应时间上限断言 |
| 增加 **请求体配置覆盖后验证设备配置未被修改** | TC-MTCP02 说明覆盖不持久化，但未验证后续 GET device 返回的 protocol_params 未变 |
| 增加 **超长 host 名称测试** | 如 host="a"*1000，测试是否被拒绝而非 crash |

---

## 3. R1-S2-011 审查 — 设备连接/断开管理 API (43 用例)

### 3.1 总体评价

用例设计是**三份中最深入的**。协议行为差异表（1.3节）准确反映了源码行为，幂等性测试设计精细。**结构设计评分: 9/10**。

### 3.2 发现的问题

#### 🔴 阻塞级问题

**ISSUE-011-1: API 端点未实现**
- `POST /api/v1/devices/{id}/connect`, `POST /api/v1/devices/{id}/disconnect`, `GET /api/v1/devices/{id}/status` 
  在 `routes.rs` 中**均不存在**
- `DeviceService` trait **不包含 connect/disconnect/get_status 方法**
- **影响**: 全部 43 个用例 → **无法执行**

**ISSUE-011-2: DeviceManager 基础设施可用但 handler 层缺失**
- `DeviceManager` (manager.rs) 已实现 `register_device`, `get_device`, `connect_all`, `disconnect_all`
- `DriverLifecycle` trait 已定义 `connect(&mut self)`, `disconnect(&mut self)`, `is_connected(&self)`
- **缺的是**: 将 DeviceManager 暴露给 HTTP handler 的服务层
- **建议**: 
  1. 在 `DeviceService` trait 中添加 `connect_device`, `disconnect_device`, `get_device_status` 方法
  2. 在 `DeviceServiceImpl` 中实现（通过 `DeviceManager::get_device` 获取驱动锁，调用 connect/disconnect）
  3. 在 `routes.rs` 注册路由

**ISSUE-011-3: Modbus 驱动未集成** (同 005-2)
- 与 R1-S2-005 同样的问题：DriverWrapper 仅支持 Virtual
- Modbus 相关用例 (CON-02/03/06/07/08/09/10/11, DIS-02/03/06/07, STA-04/05/06/07, PRO-01~04 中的 Modbus 部分) → **无条件性执行**

**ISSUE-011-4: AlreadyConnected 如何映射到 HTTP 状态码未定义**
- ModbusTcp/ModbusRtu 的 connect 在已连接时返回 `DriverError::AlreadyConnected`
- 测试 CON-06/CON-07 预期: "返回错误（DriverError::AlreadyConnected）或后端将其转为 HTTP 409 Conflict"
- **未定义**: `AppError` 没有从 `DriverError` 的转换实现，需要决定映射规则
- **建议**: 
  - `AlreadyConnected` → HTTP 409 Conflict
  - `NotConnected` (disconnect 时) → HTTP 200（幂等）
  - `Timeout` → HTTP 504 Gateway Timeout
  - `IoError` → HTTP 502 Bad Gateway
  - `ConfigError` → HTTP 400 Bad Request

**ISSUE-011-5: DeviceServiceImpl 创建设备的 Modbus 注册缺失**
- `create_device` (service.rs:223-235): 仅 Virtual 设备自动注册到 DeviceManager
- Modbus 设备需要手动或自动注册，否则 connect/disconnect 时找不到驱动
- **影响**: CON-02/CON-03 即使驱动已集成也无法找到设备

#### 🟡 高优先级问题

**ISSUE-011-6: CON-08/CON-09 预期 HTTP 状态码不一致**
- CON-08 (连接不可达): 预期 "HTTP 非200（建议 503 或 502）"
- CON-09 (连接超时): 预期 "HTTP 非200（超时错误）"
- 建议统一为: 连接失败 → HTTP 200 + `{ connected: false, error: "..." }`（与 test-connection API 一致），或统一 502 Bad Gateway
- **需与 sw-jerry 确认设计意图**

**ISSUE-011-7: STA-04/STA-05 状态查询响应结构未明确**
- 测试 2.3 节定义 status API 仅返回 `{ status: "connected" | "disconnected" | "error" }`
- 但 STA-04 备注: "可选：响应体中包含错误原因描述"
- STA-05: "取决于实现是否暴露 Connecting 状态"
- **建议**: 
  - 明确 status 响应**仅包含 status 字段**（最小化设计）
  - 若需要详细错误，通过 GET device 获取完整设备信息
  - Modbus 的 `Connecting` 状态**不暴露给 API**，仅内部使用（连接通常很快完成）

**ISSUE-011-8: ERR-05 预期结果模糊**
- "HTTP 404 或 500（取决于后端如何处理缺失驱动）"
- 测试用例不应有"取决于"的预期
- **建议**: 明确为 "HTTP 404 Not Found" + message 包含 "not registered"
- 因为设备在数据库中存在但未注册到 DeviceManager → 相当于驱动不可用

#### 🟢 低优先级问题

**ISSUE-011-9: 缺少 connect 后进行数据读写的验证**
- 连接成功 + 状态=connected 不够 → 应有一个测试验证连接后可以读取测点数据
- **建议**: 增加 POST connect + GET /points/{id}/value 的组合测试

**ISSUE-011-10: 缺少设备 disconnect 后对其他设备影响的测试**
- 断开设备 A 是否会影响设备 B 的连接？未覆盖
- 当前实现中独立存储，不应影响，但值得一个测试

**ISSUE-011-11: RTU 虚拟串口测试环境描述不完整**
- 9.4 节使用 `socat` 创建虚拟串口，但未说明如何给 Modbus RTU 模拟器使用
- **建议**: 补充完整的 RTU 模拟器启动命令和虚拟串口配对流程

### 3.3 协议行为验证

测试文档 1.3 节的驱动行为对比表已通过源码验证：

| 行为 | VirtualDriver | ModbusTcpDriver | ModbusRtuDriver | 源码位置 |
|------|:---:|:---:|:---:|------|
| 重复连接 | 幂等 Ok | Err(AlreadyConnected) | Err(AlreadyConnected) | virtual.rs:189-193, tcp.rs:339-340, rtu.rs:731-732 |
| 断开未连接 | 幂等 Ok | 幂等 Ok | 幂等 Ok | virtual.rs:199-201, tcp.rs:371-375, rtu.rs:763-767 |
| Connecting状态 | ❌ | ✅ | ✅ | tcp.rs:343, rtu.rs:735 |
| Error状态 | ❌ | ✅ | ✅ | tcp.rs:352, rtu.rs:753 |

**✅ 全部正确**

### 3.4 补充建议

| 建议 | 说明 |
|------|------|
| 增加 **connect 等待超时** 测试 | 设备 connect 不能无限等待，需要有服务端超时保护 |
| 增加 **systemctl/sigkill 后的状态恢复** | 进程重启后 DeviceManager 清空，需重新注册设备 |
| 增加 **connect 失败后状态应为 error** 的验证 | 当前 CON-08 预期状态=error，但需验证后续可恢复 |

---

## 4. 跨文档问题

### 4.1 共享问题

| 问题 | 影响文档 | 严重性 |
|------|---------|:---:|
| Modbus 驱动未集成到 DriverWrapper | 005, 011 | 🔴 阻塞 |
| API 端点未在 routes.rs 注册 | 004, 005, 011 | 🔴 阻塞 |
| Virtual 设备创建时注册，Modbus 未注册 | 005, 011 | 🔴 阻塞 |
| ApiResponse timestamp 结构 | 004 | 🟡 |
| `connected` vs `success` 字段不一致 | 005 | 🟡 |

### 4.2 测试数据一致性

| 配置字段 | 004 (schema) | 005/011 (protocol_params) | 前端 model |
|------|:---:|:---:|:---:|
| snake_case / camelCase | snake_case | 不一致 | camelCase(前端) snake_case(JSON) |
| fixed_value | `fixedValue`(config_schema) | `fixed_value`(004 7.1) | `fixedValue`(Dart) `fixed_value`(Rust) |

### 4.3 模拟器依赖

R1-S2-005 和 R1-S2-011 的 Modbus 用例依赖模拟器 (R1-SIM-001/002)。**在模拟器和驱动集成完成前，所有 Modbus 相关用例标记为 `#[ignore]` 或条件性执行**。

---

## 5. 审查结论

### 5.1 文档质量评价

三份测试用例文档的**覆盖率、结构组织和测试思维**均属优秀：

- ✅ 覆盖正常路径、错误路径、边界条件、安全测试、并发测试
- ✅ 包含前后端对齐验证 (前端 model 兼容性)
- ✅ 测试数据完整 (用户、设备、环境)
- ✅ 优先级和风险标注清晰
- ✅ 提供了执行建议和依赖条件说明
- ⚠️ 少量预期结果不够确定 ("需与 sw-tom 确认")

### 5.2 修改要求

| 文档 | 结论 | 必须修改项 | 建议修改项 |
|------|:---:|------|------|
| **R1-S2-004** | ⚠️ 需修改 | ISSUE-004-1, -2, -3 (3项) | ISSUE-004-5, -6, -8 (3项) |
| **R1-S2-005** | ⚠️ 需修改 | ISSUE-005-1, -2, -3, -4 (4项) | ISSUE-005-5, -6, -7 (3项) |
| **R1-S2-011** | ⚠️ 需修改 | ISSUE-011-1, -2, -3, -4, -5 (5项) | ISSUE-011-6, -7, -8 (3项) |

### 5.3 推荐执行顺序

1. **Step 1 — 实现 API 端点 + DeviceService 扩展** (解除三种阻塞)
   - 实现 `GET /api/v1/protocols`
   - 实现 `GET /api/v1/system/serial-ports`
   - 实现 `POST /api/v1/devices/{id}/test-connection`
   - 实现 `POST /api/v1/devices/{id}/connect`
   - 实现 `POST /api/v1/devices/{id}/disconnect`
   - 实现 `GET /api/v1/devices/{id}/status`
   - 扩展 `DeviceService` trait

2. **Step 2 — 集成 Modbus 驱动** (解除 005/011 阻塞)
   - 将 ModbusTcpDriver/ModbusRtuDriver 加入 `DriverWrapper` 和 `AnyDriver`
   - 实现 `DriverFactory::create` 的 Modbus 分支
   - `create_device` 时自动注册 Modbus 设备

3. **Step 3 — 修正测试用例** (基于本文档的 ISSUE)
   - 修正响应结构断言
   - 统一字段名 (`connected`/`success`)
   - 明确模糊的预期结果

4. **Step 4 — 执行测试**
   - Phase 1: Virtual 协议用例（全部可立即执行）
   - Phase 2: 认证/错误用例（独立于协议）
   - Phase 3: Modbus 用例（需模拟器就绪）

---

**审查完成**
