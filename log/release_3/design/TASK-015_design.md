# TASK-015 详细设计 — 设备 Service + Provider & 测点 Service + Provider

> **作者**: sw-tom (Developer)
> **日期**: 2026-05-31
> **状态**: 已完成

---

## 1. 概述

本设计文档涵盖 TASK-015 所需的四个核心组件的详细设计：

| 组件 | 文件 | 角色 |
|------|------|------|
| DeviceService | `lib/services/device_service.dart` | 设备 CRUD + 连接管理 HTTP API 封装 |
| PointService | `lib/services/point_service.dart` | 测点 CRUD + 值读写 HTTP API 封装 |
| DeviceTreeNotifier + DeviceDetailNotifier | `lib/providers/device_provider.dart` | 设备树状态管理 + 单设备详情状态管理 |
| PointListNotifier | `lib/providers/point_provider.dart` | 测点列表 + 实时值状态管理 |

设计遵循已有模式：
- **Service 层**: 与 `WorkbenchService` 一致的 `ApiClient` 模式
- **Provider 层**: 与 `WorkbenchListNotifier` / `WorkbenchDetailNotifier` 一致的 Riverpod 3.x `AsyncNotifier` 模式

---

## 2. 类设计

### 2.1 DeviceService

```
┌─────────────────────────────────────────────┐
│                 DeviceService                 │
├─────────────────────────────────────────────┤
│ - _client: ApiClient                         │
├─────────────────────────────────────────────┤
│ + DeviceService(ApiClient)                   │
│ + listByWorkbench(wbId): List<Device>        │
│ + getById(id): Device                        │
│ + create(...): Device                        │
│ + update(id, data): Device                   │
│ + delete(id): void                           │
│ + testConnection(id): Map<String, dynamic>   │
│ + connect(id): void                          │
│ + disconnect(id): void                       │
│ + getStatus(id): String                      │
└─────────────────────────────────────────────┘
```

**API 映射**:

| 方法 | HTTP | Path |
|------|------|------|
| `listByWorkbench(wbId)` | GET | `/api/v1/devices?workbench_id={wbId}` |
| `getById(id)` | GET | `/api/v1/devices/{id}` |
| `create(...)` | POST | `/api/v1/devices` |
| `update(id, data)` | PUT | `/api/v1/devices/{id}` |
| `delete(id)` | DELETE | `/api/v1/devices/{id}` |
| `testConnection(id)` | POST | `/api/v1/devices/{id}/test-connection` |
| `connect(id)` | POST | `/api/v1/devices/{id}/connect` |
| `disconnect(id)` | POST | `/api/v1/devices/{id}/disconnect` |
| `getStatus(id)` | GET | `/api/v1/devices/{id}/status` |

**数据流**:

```
UI → Provider.call() → DeviceService.method() → ApiClient.get/post/put/delete → Dio → HTTP
```

所有方法通过 `ApiResponse<T>.fromJson()` 解包，返回 `data` 字段。
异常不捕获，由 `ErrorInterceptor` 和 Provider 层统一处理。

### 2.2 PointService

```
┌─────────────────────────────────────────────┐
│                 PointService                  │
├─────────────────────────────────────────────┤
│ - _client: ApiClient                         │
├─────────────────────────────────────────────┤
│ + PointService(ApiClient)                    │
│ + listByDevice(deviceId): List<Point>        │
│ + getById(id): Point                         │
│ + create(...): Point                         │
│ + update(id, data): Point                    │
│ + delete(id): void                           │
│ + getValue(id): PointValue                   │
│ + setValue(id, value): void                  │
└─────────────────────────────────────────────┘
```

**API 映射**:

| 方法 | HTTP | Path |
|------|------|------|
| `listByDevice(deviceId)` | GET | `/api/v1/points?device_id={deviceId}` |
| `getById(id)` | GET | `/api/v1/points/{id}` |
| `create(...)` | POST | `/api/v1/points` |
| `update(id, data)` | PUT | `/api/v1/points/{id}` |
| `delete(id)` | DELETE | `/api/v1/points/{id}` |
| `getValue(id)` | GET | `/api/v1/points/{id}/value` |
| `setValue(id, value)` | PUT | `/api/v1/points/{id}/value` |

### 2.3 DeviceTreeNotifier

