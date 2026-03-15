# Kayak - 科学研究支持软件
## Product Requirement Document (PRD)

---

## 1. 产品概述

### 1.1 产品名称
**Kayak** - 科学研究支持平台

### 1.2 产品愿景
为科研人员提供一站式的试验仪器管理、实验过程设计、数据采集与分析平台，支持从实验设计到学术论文产出的完整工作流。

### 1.3 目标用户
- 工程实验室研究人员
- 科学实验数据采集人员
- 需要仪器自动化的研发团队

---

## 2. 功能需求

### 2.1 仪器管理模块

#### 2.1.1 核心概念
- **工作台(Workbench)**: 仪器的逻辑分组，对应一个实验场景
- **设备(Device)**: 试验仪器的抽象，支持嵌套结构
- **测点(Point)**: 设备的具体读写单元

#### 2.1.2 数据模型
```
工作台 (Workbench)
├── 元数据: 名称, 描述, 所属用户/团队
└── 设备列表 (Devices)
    ├── 设备元数据: 名称, 协议类型, 地址, SN码, 制造商
    ├── 子设备 (递归嵌套)
    └── 测点列表 (Points)
        ├── 测点元数据: 名称, 数据类型, 单位
        └── 访问类型: 只读(RO) / 只写(WO) / 读写(RW)
```

#### 2.1.3 支持的协议（插件形式）
| 协议 | 优先级 | 说明 |
|------|--------|------|
| Virtual (虚拟设备) | P0 | 用于开发和测试 |
| Modbus TCP/RTU | P1 | 工业标准协议 |
| CAN/CAN-FD | P2 | 汽车和工业领域 |
| VISA (GPIB/USB/Serial) | P2 | 实验室仪器标准 |
| MQTT | P3 | IoT设备支持 |

#### 2.1.4 RESTful API
```
GET    /api/v1/workbenches              # 获取工作台列表
POST   /api/v1/workbenches              # 创建工作台
GET    /api/v1/workbenches/{id}         # 获取工作台详情
PUT    /api/v1/workbenches/{id}         # 更新工作台
DELETE /api/v1/workbenches/{id}         # 删除工作台

GET    /api/v1/workbenches/{wb_id}/devices
POST   /api/v1/workbenches/{wb_id}/devices
GET    /api/v1/devices/{id}
PUT    /api/v1/devices/{id}
DELETE /api/v1/devices/{id}

GET    /api/v1/devices/{dev_id}/points          # 获取设备测点列表
POST   /api/v1/devices/{dev_id}/points          # 创建测点
GET    /api/v1/points/{id}/value                # 读取测点值
PUT    /api/v1/points/{id}/value                # 写入测点值（WO/RW类型）
GET    /api/v1/points/{id}/history?start=&end=  # 获取测点历史数据
```

### 2.2 试验方法编辑模块

#### 2.2.1 过程定义
试验方法由**环节(Node)**组成的有向图，支持嵌套子过程。

#### 2.2.2 环节类型
| 环节类型 | 功能 | 参数 |
|----------|------|------|
| Start | 过程入口 | 无 |
| Read | 读取仪器数据 | 测点引用, 变量名 |
| Control | 控制仪器 | 测点引用, 目标值 |
| Delay | 延时等待 | 时间(ms) |
| Decision | 条件判断 | 表达式, 真/假分支 |
| Branch | 多分支 | 条件表达式列表 |
| Wait | 等待条件 | 表达式, 超时 |
| Record | 记录数据 | 变量列表 |
| Config | 参数配置 | 参数表 |
| Subprocess | 嵌套子过程 | 子过程引用 |
| End | 过程结束 | 无 |

#### 2.2.3 脚本支持
- 表达式语法: Rust-like 表达式
- 内置函数: 数学运算、字符串处理、时间函数
- 变量作用域: 全局参数表 + 局部变量

