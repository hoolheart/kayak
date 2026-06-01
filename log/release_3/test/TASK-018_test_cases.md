# TASK-018 测试用例 — 测点列表/配置 UI

> **作者**: sw-mike (Test Engineer)
> **日期**: 2026-06-01
> **状态**: Draft — 待开发完成后执行
> **关联任务**: TASK-018（测点列表/配置 UI）
> **参考文档**: [tasks.md](../tasks.md) §TASK-019, [prd.md](../prd.md) §M6 测点管理

---

## 测试范围

TASK-018 实现设备详情面板中的测点管理 UI，包含以下组件：

| 组件 | 文件 | 角色 |
|------|------|------|
| PointListWidget | `lib/pages/point/point_list_widget.dart` | 测点列表展示（表格/卡片） |
| PointFormDialog | `lib/pages/point/point_form_dialog.dart` | 添加/编辑测点对话框 |
| PointValueDisplay | `lib/pages/point/point_value_display.dart` | 测点实时值显示 |
| WorkbenchDetailPage | `lib/pages/workbench/workbench_detail_page.dart` | 集成测点列表到设备详情面板 |

---

## 依赖组件与 API

### 后端 API

| API | 方法 | 说明 |
|-----|------|------|
| `GET /api/v1/points?device_id={id}` | GET | 设备下测点列表 |
| `POST /api/v1/points` | POST | 添加测点 |
| `GET /api/v1/points/{id}` | GET | 测点详情 |
| `PUT /api/v1/points/{id}` | PUT | 更新测点 |
| `DELETE /api/v1/points/{id}` | DELETE | 删除测点 |
| `GET /api/v1/points/{id}/value` | GET | 读取测点值 |

### 数据模型

| 模型 | 文件 | 关键字段 |
|------|------|----------|
| Point | `lib/models/point.dart` | id, deviceId, name, dataType, accessType, unit, minValue, maxValue, status |
| PointValue | `lib/models/point.dart` | pointId, value, timestamp |
| DataType | `lib/models/point.dart` | number, integer, string, boolean |
| AccessType | `lib/models/point.dart` | ro, wo, rw |

### 已有基础设施

| 组件 | 文件 | 说明 |
|------|------|------|
| PointListNotifier | `lib/providers/point_provider.dart` | 测点列表状态管理 |
| PointService | `lib/services/point_service.dart` | 测点 API 封装 |
| ConfirmDialog | `lib/widgets/confirm_dialog.dart` | 二次确认对话框 |
| Toast | `lib/widgets/toast.dart` | Toast 通知 |
| AppLocalizations | `generated/app_localizations.dart` | 国际化 |

---

## 一、PointListWidget 测试用例（16 项）

### TC-PL-001: 加载状态显示骨架行

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 加载状态 |
| **关联验收标准** | PRD §M6-4: 加载状态表格骨架行 |

**前置条件**：
- 设备 `dev-1` 已存在
- `pointListProvider('dev-1')` 返回 `AsyncLoading()` 状态

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待 widget 构建完成

**预期结果**：
- ✅ 显示 5 行骨架行（每行包含名称、类型、访问权限、单位、当前值、操作列的占位）
- ✅ 显示脉冲动画占位行（Skeleton 风格）
- ✅ 不显示"共 N 个测点"文本
- ✅ 不显示"+ 添加测点"按钮（或按钮显示为禁用状态）
- ✅ 不显示空状态引导

---

### TC-PL-002: 空数据状态显示引导

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-002 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 空状态 |
| **关联验收标准** | PRD §M6-3: 空状态"该设备下暂无测点" |

**前置条件**：
- 设备 `dev-1` 已存在
- `pointListProvider('dev-1')` 返回 `AsyncData([])`（空列表）

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待数据加载完成

**预期结果**：
- ✅ 显示空状态图标（`Icons.point_of_sale_outlined` 或类似图标）
- ✅ 显示文本 `l10n.pointListEmpty`（"该设备下暂无测点"）
- ✅ 显示"添加第一个测点"按钮（`FilledButton`）
- ✅ 不显示表格头部
- ✅ 不显示骨架行
- ✅ 顶部显示"共 0 个测点"

---

### TC-PL-003: 有数据时表格正确显示所有列

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-003 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 数据展示 |
| **关联验收标准** | PRD §M6-1: 表格形式展示所有测点 |

**前置条件**：
- 设备 `dev-1` 已存在
- 返回 3 个测点：
  - `pt-1`: 温度传感器, Number, RO, °C, 25.3
  - `pt-2`: 阀门状态, Boolean, RW, null, true
  - `pt-3`: 压力值, Integer, RO, MPa, 101

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待数据加载完成

**预期结果**：
- ✅ 顶部显示"共 3 个测点"
- ✅ 显示"+ 添加测点"按钮（`FilledButton`，可用状态）
- ✅ 表格包含 6 列：名称、类型、访问权限、单位、当前值、操作
- ✅ 第 1 行：温度传感器 | Number（蓝色标签）| RO（眼睛图标）| °C | 25.3 °C | 编辑/删除
- ✅ 第 2 行：阀门状态 | Boolean（绿色标签）| RW（双向箭头图标）| — | 开启（布尔值转文本）| 编辑/删除
- ✅ 第 3 行：压力值 | Integer（紫色标签）| RO | MPa | 101 MPa | 编辑/删除
- ✅ 类型标签颜色区分：Number-蓝、Integer-紫、Boolean-绿、String-橙
- ✅ 当前值列包含数值和单位（如单位存在）

---

### TC-PL-004: 点击"+ 添加测点"按钮弹出 PointFormDialog

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-004 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 添加操作 |
| **关联验收标准** | PRD §M6: 添加/编辑测点对话框 |

**前置条件**：
- 设备 `dev-1` 已存在
- 测点列表已加载（有数据或无数据均可）

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 点击顶部"+ 添加测点"按钮
3. 等待对话框动画完成

**预期结果**：
- ✅ 弹出 `PointFormDialog`（对话框标题为"添加测点"）
- ✅ 对话框为添加模式（`isEdit: false`）
- ✅ 表单所有字段为空/默认值
- ✅ 设备 ID 被传递到对话框（`deviceId: 'dev-1'`）

---

### TC-PL-005: 点击"编辑"按钮弹出预填数据的 PointFormDialog

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 编辑操作 |
| **关联验收标准** | PRD §M6: 编辑测点 |

**前置条件**：
- 设备 `dev-1` 已存在
- 测点 `pt-1`（温度传感器, Number, RO, °C）已存在

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待数据加载完成
3. 点击第 1 行"编辑"图标按钮
4. 等待对话框动画完成

**预期结果**：
- ✅ 弹出 `PointFormDialog`（对话框标题为"编辑测点"）
- ✅ 对话框为编辑模式（`isEdit: true`）
- ✅ 名称字段预填"温度传感器"
- ✅ 数据类型下拉选中"Number"
- ✅ 访问权限下拉选中"RO"
- ✅ 单位字段预填"°C"
- ✅ 测点 ID 被传递到对话框（`pointId: 'pt-1'`）

---

### TC-PL-006: 点击"删除"按钮弹出 ConfirmDialog 二次确认

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-006 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 删除操作 |
| **关联验收标准** | PRD §M6: 删除测点二次确认 |

**前置条件**：
- 设备 `dev-1` 已存在
- 测点 `pt-1`（温度传感器）已存在

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待数据加载完成
3. 点击第 1 行"删除"图标按钮

**预期结果**：
- ✅ 弹出 `ConfirmDialog`
- ✅ 对话框标题包含测点名称："确定要删除测点「温度传感器」吗？"
- ✅ 描述文本："此操作不可撤销。"
- ✅ 确认按钮为危险样式（红色背景）
- ✅ 确认按钮文本为"删除"
- ✅ 取消按钮可用

---

### TC-PL-007: 删除确认后执行删除并刷新列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 删除流程 |
| **关联验收标准** | PRD §M6: 删除测点后刷新列表 |

**前置条件**：
- 设备 `dev-1` 已存在
- 测点 `pt-1`（温度传感器）已存在
- Mock `PointService.delete('pt-1')` 返回成功

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待数据加载完成
3. 点击"删除"按钮
4. 在 ConfirmDialog 中点击"删除"确认

**预期结果**：
- ✅ 调用 `PointService.delete('pt-1')`
- ✅ ConfirmDialog 关闭
- ✅ 显示 Toast：`l10n.pointDeleteSuccess`（"测点已删除"）
- ✅ 测点列表自动刷新（重新调用 `listByDevice`）
- ✅ 列表中不再显示"温度传感器"
- ✅ 如果删除后列表为空，显示空状态引导

---

