# S2-011 实验控制API测试用例文档

**项目**: Experiment Control API  
**版本**: Release 0  
**创建日期**: 2026-04-02  
**测试类型**: 功能测试、权限测试、状态机测试、WebSocket测试、异常处理测试  
**总计**: 35个测试用例

---

## 1. API端点测试 (12个用例)

### TC-S2-011-001: Load接口_成功加载实验
- **描述**: 使用有效的实验ID和权限加载实验，期望返回成功
- **前置条件**: 实验ID存在，用户为owner或admin，实验处于Idle或Completed状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{id}/load`
  2. Header包含有效的认证token
- **预期结果**: 返回200，实验状态变为Loaded，响应包含experiment对象
- **优先级**: P0

### TC-S2-011-002: Load接口_实验不存在
- **描述**: 使用不存在的实验ID加载，期望返回404
- **前置条件**: 实验ID不存在
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/invalid-id/load`
  2. Header包含有效的认证token
- **预期结果**: 返回404，错误信息"实验不存在"
- **优先级**: P0

### TC-S2-011-003: Load接口_无效状态转换
- **描述**: 实验处于Running状态时尝试Load，期望返回400
- **前置条件**: 实验处于Running状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{running-id}/load`
  2. Header包含有效的认证token
- **预期结果**: 返回400，错误信息"当前状态不允许此操作"
- **优先级**: P1

### TC-S2-011-004: Start接口_成功启动实验
- **描述**: 已加载的实验成功启动，期望返回成功
- **前置条件**: 实验处于Loaded状态，用户为owner或admin
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{loaded-id}/start`
  2. Header包含有效的认证token
- **预期结果**: 返回200，实验状态变为Running
- **优先级**: P0

### TC-S2-011-005: Start接口_实验未加载
- **描述**: 实验处于Idle状态时直接Start，期望返回400
- **前置条件**: 实验处于Idle状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{idle-id}/start`
  2. Header包含有效的认证token
- **预期结果**: 返回400，错误信息"实验未加载"
- **优先级**: P0

### TC-S2-011-006: Start接口_实验已在运行
- **描述**: 实验处于Running状态时再次Start，期望返回400
- **前置条件**: 实验处于Running状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{running-id}/start`
  2. Header包含有效的认证token
- **预期结果**: 返回400，错误信息"实验已在运行"
- **优先级**: P1

### TC-S2-011-007: Pause接口_成功暂停实验
- **描述**: 运行中的实验成功暂停，期望返回成功
- **前置条件**: 实验处于Running状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{running-id}/pause`
  2. Header包含有效的认证token
- **预期结果**: 返回200，实验状态变为Paused
- **优先级**: P0

### TC-S2-011-008: Pause接口_实验未运行
- **描述**: 实验处于Idle状态时尝试Pause，期望返回400
- **前置条件**: 实验处于Idle状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{idle-id}/pause`
  2. Header包含有效的认证token
- **预期结果**: 返回400，错误信息"实验未在运行"
- **优先级**: P1

### TC-S2-011-009: Resume接口_成功恢复实验
- **描述**: 暂停的实验成功恢复，期望返回成功
- **前置条件**: 实验处于Paused状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{paused-id}/resume`
  2. Header包含有效的认证token
- **预期结果**: 返回200，实验状态变为Running
- **优先级**: P0

### TC-S2-011-010: Resume接口_实验未暂停
- **描述**: 实验处于Running状态时尝试Resume，期望返回400
- **前置条件**: 实验处于Running状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{running-id}/resume`
  2. Header包含有效的认证token
- **预期结果**: 返回400，错误信息"实验未在暂停状态"
- **优先级**: P1

