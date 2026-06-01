# TASK-018 详细设计评审报告

> **评审人**: sw-jerry (Software Architect)
> **评审日期**: 2026-06-01
> **评审对象**: `log/release_3/design/TASK-018_design.md`
> **关联**: TASK-018 (数据层) + TASK-019 (UI 层，本文档实际覆盖)
> **最终结论**: ⚠️ **NEEDS_REVISION** — 2 项 BLOCKING 问题需修正后方可进入开发

---

## 评审摘要

| 维度 | 结论 | 关键发现 |
|------|:----:|----------|
| **架构合规性** | ✅ 通过 | Riverpod 3.x AsyncNotifier 模式使用正确；数据流遵循 Backend→Service→Provider→Widget；DeviceConfigDialog 模式正确复用；仅 1 个组件设计内部矛盾 |
| **技术可行性** | ⚠️ 有问题 | B-02 Modbus 字段存储策略存在架构级风险；PointValueDisplay 刷新方案可行；updatePoint() 签名一致 |
| **完整性** | ⚠️ 部分缺失 | 41/53 测试用例直接覆盖；UI 设计规范大部分已映射；l10n 清单完善；但键盘导航、Provider 使用不一致、状态传递路径等细节遗漏 |

---

## 一、架构合规性评审

### 1.1 Riverpod 3.x AsyncNotifier 模式 ✅

**判定**: 正确使用

| 检查项 | 设计 | 现有模式 | 结论 |
|--------|------|----------|:---:|
| PointListNotifier extends AsyncNotifier | ✅ | 与 `DeviceTreeNotifier` 一致 | ✅ |
| pointListProvider 使用 AsyncNotifierProvider.family | ✅ | 与 `deviceTreeProvider` 一致 | ✅ |
| updatePoint() 使用 `state = const AsyncLoading()` 后 `AsyncValue.guard(build)` | ✅ | 与现有 `createPoint()`/`deletePoint()` 一致 | ✅ |
| PointFormDialog extends ConsumerStatefulWidget | ✅ | 与 `DeviceConfigDialog` 一致 | ✅ |
| PointListWidget extends ConsumerWidget | ✅ | 适合纯展示组件 | ✅ |
| PointValueDisplay extends ConsumerStatefulWidget | ✅ | 内部独立管理加载状态 | ✅ |

### 1.2 数据流设计 ✅

**判定**: 遵循单向数据流

```
Backend API → PointService → PointListNotifier → PointListWidget → PointValueDisplay
                   ↑                                                      |
                   └──────────────── (直接调用 getValue) ──────────────────┘
```

- 主数据流（列表加载）：API → Service → Notifier → Widget ✅
- 修改操作流（CRUD）：Widget → Notifier → Service → API → Notifier.build() → Widget ✅
- 副作用处理（Toast/ConfirmDialog）：通过 Notifier 方法的结果触发 ✅

### 1.3 现有组件复用 ✅

| 设计引用 | 现有组件 | 复用方式 | 结论 |
|----------|----------|----------|:---:|
| ConfirmDialog | `widgets/confirm_dialog.dart` | 删除确认弹窗 | ✅ |
| Toast | `widgets/toast.dart` | 操作成功/失败反馈 | ✅ |
| EmptyView | `widgets/empty_view.dart` | 空状态展示 | ✅ |
| ErrorView | `widgets/error_view.dart` | 错误状态展示 | ✅ |
| Skeleton/_ShimmerPlaceholder | `widgets/skeleton.dart` | 表格骨架屏 (via _ShimmerPlaceholder) | ✅ |
| deviceDetailProvider | `providers/device_provider.dart` | PointFormDialog 获取设备协议类型 | ✅ |
| pointServiceProvider | `providers/services.dart` | 全局 Service 注入 | ✅ |

**Skeleton 表格骨架处理 (S-03)**: 设计 §B-01 方案复用 `_ShimmerPlaceholder` 构建自定义表格骨架行，不依赖现有 Skeleton 组件（现有不支持表格布局）。这是一个合理的扩展方案。✅

### 1.4 DeviceConfigDialog 模式对齐 ✅

```dart
// DeviceConfigDialog 模式 (现有)               // PointFormDialog 模式 (设计)
ConsumerStatefulWidget                         ConsumerStatefulWidget         ✅
static show(context, ref, ...)                 static show(context, ref, ...) ✅
<600px → showModalBottomSheet                  <600px → showModalBottomSheet  ✅
≥600px → showDialog(AlertDialog)               ≥600px → showDialog(AlertDialog) ✅
_formKey + TextEditingControllers              Form + DropdownButtonFormField  ✅
_isSaving 状态锁                              loading 状态                    ✅
保存 → Notifier → Toast → pop                 保存 → Notifier → Toast → pop   ✅
```

