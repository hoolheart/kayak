# TASK-017: 设备配置表单 — UI 设计规范

> **路由**: 对话框（从设备树触发）  
> **依赖**: TASK-007 (可复用组件库)、TASK-016 (设备树)  
> **设计师**: sw-anna  
> **日期**: 2026-05-31

---

## 1. 页面布局

### 1.1 整体结构

```
DeviceConfigDialog (AlertDialog, 560px)
├── Header (56px)
│   ├── Title: "添加设备" / "编辑设备"
│   └── Close Button
├── Content (scrollable, padding: 16px)
│   ├── Section 1: 基础信息
│   │   ├── 设备名称 * (TextField)
│   │   └── 协议类型 * (Dropdown)
│   ├── Section 2: 协议配置 (动态切换)
│   │   ├── [Virtual / Modbus TCP / Modbus RTU]
│   └── Section 3: 高级信息 (ExpansionTile, 选填)
│       └── 制造商 / 型号 / 序列号
└── Actions
    ├── TextButton "取消"
    └── FilledButton "保存" (表单有效时启用)
```

### 1.2 布局参数

| 属性 | 值 |
|------|-----|
| Dialog Width | 560px (桌面) / 100% (移动 BottomSheet) |
| Max Height | 80vh |
| Section Gap | spaceLg (24px) |
| Field Gap | spaceMd (16px) |

---

## 2. 组件规格

### 2.1 基础信息

| 字段 | 组件 | Label | Placeholder | 验证 |
|------|------|-------|-------------|------|
| 设备名称 | TextFormField | 设备名称 * | 请输入设备名称 | 必填，1-255 字符 |
| 协议类型 | DropdownButtonFormField | 协议类型 * | 请选择协议类型 | 必填 |

**协议选项**：虚拟设备(`memory`) / Modbus TCP(`lan`) / Modbus RTU(`cable`)

### 2.2 Virtual 配置

| 字段 | 组件 | Label | Placeholder | 验证 |
|------|------|-------|-------------|------|
| 虚拟模式 | Dropdown | 虚拟模式 * | 请选择 | 必填：随机/正弦波/固定值/递增 |
| 数据类型 | Dropdown | 数据类型 * | 请选择 | 必填：int8~int64/float32/float64/bool |
| 取值范围 | Row(2×TextField) | 取值范围 | 最小值 ~ 最大值 | 数字，min < max |
| 更新间隔 | TextField + ms | 更新间隔 | 1000 | 整数 ≥ 100，默认 1000ms |

### 2.3 Modbus TCP 配置

| 字段 | 组件 | Label | Placeholder | 验证 |
|------|------|-------|-------------|------|
| 主机地址 | TextFormField | 主机地址 * | 192.168.1.100 | 必填，IPv4 格式 |
| 端口 | TextFormField | 端口 * | 502 | 必填，1-65535，默认 502 |
| 从站 ID | TextFormField | 从站 ID | 1 | 选填，1-247，默认 1 |
| 超时 | TextField + ms | 超时 | 5000 | 整数 ≥ 100，默认 5000ms |

### 2.4 Modbus RTU 配置

| 字段 | 组件 | Label | Placeholder | 验证 |
|------|------|-------|-------------|------|
| 串口 | Dropdown | 串口 * | 请选择串口 | 必填，动态获取可用列表 |
| 波特率 | Dropdown | 波特率 * | 请选择波特率 | 必填：9600/19200/38400/57600/115200，默认 9600 |
| 数据位 | Dropdown | 数据位 * | 请选择数据位 | 必填：7/8，默认 8 |
| 停止位 | Dropdown | 停止位 * | 请选择停止位 | 必填：1/2，默认 1 |
| 校验位 | Dropdown | 校验位 * | 请选择校验位 | 必填：无/奇校验/偶校验，默认 无 |
| 从站 ID | TextFormField | 从站 ID | 1 | 选填，1-247，默认 1 |
| 超时 | TextField + ms | 超时 | 5000 | 整数 ≥ 100，默认 5000ms |

### 2.5 高级信息 (ExpansionTile)

| 字段 | Label | Placeholder | 验证 |
|------|-------|-------------|------|
| 制造商 | TextFormField | 例如: Siemens | 选填，最长 255 |
| 型号 | TextFormField | 例如: S7-1200 | 选填，最长 255 |
| 序列号 | TextFormField | 例如: SN123456 | 选填，最长 255 |

---

## 3. 交互状态

### 3.1 表单验证

- **触发时机**: 失焦时验证单个字段，实时更新保存按钮状态
- **错误显示**: 红色下划线 + errorText 提示
- **保存按钮**: 全部必填项有效时启用，否则禁用

### 3.2 协议切换

| 操作 | 行为 |
|------|------|
| 切换协议 | 动态替换下方配置区域，保留通用字段 |
| 动画 | 淡入淡出 150ms |
| 配置数据 | 切换时清空协议专用字段 |

### 3.3 保存流程

1. 点击保存 → 按钮进入 loading 状态
2. 前端全字段验证 → 失败聚焦首个错误字段
3. 后端请求 POST/PUT
4. 成功 → Toast "保存成功"，关闭对话框，刷新设备树
5. 失败 → 显示后端错误（字段级或全局横幅）

### 3.4 错误显示

| 类型 | 显示方式 |
|------|----------|
| 字段级 | TextField errorText + 红色下划线 |
| 全局 | Dialog 顶部红色横幅 |
| 网络 | Toast Error + 保留表单数据 |

---

## 4. 响应式适配

| 断点 | 布局 |
|------|------|
| Desktop (> 600px) | 居中对话框，560px |
| Mobile (< 600px) | 底部 Sheet，100% 宽，maxHeight 90vh |
| 字段排列 | 始终单列 |

---

## 5. 主题适配

| 元素 | Light | Dark |
|------|-------|------|
| Dialog Background | Surface | Surface |
| TextField Fill | Surface Variant 50% | Surface Variant 50% |
| Error | Error | Error |
| Disabled | On Surface 38% | On Surface 38% |
| Dropdown Menu | Surface，Elevation 3 | Surface，Elevation 3 |

---

## 6. 设计 QA 检查项

- [ ] 必填字段带 * 标记
- [ ] 所有字段有 Label 和 Placeholder
- [ ] 输入验证规则正确（格式、范围、必填）
- [ ] 协议切换时表单区域正确切换
- [ ] 保存按钮仅在有效时启用
- [ ] 保存时显示 loading 状态
- [ ] 成功/失败反馈正确
- [ ] 移动端转为 BottomSheet
- [ ] Light/Dark 输入框样式正确
- [ ] 串口列表加载状态处理

---

**文档结束**
