# 分析页面设计规范文档 (Analysis Page Design Specification)

**任务ID**: R2-S1-002-A  
**版本**: 1.0  
**日期**: 2026-05-10  
**设计师**: sw-anna  
**项目**: Kayak 科学研究支持平台 - Release 2 Sprint 1  
**适用范围**: 分析页面 (`/analysis`) 时序数据可视化 UI  
**依赖规范**: `log/release_1/ui/design_spec_v2.md` (Release 1 全局设计规范 v2)

---

## 1. 文档说明

本文档定义分析页面的专用设计规范，包括图表组件的特殊色彩、字体、间距和交互规则。所有未在本文档中特别说明的属性，均遵循 Release 1 全局设计规范 `design_spec_v2.md`。

### 1.1 设计原则

1. **数据优先**: 图表区域占据最大视觉权重，控制面板服务于数据展示
2. **主题沉浸**: 深色主题下图表采用更深背景，营造专注分析氛围
3. **认知友好**: 同时显示的曲线不超过4条，减少视觉干扰
4. **即时反馈**: 所有交互操作在 100ms 内提供视觉反馈

---

## 2. 色彩系统

### 2.1 图表专用色彩 (Chart-Specific Colors)

以下颜色为图表组件专用，不在标准 `ColorScheme` 中，需在 Flutter 中单独定义。

#### 2.1.1 曲线颜色 (Curve Colors)

| 曲线 | 浅色主题 (Light) | 深色主题 (Dark) | 用途 |
|------|-----------------|----------------|------|
| Curve 1 | `#1976D2` | `#90CAF9` | 主要数据曲线 |
| Curve 2 | `#00838F` | `#80DEEA` | 次要数据曲线 |
| Curve 3 | `#C62828` | `#EF5350` | 第三数据曲线 |
| Curve 4 | `#2E7D32` | `#66BB6A` | 第四数据曲线 |

**命名规范 (Dart)**:
```dart
// lib/features/analysis/theme/chart_colors.dart
class ChartColors {
  static const List<Color> lightCurves = [
    Color(0xFF1976D2),  // Primary
    Color(0xFF00838F),  // Tertiary
    Color(0xFFC62828),  // Error
    Color(0xFF2E7D32),  // Success
  ];

  static const List<Color> darkCurves = [
    Color(0xFF90CAF9),  // Primary (dark)
    Color(0xFF80DEEA),  // Tertiary (dark)
    Color(0xFFEF5350),  // Error Light
    Color(0xFF66BB6A),  // Success Light
  ];

  static List<Color> getCurves(Brightness brightness) =>
      brightness == Brightness.light ? lightCurves : darkCurves;
}
```

#### 2.1.2 图表背景色 (Chart Background)

| 元素 | 浅色主题 | 深色主题 | 说明 |
|------|---------|---------|------|
| 图表画布背景 | `#FFFFFF` | `#0A0A0A` | 深色主题下比页面背景 `#121212` 更深 |
| 图表工具栏背景 | `#FAFAFA` | `#1A1A1A` | 与画布微区分 |
| 图例栏背景 | `#FAFAFA` | `#1A1A1A` | 与工具栏一致 |
| 网格线（普通） | `#EEEEEE` | `#1E1E1E` | 浅色用 Outline Variant，深色用 darkSurfaceContainerLow |
| 网格线（主刻度） | `#E0E0E0` | `#2D2D2D` | 每5条线加粗 |

**命名规范 (Dart)**:
```dart
// 图表背景色扩展
extension ChartBackgroundColors on ColorScheme {
  Color get chartCanvasBackground => brightness == Brightness.light
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF0A0A0A);

  Color get chartToolbarBackground => brightness == Brightness.light
      ? const Color(0xFFFAFAFA)
      : const Color(0xFF1A1A1A);

  Color get chartGridLine => brightness == Brightness.light
      ? const Color(0xFFEEEEEE)
      : const Color(0xFF1E1E1E);

  Color get chartGridLineMajor => brightness == Brightness.light
      ? const Color(0xFFE0E0E0)
      : const Color(0xFF2D2D2D);
}
```

#### 2.1.3 光标与提示框颜色 (Cursor & Tooltip)