### TC-PL-008: 删除操作失败显示错误 Toast

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-008 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointListWidget / 错误处理 |
| **关联验收标准** | PRD §M6: 错误状态正确 |

**前置条件**：
- 设备 `dev-1` 已存在
- 测点 `pt-1` 已存在
- Mock `PointService.delete('pt-1')` 抛出异常："测点正在使用中，无法删除"

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待数据加载完成
3. 点击"删除"按钮
4. 在 ConfirmDialog 中点击"删除"确认

**预期结果**：
- ✅ ConfirmDialog 关闭
- ✅ 显示 Toast：`ToastType.error`，消息为错误详情"测点正在使用中，无法删除"
- ✅ 测点列表不刷新（保持原数据）
- ✅ "温度传感器"仍在列表中

---

### TC-PL-009: 小屏（<600px）表格转为卡片列表

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-009 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 响应式布局 |
| **关联验收标准** | PRD §M6: 小屏表格转卡片列表 |

**前置条件**：
- 设备 `dev-1` 已存在
- 返回 2 个测点
- 屏幕宽度设置为 375px（iPhone SE 尺寸）

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 设置屏幕宽度为 375px
3. 等待数据加载完成

**预期结果**：
- ✅ 不显示表格头部（行标题）
- ✅ 每个测点显示为独立卡片（`Card` 或 `Container` 带边框）
- ✅ 卡片内显示：名称（大字号）、类型标签、访问权限图标、单位、当前值
- ✅ 卡片内包含操作按钮：编辑、删除（图标按钮或文字按钮）
- ✅ 卡片垂直排列，有适当间距
- ✅ 顶部仍显示"共 N 个测点"和"+ 添加测点"按钮

---

### TC-PL-010: 大屏（≥1024px）显示完整表格

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-010 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointListWidget / 响应式布局 |
| **关联验收标准** | PRD §M6: 表格形式展示 |

**前置条件**：
- 设备 `dev-1` 已存在
- 返回 3 个测点
- 屏幕宽度设置为 1440px

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 设置屏幕宽度为 1440px
3. 等待数据加载完成

**预期结果**：
- ✅ 显示完整表格（`DataTable` 或自定义表格布局）
- ✅ 表格列：名称、类型、访问权限、单位、当前值、操作
- ✅ 列宽合理分配（名称最宽，操作最窄）
- ✅ 表格行有 hover 效果（背景色变化）
- ✅ 表格内容对齐正确（文本左对齐，标签居中）

---

### TC-PL-011: 测点列表加载失败显示错误视图

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-011 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointListWidget / 错误状态 |
| **关联验收标准** | PRD §M6: 错误状态正确 |

**前置条件**：
- 设备 `dev-1` 已存在
- `pointListProvider('dev-1')` 返回 `AsyncError('网络连接超时')`

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`

**预期结果**：
- ✅ 显示错误图标（`Icons.error_outline`）
- ✅ 显示错误消息"网络连接超时"
- ✅ 显示"重试"按钮
- ✅ 点击"重试"按钮重新加载测点列表
- ✅ 不显示骨架行
- ✅ 不显示空状态

---

### TC-PL-012: 点击"添加第一个测点"按钮弹出对话框

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-012 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 空状态操作 |
| **关联验收标准** | PRD §M6-3: 空状态"添加第一个测点"按钮 |

**前置条件**：
- 设备 `dev-1` 已存在
- 测点列表为空

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待空状态显示
3. 点击"添加第一个测点"按钮

**预期结果**：
- ✅ 弹出 `PointFormDialog`（添加模式）
- ✅ 行为与 TC-PL-004 一致

---

### TC-PL-013: 实时值自动刷新

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-013 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointListWidget / 实时值 |
| **关联验收标准** | PRD §M6-2: 当前值每隔一定时间自动刷新 |

**前置条件**：
- 设备 `dev-1` 已存在
- 测点 `pt-1` 初始值为 25.3
- 自动刷新间隔为 5 秒

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待初始数据加载
3. 使用 fakeAsync 推进 5 秒（自动刷新间隔）

**预期结果**：
- ✅ 初始显示值 25.3
- ✅ 5 秒后自动调用 `getValue('pt-1')`
- ✅ 新值显示在对应行（如值变为 26.1）
- ✅ 值变化时有视觉反馈（可选：数值颜色闪烁或过渡动画）

---

### TC-PL-014: 测点值显示状态指示 — 正常/超时/异常

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-014 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointListWidget / 状态指示 |
| **关联验收标准** | PRD §M6: 数值旁边显示状态指示 |

**前置条件**：
- 设备 `dev-1` 已存在
- 返回 3 个测点，各对应不同状态：
  - `pt-1`: status = 'normal'
  - `pt-2`: status = 'timeout'
  - `pt-3`: status = 'error'

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待数据加载完成

**预期结果**：
- ✅ 第 1 行（normal）：当前值旁显示灰色圆点图标
- ✅ 第 2 行（timeout）：当前值旁显示橙色圆点图标
- ✅ 第 3 行（error）：当前值旁显示红色圆点图标
- ✅ 状态图标有 tooltip 说明（"正常"/"超时"/"异常"）

---

### TC-PL-015: 大量测点滚动性能

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-015 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | PointListWidget / 性能 |
| **关联验收标准** | 通用性能要求 |

**前置条件**：
- 设备 `dev-1` 已存在
- 返回 100 个测点

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 等待数据加载完成
3. 快速滚动到列表底部

**预期结果**：
- ✅ 列表滚动流畅，无卡顿
- ✅ 使用 `ListView.builder` 实现懒加载
- ✅ 帧率保持在 60fps 以上

---

### TC-PL-016: 添加测点后列表自动刷新

| 属性 | 内容 |
|------|------|
| **ID** | TC-PL-016 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointListWidget / 数据同步 |
| **关联验收标准** | PRD §M6: 添加/编辑/删除操作可用 |

**前置条件**：
- 设备 `dev-1` 已存在
- 初始有 2 个测点
- 成功添加新测点 `pt-new`（温度传感器 2）

**测试步骤**：
1. 渲染 `PointListWidget(deviceId: 'dev-1')`
2. 点击"+ 添加测点"
3. 在对话框中填写信息并保存
4. 等待保存完成

**预期结果**：
- ✅ 对话框关闭
- ✅ 显示 Toast：`l10n.pointSaveSuccess`（"测点已保存"）
- ✅ 列表自动刷新
- ✅ 新测点"温度传感器 2"出现在列表中
- ✅ 顶部计数更新为"共 3 个测点"

---

## 二、PointFormDialog 测试用例（14 项）

### TC-PF-001: 添加模式 — 表单字段默认值

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 添加模式 |
| **关联验收标准** | PRD §M6: 添加测点对话框 |

**前置条件**：
- 设备 `dev-1`（Virtual 协议）
- 对话框以添加模式打开（`isEdit: false`）

**测试步骤**：
1. 打开 `PointFormDialog(deviceId: 'dev-1', isEdit: false)`
2. 检查各字段初始状态

**预期结果**：
- ✅ 名称字段：空文本，有"必填"提示标签
- ✅ 数据类型下拉：默认选中第一项（Number）
- ✅ 访问权限下拉：默认选中 RO
- ✅ 单位字段：空文本，无必填标记
- ✅ 最小值字段：空文本，无必填标记
- ✅ 最大值字段：空文本，无必填标记
- ✅ 默认值字段：空文本，无必填标记
- ✅ Virtual 设备不显示 Modbus 配置区域
- ✅ 保存按钮：禁用状态（因为名称为空）

---

### TC-PF-002: 名称为空时保存按钮禁用

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-002 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 表单验证 |
| **关联验收标准** | PRD §M6-1: 名称必填 |

**前置条件**：
- 设备 `dev-1` 已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog`
2. 保持名称字段为空
3. 填写其他字段（数据类型、访问权限等）
4. 检查保存按钮状态

**预期结果**：
- ✅ 保存按钮保持禁用状态
- ✅ 名称字段下方显示验证错误：`l10n.pointNameRequired`（"请输入测点名称"）
- ✅ 表单不提交

---

### TC-PF-003: 名称超过 255 字符时验证拦截

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-003 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 表单验证 |
| **关联验收标准** | PRD §M6-1: 名称最长 255 字符 |

**前置条件**：
- 设备 `dev-1` 已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog`
2. 在名称字段输入 256 个字符的字符串
3. 尝试点击保存按钮

**预期结果**：
- ✅ 名称字段下方显示验证错误：`l10n.pointNameTooLong`（"名称不能超过 255 个字符"）
- ✅ 保存按钮禁用或点击无效
- ✅ 表单不提交
- ✅ 输入框有字符计数器（255/255）或等效提示

---

### TC-PF-004: 选择不同数据类型 — 下拉选项正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-004 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 数据类型选择 |
| **关联验收标准** | PRD §M6-2: 数据类型选择 |

**前置条件**：
- 设备 `dev-1` 已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog`
2. 点击数据类型下拉框
3. 依次选择每个选项

