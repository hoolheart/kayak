# S2-004 Design Review v2

**任务**: 试验数据查询API (Experiment Data Query API)  
**评审人**: sw-jerry (Software Architect)  
**评审日期**: 2026-03-28  
**文档版本**: 1.0 → 1.1  
**评审结果**: ✅ **APPROVED** (with implementation requirements)

---

## 1. 变更摘要

### 1.1 修复的问题

| # | 问题 | 状态 | 验证位置 |
|---|------|------|----------|
| 1 | Timestamp转换Bug | ✅ **已修复** | Section 6.2, line 560-561 |
| 2 | Range请求`.take()`重复调用 | ✅ **已修复** | Section 7.2, line 657 |
| 3 | 权限验证缺失 | ⚠️ **部分修复** | Trait signatures + handlers |

### 1.2 关键修复验证

**Issue 1 - Timestamp转换 (FIXED)**:
```rust
// Section 6.2, line 560-561
let nanos = *ts;
let dt = DateTime::from_timestamp(nanos / 1_000_000_000, (nanos % 1_000_000_000) as u32).unwrap();
```
✅ 正确将纳秒时间戳拆分为秒和纳秒分量

**Issue 2 - Range请求 (FIXED)**:
```rust
// Section 7.2, line 657
let body = StreamBody::new(ByteStream::new(stream.take(end - start + 1)));
```
✅ `.take()`只调用一次，不再重复

---

## 2. 授权检查验证

### 2.1 Trait签名 ✅

| 方法 | user_id参数 | 状态 |
|------|-------------|------|
| `get_experiment(id, user_id)` | ✅ | 正确 |
| `list_experiments(filter, ...)` | ✅ (filter.user_id) | 正确 |
| `get_point_history(..., user_id)` | ✅ | 正确 |
| `get_data_file_info(..., user_id)` | ✅ | 正确 |

### 2.2 Handler实现

| Handler | Auth提取 | user_id传递 | 状态 |
|---------|----------|-------------|------|
| `list_experiments` | ✅ (line 680) | ✅ filter.user_id | ✅ |
| `get_experiment` | ✅ (line 710) | ✅ service call | ✅ |
| `get_point_history` | ✅ (line 729) | ✅ service call | ✅ |
| `download_data_file` | ❌ **缺失** | ❌ **缺失** | ⚠️ |

### 2.3 遗留问题

**`download_data_file` handler缺少授权检查** (Section 8.4, line 757-790):

```rust
pub async fn download_data_file(
    Path(id): Path<Uuid>,
    State(state): State<AppState>,
    req: Request,  // ❌ 缺少 Auth(user_id) 提取
) -> Result<Response, AppError> {
    let file_info = state.experiment_service
        .get_data_file_info(id)  // ❌ 未传递 user_id
        .await
```

**风险**: 任何已认证用户都可以下载任意试验的数据文件

**要求**: 实现时必须添加授权检查

---

## 3. 设计质量评估

### 3.1 架构分层 ✅

| 层级 | 评价 |
|------|------|
| API Handlers | ✅ 清晰的请求处理 |
| Services | ✅ 业务逻辑封装 |
| Repositories | ✅ 接口定义清晰 |
| Models/DTOs | ✅ 类型安全 |

### 3.2 DIP遵循 ✅

- Service依赖Repository traits (接口)
- Handler依赖Service traits (接口)
- 依赖注入通过`AppState`实现

### 3.3 错误处理 ✅

- 自定义错误类型使用`thiserror`
- 错误类型覆盖全面
- HTTP状态码映射已定义

---

## 4. 实现要求

### 4.1 必须实现 (Must Implement)

| # | 要求 | 原因 |
|---|------|------|
| 1 | `download_data_file`必须提取`Auth(user_id)`并传递给`get_data_file_info` | 安全: 防止未授权访问 |
| 2 | `get_data_file_info`实现必须验证用户是否有权访问该试验 | 安全: 数据隔离 |
| 3 | 所有返回试验数据的API必须使用`user_id`过滤 | 安全: 用户数据隔离 |

### 4.2 建议实现 (Should Implement)

| # | 建议 | 原因 |
|---|------|------|
| 1 | 添加`DataFileError::AccessDenied`变体 | 明确的错误类型 |
| 2 | download handler应先验证试验存在性再检查权限 | 错误信息准确性 |

---

## 5. 总结

### 5.1 修复验证

| 问题 | 原状态 | 当前状态 |
|------|--------|----------|
| Timestamp转换Bug | ❌ Critical | ✅ Fixed |
| Range请求Bug | ❌ Critical | ✅ Fixed |
| 权限验证缺失 | ❌ High | ⚠️ Partially Fixed |

### 5.2 批准决定

**结果**: ✅ **APPROVED**

**理由**:
1. Critical Bug #1 (Timestamp) 已修复并验证
2. Critical Bug #2 (Range) 已修复并验证
3. 授权模式已在trait signatures中正确定义
4. 主要API handlers已正确实现授权检查

**条件**: 实现时必须完成`download_data_file`的授权检查

### 5.3 下一步

1. sw-tom按设计实现代码
2. 特别注意`download_data_file` handler的授权检查
3. 实现完成后提交Code Review

---

**评审人签名**: sw-jerry  
**评审时间**: 2026-03-28