| 元素 | 浅色主题 | 深色主题 | 说明 |
|------|---------|---------|------|
| 垂直光标线 | `#757575` @ 50% | `#9E9E9E` @ 50% | On Surface Variant 半透明 |
| 水平光标线 | 各曲线颜色 @ 50% | 各曲线颜色 @ 50% | 与对应曲线同色 |
| 光标交点圆点 | 曲线颜色 + 2px 白边 | 曲线颜色 + 2px 黑边 | 确保在任何背景可见 |
| 提示框背景 | `#E0E0E0` | `#3D3D3D` | Surface Container High |
| 提示框边框 | `#E0E0E0` | `#424242` | Outline |
| 提示框文字 | `#212121` | `#F5F5F5` | On Surface |

### 2.2 控制面板色彩 (Control Panel Colors)

| 元素 | 浅色主题 | 深色主题 | 说明 |
|------|---------|---------|------|
| 控制面板容器 | `#FFFFFF` | `#1E1E1E` | Surface / Surface Container Low |
| 控制卡片背景 | `#FAFAFA` | `#0A0A0A` | Surface Container Lowest / darkSurfaceContainerLowest |
| 卡片标题图标 | `#1976D2` | `#90CAF9` | Primary |
| 卡片标题文字 | `#212121` | `#F5F5F5` | On Surface |
| 已选测点指示条 | `#1976D2` | `#90CAF9` | Primary, 3px 宽 |
| 曲线色块（测点列表） | 对应曲线颜色 | 对应曲线颜色 | 8px × 8px 圆角方块 |
| 预设按钮激活态 | `#BBDEFB` | `#1565C0` | Primary Container |

### 2.3 数据表格色彩 (Data Table Colors)

| 元素 | 浅色主题 | 深色主题 | 说明 |
|------|---------|---------|------|
| 表格背景 | `#FFFFFF` | `#1E1E1E` | Surface / Surface Container Low |
| 表头背景 | `#F5F5F5` | `#1E1E1E` | Surface Container Low |
| 奇数行背景 | `#FFFFFF` | `#1E1E1E` | Surface |
| 偶数行背景 | `#FAFAFA` | `#1A1A1A` | 自定义深色行 |
| 悬停行背景 | `#EEEEEE` | `#2D2D2D` | Surface Container / darkSurfaceContainer |
| 表头文字 | `#212121` | `#F5F5F5` | On Surface |
| 单元格文字 | `#212121` | `#F5F5F5` | On Surface |
| 时间戳文字 | `#757575` | `#9E9E9E` | On Surface Variant, monospace |
| 数值文字 | `#212121` | `#F5F5F5` | On Surface, monospace, right-aligned |

---

## 3. 字体系统

### 3.1 图表专用字体规范

| 元素 | 字体层级 | 字号 | 字重 | 行高 | 字间距 | 颜色 | 字体家族 |
|------|---------|------|------|------|--------|------|---------|
| 图表标题 | Title Small | 14pt | 500 | 20pt | 0.1px | On Surface | 系统默认 |
| X轴标签 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface Variant | 系统默认 |
| Y轴标签 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface Variant | 系统默认 |
| 轴标题 | Label Medium | 12pt | 500 | 16pt | 0.5px | On Surface Variant | 系统默认 |
| 提示框标题 | Label Medium | 12pt | 500 | 16pt | 0.5px | On Surface | 系统默认 |
| 提示框数据名 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface | 系统默认 |
| 提示框数值 | Body Medium | 14pt | 400 | 20pt | 0.25px | On Surface | monospace |
| 图例名称 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface | 系统默认 |
| 图例数值 | Label Medium | 12pt | 500 | 16pt | 0.5px | 曲线颜色 | monospace |
| 工具栏范围文字 | Body Small | 12pt | 400 | 16pt | 0.4px | On Surface Variant | 系统默认 |

### 3.2 等宽字体数值显示

所有数值（测点值、坐标轴刻度、图例当前值）使用等宽字体对齐：

```dart
// Flutter 等宽字体配置
const TextStyle chartMonospaceStyle = TextStyle(
  fontFamily: 'monospace', // Flutter Web 自动映射到系统等宽字体
  fontFeatures: [FontFeature.tabularFigures()], // 等宽数字
);
```

**等宽字体使用场景**:
- Y轴刻度标签
- 提示框中的数值
- 图例中的当前值
- 数据表格中的数值列
- 时间戳（ISO 8601 格式）

---

## 4. 间距系统

### 4.1 页面级间距

