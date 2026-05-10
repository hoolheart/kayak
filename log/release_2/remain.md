# Release 2 剩余任务清单

**版本**: 1.0  
**创建日期**: 2026-05-10  
**说明**: 本清单记录了 Release 1 `remain.md` 中定义但 Release 2 未包含的功能，将在后续 Release 中实现

---

## Release 2 范围说明

### Sprint 1 已完成（2026-05-10）
- ✅ 时序数据绘图工具（R2-ANALYSIS-001）
  - HDF5 时序数据查询 API（POST /api/v1/experiments/{id}/data/query）
  - LTTB 降采样算法（Rust 自研实现）
  - 时序图表组件（fl_chart，单/多曲线、图例、主题适配）
  - 分析页面（/analysis 路由、控制面板、图表展示区）

### Sprint 2 待完成（计划中）
- 🔵 团队管理功能（R2-TEAM-001 + R2-TEAM-003）
- 🔵 Python SDK 核心功能（R2-PYTHON-001 + R2-PYTHON-002）

Release 2 未包含的其他任务将在 Release 3 及以后实现。

---

## Release 3 建议范围（预估 4 周，2 个 Sprint）

### Sprint 1: 试验方法可视化编辑器

| 任务ID | 任务名称 | 重估工时 | 优先级 | 模拟设备需求 |
|--------|----------|----------|--------|-------------|
| R3-EDITOR-001 | 可视化流程图编辑器（基础） | 56h | P1 | 否 |
| R3-EDITOR-002 | 高级节点类型（Decision/Branch/Wait/Record/Config/Subprocess） | 48h | P1 | 否 |
| R3-EDITOR-003 | 表达式编辑器增强 | 28h | P2 | 否 |

### Sprint 2: 协议扩展（CAN/VISA + 模拟设备框架）

| 任务ID | 任务名称 | 重估工时 | 优先级 | 模拟设备需求 |
|--------|----------|----------|--------|-------------|
| R3-PROTO-003 | CAN/CAN-FD 协议驱动实现 | 58h | P2 | ✅ vcan/UDP模拟 |
| R3-PROTO-004 | VISA 协议驱动实现 | 42h | P2 | ✅ TCP模拟 |
| R3-PROTO-005 | MQTT 协议驱动实现 | 26h | P3 | ✅ rumqttd模拟 |
| R3-PROTO-UI-002 | CAN/VISA/MQTT 协议配置 UI | 16h | P2 | 否 |
| R3-EDITOR-004 | 方法模板库 | 18h | P3 | 否 |

**Release 3 总计**: ~292h | **建议周期**: 4 周（2 Sprint）

---

## Release 4 建议范围（预估 4 周，2 个 Sprint）

### Sprint 1: 数据分析高级功能

| 任务ID | 任务名称 | 重估工时 | 优先级 |
|--------|----------|----------|--------|
| R4-ANALYSIS-002 | 频谱分析（FFT） | 28h | P2 |
| R4-ANALYSIS-003 | 多类型图表支持（XY/直方图/热图） | 46h | P2 |
| R4-ANALYSIS-004 | 数据处理工具（滤波/插值/重采样） | 36h | P2 |
| R4-ANALYSIS-005 | 分析工作区（Analysis Studio） | 36h | P1 |
| R4-ANALYSIS-006 | LaTeX 图表导出 | 26h | P3 |

### Sprint 2: 部署优化与高级功能

| 任务ID | 任务名称 | 重估工时 | 优先级 |
|--------|----------|----------|--------|
| R4-TEAM-002 | 细粒度权限控制（资源级 ACL） | 28h | P2 |
| R4-DEPLOY-001 | 前后端分离容器部署 | 18h | P2 |
| R4-ADV-002 | 数据自动备份 | 18h | P2 |
| R4-ADV-004 | 通知系统 | 26h | P3 |
| R4-PERF-001 | HDF5 写入性能优化 | 36h | P2 |
| R4-PERF-002 | 前端性能优化（虚拟滚动/懒加载） | 26h | P2 |
| R4-PYTHON-003 | Python SDK 发布到 PyPI | 8h | P3 |

**Release 4 总计**: ~332h | **建议周期**: 4 周（2 Sprint）

---

## 任务统计

| Release | 主要内容 | 预估工时 | 建议周期 |
|---------|----------|----------|----------|
| Release 1 | Modbus TCP/RTU + 协议配置 UI + 设备管理 | ~185h | 4周 |
| Release 2 | 时序数据绘图 + 团队管理 + Python SDK | ~130h | 2周 |
| Release 3 | 可视化编辑器 + CAN/VISA/MQTT 协议 | ~292h | 4周 |
| Release 4 | 数据分析高级 + 部署优化 + 权限进阶 | ~332h | 4周 |
| **总计** | | **~939h** | **~14周** |

---

## 说明

1. **Release 3 协议驱动依赖模拟设备框架**：
   - 可行性评估报告 §8 建议在 Release 3 实现通用模拟设备框架
   - 框架核心实现（trait + 管理器）：8h
   - ModbusTcp/Rtu 迁移到框架：8h
   - CAN/VISA/MQTT Simulator 实现：28h
   - **框架建设总工时**: ~48h，分摊到 Release 3 Sprint 中

2. **优先级定义**: P0=必须, P1=高, P2=中, P3=低

3. **工时估算**: 基于保守估算，含设计、开发、测试、审查全流程

---

**文档结束**
