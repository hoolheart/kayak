# Release 1 产品需求文档 (PRD)

**版本**: 1.1  
**日期**: 2026-05-02  
**状态**: 已批准  
**范围**: Sprint 1-2 (共4周)

---

## 1. 版本概述

### 1.1 版本目标
Release 1 的核心目标有三个：
1. **前端全面重新设计**：Release 0 的前端页面未经专业 UI 设计，Release 1 将由 sw-anna 进行全新 UI/UX 设计，提升视觉品质和用户体验
2. **扩展设备协议支持**：实现 **Modbus TCP** 和 **Modbus RTU** 两种工业标准协议的驱动支持
3. **Web 模式优先**：所有前端开发和可视化测试默认使用 Web 模式 (`flutter run -d chrome`)

### 1.2 与 Release 0 的关系
Release 0 建立了平台基础框架：
- ✅ 用户认证与授权
- ✅ 工作台/设备/测点管理（仅 Virtual 协议）
- ✅ 试验方法编辑与执行
- ✅ 数据采集与存储
- ❌ 前端页面未经专业 UI 设计

Release 1 在此基础上扩展：
- 🆕 **全新 UI/UX 设计**（Figma 原型 + 设计规范）
- 🆕 **Web 模式默认部署**
- 🆕 Modbus TCP 协议驱动
- 🆕 Modbus RTU 协议驱动
- 🆕 Modbus 模拟设备（TCP/RTU）
- 🆕 多协议设备配置UI

### 1.3 版本范围决策

| 模块 | 包含 | 说明 |
|------|------|------|
| 全新 UI/UX 设计 | ✅ | Figma 原型 + 设计规范文档 |
| Web 模式部署 | ✅ | 默认使用 `flutter build web` |
| Modbus TCP 驱动 | ✅ | 含模拟设备 |
| Modbus RTU 驱动 | ✅ | 含模拟设备 |
| 协议配置UI | ✅ | 基于新设计的 UI 规范 |
| CAN/CAN-FD 驱动 | ❌ | 移至 Release 2 |
| VISA 驱动 | ❌ | 移至 Release 2 |
| MQTT 驱动 | ❌ | 移至 Release 3 |
| 可视化编辑器 | ❌ | 移至 Release 2 |
| 数据分析 | ❌ | 移至 Release 2-3 |

---

## 2. 功能需求

### 2.1 Modbus TCP 协议驱动 (R1-PROTO-001)

#### 2.1.1 功能描述
实现 Modbus TCP 协议驱动，支持通过 TCP/IP 网络与 Modbus 从站设备通信。

#### 2.1.2 支持的数据模型

| Modbus 功能码 | 数据类型 | 读写权限 | 说明 |
|--------------|---------|---------|------|
| 01 (0x01) | Coil | RW | 线圈状态，布尔值 |
| 02 (0x02) | Discrete Input | RO | 离散输入，布尔值 |
| 03 (0x03) | Holding Register | RW | 保持寄存器，16位无符号整数 |
| 04 (0x04) | Input Register | RO | 输入寄存器，16位无符号整数 |

#### 2.1.3 配置参数

```json
{
  "host": "192.168.1.100",
  "port": 502,
  "slave_id": 1,
  "timeout_ms": 5000,
  "connection_pool_size": 4
}
```

#### 2.1.4 测点配置

```json
{
  "function_code": 3,
  "address": 0,
  "quantity": 1,
  "data_type": "uint16",
  "scale": 1.0,
  "offset": 0.0
}
```

#### 2.1.5 错误处理
- 连接超时：返回 `DriverError::Timeout`
- 从站无响应：返回 `DriverError::IoError`
- 非法功能码：返回 `DriverError::InvalidValue`
- 地址越界：返回 `DriverError::InvalidValue`

### 2.2 Modbus RTU 协议驱动 (R1-PROTO-002)

#### 2.2.1 功能描述
实现 Modbus RTU 串口协议驱动，支持 RS485/RS232 接口。

#### 2.2.2 串口参数配置

