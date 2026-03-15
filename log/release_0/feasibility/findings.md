# Kayak 技术可行性评估 - 研究发现

## 项目需求摘要

### 核心功能模块
1. **仪器管理**：工作台-设备-测点三层结构，设备可嵌套，支持Modbus/CAN/VISA等协议插件
2. **试验方法编辑**：基于脚本的过程定义，可视化编辑能力
3. **试验过程控制**：启动/暂停/停止，HDF5数据存储
4. **数据管理**：HDF5文件 + SQLite元数据
5. **数据分析**：可视化分析，LaTeX图表导出
6. **用户权限管理**：团队/用户两层权限
7. **多语言支持**：英文/中文/法文
8. **Material Design风格**：浅色/深色主题

### 技术要求
- 前端：Flutter
- 后端：Rust
- 部署方式：桌面完整部署、单容器Web部署、前后端分离双容器部署、混合部署

## 研究发现

### Flutter 桌面端可行性
**状态：可行**
- Flutter 3.x版本桌面支持已稳定（Windows/macOS/Linux）
- Material 3设计系统完全支持浅色/深色主题
- flutter_localizations支持多语言国际化
- 图表可视化：fl_chart、syncfusion_flutter_charts等库可用
- 文件操作：通过path_provider、file_selector支持

### Rust 后端可行性
**状态：可行**
- Tokio异步运行时成熟，适合高并发仪器通信
- HDF5绑定：hdf5-rust crate可用
- SQLite：rusqlite crate稳定
- 协议支持：
  - Modbus: tokio-modbus
  - CAN: socketcan crate
  - VISA: 需调研或自行实现FFI绑定
- Web框架：Axum或Actix-web支持REST API和WebSocket

### 数据库架构
**推荐方案：HDF5 + SQLite混合**
- HDF5：存储实验数据（时序数据、波形等）
- SQLite：存储元数据（仪器配置、实验定义、用户信息）
- 理由：HDF5适合大块科学数据，SQLite适合关系型元数据

### 部署方案分析
| 部署方式 | 技术挑战 | 可行性 |
|----------|----------|--------|
| 桌面完整部署 | Flutter桌面 + Rust嵌入式服务 | 高 |
| 单容器Web部署 | Web版Flutter编译 + Rust后端 | 高 |
| 前后端分离部署 | 标准容器化部署 | 高 |
| 混合部署 | 桌面前端 + 容器后端 | 中（网络配置复杂） |

### LaTeX图表导出
- 可行方案：
  1. matplotlib (Python) 通过Python客户端库实现
  2. tikzplotlib 生成TikZ代码
  3. pgfplots 直接生成LaTeX代码
- 推荐：通过Python客户端库使用matplotlib生成高质量图表

### Python客户端库
- 必要性：连接数据分析生态（NumPy, SciPy, pandas）
- 实现：PyO3或rust-cpython绑定，或直接HTTP API封装