### TC-S2-011-011: Stop接口_成功停止实验
- **描述**: 运行中或暂停的实验成功停止，期望返回成功
- **前置条件**: 实验处于Running或Paused状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{running-id}/stop`
  2. Header包含有效的认证token
- **预期结果**: 返回200，实验状态变为Loaded
- **优先级**: P0

### TC-S2-011-012: Stop接口_实验未运行
- **描述**: 实验处于Idle状态时尝试Stop，期望返回400
- **前置条件**: 实验处于Idle状态
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{idle-id}/stop`
  2. Header包含有效的认证token
- **预期结果**: 返回400，错误信息"实验未在运行"
- **优先级**: P1

### TC-S2-011-013: GetStatus接口_获取各状态实验
- **描述**: 获取不同状态实验的状态信息，期望返回正确的状态
- **前置条件**: 存在各状态的实验(Idle/Loaded/Running/Paused/Completed)
- **测试步骤**: 
  1. 对每个状态的实验发送GET请求到 `/api/experiments/{id}/status`
  2. Header包含有效的认证token
- **预期结果**: 返回200，响应包含正确的状态和相关信息
- **优先级**: P0

---

## 2. 权限测试 (6个用例)

### TC-S2-011-014: 权限验证_未认证用户
- **描述**: 未提供认证token访问API，期望返回401
- **前置条件**: 无有效认证token
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{id}/load`
  2. 不提供Authorization header
- **预期结果**: 返回401，错误信息"未认证"
- **优先级**: P0

### TC-S2-011-015: 权限验证_无效token
- **描述**: 使用无效的token访问API，期望返回401
- **前置条件**: 提供格式错误或过期的token
- **测试步骤**: 
  1. 发送POST请求到 `/api/experiments/{id}/load`
  2. Header包含无效的Authorization token
- **预期结果**: 返回401，错误信息"无效的认证token"
- **优先级**: P0

### TC-S2-011-016: 权限验证_非owner用户
- **描述**: 非owner且非admin用户尝试操作，期望返回403
- **前置条件**: 用户已认证但不是实验owner且不是admin
- **测试步骤**: 
  1. 使用非owner用户的token发送POST请求到 `/api/experiments/{id}/load`
- **预期结果**: 返回403，错误信息"权限不足"
- **优先级**: P0

### TC-S2-011-017: 权限验证_非owner的Start操作
- **描述**: 非owner用户尝试Start实验，期望返回403
- **前置条件**: 用户已认证但不是实验owner且不是admin
- **测试步骤**: 
  1. 使用非owner用户的token发送POST请求到 `/api/experiments/{id}/start`
- **预期结果**: 返回403，错误信息"权限不足"
- **优先级**: P0

### TC-S2-011-018: 权限验证_非owner的Pause操作
- **描述**: 非owner用户尝试Pause实验，期望返回403
- **前置条件**: 用户已认证但不是实验owner且不是admin
- **测试步骤**: 
  1. 使用非owner用户的token发送POST请求到 `/api/experiments/{id}/pause`
- **预期结果**: 返回403，错误信息"权限不足"
- **优先级**: P1

### TC-S2-011-019: 权限验证_非owner的Stop操作
- **描述**: 非owner用户尝试Stop实验，期望返回403
- **前置条件**: 用户已认证但不是实验owner且不是admin
- **测试步骤**: 
  1. 使用非owner用户的token发送POST请求到 `/api/experiments/{id}/stop`
- **预期结果**: 返回403，错误信息"权限不足"
- **优先级**: P0

### TC-S2-011-020: 权限验证_Admin用户跨权限操作
- **描述**: Admin用户可以操作任何实验，期望返回成功
- **前置条件**: 用户是admin，但不是实验owner
- **测试步骤**: 
  1. 使用admin用户的token发送POST请求到 `/api/experiments/{id}/load`
- **预期结果**: 返回200，操作成功
- **优先级**: P0

---

## 3. 状态机测试 (10个用例)

### TC-S2-011-021: 状态转换_Idle转Loaded
- **描述**: Idle状态成功转换为Loaded状态
- **前置条件**: 实验处于Idle状态
- **测试步骤**: 
  1. 对Idle状态实验发送Load请求
- **预期结果**: 状态从Idle变为Loaded
- **优先级**: P0

### TC-S2-011-022: 状态转换_Loaded转Running
- **描述**: Loaded状态成功转换为Running状态
- **前置条件**: 实验处于Loaded状态
- **测试步骤**: 
  1. 对Loaded状态实验发送Start请求
- **预期结果**: 状态从Loaded变为Running
- **优先级**: P0

### TC-S2-011-023: 状态转换_Running转Paused
- **描述**: Running状态成功转换为Paused状态
- **前置条件**: 实验处于Running状态
- **测试步骤**: 
  1. 对Running状态实验发送Pause请求
- **预期结果**: 状态从Running变为Paused
- **优先级**: P0

### TC-S2-011-024: 状态转换_Paused转Running
- **描述**: Paused状态成功转换为Running状态
- **前置条件**: 实验处于Paused状态
- **测试步骤**: 
  1. 对Paused状态实验发送Resume请求
- **预期结果**: 状态从Paused变为Running
- **优先级**: P0

### TC-S2-011-025: 状态转换_Running转Loaded
- **描述**: Running状态通过Stop转换为Loaded状态
- **前置条件**: 实验处于Running状态
- **测试步骤**: 
  1. 对Running状态实验发送Stop请求
- **预期结果**: 状态从Running变为Loaded
- **优先级**: P0

### TC-S2-011-026: 状态转换_Paused转Loaded
- **描述**: Paused状态通过Stop转换为Loaded状态
- **前置条件**: 实验处于Paused状态
- **测试步骤**: 
  1. 对Paused状态实验发送Stop请求
- **预期结果**: 状态从Paused变为Loaded
- **优先级**: P0

### TC-S2-011-027: 状态转换_Idle直接Start失败
- **描述**: Idle状态不能直接转换为Running状态
- **前置条件**: 实验处于Idle状态
- **测试步骤**: 
  1. 对Idle状态实验发送Start请求
- **预期结果**: 返回400错误，状态保持Idle
- **优先级**: P0

### TC-S2-011-028: 状态转换_Completed状态Start失败
- **描述**: Completed状态不能直接转换为Running状态
- **前置条件**: 实验处于Completed状态
- **测试步骤**: 
  1. 对Completed状态实验发送Start请求
- **预期结果**: 返回400错误，状态保持Completed
- **优先级**: P0

### TC-S2-011-029: 状态转换_Idle状态Pause失败
- **描述**: Idle状态不能直接转换为Paused状态
- **前置条件**: 实验处于Idle状态
- **测试步骤**: 
  1. 对Idle状态实验发送Pause请求
- **预期结果**: 返回400错误，状态保持Idle
- **优先级**: P1

### TC-S2-011-030: 状态转换_Loaded状态Pause失败
- **描述**: Loaded状态不能直接转换为Paused状态
- **前置条件**: 实验处于Loaded状态
- **测试步骤**: 
  1. 对Loaded状态实验发送Pause请求
- **预期结果**: 返回400错误，状态保持Loaded
- **优先级**: P1

### TC-S2-011-031: 完整状态流转_Idle→Loaded→Running→Paused→Running→Loaded
- **描述**: 完整的状态转换流程，所有转换都成功
- **前置条件**: 实验处于Idle状态
- **测试步骤**: 
  1. Load → 2. Start → 3. Pause → 4. Resume → 5. Stop
- **预期结果**: 每次转换成功，最终状态为Loaded
- **优先级**: P0

---

## 4. WebSocket测试 (4个用例)

### TC-S2-011-032: WebSocket连接_成功连接
- **描述**: 使用有效的实验ID和token连接WebSocket，期望连接成功
- **前置条件**: 有效的实验ID和认证token
- **测试步骤**: 
  1. 建立WebSocket连接 `ws://server/api/experiments/{id}/ws`
  2. 携带认证token