### 🔴 BLOCKING ISSUE #1: D-05 决策与实现计划矛盾

**位置**: §3.3 vs §6.1 Step 2 vs 附录 A §D-05

**问题描述**:

设计在三个位置对"编辑模式如何加载数据"给出了矛盾的说法：

| 来源 | 说法 |
|------|------|
| §3.3 序列图 (行 564) | `Dialog->>Service: getById(pointId)` — 对话框自行调用 API |
| §6.1 Step 2 (行 900) | "通过 `PointService.getById` 加载现有数据预填" — 对话框自行调用 API |
| §D-05 (行 1125) | "通过父组件传入 Point" (Option B)，理由"避免额外 API 调用" |

**影响**: 如果按 §D-05 实现（父组件传入 `existing: Point`），则序列图 §3.3 中的 `getById` 调用需删除，但 `_isEdit` 模式下打开对话框时的加载状态处理方式也需要调整（不再有独立的 loading 状态）。如果按 §3.3/§6.1 实现（对话框自行调用 getById），则 D-05 决策记录需修正。

**建议**: 
- 统一为 **D-05 方案 B**（父组件传入 `existing: Point`），因为 Point 对象在列表中已经完整加载，无需重复请求。序列图和 §6.1 Step 2 需同步修正。
- 或者统一为方案 A，但需在 D-05 中更新理由为"确保编辑时数据最新"。

---

## 二、技术可行性评审

### 🔴 BLOCKING ISSUE #2: B-02 Modbus 字段存储策略存在架构级风险

**位置**: §5 (Modbus 字段对齐方案)

**问题描述**:

设计承认当前后端 `CreatePointRequest`、`PointDto`、`PointResponse` 均**不包含** `address`、`register_type`、`data_format` 字段（见 §5.2 表格）。设计的短期方案是：

1. 前端 Point 模型新增 `address` 字段 → **可行** ✅（后端 DB 有 `address TEXT` 列）
2. 前端 PointFormDialog 显示 Modbus 字段输入 → **可行** ✅
3. 调用 `PointService.create()` 时传递 `address` 和 `metadata` → **无效** ❌

**根因分析**: 后端从请求中反序列化到 `CreatePointRequest` 时，未定义的字段会被 serde 默认忽略（除非配置 `deny_unknown_fields`）。即使前端发送 `metadata: {...}`，后端不会写入 DB 的 `metadata` JSON 列。`address` 同理：后端 handler 需要显式从请求 JSON 中提取 `address` 再写入 `points.address` 列，而当前实现并未做此映射。

**影响**: 
- 添加 Modbus 测点时，`register_type` 和 `data_format` **静默丢失**（不存储到任何地方）
- 编辑 Modbus 测点时，这些字段在 GET 响应中**不存在**，导致表单回填空值
- 用户体验：填写了 Modbus 配置 → 保存 → 重新打开编辑 → 配置消失

**建议方案 (按优先级)**:

| 方案 | 描述 | 推荐度 |
|------|------|:------:|
| **A** | 协调后端在 `CreatePointRequest`/`PointDto` 中新增 `address`、`metadata` 字段（约 2-3 小时后端工作量） | ⭐⭐⭐ 首选 |
| **B** | 本 Release 中 Modbus 配置区域显示为"即将推出"占位状态，仅展示 Virtual 设备的基础字段 | ⭐⭐ 可接受 |
| **C** | 将 register_type 和 data_format 序列化为 JSON 存在 `default_value` 字段（hack，污染语义） | ⭐ 不推荐 |
| **D** | UI 接受输入但不持久化（等于没有功能） | ❌ 不可接受 |

**当前风险的缓解**: 如果选择方案 A 不可行且方案 B 不接受，可在设计文档中将 B-02 标记为 `[BLOCKED BY BACKEND]`，明确列出所需的后端变更清单。

### 2.3 PointValueDisplay 独立刷新方案 ✅

**判定**: 技术可行

- `ConsumerStatefulWidget` 内部管理 `_isLoading` 和 `AnimationController` → 模式正确 ✅
- 独立调用 `PointService.getValue(pointId)` → 不影响父组件状态 ✅
- 刷新按钮旋转动画 (SingleTickerProviderStateMixin) → 实现合理 ✅

### 2.4 updatePoint() 签名 ✅

```dart
// 设计 §2.3
Future<void> updatePoint(String pointId, Map<String, dynamic> data)
```