#### 2.2.4 配置参数表
```json
{
  "parameters": {
    "temperature_setpoint": {
      "type": "number",
      "default": 25.0,
      "unit": "°C",
      "description": "目标温度"
    },
    "sample_rate": {
      "type": "integer", 
      "default": 1000,
      "unit": "Hz",
      "range": [1, 10000]
    }
  }
}
```

### 2.3 试验过程控制模块

#### 2.3.1 状态机
```
          +---------+
          |  IDLE   |
          +----+----+
               | load
               v
          +---------+
    +---->| LOADED  |<----+
    |     +----+----+     |
    |          | start    | stop/reset
    |          v          |
 pause      +---------+   |
+---------->| RUNNING |---+---> error
|           +----+----+   |
|                | pause  |
|                v        |
|           +---------+   |
+-----------| PAUSED  |---+
            +---------+
```

#### 2.3.2 控制操作
| 操作 | 说明 | 当前状态要求 |
|------|------|--------------|
| Load | 载入试验方法 | IDLE |
| Start | 开始试验 | LOADED/PAUSED |
| Pause | 暂停试验 | RUNNING |
| Resume | 继续试验 | PAUSED |
| Stop | 停止试验 | RUNNING/PAUSED |
| Reset | 重置状态 | 任意状态 |

#### 2.3.3 实时监控
- 仪器数据视图: 实时显示连接的仪器数据
- 参数监控面板: 显示当前配置参数值
- 日志输出窗口: 显示过程执行日志
- 错误信息显示: 异常捕获和显示

#### 2.3.4 数据存储
- 试验数据自动写入HDF5文件
- 元数据记录: 试验ID、方法、参数、时间戳
- 控制操作日志: 操作类型、时间、用户
- 错误日志: 错误类型、堆栈、上下文

### 2.4 数据管理模块

#### 2.4.1 存储架构
```
文件系统: HDF5文件 (科学数据)
  ├── /metadata      # 试验元数据
  ├── /raw_data      # 原始仪器数据
  ├── /processed     # 处理后数据
  └── /annotations   # 用户标注

SQLite数据库 (元信息索引)
  ├── data_files     # HDF5文件元信息
  ├── experiments    # 试验记录
  └── permissions    # 权限记录
```

#### 2.4.2 HDF5文件结构
```
experiment_20240315_001.h5
├── attributes
│   ├── experiment_id
│   ├── method_id
│   ├── user_id
│   ├── team_id
│   ├── start_time
│   └── end_time
├── raw_data
│   ├── device_1/point_1 (time-series dataset)
│   └── device_1/point_2
├── parameters
│   └── config_table
├── logs
│   ├── control_actions
│   └── errors
└── user_data (预留扩展)
```

#### 2.4.3 元信息数据库Schema
```sql
-- HDF5文件元信息表
create table data_files (
    id text primary key,
    file_path text not null,
    file_hash text not null,
    experiment_id text,
    source_type text, -- 'experiment', 'analysis', 'import'
    owner_type text,  -- 'user', 'team'
    owner_id text not null,
    created_at timestamp default current_timestamp,
    modified_at timestamp default current_timestamp,
    data_size_bytes integer,
    record_count integer,
    status text       -- 'active', 'archived', 'deleted'
);

-- 权限表
CREATE TABLE permissions (
    resource_type text,  -- 'workbench', 'method', 'data'
    resource_id text,
    user_id text,
    permission text      -- 'read', 'write', 'admin'
);
```

### 2.5 数据分析模块

#### 2.5.1 可视化工具
| 工具 | 功能 | 输出格式 |
|------|------|----------|
| Time Series | 时序数据绘图 | PNG/SVG/PDF |
| Spectrum | 频谱分析 | PNG/SVG/PDF |
| XY Plot | 散点/曲线图 | PNG/SVG/PDF |
| Histogram | 直方图 | PNG/SVG/PDF |
| Heatmap | 热图 | PNG/SVG/PDF |
| 3D Surface | 三维曲面 | PNG/SVG/PDF |