| 参数 | 可选值 | 默认值 |
|------|--------|--------|
| port | 系统串口列表 | "/dev/ttyUSB0" |
| baud_rate | 9600, 19200, 38400, 57600, 115200 | 9600 |
| data_bits | 7, 8 | 8 |
| stop_bits | 1, 2 | 1 |
| parity | None, Even, Odd | None |

#### 2.2.3 配置参数

```json
{
  "port": "/dev/ttyUSB0",
  "baud_rate": 9600,
  "data_bits": 8,
  "stop_bits": 1,
  "parity": "None",
  "slave_id": 1,
  "timeout_ms": 1000
}
```

#### 2.2.4 跨平台支持
- **Linux**: `/dev/ttyUSB0`, `/dev/ttyACM0`, `/dev/ttyS0`
- **macOS**: `/dev/cu.usbserial-*`, `/dev/tty.usbserial-*`
- **Windows**: `COM1`, `COM2`, `COM3`

### 2.3 Modbus 模拟设备 (R1-SIM-001 / R1-SIM-002)

#### 2.3.1 功能描述
为 Modbus TCP 和 Modbus RTU 分别实现模拟设备，用于：
1. 开发测试（无真实硬件）
2. CI/CD 自动化测试
3. 用户演示和培训

#### 2.3.2 模拟设备架构

```
┌─────────────────────────────────────────┐
│           Modbus Simulator              │
├─────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    │
│  │ TCP Server  │    │ RTU Server  │    │
│  │ (tokio::net)│    │ (tokio-serial)│  │
│  └──────┬──────┘    └──────┬──────┘    │
│         │                  │            │
│  ┌──────▼──────────────────▼──────┐     │
│  │      Modbus Frame Parser       │     │
│  └──────┬──────────────────┬──────┘     │
│         │                  │            │
│  ┌──────▼──────┐    ┌──────▼──────┐     │
│  │ Coil Memory │    │ Register    │     │
│  │ (Vec<bool>) │    │ Memory      │     │
│  └─────────────┘    │ (Vec<u16>)  │     │
│                     └─────────────┘     │
└─────────────────────────────────────────┘
```

#### 2.3.3 模拟数据配置

```json
{
  "coils": {
    "0": true,
    "1": false,
    "2": true
  },
  "discrete_inputs": {
    "0": true,
    "1": false
  },
  "holding_registers": {
    "0": 2500,
    "1": 3000
  },
  "input_registers": {
    "0": 1500,
    "1": 2000
  },
  "auto_increment": {
    "holding_registers": {
      "0": { "step": 1, "min": 0, "max": 65535 }
    }
  }
}
```

#### 2.3.4 模拟设备启动方式
- **嵌入式模式**: 作为测试辅助工具，在单元测试中启动临时模拟设备
- **独立进程模式**: 提供可执行文件，用于手动测试和演示
- **Docker模式**: 提供 Dockerfile，用于 CI/CD 环境

### 2.4 全新 UI/UX 设计 (R1-UI-001)

#### 2.4.1 设计目标
Release 0 的前端页面未经专业 UI 设计，视觉品质和用户体验有待提升。Release 1 将由 sw-anna 进行全新 UI/UX 设计，建立统一的设计规范。

#### 2.4.2 设计范围

| 页面 | 设计内容 | 优先级 |
|------|---------|--------|
| 登录页 | 全新视觉设计，品牌感提升 | P0 |
| Dashboard | 数据可视化布局，信息层次优化 | P0 |
| 工作台列表 | 卡片/列表视图优化，空状态设计 | P0 |
| 工作台详情 | 设备树形展示优化，Tab导航重设计 | P0 |
| 设备配置 | 协议选择器 + 动态表单（新设计重点） | P0 |
| 试验列表 | 状态标识优化，筛选交互改进 | P1 |
| 试验控制台 | 控制按钮组重设计，日志窗口优化 | P1 |
| 方法编辑 | JSON编辑器视觉优化 | P1 |
| 设置页 | 设置项分组，表单布局优化 | P1 |