**判定**: 与现有架构一致 ✅
- 参数类型与 `PointService.update(String id, Map<String, dynamic> data)` 匹配
- 内部实现模式与 `createPoint()` / `deletePoint()` 一致
- 使用 `state = await AsyncValue.guard(build)` 刷新列表 → 与现有模式一致

### 2.5 pointValueProvider 设计冗余

**位置**: §2.4

**问题**: 设计 §2.4 定义了 `pointValueProvider`（FutureProvider.family），但 §6.1 Step 3 的实现方案显示 PointValueDisplay 直接调用 `PointService.getValue()`，**完全未使用该 Provider**。

**建议**: 
- 如果 PointValueDisplay 已通过 ConsumerState 自行管理值加载，则删除 §2.4 中的 `pointValueProvider` 定义
- 或者让 PointValueDisplay 使用 `ref.watch(pointValueProvider(pointId))` 消费该 Provider，并暴露 `ref.invalidate` 供刷新按钮使用

---

## 三、完整性评审

### 3.1 测试用例覆盖率

**53 个测试用例覆盖分析**:

| 测试范围 | 总数 | 设计中直接覆盖 | 需补充说明 | 覆盖率 |
|----------|:---:|:-----------:|:--------:|:-----:|
| PointListWidget | 16 | 16 | 0 | 100% |
| PointFormDialog | 14 | 14 | 0 | 100% |
| PointValueDisplay | 8 | 8 | 0 | 100% |
| WorkbenchDetailPage 集成 | 8 | 8 | 0 | 100% |
| 响应式 | 4 | 4 | 0 | 100% |
| 无障碍 | 3 | 2 | 1 (TC-A11Y-003 键盘导航) | 67% |
| **总计** | **53** | **52** | **1** | **98%** |

**遗漏项**:
- **TC-A11Y-003** (键盘导航): §6.1 实现计划中未明确提及 Tab 键遍历、Enter 提交、ESC 关闭等键盘交互要求。建议在 §6.1 Step 2 (PointFormDialog) 中增加键盘导航实现要点。

### 3.2 UI 设计规范映射

从组件树 §1 和 UI 实现计划 §6 的映射关系：

| 设计规范需求 | 实现方案位置 | 覆盖状态 |
|-------------|-------------|:------:|
| 测点表格 6 列 | §6.1 Step 1.4 | ✅ |
| 类型标签颜色 (Number蓝/Integer紫/Boolean绿/String橙) | §6.1 Step 1.4 | ✅ |
| 访问权限图标 (RO/WO/RW) | §6.1 Step 1.4 | ✅ |
| Hover 效果 (OnSurface 4%) | §6.1 Step 1.4 | ✅ |
| 状态圆点 (8px, 三色) | §6.1 Step 3.4 | ✅ |
| 刷新按钮 (20px, 旋转动画) | §6.1 Step 3.5 + §B-02 | ✅ |
| 移动端 Card 布局 | §6.1 Step 1.5 | ✅ |
| 桌面端 DataTable | §6.1 Step 1.4 | ✅ |
| PointFormDialog 响应式 | §6.1 Step 2 + §6.4 | ✅ |
| Modbus ExpansionTile | §6.1 Step 2.5 | ✅ |
| 表单验证 (失焦触发) | §6.1 Step 2.4 | ✅ |
| 保存按钮 loading 状态 | §6.1 Step 2.6 | ✅ |
| 三态 (Loading/Error/Empty/Data) | §6.1 Step 1.3 | ✅ |

### 3.3 l10n Key 设计完整性

设计 §7 列出了 **31+ 个新增 key**（实际计数：P0 17 + P1 14 + DataType 4 + AccessType 3 + Boolean 2 = 40，其中部分已有可复用），每个 key 均明确了英文/中文/用途。✅

**验证要点**:
- `@placeholders` 配置已覆盖 `pointCount` 和 `pointDeleteConfirm` ✅
- 数据类型选项 (dataTypeNumber/Integer/Boolean/String) 明确 ✅
- 访问权限选项 (accessTypeRo/Wo/Rw) 明确 ✅
- 布尔值显示 (booleanTrue/False) 明确 ✅
- 复用的现有 key (edit/delete/save/cancel/retry/deviceDetail/deviceDetailPlaceholder) 已列出 ✅

### 3.4 遗漏项汇总