#### 2.5.2 LaTeX导出
- 图表导出为tikz/pgfplots格式
- 支持pgfplots兼容性
- 自动生成的LaTeX代码可直接嵌入论文

#### 2.5.3 数据导出
- CSV/Excel格式
- HDF5子集导出
- NumPy数组导出（Python客户端）

### 2.6 用户权限模块

#### 2.6.1 权限模型
```
用户(User)
├── 个人工作台/方法/数据
└── 团队 membership

团队(Team)
├── 团队成员 (TeamMember)
│   ├── 角色: owner, admin, member
│   └── 权限: 继承团队权限
├── 团队工作台
├── 团队方法
└── 团队数据
```

#### 2.6.2 权限矩阵
| 角色 | 工作台 | 方法 | 数据 |
|------|--------|------|------|
| Owner | 完全控制 | 完全控制 | 完全控制 + 转移所有权 |
| Admin | 读写 | 读写 | 读写 |
| Member | 只读 | 只读/读写* | 只读/读写* |

*Member权限由Owner/Admin配置

#### 2.6.3 API权限控制
- JWT Token认证
- 基于资源的权限检查
- 团队权限继承

### 2.7 前端界面要求

#### 2.7.1 界面框架
- Material Design 3 设计规范
- 响应式布局（桌面优先）
- 支持多语言（i18n）

#### 2.7.2 主题支持
- 浅色主题（Light）
- 深色主题（Dark）
- 跟随系统（默认）

#### 2.7.3 核心页面
| 页面 | 功能 |
|------|------|
| Dashboard | 工作台概览、快捷操作 |
| Instrument Manager | 仪器配置管理 |
| Method Editor | 试验方法编辑（代码+可视化） |
| Experiment Runner | 试验执行控制台 |
| Data Manager | 数据浏览和管理 |
| Analysis Studio | 数据分析工作台 |
| Settings | 用户设置、团队管理 |

### 2.8 Python客户端库

#### 2.8.1 功能范围
- REST API封装
- 用户认证
- 仪器数据读取
- 数据文件下载
- 本地数据分析（配合pandas/numpy）

#### 2.8.2 安装
```bash
pip install kayak-client
```

#### 2.8.3 基本用法
```python
from kayak import Client

# 连接服务器
client = Client("http://localhost:8080")
client.login("user", "password")

# 获取工作台
workbench = client.get_workbench("workbench_id")

# 读取设备数据
device = workbench.get_device("device_id")
value = device.read_point("point_id")

# 下载数据文件
client.download_data("data_id", "./local_data.h5")
```

---

## 3. 非功能需求

### 3.1 性能需求
| 指标 | 目标值 |
|------|--------|
| API响应时间 | < 100ms (P95) |
| 数据写入吞吐量 | > 10k samples/sec |
| 并发试验数 | >= 5 |
| 前端首屏加载 | < 3s |

### 3.2 可靠性需求
- 试验过程异常恢复
- 自动数据备份
- 日志完整性保证

### 3.3 可扩展性需求
- 插件化协议支持
- 模块化功能扩展
- 水平扩展能力

### 3.4 安全需求
- 密码加密存储 (bcrypt)
- API通信加密 (TLS)
- 敏感数据脱敏

---

## 4. 部署架构

### 4.1 四种部署模式

#### 模式1: 桌面完整部署
```
┌─────────────────────────────────────┐
│           Desktop App               │
│  ┌──────────────┐  ┌──────────────┐ │
│  │   Flutter    │  │   Rust       │ │
│  │   Frontend   │──│   Backend    │ │
│  └──────────────┘  └──────────────┘ │
│         │                 │         │
│         └─────┬───────────┘         │
│               │                     │
│         ┌─────▼───────┐             │
│         │  SQLite DB  │             │
│         └─────────────┘             │
└─────────────────────────────────────┘
```