#### 2.4.3 设计规范要求
- **设计语言**: Material Design 3 为基础，融入品牌特色
- **色彩系统**: 重新定义主色、辅色、语义色，确保浅色/深色主题一致性
- **排版系统**: 定义字体层级、字重、行高规范
- **组件规范**: 按钮、输入框、卡片、表格、对话框的统一样式
- **间距系统**: 8pt 网格系统，统一的间距规范
- **图标系统**: 统一使用 Material Symbols，定义图标大小规范
- **动效规范**: 页面过渡、状态切换的微动效

#### 2.4.4 交付物
1. **Figma 原型文件**: 所有页面的高保真原型
2. **设计规范文档**: 色彩、字体、组件、间距规范
3. **切图资源**: 图标、插图等静态资源
4. **UI 规格说明**: 每个页面的详细尺寸、颜色、交互说明

### 2.5 多协议设备配置UI (R1-PROTO-UI-001)

#### 2.5.1 功能描述
基于新 UI 设计规范，扩展创建设备UI，支持选择多种协议，每种协议显示对应的参数配置表单。

#### 2.5.2 协议选择器
- 下拉选择框，选项：Virtual / Modbus TCP / Modbus RTU
- 选择后动态加载对应协议的参数表单
- 使用新设计的下拉组件样式

#### 2.5.3 协议参数表单

**Virtual 协议表单**：
- 模式选择：Random / Fixed / Sine / Ramp
- 数据类型：Number / Integer / String / Boolean
- 访问类型：RO / WO / RW
- 最小值/最大值
- 固定值（Fixed模式）

**Modbus TCP 协议表单**（新增）：
- 主机地址（IP输入框）
- 端口（数字输入，默认502）
- 从站ID（数字输入，默认1）
- 超时时间（毫秒）
- 连接池大小

**Modbus RTU 协议表单**（新增）：
- 串口选择（下拉框，自动扫描可用串口）
- 波特率选择：9600/19200/38400/57600/115200
- 数据位：7/8
- 停止位：1/2
- 校验：None/Even/Odd
- 从站ID
- 超时时间

#### 2.5.4 测点配置增强
- 根据协议类型显示不同的测点配置字段
- Modbus 测点需配置：功能码、地址、数量、数据类型、缩放因子、偏移量

#### 2.5.5 协议参数验证
- IP地址格式验证
- 端口范围验证（1-65535）
- 从站ID验证（1-247）
- 串口参数组合验证

---

## 3. 非功能需求

### 3.1 性能需求
- Modbus TCP 单次读写响应时间 < 100ms（局域网环境）
- Modbus RTU 单次读写响应时间 < 200ms（9600波特率）
- 模拟设备支持最多 10 个并发客户端连接

### 3.2 可靠性需求
- 连接断开自动重试（最多3次）
- 网络超时可配置（默认5秒）
- 串口错误优雅处理

### 3.3 兼容性需求
- 支持标准 Modbus 协议（符合 Modbus Application Protocol V1.1b3）
- 串口库支持 Windows/macOS/Linux 三平台

### 3.4 测试需求
- 所有驱动功能必须有单元测试覆盖
- 模拟设备必须支持自动化测试
- 协议配置UI必须有 Widget 测试

### 3.5 Web 模式部署需求
- **默认部署目标**: Web (`flutter build web`)
- **开发测试**: `flutter run -d chrome`
- **浏览器兼容**: Chrome, Edge, Firefox, Safari (最新2个版本)
- **响应式适配**: 支持桌面端 (>=1280px) 和 平板端 (>=768px)
- **Web 特定优化**:
  - 首屏加载时间 < 3s
  - 支持 PWA 模式
  - 禁用桌面端特有的窗口管理功能（window_manager）

---

## 4. 接口需求

### 4.1 后端API扩展

#### 4.1.1 获取支持的协议列表
```
GET /api/v1/protocols

Response:
{
  "code": 200,
  "data": [
    {
      "id": "virtual",
      "name": "Virtual",
      "description": "虚拟设备（用于测试）",
      "config_schema": { ... }
    },
    {
      "id": "modbus_tcp",
      "name": "Modbus TCP",
      "description": "Modbus TCP/IP 协议",
      "config_schema": { ... }
    },
    {
      "id": "modbus_rtu",
      "name": "Modbus RTU",
      "description": "Modbus RTU 串口协议",
      "config_schema": { ... }
    }
  ]
}
```