```
┌────────────────────────────────────────────────────────────┐
│                DeviceTreeNotifier                          │
│                extends AsyncNotifier<List<DeviceTreeNode>>  │
├────────────────────────────────────────────────────────────┤
│ + build(): List<DeviceTreeNode>  (family: workbenchId)     │
│ + refresh(): void                                          │
│ # _buildTree(List<Device>): List<DeviceTreeNode>           │
└────────────────────────────────────────────────────────────┘
```

**树构建算法**:

```
输入: 平铺 List<Device>
输出: 嵌套 List<DeviceTreeNode>

1. 按 parentId 分组:
   - rootDevices: parentId == null
   - childrenByParentId: parentId -> List<Device>
2. 遍历 rootDevices:
   - 为每个 rootDevice 创建 DeviceTreeNode
   - 递归查找并填充 children
3. 返回根节点列表
```

**状态流转**:
- `AsyncLoading` → build 执行中
- `AsyncData<List<DeviceTreeNode>>` → 构建成功
- `AsyncError` → 加载失败（网络错误、解析错误）

### 2.4 DeviceDetailNotifier

```
┌─────────────────────────────────────────────────────┐
│              DeviceDetailNotifier                    │
│              extends AsyncNotifier<Device>           │
├─────────────────────────────────────────────────────┤
│ + DeviceDetailNotifier(id)                           │
│ + build(): Device  (family: deviceId)                │
│ + createDevice(...): void                            │
│ + updateDevice(data): void                           │
│ + deleteDevice(): void                               │
│ + testConnection(): Map<String, dynamic>             │
│ + connect(): void                                    │
│ + disconnect(): void                                 │
│ # _mapError(Object): String                          │
│ # _mapStatusCode(int?): String                       │
└─────────────────────────────────────────────────────┘
```

**操作互斥**: 通过 `_isOperationInProgress` 标志位控制，防止连接/断开/测试连接并发执行。

**副作用**:
- `createDevice` 成功后 → 刷新 `deviceTreeProvider`
- `deleteDevice` 成功后 → 刷新 `deviceTreeProvider`
- `updateDevice` 成功后 → 更新本地状态 + 刷新 `deviceTreeProvider`

### 2.5 PointListNotifier

```
┌─────────────────────────────────────────────────────┐
│              PointListNotifier                       │
│              extends AsyncNotifier<List<Point>>      │
├─────────────────────────────────────────────────────┤
│ + build(): List<Point>  (family: deviceId)          │
│ + refresh(): void                                    │
│ + createPoint(...): void                             │
│ + deletePoint(id): void                              │
│ + refreshValues(): Map<String, PointValue>           │
│ # _mapError(Object): String                          │
│ # _mapStatusCode(int?): String                       │
└─────────────────────────────────────────────────────┘
```

**批量值读取**:
- `refreshValues()` 遍历当前列表中的每个测点
- 为每个测点调用 `PointService.getValue()`
- 结果以 `Map<String, PointValue>` 形式存储（pointId → PointValue）
- 单个测点读取失败不影响其他测点

---

## 3. 数据流图

### 3.1 设备树加载流程

```
┌──────────┐    ┌────────────────────┐    ┌───────────────┐    ┌───────────┐
│   UI     │    │ DeviceTreeNotifier │    │ DeviceService │    │ ApiClient │
│          │    │   .build()         │    │ .listByWork-  │    │  .get()   │
│          │    │                    │    │   bench()     │    │           │
├──────────┤    ├────────────────────┤    ├───────────────┤    ├───────────┤
│ watch()  │───→│                    │    │               │    │           │
│          │    │  state=Loading     │───→│  /api/v1/     │───→│  GET      │
│          │    │                    │    │  devices      │    │           │
│          │    │                    │    │  ?workbench_id│    │           │
│          │    │                    │    │               │←───│  Response │
│          │    │  _buildTree()      │←───│  List<Device> │    │           │
│          │    │                    │    │               │    │           │
│          │←───│  state=Data(tree)  │    │               │    │           │
└──────────┘    └────────────────────┘    └───────────────┘    └───────────┘
```

### 3.2 创建设备流程

