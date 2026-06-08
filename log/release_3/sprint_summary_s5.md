# Sprint 5 总结 — M8 试验执行控制台

> **Sprint**: Week 5（2026-06-02）
> **Release**: 3（Kayak 前端全面重写）
> **作者**: sw-prod (Scrum Master)

---

## 一、Sprint 目标

实现试验管理的完整端到端功能：Service/Provider 层（含 WebSocket）、试验列表、创建向导、以及核心的试验执行控制台。

---

## 二、完成情况

| 任务 | 描述 | 状态 | 关键交付物 |
|:---:|------|:----:|-----------|
| TASK-020 | 试验 Service + Provider（含 WebSocket 3.0.3） | ✅ | ExperimentService, WsService, ExperimentProvider |
| TASK-021 | 试验列表页面 UI | ✅ | ExperimentListPage, StatusBadge |
| TASK-022 | 试验创建流程 UI | ✅ | ExperimentCreatePage（4步向导）, MethodService |
| TASK-023 | 试验控制台 UI（核心页面） | ✅ | ExperimentConsolePage（~2100行） |

### Release 3 累计进度

| 指标 | Sprint 5 | 累计 |
|:---:|:--------:|:----:|
| 任务完成 | **4/4 (100%)** | **23/27 (85%)** |
| P0 完成 | 4/4 | **19/20 (95%)** |
| 代码行数（新增） | ~5,800 | ~17,500 |
| 测试总数 | 423 (前端) + 583 (后端) = **1,006** | — |

---

## 三、质量指标

### 验证结果

| 检查项 | 结果 |
|--------|:----:|
| 前端测试 | ✅ **423/423 通过** |
| 后端测试 | ✅ **583/583 通过** |
| 全量测试 | ✅ **1,006/1,006 通过** |
| `flutter analyze` | ✅ **零错误、零警告** |
| `cargo clippy -D warnings` | ✅ **零警告** |
| `flutter build web --release` | ✅ **构建成功** |

### 代码审查

| 任务 | 审查问题 | 已关闭 | 结论 |
|:---:|:--------:|:-----:|:----:|
| TASK-020 | 2 P0 + 5 P1 | 全部 | ✅ APPROVED |
| TASK-021 | 1 Critical + 3 High | 全部 | ✅ APPROVED |
| TASK-022 | 2 Critical + 1 High | 全部 | ✅ APPROVED |
| TASK-023 | 3 Critical + 3 High | 全部 | ✅ APPROVED |

### 生产 Bug

| Bug | 严重级 | 发现 | 修复 |
|:---:|:------:|:----:|:----:|
| BUG-021-01: 移动端日期选择器布局崩溃 | High | TASK-021 测试 | ✅ |
| WS 日志类型缺失 | Medium | TASK-023 设计 | ✅ 改用轮询 |

---

## 四、Sprint 5 交付成果

| 文件 | 说明 |
|------|------|
| `lib/services/experiment_service.dart` | 试验 CRUD + 控制操作 |
| `lib/services/ws_service.dart` | WebSocket 连接管理（指数退避重连） |
| `lib/widgets/status_badge.dart` | 状态标签组件 |
| `lib/pages/experiment/experiment_list_page.dart` | 试验列表（筛选、分页、响应式） |
| `lib/pages/experiment/experiment_create_page.dart` | 4 步创建向导 |
| `lib/pages/experiment/experiment_console_page.dart` | **核心页面**：控制面板+日志+WS |
| `lib/providers/experiment_provider.dart` | 列表/控制/WS Provider |
| `lib/utils/error_mapping.dart` | 共享错误映射工具 |
| 后端 `routes.rs` + `experiment_control.rs` | 新增 `POST /experiments` 端点 |

---

## 五、关键决策记录

| 决策 | 方案 | 原因 |
|------|------|------|
| WS 日志类型缺失 | REST 轮询替代 WS 推送 | 后端 WsMessage 无 log 类型 |
| 控制台无工作台名 | 简化 Info Card | Experiment 模型无 workbenchId |
| 状态筛选多选→单选 | DropdownButton | 后端仅支持单值筛选 |
| ErrorMapping 工具类 | 共享错误码映射 | 消除 Provider 间重复代码 |

---

## 六、Sprint 6（剩余任务）

| 优先级 | 任务 | 描述 | 
|:-----:|:----:|------|
| P1 | TASK-024 | M2 首页仪表盘 UI |
| P1 | TASK-025 | M7 试验方法管理 UI |
| P1 | TASK-026 | M9 数据分析与可视化（fl_chart 1.2.0） |
| P1 | TASK-027 | M10 设置页面 UI |

**Release 3 完成度：85%（23/27）**。剩余 4 个 P1 任务在 Sprint 6。

---

**下一步**: sw-camille 进行 Sprint 5 验收审查