| # | 类别 | 描述 | 严重度 |
|---|------|------|:-----:|
| M-01 | 实现 | PointValueDisplay 的 `status` 属性传递路径不明确 — Point 模型有 `status` 字段，PointListNotifier 通过 `refreshValues()` 更新值缓存但不更新 Point.status。PointValueDisplay 如何获取实时的 status？ | SUGGESTION |
| M-02 | 实现 | 键盘导航 (TC-A11Y-003) 在设计 §6 中无对应实现要点 | SUGGESTION |
| M-03 | 设计 | §2.4 `pointValueProvider` 定义后未被 §6 使用 → 冗余或遗漏 | SUGGESTION |
| M-04 | 架构 | `updatePoint()` 刷新列表时会短暂显示 loading 状态（state = AsyncLoading），导致整个列表闪烁重建。现有 `createPoint()`/`deletePoint()` 有相同问题，但这应该是未来优化的技术债记录 | SUGGESTION |

---

## 四、文件修改清单验证

设计 §8 提出的 7 项文件修改：

| 操作 | 文件 | 行数估计 | 结论 |
|:----:|------|:-------:|:---:|
| 新建 | `lib/pages/point/point_list_widget.dart` | ~350 | ✅ 合理 |
| 新建 | `lib/pages/point/point_form_dialog.dart` | ~450 | ✅ 合理 |
| 新建 | `lib/pages/point/point_value_display.dart` | ~180 | ✅ 合理 |
| 修改 | `lib/providers/point_provider.dart` | ~20 (新增 updatePoint) | ✅ 合理 |
| 修改 | `lib/pages/workbench/workbench_detail_page.dart` | 替换 _PointListSection | ✅ 合理 |
| 修改 | `lib/l10n/app_en.arb` / `app_zh.arb` | 28+ keys | ✅ 合理 |
| 可选 | `lib/models/point.dart` | 新增 address/metadata | ⚠️ 取决于 B-02 决策 |

**文件组织结构**: 三个新建文件放在 `lib/pages/point/` 下是合理的目录结构。与现有 `lib/pages/device/` 模式一致 ✅

---

## 五、BLOCKING 问题清单

| # | 问题 | 位置 | 严重度 | 修正方向 |
|---|------|------|:-----:|----------|
| B-01 | D-05 编辑模式数据加载方式与 §3.3/§6.1 矛盾 | §3.3 行 564 / §D-05 行 1125 | 🔴 BLOCKING | 统一为一种方案并修正所有引用 |
| B-02 | Modbus 字段 (address/register_type/data_format) 无法经过当前后端 API 持久化 | §5 全节 | 🔴 BLOCKING | 选择方案 A (协调后端) 或 B (占位状态)；不能选择方案 C/D |

---

## 六、SUGGESTION 问题清单

| # | 类别 | 描述 | 建议 |
|---|------|------|------|
| S-01 | 设计 | `pointValueProvider` §2.4 定义但 §6 未使用 | 删除或改用 ref.watch |
| S-02 | 实现 | PointValueDisplay.status 传递路径 | 在 §6.1 Step 3 中补充 status 来源说明 |
| S-03 | 完整性 | TC-A11Y-003 键盘导航无实现要点 | 在 §6.1 Step 2 增加键盘导航要求 |
| S-04 | 架构 | updatePoint() 导致列表闪烁 | 可标注为 [KNOWN_TECHDEBT] 等待后续优化 |
| S-05 | 完整性 | RW 测点值写入 (setValue) 未在设计/测试中覆盖 | 非 TASK-018/019 范围但值得记录为后续任务 |

---

## 七、最终结论

> ## ⚠️ NEEDS_REVISION
>
> 详细设计文档结构清晰、组件层次分明、Data Flow 图完整、l10n 覆盖充分。**架构合规性整体良好**，Riverpod 3.x 模式使用正确，DeviceConfigDialog 模式对齐良好。
>
> **必须修正的 2 项 BLOCKING 问题**：
>
> 1. **B-01**: D-05 与 §3.3/§6.1 关于编辑模式数据加载的矛盾 — 需统一方案
> 2. **B-02**: Modbus 字段存储策略缺陷 — 需明确前端-Modbus 功能在本次 Release 的范围
>
> **建议修正的 5 项 SUGGESTION**：
>
> S-01~S-05 （详见第六章）
>
> 待 B-01 和 B-02 修正后，结论可升级为 **APPROVED**，进入 TASK-018/019 开发阶段。

---

**附录：设计文档亮点**

1. 📊 **Mermaid 图表质量高**: 组件树、类图、5 个序列图 (加载/添加/编辑/删除/值刷新) 都清晰表达了数据流
2. 📋 **决策记录表 (附录 A)**: 6 个技术决策有选项对比和选择理由，是可追溯的架构实践
3. 🔧 **自检清单 (§6.3)**: 与测试用例对齐，提供了开发自检参照
4. 📝 **问题透明度**: B-02 风险等级评估表 (§5.6) 坦诚地列出了3个风险及其缓解措施