**预期结果**：
- ✅ 下拉框包含 4 个选项：
  - Number（浮点数）
  - Integer（整数）
  - Boolean（布尔值）
  - String（字符串）
- ✅ 每个选项显示正确的本地化文本
- ✅ 选择后下拉框关闭，显示选中项
- ✅ 表单状态更新

---

### TC-PF-005: 选择不同访问权限 — 下拉选项正确

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 访问权限选择 |
| **关联验收标准** | PRD §M6-2: 访问权限选择 |

**前置条件**：
- 设备 `dev-1` 已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog`
2. 点击访问权限下拉框
3. 依次选择每个选项

**预期结果**：
- ✅ 下拉框包含 3 个选项：
  - RO（只读）
  - WO（只写）
  - RW（读写）
- ✅ 每个选项显示正确的本地化文本和图标
- ✅ 选择后下拉框关闭，显示选中项
- ✅ 表单状态更新

---

### TC-PF-006: 单位、取值范围、描述为选填

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-006 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 选填字段 |
| **关联验收标准** | PRD §M6-2: 单位/取值范围/描述选填 |

**前置条件**：
- 设备 `dev-1` 已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog`
2. 填写名称（必填）："温度传感器"
3. 保持单位、最小值、最大值、默认值为空
4. 点击保存

**预期结果**：
- ✅ 保存按钮在填写名称后变为可用
- ✅ 表单验证通过
- ✅ 调用 `PointService.create(...)`，参数中 unit/minValue/maxValue/defaultValue 为 null
- ✅ API 调用成功，对话框关闭

---

### TC-PF-007: Modbus 设备额外显示寄存器类型、起始地址、数据格式

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / Modbus 配置 |
| **关联验收标准** | PRD §M6-2: Modbus 设备额外显示 |

**前置条件**：
- 设备 `dev-modbus`（ProtocolType.modbusTcp）已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog(deviceId: 'dev-modbus')`
2. 检查表单字段
3. 点击 Modbus 配置区域的各下拉框

**预期结果**：
- ✅ 表单底部显示"Modbus 配置"区域（带分隔线或标题）
- ✅ 寄存器类型下拉包含 4 个选项：
  - Coil
  - Discrete Input
  - Holding Register
  - Input Register
- ✅ 起始地址输入框：数字输入，范围 0-65535，默认空
- ✅ 数据格式下拉包含选项：uint16, int16, float32, uint32, int32 等
- ✅ Modbus 字段均为必填（有*标记）
- ✅ 保存按钮在 Modbus 字段未填时禁用

---

### TC-PF-008: 保存成功 → 关闭对话框 → Toast "测点已保存"

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-008 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 保存成功 |
| **关联验收标准** | PRD §M6: 添加/编辑测点成功反馈 |

**前置条件**：
- 设备 `dev-1` 已存在
- Mock `PointService.create(...)` 返回新创建的 Point 对象

**测试步骤**：
1. 打开 `PointFormDialog`（添加模式）
2. 填写名称："温度传感器"
3. 数据类型：Number
4. 访问权限：RO
5. 单位：°C
6. 点击保存

**预期结果**：
- ✅ 显示加载状态（保存按钮显示 CircularProgressIndicator）
- ✅ 调用 `PointService.create(...)`
- ✅ API 返回成功
- ✅ 对话框关闭（`Navigator.pop`）
- ✅ 显示 Toast：`l10n.pointSaveSuccess`（"测点已保存"），类型为 `ToastType.success`
- ✅ 回调通知父组件刷新列表

---

### TC-PF-009: 保存失败（网络错误）→ 显示友好错误消息 + 对话框不关闭

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-009 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointFormDialog / 错误处理 |
| **关联验收标准** | PRD §M6: 保存失败处理 |

**前置条件**：
- 设备 `dev-1` 已存在
- Mock `PointService.create(...)` 抛出异常："网络连接失败"

**测试步骤**：
1. 打开 `PointFormDialog`（添加模式）
2. 填写名称："温度传感器"
3. 点击保存

**预期结果**：
- ✅ 显示加载状态
- ✅ 调用 `PointService.create(...)`
- ✅ API 返回错误
- ✅ 对话框**不关闭**
- ✅ 保存按钮恢复为可用状态
- ✅ 表单下方显示错误消息："网络连接失败"
- ✅ 用户输入数据保留（不丢失）

---

### TC-PF-010: 编辑模式预填现有值

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-010 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 编辑模式 |
| **关联验收标准** | PRD §M6: 编辑测点预填数据 |

**前置条件**：
- 测点 `pt-1` 已存在，字段值：
  - name: "温度传感器"
  - dataType: DataType.number
  - accessType: AccessType.ro
  - unit: "°C"
  - minValue: -50.0
  - maxValue: 150.0
  - defaultValue: "25.0"
- Mock `PointService.getById('pt-1')` 返回上述数据

**测试步骤**：
1. 打开 `PointFormDialog(pointId: 'pt-1', isEdit: true)`
2. 等待数据加载
3. 检查各字段值

**预期结果**：
- ✅ 对话框标题为"编辑测点"
- ✅ 名称字段："温度传感器"
- ✅ 数据类型下拉：Number
- ✅ 访问权限下拉：RO
- ✅ 单位字段："°C"
- ✅ 最小值字段："-50.0"
- ✅ 最大值字段："150.0"
- ✅ 默认值字段："25.0"
- ✅ 保存按钮初始为禁用状态（数据未改变）

---

### TC-PF-011: 编辑模式修改后保存

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-011 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointFormDialog / 编辑保存 |
| **关联验收标准** | PRD §M6: 编辑测点保存 |

**前置条件**：
- 测点 `pt-1` 已存在
- 编辑模式已打开，预填数据已加载
- Mock `PointService.update('pt-1', ...)` 返回更新后的 Point

**测试步骤**：
1. 打开编辑对话框
2. 修改名称为"温度传感器（更新）"
3. 修改单位为"K"
4. 点击保存

**预期结果**：
- ✅ 调用 `PointService.update('pt-1', {'name': '温度传感器（更新）', 'unit': 'K'})`
- ✅ API 返回成功
- ✅ 对话框关闭
- ✅ 显示 Toast：`l10n.pointSaveSuccess`（"测点已保存"）
- ✅ 回调通知父组件刷新列表

---

### TC-PF-012: 取值范围验证 — 最小值大于最大值

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-012 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointFormDialog / 表单验证 |
| **关联验收标准** | 通用表单验证 |

**前置条件**：
- 设备 `dev-1` 已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog`
2. 填写名称："温度传感器"
3. 最小值：100
4. 最大值：0
5. 点击保存

**预期结果**：
- ✅ 最大值字段下方显示验证错误：`l10n.pointRangeInvalid`（"最大值必须大于最小值"）
- ✅ 保存按钮禁用
- ✅ 表单不提交

---

### TC-PF-013: 起始地址范围验证 — 0-65535

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-013 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointFormDialog / Modbus 验证 |
| **关联验收标准** | PRD §M6-2: 起始地址 0-65535 |