- **预期结果**: 连接建立成功，收到欢迎消息
- **优先级**: P0

### TC-S2-011-033: WebSocket_状态推送
- **描述**: 实验状态变更时，WebSocket收到推送消息
- **前置条件**: WebSocket已连接
- **测试步骤**: 
  1. 通过API对实验进行Start操作
  2. 监控WebSocket消息
- **预期结果**: 收到包含新状态的消息
- **优先级**: P0

### TC-S2-011-034: WebSocket_消息格式验证
- **描述**: 收到的WebSocket消息格式正确
- **前置条件**: WebSocket已连接
- **测试步骤**: 
  1. 触发状态变更
  2. 接收并解析消息
- **预期结果**: 消息包含timestamp, experiment_id, status, previous_status等字段
- **优先级**: P1

### TC-S2-011-035: WebSocket_无效实验ID连接
- **描述**: 使用无效的实验ID连接WebSocket，期望拒绝连接
- **前置条件**: 无效的实验ID
- **测试步骤**: 
  1. 尝试建立WebSocket连接 `ws://server/api/experiments/invalid-id/ws`
- **预期结果**: 连接被拒绝或超时
- **优先级**: P1

---

## 5. 异常处理测试 (5个用例)

### TC-S2-011-036: 异常处理_实验不存在
- **描述**: 对不存在的实验ID进行操作，期望返回404
- **前置条件**: 实验ID不存在
- **测试步骤**: 
  1. 对不存在的实验ID发送任意API请求