#### 模式2: 单容器Web部署
```
┌────────────────────────────────────────┐
│           Docker Container             │
│  ┌──────────────┐  ┌──────────────┐    │
│  │   Flutter    │  │   Rust       │    │
│  │   Web App    │──│   Backend    │    │
│  └──────────────┘  └──────────────┘    │
│         │                 │            │
│         └─────┬───────────┘            │
│               │                        │
│         ┌─────▼───────┐                │
│         │  SQLite DB  │                │
│         └─────────────┘                │
└────────────────────────────────────────┘
```

#### 模式3: 前后端分离双容器部署
```
┌──────────────────┐      ┌──────────────────┐
│  Frontend        │      │  Backend         │
│  Container       │      │  Container       │
│  ┌────────────┐  │      │  ┌────────────┐  │
│  │ Flutter    │  │      │  │ Rust       │  │
│  │ Web App    │──┼──────┼──▶ Backend    │  │
│  └────────────┘  │      │  └────────────┘  │
└──────────────────┘      │         │        │
                          │    ┌────▼────┐   │
                          │    │ SQLite  │   │
                          │    └─────────┘   │
                          └──────────────────┘
```

#### 模式4: 混合部署（桌面前端+容器后端）
```
┌─────────────────────┐         ┌──────────────────┐
│   Desktop (Win/Mac/ │         │  Backend         │
│    Linux)           │         │  Container       │
│  ┌───────────────┐  │         │  ┌────────────┐  │
│  │ Flutter       │  │         │  │ Rust       │  │
│  │ Desktop App   │──┼─────────┼──▶ Backend    │  │
│  └───────────────┘  │         │  └────────────┘  │
└─────────────────────┘         │         │        │
                                │    ┌────▼────┐   │
                                │    │ SQLite  │   │
                                │    └─────────┘   │
                                └──────────────────┘
```

---

## 5. Release 0 范围

### 5.1 包含的功能

#### Sprint 1 (2周)
| 任务 | 内容 |
|------|------|
| 1.1 | 项目工程搭建与CI/CD |
| 1.2 | 用户认证系统 |
| 1.3 | 基础仪器管理（虚拟设备） |

#### Sprint 2 (2周)
| 任务 | 内容 |
|------|------|
| 2.1 | 数据管理基础框架 |
| 2.2 | 试验过程控制基础框架 |
| 2.3 | 前端基础UI与导航 |

### 5.2 交付标准
- [ ] 可编译运行，无错误无警告
- [ ] 提供启动/停止脚本
- [ ] 支持桌面部署和单容器部署
- [ ] 完整的API文档
- [ ] 基础用户手册

### 5.3 不包含的功能（移至后续Release）
- Modbus/CAN/VISA协议支持（P1/P2）
- 可视化试验方法编辑器
- 数据分析模块
- Python客户端库
- LaTeX导出
- 团队权限管理

---

## 6. 附录

### 6.1 术语表
| 术语 | 说明 |
|------|------|
| Workbench | 工作台，仪器的逻辑分组 |
| Device | 设备，试验仪器的抽象 |
| Point | 测点，设备的具体读写单元 |
| Method | 试验方法，定义实验过程 |
| Experiment | 一次具体的试验执行 |

### 6.2 技术选型
| 领域 | 技术 |
|------|------|
| 前端 | Flutter 3.x |
| 后端 | Rust + Axum |
| 数据库 | SQLite 3 + sqlx |
| 数据存储 | HDF5 |
| 容器 | Docker |
| 构建 | Cargo (Rust), Flutter CLI |

### 6.3 参考文档
- Material Design 3: https://m3.material.io/
- HDF5 Format: https://www.hdfgroup.org/solutions/hdf5/
- Flutter Desktop: https://docs.flutter.dev/desktop
- Rust Axum: https://docs.rs/axum/

---

**版本**: 1.0  
**创建日期**: 2024-03-15  
**状态**: Draft
