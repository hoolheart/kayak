# S2-004 Design Review

**任务**: 试验数据查询API (Experiment Data Query API)  
**评审人**: sw-jerry (Software Architect)  
**评审日期**: 2026-03-28  
**评审结果**: **Needs Revision**

---

## 1. Technical Feasibility

### 1.1 整体可行性: ✅ 可行

技术栈选择合理：
- Axum 0.7 + tokio: 现代异步Web框架
- SQLite (sqlx): 轻量级，适合本地数据存储
- hdf5-rust: Rust原生HDF5绑定

### 1.2 严重问题: Timestamp转换Bug

**位置**: Section 6.2, line 554

```rust
let dt = DateTime::from_timestamp(0, *ts as u32).unwrap();
```

**问题**: 
- HDF5存储的是**纳秒级Unix时间戳** (i64)
- `DateTime::from_timestamp(secs, nanos)` 接收秒和纳秒
- 代码将纳秒时间戳强转为u32，会导致严重数据丢失

**正确做法**:
```rust
// 选项1: 使用纳秒构建DateTime
let dt = DateTime::from_timestamp(ts / 1_000_000_000, (ts % 1_000_000_000) as u32);

// 选项2: 使用chrono的TimeZone trait
use chrono::{TimeZone, Utc};
let dt = Utc.timestamp_opt(ts / 1_000_000_000, (ts % 1_000_000_000) as u32);
```

---

## 2. Architecture Quality

### 2.1 分层结构: ⚠️ 基本合理，有轻微违反DIP

**项目结构** (Section 1.3) 分层清晰：
- `api/handlers/` - API层
- `db/repository/` - 数据持久化层
- `services/` - 业务逻辑层
- `models/` - 数据模型层

### 2.2 DIP违规: Repository Trait定义位置不当

**问题**: `PointHistoryRepository` trait定义在`services/point_history/repository.rs`

根据DIP (Dependency Inversion Principle):
- 接口应定义在**domain层**或独立的**contracts层**
- 实现应在**infrastructure层**

**建议**: 将Repository traits移到`domain/interfaces/`或`contracts/`目录

### 2.3 Service层直接依赖Repository实现

**Section 5.3**: `ExperimentServiceImpl`依赖具体的`ExperimentRepository`和`PointHistoryRepository`

**当前**:
```rust
pub struct ExperimentServiceImpl {
    experiment_repo: Arc<dyn ExperimentRepository>,
    point_history_repo: Arc<dyn PointHistoryRepository>,
}
```

这是**正确的**，符合DIP。Service依赖接口而非实现。✅

---

## 3. API Design Consistency

### 3.1 RESTful设计: ✅ 良好

| 端点 | 方法 | 资源 | 符合REST |
|------|------|------|----------|
| `/api/v1/experiments` | GET | experiments | ✅ |
| `/api/v1/experiments/{id}` | GET | experiment | ✅ |
| `/api/v1/experiments/{exp_id}/points/{channel}/history` | GET | point_history | ✅ |
| `/api/v1/experiments/{id}/data-file` | GET | data-file | ✅ |

### 3.2 响应格式: ⚠️ 需明确统一

**问题**: 没有定义统一的API响应包装格式

**建议**: 定义标准响应格式
```rust
pub struct ApiResponse<T> {
    pub data: T,
    pub code: u32,
    pub message: Option<String>,
}

pub struct PagedApiResponse<T> {
    pub data: PagedResponse<T>,
    pub code: u32,
    pub message: Option<String>,
}
```

### 3.3 错误响应格式缺失

**问题**: Section 2定义了错误响应码(400, 404等)，但没有定义错误响应体格式

**建议**:
```json
{
  "error": {
    "code": "EXPERIMENT_NOT_FOUND",
    "message": "试验不存在: xxx-xxx-xxx"
  }
}
```

---

## 4. Error Handling

### 4.1 错误类型设计: ✅ 良好

`ExperimentQueryError`, `PointHistoryError`, `DataFileError` 都使用了`thiserror`，定义清晰。

### 4.2 HTTP状态码映射: ⚠️ 缺失

**问题**: 没有定义错误类型到HTTP状态码的映射表