#### 4.1.2 获取可用串口列表
```
GET /api/v1/system/serial-ports

Response:
{
  "code": 200,
  "data": [
    { "path": "/dev/ttyUSB0", "description": "USB Serial" },
    { "path": "/dev/ttyACM0", "description": "USB ACM" }
  ]
}
```

#### 4.1.3 设备连接测试
```
POST /api/v1/devices/{id}/test-connection

Response:
{
  "code": 200,
  "data": {
    "success": true,
    "latency_ms": 15,
    "message": "Connection successful"
  }
}
```

### 4.2 数据库Schema扩展

#### 4.2.1 设备表扩展
设备表 `devices` 的 `protocol_config` JSON 字段需要支持新的协议配置：

**Modbus TCP 配置示例**:
```json
{
  "protocol": "modbus_tcp",
  "host": "192.168.1.100",
  "port": 502,
  "slave_id": 1,
  "timeout_ms": 5000,
  "connection_pool_size": 4
}
```

**Modbus RTU 配置示例**:
```json
{
  "protocol": "modbus_rtu",
  "port": "/dev/ttyUSB0",
  "baud_rate": 9600,
  "data_bits": 8,
  "stop_bits": 1,
  "parity": "None",
  "slave_id": 1,
  "timeout_ms": 1000
}
```

#### 4.2.2 测点表扩展
测点表 `points` 的 `metadata` JSON 字段需要支持 Modbus 特定配置：

```json
{
  "modbus": {
    "function_code": 3,
    "address": 0,
    "quantity": 1,
    "data_type": "uint16",
    "scale": 1.0,
    "offset": 0.0
  }
}
```

---

## 5. 验收标准

### 5.1 功能验收

| 验收项 | 验收标准 | 优先级 |
|--------|---------|--------|
| 全新 UI/UX 设计 | Figma 原型完成，设计规范文档完整 | P0 |
| Web 模式部署 | `flutter build web` 成功，可在浏览器运行 | P0 |
| Modbus TCP 驱动 | 可成功连接模拟设备，读写线圈和寄存器 | P0 |
| Modbus RTU 驱动 | 可成功连接模拟设备，读写线圈和寄存器 | P0 |
| Modbus TCP 模拟设备 | 可独立启动，响应标准 Modbus 请求 | P0 |
| Modbus RTU 模拟设备 | 可独立启动，响应标准 Modbus 请求 | P0 |
| 协议配置UI | 可创建/编辑 Modbus 设备，表单验证正确 | P0 |
| 串口扫描 | 可扫描并显示系统可用串口 | P1 |
| 连接测试 | 可测试设备连接并返回结果 | P1 |

### 5.2 质量验收

| 验收项 | 标准 |
|--------|------|
| 编译 | `cargo build` 无错误、无警告 |
| 单元测试 | `cargo test` 全部通过，覆盖率 > 80% |
| 前端编译 | `flutter build web` 无错误、无警告 |
| 前端运行 | `flutter run -d chrome` 正常展示所有页面 |
| 集成测试 | 端到端流程测试通过 |
| 文档 | API文档、用户手册、开发文档完整 |

---

## 6. 风险与缓解

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|----------|
| UI 设计工作量超预期 | 中 | 高 | Sprint 1 第一周完成核心页面设计，逐步迭代 |
| Web 模式兼容性问题 | 中 | 中 | 使用条件编译隔离桌面端代码，CI 验证 Web 编译 |
| tokio-modbus crate 不稳定 | 低 | 高 | 提前进行技术预研，准备替代方案（自研简单实现） |
| 串口跨平台兼容性 | 中 | 中 | 使用 tokio-serial crate，CI中三平台编译验证 |
| 模拟设备复杂度超预期 | 中 | 中 | 先实现基础功能（线圈+保持寄存器），再扩展 |
| DeviceManager 泛型限制 | 高 | 高 | Sprint 1 第一周完成架构重构 |

---

**文档结束**