**前置条件**：
- 设备 `dev-modbus`（Modbus TCP）已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog(deviceId: 'dev-modbus')`
2. 填写名称："温度传感器"
3. 寄存器类型：Holding Register
4. 起始地址：65536（超出范围）
5. 数据格式：uint16
6. 点击保存

**预期结果**：
- ✅ 起始地址字段下方显示验证错误：`l10n.pointAddressRange`（"起始地址必须在 0-65535 之间"）
- ✅ 保存按钮禁用
- ✅ 表单不提交

---

### TC-PF-014: 取消操作关闭对话框不保存

| 属性 | 内容 |
|------|------|
| **ID** | TC-PF-014 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointFormDialog / 取消操作 |
| **关联验收标准** | 通用交互规范 |

**前置条件**：
- 设备 `dev-1` 已存在
- 对话框以添加模式打开

**测试步骤**：
1. 打开 `PointFormDialog`
2. 填写名称："温度传感器"
3. 点击"取消"按钮

**预期结果**：
- ✅ 对话框关闭
- ✅ 不调用 `PointService.create`
- ✅ 不显示 Toast
- ✅ 父组件不刷新列表

---

## 三、PointValueDisplay 测试用例（8 项）

### TC-PV-001: 显示数值 + 单位（格式化为合理精度）

| 属性 | 内容 |
|------|------|
| **ID** | TC-PV-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointValueDisplay / 数值显示 |
| **关联验收标准** | PRD §M6: 实时数值显示 |

**前置条件**：
- 测点 `pt-1`（DataType.number, unit: "°C"）
- Mock `getValue('pt-1')` 返回 `PointValue(value: 25.3256, timestamp: '2026-06-01T10:00:00Z')`

**测试步骤**：
1. 渲染 `PointValueDisplay(pointId: 'pt-1', dataType: DataType.number, unit: '°C')`
2. 等待数据加载

**预期结果**：
- ✅ 显示格式化后的数值："25.33"（保留 2 位小数）
- ✅ 显示单位："°C"
- ✅ 完整显示："25.33 °C"
- ✅ Number 类型默认保留 2 位小数

---

### TC-PV-002: 不同数据类型的格式化

| 属性 | 内容 |
|------|------|
| **ID** | TC-PV-002 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointValueDisplay / 类型格式化 |
| **关联验收标准** | PRD §M6: 正确解析和显示数据 |

**前置条件**：
- 各类型测点已存在

**测试步骤**：
1. 渲染各类型 PointValueDisplay：
   - Number: value = 25.3256
   - Integer: value = 101
   - Boolean: value = true
   - String: value = "Running"

**预期结果**：
- ✅ Number: "25.33"（2 位小数）
- ✅ Integer: "101"（无小数）
- ✅ Boolean: "开启"（本地化布尔文本）或 "true"
- ✅ String: "Running"（原样显示）

---

### TC-PV-003: 状态指示 — 正常（灰色图标）

| 属性 | 内容 |
|------|------|
| **ID** | TC-PV-003 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointValueDisplay / 状态指示 |
| **关联验收标准** | PRD §M6: 状态指示：正常（灰色） |

**前置条件**：
- 测点 `pt-1` status = 'normal'
- 值已加载

**测试步骤**：
1. 渲染 `PointValueDisplay(pointId: 'pt-1', status: 'normal')`
2. 等待数据加载

**预期结果**：
- ✅ 数值旁显示灰色圆点图标（`Icons.circle`，`colorScheme.onSurfaceVariant`）
- ✅ Tooltip 显示"正常"
- ✅ 数值以正常颜色显示

---

### TC-PV-004: 状态指示 — 超时（橙色图标）

| 属性 | 内容 |
|------|------|
| **ID** | TC-PV-004 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointValueDisplay / 状态指示 |
| **关联验收标准** | PRD §M6: 状态指示：超时（橙色） |

**前置条件**：
- 测点 `pt-1` status = 'timeout'

**测试步骤**：
1. 渲染 `PointValueDisplay(pointId: 'pt-1', status: 'timeout')`

**预期结果**：
- ✅ 数值旁显示橙色圆点图标（`colorScheme.tertiary` 或 `Colors.orange`）
- ✅ Tooltip 显示"超时"
- ✅ 数值可能显示为"—"或最后已知值（带灰色）

---

### TC-PV-005: 状态指示 — 异常（红色图标）

| 属性 | 内容 |
|------|------|
| **ID** | TC-PV-005 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointValueDisplay / 状态指示 |
| **关联验收标准** | PRD §M6: 状态指示：异常（红色） |

**前置条件**：
- 测点 `pt-1` status = 'error'

**测试步骤**：
1. 渲染 `PointValueDisplay(pointId: 'pt-1', status: 'error')`

**预期结果**：
- ✅ 数值旁显示红色圆点图标（`colorScheme.error`）
- ✅ Tooltip 显示"异常"
- ✅ 数值显示为"—"或错误提示

---

### TC-PV-006: "刷新"按钮点击后调用 API 刷新数值

| 属性 | 内容 |
|------|------|
| **ID** | TC-PV-006 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | PointValueDisplay / 手动刷新 |
| **关联验收标准** | PRD §M6: 支持手动"刷新"按钮 |

**前置条件**：
- 测点 `pt-1` 已存在
- 初始值：25.3
- Mock `getValue('pt-1')` 第一次返回 25.3，第二次返回 26.1

**测试步骤**：
1. 渲染 `PointValueDisplay(pointId: 'pt-1')`
2. 等待初始值加载（显示 25.3）
3. 点击"刷新"按钮（`Icons.refresh`）

**预期结果**：
- ✅ 点击后显示加载状态（按钮旋转动画或骨架占位）
- ✅ 调用 `PointService.getValue('pt-1')`
- ✅ 新值 26.1 显示
- ✅ 刷新按钮恢复为正常状态

---

### TC-PV-007: 加载中显示数值为骨架占位

| 属性 | 内容 |
|------|------|
| **ID** | TC-PV-007 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointValueDisplay / 加载状态 |
| **关联验收标准** | 通用三态要求 |

**前置条件**：
- 测点 `pt-1` 已存在
- Mock `getValue('pt-1')` 延迟 2 秒返回

**测试步骤**：
1. 渲染 `PointValueDisplay(pointId: 'pt-1')`
2. 在 2 秒内检查显示状态

**预期结果**：
- ✅ 显示骨架占位（灰色脉冲矩形，宽度约 60px，高度约 16px）
- ✅ 不显示数值
- ✅ 不显示单位
- ✅ 状态图标区域也显示骨架或隐藏

---

### TC-PV-008: 网络错误显示 "—" 和错误提示

| 属性 | 内容 |
|------|------|
| **ID** | TC-PV-008 |
| **优先级** | **P1 — HIGH** |
| **类别** | PointValueDisplay / 错误状态 |
| **关联验收标准** | 通用三态要求 |

**前置条件**：
- 测点 `pt-1` 已存在
- Mock `getValue('pt-1')` 抛出异常："连接超时"

**测试步骤**：
1. 渲染 `PointValueDisplay(pointId: 'pt-1')`
2. 等待请求完成

**预期结果**：
- ✅ 数值显示为"—"（破折号）
- ✅ 状态图标显示为灰色或错误样式
- ✅ Tooltip 显示错误信息"连接超时"
- ✅ 显示"刷新"按钮，允许用户重试

---

## 四、WorkbenchDetailPage 集成测试用例（8 项）

### TC-WD-001: 未选中设备时详情面板显示占位引导

| 属性 | 内容 |
|------|------|
| **ID** | TC-WD-001 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailPage / 设备选择 |
| **关联验收标准** | PRD §M6: 设备详情面板占位 |

**前置条件**：
- 工作台 `wb-1` 已存在
- 设备树已加载
- 未选中任何设备（`_selectedDeviceId == null`）

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 等待页面加载完成
3. 不点击任何设备

**预期结果**：
- ✅ 右侧详情面板显示占位视图
- ✅ 显示图标（`Icons.memory`，48px）
- ✅ 显示标题：`l10n.deviceDetail`（"设备详情"）
- ✅ 显示提示文本：`l10n.deviceDetailPlaceholder`（"从左侧选择设备查看详情"）
- ✅ 不显示测点列表
- ✅ 不显示协议参数

---

### TC-WD-002: 选中设备后显示完整设备详情

| 属性 | 内容 |
|------|------|
| **ID** | TC-WD-002 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailPage / 设备详情 |
| **关联验收标准** | PRD §M6: 设备详情面板完整展示 |

**前置条件**：
- 工作台 `wb-1` 已存在
- 设备 `dev-1`（Virtual）已存在
- 设备有 2 个测点

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 等待页面加载
3. 在设备树中点击 `dev-1`

**预期结果**：
- ✅ 设备树中 `dev-1` 高亮显示
- ✅ 右侧详情面板切换到设备详情视图
- ✅ 显示设备信息区：协议图标、名称、状态标签、协议类型
- ✅ 显示协议参数（Virtual 设备可能无参数或显示占位）
- ✅ 显示"测点列表"标题（通过 l10n）
- ✅ 显示 `PointListWidget`（嵌入的测点列表）
- ✅ 测点列表显示 2 个测点

---

### TC-WD-003: 测点列表所有文本来自 l10n（无硬编码）

| 属性 | 内容 |
|------|------|
| **ID** | TC-WD-003 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailPage / 国际化 |
| **关联验收标准** | PRD §9: 国际化要求 |

**前置条件**：
- 应用设置为中文环境（`locale: zh`）
- 工作台 `wb-1`、设备 `dev-1` 已存在
- 测点列表有数据

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 点击设备 `dev-1`
3. 检查所有可见文本

**预期结果**：
- ✅ "测点列表"标题来自 `l10n.pointListTitle`
- ✅ "共 N 个测点"来自 `l10n.pointCount(N)`
- ✅ "+ 添加测点"按钮来自 `l10n.addPoint`
- ✅ "编辑"按钮 tooltip 来自 `l10n.edit`
- ✅ "删除"按钮 tooltip 来自 `l10n.delete`
- ✅ 空状态文本来自 `l10n.pointListEmpty`
- ✅ "添加第一个测点"按钮来自 `l10n.addFirstPoint`
- ✅ 无硬编码中文字符串（除 arb 文件外）
- ✅ 无硬编码英文占位符

---

### TC-WD-004: 设备详情加载中显示骨架屏

| 属性 | 内容 |
|------|------|
| **ID** | TC-WD-004 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailPage / 加载状态 |
| **关联验收标准** | PRD §M6: 加载状态骨架行 |

**前置条件**：
- 工作台 `wb-1` 已存在
- 设备 `dev-1` 已存在
- `deviceDetailProvider('dev-1')` 返回 `AsyncLoading()`

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 点击设备 `dev-1`
3. 等待设备详情加载

**预期结果**：
- ✅ 右侧详情面板显示骨架屏
- ✅ 设备信息区显示骨架占位（图标、名称、状态）
- ✅ 协议参数区显示骨架占位
- ✅ 测点列表区显示骨架占位（5 行）
- ✅ 有脉冲动画效果

---

### TC-WD-005: 设备详情加载失败显示错误视图

| 属性 | 内容 |
|------|------|
| **ID** | TC-WD-005 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailPage / 错误状态 |
| **关联验收标准** | PRD §M6: 错误状态正确 |

**前置条件**：
- 工作台 `wb-1` 已存在
- 设备 `dev-1` 已存在
- `deviceDetailProvider('dev-1')` 返回 `AsyncError('设备不存在')`

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 点击设备 `dev-1`

**预期结果**：
- ✅ 右侧详情面板显示错误视图
- ✅ 显示错误图标
- ✅ 显示错误消息"设备不存在"
- ✅ 显示"重试"按钮
- ✅ 点击"重试"重新加载设备详情

---

### TC-WD-006: 选中 Modbus 设备显示协议参数和 Modbus 测点配置

| 属性 | 内容 |
|------|------|
| **ID** | TC-WD-006 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailPage / Modbus 设备 |
| **关联验收标准** | PRD §M6: Modbus 测点有额外配置字段 |

**前置条件**：
- 工作台 `wb-1` 已存在
- 设备 `dev-modbus`（Modbus TCP）已存在
- protocolParams: `{host: '192.168.1.100', port: 502}`
- 有 1 个 Modbus 测点

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 点击设备 `dev-modbus`

**预期结果**：
- ✅ 设备信息区显示 Modbus TCP 协议图标（`Icons.lan`）
- ✅ 显示协议类型标签"Modbus TCP"
- ✅ 协议参数区显示 host 和 port
- ✅ 测点列表显示 Modbus 测点
- ✅ 点击"添加测点"后，对话框显示 Modbus 配置区域

---

### TC-WD-007: 添加测点后列表自动刷新

| 属性 | 内容 |
|------|------|
| **ID** | TC-WD-007 |
| **优先级** | **P0 — CRITICAL** |
| **类别** | WorkbenchDetailPage / 数据同步 |
| **关联验收标准** | PRD §M6: 添加测点后刷新列表 |

**前置条件**：
- 工作台 `wb-1`、设备 `dev-1` 已存在
- 初始有 1 个测点

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 点击设备 `dev-1`
3. 点击"+ 添加测点"
4. 填写表单并保存

**预期结果**：
- ✅ 对话框关闭
- ✅ 显示 Toast"测点已保存"
- ✅ 测点列表自动刷新
- ✅ 新测点出现在列表中
- ✅ 计数更新为"共 2 个测点"

---

### TC-WD-008: 删除设备后测点列表清理

| 属性 | 内容 |
|------|------|
| **ID** | TC-WD-008 |
| **优先级** | **P1 — HIGH** |
| **类别** | WorkbenchDetailPage / 状态清理 |
| **关联验收标准** | 通用状态管理要求 |

**前置条件**：
- 工作台 `wb-1` 已存在
- 设备 `dev-1` 已选中，显示测点列表

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 点击设备 `dev-1`，查看测点列表
3. 在外部（或通过 API）删除 `dev-1`
4. 设备树刷新，`dev-1` 消失

**预期结果**：
- ✅ `_selectedDeviceId` 被清空（设为 null）
- ✅ 右侧详情面板恢复为占位视图
- ✅ 不显示已删除设备的测点列表
- ✅ 无内存泄漏或状态不一致错误

---

## 五、响应式布局测试用例（4 项）

### TC-RL-001: 桌面端（≥1024px）左右分栏布局

| 属性 | 内容 |
|------|------|
| **ID** | TC-RL-001 |
| **优先级** | **P1 — HIGH** |
| **类别** | 响应式 / 桌面端 |
| **关联验收标准** | PRD §M6: 设备详情面板布局 |

**前置条件**：
- 屏幕宽度 1440px
- 工作台 `wb-1`、设备 `dev-1` 已存在

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 点击设备 `dev-1`
3. 检查布局

**预期结果**：
- ✅ 左侧设备树固定宽度 280px
- ✅ 右侧设备详情面板 flex: 1
- ✅ 测点列表在详情面板内，宽度自适应
- ✅ 表格显示完整 6 列
- ✅ 操作按钮（编辑/删除）始终可见

---

### TC-RL-002: 平板端（600-1024px）上下堆叠，设备树可折叠

| 属性 | 内容 |
|------|------|
| **ID** | TC-RL-002 |
| **优先级** | **P1 — HIGH** |
| **类别** | 响应式 / 平板端 |
| **关联验收标准** | PRD §M6: 平板布局 |

**前置条件**：
- 屏幕宽度 768px（iPad 竖屏）
- 工作台 `wb-1`、设备 `dev-1` 已存在

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 检查布局
3. 点击设备树标题展开/折叠

**预期结果**：
- ✅ 设备树面板在上方，默认展开
- ✅ 详情面板在下方
- ✅ 设备树可点击折叠
- ✅ 测点列表显示为表格（仍有足够宽度）

---

### TC-RL-003: 移动端（<600px）上下堆叠，设备树默认折叠

| 属性 | 内容 |
|------|------|
| **ID** | TC-RL-003 |
| **优先级** | **P1 — HIGH** |
| **类别** | 响应式 / 移动端 |
| **关联验收标准** | PRD §M6: 移动端布局 |

**前置条件**：
- 屏幕宽度 375px（iPhone SE）
- 工作台 `wb-1`、设备 `dev-1` 已存在

**测试步骤**：
1. 导航到 `/workbenches/wb-1`
2. 检查布局
3. 展开设备树并选择设备

**预期结果**：
- ✅ 设备树默认折叠（只显示标题栏）
- ✅ 详情面板占据全宽
- ✅ 测点列表显示为卡片布局（见 TC-PL-009）
- ✅ "+ 添加测点"按钮全宽显示
- ✅ 操作按钮（编辑/删除）可点击，大小适合触摸（≥44x44px）

---

### TC-RL-004: 对话框在移动端显示为底部 Sheet

| 属性 | 内容 |
|------|------|
| **ID** | TC-RL-004 |
| **优先级** | **P1 — HIGH** |
| **类别** | 响应式 / 对话框适配 |
| **关联验收标准** | 通用响应式规范 |

**前置条件**：
- 屏幕宽度 375px
- 设备 `dev-1` 已存在
- 测点列表已显示

**测试步骤**：
1. 点击"+ 添加测点"
2. 检查对话框样式

**预期结果**：
- ✅ 对话框从底部弹出（全屏宽度）
- ✅ 占据屏幕底部大部分高度（约 90%）
- ✅ 可上下拖动关闭
- ✅ 表单字段垂直排列，适合触摸输入
- ✅ 保存/取消按钮全宽显示在底部

---

## 六、无障碍与交互测试用例（3 项）

### TC-A11Y-001: 所有按钮有 Tooltip 和语义标签

| 属性 | 内容 |
|------|------|
| **ID** | TC-A11Y-001 |
| **优先级** | **P1 — HIGH** |
| **类别** | 无障碍 / 语义化 |
| **关联验收标准** | 通用无障碍要求 |

**测试步骤**：
1. 渲染 `PointListWidget`（有数据状态）
2. 检查所有交互元素的语义属性

**预期结果**：
- ✅ "+ 添加测点"按钮有 `tooltip: l10n.addPoint`
- ✅ 每个"编辑"按钮有 `tooltip: l10n.edit`
- ✅ 每个"删除"按钮有 `tooltip: l10n.delete`
- ✅ 刷新按钮有 `tooltip: l10n.refresh`
- ✅ 所有 IconButton 有正确的 `semanticLabel`

---

### TC-A11Y-002: 表单字段有正确的标签和提示

| 属性 | 内容 |
|------|------|
| **ID** | TC-A11Y-002 |
| **优先级** | **P1 — HIGH** |
| **类别** | 无障碍 / 表单 |
| **关联验收标准** | 通用无障碍要求 |

**测试步骤**：
1. 打开 `PointFormDialog`
2. 检查表单字段的无障碍属性

**预期结果**：
- ✅ 名称输入框有 `labelText: l10n.pointNameLabel`
- ✅ 名称输入框有 `hintText: l10n.pointNameHint`
- ✅ 数据类型下拉有 `labelText: l10n.pointDataTypeLabel`
- ✅ 访问权限下拉有 `labelText: l10n.pointAccessTypeLabel`
- ✅ 必填字段标记有 `*` 且语义上标注 required

---

### TC-A11Y-003: 键盘导航支持

| 属性 | 内容 |
|------|------|
| **ID** | TC-A11Y-003 |
| **优先级** | **P2 — MEDIUM** |
| **类别** | 无障碍 / 键盘 |
| **关联验收标准** | 通用无障碍要求 |

**测试步骤**：
1. 打开 `PointFormDialog`
2. 使用 Tab 键遍历所有字段
3. 使用 Enter 键提交表单

**预期结果**：
- ✅ Tab 键按正确顺序聚焦各字段
- ✅ 聚焦状态有视觉反馈（轮廓线或背景色变化）
- ✅ 在名称字段按 Enter 不提交（多行字段除外）
- ✅ 在保存按钮按 Enter 提交表单
- ✅ ESC 键关闭对话框（底部 Sheet 也可关闭）

---

## 测试用例汇总

| 类别 | 用例数 | P0 | P1 | P2 |
|------|--------|----|----|-----|
| PointListWidget | 16 | 10 | 5 | 1 |
| PointFormDialog | 14 | 9 | 5 | 0 |
| PointValueDisplay | 8 | 5 | 3 | 0 |
| WorkbenchDetailPage | 8 | 5 | 3 | 0 |
| 响应式布局 | 4 | 0 | 4 | 0 |
| 无障碍与交互 | 3 | 0 | 2 | 1 |
| **总计** | **53** | **29** | **22** | **2** |

---

## 测试数据需求

### Mock 测点数据

```dart
// 标准测点（Virtual 设备）
final point1 = Point(
  id: 'pt-1',
  deviceId: 'dev-1',
  name: '温度传感器',
  dataType: DataType.number,
  accessType: AccessType.ro,
  unit: '°C',
  minValue: -50.0,
  maxValue: 150.0,
  defaultValue: null,
  status: 'normal',
  createdAt: DateTime.parse('2026-05-01T00:00:00Z'),
  updatedAt: DateTime.parse('2026-05-01T00:00:00Z'),
);

