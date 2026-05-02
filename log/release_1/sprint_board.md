# Sprint Board - Release 1

## Sprint Information
- **Sprint Start**: 2026-05-02
- **Sprint End**: 2026-05-30 (4周，2个Sprint)
- **Total Tasks**: 24
- **Completed Tasks**: 5

---

## Backlog

| Task ID | Description | Assigned | Priority |
|---------|-------------|----------|----------|
| R2-PROTO-003 | CAN/CAN-FD协议驱动实现 | - | P2 |
| R2-PROTO-004 | VISA协议驱动实现 | - | P2 |
| R3-PROTO-005 | MQTT协议驱动实现 | - | P3 |
| R2-EDITOR-001 | 可视化流程图编辑器 | - | P1 |
| R2-EDITOR-002 | 高级节点类型支持 | - | P1 |
| R2-ANALYSIS-001 | 时序数据绘图工具 | - | P1 |
| R2-PYTHON-001 | Python SDK核心功能 | - | P2 |
| R2-TEAM-001 | 团队管理功能 | - | P1 |
| R1-S1-006 | 协议配置UI - Modbus TCP 表单（基于新设计） | sw-tom | P0 |
| R1-S1-UI-002 | Web 模式适配与主题系统重构 | sw-tom | P0 |
| R1-S1-UI-003 | 核心页面前端重构（登录页 + Dashboard + 工作台） | sw-tom | P0 |

---

## Design (UI/Architecture)

| Task ID | Description | Assigned | Status |
|---------|-------------|----------|--------|
| R1-S1-UI-001 | 全新 UI/UX 设计 - 核心页面 Figma 原型 | sw-anna | 🔵 待开始 |

---

## Development

| Task ID | Description | Assigned | Status |
|---------|-------------|----------|--------|
| R1-S1-006 | 协议配置UI - Modbus TCP 表单（基于新设计） | sw-tom | 🔵 待开始 |
| R1-S1-UI-002 | Web 模式适配与主题系统重构 | sw-tom | 🔵 待开始 |
| R1-S1-UI-003 | 核心页面前端重构（登录页 + Dashboard + 工作台） | sw-tom | 🔵 待开始 |

---

## Code Review

| Task ID | Description | Reviewer | Status |
|---------|-------------|----------|--------|
| - | - | - | - |

---

## Testing

| Task ID | Description | Tester | Status |
|---------|-------------|--------|--------|
| R1-S1-010 | Sprint 1 集成测试与编译验证 | sw-mike | 🔵 待开始 |

---

## Done

| Task ID | Description | Completed Date |
|---------|-------------|----------------|
| R1-S1-001 | DeviceManager 泛型消除重构 | 2026-05-03 |
| R1-S1-002 | Modbus 核心数据类型与错误定义 | 2026-05-03 |
| R1-S1-003 | Modbus TCP 驱动实现 | 2026-05-03 |
| R1-S1-004 | Modbus RTU 驱动实现 | 2026-05-03 |
| R1-S1-005 | 后端依赖清理（移除 5 个未使用依赖） | 2026-05-03 |

---

## Sprint 2 Tasks ( Planned )

| Task ID | Description | Assigned | Priority |
|---------|-------------|----------|----------|
| R1-S2-001 | 协议配置UI - Modbus RTU 表单与串口扫描 | sw-tom | P0 |
| R1-S2-002 | 协议配置UI - 测点配置增强 | sw-tom | P0 |
| R1-S2-003 | 设备连接测试功能 | sw-tom | P1 |
| R1-S2-004 | 协议列表与串口扫描API | sw-tom | P0 |
| R1-S2-005 | 设备连接测试API | sw-tom | P1 |
| R1-S2-006 | 模拟设备独立运行工具 | sw-tom | P1 |
| R1-S2-007 | API文档更新 (OpenAPI) | sw-tom | P1 |
| R1-S2-008 | 用户手册更新 | sw-anna | P1 |
| R1-S2-009 | 端到端集成测试 | sw-mike | P0 |
| R1-S2-010 | Sprint 2 编译验证与交付 | sw-tom | P0 |

---

## Blockers

| Task ID | Blocker Description | Blocking Tasks |
|---------|-------------------|----------------|
| Git Workflow | 所有修改都在一个分支上，需要按任务分离提交 | R1-S1-001~005 |

---

## Sprint Metrics

### Sprint 1 Progress
- **Total**: 14 tasks (含新增依赖清理)
- **Completed**: 5
- **In Progress**: 0
- **Remaining**: 9

### Sprint 2 Progress
- **Total**: 10 tasks
- **Completed**: 0
- **In Progress**: 0
- **Remaining**: 10

### Overall Release 1 Progress
- **Completion**: 21% (5/24 tasks)

---

**Last Updated**: 2026-05-03
