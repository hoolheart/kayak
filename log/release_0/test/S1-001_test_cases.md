# S1-001 测试用例文档
## Rust后端工程初始化

**任务ID**: S1-001  
**任务名称**: Rust后端工程初始化  
**文档版本**: 1.0  
**创建日期**: 2024-03-15  
**测试类型**: 集成测试、构建测试、API测试

---

## 1. 测试范围

### 1.1 测试目标
本文档覆盖 S1-001 任务的所有验收标准，确保Rust后端工程初始化完成后的质量和可用性。

### 1.2 验收标准映射

| 验收标准 | 测试用例ID | 测试类型 |
|---------|-----------|---------|
| 1. 项目可编译通过 `cargo build` 无错误 | TC-S1-001-01 | 构建测试 |
| 2. 启动后能响应健康检查接口 `GET /health` | TC-S1-001-02 | API集成测试 |
| 3. 日志输出格式规范，包含时间戳和级别 | TC-S1-001-03 | 功能测试 |

---

## 2. 测试用例详情

### 2.1 构建测试

#### TC-S1-001-01: 项目编译验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-001-01 |
| **测试名称** | 项目编译验证 |
| **测试类型** | 构建测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证Rust项目能够成功编译，无错误或警告 |

**前置条件:**
1. Rust工具链已安装 (rustc >= 1.75.0)
2. Cargo 可用
3. 项目代码已提交到 `kayak-backend/` 目录
4. 所有依赖项在 Cargo.toml 中已声明

**测试步骤:**

1. 进入项目目录
   ```bash
   cd /home/hzhou/workspace/kayak/kayak-backend
   ```

2. 执行编译命令
   ```bash
   cargo build --release
   ```

3. 检查编译输出
   ```bash
   echo $?
   ```

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| 退出码 | 0 |
| 编译错误 | 0 |
| 编译警告 | 0 或已记录在案的警告 |
| 生成的可执行文件 | `target/release/kayak-backend` 存在 |

**通过标准:**
- [ ] `cargo build` 命令成功完成 (exit code = 0)
- [ ] 无编译错误
- [ ] 警告数量 <= 5 个（如有警告需评估是否可以修复）
- [ ] 生成的二进制文件可执行

**自动化测试脚本:**

```bash
#!/bin/bash
# TC-S1-001-01: Build Verification Script

set -e

PROJECT_DIR="/home/hzhou/workspace/kayak/kayak-backend"
BUILD_LOG="/tmp/s1-001-build.log"

echo "=== TC-S1-001-01: 项目编译验证 ==="
echo "开始时间: $(date)"

# 进入项目目录
cd "$PROJECT_DIR" || exit 1

# 清理之前的构建
echo "清理之前的构建..."
cargo clean

# 执行编译
echo "执行 cargo build..."
if cargo build --release 2>&1 | tee "$BUILD_LOG"; then
    echo "✓ 编译成功"
else
    echo "✗ 编译失败"
    exit 1
fi

# 检查可执行文件
if [ -f "target/release/kayak-backend" ]; then
    echo "✓ 可执行文件存在"
    ls -lh target/release/kayak-backend
else
    echo "✗ 可执行文件不存在"
    exit 1
fi

# 检查错误和警告
ERROR_COUNT=$(grep -c "^error" "$BUILD_LOG" || echo "0")
WARNING_COUNT=$(grep -c "^warning" "$BUILD_LOG" || echo "0")

echo ""
echo "=== 编译统计 ==="
echo "错误数量: $ERROR_COUNT"
echo "警告数量: $WARNING_COUNT"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✓ 无编译错误"
else
    echo "✗ 发现 $ERROR_COUNT 个编译错误"
    exit 1
fi

echo ""
echo "=== 测试通过 ==="
echo "结束时间: $(date)"
```

**备注:**
- 编译时间应在合理范围内（首次编译 < 5分钟，增量编译 < 30秒）
- 建议执行 `cargo clippy` 检查代码质量

---

### 2.2 API集成测试

#### TC-S1-001-02: 健康检查接口验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-001-02 |
| **测试名称** | 健康检查接口验证 |
| **测试类型** | API集成测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证后端服务启动后能正确响应健康检查请求 |

**前置条件:**
1. 项目编译成功 (TC-S1-001-01 通过)
2. 服务可正常启动
3. 健康检查端点已实现: `GET /health`

**测试步骤:**

1. 编译并启动服务
   ```bash
   cd /home/hzhou/workspace/kayak/kayak-backend
   cargo run --release &
   SERVER_PID=$!
   ```

2. 等待服务启动 (最多等待10秒)
   ```bash
   sleep 2
   ```

3. 发送健康检查请求
   ```bash
   curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost:8080/health
   ```

4. 记录响应结果

5. 停止服务
   ```bash
   kill $SERVER_PID 2>/dev/null || true
   ```