---

*评审人: sw-jerry (Software Architect)*
*日期: 2026-06-01*
*下次评审条件: B-01 和 B-02 修正后*

---

## 八、二次评审结论（v1.1）

> **评审人**: sw-jerry (Software Architect)
> **评审日期**: 2026-06-01
> **评审对象**: `log/release_3/design/TASK-018_design.md` v1.1
> **评审版本**: 仅验证 B-01 和 B-02 修正

### B-01 修正验证：编辑模式数据加载方案统一性

| 验证点 | v1.1 内容 | 判定 |
|--------|-----------|:--:|
| §3.3 序列图 | 行 563 `PointFormDialog.show(deviceId, existing=point)`, 行 566 `从 existing 数据预填表单字段` — 无 `getById` 调用 | ✅ |
| PointFormDialog 构造函数 | 行 355 `this.existing` (`final Point? existing`) | ✅ |
| PointFormDialog 文档注释 | 行 337-341 "父组件通过 [existing] 参数传入 [Point] 对象预填表单，**无需额外 API 调用**" | ✅ |
| §6.1 Step 2 实现要点 | 行 891-892 "父组件传入 existing: Point … **不额外调用 PointService.getById()**" | ✅ |
| §D-05 决策记录 | 行 1138 仍选 B，理由 "现有 Point 对象已包含编辑所需全部字段，避免额外 API 调用" | ✅ |

**结论**：全部 5 处矛盾引用已统一切换为"父组件传入 `existing: Point`"方案。**B-01 已解决。** ✅

### B-02 修正验证：Modbus 字段存储方案

| 验证点 | v1.1 方案 | 判定 |
|--------|-----------|:--:|
| 存储位置 | `device.protocol_params.points[pointId]`（§5.3） | ✅ |
| `Point` 模型 | 不做字段扩展（§4.3 划线删除、§6.2 划线删除） | ✅ |
| 保存流程 | 两步：先 `createPoint` 基本字段 → 再 `DeviceService.update()` 写入 `protocol_params`（§C-1） | ✅ |
| 读取回填 | `deviceDetailProvider` → `device.protocol_params.points[pointId].*`（§5.4） | ✅ |
| 并发保护 | Read-Modify-Write：先 `getById` 读完整 `protocol_params` → 仅更新 `points[pointId]` 子键 → 写回（§C-2） | ✅ |
| 风险记录 | 5 项风险及缓解措施（§5.6） | ✅ |
| 长期迁移路径 | 后端扩展 `metadata` 字段后的迁移方案（§5.3 长期方案） | ✅ |
| D-06 决策 | 行 1139 选 B（device protocol_params），标注 A 为长期目标 | ✅ |
| `DeviceService.update()` | 已确认存在于 `lib/services/device_service.dart`（§5.5） | ✅ |

**结论**：采用 device `protocol_params` 作为短期存储方案，`Point` 模型不做字段扩展，技术可行性已得到保证，风险已充分记录并有缓解措施。**B-02 已解决。** ✅

### SUGGESTION 问题处置说明

| # | v1.0 问题 | v1.1 状态 | 处置 |
|---|-----------|-----------|:--:|
| S-01 | `pointValueProvider` §2.4 定义但 §6 未使用 | 未修正 | → 降级为 **实施提醒**：开发时建议统一使用 `pointValueProvider` 而非在 StatefulWidget 中直接调 Service，以保持 Provider 层一致性 |
| S-02 | PointValueDisplay.status 传递路径不明确 | 未修正 | → 降级为 **实施提醒**：开发时需确认 `Point.status` 在 `refreshValues()` 后的更新机制 |
| S-03 | TC-A11Y-003 键盘导航 | 未修正 | → 降级为 **实施提醒**：UI 开发时需关注 Tab/Enter/ESC 键盘交互 |
| S-04 | updatePoint() 列表闪烁 | 未修正 | → 降级为 **KNOWN_TECHDEBT**：不影响功能，后续可优化为精细更新 |
| S-05 | RW 测点值写入 | 未修正 | → 确认非本 Task 范围 |

以上 5 项 SUGGESTION 均非阻塞性问题，不阻止进入开发阶段。

---

## ✅ APPROVED

> 两次 BLOCKING 问题（B-01 编辑模式数据加载矛盾、B-02 Modbus 字段存储策略）已在 v1.1 中全部修正并经逐行验证通过。设计文档完整性良好，架构合规性达标，技术可行性明确。
>
> **sw-tom 可立即进入 TASK-018/019 开发实现阶段。**

---

*二次评审人: sw-jerry (Software Architect)*
*日期: 2026-06-01*