```
┌──────────┐  ┌──────────────────┐  ┌───────────────┐  ┌───────────┐  ┌──────────────────┐
│   UI     │  │ DeviceDetailN.   │  │ DeviceService │  │ ApiClient │  │ DeviceTreeN.     │
├──────────┤  ├──────────────────┤  ├───────────────┤  ├───────────┤  ├──────────────────┤
│ call     │─→│ createDevice()   │  │               │  │           │  │                  │
│          │  │ state=Loading    │─→│ .create()     │─→│ POST      │  │                  │
│          │  │                  │  │               │←─│ Response  │  │                  │
│          │  │                  │←─│ Device        │  │           │  │                  │
│          │  │ refreshTree()    │───────────────────────────────────→│ refresh()        │
│          │  │ state=Data       │  │               │  │           │  │ state=Loading    │
│          │←─│ (or Error)       │  │               │  │           │  │ state=Data(新树) │
└──────────┘  └──────────────────┘  └───────────────┘  └───────────┘  └──────────────────┘
```

### 3.3 批量读取测点值流程

```
┌──────────┐  ┌──────────────────┐  ┌───────────────┐  ┌───────────┐
│   UI     │  │ PointListN.      │  │ PointService  │  │ ApiClient │
├──────────┤  ├──────────────────┤  ├───────────────┤  ├───────────┤
│ call     │─→│ refreshValues()  │  │               │  │           │
│          │  │ for each point:  │─→│ .getValue(id) │─→│ GET /{id}/│
│          │  │                  │  │               │  │   value   │
│          │  │                  │←─│ PointValue    │←─│ Response  │
│          │  │ store in _values │  │               │  │           │
│          │  │ Map<pointId, v>  │  │               │  │           │
│          │  │ state = Data     │  │               │  │           │
│          │←─│ (points with     │  │               │  │           │
│          │  │  current values) │  │               │  │           │
└──────────┘  └──────────────────┘  └───────────────┘  └───────────┘
```

---

## 4. 服务注册

更新 `lib/providers/services.dart`，添加：

```dart
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.read(apiClientProvider));
});

final pointServiceProvider = Provider<PointService>((ref) {
  return PointService(ref.read(apiClientProvider));
});
```

---

## 5. 关键设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| DeviceTree 构建位置 | Provider 层（而非 Service 层） | Service 层保持简单，只做 API 映射；树构建是状态管理逻辑 |
| 操作互斥 | `_isOperationInProgress` 标志 | 防止连接/测试/断开并发执行导致状态不一致 |
| 批量值读取 | `refreshValues()` 返回 `Map<String, PointValue>` | 让 UI 层灵活展示值，单个失败不中断整体流程 |
| 错误映射 | `_mapError` / `_mapStatusCode` 私有方法 | 与 `WorkbenchListNotifier` 一致的用户可读错误消息 |
| 创建/删除后刷新 | 通过 `ref.invalidate(deviceTreeProvider)` | 确保设备树始终反映最新数据 |

---

## 6. DeviceTreeNode 构建算法

```dart
List<DeviceTreeNode> _buildTree(List<Device> devices) {
  // 1. 按 parentId 分组
  final Map<String?, List<Device>> grouped = {};
  for (final device in devices) {
    grouped.putIfAbsent(device.parentId, () => []).add(device);
  }

  // 2. 递归构建树节点
  List<DeviceTreeNode> buildChildren(String? parentId) {
    final children = grouped[parentId] ?? [];
    return children.map((device) {
      return DeviceTreeNode(
        id: device.id,
        workbenchId: device.workbenchId,
        parentId: device.parentId,
        name: device.name,
        protocolType: device.protocolType,
        protocolParams: device.protocolParams,
        manufacturer: device.manufacturer,
        model: device.model,
        sn: device.sn,
        status: device.status,
        children: buildChildren(device.id),
        createdAt: device.createdAt,
        updatedAt: device.updatedAt,
      );
    }).toList();
  }

  // 3. 从根节点（parentId == null）开始
  return buildChildren(null);
}
```

---

## 7. 文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/services/device_service.dart` | **新建** | 设备 Service |
| `lib/services/point_service.dart` | **新建** | 测点 Service |
| `lib/providers/device_provider.dart` | **新建** | 设备 Provider（DeviceTreeNotifier + DeviceDetailNotifier） |
| `lib/providers/point_provider.dart` | **新建** | 测点 Provider（PointListNotifier） |
| `lib/providers/services.dart` | **修改** | 注册 deviceServiceProvider + pointServiceProvider |

---

## 8. 测试策略

参见 `log/release_3/test/TASK-015_test_cases.md`（52 个用例）。

关键测试点：
- Service 层：验证 HTTP 方法、路径、参数、响应解析
- Provider 层：验证状态流转、树构建、创建/删除后刷新、错误映射
- 注册：验证 Provider 容器中可正确访问所有新组件