**预期结果:**

| 检查项 | 预期值 |
|-------|--------|
| HTTP状态码 | 200 |
| 响应Content-Type | application/json |
| 响应体 | 包含 `status` 字段，值为 `healthy` 或类似 |
| 响应时间 | < 500ms |

**响应体示例:**
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "timestamp": "2024-03-15T10:30:00Z"
}
```

**通过标准:**
- [ ] HTTP 状态码为 200
- [ ] 响应包含有效的JSON格式
- [ ] 响应包含状态指示字段
- [ ] 服务启动时间 < 10秒

**自动化测试脚本:**

```bash
#!/bin/bash
# TC-S1-001-02: Health Check API Verification Script

set -e

PROJECT_DIR="/home/hzhou/workspace/kayak/kayak-backend"
SERVER_PORT=8080
SERVER_PID=""
TEST_LOG="/tmp/s1-001-health.log"

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        echo "停止服务 (PID: $SERVER_PID)..."
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
}

trap cleanup EXIT

echo "=== TC-S1-001-02: 健康检查接口验证 ==="
echo "开始时间: $(date)"

# 进入项目目录
cd "$PROJECT_DIR" || exit 1

# 检查端口是否被占用
if lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "错误: 端口 $SERVER_PORT 已被占用"
    exit 1
fi

# 启动服务
echo "启动后端服务..."
cargo run --release > "$TEST_LOG" 2>&1 &
SERVER_PID=$!
echo "服务PID: $SERVER_PID"

# 等待服务启动
echo "等待服务启动..."
MAX_WAIT=10
WAITED=0
while ! curl -s http://localhost:$SERVER_PORT/health >/dev/null 2>&1; do
    sleep 1
    WAITED=$((WAITED + 1))
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo "✗ 服务启动超时 (${MAX_WAIT}秒)"
        echo "服务日志:"
        tail -50 "$TEST_LOG"
        exit 1
    fi
    echo "  等待中... ($WAITED/$MAX_WAIT)"
done
echo "✓ 服务已启动 (用时 ${WAITED}秒)"

# 测试健康检查接口
echo ""
echo "测试健康检查接口..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nRESPONSE_TIME:%{time_total}\n" \
    http://localhost:$SERVER_PORT/health)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
RESPONSE_TIME=$(echo "$RESPONSE" | grep "RESPONSE_TIME:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:" | grep -v "RESPONSE_TIME:")

echo "HTTP状态码: $HTTP_CODE"
echo "响应时间: ${RESPONSE_TIME}s"
echo "响应体: $RESPONSE_BODY"

# 验证HTTP状态码
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ HTTP状态码正确 (200)"
else
    echo "✗ HTTP状态码错误: $HTTP_CODE (期望: 200)"
    exit 1
fi

# 验证响应时间
if (( $(echo "$RESPONSE_TIME < 0.5" | bc -l) )); then
    echo "✓ 响应时间正常 (< 0.5s)"
else
    echo "✗ 响应时间过长: ${RESPONSE_TIME}s"
    exit 1
fi

# 验证JSON格式
if echo "$RESPONSE_BODY" | python3 -m json.tool >/dev/null 2>&1; then
    echo "✓ 响应是有效的JSON格式"
else
    echo "✗ 响应不是有效的JSON格式"
    exit 1
fi

# 验证响应内容
if echo "$RESPONSE_BODY" | grep -q "status"; then
    echo "✓ 响应包含status字段"
else
    echo "✗ 响应缺少status字段"
    exit 1
fi

