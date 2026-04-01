# S2-006 Code Review Report

**任务ID**: S2-006  
**任务名称**: 数据管理页面 - 试验详情与数据查看  
**评审日期**: 2026-04-01  
**评审人**: sw-jerry  
**评审结果**: **NOT APPROVED**

---

## 1. 评审摘要

实现与设计存在多处偏差，主要问题包括：
- 缺少Widget测试所需的Key标识
- 通道选择器未实现动态通道列表
- CSV导出未实现平台特定处理（Web平台不兼容）
- 部分UI细节与测试用例不符

---

## 2. 设计符合性分析

### 2.1 符合项 ✓

| 项目 | 状态 |
|------|------|
| 页面路由结构 | ✓ 符合 |
| State字段结构 (experiment, pointHistory, isLoading, isLoadingHistory, error, historyError, historyPage, hasMoreHistory) | ✓ 符合 |
| 时间戳转换逻辑 (nanoseconds → millisecondsSinceEpoch) | ✓ 符合 |
| CSV格式 (Timestamp,Value + ISO8601) | ✓ 符合 |
| 分页逻辑 (hasMoreHistory = newData.length >= 100) | ✓ 符合 |
| 状态颜色定义 | ✓ 符合 |
| Provider定义 | ✓ 符合 |

### 2.2 偏差项 ✗

| 项目 | 设计要求 | 实现情况 | 严重程度 |
|------|----------|----------|----------|
| **ChannelSelector组件** | 应支持动态channels列表 | 硬编码只包含'default'通道 | 高 |
| **CSV导出** | 平台特定实现 (Web: FileSaver, Mobile: share_plus, Desktop: file_picker) | 直接使用dart:io File (Web平台不兼容) | 高 |
| **Widget测试Key** | retry_button, export_csv_button, channel_selector | 均未添加 | 中 |
| **自动加载历史数据** | 试验加载完成后自动加载默认通道历史 | 未实现 | 中 |
| **空描述占位符** | 应显示"暂无描述" | 直接不显示描述行 | 低 |

---

## 3. 测试用例覆盖分析

### 3.1 可通过测试用例 ✓

以下测试用例在假设添加Key标识后可正常通过：

- TC-STATE-001 ~ TC-STATE-006: State管理测试 ✓
- TC-NOTIFIER-001 ~ TC-NOTIFIER-004: Notifier逻辑测试 ✓
- TC-UI-001: 显示试验名称 ✓
- TC-UI-002: 部分通过（缺少"暂无描述"占位符）
- TC-UI-003: 时间信息展示 ✓
- TC-UI-004: 加载状态显示 ✓
- TC-UI-006: 表格显示（表头文字不匹配）

### 3.2 无法通过的测试用例 ✗

| 测试ID | 问题描述 | 原因 |
|--------|----------|------|
| TC-UI-005 | 重试按钮缺少Key | `find.byKey(const Key('retry_button'))` 无法找到 |
| TC-UI-006 | 表头文字不匹配 | 期望"时间"，实际"时间戳" |
| TC-UI-008 | 导出按钮缺少Key | `find.byKey(const Key('export_csv_button'))` 无法找到 |
| TC-UI-009 | 通道选择器缺少Key | `find.byKey(const Key('channel_selector'))` 无法找到 |
| TC-UI-010 | 自动加载历史数据 | 试验加载完成后未触发loadPointHistory |
| TC-INT-001 | 重试功能（通道历史） | 缺少Key导致测试无法正确定位元素 |

---

## 4. 具体问题详情

### 4.1 高优先级问题

#### 问题1: CSV导出Web平台不兼容
**位置**: `experiment_detail_page.dart` 第458-490行

**问题描述**:
```dart
Future<void> _exportCsv(BuildContext context) async {
  // ...
  final file = File(fileName);  // dart:io 在Web平台不可用
  await file.writeAsString(csv);
```
设计文档6.4节明确要求平台特定实现：
- Web: FileSaver
- Android/iOS: share_plus  
- Desktop: file_picker

**建议修复**:
使用 `file_picker` 包统一处理，或使用条件导入：
```dart
import 'file_picker/file_picker.dart' if (dart.library.html) 'file_picker_stub.dart';
```

---

#### 问题2: 通道选择器不支持动态通道
**位置**: `experiment_detail_page.dart` 第199-218行

**问题描述**:
```dart
DropdownButton<String>(
  value: _selectedChannel,
  items: const [
    DropdownMenuItem(value: 'default', child: Text('default')),
  ],
```
设计文档3.3.3节定义ChannelSelector应接收`channels`参数，且5.2节说明通道来源于`Experiment.channels`。

**建议修复**:
从Experiment模型获取channels列表，或调用API获取可用通道。

---

### 4.2 中优先级问题

#### 问题3: 缺少Widget测试Key标识
**位置**: 多处

以下Key未添加到相应Widget：
- `Key('retry_button')` - 重试按钮
- `Key('export_csv_button')` - 导出CSV按钮
- `Key('channel_selector')` - 通道选择下拉框

**影响**: Widget测试用例无法正确定位元素

---

#### 问题4: 试验加载后未自动加载历史数据
**位置**: `experiment_detail_page.dart` 第32-40行

**问题描述**:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(experimentDetailProvider.notifier).loadExperiment(widget.experimentId);
  });
}
```
只加载了试验详情，未自动加载默认通道的历史数据。TC-UI-010期望试验加载完成后自动调用`loadPointHistory`。

**建议修复**:
在loadExperiment完成后，监听state变化，触发loadPointHistory调用。

---

### 4.3 低优先级问题

#### 问题5: 表头文字不一致
**位置**: `experiment_detail_page.dart` 第368行

**问题**: 实际使用"时间戳"，测试期望"时间"
```dart
Expanded(child: _buildHeaderCell(context, '时间戳', flex: 2)),
```
建议与测试用例对齐或更新测试用例。

---

#### 问题6: 描述为空时缺少占位符
**位置**: `experiment_detail_page.dart` 第175-176行

**问题**: 
```dart
if (experiment.description != null)
  _buildInfoRow('描述', experiment.description!),
```
TC-UI-002期望无描述时显示"暂无描述"，实际完全不显示描述行。

**建议修复**:
```dart
_buildInfoRow('描述', experiment.description ?? '暂无描述'),
```

---

## 5. 技术债务

| 项目 | 描述 |
|------|------|
| 未使用的import | `dart:io` 在Web平台不可用，应移除或条件导入 |
| 代码重复 | 状态颜色定义在多处重复 (Design 9.1节定义的颜色) |

---

## 6. 修复建议优先级

### 必须修复 (阻塞发布)
1. CSV导出Web平台兼容性
2. 动态通道列表支持

### 建议修复 (发布前修复)
3. 添加Widget测试Key标识
4. 实现自动加载历史数据

### 可选修复 (后续迭代)
5. 表头文字对齐
6. 空描述占位符

---

## 7. 结论

**评审结果**: NOT APPROVED

实现基本功能框架正确，但存在2个高优先级问题阻塞发布：
1. Web平台CSV导出不兼容
2. 通道选择器无法支持动态通道列表

建议修复上述问题后重新评审。

---

**签名**: sw-jerry  
**日期**: 2026-04-01