| Token | 值 | 用途 |
|-------|-----|------|
| page-padding | 24px | 内容区整体内边距 |
| panel-gap | 16px | 控制面板与图表区之间间距 |
| section-gap | 16px | 页面内各区块之间间距 |
| header-bottom-margin | 8px | 页面标题下方间距 |

### 4.2 控制面板间距

| Token | 值 | 用途 |
|-------|-----|------|
| panel-width | 320px | 控制面板固定宽度 |
| panel-padding | 16px | 控制面板内边距 |
| card-gap | 16px | 控制卡片之间间距 |
| card-padding | 16px | 控制卡片内边距 |
| card-header-bottom | 12px | 卡片标题与内容间距 |
| input-gap | 12px | 输入框之间间距 |
| setting-row-height | 48px | 设置项行高 |
| button-gap | 12px | 按钮之间间距 |
| preset-button-gap | 8px | 预设按钮之间间距 |

### 4.3 图表区域间距

| Token | 值 | 用途 |
|-------|-----|------|
| toolbar-height | 48px | 图表工具栏高度 |
| toolbar-padding | 0 16px | 工具栏水平内边距 |
| legend-height | 40px | 图例栏高度 |
| legend-padding | 0 16px | 图例栏水平内边距 |
| y-axis-width | 56px | Y轴区域宽度 |
| plot-padding | 8px | 图表绘制区内边距 |
| tooltip-padding | 12px 16px | 提示框内边距 |
| tooltip-arrow-size | 8px | 提示框箭头尺寸 |
| tooltip-offset | 16px | 提示框距光标偏移 |

### 4.4 数据表格间距

| Token | 值 | 用途 |
|-------|-----|------|
| table-header-height | 40px | 表头行高 |
| table-row-height | 36px | 数据行高 |
| table-cell-padding | 8px 12px | 单元格内边距 |
| table-max-height | 240px | 表格最大高度 |
| preview-section-max-height | 280px | 数据预览区最大高度 |

---

## 5. 组件规范

### 5.1 控制面板卡片 (Control Card)

继承标准 `Standard Card` 规范，有以下调整：

```dart
// 控制卡片主题
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: colorScheme.surfaceContainerLowest, // Light: #FAFAFA, Dark: #0A0A0A
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colorScheme.outlineVariant),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: textTheme.titleSmall),
        ],
      ),
      const Divider(height: 24), // 12px top + 12px bottom margin
      // Content
      ...
    ],
  ),
)
```

**特殊状态**:
- **禁用态**: 整个卡片透明度 38%，内部控件不可交互
- **加载态**: 卡片内容被骨架屏替代，保留标题

### 5.2 测点选择列表项 (Point List Item)

```dart
// 测点列表项规范
Container(
  height: 40,
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    // 选中态: 左侧 3px Primary 指示条
  ),
  child: Row(
    children: [
      Checkbox(value: isSelected, onChanged: ...), // 18px
      const SizedBox(width: 12),
      Expanded(
        child: Text(pointName, style: textTheme.bodyMedium),
      ),
      // 曲线颜色指示块 (选中时显示)
      if (isSelected)
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: curveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      const SizedBox(width: 8),
      Text(unit, style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      )),
    ],
  ),
)
```

**状态**:
- **未选中**: 标准样式
- **选中**: 左侧 3px Primary 色指示条，右侧显示曲线颜色块
- **禁用**（已达4个上限）: Checkbox `enabled: false`，整行 38% 透明度
- **悬停**: `Surface Container` 背景色

### 5.3 图表工具栏按钮 (Chart Toolbar Button)

继承标准 `Icon Button` 规范，有以下调整：

```dart
// 工具栏图标按钮
IconButton(
  icon: Icon(icon, size: 20),
  onPressed: ...,
  style: IconButton.styleFrom(
    minimumSize: const Size(40, 40),
    backgroundColor: isActive
        ? colorScheme.primaryContainer
        : Colors.transparent,
    foregroundColor: isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant,
  ),
)
```

**模式切换规则**:
- **缩放模式** (zoom): 默认激活，滚轮缩放
- **平移模式** (pan): 点击切换，左键拖拽平移
- **光标模式** (cursor): 点击切换，显示十字光标

**注意**: 平移模式和光标模式互斥，缩放模式始终可用。

### 5.4 图例项 (Legend Item)