echo ""
echo "=== 测试通过 ==="
echo "结束时间: $(date)"
```

**备注:**
- 默认服务端口为8080，如配置不同请调整脚本
- 需要安装 `curl` 和 `bc` 工具
- 健康检查端点应支持跨域(CORS)请求

---

### 2.3 日志格式验证

#### TC-S1-001-03: 日志输出格式验证

| 字段 | 内容 |
|-----|------|
| **测试ID** | TC-S1-001-03 |
| **测试名称** | 日志输出格式验证 |
| **测试类型** | 功能测试 |
| **优先级** | P0 (Critical) |
| **测试目的** | 验证日志输出格式规范，包含时间戳和级别 |

**前置条件:**
1. 项目编译成功 (TC-S1-001-01 通过)
2. tracing/tracing-subscriber 已正确配置
3. 服务可正常启动

**测试步骤:**

1. 启动服务并捕获日志输出
   ```bash
   cd /home/hzhou/workspace/kayak/kayak-backend
   cargo run --release 2>&1 | tee /tmp/kayak-server.log &
   SERVER_PID=$!
   sleep 2
   ```

2. 触发日志记录（发送健康检查请求）
   ```bash
   curl -s http://localhost:8080/health >/dev/null
   ```

3. 等待日志写入
   ```bash
   sleep 1
   ```

4. 分析日志格式
   ```bash
   cat /tmp/kayak-server.log
   ```

5. 停止服务
   ```bash
   kill $SERVER_PID 2>/dev/null || true
   ```

**预期日志格式示例:**

```
2024-03-15T10:30:00.123456Z  INFO kayak_backend: Server starting on 0.0.0.0:8080
2024-03-15T10:30:00.234567Z DEBUG kayak_backend::middleware: CORS middleware initialized
2024-03-15T10:30:02.345678Z  INFO tower_http::trace: request started method=GET uri=/health
2024-03-15T10:30:02.345789Z  INFO tower_http::trace: request finished latency=1ms status=200
```

**日志格式要求:**

| 字段 | 要求 | 示例 |
|-----|------|------|
| 时间戳 | ISO 8601格式，包含微秒 | 2024-03-15T10:30:00.123456Z |
| 日志级别 | 大写，宽度对齐 | INFO, DEBUG, WARN, ERROR |
| 目标模块 | 可选，便于调试 | kayak_backend::middleware |
| 消息内容 | 清晰可读 | Server starting on ... |

**通过标准:**
- [ ] 日志包含时间戳字段（ISO 8601格式）
- [ ] 日志包含级别字段（DEBUG/INFO/WARN/ERROR）
- [ ] 至少输出一条INFO级别日志
- [ ] 日志消息清晰可读
- [ ] 错误日志（如有）包含足够上下文信息

**自动化测试脚本:**

```bash
#!/bin/bash
# TC-S1-001-03: Log Format Verification Script

set -e

PROJECT_DIR="/home/hzhou/workspace/kayak/kayak-backend"
LOG_FILE="/tmp/s1-001-log-test.log"
SERVER_PID=""

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        echo "停止服务 (PID: $SERVER_PID)..."
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
}

trap cleanup EXIT

echo "=== TC-S1-001-03: 日志输出格式验证 ==="
echo "开始时间: $(date)"

# 进入项目目录
cd "$PROJECT_DIR" || exit 1

# 清理之前的日志
rm -f "$LOG_FILE"

# 启动服务并捕获日志
echo "启动后端服务并捕获日志..."
cargo run --release > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo "服务PID: $SERVER_PID"

# 等待服务启动
sleep 3

# 发送请求触发日志
echo "发送请求触发日志记录..."
curl -s http://localhost:8080/health >/dev/null 2>&1 || true
curl -s http://localhost:8080/nonexistent >/dev/null 2>&1 || true

# 等待日志写入
sleep 2

# 停止服务以刷新日志
cleanup
SERVER_PID=""

# 分析日志
echo ""
echo "=== 日志分析 ==="
echo "日志内容:"
cat "$LOG_FILE"
echo ""

# 检查日志文件非空
if [ ! -s "$LOG_FILE" ]; then
    echo "✗ 日志文件为空"
    exit 1
fi
echo "✓ 日志文件非空"