final point2 = Point(
  id: 'pt-2',
  deviceId: 'dev-1',
  name: '阀门状态',
  dataType: DataType.boolean,
  accessType: AccessType.rw,
  unit: null,
  minValue: null,
  maxValue: null,
  defaultValue: null,
  status: 'normal',
  createdAt: DateTime.parse('2026-05-01T00:00:00Z'),
  updatedAt: DateTime.parse('2026-05-01T00:00:00Z'),
);

// Modbus 测点
final modbusPoint = Point(
  id: 'pt-m1',
  deviceId: 'dev-modbus',
  name: '线圈状态',
  dataType: DataType.boolean,
  accessType: AccessType.rw,
  unit: null,
  minValue: null,
  maxValue: null,
  defaultValue: null,
  status: 'normal',
  createdAt: DateTime.parse('2026-05-01T00:00:00Z'),
  updatedAt: DateTime.parse('2026-05-01T00:00:00Z'),
);
```

### Mock 测点值数据

```dart
final pointValue1 = PointValue(
  pointId: 'pt-1',
  value: 25.3256,
  timestamp: '2026-06-01T10:00:00Z',
);
```

---

## 相关 l10n Key 需求（需新增）

| Key | 中文 | 英文 | 说明 |
|-----|------|------|------|
| `pointColumnName` | 名称 | Name | 表格列标题 |
| `pointColumnType` | 类型 | Type | 表格列标题 |
| `pointColumnAccess` | 访问权限 | Access | 表格列标题 |
| `pointColumnUnit` | 单位 | Unit | 表格列标题 |
| `pointColumnValue` | 当前值 | Value | 表格列标题 |
| `pointColumnAction` | 操作 | Actions | 表格列标题 |
| `pointListTitle` | 测点列表 | Points | 详情面板标题 |
| `pointCount` | 共 {count} 个测点 | {count} points | 顶部计数 |
| `addPoint` | 添加测点 | Add Point | 添加按钮 |
| `addFirstPoint` | 添加第一个测点 | Add First Point | 空状态按钮 |
| `pointListEmpty` | 该设备下暂无测点 | No points for this device | 空状态文本 |
| `pointNameLabel` | 名称 | Name | 表单标签 |
| `pointNameHint` | 请输入测点名称 | Enter point name | 表单提示 |
| `pointNameRequired` | 请输入测点名称 | Point name is required | 验证错误 |
| `pointNameTooLong` | 名称不能超过 255 个字符 | Name must not exceed 255 characters | 验证错误 |
| `pointDataTypeLabel` | 数据类型 | Data Type | 表单标签 |
| `pointAccessTypeLabel` | 访问权限 | Access | 表单标签 |
| `pointUnitLabel` | 单位 | Unit | 表单标签 |
| `pointMinValueLabel` | 最小值 | Min Value | 表单标签 |
| `pointMaxValueLabel` | 最大值 | Max Value | 表单标签 |
| `pointRangeInvalid` | 最大值必须大于最小值 | Max must be greater than min | 验证错误 |
| `pointDefaultValueLabel` | 默认值 | Default Value | 表单标签 |
| `pointSaveSuccess` | 测点已保存 | Point saved | Toast 消息 |
| `pointDeleteSuccess` | 测点已删除 | Point deleted | Toast 消息 |
| `pointDeleteConfirm` | 确定要删除测点「{name}」吗？ | Delete point "{name}"? | 确认对话框标题 |
| `pointDeleteWarning` | 此操作不可撤销。 | This action cannot be undone. | 确认对话框描述 |
| `pointModbusConfig` | Modbus 配置 | Modbus Config | 表单区域标题 |
| `pointRegisterTypeLabel` | 寄存器类型 | Register Type | 表单标签 |
| `pointAddressLabel` | 起始地址 | Start Address | 表单标签 |
| `pointAddressRange` | 起始地址必须在 0-65535 之间 | Address must be 0-65535 | 验证错误 |
| `pointDataFormatLabel` | 数据格式 | Data Format | 表单标签 |
| `pointStatusNormal` | 正常 | Normal | 状态 Tooltip |
| `pointStatusTimeout` | 超时 | Timeout | 状态 Tooltip |
| `pointStatusError` | 异常 | Error | 状态 Tooltip |
| `refresh` | 刷新 | Refresh | 刷新按钮 |

---

## 七、sw-tom 评审结论

> **评审人**: sw-tom (Software Developer)
> **评审日期**: 2026-06-01
> **评审结论**: ⚠️ **NEEDS_REVISION**（5 项关键问题需修订后方可用作开发驱动）

---

### 7.1 全局性问题

#### ❌ G-01: Task ID 错误

测试用例文件标题为 **TASK-018**，但对照 `tasks.md`：

| tasks.md 定义 | ID | 内容 |
|---|---|---|
| TASK-018 (line 1131) | 测点 **Service + Provider** | 数据层（PointService、PointListNotifier） |
| TASK-019 (line 1185) | 测点 **列表/配置 UI** | UI 层（PointListWidget、PointFormDialog 等） |

本文件测试的 **全部是 UI 层组件**（PointListWidget、PointFormDialog、PointValueDisplay、WorkbenchDetailPage 集成），应归为 **TASK-019** 而非 TASK-018。

**建议**：重命名文件为 `TASK-019_test_cases.md`，并修正头部的「关联任务」引用。

---

#### ⚠️ G-02: 数据模型字段不匹配 — `description` 不存在

Point 数据模型（`lib/models/point.dart`）**没有 `description` 字段**，只有 `defaultValue`。但以下测试用例引用了"描述"字段：

| 用例 | 引用内容 |
|------|---------|
| TC-PF-001 | "描述字段：空文本，无必填标记" |
| TC-PF-006 | "保持描述为空" → "description 为 null" |
| TC-PF-010 | "描述字段：'主温度传感器'" |
| l10n key 清单 | `pointDescriptionLabel` |

**影响**：如果 UI 表单包含"描述"字段，但 PointService.create() 和 Point.update() 均不传递 description 参数（create 只有 `defaultValue`），会导致保存时丢失数据或 API 调用错误。

**建议**：
1. **优先方案**：确认后端是否支持 description 字段。如果支持，在 PointService.create() 和 Point.update() 及 PointListNotifier 中添加 description 参数。
2. **备选方案**：如果不支持，表单中移除"描述"字段，测试用例及 l10n key 相应删除。
3. `Point` 模型的 `defaultValue` 目前也**没有任何测试覆盖**——如果 description 被移除，测试可改为覆盖 defaultValue。

---

#### ⚠️ G-03: PointService.update() 用 Map 而非命名参数

`PointService.update()`（`point_service.dart`）的实际签名：

```dart
Future<Point> update(String id, Map<String, dynamic> data) async
```

但 TC-PF-011 的预期写的是：

> ✅ 调用 `PointService.update('pt-1', name: '温度传感器（更新）', unit: 'K', ...)`

**这是不可行的**——Service 层 API 不接受命名参数，而是接受 `Map<String, dynamic>`。对话框层调用时必然要构造 Map。

**建议**：TC-PF-011 的预期改为：

> ✅ 调用 `PointService.update('pt-1', {'name': '温度传感器（更新）', 'unit': 'K', ...})`

或描述为"调用 PointListNotifier 的 updatePoint 方法（如有）"。

---

#### ⚠️ G-04: PointListNotifier 缺少 `updatePoint()` 方法

`point_provider.dart` 中 PointListNotifier 有 `createPoint()` 和 `deletePoint()`，但**没有 `updatePoint()` 方法**。编辑测点流程（TC-PL-005、TC-PF-010、TC-PF-011）将无法通过现有 Provider 实现。

**建议**：确认在 TASK-019 的实现中是否计划添加 `updatePoint()` 方法。如果计划添加，测试用例应与此一致。测试用例可以注明"需在 PointListNotifier 中补充 updatePoint 方法"。

---

#### ⚠️ G-05: 缺少表格列标题的 l10n Key

TC-PL-003 和 TC-PL-010 预期表格包含 6 列（名称、类型、访问权限、单位、当前值、操作），但 l10n key 清单中**缺少对应的列标题 key**：

| 缺失 key | 用途 |
|----------|------|
| `pointColumnName` | 列标题「名称」/ "Name" |
| `pointColumnType` | 列标题「类型」/ "Type" |
| `pointColumnAccess` | 列标题「访问权限」/ "Access" |
| `pointColumnUnit` | 列标题「单位」/ "Unit" |
| `pointColumnValue` | 列标题「当前值」/ "Value" |
| `pointColumnAction` | 列标题「操作」/ "Actions" |

另外 TC-WD-001 引用了 `l10n.deviceDetail` 和 `l10n.deviceDetailPlaceholder`（设备详情面板占位），这些**可能属于设备相关的 l10n key**，但未包含在本清单中。建议明确归属。

---

### 7.2 各用例逐项评审

#### 一、PointListWidget（16 项）

| 用例 ID | 结论 | 说明 |
|---------|:----:|------|
| TC-PL-001 | ⚠️ 修改 | 预期结果写了"骨架行使用 `Container` + `BoxDecoration` 实现脉冲动画效果"——现有 `Skeleton` 组件（`widgets/skeleton.dart`）使用 `ShaderMask` + `_ShimmerContainer` 实现 shimmer，不是 `Container + BoxDecoration`。应改为"使用 SkeletonTable 或 Skeleton 组件显示骨架行"或仅描述视觉效果（"显示脉冲动画占位行"），不绑定实现细节。 |
| TC-PL-002 | ✅ 通过 | 空状态逻辑与 `AsyncValueWidget` / `EmptyView` 组件设计一致。注意确认空状态时顶部是否真的显示"共 0 个测点"（TC-WD-003 要求计数来自 `l10n.pointCount(N)`，`pointCount(0)` 应是有效调用）。 |
| TC-PL-003 | ✅ 通过 | 6 列对齐 tasks.md 要求，类型标签颜色区分合理。 |
| TC-PL-004 | ✅ 通过 | 标准添加流程。 |
| TC-PL-005 | ⚠️ 依赖 G-04 | 编辑按钮点击 → 弹出对话框流程合理，但依赖 `updatePoint()` 方法是否存在。 |
| TC-PL-006 | ✅ 通过 | 与现有 `ConfirmDialog` 组件（`confirm_dialog.dart`）API 一致。 |
| TC-PL-007 | ✅ 通过 | 删除流程完整（确认 → 调用 API → Toast → 刷新 → 空状态）。 |
| TC-PL-008 | ✅ 通过 | 删除失败处理正确。 |
| TC-PL-009 | ✅ 通过 | 响应式卡片布局，断点 600px 与 TC-RL-003 一致。 |
| TC-PL-010 | ⚠️ 微调 | 预期结果中"表格行有 hover 效果（背景色变化）"——在 Web 上 `DataTable` 原生支持 hover，但需确认实现是否使用 `DataTable` 或自定义布局。如果使用自定义布局，hover 需手动实现。建议不绑定具体 widget。 |
| TC-PL-011 | ✅ 通过 | 错误视图 + 重试按钮，与 `ErrorView` 组件设计一致。 |
| TC-PL-012 | ✅ 通过 | 空状态按钮变体，行为与 TC-PL-004 一致。 |
| TC-PL-013 | ⚠️ 修改 | **"等待 5 秒"在自动化测试中不可行。** 测试环境不应等待真实时间。应使用 Dart 的 `fakeAsync` 或 `ticker` 模拟时间流逝。建议改为：`使用 fakeAsync 模拟 5 秒自动刷新间隔`。 |
| TC-PL-014 | ✅ 通过 | 三种状态（normal/timeout/error）的颜色映射合理。注意颜色值应在主题中定义而非硬编码，测试中用 `colorScheme` 引用。 |
| TC-PL-015 | ⚠️ 修改 | **帧率测试（60fps）不适合 Widget test。** Widget 测试环境（`TestWidgetsFlutterBinding`）不提供真实的帧率测量。建议：① 保留该用例但标记为 **手动/集成测试**（而非 Widget test）；② 或仅在 Widget test 中验证使用 `ListView.builder` 实现。 |
| TC-PL-016 | ✅ 通过 | 添加后自动刷新 + 计数更新。 |

#### 二、PointFormDialog（14 项）

| 用例 ID | 结论 | 说明 |
|---------|:----:|------|
| TC-PF-001 | ⚠️ 依赖 G-02 | 涉及"描述字段"（G-02）；"保存按钮：禁用状态（因为名称为空）"——需确认是否实现 dirty check。 |
| TC-PF-002 | ✅ 通过 | 名称必填验证。 |
| TC-PF-003 | ✅ 通过 | 255 字符上限验证。注意输入框字符计数器（maxLength）的 UI 实现。 |
| TC-PF-004 | ✅ 通过 | 4 个数据类型选项。 |
| TC-PF-005 | ✅ 通过 | 3 个访问权限选项。 |
| TC-PF-006 | ⚠️ 依赖 G-02 | 涉及"描述"字段（G-02）。此外 `defaultValue` 字段未被测试覆盖——是否需要测试 defaultValue？ |
| TC-PF-007 | ✅ 通过 | Modbus 配置区域逻辑清晰：寄存器类型(4)、起始地址(0-65535)、数据格式（uint16/int16 等）。 |
| TC-PF-008 | ✅ 通过 | 保存成功流程完整（loading → API → pop → Toast → 回调刷新）。 |
| TC-PF-009 | ✅ 通过 | 保存失败处理正确（不关闭对话框、保留数据、显示错误）。 |
| TC-PF-010 | ⚠️ 微调 | "保存按钮初始为禁用状态（数据未改变）"——dirty check 是好的 UX 模式但 **未在 tasks.md/PRD 中明确要求**。建议降为 P1 或标注为"如果实现 dirty check"。 |
| TC-PF-011 | ⚠️ 依赖 G-03、G-04 | update API 签名不匹配（G-03），且 Provider 无 updatePoint 方法（G-04）。 |
| TC-PF-012 | ✅ 通过 | 取值范围验证（min > max）。 |
| TC-PF-013 | ✅ 通过 | Modbus 起始地址范围验证（0-65535）。 |
| TC-PF-014 | ✅ 通过 | 取消操作。 |

#### 三、PointValueDisplay（8 项）

| 用例 ID | 结论 | 说明 |
|---------|:----:|------|
| TC-PV-001 | ✅ 通过 | 数值+单位格式化。Number 保留 2 位小数的假设合理但非 PRD 强制要求。如果业务需要不同精度，这个测试可能过于严格。建议改为"按数据类型默认精度显示"。 |
| TC-PV-002 | ✅ 通过 | 各类型格式化（Number/Integer/Boolean/String）。注意 Boolean 本地化文本取决于 arb 文件实现，测试应留有余地（"开启"或"true"均可）。 |
| TC-PV-003 | ✅ 通过 | 正常状态灰色图标。 |
| TC-PV-004 | ✅ 通过 | 超时状态橙色图标 + "最后已知值"。 |
| TC-PV-005 | ✅ 通过 | 异常状态红色图标 + "—"。 |
| TC-PV-006 | ✅ 通过 | 手动刷新按钮流程。 |
| TC-PV-007 | ✅ 通过 | 加载中骨架占位。 |
| TC-PV-008 | ✅ 通过 | 错误状态显示"—" + 重试。 |

#### 四、WorkbenchDetailPage（8 项）

| 用例 ID | 结论 | 说明 |
|---------|:----:|------|
| TC-WD-001 | ✅ 通过 | 未选中设备占位视图。l10n key `deviceDetail` 和 `deviceDetailPlaceholder` 可能应归入设备模块而非测点。 |
| TC-WD-002 | ✅ 通过 | 选中设备显示详情 + PointListWidget 嵌入。 |
| TC-WD-003 | ✅ 通过 | 国际化检查完整，覆盖了标题、计数、按钮、空状态。 |
| TC-WD-004 | ✅ 通过 | 设备详情加载中骨架屏。 |
| TC-WD-005 | ✅ 通过 | 设备详情加载错误 + 重试。 |
| TC-WD-006 | ✅ 通过 | Modbus 设备特殊显示（协议图标、参数、Modbus 测点配置）。 |
| TC-WD-007 | ✅ 通过 | 添加测点后列表自动刷新（与 TC-PL-016 覆盖同一场景，但从集成测试角度合理）。 |
| TC-WD-008 | ⚠️ 微调 | 外部删除设备后清理状态。测试实现需注意：在 Widget test 中"从外部删除设备"需要操作 Provider 状态或 mock 数据层，技术上可行但需明确测试方法。 |

#### 五、响应式布局（4 项）

| 用例 ID | 结论 | 说明 |
|---------|:----:|------|
| TC-RL-001 | ✅ 通过 | 桌面端左右分栏（≥1024px）。 |
| TC-RL-002 | ✅ 通过 | 平板上下堆叠，设备树可折叠（600-1024px）。 |
| TC-RL-003 | ✅ 通过 | 移动端设备树默认折叠（<600px）。 |
| TC-RL-004 | ⚠️ 修改 | 指定了实现细节 `showModalBottomSheet`。这与 `ConfirmDialog` 的自适应实现模式一致（`confirm_dialog.dart` 已经实现了 <600px 时使用 BottomSheet）。建议改为描述用户可见行为而非具体 API：✅ 对话框在移动端从底部弹出（全屏宽度），✅ 可向下拖动关闭，不需要指定 `showModalBottomSheet`。 |

#### 六、无障碍与交互（3 项）

| 用例 ID | 结论 | 说明 |
|---------|:----:|------|
| TC-A11Y-001 | ✅ 通过 | 按钮 tooltip 和语义标签。注意 `l10n.refresh` 已在 TASK-006 覆盖范围之外——需确认是否已在 ARB 文件中定义，或需新增。 |
| TC-A11Y-002 | ✅ 通过 | 表单字段标签和提示。 |
| TC-A11Y-003 | ⚠️ 修改 | **键盘事件模拟在 `flutter_test` 中需要特殊处理**。Tab 键导航、Enter 提交、ESC 关闭需要发送 `KeyEvent` 并等待 frame。技术上可行但测试实现较复杂。建议：① 降为 P2；② 明确标注"需使用 `KeyDownEvent`/`KeyUpEvent` 模拟"。 |

---

### 7.3 遗漏测试场景建议

建议 sw-mike 考虑补充以下场景：

| # | 场景 | 组件 | 优先级 | 说明 |
|---|------|------|:------:|------|
| M-01 | **RW 测点写入值** | PointValueDisplay | P1 | 现有测试只覆盖了 RO 测点的值读取，未覆盖 RW 测点的值写入操作（`setValue` API）。 |
| M-02 | **defaultValue 字段处理** | PointFormDialog | P1 | Point 模型有 `defaultValue` 字段但测试未涉及。表单是否应该展示 defaultValue？ |
| M-03 | **测点名称含特殊字符** | PointFormDialog | P2 | 名称中含 HTML/XML/SQL 注入字符的处理。 |
| M-04 | **并发操作：编辑时自动刷新** | PointListWidget | P2 | 用户正在编辑测点时后台自动刷新触发——编辑对话框应保持打开不丢失数据。 |
| M-05 | **大量测点名长文本截断** | PointListWidget | P2 | 名称超长时的省略号处理（尤其在卡片布局中）。 |
| M-06 | **编辑时取消后不刷新列表** | PointFormDialog / PointListWidget | P1 | 当前测试覆盖了"取消不保存"，但未验证取消后列表不发送额外的 API 请求。 |

---

### 7.4 测试数据建议

Mock 数据中 `point2` 没有提供 `defaultValue` 字段——虽然它是可选字段，建议在所有 mock Point 对象的构造中**明确写出所有字段**（包括设为 null 的）以提高可读性和覆盖率：

```dart
final point2 = Point(
  id: 'pt-2',
  deviceId: 'dev-1',
  name: '阀门状态',
  dataType: DataType.boolean,
  accessType: AccessType.rw,
  unit: null,          // 显式声明
  minValue: null,      // 显式声明
  maxValue: null,      // 显式声明
  defaultValue: null,  // 显式声明
  status: 'normal',
  createdAt: DateTime.parse('2026-05-01T00:00:00Z'),
  updatedAt: DateTime.parse('2026-05-01T00:00:00Z'),
);
```

---

### 7.5 整体结论

> ## ✅ 覆盖率评价
>
> 测试用例覆盖了 **所有 4 个主要组件** 的全部关键状态（loading/error/empty/data），响应式布局 3 个断点完整，无障碍 3 项合理。53 个用例中绝大多数（39/53）在技术上是可行的。
>
> ## ⚠️ NEEDS_REVISION
>
> **必须修正的 5 个关键问题**（阻塞级）：
>
> 1. **G-01**: Task ID 错误（TASK-018 → TASK-019）——影响 CI 和任务跟踪
> 2. **G-02**: `description` 字段不存在于数据模型 / Service 层——影响所有 FormDialog 测试
> 3. **G-03**: `update()` API 签名不匹配——影响 TC-PF-011
> 4. **G-04**: Provider 缺少 `updatePoint()` 方法——影响编辑流程测试
> 5. **G-05**: 缺少表格列标题 l10n key——影响国际化验证
>
> **建议修改**的 8 个用例（非阻塞但建议优化）：
> - TC-PL-001（骨架实现细节）、TC-PL-013（时间等待）、TC-PL-015（性能测试）、TC-RL-004（BottomSheet 实现细节）、TC-PF-010（dirty check 未要求）、TC-A11Y-003（键盘模拟复杂度）
>
> **建议补充** 6 个遗漏场景（M-01 至 M-06）
>
> 待上述 G-01~G-05 修正后，整体结论可升级为 **APPROVED**。

---

## 测试用例终审结论

**评审人**: sw-tom
**日期**: 2026-06-01
**结论**: ✅ **APPROVED** — 全部阻塞内容问题已解决（G-02~G-05 已正确修复，G-01 文件命名 TASK-018→TASK-019 为组织性调整，可在开发初始化时处理），可进入下一阶段（UI 设计）。

### 修订确认记录

| 问题 | 状态 | 说明 |
|:----:|:----:|:------|
| ❌ G-01 | ⚠️ 部分 | 文件仍命名 TASK-018（建议开发初始化时重命名为 TASK-019_test_cases.md） |
| ⚠️ G-02 | ✅ 已修复 | 所有用例移除"描述"字段引用，改用 defaultValue；l10n 清单已删除 pointDescriptionLabel |
| ⚠️ G-03 | ✅ 已修复 | TC-PF-011 改用 Map 参数语法与 PointService.update() 签名一致 |
| ⚠️ G-04 | ✅ 已修复 | 测试改用 PointService.update() 替代不存在的 updatePoint() |
| ⚠️ G-05 | ✅ 已修复 | 6 个表格列标题 l10n key 已补充完整 |

**最终用例清单**: 53 项（P0: 29, P1: 22, P2: 2），覆盖 4 个组件 + 响应式 + 无障碍。

---