```dart
// 图例项规范
InkWell(
  onTap: onToggleVisibility,
  onDoubleTap: onSolo,
  child: Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: isHovered ? colorScheme.surfaceContainer : Colors.transparent,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 颜色线
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isVisible ? curveColor : curveColor.withOpacity(0.38),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        // 测点名称
        Text(
          pointName,
          style: textTheme.bodySmall?.copyWith(
            color: isVisible
                ? colorScheme.onSurface
                : colorScheme.onSurface.withOpacity(0.38),
            decoration: isVisible ? null : TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 4),
        // 单位
        Text(
          unit,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(
              isVisible ? 1.0 : 0.38,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 当前值 (monospace)
        Text(
          currentValue,
          style: textTheme.labelMedium?.copyWith(
            color: isVisible ? curveColor : curveColor.withOpacity(0.38),
            fontFamily: 'monospace',
          ),
        ),
      ],
    ),
  ),
)
```

**交互状态**:
- **默认**: 标准样式
- **悬停**: `Surface Container` 背景，对应曲线线宽 2px → 3px
- **隐藏态**: 全部元素 38% 透明度，名称带删除线
- **当前值更新**: 数值变化时 300ms 颜色脉冲动画（曲线颜色 → 高亮 → 曲线颜色）

### 5.5 数据提示框 (Chart Tooltip)

```dart
// 提示框规范
Container(
  constraints: const BoxConstraints(
    minWidth: 180,
    maxWidth: 280,
  ),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: colorScheme.surfaceContainerHigh, // Light: #E0E0E0, Dark: #3D3D3D
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: colorScheme.outline),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.12),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 时间戳
      Text(
        formattedTimestamp,
        style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
      ),
      const Divider(height: 16),
      // 数据行
      ...dataRows.map((row) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: row.curveColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.pointName,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${row.value} ${row.unit}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ],
      )),
    ],
  ),
)
```

**定位规则**:
- 默认显示在光标右下方 (offset: 16px, 16px)
- 若右侧空间不足，自动翻转至左下方
- 若下方空间不足，自动翻转至上方
- 始终保持在图表画布边界内

### 5.6 预设时间按钮 (Preset Time Button)

```dart
// 预设时间按钮规范
textButtonStyle: TextButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  minimumSize: const Size(0, 32),
  backgroundColor: isActive
      ? colorScheme.primaryContainer
      : Colors.transparent,
  foregroundColor: isActive
      ? colorScheme.onPrimaryContainer
      : colorScheme.primary,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: isActive
        ? BorderSide.none
        : BorderSide(color: colorScheme.outline),
  ),
)
```

**预设选项**:
- "最近1小时"
- "最近24小时"
- "全部"

**行为**: 点击预设按钮时，自动计算对应时间范围并填充自定义输入框，同时该按钮进入 Active 状态。手动修改时间输入框时，所有预设按钮取消 Active。

### 5.7 降采样滑块 (Downsample Slider)

```dart
// 滑块主题覆盖
SliderTheme(
  data: SliderTheme.of(context).copyWith(
    activeTrackColor: colorScheme.primary,
    inactiveTrackColor: colorScheme.surfaceContainerHighest,
    thumbColor: colorScheme.primary,
    overlayColor: colorScheme.primary.withOpacity(0.12),
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 10,
    ),
    overlayShape: const RoundSliderOverlayShape(
      overlayRadius: 20,
    ),
  ),
  child: Slider(
    value: downsampleValue,
    min: 100,
    max: 10000,
    divisions: 99, // 每 100 一步
    label: downsampleValue.toStringAsFixed(0),
    onChanged: ...,
  ),
)
```

**数值显示**: 滑块右侧显示当前值（Label Medium, Primary color），格式为整数。

---

## 6. 主题适配规则

### 6.1 自动主题切换

图表组件必须响应 `Theme.of(context)` 的变化，当全局主题切换时：

1. **背景色**: 图表画布、工具栏、图例栏背景同步切换
2. **曲线颜色**: 从 `ChartColors.lightCurves` 切换至 `ChartColors.darkCurves`
3. **网格线**: 颜色同步切换
4. **文字颜色**: 坐标轴标签、提示框文字同步切换
5. **过渡动画**: 颜色变化使用 300ms `ease-in-out` 过渡

### 6.2 主题切换动画实现