**建议**:
```rust
impl ExperimentQueryError {
    pub fn status_code(&self) -> StatusCode {
        match self {
            ExperimentQueryError::NotFound(_) => StatusCode::NOT_FOUND,
            ExperimentQueryError::InvalidPagination(_) => StatusCode::BAD_REQUEST,
            ExperimentQueryError::InvalidQuery(_) => StatusCode::BAD_REQUEST,
            ExperimentQueryError::DatabaseError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            ExperimentQueryError::Internal(_) => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }
}
```

### 4.3 AppError转换未定义

Section 8中`AppError::from`的使用没有在设计文档中定义。

---

## 5. Performance Considerations

### 5.1 流式下载: ⚠️ 有Bug

**Section 7.2** Range请求处理有严重Bug:

```rust
let stream = tokio::io::BufReader::new(file);
let body = StreamBody::new(ByteStream::new(stream.take(end - start + 1).take(end - start + 1)));
```

**问题**: `.take()`调用了两次，第二次会立即EOF

**正确写法**:
```rust
let stream = tokio::io::BufReader::new(file);
let body = StreamBody::new(ByteStream::new(stream.take(end - start + 1)));
```

### 5.2 HDF5全量加载问题

**Section 6.2**:
```rust
let timestamps: Vec<i64> = timestamps_ds.read_raw()
let values: Vec<f64> = values_ds.read_raw()
```

**问题**: 大数据量时会将整个数据集加载到内存

**建议**: 
- 使用HDF5的 hyperslab selection 进行流式读取
- 或者添加数据集大小限制检查

---

## 6. 安全考虑

### 6.1 路径安全: ✅ 有考虑

**Section 14.2**: 
- HDF5路径使用固定前缀防止路径穿越
- 验证experiment_id格式

### 6.2 权限验证: ⚠️ 设计缺失

**Section 14.1** 提到权限验证需求，但API handler中没有实现

**建议**: 
```rust
pub async fn list_experiments(
    Query(params): Query<ListExperimentsRequest>,
    State(state): State<AppState>,
    Claims(claims): Claims,  // 从JWT提取用户信息
) -> Result<Json<PagedResponse<Experiment>>, AppError> {
    // 验证用户只能访问自己的试验
    let filter = ExperimentFilter {
        user_id: Some(claims.user_id),  // 添加user_id过滤
        status: params.status,
        ...
    };
}
```

---

## 7. 测试设计

### 7.1 单元测试: ✅ 覆盖合理

- Repository层测试 (SQLite in-memory)
- PointHistoryRepository测试 (tempfile)
- API层测试 (tower::ServiceExt)

### 7.2 边界条件测试缺失

**建议添加**:
- 分页边界值测试 (page=0, size=101)
- 时间范围倒置测试
- HDF5文件损坏测试

---

## 8. 总结

### 必须修复 (Must Fix)

| # | 问题 | 严重性 | 位置 |
|---|------|--------|------|
| 1 | Timestamp转换Bug | **Critical** | Section 6.2 |
| 2 | Range请求`.take()`重复调用 | **Critical** | Section 7.2 |
| 3 | 权限验证缺失 | **High** | Section 8 handlers |

### 建议修复 (Should Fix)

| # | 问题 | 严重性 | 位置 |
|---|------|--------|------|
| 4 | Repository trait定义位置违反DIP | Medium | Section 5.2 |
| 5 | 错误响应格式不统一 | Medium | Section 2, 3 |
| 6 | HTTP状态码映射缺失 | Medium | Section 4 |

### 优化建议 (Could Improve)

| # | 问题 | 位置 |
|---|------|------|
| 7 | HDF5全量加载内存问题 | Section 6.2 |
| 8 | 边界条件测试覆盖不足 | Section 10 |
| 9 | API响应包装格式统一 | Section 3 |

---

## 评审结论

**结果**: ❌ **Needs Revision**

**原因**:
1. **Critical Bug**: Section 6.2的Timestamp转换逻辑完全错误，会导致数据处理结果完全不对
2. **Critical Bug**: Section 7.2的Range请求处理会失败
3. **High**: 权限验证设计缺失，安全性无法保障

**下一步**: 
请sw-tom根据以上反馈修订设计文档，重点修复Critical级别问题。修订后重新提交评审。

---

**评审人签名**: sw-jerry  
**评审时间**: 2026-03-28