# 检查时间戳格式 (ISO 8601)
TIMESTAMP_COUNT=$(grep -cE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+Z' "$LOG_FILE" || echo "0")
if [ "$TIMESTAMP_COUNT" -gt 0 ]; then
    echo "✓ 发现 $TIMESTAMP_COUNT 条包含ISO 8601时间戳的日志"
else
    echo "✗ 未找到符合ISO 8601格式的时间戳"
    exit 1
fi

# 检查日志级别
LEVEL_COUNT=$(grep -cE '\s(INFO|DEBUG|WARN|ERROR|TRACE)\s' "$LOG_FILE" || echo "0")
if [ "$LEVEL_COUNT" -gt 0 ]; then
    echo "✓ 发现 $LEVEL_COUNT 条包含日志级别的记录"
else
    echo "✗ 未找到标准日志级别标记"
    exit 1
fi

# 统计各级别日志数量
echo ""
echo "=== 日志级别统计 ==="
for level in INFO DEBUG WARN ERROR TRACE; do
    COUNT=$(grep -cE "\s${level}\s" "$LOG_FILE" || echo "0")
    if [ "$COUNT" -gt 0 ]; then
        echo "  $level: $COUNT 条"
    fi
done

# 检查是否包含INFO级别日志
if grep -qE '\sINFO\s' "$LOG_FILE"; then
    echo "✓ 包含INFO级别日志"
else
    echo "✗ 未找到INFO级别日志"
    exit 1
fi

# 检查启动日志
if grep -qi "starting\|started\|server" "$LOG_FILE"; then
    echo "✓ 包含服务启动相关日志"
else
    echo "⚠ 未找到服务启动相关日志（警告）"
fi

echo ""
echo "=== 测试通过 ==="
echo "结束时间: $(date)"
```

**备注:**
- 日志格式建议使用 tracing-subscriber 的 fmt 层配置
- 推荐配置：`tracing_subscriber::fmt().with_timer(time::UtcTime::rfc_3339())`
- 生产环境建议添加日志轮转配置

---

## 3. 集成测试场景

### 3.1 完整启动流程测试

**场景描述:** 验证后端服务从编译到运行的完整流程

**测试步骤:**

1. 执行 TC-S1-001-01 编译测试
2. 启动服务
3. 执行 TC-S1-001-02 健康检查测试
4. 执行 TC-S1-001-03 日志验证
5. 测试基础中间件功能

**预期结果:**
- 所有子测试用例通过
- 服务稳定运行5分钟以上无崩溃
- 内存占用稳定，无明显泄漏

---

### 3.2 CORS中间件测试

**测试ID:** TC-S1-001-04  
**测试目的:** 验证CORS中间件配置正确

**测试步骤:**
```bash
# 发送跨域预检请求
curl -s -X OPTIONS -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -w "\nHTTP_CODE:%{http_code}\n" \
     http://localhost:8080/health
```

**预期结果:**
- HTTP状态码: 204
- 响应头包含: `Access-Control-Allow-Origin`

---

### 3.3 错误处理中间件测试

**测试ID:** TC-S1-001-05  
**测试目的:** 验证错误处理和响应格式

**测试步骤:**
```bash
# 访问不存在的端点
curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost:8080/api/v1/nonexistent
```

**预期结果:**
- HTTP状态码: 404
- 响应格式为JSON（如果已实现统一错误响应格式）

---

## 4. 测试数据需求

### 4.1 环境要求

| 需求项 | 规格 |
|-------|------|
| Rust版本 | >= 1.75.0 |
| Cargo版本 | >= 1.75.0 |
| 操作系统 | Linux / macOS / Windows |
| 可用端口 | 8080 (可配置) |
| 磁盘空间 | >= 500MB |
| 内存 | >= 1GB |

### 4.2 依赖工具

| 工具 | 用途 | 安装命令 |
|-----|------|---------|
| curl | API测试 | `apt install curl` |
| bc | 数值计算 | `apt install bc` |
| python3 | JSON验证 | 通常预装 |
| lsof | 端口检查 | `apt install lsof` |

---

## 5. 缺陷报告模板

### 5.1 缺陷严重程度定义

| 级别 | 定义 | 示例 |
|-----|------|------|
| P0 (Critical) | 阻塞性问题，无法继续测试 | 编译失败、服务无法启动 |
| P1 (High) | 主要功能缺陷，有变通方案 | 健康检查返回错误状态码 |
| P2 (Medium) | 次要功能缺陷，影响用户体验 | 日志格式不规范 |
| P3 (Low) | 轻微问题，建议改进 | 警告信息过多 |

### 5.2 缺陷报告模板

```markdown
## 缺陷报告: [简要描述]

**缺陷ID**: BUG-S1-001-XX  
**关联测试用例**: TC-S1-001-XX  
**严重程度**: [P0/P1/P2/P3]  
**发现日期**: YYYY-MM-DD  
**报告人**: [姓名]

### 问题描述
[详细描述问题现象]

### 复现步骤
1. [步骤1]
2. [步骤2]
3. [步骤3]

### 预期结果
[描述预期的正确行为]

### 实际结果
[描述实际观察到的行为]

### 环境信息
- Rust版本: [版本号]
- 操作系统: [系统版本]
- 分支/提交: [commit hash]

### 附件
- [日志文件]
- [截图]
- [其他相关文件]
```

---

## 6. 测试执行记录

### 6.1 执行历史

| 日期 | 版本 | 执行人 | 结果 | 备注 |
|-----|------|-------|------|------|
| | | | | |

### 6.2 测试覆盖矩阵

| 测试ID | 描述 | 执行次数 | 通过次数 | 失败次数 | 通过率 |
|-------|------|---------|---------|---------|-------|
| TC-S1-001-01 | 项目编译验证 | 0 | 0 | 0 | - |
| TC-S1-001-02 | 健康检查接口验证 | 0 | 0 | 0 | - |
| TC-S1-001-03 | 日志输出格式验证 | 0 | 0 | 0 | - |
| TC-S1-001-04 | CORS中间件测试 | 0 | 0 | 0 | - |
| TC-S1-001-05 | 错误处理中间件测试 | 0 | 0 | 0 | - |

---

## 7. 附录

### 7.1 参考文档

- [Rust Book](https://doc.rust-lang.org/book/)
- [Axum框架文档](https://docs.rs/axum/)
- [Tracing文档](https://docs.rs/tracing/)
- [PRD文档](./prd.md)

### 7.2 修订历史

| 版本 | 日期 | 修订人 | 修订内容 |
|-----|------|-------|---------|
| 1.0 | 2024-03-15 | QA | 初始版本 |

---

**文档结束**