```dart
// Flutter 主题切换动画
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  color: colorScheme.chartCanvasBackground,
  child: CustomPaint(
    painter: TimeSeriesChartPainter(
      theme: Theme.of(context),
      // 其他参数...
    ),
  ),
)
```

### 6.3 系统主题跟随

- 应用设置"跟随系统"时，图表自动适配系统深色/浅色模式
- 应用设置"手动切换"时，图表跟随应用全局主题设置
- 无需单独的图表主题设置

---

## 7. 响应式规则

### 7.1 断点定义

| 断点 | 宽度 | 布局名称 |
|------|------|---------|
| Desktop | >= 1280px | 完整布局 |
| Tablet | >= 768px and < 1280px | 紧凑布局 |
| Small | < 768px | 最小布局（本页面不支持） |

### 7.2 Desktop (>= 1280px) 布局

```
┌──────────────────────────────────────────────────────────────┐
│ Sidebar (240px) │ Breadcrumb (48px)                          │
│                 ├────────────────────────────────────────────┤
│                 │ Page Header (56px)                         │
│                 ├────────────────────────────────────────────┤
│                 │ Control Panel (320px) │ Chart Area (flex)  │
│                 │                       │ ┌──────────────┐   │
│                 │ ┌─────────────────┐   │ │ Toolbar    │   │
│                 │ │ Experiment Card │   │ ├──────────────┤   │
│                 │ ├─────────────────┤   │ │              │   │
│                 │ │ Device Card     │   │ │   Canvas   │   │
│                 │ ├─────────────────┤   │ │              │   │
│                 │ │ Time Range Card │   │ ├──────────────┤   │
│                 │ ├─────────────────┤   │ │ Legend     │   │
│                 │ │ Settings Card   │   │ └──────────────┘   │
│                 │ ├─────────────────┤   │                    │
│                 │ │ Action Buttons  │   │                    │
│                 │ └─────────────────┘   │                    │
│                 │                       │                    │
│                 ├───────────────────────┴────────────────────┤
│                 │ Data Preview (collapsible, max 280px)      │
│                 └────────────────────────────────────────────┘
```

### 7.3 Tablet (>= 768px and < 1280px) 布局

- 侧边栏折叠为 72px（图标-only）
- 控制面板宽度保持 320px，内部 padding 从 16px 减至 12px
- 图例栏：当图例项超过 3 个时，显示"更多"按钮，点击展开下拉面板
- 数据预览区默认收起
- 工具栏按钮移除文字标签（如有），仅保留图标

### 7.4 响应式实现代码参考

```dart
// 响应式布局
LayoutBuilder(
  builder: (context, constraints) {
    final isDesktop = constraints.maxWidth >= 1280;
    final isTablet = constraints.maxWidth >= 768;

    return Row(
      children: [
        // Control Panel
        SizedBox(
          width: isDesktop ? 320 : 280,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            child: ControlPanel(...),
          ),
        ),
        // Chart Area
        Expanded(
          child: ChartArea(
            showLegendInToolbar: !isDesktop,
            ...
          ),
        ),
      ],
    );
  },
)
```

---

## 8. 状态规范

### 8.1 图表状态机

```
Chart States:
├── Empty
│   ├── Trigger: No experiment selected
│   └── Visual: Empty state illustration
├── Loading
│   ├── Trigger: "Load Data" clicked
│   ├── Visual: Centered spinner + progress text
│   └── Sub-state: Skeleton preview (optional)
├── Loaded (Success)
│   ├── Trigger: Data received from API
│   ├── Visual: Full chart with curves
│   └── Sub-states:
│       ├── Idle: No interaction
│       ├── Zooming: Mouse wheel active
│       ├── Panning: Mouse drag active
│       ├── Cursor: Mouse hover with crosshair
│       └── RangeEmpty: Zoomed/panned to area with no data
├── Error
│   ├── Trigger: API error or data parsing error
│   └── Visual: Error illustration + retry button
└── NoDataInRange
    ├── Trigger: Valid query returned empty dataset
    └── Visual: Info illustration + range adjustment hint
```

### 8.2 状态转换规则