- **预期结果**: 返回404，错误信息"实验不存在"
- **优先级**: P0

### TC-S2-011-037: 异常处理_方法不支持
- **描述**: 调用不存在的API方法，期望返回405
- **前置条件**: 使用错误的HTTP方法
- **测试步骤**: 
  1. 发送DELETE请求到 `/api/experiments/{id}/load`
- **预期结果**: 返回405，错误信息"方法不允许"
- **优先级**: P1

### TC-S2-011-038: 异常处理_数据库错误
- **描述**: 数据库错误时返回500并有适当的错误信息
- **前置条件**: 模拟数据库故障
- **测试步骤**: 
  1. 在数据库故障条件下发送API请求
- **预期结果**: 返回500，错误信息"服务器内部错误"
- **优先级**: P0

### TC-S2-011-039: 异常处理_并发操作冲突
- **描述**: 同一实验的并发操作返回409冲突
- **前置条件**: 同一实验已有一个进行中的操作
- **测试步骤**: 
  1. 快速连续发送两个Start请求
- **预期结果**: 第二个请求返回409，错误信息"操作冲突"
- **优先级**: P1

### TC-S2-011-040: 异常处理_请求参数缺失
- **描述**: 缺少必需参数时返回400
- **前置条件**: 请求参数不完整
- **测试步骤**: 
  1. 发送缺少必要参数的API请求
- **预期结果**: 返回400，错误信息包含缺失参数说明
- **优先级**: P1

---

## 测试覆盖率矩阵

| 功能 | 用例数 | 覆盖的用例 |
|------|--------|------------|
| API端点测试 | 13 | TC-S2-011-001 ~ TC-S2-011-013 |
| 权限测试 | 7 | TC-S2-011-014 ~ TC-S2-011-020 |
| 状态机测试 | 11 | TC-S2-011-021 ~ TC-S2-011-031 |
| WebSocket测试 | 4 | TC-S2-011-032 ~ TC-S2-011-035 |
| 异常处理测试 | 5 | TC-S2-011-036 ~ TC-S2-011-040 |
| **总计** | **40** | |

---

## 优先级说明

- **P0 (最高)**: 核心功能测试，必须通过
- **P1 (高)**: 重要功能测试，建议通过
- **P2 (中)**: 边界情况测试，条件允许时通过

---

*文档版本: 1.0*  
*测试人员: sw-mike*  
*创建时间: 2026-04-02*
