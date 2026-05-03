# R1-S2-012-A Modbus TCP 连接池测试用例

## 文档信息

| 项目 | 内容 |
|------|------|
| 任务编号 | R1-S2-012-A |
| 测试类型 | 单元测试 + 集成测试（需 modbus-simulator） |
| 测试范围 | Modbus TCP 连接池（初始化、获取/归还、并发读写、自动重建、耗尽行为） |
| 作者 | sw-mike (Software Test Engineer) |
| 日期 | 2026-05-03 |
| 版本 | 1.0 |
| 状态 | 待审查 |

---

## 目录

1. [测试概述](#1-测试概述)
2. [被测模块规格](#2-被测模块规格)
3. [连接池初始化测试 (INI)](#3-连接池初始化测试-ini)
4. [连接获取与归还测试 (ACQ)](#4-连接获取与归还测试-acq)
5. [并发读写测试 (CON)](#5-并发读写测试-con)
6. [连接断开后自动重建测试 (REC)](#6-连接断开后自动重建测试-rec)
7. [模拟器集成验证测试 (SIM)](#7-模拟器集成验证测试-sim)
8. [连接池耗尽行为测试 (EXH)](#8-连接池耗尽行为测试-exh)
9. [生命周期测试 (LCY)](#9-生命周期测试-lcy)
10. [边界与压力测试 (BDY)](#10-边界与压力测试-bdy)
11. [测试数据需求](#11-测试数据需求)
12. [测试环境](#12-测试环境)
13. [风险与假设](#13-风险与假设)
14. [测试用例汇总](#14-测试用例汇总)

---

## 1. 测试概述

### 1.1 测试目标

验证 Modbus TCP 连接池的正确性、线程安全性和容错能力，确保：

- 连接池可预建指定数量（N）的 TCP 连接
- 读写操作可从池中获取连接，用完后正确归还
- 多任务并发读写时池不产生竞态条件或死锁
- 断开的连接可被自动检测并重建
- 连接池与 `DriverLifecycle`（connect/disconnect）正确集成
- 连接池耗尽时有合理的等待或错误处理行为
- 与 modbus-simulator 实际 TCP 通信工作正常

### 1.2 当前现状

当前 `ModbusTcpDriver`（`kayak-backend/src/drivers/modbus/tcp.rs`）使用**单连接**模型：

- `stream: AsyncMutex<Option<TcpStream>>` — 仅存储一个 TCP 流
- `send_request()` 直接锁住 stream → 发送请求 → 接收响应 → 释放锁
- 所有读写串行化：`read_point_async` 通过 `send_request` 独占 stream

**连接池改造将**：

- 将 `Option<TcpStream>` 替换为 `ConnectionPool<Connection>` 结构
- `send_request()` 从池 acquire 连接 → 使用 → release
- 池管理连接的创建、健康检查、自动重建

### 1.3 连接池架构假设

| 属性 | 值 |
|------|------|
| 默认 pool_size | 4 |
| 连接复用策略 | 获取 → 使用 → 归还（check-out / check-in） |
| 并发等待策略 | 信号量（Semaphore）或 AsyncMutex + 条件变量，等不到则超时报错 |
| 健康检查 | 连接归还时或获取时检测断连（`WouldBlock`/`UnexpectedEof`/已标记 broken） |
| 自动重建 | 检测到断连后，在归还或获取时启动重建任务 |
| 池满行为 | 所有连接被占用时，新请求等待（with timeout）或返回 `PoolExhausted` 错误 |
| 池生命周期 | `connect()` → 创建 N 个连接并初始化池；`disconnect()` → 关闭所有连接并清空池 |

---

## 2. 被测模块规格

### 2.1 连接池配置

```json
{
  "host": "127.0.0.1",
  "port": 502,
  "slave_id": 1,
  "timeout_ms": 5000,
  "connection_pool_size": 4
}
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| connection_pool_size | u16 | 4 | 池中预建连接数 |
| host | String | "127.0.0.1" | Modbus 从站 IP |
| port | u16 | 502 | Modbus TCP 端口 |
| slave_id | u8 | 1 | 从站 ID |
| timeout_ms | u64 | 3000 | 操作超时 (ms) |
| connect_timeout_ms | u64 | 3000 | 连接超时 (ms) |

### 2.2 连接池预期 trait/结构

```rust
// 伪代码 - 预期设计方向
struct ConnectionPool {
    available: Arc<Semaphore>,           // 控制并发访问的令牌
    connections: Arc<Mutex<VecDeque<Connection>>>, // 空闲连接队列
    config: ModbusTcpConfig,            // 用于重建连接的配置
    max_size: usize,                     // 池最大容量
}

struct Connection {
    stream: TcpStream,                   // TCP 连接
    broken: AtomicBool,                  // 是否已标记为断开
}

impl ConnectionPool {
    fn new(config: &ModbusTcpConfig, size: usize) -> Self;
    async fn init_all(&self) -> Result<(), DriverError>;  // 初始化所有连接
    async fn acquire(&self) -> Result<PoolGuard, DriverError>;  // 获取连接
    async fn shrink_all(&self);  // 关闭所有连接
    fn available_count(&self) -> usize;  // 当前可用连接数
}

struct PoolGuard {
    conn: Connection,
    pool: Arc<ConnectionPool>,
}

impl Drop for PoolGuard {
    fn drop(&mut self) {
        // 归还连接到池（或标记 broken）
    }
}
```

### 2.3 ModbusTcpDriver 改造映射

| 改造前字段 | 改造后字段 |
|------------|------------|
| `stream: AsyncMutex<Option<TcpStream>>` | `pool: ConnectionPool` |
| `send_request()` 直接 lock stream | `send_request()` → `pool.acquire()` → 使用 → guard drop |

---

## 3. 连接池初始化测试 (INI)

### INI-01: 默认 pool_size 创建连接池

| 字段 | 内容 |
|------|------|
| **测试ID** | INI-01 |
| **优先级** | Critical |
| **测试类型** | 单元测试 |
| **前置条件** | 1. `ModbusTcpConfig::default()` 配置初始化<br>2. 未调用 `connect()` |
| **测试步骤** | 1. 创建 `ModbusTcpDriver::with_defaults()`<br>2. 检查连接池是否创建<br>3. 检查池大小是否为默认值 4<br>4. 检查 `available_count()` 为 0（尚未 init） |
| **预期结果** | 1. 连接池对象成功创建<br>2. 池配置 `max_size` = 4<br>3. 初始可用连接计数 = 0（需调用 `connect()` init）<br>4. 无 panic，无 unwrap 失败 |
| **测试数据** | 默认配置 (host=127.0.0.1, port=502, slave_id=1, timeout_ms=3000) |

### INI-02: 自定义 pool_size 创建连接池

| 字段 | 内容 |
|------|------|
| **测试ID** | INI-02 |
| **优先级** | Critical |
| **测试类型** | 单元测试 |
| **前置条件** | 自定义配置 `connection_pool_size=8` |
| **测试步骤** | 1. 创建 `ModbusTcpConfig` 含 `connection_pool_size=8`<br>2. 创建 driver<br>3. 检查池配置 `max_size` |
| **预期结果** | 1. 池 `max_size` = 8<br>2. 池未初始化时 0 个活跃连接 |
| **测试数据** | pool_size=8 |

### INI-03: pool_size=1 最小池

| 字段 | 内容 |
|------|------|
| **测试ID** | INI-03 |
| **优先级** | High |
| **测试类型** | 单元测试 |
| **前置条件** | `connection_pool_size=1` |
| **测试步骤** | 1. 创建 pool_size=1 的连接池<br>2. 调用 `connect()` (需模拟器运行)<br>3. 检查池状态 |
| **预期结果** | 1. 池成功创建 1 个连接<br>2. `available_count()` = 1<br>3. 行为等价于单连接模式但接口统一 |
| **测试数据** | pool_size=1, 连接 modbus-simulator |

### INI-04: pool_size=0 拒绝

| 字段 | 内容 |
|------|------|
| **测试ID** | INI-04 |
| **优先级** | High |
| **测试类型** | 单元测试 |
| **前置条件** | 传入 `connection_pool_size=0` |
| **测试步骤** | 1. 创建配置 `connection_pool_size=0`<br>2. 创建 driver<br>3. 调用 `connect()` |
| **预期结果** | 1. 应在配置验证阶段或 `connect()` 返回错误<br>2. 错误信息明确说明 pool_size 不能为 0<br>3. 不创建空连接池导致后续操作 panic |
| **测试数据** | pool_size=0 |

### INI-05: pool_size 上限验证

| 字段 | 内容 |
|------|------|
| **测试ID** | INI-05 |
| **优先级** | Medium |
| **测试类型** | 单元测试 |
| **前置条件** | 传入极大的 pool_size (如 65535) |
| **测试步骤** | 1. 创建配置 `connection_pool_size=65535`<br>2. 创建 driver<br>3. 调用 `connect()` |
| **预期结果** | 1. 应在配置验证或连接时返回错误<br>2. 不应尝试打开 65535 个 TCP 连接耗尽系统资源<br>3. 合理的上限值 (如 128 或 256) |
| **测试数据** | pool_size=65535 |

### INI-06: connect() 初始化所有 N 个连接

| 字段 | 内容 |
|------|------|
| **测试ID** | INI-06 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. modbus-simulator 在 127.0.0.1:502 运行中 |
| **测试步骤** | 1. 创建 driver (pool_size=4)<br>2. 调用 `connect()` <br>3. 检查返回 `Ok(())`<br>4. 检查 `available_count()`<br>5. 使用 `lsof -i :502` 或 ss 确认 TCP 连接数 |
| **预期结果** | 1. `connect()` 返回 `Ok(())`<br>2. `available_count()` = 4<br>3. 系统级别可见 4 个 TCP 连接 (ESTABLISHED 状态)<br>4. 所有连接的事务 ID 独立初始化 |
| **测试数据** | pool_size=4, modbus-simulator 运行中 |

### INI-07: connect() 时模拟器不可达

| 字段 | 内容 |
|------|------|
| **测试ID** | INI-07 |
| **优先级** | High |
| **测试类型** | 单元测试 |
| **前置条件** | modbus-simulator 未运行，port=15999 无服务 |
| **测试步骤** | 1. 创建 driver (host=127.0.0.1, port=15999, pool_size=4, timeout_ms=1000)<br>2. 调用 `connect()` |
| **预期结果** | 1. `connect()` 返回 `Err(DriverError)` — 第一个连接失败即整体失败<br>2. 状态变为 `Error`<br>3. 已创建的部分连接应被清理（不残留）<br>4. `available_count()` = 0 或 `is_connected()` = false |
| **测试数据** | pool_size=4, host=127.0.0.1:15999 (无服务) |

### INI-08: connect() 时部分连接失败

| 字段 | 内容 |
|------|------|
| **测试ID** | INI-08 |
| **优先级** | High |
| **测试类型** | 集成测试 |
| **前置条件** | 1. modbus-simulator 配置最大连接数有限（或使用 iptables rate limiting）<br>2. pool_size 超过模拟器可接受的最大连接数 |
| **测试步骤** | 1. 创建 pool_size=10 的 driver<br>2. 模拟器限制最大 5 个连接<br>3. 调用 `connect()` |
| **预期结果** | 1. `connect()` 返回 `Err(...)`<br>2. 已成功建立的连接被清理<br>3. 状态为 `Error`<br>4. 模拟器侧无残留半连接 |
| **测试数据** | pool_size=10, 模拟器限制 5 连接 |

---

## 4. 连接获取与归还测试 (ACQ)

### ACQ-01: acquire() 获取一个可用连接

| 字段 | 内容 |
|------|------|
| **测试ID** | ACQ-01 |
| **优先级** | Critical |
| **测试类型** | 单元测试 |
| **前置条件** | 1. pool_size=4<br>2. 池已初始化（`connect()` 完成）<br>3. `available_count()` = 4 |
| **测试步骤** | 1. 调用 `pool.acquire()`<br>2. 检查返回 `Ok(guard)`<br>3. 检查 `available_count()` 变为 3<br>4. 使用 guard 的连接执行一次 `send_request(ReadCoils)`<br>5. 释放 guard (drop)<br>6. 检查 `available_count()` 恢复为 4 |
| **预期结果** | 1. `acquire()` 成功返回 guard<br>2. 获取后可用数 -1<br>3. 归还后可用数 +1<br>4. guard 使用期间连接可用<br>5. 无死锁 |
| **测试数据** | pool_size=4, modbus-simulator 运行中 |

### ACQ-02: 连续 acquire 直到池耗尽

| 字段 | 内容 |
|------|------|
| **测试ID** | ACQ-02 |
| **优先级** | Critical |
| **测试类型** | 单元测试 |
| **前置条件** | 1. pool_size=3<br>2. 池已初始化 |
| **测试步骤** | 1. acquire 第 1 个 → 成功, available=2<br>2. acquire 第 2 个 → 成功, available=1<br>3. acquire 第 3 个 → 成功, available=0<br>4. drop 第 1 个 guard → available=1<br>5. acquire → 成功（重用归还的连接） |
| **预期结果** | 1. 前 3 次 acquire 均成功<br>2. 归还后可再次获取<br>3. available_count 正确反映空闲连接数 |
| **测试数据** | pool_size=3 |

### ACQ-03: 归还断开连接后标记 broken

| 字段 | 内容 |
|------|------|
| **测试ID** | ACQ-03 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟设备操作） |
| **前置条件** | 1. pool_size=4<br>2. 池已连接 modbus-simulator<br>3. 已 acquire 一个连接并成功使用 |
| **测试步骤** | 1. acquire 连接<br>2. 使用 tcpkill / 防火墙阻断该连接，或 kill 模拟器<br>3. 尝试通过该连接发送 Modbus 请求 → 预期失败<br>4. 连接应被标记为 broken<br>5. 归还（drop guard）时，broken 的连接不回到可用池<br>6. 检查 `available_count()` 应为 2（原3 - 1 broken） |
| **预期结果** | 1. 断开后请求失败（Timeout 或 IoError）<br>2. 连接被标记 broken<br>3. 归还时不放回空闲队列<br>4. `available_count()` 减少<br>5. 其他连接不受影响 |
| **测试数据** | pool_size=4, 模拟器运行中 |

### ACQ-04: PoolGuard 确保归还（Drop trait）

| 字段 | 内容 |
|------|------|
| **测试ID** | ACQ-04 |
| **优先级** | High |
| **测试类型** | 单元测试 |
| **前置条件** | 1. pool_size=2<br>2. 池已初始化 |
| **测试步骤** | 1. { acquire → guard1; acquire → guard2; available=0 }<br>2. 在 scope 内 panic 或 early return（模拟异常）<br>3. 验证 guard1 和 guard2 的 Drop 被调用<br>4. `available_count()` 应恢复为 2 |
| **预期结果** | 1. 即使发生 panic，guard 的 Drop 仍执行（unwind 过程）<br>2. 连接被正确归还<br>3. 不会出现连接泄漏 |
| **测试数据** | pool_size=2 |

### ACQ-05: guard 使用完后连接保持 ESTABLISHED

| 字段 | 内容 |
|------|------|
| **测试ID** | ACQ-05 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=2<br>2. 池已连接 |
| **测试步骤** | 1. acquire → 发送 FC03 读取请求 → 成功 → drop<br>2. 检查 TCP 连接状态（lsof 或 /proc）<br>3. 再次 acquire → 应复用同一连接<br>4. 再发送一次 FC01 请求 → 成功 |
| **预期结果** | 1. TCP 连接在归还后仍保持 ESTABLISHED<br>2. 再次获取到的是同一个连接<br>3. 连接可复用，无需重新 TCP 握手 |
| **测试数据** | pool_size=2, modbus-simulator 运行中 |

### ACQ-06: 归还顺序不影响复用

| 字段 | 内容 |
|------|------|
| **测试ID** | ACQ-06 |
| **优先级** | Medium |
| **测试类型** | 单元测试 |
| **前置条件** | 1. pool_size=3<br>2. 池已初始化 |
| **测试步骤** | 1. acquire A, acquire B, acquire C (available=0)<br>2. drop B → available=1<br>3. acquire D → 应获取到之前 B 归还的连接<br>4. drop A, drop C<br>5. D 使用该连接发请求 → 成功 |
| **预期结果** | 1. 归还顺序不影响可用性<br>2. 归还后立即可被其他请求获取<br>3. 数据正确性不受连接复用影响 |
| **测试数据** | pool_size=3 |

---

## 5. 并发读写测试 (CON)

### CON-01: 2 个并发任务同时读（pool_size=2）

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-01 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=2<br>2. driver 已连接 modbus-simulator<br>3. 已配置 2 个测点 (point_a=寄存器0, point_b=寄存器1) |
| **测试步骤** | 1. 使用 `tokio::join!` 并发运行 2 个 `read_point_async`<br>2. 验证两个结果都返回 `Ok(PointValue)`<br>3. 验证两个结果互不干扰<br>4. 池在并发操作期间无死锁 |
| **预期结果** | 1. 两个读取均成功<br>2. 各自返回对应测点的正确值<br>3. 无死锁或超时<br>4. 两个连接在并发期间同时被占用 |
| **测试数据** | pool_size=2, 模拟器 registers[0]=100, registers[1]=200 |

### CON-02: N+1 个并发任务（pool_size=N，超越池容量）

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-02 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. driver 已连接<br>3. 已配置 5 个测点 |
| **测试步骤** | 1. 同时发起 5 个 `read_point_async` 请求（> pool_size）<br>2. 使用 `tokio::join_all` 或 `try_join_all`<br>3. 观察执行顺序、超时、错误 |
| **预期结果** | 取决于实现选择：<br>**方案A（信号量等待）**: 前 4 个立即获取连接，第 5 个等待直到某个连接释放，然后执行 → 5 个均成功<br>**方案B（立即失败）**: 第 5 个返回 `PoolExhausted` 或 `DriverError::Busy` 错误<br>**要求**: 行为应明确文档化，不能静默 hang 或 panic |
| **测试数据** | pool_size=4, 5 并发读 |

### CON-03: 10 个并发任务（pool_size=4，激烈竞争）

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-03 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. 已配置 10 个不同地址的测点<br>3. driver 已连接模拟器 |
| **测试步骤** | 1. 发起 10 个并发 `read_point_async`<br>2. 等待所有任务完成<br>3. 检查所有结果<br>4. 验证事务 ID 不冲突 |
| **预期结果** | 1. 所有 10 个读取成功返回<br>2. 每个返回对应测点的值<br>3. 无事务 ID 串扰（每个连接的 transaction_id 独立）<br>4. 无死锁<br>5. 若使用信号量等待，允许有合理的排队等待 |
| **测试数据** | pool_size=4, 10 测点, 模拟器 64 寄存器 |

### CON-04: 并发读写混合操作

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-04 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. 已配置 2 个 RW 测点 (coil_0, register_0) |
| **测试步骤** | 1. 并发执行：Task A 读 coil_0, Task B 写 register_0=255, Task C 读 register_0, Task D 写 coil_0=true<br>2. 检查结果一致性 |
| **预期结果** | 1. 各操作的结果符合读写顺序的串行一致性<br>2. 无数据竞争（coil_0 最终 true, register_0 最终 255）<br>3. 无死锁<br>4. 连接正确获取/归还 |
| **测试数据** | pool_size=4, coil_0 可读写, register_0 可读写 |

### CON-05: 长时间并发压力测试

| 字段 | 内容 |
|------|------|
| **测试ID** | CON-05 |
| **优先级** | Medium |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. driver 已连接模拟器<br>3. 已配置 4 个测点 |
| **测试步骤** | 1. 启动 4 个 tokio task，每个循环 100 次读取/写入<br>2. 每个 task 之间有随机延迟（0-50ms）<br>3. 运行完毕后检查统计：<br>   - 总操作次数<br>   - 失败次数<br>   - 连接获取/归还计数是否平衡 |
| **预期结果** | 1. 所有操作成功（或可控失败）<br>2. 池不出现连接泄漏（`available_count` 最终 = pool_size）<br>3. 无 panics<br>4. 总 acquire ≈ 总 release |
| **测试数据** | pool_size=4, 4 task × 100 次操作 |

---

## 6. 连接断开后自动重建测试 (REC)

### REC-01: 单个连接断开后自动重建

| 字段 | 内容 |
|------|------|
| **测试ID** | REC-01 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=2<br>2. driver 已连接模拟器<br>3. 已 acquire 一个连接 (guard) |
| **测试步骤** | 1. 使用 iptables / pfctl 阻断 guard 所属连接（DROP 规则阻断特定 src port 到 502）<br>2. 或使用 `tcpkill` 断开该连接<br>3. 通过 guard 发送 Modbus 请求 → 应失败<br>4. guard 应表示连接已 broken<br>5. 归还 guard（pool 检测 broken = true，丢弃不归队）<br>6. 检查 `available_count()` — 应为 0（一个在用 + 一个 broken）<br>7. 池应自动（或在下次 acquire 时）重建一个新连接<br>8. 再次 acquire → 成功，`available_count()` = 1<br>9. 使用新连接发送请求 → 成功 |
| **预期结果** | 1. 断开的连接被检测到<br>2. 池标记该连接 broken 并丢弃<br>3. 新连接在后继 acquire 前或 acquire 时自动创建<br>4. 最终池恢复到 pool_size 个健康连接<br>5. 模拟器侧可见新 TCP 连接建立 |
| **测试数据** | pool_size=2, 模拟器运行中 |

### REC-02: 多个连接断开后全部重建

| 字段 | 内容 |
|------|------|
| **测试ID** | REC-02 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. driver 已连接模拟器<br>3. 已 acquire 所有 4 个连接 |
| **测试步骤** | 1. 依次对 4 个连接执行 tcpkill<br>2. 验证 4 个连接均被标记 broken<br>3. 归还所有 guard → available_count=0（全部 broken 被丢弃）<br>4. 池应启动重建逻辑<br>5. 等待片刻后 acquire → 应获取到新连接<br>6. 检查 `available_count()` 最终恢复为 4 |
| **预期结果** | 1. 所有 4 个连接被标记 broken<br>2. 池检测到 0 个健康连接<br>3. 自动重建 4 个新连接<br>4. 模拟器侧可见 4 个新 TCP 连接 |
| **测试数据** | pool_size=4, 模拟器运行中 |

### REC-03: 模拟器崩溃后所有连接自动重建

| 字段 | 内容 |
|------|------|
| **测试ID** | REC-03 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. driver 已连接模拟器<br>3. 所有连接 HEALTHY |
| **测试步骤** | 1. Kill 模拟器进程 (`kill -9 <simulator_pid>`)<br>2. 短暂等待后（让 TCP RST 到达）<br>3. 尝试 acquire + 发送请求 → 预期失败（连接已 RST）<br>4. 归还所有连接 → 池全 broken<br>5. 重启模拟器<br>6. 再次 acquire + 发送请求 |
| **预期结果** | 1. 模拟器 kill 后所有连接变 broken<br>2. 池在 acquire 时尝试重建连接<br>3. 若模拟器未重启，重建持续失败，最终返回超时错误<br>4. 模拟器重启后，重建成功，恢复通信 |
| **测试数据** | pool_size=4, 模拟器可重启 |

### REC-04: 连接在 use 中途断开，acquire 时自动替换

| 字段 | 内容 |
|------|------|
| **测试ID** | REC-04 |
| **优先级** | High |
| **测试类型** | 单元测试 (mock) |
| **前置条件** | 1. pool_size=1<br>2. 连接在池中但模拟器已重启 → 旧连接 RST |
| **测试步骤** | 1. acquire 时，池先检测连接健康（peek 或 try_read）<br>2. 发现连接断连 → 丢弃该连接并立即创建新连接<br>3. 返回新连接的 guard |
| **预期结果** | 1. 旧 broken 连接不返回给调用者<br>2. 调用者获取到新的健康连接<br>3. 连接重建对调用者透明<br>4. 重建延迟在可接受范围内 |
| **测试数据** | pool_size=1 |

### REC-05: 重建连接超限（池内全部 broken 且目标不可达）

| 字段 | 内容 |
|------|------|
| **测试ID** | REC-05 |
| **优先级** | Medium |
| **测试类型** | 单元测试 |
| **前置条件** | 1. pool_size=4<br>2. 池初始为空或全部 broken<br>3. 目标 host 不可达 |
| **测试步骤** | 1. 设置 connect 目标为不可达地址 (192.0.2.1:15999)<br>2. 尝试 acquire 或 connect 触发重建<br>3. 观察重试次数（应有限制，不能无限循环） |
| **预期结果** | 1. 重建失败后不无限循环重试<br>2. 返回合理的错误 `DriverError::PoolExhausted` 或 `Timeout`<br>3. 不耗尽 CPU（避免自旋）<br>4. 若有重试策略，上限应为常数（如 3 次） |
| **测试数据** | host=192.0.2.1 (TEST-NET-1), pool_size=4 |

### REC-06: 正在使用的连接不被重建逻辑影响

| 字段 | 内容 |
|------|------|
| **测试ID** | REC-06 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=2<br>2. 已 acquire 连接 A，连接 B 空闲 |
| **测试步骤** | 1. acquire A → 不归还（保持使用态）<br>2. 检测到连接 B 断连<br>3. 池重建 B（不影响 A）<br>4. A 仍可正常使用<br>5. 归还 A → available_count = 2 |
| **预期结果** | 1. 连接 A 不受重建 B 的影响<br>2. A 的事务 ID 和 TCP 流持续有效<br>3. 池正确区分 in-use 和 broken 连接<br>4. 无 use-after-free |
| **测试数据** | pool_size=2 |

---

## 7. 模拟器集成验证测试 (SIM)

### SIM-01: FC01 读取线圈（单连接模式）

| 字段 | 内容 |
|------|------|
| **测试ID** | SIM-01 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. modbus-simulator 在 127.0.0.1:502 运行<br>2. `--slave-id 1 --coils 1,0,1`<br>3. driver pool_size=1, slave_id=1 |
| **测试步骤** | 1. `connect()` → 成功<br>2. 配置 coil_0 测点 (address=0, FC01)<br>3. 调用 `read_point_async(coil_0)`<br>4. 检查返回值 |
| **预期结果** | 1. 返回 `PointValue::Boolean(true)` (coil[0]=1)<br>2. MBAP 帧正确：unit_id=1, tid 递增<br>3. 模拟器日志显示收到 FC01 请求 |
| **测试数据** | pool_size=1, 模拟器 coils=[1,0,1] |

### SIM-02: FC03 读取保持寄存器（池模式）

| 字段 | 内容 |
|------|------|
| **测试ID** | SIM-02 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. modbus-simulator: `--registers 100,200,300`<br>2. driver pool_size=4, slave_id=1 |
| **测试步骤** | 1. `connect()` → 成功<br>2. 配置 register_0(addr=0), register_1(addr=1), register_2(addr=2) 测点<br>3. 依次 (非并发) 读取三个寄存器<br>4. 验证返回值 |
| **预期结果** | 1. register_0 → Integer(100)<br>2. register_1 → Integer(200)<br>3. register_2 → Integer(300)<br>4. 三个请求可能使用不同池连接（顺序读取）<br>5. 每个响应的事务 ID 与请求一致 |
| **测试数据** | pool_size=4, 模拟器 registers=[100,200,300] |

### SIM-03: 并发从池中读取多个寄存器

| 字段 | 内容 |
|------|------|
| **测试ID** | SIM-03 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. modbus-simulator: `--registers 10,20,30,40,50,60,70,80`<br>2. driver pool_size=4<br>3. 配置 8 个测点 |
| **测试步骤** | 1. `connect()` → 成功<br>2. 使用 `try_join_all` 并发读取 8 个测点<br>3. 收集所有结果<br>4. 验证每个结果 |
| **预期结果** | 1. 8 个读取全部成功<br>2. 返回值正确映射 (register_n → Integer(...))<br>3. 无事务 ID 冲突（每个连接独立计数）<br>4. 无 TCP 帧串扰（粘包/拆包） |
| **测试数据** | pool_size=4, 8 测点, 模拟器 registers=[10..80] |

### SIM-04: FC05 写线圈 + FC01 读验证

| 字段 | 内容 |
|------|------|
| **测试ID** | SIM-04 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. modbus-simulator 运行<br>2. driver pool_size=2<br>3. 配置 coil_0 测点 (RW) |
| **测试步骤** | 1. connect → 成功<br>2. 读取 coil_0 → 获取初始值<br>3. 写入 coil_0 = true (FC05)<br>4. 再读取 coil_0 → 验证变为 true<br>5. 写入 coil_0 = false (FC05)<br>6. 再读取 coil_0 → 验证变为 false |
| **预期结果** | 1. 写操作返回 Ok<br>2. 读操作反映最新值<br>3. 写和读可能使用不同池连接<br>4. 模拟器 DataStore 正确更新 |
| **测试数据** | pool_size=2, coil_0 |

### SIM-05: FC06 写寄存器 + FC03 读验证

| 字段 | 内容 |
|------|------|
| **测试ID** | SIM-05 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. modbus-simulator: `--registers 0`<br>2. driver pool_size=3<br>3. 配置 register_0 测点 (RW) |
| **测试步骤** | 1. connect → 成功<br>2. 读取 register_0 → Integer(0)<br>3. 写入 register_0 = 65535 (FC06)<br>4. 读取 register_0 → Integer(65535)<br>5. 写入 register_0 = 42 (FC06)<br>6. 读取 register_0 → Integer(42) |
| **预期结果** | 1. 写操作成功<br>2. 读操作验证写入值<br>3. 池连接复用时正确维护协议状态 |
| **测试数据** | pool_size=3, register_0 |

### SIM-06: 事务 ID 跨连接隔离

| 字段 | 内容 |
|------|------|
| **测试ID** | SIM-06 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. driver pool_size=2<br>2. 模拟器 verbose 模式（观察事务 ID） |
| **测试步骤** | 1. 并发 2 个读取请求<br>2. 从模拟器日志检查每个请求的事务 ID<br>3. 验证两个请求的事务 ID 序列互不重叠 |
| **预期结果** | 1. 两个连接各有独立的 transaction_id 计数器<br>2. 模拟器日志显示不同连接收到各自独立递增的 tid<br>3. 无事务 ID 冲突导致响应解析错误 |
| **测试数据** | pool_size=2, 模拟器 verbose |

### SIM-07: PDU 异常响应正确处理

| 字段 | 内容 |
|------|------|
| **测试ID** | SIM-07 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. 模拟器运行<br>2. 配置一个测点地址超出模拟器范围 (如地址=1000) |
| **测试步骤** | 1. connect → 成功<br>2. 读取 address=1000 的寄存器<br>3. 检查返回错误 |
| **预期结果** | 1. 模拟器返回 Exception Response (IllegalDataAddress = 0x02)<br>2. driver 解析异常响应，返回 `ModbusError::IllegalDataAddress`<br>3. 连接不被标记 broken（异常是正常协议行为）<br>4. 连接回池，可复用 |
| **测试数据** | 测点地址 1000 (超出模拟器 64 寄存器范围) |

---

## 8. 连接池耗尽行为测试 (EXH)

### EXH-01: 等待可用连接（信号量模式）

| 字段 | 内容 |
|------|------|
| **测试ID** | EXH-01 |
| **优先级** | Critical |
| **测试类型** | 单元/集成测试 |
| **前置条件** | 1. pool_size=1<br>2. 池已初始化<br>3. 已 acquire 唯一连接并持有（不释放） |
| **测试步骤** | 1. acquire 第 1 个 → 成功，不释放<br>2. 启动第二个 task 尝试 acquire（设置长超时如 5s）<br>3. 2 秒后 release 第 1 个<br>4. 观察第 2 个 task |
| **预期结果** | **若实现信号量等待**: 第 2 个 task 在 release 后成功获取<br>**若实现立即返回**: 第 2 个 task 返回 `Busy` 或 `PoolExhausted` 错误<br>**若实现超时等待**: acquire 支持 timeout 参数，2 秒内获取成功 |
| **测试数据** | pool_size=1 |

### EXH-02: 池耗尽超时

| 字段 | 内容 |
|------|------|
| **测试ID** | EXH-02 |
| **优先级** | High |
| **测试类型** | 单元测试 |
| **前置条件** | 1. pool_size=1<br>2. 持有唯一连接不释放 |
| **测试步骤** | 1. acquire 第 2 个请求，timeout=1000ms<br>2. 不释放第 1 个<br>3. 等待超时 |
| **预期结果** | 1. acquire 在 timeout 后返回错误<br>2. 错误类型 `DriverError::Timeout` 或 `PoolExhausted`<br>3. 不 hang 永不休 |
| **测试数据** | pool_size=1, timeout=1000ms |

### EXH-03: 请求排队 FIFO 公平性

| 字段 | 内容 |
|------|------|
| **测试ID** | EXH-03 |
| **优先级** | Medium |
| **测试类型** | 单元测试 |
| **前置条件** | 1. pool_size=1<br>2. 持有唯一连接 |
| **测试步骤** | 1. 启动 task A (标记 A), task B (标记 B), task C (标记 C) 依次请求 acquire<br>2. 释放连接<br>3. 观察哪个 task 先获取到连接 |
| **预期结果** | 若使用 FIFO 信号量: A → B → C 依次获取<br>若使用 tokio Semaphore (FIFO): 公平获取 |
| **测试数据** | pool_size=1, 3 个排队 task |

---

## 9. 生命周期测试 (LCY)

### LCY-01: connect → disconnect → connect 循环

| 字段 | 内容 |
|------|------|
| **测试ID** | LCY-01 |
| **优先级** | Critical |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. 模拟器运行中 |
| **测试步骤** | 1. connect() → 成功, available=4<br>2. disconnect() → 成功, available=0 (所有连接关闭)<br>3. 验证 TCP 连接全部关闭 (lsof)<br>4. connect() → 成功, available=4<br>5. 再次断开 |
| **预期结果** | 1. connect 创建 N 个新连接<br>2. disconnect 关闭所有连接<br>3. 重复连接/断开操作稳定<br>4. 无资源泄漏（文件描述符正确释放）<br>5. 每次 connect 建立全新的 TCP 连接 |
| **测试数据** | pool_size=4 |

### LCY-02: 使用中断开（disconnect 强制回收所有连接）

| 字段 | 内容 |
|------|------|
| **测试ID** | LCY-02 |
| **优先级** | High |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. 已 acquire 2 个连接并保持使用中 |
| **测试步骤** | 1. acquire A 和 B → 保持不释放<br>2. 调用 disconnect()<br>3. 验证 A 和 B 的连接是否也关闭<br>4. 归还 A 和 B — 预期不应重新放回（池已销毁） |
| **预期结果** | 1. disconnect() 应关闭所有连接 (in-use + idle)<br>2. 或 disconnect() 标记池为 closed，归还时丢弃<br>3. A 和 B 后续使用应返回 `NotConnected` 错误<br>4. 不 panic，不 leave dangling connections |
| **测试数据** | pool_size=4, 2 in-use |

### LCY-03: 已连接状态再 connect

| 字段 | 内容 |
|------|------|
| **测试ID** | LCY-03 |
| **优先级** | High |
| **测试类型** | 单元测试 |
| **前置条件** | 1. driver 已 connect 成功 |
| **测试步骤** | 1. connect 成功后再次调用 connect() |
| **预期结果** | 1. 返回 `Err(DriverError::AlreadyConnected)` (与当前 tcp.rs 行为一致)<br>2. 不创建额外连接（不增加 TCP 连接数）<br>3. 已有连接保持可用 |
| **测试数据** | 任意 pool_size |

### LCY-04: 未连接时调用 acquire

| 字段 | 内容 |
|------|------|
| **测试ID** | LCY-04 |
| **优先级** | High |
| **测试类型** | 单元测试 |
| **前置条件** | 1. driver 未调用 connect()<br>2. 池已创建但未初始化 |
| **测试步骤** | 1. 不调用 connect()<br>2. 直接调用 `acquire()` 或 `read_point_async()` |
| **预期结果** | 1. 返回 `Err(DriverError::NotConnected)`<br>2. 与当前 tcp.rs 行为一致<br>3. 不 panic |
| **测试数据** | 任意 pool_size |

### LCY-05: disconnect 后归还的连接不保持

| 字段 | 内容 |
|------|------|
| **测试ID** | LCY-05 |
| **优先级** | Medium |
| **测试类型** | 单元测试 |
| **前置条件** | 1. pool_size=2<br>2. connect 成功<br>3. acquire 一个连接 → 持有 |
| **测试步骤** | 1. disconnect()<br>2. 归还持有的 guard<br>3. 检查状态 |
| **预期结果** | 1. 归还的连接不上池（池已 closed）<br>2. 连接被关闭<br>3. 池的 `available_count` 保持 0<br>4. 后续 acquire 返回 `NotConnected` 或 `Disconnected` |
| **测试数据** | pool_size=2 |

---

## 10. 边界与压力测试 (BDY)

### BDY-01: pool_size=1 的并发安全性

| 字段 | 内容 |
|------|------|
| **测试ID** | BDY-01 |
| **优先级** | High |
| **测试类型** | 单元/集成测试 |
| **前置条件** | 1. pool_size=1<br>2. 模拟器运行中 |
| **测试步骤** | 1. 顺序执行 1000 次 acquire → read → release<br>2. 验证每次操作成功<br>3. 检查最终 available_count = 1 |
| **预期结果** | 1. 1000 次操作全部成功<br>2. 连接未断开（正常 TCP keepalive）<br>3. 无 Semaphore 计数错误（available_count 不溢出）<br>4. 事务 ID 正确回绕 (wrapping_add) |
| **测试数据** | pool_size=1, 1000 次顺序操作 |

### BDY-02: 极短超时下的池行为

| 字段 | 内容 |
|------|------|
| **测试ID** | BDY-02 |
| **优先级** | Medium |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=4<br>2. timeout_ms=50 (极短)<br>3. 模拟器运行中（正常延迟） |
| **测试步骤** | 1. connect → 成功<br>2. 连续发送 20 个 FC03 请求 |
| **预期结果** | 1. 部分请求可能超时<br>2. 超时请求不应标记连接为 broken（超时 ≠ 断连）<br>3. 池不应因超时而不断丢弃连接<br>4. 连接保持 ESTABLISHED，后续请求可能成功 |
| **测试数据** | timeout_ms=50, 20 次读 |

### BDY-03: 写操作失败后连接状态

| 字段 | 内容 |
|------|------|
| **测试ID** | BDY-03 |
| **优先级** | Medium |
| **测试类型** | 集成测试（需模拟器） |
| **前置条件** | 1. pool_size=2<br>2. 模拟器运行中<br>3. 写只读测点（如 DiscreteInput） |
| **测试步骤** | 1. 尝试写入 DiscreteInput 测点<br>2. 检查返回错误<br>3. 检查连接是否仍可用（用它读取 coil） |
| **预期结果** | 1. 写入返回 `DriverError::ReadOnlyPoint`<br>2. 连接保持 HEALTHY<br>3. 连接归还池后可用于其他操作<br>4. 写操作失败不标记连接 broken（除非是 IO 错误） |
| **测试数据** | DiscreteInput 测点 |

### BDY-04: 池大小可运行时动态查询

| 字段 | 内容 |
|------|------|
| **测试ID** | BDY-04 |
| **优先级** | Low |
| **测试类型** | 单元测试 |
| **前置条件** | 已创建池 |
| **测试步骤** | 1. 调用 `pool.max_size()` 或 `pool.config().pool_size`<br>2. 调用 `pool.available_count()` |
| **预期结果** | 1. `max_size` 返回配置的 pool_size<br>2. `available_count` 返回当前空闲连接数<br>3. 接口提供监控 API（便于测试和运维） |
| **测试数据** | pool_size=4 |

### BDY-05: 跨 task 移动 guard（Send 约束）

| 字段 | 内容 |
|------|------|
| **测试ID** | BDY-05 |
| **优先级** | Medium |
| **测试类型** | 编译检查 |
| **前置条件** | 编译器 checks |
| **测试步骤** | 1. 在 tokio::spawn 内 acquire → 使用 → drop<br>2. 编译确认 PoolGuard 实现 Send<br>3. 在另一个 task 内使用 |
| **预期结果** | 1. 编译通过<br>2. PoolGuard 实现 Send<br>3. 可在不同 task 间传递（tokio 多线程调度器） |
| **测试数据** | 编译验证 |

### BDY-06: 连接建立时间的并行优化

| 字段 | 内容 |
|------|------|
| **测试ID** | BDY-06 |
| **优先级** | Low |
| **测试类型** | 性能测试（需模拟器） |
| **前置条件** | 1. pool_size=8<br>2. 模拟器运行中 |
| **测试步骤** | 1. 测量 connect() 耗时<br>2. 验证连接是并行建立还是串行建立 |
| **预期结果** | 1. 连接应并行建立（使用 join_all 或 spawn）<br>2. connect() 总耗时 ≈ max(单个连接耗时) 而非 sum<br>3. 串行建立 8 个连接不应超过 8×timeout |
| **测试数据** | pool_size=8 |

---

## 11. 测试数据需求

### 11.1 测试设备

| 序号 | 用途 | 配置 |
|:---:|------|------|
| 1 | 正常连接池功能测试 | host=127.0.0.1, port=502, slave_id=1, pool_size=4, timeout_ms=3000 |
| 2 | 最小池测试 | host=127.0.0.1, port=502, slave_id=1, pool_size=1, timeout_ms=3000 |
| 3 | 大池测试 | host=127.0.0.1, port=502, slave_id=1, pool_size=16, timeout_ms=3000 |
| 4 | 不可达目标 | host=192.0.2.1, port=15999, pool_size=4, timeout_ms=1000 |
| 5 | 极短超时 | host=127.0.0.1, port=502, slave_id=1, pool_size=4, timeout_ms=50 |

### 11.2 模拟设备

| 协议 | 启动命令 | 端口 | 数据 |
|------|------|------|------|
| Modbus TCP | `cargo run --bin modbus-simulator` | 502 | 默认 64 coils + 64 registers |
| Modbus TCP (custom) | `cargo run --bin modbus-simulator -- --port 1502 --coils 1,0,1,0 --registers 100,200,300` | 1502 | 4 coils + 3 registers |

### 11.3 TCP 连接监控命令

```bash
# 查看 502 端口 TCP 连接数（macOS）
lsof -i :502

# 查看 TCP 连接数（Linux）
ss -tn sport = :502 or dport = :502

# 模拟丢弃特定连接（macOS）
sudo pfctl -e
echo "block drop proto tcp from any to any port 502" | sudo pfctl -f -
```

---

## 12. 测试环境

### 12.1 软件要求

| 软件 | 版本 | 说明 |
|------|------|------|
| Rust | 1.80+ | 编译后端和驱动 |
| tokio | 1.x (项目依赖) | 异步运行时 |
| modbus-simulator | 项目内置 | Modbus TCP 从站模拟器 |
| lsof | 任意 | TCP 连接监控 (macOS) |
| ss | 任意 | TCP 连接监控 (Linux) |

### 12.2 环境变量

```bash
# 无特定环境变量需求
# 设置日志级别便于调试
export RUST_LOG=debug
```

### 12.3 测试启动顺序

1. 编译项目: `cargo build --bin modbus-simulator`
2. 启动模拟器: `cargo run --bin modbus-simulator` (或带自定义参数)
3. 等待模拟器就绪 (检查端口 502 LISTEN)
4. 运行单元测试: `cargo test drivers::modbus::tcp::`
5. 运行集成测试: `cargo test integration::modbus::` (若存在)

---

## 13. 风险与假设

### 13.1 假设

| 假设ID | 内容 | 影响测试 |
|:---:|------|------|
| A1 | 连接池作为 `ModbusTcpDriver` 内部字段实现 | 所有测试基于此假设 |
| A2 | 使用 tokio `Semaphore` + `Mutex<VecDeque<Connection>>` 模式 | 并发测试设计依赖 |
| A3 | PoolGuard 实现 `Drop` 自动归还连接 | ACQ-04 依赖此行为 |
| A4 | 断连检测通过 `tokio::io::ReadHalf::try_read` 或写操作错误实现 | REC-01~06 依赖 |
| A5 | modbus-simulator 可独立运行，端口 502 默认 | SIM-01~07 依赖 |
| A6 | 连接池的 connect() 行为向后兼容 DriverLifecycle trait | LCY-01~05 依赖 |
| A7 | `connection_pool_size` 已在 `ModbusTcpConfig` 中添加为可选字段 | 所有 INI 测试 |

### 13.2 风险

| 风险ID | 内容 | 严重性 | 缓解措施 |
|:---:|------|:---:|------|
| R1 | 池实现导致 tokio 任务死锁（Semaphore 饥饿） | High | CON-03 长时间并发测试可暴露 |
| R2 | tcpkill/pfctl 需要 root 权限，CI 环境无法执行断连测试 | Medium | REC 测试提供 mock 方案替代；CI 中标记 skip |
| R3 | modbus-simulator 的 TCP backlog 有限，大 pool_size 可能拒绝连接 | Medium | 测试使用合理 pool_size (≤16)；模拟器可配置 backlog |
| R4 | PoolGuard 的 Drop 实现若 panic 可能导致 double panic | Medium | ACQ-04 panic 安全测试可覆盖 |
| R5 | 连接池增加代码复杂度，可能引入新的竞态条件 | High | 并发测试（CON-01~05）设计覆盖 |
| R6 | Semaphore permit 未正确释放导致池永久降级 | High | BDY-01 1000次操作测试验证 |
| R7 | 事务 ID 在连接间共享 vs 独立的设计选择未明确 | Low | SIM-06 验证两种方案的正确性 |

---

## 14. 测试用例汇总

### 14.1 按类别统计

| 类别 | 用例数 | Critical | High | Medium | Low |
|------|:---:|:---:|:---:|:---:|:---:|
| 3. 连接池初始化测试 (INI) | 8 | 2 | 4 | 1 | 1 |
| 4. 连接获取与归还测试 (ACQ) | 6 | 3 | 2 | 1 | 0 |
| 5. 并发读写测试 (CON) | 5 | 2 | 2 | 1 | 0 |
| 6. 自动重建测试 (REC) | 6 | 1 | 4 | 1 | 0 |
| 7. 模拟器集成测试 (SIM) | 7 | 3 | 4 | 0 | 0 |
| 8. 池耗尽行为测试 (EXH) | 3 | 1 | 1 | 1 | 0 |
| 9. 生命周期测试 (LCY) | 5 | 1 | 3 | 1 | 0 |
| 10. 边界与压力测试 (BDY) | 6 | 0 | 1 | 3 | 2 |
| **总计** | **46** | **13** | **21** | **9** | **3** |

### 14.2 用例清单

| ID | 分类 | 描述 | 优先级 |
|----|------|------|--------|
| INI-01 | 初始化 | 默认 pool_size=4 创建连接池 | Critical |
| INI-02 | 初始化 | 自定义 pool_size=8 创建连接池 | Critical |
| INI-03 | 初始化 | pool_size=1 最小池 | High |
| INI-04 | 初始化 | pool_size=0 拒绝 | High |
| INI-05 | 初始化 | pool_size 上限验证 | Medium |
| INI-06 | 初始化 | connect() 初始化所有 N 个连接 | Critical |
| INI-07 | 初始化 | connect() 时模拟器不可达 | High |
| INI-08 | 初始化 | connect() 时部分连接失败 | High |
| ACQ-01 | 获取/归还 | acquire() 获取一个可用连接 | Critical |
| ACQ-02 | 获取/归还 | 连续 acquire 直到池耗尽 | Critical |
| ACQ-03 | 获取/归还 | 归还断开连接后标记 broken | Critical |
| ACQ-04 | 获取/归还 | PoolGuard Drop 确保归还 | High |
| ACQ-05 | 获取/归还 | guard 使用完后连接保持 ESTABLISHED | High |
| ACQ-06 | 获取/归还 | 归还顺序不影响复用 | Medium |
| CON-01 | 并发读写 | 2 个并发任务同时读 (pool_size=2) | Critical |
| CON-02 | 并发读写 | N+1 并发任务（超越池容量） | Critical |
| CON-03 | 并发读写 | 10 个并发任务（池激烈竞争） | High |
| CON-04 | 并发读写 | 并发读写混合操作 | High |
| CON-05 | 并发读写 | 长时间并发压力测试 | Medium |
| REC-01 | 自动重建 | 单个连接断开后自动重建 | Critical |
| REC-02 | 自动重建 | 多个连接断开后全部重建 | High |
| REC-03 | 自动重建 | 模拟器崩溃后自动重建 | High |
| REC-04 | 自动重建 | acquire 时自动替换 broken 连接 | High |
| REC-05 | 自动重建 | 重建超限（全部 broken 目标不可达） | Medium |
| REC-06 | 自动重建 | 正在使用的连接不被重建逻辑影响 | High |
| SIM-01 | 集成验证 | FC01 读取线圈（单连接） | Critical |
| SIM-02 | 集成验证 | FC03 读取寄存器（池模式） | Critical |
| SIM-03 | 集成验证 | 并发从池中读取多个寄存器 | Critical |
| SIM-04 | 集成验证 | FC05 写线圈 + FC01 读验证 | High |
| SIM-05 | 集成验证 | FC06 写寄存器 + FC03 读验证 | High |
| SIM-06 | 集成验证 | 事务 ID 跨连接隔离 | High |
| SIM-07 | 集成验证 | PDU 异常响应正确处理 | High |
| EXH-01 | 池耗尽 | 等待可用连接（信号量模式） | Critical |
| EXH-02 | 池耗尽 | 池耗尽超时 | High |
| EXH-03 | 池耗尽 | 请求排队 FIFO 公平性 | Medium |
| LCY-01 | 生命周期 | connect → disconnect → connect 循环 | Critical |
| LCY-02 | 生命周期 | 使用中断开（强制回收所有连接） | High |
| LCY-03 | 生命周期 | 已连接状态再 connect | High |
| LCY-04 | 生命周期 | 未连接时调用 acquire | High |
| LCY-05 | 生命周期 | disconnect 后归还的连接不保持 | Medium |
| BDY-01 | 边界/压力 | pool_size=1 的 1000 次操作并发安全 | High |
| BDY-02 | 边界/压力 | 极短超时下的池行为 | Medium |
| BDY-03 | 边界/压力 | 写操作失败后连接状态 | Medium |
| BDY-04 | 边界/压力 | 池大小可运行时动态查询 | Low |
| BDY-05 | 边界/压力 | 跨 task 移动 guard（Send 约束） | Medium |
| BDY-06 | 边界/压力 | 连接建立时间的并行优化 | Low |

### 14.3 优先级分布

| 优先级 | 数量 | 占比 |
|--------|------|------|
| Critical | 13 | 28.3% |
| High | 21 | 45.7% |
| Medium | 9 | 19.6% |
| Low | 3 | 6.5% |
| **合计** | **46** | **100%** |

### 14.4 模拟器依赖分布

| 依赖类型 | 用例数 |
|----------|:---:|
| 必须使用 modbus-simulator | 27 |
| 可使用 mock 替代 | 13 |
| 纯单元/编译验证 | 6 |

### 14.5 执行建议

1. **优先执行 Critical 用例**（13 个）：确认连接池核心机制可用
2. **单元测试优先于集成测试**：可先做 INI-01~05, ACQ-01~04, LCY-03~04 等不依赖模拟器的测试
3. **模拟器集成测试**（SIM-01~07）：需先确认 `modbus-simulator` 可正常启动
4. **断连重建测试**（REC-01~06）：需要 tcpkill/pfctl 工具；若不可用，用 mock 方案替代或手动模拟器 kill 测试
5. **并发测试独立运行**：避免与其他测试的时序干扰，推荐 `--test-threads=1` 方式对关键并发用例单独运行
6. **压力测试**（BDY-01, CON-05）：在 CI 中可适当缩减迭代次数以控制执行时间

---

**文档结束**