| 从状态 | 事件 | 到状态 | 视觉过渡 |
|--------|------|--------|---------|
| Empty | 选择试验 | Empty | 控制面板更新 |
| Empty | 点击"加载数据" | Loading | 按钮 loading + 图表区 spinner |
| Loading | API 成功返回 | Loaded | spinner 淡出，曲线绘制动画 |
| Loading | API 返回空数据 | NoDataInRange | spinner 淡出，空数据提示淡入 |
| Loading | API 错误 | Error | spinner 淡出，错误提示淡入 |
| Loaded | 点击"加载数据" | Loading | 当前图表淡出，spinner 淡入 |
| Loaded | 缩放至无数据区域 | RangeEmpty | 半透明遮罩 + 提示 |
| Loaded | 双击图表 | Loaded (Reset) | 平滑动画回到初始视图 |
| Error | 点击"重试" | Loading | 错误提示淡出，spinner 淡入 |
| NoDataInRange | 调整时间范围 | Loading | 提示淡出，spinner 淡入 |

### 8.3 加载状态层级

```
Loading State Hierarchy:
├── Global Loading (entire chart area)
│   └── Used for: Initial data load, full refresh
├── Incremental Loading (bottom-right corner indicator)
│   └── Used for: Pan/zoom triggered data fetch
└── Background Loading (no visual blocker)
    └── Used for: Auto-refresh on running experiment
```

---

## 9. 交互规范

### 9.1 鼠标交互映射

| 操作 | 上下文 | 行为 |
|------|--------|------|
| 滚轮向上 | 图表画布 | X轴放大（时间范围缩小） |
| 滚轮向下 | 图表画布 | X轴缩小（时间范围扩大） |
| 左键拖拽 | 图表画布（平移模式） | 平移时间轴 |
| 左键拖拽 | 图表画布（光标模式） | 选择区域（可选高级功能） |
| 鼠标移动 | 图表画布（光标模式） | 十字光标跟随 + 提示框更新 |
| 鼠标离开 | 图表画布 | 隐藏光标和提示框 |
| 双击 | 图表画布 | 恢复初始视图 |
| Ctrl/Cmd + 滚轮 | 图表画布 | Y轴缩放（独立缩放） |
| 中键拖拽 | 图表画布 | 平移（无论当前模式） |

### 9.2 键盘交互映射

| 按键 | 行为 |
|------|------|
| `+` / `=` | X轴放大 |
| `-` / `_` | X轴缩小 |
| `0` | 恢复初始视图 |
| `Arrow Left` | 向左平移 |
| `Arrow Right` | 向右平移 |
| `Arrow Up` | Y轴向上平移（如有） |
| `Arrow Down` | Y轴向下平移（如有） |
| `Tab` | 在工具栏按钮间导航 |
| `Enter` / `Space` | 激活聚焦的按钮 |
| `Escape` | 取消当前操作（如区域选择） |

### 9.3 触摸交互映射（Flutter Web 桌面端不考虑，但预留）

| 手势 | 行为 |
|------|------|
| 双指捏合 | 缩放 |
| 单指拖拽 | 平移 |
| 单指长按 | 显示光标和提示框 |
| 双击 | 恢复初始视图 |

---

## 10. 性能规范

### 10.1 渲染性能

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 初始渲染 | < 2s | 从点击"加载数据"到曲线完全显示 |
| 缩放/平移帧率 | >= 60fps | 交互过程中保持流畅 |
| 光标跟随延迟 | < 16ms | 鼠标移动到提示框更新 |
| 数据点上限 | 10,000 | 不降采样时前端渲染上限 |
| 内存占用 | < 200MB | 含 4 条曲线 × 10,000 点数据 |

### 10.2 数据加载策略

```
Data Loading Strategy:
1. Initial Load
   └── 请求时间范围: [experiment_start, experiment_end]
   └── downsample: 1000 (默认)
   └── 前端显示: 全部数据点

2. Zoom In (time range shrinks)
   └── 当可见数据点 < 500 时
   └── 触发增量加载: 请求当前视图范围的原始数据
   └── downsample: max(visible_width_in_pixels, 500)

3. Pan (move to unloaded area)
   └── 检测当前视图与已加载数据的交集
   └── 触发增量加载: 请求未加载区域的数据
   └── 合并到现有数据集

4. Zoom Out (time range expands)
   └── 优先使用已缓存数据
   └── 仅当需要超出已缓存范围时请求新数据
```

### 10.3 降级策略

