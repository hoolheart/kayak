# R2-S1-002-B 时序图表组件 — Widget 测试用例

**任务**: R2-S1-002-B 时序图表组件 Widget 测试用例设计
**测试设计者**: sw-mike
**日期**: 2026-05-10
**被测模块**:
- `lib/features/analysis/screens/analysis_page.dart` (分析页面)
- `lib/features/analysis/widgets/time_series_chart.dart` (时序图表组件)
- `lib/features/analysis/widgets/chart_legend_bar.dart` (图例栏)
- `lib/features/analysis/widgets/chart_toolbar.dart` (图表工具栏)
- `lib/features/analysis/widgets/chart_tooltip.dart` (数据提示框)
- `lib/features/analysis/widgets/chart_empty_state.dart` (空状态)
- `lib/features/analysis/widgets/chart_loading_state.dart` (加载状态)
- `lib/features/analysis/widgets/chart_error_state.dart` (错误状态)
- `lib/features/analysis/widgets/control_panel.dart` (控制面板)
- `lib/features/analysis/widgets/data_preview_table.dart` (数据表格)
- `lib/features/analysis/providers/chart_data_provider.dart` (图表数据状态管理)

---

## 文档目录

1. [测试策略与范围](#一测试策略与范围)
2. [测试数据设计](#二测试数据设计)
3. [Mock 与辅助函数](#三mock-与辅助函数)
4. [页面结构测试](#四页面结构测试)
5. [图表状态测试](#五图表状态测试)
6. [图表渲染测试](#六图表渲染测试)
7. [图例交互测试](#七图例交互测试)
8. [主题适配测试](#八主题适配测试)
9. [控制面板交互测试](#九控制面板交互测试)
10. [错误状态测试](#十错误状态测试)
11. [fl_chart Widget 测试特殊注意事项](#十一fl_chart-widget-测试特殊注意事项)
12. [用例汇总表](#十二用例汇总表)

---

## 一、测试策略与范围

### 1.1 测试类型

本次测试为 **Flutter Widget 测试**，使用 `flutter_test` 框架，结合 `mocktail` 进行依赖模拟。

### 1.2 测试范围

| 范围项 | 包含 | 不包含 |
|--------|------|--------|
| 页面结构渲染 | ✅ 控制面板、图表区、数据表格 | ❌ AppBar、Sidebar（复用现有组件） |
| 图表空/加载/错误状态 | ✅ 全部测试 | |
| 单/多曲线渲染 | ✅ 最多4条曲线 | ❌ 超过4条曲线（业务层限制） |
| 图例交互 | ✅ 点击隐藏/显示 | ❌ 双击solo、Ctrl+点击（P1功能） |
| 主题适配 | ✅ 深色/浅色主题颜色验证 | ❌ 主题切换动画 |
| 控制面板交互 | ✅ 选择试验/设备/测点触发加载 | ❌ 时间范围选择器完整测试 |
| 图表交互 | ✅ 视图复位按钮 | ❌ 滚轮缩放、拖拽平移（需集成测试） |
| 数据表格 | ✅ 展开/收起、表头渲染 | ❌ 排序、行点击高亮 |

### 1.3 测试环境

- **测试框架**: `flutter_test` + `mocktail`
- **状态管理**: `flutter_riverpod` (使用 `ProviderScope` override)
- **路由**: `go_router` (使用 `MaterialApp.router` 或简化路由)
- **屏幕尺寸**: 1440×1080 (桌面端默认)
- **Flutter 版本**: 3.19+

---

## 二、测试数据设计

### 2.1 模拟试验数据

```dart
/// 试验列表数据
final mockExperiments = [
  Experiment(
    id: 'exp-001',
    userId: 'user-001',
    name: '温度压力联合测试',
    status: ExperimentStatus.completed,
    createdAt: DateTime.parse('2026-05-01T00:00:00Z'),
    updatedAt: DateTime.parse('2026-05-01T23:59:59Z'),
  ),
  Experiment(
    id: 'exp-002',
    userId: 'user-001',
    name: '流量稳定性试验',
    status: ExperimentStatus.running,
    createdAt: DateTime.parse('2026-05-02T10:00:00Z'),
    updatedAt: DateTime.parse('2026-05-02T10:30:00Z'),
  ),
];

/// 设备列表数据
final mockDevices = [
  Device(
    id: 'dev-001',
    workbenchId: 'wb-001',
    name: '虚拟传感器A',
    protocolType: ProtocolType.virtual,
    status: DeviceStatus.online,
  ),
  Device(
    id: 'dev-002',
    workbenchId: 'wb-001',
    name: 'Modbus温控器',
    protocolType: ProtocolType.modbusTcp,
    status: DeviceStatus.online,
  ),
];

/// 测点列表数据
final mockPoints = [
  Point(
    id: 'pt-001',
    deviceId: 'dev-001',
    name: 'Temperature',
    dataType: DataType.number,
    unit: '°C',
    minValue: -40.0,
    maxValue: 85.0,
  ),
  Point(
    id: 'pt-002',
    deviceId: 'dev-001',
    name: 'Pressure',
    dataType: DataType.number,
    unit: 'Pa',
    minValue: 0.0,
    maxValue: 100000.0,
  ),
  Point(
    id: 'pt-003',
    deviceId: 'dev-001',
    name: 'Flow Rate',
    dataType: DataType.number,
    unit: 'L/min',
    minValue: 0.0,
    maxValue: 100.0,
  ),
  Point(
    id: 'pt-004',
    deviceId: 'dev-001',
    name: 'Vibration',
    dataType: DataType.number,
    unit: 'mm/s',
    minValue: 0.0,
    maxValue: 10.0,
  ),
  Point(
    id: 'pt-005',
    deviceId: 'dev-001',
    name: 'Humidity',
    dataType: DataType.number,
    unit: '%RH',
    minValue: 0.0,
    maxValue: 100.0,
  ),
];
```

### 2.2 模拟时序数据响应

```dart
/// 单曲线数据（温度）
final mockSingleCurveData = ChartDataResponse(
  experimentId: 'exp-001',
  deviceId: 'dev-001',
  points: [
    ChartPointSeries(
      pointId: 'pt-001',
      pointName: 'Temperature',
      unit: '°C',
      dataType: 'float32',
      timestamps: List.generate(
        100,
        (i) => 1714521600000 + i * 60000, // 1分钟间隔
      ),
      values: List.generate(
        100,
        (i) => 25.0 + 5.0 * sin(2 * pi * i / 100),
      ),
    ),
  ],
  totalSamples: 100,
  returnedSamples: 100,
);

/// 多曲线数据（4条曲线）
final mockMultiCurveData = ChartDataResponse(
  experimentId: 'exp-001',
  deviceId: 'dev-001',
  points: [
    ChartPointSeries(
      pointId: 'pt-001',
      pointName: 'Temperature',
      unit: '°C',
      dataType: 'float32',
      timestamps: List.generate(100, (i) => 1714521600000 + i * 60000),
      values: List.generate(100, (i) => 25.0 + 5.0 * sin(2 * pi * i / 100)),
    ),
    ChartPointSeries(
      pointId: 'pt-002',
      pointName: 'Pressure',
      unit: 'Pa',
      dataType: 'float32',
      timestamps: List.generate(100, (i) => 1714521600000 + i * 60000),
      values: List.generate(100, (i) => 101325.0 + 1000.0 * cos(2 * pi * i / 100)),
    ),
    ChartPointSeries(
      pointId: 'pt-003',
      pointName: 'Flow Rate',
      unit: 'L/min',
      dataType: 'float32',
      timestamps: List.generate(100, (i) => 1714521600000 + i * 60000),
      values: List.generate(100, (i) => 50.0 + 20.0 * sin(2 * pi * i / 50)),
    ),
    ChartPointSeries(
      pointId: 'pt-004',
      pointName: 'Vibration',
      unit: 'mm/s',
      dataType: 'float32',
      timestamps: List.generate(100, (i) => 1714521600000 + i * 60000),
      values: List.generate(100, (i) => 2.0 + 1.5 * cos(2 * pi * i / 25)),
    ),
  ],
  totalSamples: 400,
  returnedSamples: 400,
);

/// 空数据响应（时间范围内无数据）
final mockEmptyRangeData = ChartDataResponse(
  experimentId: 'exp-001',
  deviceId: 'dev-001',
  points: [],
  totalSamples: 0,
  returnedSamples: 0,
);

/// 降采样数据（1000点）
final mockDownsampledData = ChartDataResponse(
  experimentId: 'exp-001',
  deviceId: 'dev-001',
  points: [
    ChartPointSeries(
      pointId: 'pt-001',
      pointName: 'Temperature',
      unit: '°C',
      dataType: 'float32',
      timestamps: List.generate(1000, (i) => 1714521600000 + i * 86400),
      values: List.generate(1000, (i) => 25.0 + 5.0 * sin(2 * pi * i / 1000)),
    ),
  ],
  totalSamples: 86400,
  returnedSamples: 1000,
);
```

### 2.3 曲线颜色定义（用于断言验证）

```dart
/// 浅色主题曲线颜色
const lightCurveColors = [
  Color(0xFF1976D2), // Primary - Curve 1
  Color(0xFF00838F), // Tertiary - Curve 2
  Color(0xFFC62828), // Error - Curve 3
  Color(0xFF2E7D32), // Success - Curve 4
];

/// 深色主题曲线颜色
const darkCurveColors = [
  Color(0xFF90CAF9), // Primary (dark) - Curve 1
  Color(0xFF80DEEA), // Tertiary (dark) - Curve 2
  Color(0xFFEF5350), // Error Light - Curve 3
  Color(0xFF66BB6A), // Success Light - Curve 4
];
```

---

## 三、Mock 与辅助函数

### 3.1 Service Mock

```dart
class MockAnalysisService extends Mock implements AnalysisService {}
class MockExperimentService extends Mock implements ExperimentService {}
class MockDeviceService extends Mock implements DeviceService {}
```

### 3.2 测试辅助函数

```dart
/// 创建带主题的测试应用
Widget createTestableWidget({
  required Widget child,
  required Brightness brightness,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: brightness == Brightness.light
            ? lightColorScheme
            : darkColorScheme,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

/// 创建分析页面（带完整依赖注入）
Widget createAnalysisPage({
  required Brightness brightness,
  required MockAnalysisService analysisService,
  required MockExperimentService experimentService,
  required MockDeviceService deviceService,
}) {
  return ProviderScope(
    overrides: [
      analysisServiceProvider.overrideWithValue(analysisService),
      experimentServiceProvider.overrideWithValue(experimentService),
      deviceServiceProvider.overrideWithValue(deviceService),
    ],
    child: MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: brightness == Brightness.light
            ? lightColorScheme
            : darkColorScheme,
        useMaterial3: true,
      ),
      home: const AnalysisPage(),
    ),
  );
}

/// 模拟 fl_chart LineChart 的 BarAreaData 查找
Finder findLineChart() => find.byType(LineChart);

/// 查找图例项（通过文本）
Finder findLegendItem(String text) => find.widgetWithText(InkWell, text);
```

### 3.3 预设响应配置

```dart
/// 配置标准成功响应
void setupStandardResponses(MockAnalysisService service) {
  when(() => service.queryData(any())).thenAnswer((_) async => mockSingleCurveData);
}

/// 配置延迟响应（用于测试加载状态）
void setupDelayedResponse(MockAnalysisService service, {required Duration delay}) {
  when(() => service.queryData(any())).thenAnswer((_) async {
    await Future.delayed(delay);
    return mockSingleCurveData;
  });
}

/// 配置错误响应
void setupErrorResponse(MockAnalysisService service, {String message = '加载失败'}) {
  when(() => service.queryData(any())).thenThrow(
    ApiException(code: 500, message: message),
  );
}
```

---

## 四、页面结构测试

### TC-STRUCT-001: 页面基础结构渲染

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-STRUCT-001 |
| **测试描述** | 验证分析页面加载时，控制面板、图表区和数据预览区的基本结构正确渲染 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.5, Figma §2.2, Spec §7.2 |

#### 前置条件

1. 模拟试验列表 API 返回 `mockExperiments`
2. 模拟设备列表 API 返回 `mockDevices`
3. 图表数据服务返回空状态（未选择试验时）

#### 测试步骤

1. 使用 `createAnalysisPage(brightness: Brightness.light, ...)` 构建页面
2. 等待 `pumpAndSettle()` 完成初始加载
3. 验证页面结构元素是否存在

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | `find.text('数据分析')` findsOneWidget | 页面标题正确显示 |
| 3.2 | `find.text('查看试验时序数据')` findsOneWidget | 副标题正确显示 |
| 3.3 | `find.byType(ControlPanel)` findsOneWidget | 控制面板组件存在 |
| 3.4 | `find.byType(TimeSeriesChart)` findsOneWidget | 图表组件存在 |
| 3.5 | `find.byType(ChartToolbar)` findsOneWidget | 图表工具栏存在 |
| 3.6 | `find.byType(ChartLegendBar)` findsOneWidget | 图例栏存在 |
| 3.7 | `find.byType(DataPreviewSection)` findsNothing | 数据预览区默认收起 |
| 3.8 | 控制面板宽度 == 320.0 | 桌面端控制面板固定宽度 |

---

### TC-STRUCT-002: 控制面板内部卡片结构

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-STRUCT-002 |
| **测试描述** | 验证控制面板内的4个功能卡片和按钮区正确渲染 |
| **优先级** | P0 |
| **关联需求** | Figma §3.2, Spec §5.1 |

#### 前置条件

同 TC-STRUCT-001

#### 测试步骤

1. 构建分析页面并等待加载完成
2. 在控制面板范围内查找各卡片

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 2.1 | `find.text('选择试验')` findsOneWidget | 试验选择卡片标题 |
| 2.2 | `find.text('选择设备与测点')` findsOneWidget | 设备与测点选择卡片标题 |
| 2.3 | `find.text('时间范围')` findsOneWidget | 时间范围卡片标题 |
| 2.4 | `find.text('图表设置')` findsOneWidget | 设置卡片标题 |
| 2.5 | `find.text('加载数据')` findsOneWidget | 加载数据按钮 |
| 2.6 | `find.text('重置视图')` findsOneWidget | 重置视图按钮 |
| 2.7 | `find.text('降采样点数')` findsOneWidget | 降采样设置标签 |
| 2.8 | `find.byType(Slider)` findsOneWidget | 降采样滑块存在 |

---

### TC-STRUCT-003: 面包屑导航与侧边栏集成

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-STRUCT-003 |
| **测试描述** | 验证分析页面在 AppShell 中正确显示面包屑导航 |
| **优先级** | P1 |
| **关联需求** | Figma §2.2, UI §5.2 |

#### 前置条件

1. 使用完整路由配置构建页面（`MaterialApp.router`）
2. 当前路由为 `/analysis`

#### 测试步骤

1. 构建带 go_router 的完整应用
2. 导航至 `/analysis`
3. 等待加载完成

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | `find.text('首页')` findsOneWidget | 面包屑首页链接 |
| 3.2 | `find.text('分析')` findsOneWidget | 面包屑当前页 |
| 3.3 | `find.byIcon(Icons.analytics)` findsOneWidget | 侧边栏分析导航项高亮 |

---

### TC-STRUCT-004: 数据预览区展开与收起

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-STRUCT-004 |
| **测试描述** | 验证"显示数据表格"开关控制数据预览区的展开与收起 |
| **优先级** | P1 |
| **关联需求** | Figma §3.4, Spec §8.2 |

#### 前置条件

1. 图表已有数据加载完成（`mockSingleCurveData`）
2. 数据预览区默认收起

#### 测试步骤

1. 构建页面并加载数据
2. 查找"显示数据表格" Switch
3. 点击 Switch 开启
4. 等待动画完成
5. 验证数据表格区域显示
6. 再次点击 Switch 关闭
7. 验证数据表格区域隐藏

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 5.1 | `find.byType(DataPreviewTable)` findsOneWidget | 数据表格组件显示 |
| 5.2 | `find.text('数据预览')` findsOneWidget | 数据预览区标题 |
| 5.3 | `find.text('时间戳')` findsOneWidget | 表格时间戳列标题 |
| 5.4 | `find.text('Temperature')` findsWidgets | 测点名称列标题 |
| 7.1 | `find.byType(DataPreviewTable)` findsNothing | 数据表格组件隐藏 |

---

## 五、图表状态测试

### TC-STATE-001: 空状态渲染（未选择试验）

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-STATE-001 |
| **测试描述** | 验证未选择试验时，图表区域显示空状态提示 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.3, Figma §4.1, Spec §8.1 |

#### 前置条件

1. 页面初始状态：未选择任何试验
2. 图表数据 Provider 状态为 `ChartState.empty`

#### 测试步骤

1. 构建分析页面
2. 等待初始加载完成
3. 验证空状态 UI 元素
4. 验证图表画布未渲染 fl_chart

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | `find.byType(ChartEmptyState)` findsOneWidget | 空状态组件存在 |
| 3.2 | `find.text('暂无数据')` findsOneWidget | 空状态标题 |
| 3.3 | `find.text('请选择试验并加载数据以查看时序图表')` findsOneWidget | 空状态描述 |
| 3.4 | `find.byIcon(Icons.insert_chart_outlined)` findsOneWidget | 空状态图标 |
| 3.5 | `find.byType(LineChart)` findsNothing | 未渲染实际图表 |
| 3.6 | 空状态背景色 == `Color(0xFFFFFFFF)` (Light) | 浅色主题背景色正确 |

#### 补充断言（深色主题）

```dart
// 使用 Brightness.dark 构建页面后：
expect(
  tester.widget<Container>(find.byType(Container).first).color,
  equals(const Color(0xFF0A0A0A)),
);
```

---

### TC-STATE-002: 加载状态渲染

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-STATE-002 |
| **测试描述** | 验证点击"加载数据"后，图表区域显示加载指示器 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.3, Figma §4.2, Spec §8.1 |

#### 前置条件

1. 已选择试验 `exp-001`
2. 已选择设备 `dev-001`
3. 已选择测点 `pt-001`
4. 配置延迟响应：`setupDelayedResponse(service, delay: const Duration(seconds: 2))`

#### 测试步骤

1. 构建页面并完成选择
2. 点击"加载数据"按钮
3. 在延迟期间立即验证加载状态
4. 验证加载状态 UI 元素
5. 等待响应完成后验证加载状态消失

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | `find.byType(ChartLoadingState)` findsOneWidget | 加载状态组件存在 |
| 3.2 | `find.byType(CircularProgressIndicator)` findsOneWidget | 加载指示器存在 |
| 3.3 | `find.text('正在加载数据...')` findsOneWidget | 加载标题 |
| 3.4 | `find.text('正在从 HDF5 文件读取时序数据')` findsOneWidget | 加载描述 |
| 3.5 | `find.byType(LinearProgressIndicator)` findsOneWidget | 进度条存在（可选） |
| 3.6 | "加载数据"按钮显示 CircularProgressIndicator (16px) | 按钮进入 loading 状态 |
| 5.1 | `find.byType(ChartLoadingState)` findsNothing | 加载完成后消失 |
| 5.2 | `find.byType(LineChart)` findsOneWidget | 图表正确渲染 |

---

### TC-STATE-003: 时间范围内无数据状态

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-STATE-003 |
| **测试描述** | 验证 API 返回空数据集时显示"所选时间范围内无数据"提示 |
| **优先级** | P1 |
| **关联需求** | Figma §4.4, Spec §8.1 |

#### 前置条件

1. 已选择试验、设备、测点
2. 配置响应返回空数据：`mockEmptyRangeData`

#### 测试步骤

1. 构建页面并完成选择
2. 点击"加载数据"
3. 等待加载完成
4. 验证无数据状态 UI

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 4.1 | `find.text('所选时间范围内无数据')` findsOneWidget | 无数据提示标题 |
| 4.2 | `find.text('请调整时间范围或选择其他试验')` findsOneWidget | 操作建议文本 |
| 4.3 | `find.byIcon(Icons.search_off)` findsOneWidget | 无数据图标 |
| 4.4 | `find.text('调整时间范围')` findsOneWidget | 调整时间范围按钮 |

---

## 六、图表渲染测试

### TC-RENDER-001: 单曲线正确渲染

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-RENDER-001 |
| **测试描述** | 验证选择单个测点时，图表正确显示一条曲线，颜色和坐标轴正确 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.3, Figma §3.3.2, Spec §2.1.1 |

#### 前置条件

1. 选择试验 `exp-001`，设备 `dev-001`，测点 `pt-001` (Temperature)
2. 配置响应返回 `mockSingleCurveData`
3. 使用浅色主题

#### 测试步骤

1. 构建页面并完成选择
2. 点击"加载数据"
3. 等待加载完成
4. 验证 fl_chart 组件渲染
5. 验证曲线颜色
6. 验证图例显示

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 4.1 | `find.byType(LineChart)` findsOneWidget | LineChart 组件已渲染 |
| 4.2 | `find.byType(LineChartData)` isNotNull | 通过 widget 属性获取数据 |
| 5.1 | 第一条曲线颜色 == `Color(0xFF1976D2)` | 曲线1使用 Primary 颜色 |
| 5.2 | 曲线线宽 == 2.0 | 线宽符合规范 |
| 5.3 | 数据点数量 == 100 | 所有数据点已渲染 |
| 6.1 | `find.text('Temperature')` findsOneWidget | 图例显示测点名称 |
| 6.2 | `find.text('°C')` findsWidgets | 图例显示单位 |
| 6.3 | `find.textContaining('25.')` findsOneWidget | 图例显示当前值 |
| 6.4 | 图例颜色线颜色 == `Color(0xFF1976D2)` | 图例颜色指示块正确 |

#### 坐标轴验证

```dart
// 获取 LineChartData 验证坐标轴配置
final lineChart = tester.widget<LineChart>(find.byType(LineChart));
final data = lineChart.data;

expect(data.gridData.show, isTrue);
expect(data.gridData.drawHorizontalLine, isTrue);
expect(data.gridData.drawVerticalLine, isTrue);
expect(data.titlesData.show, isTrue);
expect(data.lineBarsData.length, equals(1));
expect(data.lineBarsData[0].spots.length, equals(100));
```

---

### TC-RENDER-002: 多曲线渲染与颜色分配

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-RENDER-002 |
| **测试描述** | 验证选择4个测点时，图表正确显示4条不同颜色的曲线 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.3, Figma §3.3.2, Spec §2.1.1 |

#### 前置条件

1. 选择试验 `exp-001`，设备 `dev-001`
2. 选择测点 `pt-001`, `pt-002`, `pt-003`, `pt-004`（4个测点）
3. 配置响应返回 `mockMultiCurveData`
4. 使用浅色主题

#### 测试步骤

1. 构建页面并选择4个测点
2. 点击"加载数据"
3. 等待加载完成
4. 验证曲线数量和颜色
5. 验证图例栏显示

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 4.1 | `data.lineBarsData.length` == 4 | 4条曲线数据 |
| 4.2 | 曲线1颜色 == `Color(0xFF1976D2)` | Primary |
| 4.3 | 曲线2颜色 == `Color(0xFF00838F)` | Tertiary |
| 4.4 | 曲线3颜色 == `Color(0xFFC62828)` | Error |
| 4.5 | 曲线4颜色 == `Color(0xFF2E7D32)` | Success |
| 5.1 | `find.text('Temperature')` findsOneWidget | 图例1 |
| 5.2 | `find.text('Pressure')` findsOneWidget | 图例2 |
| 5.3 | `find.text('Flow Rate')` findsOneWidget | 图例3 |
| 5.4 | `find.text('Vibration')` findsOneWidget | 图例4 |
| 5.5 | `find.text('已选择 4/4')` findsOneWidget | 已选计数正确 |

---

### TC-RENDER-003: 多曲线图例当前值显示

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-RENDER-003 |
| **测试描述** | 验证图例栏显示每条曲线的最新（或光标处）数值 |
| **优先级** | P1 |
| **关联需求** | Figma §3.3.3, Spec §5.4 |

#### 前置条件

同 TC-RENDER-002

#### 测试步骤

1. 构建页面并加载4条曲线数据
2. 等待渲染完成
3. 验证图例栏中各曲线的当前值显示格式

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | 图例数值使用等宽字体 | `fontFamily == 'monospace'` |
| 3.2 | 图例数值颜色为对应曲线颜色 | Temperature 值颜色 == Primary |
| 3.3 | 数值格式保留合适小数位 | 如 `25.34` 而非 `25.340000` |
| 3.4 | 单位显示在数值右侧 | 格式: `25.34 °C` |

---

## 七、图例交互测试

### TC-LEGEND-001: 点击图例隐藏曲线

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-LEGEND-001 |
| **测试描述** | 验证点击图例项可隐藏对应曲线，图表和图例同步更新 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.3, Figma §5.1, Spec §5.4 |

#### 前置条件

1. 已加载2条曲线数据（Temperature, Pressure）
2. 图表状态为 `ChartState.loaded`

#### 测试步骤

1. 构建页面并加载多曲线数据
2. 等待渲染完成
3. 点击"Temperature"图例项
4. 验证曲线隐藏
5. 验证图例状态更新
6. 再次点击"Temperature"图例项
7. 验证曲线恢复显示

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 4.1 | 图表中 Temperature 曲线不可见 | `lineBarsData[0].show` == false |
| 4.2 | Temperature 图例项颜色变灰（38%透明度） | 颜色透明度验证 |
| 4.3 | Temperature 图例文字带删除线 | `TextDecoration.lineThrough` |
| 4.4 | Pressure 曲线仍正常显示 | `lineBarsData[1].show` == true |
| 7.1 | Temperature 曲线重新显示 | `lineBarsData[0].show` == true |
| 7.2 | 图例项恢复原始样式 | 无删除线，不透明 |

---

### TC-LEGEND-002: 隐藏多条曲线后图表自适应

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-LEGEND-002 |
| **测试描述** | 验证隐藏部分曲线后，Y轴范围自动适应剩余曲线数据 |
| **优先级** | P1 |
| **关联需求** | R2-ANALYSIS-001 §2.1.3, Spec §5.4 |

#### 前置条件

1. 已加载2条曲线：Temperature (20~30°C), Pressure (100000~102000 Pa)
2. 两条曲线 Y 轴数值范围差异大

#### 测试步骤

1. 构建页面并加载数据
2. 记录当前 Y 轴范围
3. 隐藏 Pressure 曲线
4. 验证 Y 轴范围自适应 Temperature 数据

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 4.1 | Y轴最小值接近 20.0 | 自适应 Temperature 最小值 |
| 4.2 | Y轴最大值接近 30.0 | 自适应 Temperature 最大值 |
| 4.3 | 隐藏 Pressure 后图表重绘 | 无残留视觉元素 |

---

### TC-LEGEND-003: 图例悬停高亮效果

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-LEGEND-003 |
| **测试描述** | 验证悬停图例项时，对应曲线线宽增加（2px→3px） |
| **优先级** | P1 |
| **关联需求** | Figma §5.1, Spec §5.4 |

#### 前置条件

1. 已加载单曲线数据
2. 使用 `tester.hover()` 模拟鼠标悬停（Flutter Web 测试支持）

#### 测试步骤

1. 构建页面并加载数据
2. 获取图例项的 RenderBox 位置
3. 使用 `tester.hover()` 悬停在图例项上
4. 触发重建
5. 验证曲线线宽变化

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 5.1 | 悬停时曲线线宽 == 3.0 | 从 2.0 增加到 3.0 |
| 5.2 | 图例项背景色变化 | `Surface Container` 背景高亮 |
| 5.3 | 鼠标移开后线宽恢复 2.0 | 恢复正常状态 |

**注意**: 此测试在 headless 测试环境中可能受限，需使用 `flutter test --platform chrome` 或 golden test 验证。

---

## 八、主题适配测试

### TC-THEME-001: 浅色主题图表颜色

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-THEME-001 |
| **测试描述** | 验证浅色主题下，图表背景、网格线、曲线颜色正确 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.4, Figma §6.1, Spec §2.1.2 |

#### 前置条件

1. `ThemeData.brightness == Brightness.light`
2. 使用标准浅色 ColorScheme

#### 测试步骤

1. 使用浅色主题构建页面
2. 加载单曲线数据
3. 验证各元素颜色

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | 图表画布背景 == `Color(0xFFFFFFFF)` | Surface |
| 3.2 | 图表工具栏背景 == `Color(0xFFFAFAFA)` | Surface Container Lowest |
| 3.3 | 图例栏背景 == `Color(0xFFFAFAFA)` | Surface Container Lowest |
| 3.4 | 网格线颜色 == `Color(0xFFEEEEEE)` | Outline Variant |
| 3.5 | 主网格线颜色 == `Color(0xFFE0E0E0)` | Outline |
| 3.6 | 曲线1颜色 == `Color(0xFF1976D2)` | Primary |
| 3.7 | X轴标签颜色 == `Color(0xFF757575)` | On Surface Variant |
| 3.8 | Y轴标签颜色 == `Color(0xFF757575)` | On Surface Variant |

---

### TC-THEME-002: 深色主题图表颜色

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-THEME-002 |
| **测试描述** | 验证深色主题下，图表背景、网格线、曲线颜色正确 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.4, Figma §6.2, Spec §2.1.2 |

#### 前置条件

1. `ThemeData.brightness == Brightness.dark`
2. 使用标准深色 ColorScheme

#### 测试步骤

1. 使用深色主题构建页面
2. 加载单曲线数据
3. 验证各元素颜色

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | 图表画布背景 == `Color(0xFF0A0A0A)` | darkSurfaceContainerLowest |
| 3.2 | 图表工具栏背景 == `Color(0xFF1A1A1A)` | 自定义深色 |
| 3.3 | 图例栏背景 == `Color(0xFF1A1A1A)` | 自定义深色 |
| 3.4 | 网格线颜色 == `Color(0xFF1E1E1E)` | darkSurfaceContainerLow |
| 3.5 | 主网格线颜色 == `Color(0xFF2D2D2D)` | darkSurfaceContainer |
| 3.6 | 曲线1颜色 == `Color(0xFF90CAF9)` | Primary (dark) |
| 3.7 | 曲线2颜色 == `Color(0xFF80DEEA)` | Tertiary (dark) |
| 3.8 | 曲线3颜色 == `Color(0xFFEF5350)` | Error Light |
| 3.9 | 曲线4颜色 == `Color(0xFF66BB6A)` | Success Light |
| 3.10 | X轴标签颜色 == `Color(0xFF9E9E9E)` | On Surface Variant |

---

### TC-THEME-003: 主题切换后颜色同步更新

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-THEME-003 |
| **测试描述** | 验证动态切换主题时，图表颜色同步更新 |
| **优先级** | P1 |
| **关联需求** | Spec §6.1, §6.2 |

#### 前置条件

1. 使用 `AnimatedTheme` 或状态驱动主题切换
2. 已加载曲线数据

#### 测试步骤

1. 使用浅色主题构建页面并加载数据
2. 验证浅色主题颜色
3. 通过 `tester.pumpWidget()` 切换为深色主题
4. 等待动画完成（300ms）
5. 验证深色主题颜色

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 2.1 | 曲线颜色 == `Color(0xFF1976D2)` | 浅色主题 |
| 5.1 | 曲线颜色 == `Color(0xFF90CAF9)` | 深色主题 |
| 5.2 | 背景色从 `#FFFFFF` 变为 `#0A0A0A` | 背景同步切换 |
| 5.3 | 网格线颜色同步更新 | 深色网格线 |

---

## 九、控制面板交互测试

### TC-CTRL-001: 选择试验后加载设备和元数据

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-CTRL-001 |
| **测试描述** | 验证从试验下拉框选择试验后，试验元数据和设备列表正确加载 |
| **优先级** | P0 |
| **关联需求** | Figma §5.2, Spec §9.2 |

#### 前置条件

1. 模拟试验列表 API 返回 `mockExperiments`
2. 模拟设备列表 API 返回 `mockDevices`

#### 测试步骤

1. 构建页面并等待初始加载
2. 点击试验选择 Dropdown
3. 选择"温度压力联合测试"
4. 验证试验元数据显示
5. 验证设备下拉框已填充

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 4.1 | `find.text('状态')` findsOneWidget | 试验状态标签 |
| 4.2 | `find.text('Completed')` findsOneWidget | 状态值 |
| 4.3 | `find.text('开始时间')` findsOneWidget | 开始时间标签 |
| 4.4 | `find.text('采样数')` findsOneWidget | 采样数标签 |
| 5.1 | 设备 Dropdown 选项包含 "虚拟传感器A" | 设备列表已加载 |
| 5.2 | 设备 Dropdown 选项包含 "Modbus温控器" | 设备列表已加载 |

---

### TC-CTRL-002: 选择设备后加载测点列表

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-CTRL-002 |
| **测试描述** | 验证选择设备后，测点列表正确加载并显示复选框 |
| **优先级** | P0 |
| **关联需求** | Figma §3.2.2, Spec §5.2, §9.2 |

#### 前置条件

1. 已完成试验选择
2. 模拟设备测点 API 返回 `mockPoints`

#### 测试步骤

1. 选择试验后，选择设备 "虚拟传感器A"
2. 等待测点列表加载
3. 验证测点列表渲染

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | `find.text('Temperature')` findsOneWidget | 测点1名称 |
| 3.2 | `find.text('Pressure')` findsOneWidget | 测点2名称 |
| 3.3 | `find.text('Flow Rate')` findsOneWidget | 测点3名称 |
| 3.4 | `find.text('Vibration')` findsOneWidget | 测点4名称 |
| 3.5 | `find.text('Humidity')` findsOneWidget | 测点5名称 |
| 3.6 | `find.byType(Checkbox)` findsNWidgets(5) | 5个测点复选框 |
| 3.7 | `find.text('已选择 0/4')` findsOneWidget | 初始已选计数 |
| 3.8 | 每个测点项右侧显示单位 | °C, Pa, L/min 等 |

---

### TC-CTRL-003: 测点选择上限限制

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-CTRL-003 |
| **测试描述** | 验证最多只能选择4个测点，第5个测点复选框被禁用 |
| **优先级** | P0 |
| **关联需求** | Figma §3.2.2, Spec §5.2 |

#### 前置条件

1. 测点列表已加载（5个测点）
2. 当前未选择任何测点

#### 测试步骤

1. 依次选择 Temperature、Pressure、Flow Rate、Vibration（4个）
2. 验证已选计数更新
3. 尝试选择 Humidity（第5个）
4. 验证第5个复选框状态
5. 验证 Snackbar 提示

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 2.1 | `find.text('已选择 1/4')` findsOneWidget | 选择1个后计数 |
| 2.2 | `find.text('已选择 4/4')` findsOneWidget | 选择4个后计数 |
| 4.1 | 第5个 Checkbox `enabled` == false | 复选框禁用 |
| 4.2 | 第5个测点项透明度 == 0.38 | 视觉禁用态 |
| 5.1 | `find.text('最多选择4个测点')` findsOneWidget | Snackbar 提示 |

---

### TC-CTRL-004: 测点选择后显示曲线颜色指示块

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-CTRL-004 |
| **测试描述** | 验证选择测点后，列表项右侧显示对应曲线颜色块 |
| **优先级** | P1 |
| **关联需求** | Figma §3.2.2, Spec §2.2, §5.2 |

#### 前置条件

1. 测点列表已加载
2. 使用浅色主题

#### 测试步骤

1. 选择 Temperature（第1个）
2. 验证颜色块显示
3. 选择 Pressure（第2个）
4. 验证颜色块显示
5. 选择 Flow Rate（第3个）
6. 选择 Vibration（第4个）
7. 验证4个测点颜色块颜色

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 2.1 | Temperature 项右侧显示颜色块 | Container 存在 |
| 2.2 | 颜色块颜色 == `Color(0xFF1976D2)` | 曲线1颜色 |
| 4.1 | Pressure 项右侧显示颜色块 | 曲线2颜色 |
| 4.2 | 颜色块颜色 == `Color(0xFF00838F)` | 曲线2颜色 |
| 7.1 | 4个已选测点均显示颜色块 | 数量验证 |
| 7.2 | 颜色顺序符合规范 | Primary → Tertiary → Error → Success |

---

### TC-CTRL-005: 选择测点后触发数据加载

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-CTRL-005 |
| **测试描述** | 验证选择试验、设备、测点后，点击"加载数据"按钮正确调用 API |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.2, Figma §5.2 |

#### 前置条件

1. 已选择试验 `exp-001`
2. 已选择设备 `dev-001`
3. 已选择测点 `pt-001`
4. 配置 API 模拟返回 `mockSingleCurveData`

#### 测试步骤

1. 构建页面并完成上述选择
2. 点击"加载数据"按钮
3. 验证 API 调用参数
4. 等待响应完成
5. 验证图表渲染

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | `verify(() => service.queryData(captureAny())).called(1)` | API 被调用1次 |
| 3.2 | 请求参数 `experimentId` == `'exp-001'` | 试验ID正确 |
| 3.3 | 请求参数 `deviceId` == `'dev-001'` | 设备ID正确 |
| 3.4 | 请求参数 `pointIds` == `['pt-001']` | 测点ID正确 |
| 3.5 | 请求参数 `downsample` == 1000 | 默认降采样值 |
| 5.1 | `find.byType(LineChart)` findsOneWidget | 图表已渲染 |

#### 请求参数验证

```dart
final captured = verify(() => mockService.queryData(captureAny())).captured;
final request = captured.first as DataQueryRequest;
expect(request.experimentId, equals('exp-001'));
expect(request.deviceId, equals('dev-001'));
expect(request.pointIds, equals(['pt-001']));
expect(request.downsample, equals(1000));
```

---

### TC-CTRL-006: 视图复位按钮功能

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-CTRL-006 |
| **测试描述** | 验证点击"重置视图"按钮后，图表恢复到初始视图范围 |
| **优先级** | P1 |
| **关联需求** | R2-ANALYSIS-001 §2.1.3, Figma §5.2 |

#### 前置条件

1. 图表已加载数据
2. 用户已通过缩放/平移改变了视图范围（模拟状态变更）

#### 测试步骤

1. 构建页面并加载数据
2. 记录初始 X 轴范围（`minX`, `maxX`）
3. 模拟缩放操作（修改 Provider 状态）
4. 验证视图范围已改变
5. 点击"重置视图"按钮
6. 验证视图范围恢复初始值

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 4.1 | 当前 X 轴范围 != 初始范围 | 缩放已生效 |
| 6.1 | 当前 X 轴范围 == 初始范围 | 复位成功 |
| 6.2 | 图表重绘动画执行 | `animationDuration` > 0 |

---

## 十、错误状态测试

### TC-ERROR-001: API 失败时显示错误状态

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-ERROR-001 |
| **测试描述** | 验证数据加载 API 失败时，图表区域显示错误信息和重试按钮 |
| **优先级** | P0 |
| **关联需求** | R2-ANALYSIS-001 §2.1.3, Figma §4.3, Spec §8.1 |

#### 前置条件

1. 已选择试验、设备、测点
2. 配置 API 返回错误：`setupErrorResponse(service, message: '无法读取试验数据文件')`

#### 测试步骤

1. 构建页面并完成选择
2. 点击"加载数据"
3. 等待错误响应
4. 验证错误状态 UI
5. 点击"重试"按钮
6. 验证重新发起 API 请求

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 4.1 | `find.byType(ChartErrorState)` findsOneWidget | 错误状态组件 |
| 4.2 | `find.byIcon(Icons.error_outline)` findsOneWidget | 错误图标 |
| 4.3 | `find.text('数据加载失败')` findsOneWidget | 错误标题 |
| 4.4 | `find.text('无法读取试验数据文件，请检查文件是否存在或稍后重试')` findsOneWidget | 错误描述 |
| 4.5 | `find.text('重试')` findsOneWidget | 重试按钮 |
| 4.6 | `find.text('查看详情')` findsOneWidget | 查看详情按钮 |
| 6.1 | `verify(() => service.queryData(any())).called(2)` | 总共调用2次 |

---

### TC-ERROR-002: 网络超时错误处理

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-ERROR-002 |
| **测试描述** | 验证网络超时后显示特定错误提示和继续加载选项 |
| **优先级** | P1 |
| **关联需求** | Spec §10.3 |

#### 前置条件

1. 配置 API 抛出超时异常

#### 测试步骤

1. 构建页面并触发加载
2. 模拟超时错误
3. 验证错误提示内容

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | `find.text('请求超时')` findsOneWidget 或包含 "超时" | 超时提示 |
| 3.2 | `find.text('继续加载')` findsOneWidget | 继续加载按钮（降级策略） |

---

### TC-ERROR-003: 错误状态不影响控制面板操作

| 属性 | 内容 |
|------|------|
| **测试ID** | TC-ERROR-003 |
| **测试描述** | 验证图表区域显示错误状态时，控制面板仍可正常交互 |
| **优先级** | P1 |
| **关联需求** | Spec §8.1 |

#### 前置条件

1. 图表处于错误状态
2. 控制面板已选择试验和设备

#### 测试步骤

1. 构建页面并触发错误状态
2. 在控制面板中切换试验选择
3. 验证控制面板响应正常

#### 预期结果

| 步骤 | 断言 | 说明 |
|------|------|------|
| 3.1 | 试验 Dropdown 可正常展开 | 控制面板未冻结 |
| 3.2 | 可选择其他试验 | 交互正常 |
| 3.3 | 错误状态仍显示在图表区 | 错误状态未被意外清除 |

---

## 十一、fl_chart Widget 测试特殊注意事项

### 11.1 fl_chart 组件测试限制

`fl_chart` 的 `LineChart` 在 Widget 测试中有以下特殊行为，需要特别注意：

| 限制项 | 说明 | 应对策略 |
|--------|------|----------|
| **CustomPainter 渲染** | `LineChart` 内部使用 `CustomPaint`，Widget 测试中无法直接获取绘制的路径和线条 | 通过 `LineChartData` 属性验证配置，而非渲染结果 |
| **手势识别** | 缩放/平移/悬停依赖 `GestureDetector` 和 `MouseRegion`，在 headless 测试中行为不完整 | 通过 Provider 状态变更模拟交互结果，跳过实际手势 |
| **动画** | 曲线绘制动画使用 `ImplicitlyAnimatedWidget`，测试时需控制 `animationDuration` | 设置 `animationDuration: Duration.zero` 加速测试 |
| **Tooltip 定位** | Tooltip 使用 `Overlay` 或 `Stack` 定位，测试中获取位置较困难 | 验证 Tooltip 组件是否存在及其内容 |

### 11.2 fl_chart 测试辅助方法

```dart
/// 从 LineChart 中提取 LineChartData
LineChartData? extractLineChartData(WidgetTester tester) {
  final lineChart = tester.widget<LineChart>(find.byType(LineChart));
  return lineChart.data;
}

/// 验证曲线配置
void expectCurveConfig({
  required LineChartData data,
  required int index,
  required Color color,
  required double lineWidth,
  required int spotCount,
  required bool isVisible,
}) {
  final barData = data.lineBarsData[index];
  expect(barData.colors.single, equals(color));
  expect(barData.barWidth, equals(lineWidth));
  expect(barData.spots.length, equals(spotCount));
  expect(barData.show, equals(isVisible));
}

/// 验证网格线配置
void expectGridConfig({
  required LineChartData data,
  required bool showHorizontal,
  required bool showVertical,
  required Color color,
}) {
  expect(data.gridData.show, isTrue);
  expect(data.gridData.drawHorizontalLine, equals(showHorizontal));
  expect(data.gridData.drawVerticalLine, equals(showVertical));
  expect(data.gridData.getDrawingHorizontalLine(any).color, equals(color));
}

/// 验证坐标轴标签
void expectAxisTitles({
  required LineChartData data,
  required bool showBottom,
  required bool showLeft,
}) {
  expect(data.titlesData.show, isTrue);
  if (showBottom) {
    expect(data.titlesData.bottomTitles.showTitles, isTrue);
  }
  if (showLeft) {
    expect(data.titlesData.leftTitles.showTitles, isTrue);
  }
}
```

### 11.3 性能相关测试配置

```dart
/// 测试时禁用动画以提高速度
LineChartData createTestChartData(List<ChartPointSeries> series) {
  return LineChartData(
    gridData: FlGridData(show: true),
    titlesData: FlTitlesData(show: true),
    lineBarsData: series.map((s) => LineChartBarData(
      spots: s.toSpots(),
      colors: [s.color],
      barWidth: 2,
      dotData: FlDotData(show: false),
      // 测试中禁用动画
    )).toList(),
    // 禁用内置动画
    lineTouchData: LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.grey,
      ),
    ),
  );
}
```

### 11.4 光标与 Tooltip 测试策略

由于 fl_chart 的 `LineTouchData` 在 Widget 测试中难以通过真实鼠标事件触发，建议：

1. **直接调用回调**: 通过 `LineTouchResponse` 直接调用 `lineTouchData.touchCallback`
2. **Provider 状态验证**: 验证 hover 状态 Provider 是否正确更新
3. **Golden Test**: 对光标和 Tooltip 使用 golden file 测试（`flutter test --update-goldens`）

```dart
/// 模拟光标悬停（直接调用回调）
void simulateCursorHover(WidgetTester tester, Offset position) {
  final lineChart = tester.widget<LineChart>(find.byType(LineChart));
  final touchData = lineChart.data.lineTouchData;
  
  // 构造模拟触摸响应
  final response = LineTouchResponse(
    lineBarSpots: [
      LineBarSpot(
        lineChart.data.lineBarsData[0],
        0,
        lineChart.data.lineBarsData[0].spots[50],
      ),
    ],
    touchInput: MouseCursorTouchInput(),
  );
  
  touchData.touchCallback?.call(response);
  tester.pump();
}
```

### 11.5 推荐的测试文件结构

```
test/features/analysis/
├── analysis_page_test.dart           # 页面结构 + 状态测试
├── time_series_chart_test.dart       # 图表渲染 + 主题测试
├── chart_legend_test.dart            # 图例交互测试
├── control_panel_test.dart           # 控制面板交互测试
├── chart_empty_state_test.dart       # 空状态组件测试
├── chart_loading_state_test.dart     # 加载状态组件测试
├── chart_error_state_test.dart       # 错误状态组件测试
├── mocks/
│   ├── analysis_service_mock.dart    # AnalysisService Mock
│   ├── chart_data_mock.dart          # 图表测试数据
│   └── chart_test_helpers.dart       # 测试辅助函数
└── goldens/
    ├── analysis_page_light.png
    ├── analysis_page_dark.png
    ├── chart_single_curve.png
    └── chart_multi_curve.png
```

---

## 十二、用例汇总表

| 测试ID | 测试描述 | 优先级 | 类型 | 关联需求 |
|--------|----------|--------|------|----------|
| TC-STRUCT-001 | 页面基础结构渲染 | P0 | Widget | R2-ANALYSIS-001 §2.1.5 |
| TC-STRUCT-002 | 控制面板内部卡片结构 | P0 | Widget | Figma §3.2 |
| TC-STRUCT-003 | 面包屑导航与侧边栏集成 | P1 | Widget | Figma §2.2 |
| TC-STRUCT-004 | 数据预览区展开与收起 | P1 | Widget | Figma §3.4 |
| TC-STATE-001 | 空状态渲染（未选择试验） | P0 | Widget | R2-ANALYSIS-001 §2.1.3 |
| TC-STATE-002 | 加载状态渲染 | P0 | Widget | R2-ANALYSIS-001 §2.1.3 |
| TC-STATE-003 | 时间范围内无数据状态 | P1 | Widget | Figma §4.4 |
| TC-RENDER-001 | 单曲线正确渲染 | P0 | Widget | R2-ANALYSIS-001 §2.1.3 |
| TC-RENDER-002 | 多曲线渲染与颜色分配 | P0 | Widget | R2-ANALYSIS-001 §2.1.3 |
| TC-RENDER-003 | 多曲线图例当前值显示 | P1 | Widget | Figma §3.3.3 |
| TC-LEGEND-001 | 点击图例隐藏曲线 | P0 | Widget | R2-ANALYSIS-001 §2.1.3 |
| TC-LEGEND-002 | 隐藏多条曲线后图表自适应 | P1 | Widget | R2-ANALYSIS-001 §2.1.3 |
| TC-LEGEND-003 | 图例悬停高亮效果 | P1 | Widget | Figma §5.1 |
| TC-THEME-001 | 浅色主题图表颜色 | P0 | Widget | R2-ANALYSIS-001 §2.1.4 |
| TC-THEME-002 | 深色主题图表颜色 | P0 | Widget | R2-ANALYSIS-001 §2.1.4 |
| TC-THEME-003 | 主题切换后颜色同步更新 | P1 | Widget | Spec §6.1 |
| TC-CTRL-001 | 选择试验后加载设备和元数据 | P0 | Widget | Figma §5.2 |
| TC-CTRL-002 | 选择设备后加载测点列表 | P0 | Widget | Figma §3.2.2 |
| TC-CTRL-003 | 测点选择上限限制 | P0 | Widget | Figma §3.2.2 |
| TC-CTRL-004 | 测点选择后显示曲线颜色指示块 | P1 | Widget | Figma §3.2.2 |
| TC-CTRL-005 | 选择测点后触发数据加载 | P0 | Widget | R2-ANALYSIS-001 §2.1.2 |
| TC-CTRL-006 | 视图复位按钮功能 | P1 | Widget | R2-ANALYSIS-001 §2.1.3 |
| TC-ERROR-001 | API 失败时显示错误状态 | P0 | Widget | R2-ANALYSIS-001 §2.1.3 |
| TC-ERROR-002 | 网络超时错误处理 | P1 | Widget | Spec §10.3 |
| TC-ERROR-003 | 错误状态不影响控制面板操作 | P1 | Widget | Spec §8.1 |

### 测试统计

| 类别 | 数量 |
|------|------|
| 页面结构测试 | 4 |
| 图表状态测试 | 3 |
| 图表渲染测试 | 3 |
| 图例交互测试 | 3 |
| 主题适配测试 | 3 |
| 控制面板交互测试 | 6 |
| 错误状态测试 | 3 |
| **总计** | **25** |

### 优先级分布

| 优先级 | 数量 |
|--------|------|
| P0 | 15 |
| P1 | 10 |
| **总计** | **25** |

---

## 附录 A：测试数据快速参考

### API 响应数据模板

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "experiment_id": "exp-001",
    "device_id": "dev-001",
    "points": [
      {
        "point_id": "pt-001",
        "point_name": "Temperature",
        "unit": "°C",
        "data_type": "float32",
        "timestamps": [1714521600000, 1714521660000, ...],
        "values": [25.0, 25.31, ...]
      }
    ],
    "total_samples": 86400,
    "returned_samples": 1000
  },
  "timestamp": "2026-05-10T12:00:00Z"
}
```

### 颜色值速查表

| 元素 | Light | Dark |
|------|-------|------|
| 图表画布背景 | `#FFFFFF` | `#0A0A0A` |
| 图表工具栏背景 | `#FAFAFA` | `#1A1A1A` |
| 图例栏背景 | `#FAFAFA` | `#1A1A1A` |
| 网格线 | `#EEEEEE` | `#1E1E1E` |
| 主网格线 | `#E0E0E0` | `#2D2D2D` |
| 曲线1 | `#1976D2` | `#90CAF9` |
| 曲线2 | `#00838F` | `#80DEEA` |
| 曲线3 | `#C62828` | `#EF5350` |
| 曲线4 | `#2E7D32` | `#66BB6A` |
| X/Y轴标签 | `#757575` | `#9E9E9E` |
| 提示框背景 | `#E0E0E0` | `#3D3D3D` |

---

**文档结束**

*本文档基于 `log/release_2/prd.md` §2.1、`log/release_2/ui/figma/analysis_page.md` 和 `log/release_2/ui/specifications/analysis_page_spec.md` 编制。测试用例需随实现细节调整同步更新。*
