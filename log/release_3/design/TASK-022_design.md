# TASK-022: 试验创建流程 — 修正设计

## 修正原因

UI 审查 `log/release_3/review/TASK-022_ui_review.md` 发现 3 个 **BLOCKING** 问题：

1. **后端 `POST /api/v1/experiments` 端点缺失** — `ExperimentService.create()` 调用的端点未在路由中注册
2. **后端 `CreateExperimentRequest` schema 简化** — 后端仅支持 `name` + `method_id` + `description`，前端需匹配
3. **路由冲突** — `/experiments/new` 在 `ShellRoute` 内，AppShell 的 BottomNavigationBar 与向导底部按钮冲突

## 修正方案

### 问题 1 & 2：添加后端 Create 端点

#### 后端：Service 层

在 `ExperimentControlService` 中新增 `create()` 方法：

```rust
pub async fn create(
    &self,
    user_id: Uuid,
    name: String,
    method_id: Option<Uuid>,
    description: Option<String>,
) -> Result<ExperimentControlDto, ExperimentControlError>
```

该方法使用 `ExperimentRepository::create()` 持久化新试验实体。不涉及工作台关联或参数存储（当前迭代暂不支持）。

#### 后端：Handler 层

在 `experiment_control.rs` 新增 `create_experiment` handler：

- 路由：`POST /api/v1/experiments`
- 请求体：`CreateExperimentRequestBody { name: String, method_id: Option<Uuid>, description: Option<String> }`
- `user_id` 从 JWT Auth 上下文自动提取

#### 后端：路由注册

在 `experiment_control_routes()` 中添加 `.route("/", post(create_experiment))`。

#### 前端：Service 层适配

前端 `CreateExperimentRequest` 已包含 `name` + `methodId` + `description`，与后端一致，**无需修改**。

### 问题 3：路由冲突修复

将 `/experiments/new` 从 `ShellRoute` 子路由列表移至**顶层路由**：

```dart
// 顶层路由（无 AppShell 包裹）
GoRoute(
  path: '/experiments/new',
  name: 'experiment-create',
  builder: (context, state) => const ExperimentCreatePage(),
),

// ShellRoute 内仅保留：
GoRoute(
  path: '/experiments',
  name: 'experiments',
  builder: (context, state) => const ExperimentListPage(),
),
GoRoute(
  path: '/experiments/:id',
  name: 'experiment-console',
  builder: (context, state) => ExperimentConsolePage(...),
),
```

## 路由设计

```
/                          → NotFoundPage (fallback)
/login                     → LoginPage          (公开)
/register                  → RegisterPage       (公开)
/experiments/new           → ExperimentCreatePage (受保护，无 AppShell)
--- ShellRoute (AppShell) ---
/dashboard                 → DashboardPage
/workbenches               → WorkbenchListPage
/workbenches/:id           → WorkbenchDetailPage
/methods                   → MethodListPage
/methods/:id/edit          → MethodEditPage
/experiments               → ExperimentListPage
/experiments/:id           → ExperimentConsolePage
/analysis                  → AnalysisPage
/settings                  → SettingsPage
```

## 后端 API 端点

| 方法 | 路径 | Handler | 描述 |
|------|------|---------|------|
| POST | `/api/v1/experiments` | `create_experiment` | 创建试验 |

### 请求体

```json
{
  "name": "My Experiment",
  "method_id": "550e8400-e29b-41d4-a716-446655440000",
  "description": "Optional description"
}
```

### 响应

```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "My Experiment",
    "status": "IDLE",
    "method_id": "550e8400-e29b-41d4-a716-446655440000",
    "description": "Optional description",
    "created_at": "2026-06-02T00:00:00Z",
    "updated_at": "2026-06-02T00:00:00Z"
  }
}
```

## 数据流

```
ExperimentCreatePage (Step 4 Confirm)
  → ExperimentService.create(CreateExperimentRequest)
    → POST /api/v1/experiments { name, method_id?, description? }
      → ExperimentControlService.create()
        → ExperimentRepository.create(&Experiment)
          → INSERT INTO experiments
      ← ExperimentControlDto ← Experiment
    ← ApiResponse<ExperimentControlDto>
  ← Experiment (returned)
  → Toast "创建成功"
  → router.go('/experiments/{id}')
```

## 影响范围

| 文件 | 变更类型 |
|------|----------|
| `kayak-backend/src/services/experiment_control/mod.rs` | 新增 `create()` 方法 |
| `kayak-backend/src/api/handlers/experiment_control.rs` | 新增 `create_experiment` handler |
| `kayak-backend/src/api/routes.rs` | 新增 POST `/` 路由 |
| `kayak-frontend/lib/router/app_router.dart` | `/experiments/new` 移出 ShellRoute |
| `log/release_3/design/TASK-022_design.md` | 本文档 |

## 验证

```bash
# 后端
cd kayak-backend && cargo build 2>&1 | head -20

# 前端
cd kayak-frontend && flutter test --exclude-tags golden && flutter analyze --fatal-infos
```