| 场景 | 降级行为 |
|------|---------|
| 数据点 > 10,000 | 强制降采样至 10,000，显示警告 Snackbar |
| 渲染卡顿 (> 33ms/帧) | 自动隐藏数据点标记，仅显示连线 |
| 严重卡顿 (> 100ms/帧) | 切换至 LTTB 预览模式，显示简化曲线 |
| API 超时 | 显示部分已加载数据 + 错误提示 + "继续加载"按钮 |

---

## 11. 与现有设计规范的兼容性

### 11.1 复用的现有规范

| 组件 | 复用规范 | 文件位置 |
|------|---------|---------|
| AppBar | design_spec_v2.md 5.1 / 8.1 | 全局组件 |
| Sidebar | design_spec_v2.md 5.6 | 全局组件 |
| Breadcrumb | design_spec_v2.md 8.1 | 全局组件 |
| Filled Button | design_spec_v2.md 5.1 | 全局组件 |
| Outlined Button | design_spec_v2.md 5.1 | 全局组件 |
| Text Button | design_spec_v2.md 5.1 | 全局组件 |
| Icon Button | design_spec_v2.md 5.1 | 全局组件 |
| Filled Text Field | design_spec_v2.md 5.2 | 全局组件 |
| Dropdown | design_spec_v2.md 5.2 | 全局组件 |
| Checkbox | Material Design 3 默认 | Flutter 内置 |
| Switch | Material Design 3 默认 | Flutter 内置 |
| Slider | Material Design 3 默认 | Flutter 内置 |
| Card | design_spec_v2.md 5.3 | 全局组件 |
| Data Table | design_spec_v2.md 5.4 | 全局组件 |
| Snackbar | design_spec_v2.md 5.9 | 全局组件 |
| CircularProgressIndicator | design_spec_v2.md 5.8 | 全局组件 |
| LinearProgressIndicator | design_spec_v2.md 5.8 | 全局组件 |

### 11.2 新增/覆写的规范

| 组件 | 变更说明 | 本文档章节 |
|------|---------|-----------|
| 图表画布背景色 | 深色主题下使用 `#0A0A0A` | 2.1.2 |
| 曲线颜色 | 新增4色专用调色板 | 2.1.1 |
| 网格线颜色 | 深色主题下特殊处理 | 2.1.2 |
| 提示框样式 | 新增专用组件规范 | 5.5 |
| 图例项样式 | 新增专用组件规范 | 5.4 |
| 预设时间按钮 | 新增专用组件规范 | 5.6 |
| 图表工具栏按钮 | 覆写 Icon Button 激活态 | 5.3 |
| 测点列表项 | 新增专用组件规范 | 5.2 |
| 控制卡片 | 覆写 Card 背景色 | 5.1 |
| 等宽字体数值 | 新增字体使用规则 | 3.2 |

---

## 12. 设计检查清单

### 12.1 开发前检查 (Design QA Before Dev)

- [ ] 所有颜色值已定义并在 `color_schemes.dart` 中有对应或已新增扩展
- [ ] 所有字体层级使用现有 `AppTypography.textTheme` 中的样式
- [ ] 所有间距符合 8pt 网格系统
- [ ] 图表区域在深色主题下背景色 (`#0A0A0A`) 已确认
- [ ] 4条曲线颜色在深色/浅色主题下均通过 WCAG 2.1 AA 对比度标准
- [ ] 响应式布局在 1280px 和 768px 断点已定义
- [ ] 所有交互状态已定义（默认、悬停、按下、禁用、加载、错误）
- [ ] 空状态、加载状态、错误状态设计已完成
- [ ] 键盘导航路径已定义
- [ ] 图标名称已确认存在于 Material Symbols 中

### 12.2 开发后检查 (Design QA After Dev)

- [ ] 图表画布背景色与规范一致
- [ ] 曲线颜色与规范一致
- [ ] 网格线颜色与规范一致
- [ ] 坐标轴文字样式与规范一致
- [ ] 提示框样式与规范一致
- [ ] 图例交互（点击隐藏/显示、双击 solo）与规范一致
- [ ] 控制面板卡片样式与规范一致
- [ ] 主题切换动画（300ms）已实现
- [ ] 响应式布局在断点处正确切换
- [ ] 加载状态动画与规范一致
- [ ] 数据表格样式与规范一致

---

**文档结束**

*本文档基于 Release 1 全局设计规范 `design_spec_v2.md` 编制。任何冲突以本文档（分析页面专用规范）为准，未覆盖部分以全局规范为准。*
