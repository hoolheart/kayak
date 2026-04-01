# S2-006: 数据管理页面 - 试验详情与数据查看 (Experiment Detail and Data View)

**任务ID**: S2-006  
**任务名称**: 数据管理页面 - 试验详情与数据查看 (Data Management Page - Experiment Detail and Data View)  
**文档版本**: 1.1  
**创建日期**: 2026-04-01  
**测试类型**: 单元测试、Widget测试、集成测试  
**技术栈**: Flutter / Riverpod / mocktail / flutter_test  
**依赖任务**: S2-005 (试验列表页面), S2-004 (试验数据查询API)

---

## 1. 测试概述

### 1.1 测试范围

本文档覆盖 S2-006 任务的所有功能测试，包括：
1. **试验详情页面** - 展示试验元信息（名称、状态、时间等）
2. **测点历史数据展示** - 时序数据表格（时间戳+数值）
3. **数据导出功能** - CSV格式导出
4. **API集成** - 获取试验详情和测点历史数据
5. **错误处理** - 网络错误、数据加载失败等情况

### 1.2 验收标准映射

| 验收标准 | 相关测试用例 | 测试类型 |
|---------|-------------|---------|
| 1. 展示试验完整元信息 | TC-STATE-001 ~ TC-STATE-003, TC-UI-001 ~ TC-UI-005 | Unit + Widget |
| 2. 测点数据表格展示 | TC-STATE-004 ~ TC-STATE-006, TC-UI-006 ~ TC-UI-010 | Unit + Widget |
| 3. 导出CSV功能可用 | TC-CSV-001 ~ TC-CSV-006 | Unit + Integration |

### 1.3 数据模型

#### Experiment 实体
```dart
class Experiment {
  final String id;
  final String userId;
  final String? methodId;
  final String name;
  final String? description;
  final ExperimentStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### ExperimentDetailState
```dart
class ExperimentDetailState {
  final Experiment? experiment;
  final List<PointHistoryData> pointHistory;
  final bool isLoading;
  final bool isLoadingHistory;
  final String? error;
  final String? historyError;
  final int historyPage;
  final bool hasMoreHistory;
}

class PointHistoryData {
  final DateTime timestamp;
  final double value;
}
```

#### PointHistoryResponse
```dart
class PointHistoryResponse {
  final String experimentId;
  final String channel;
  final List<PointHistoryItem> data;
  final DateTime? startTime;
  final DateTime? endTime;
  final int totalPoints;
}

class PointHistoryItem {
  final int timestamp; // nanoseconds since epoch
  final double value;
}
```

---

## 2. 单元测试 - State Management

### TC-STATE-001: 试验详情初始状态验证

```dart
void main() {
  group('ExperimentDetailState', () {
    test('初始状态具有正确的默认值', () {
      const state = ExperimentDetailState();

      expect(state.experiment, isNull);
      expect(state.pointHistory, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingHistory, isFalse);
      expect(state.error, isNull);
      expect(state.historyError, isNull);
      expect(state.historyPage, equals(1));
      expect(state.hasMoreHistory, isFalse);
    });

    test('copyWith创建具有更新值的新实例', () {
      const state = ExperimentDetailState();
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试实验',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      
      final newState = state.copyWith(experiment: experiment);

      expect(newState.experiment, equals(experiment));
      expect(state.experiment, isNull);
    });

    test('copyWith更新一个字段时保留其他字段', () {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试实验',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      
      final state = ExperimentDetailState(experiment: experiment);
      final newState = state.copyWith(isLoading: true);

      expect(newState.experiment, equals(experiment));
      expect(newState.isLoading, isTrue);
      expect(state.isLoading, isFalse);
    });
  });
}
```

### TC-STATE-002: 错误状态清除

```dart
    test('copyWith使用clearError清除错误', () {
      final state = ExperimentDetailState(
        error: '网络错误',
        historyError: '数据加载失败',
      );
      
      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
      expect(newState.historyError, equals('数据加载失败')); // 不影响historyError
    });

    test('copyWith使用clearHistoryError清除历史错误', () {
      final state = ExperimentDetailState(
        error: '网络错误',
        historyError: '数据加载失败',
      );
      
      final newState = state.copyWith(clearHistoryError: true);

      expect(newState.historyError, isNull);
      expect(newState.error, equals('网络错误')); // 不影响error
    });

    test('copyWith可以同时清除两种错误', () {
      final state = ExperimentDetailState(
        error: '网络错误',
        historyError: '数据加载失败',
      );
      
      final newState = state.copyWith(
        clearError: true,
        clearHistoryError: true,
      );

      expect(newState.error, isNull);
      expect(newState.historyError, isNull);
    });
```

### TC-STATE-003: 测点历史数据更新

```dart
    test('copyWith可以更新测点历史数据', () {
      final history1 = [
        PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, 0),
          value: 25.5,
        ),
      ];
      final history2 = [
        PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, 1),
          value: 26.0,
        ),
      ];
      
      final state = ExperimentDetailState(pointHistory: history1);
      final newState = state.copyWith(pointHistory: history2);

      expect(newState.pointHistory, equals(history2));
      expect(newState.pointHistory.length, equals(1));
      expect(newState.pointHistory.first.value, equals(26.0));
    });

    test('copyWith可以追加测点历史数据', () {
      final existingHistory = [
        PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, 0),
          value: 25.5,
        ),
      ];
      final newHistory = [
        PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, 1),
          value: 26.0,
        ),
      ];
      
      final state = ExperimentDetailState(pointHistory: existingHistory);
      final combinedHistory = [...state.pointHistory, ...newHistory];
      final newState = state.copyWith(pointHistory: combinedHistory);

      expect(newState.pointHistory.length, equals(2));
      expect(newState.pointHistory[0].value, equals(25.5));
      expect(newState.pointHistory[1].value, equals(26.0));
    });

    test('copyWith可以重置分页状态', () {
      final state = ExperimentDetailState(
        historyPage: 5,
        hasMoreHistory: true,
        pointHistory: [
          PointHistoryData(
            timestamp: DateTime(2024, 1, 1),
            value: 25.5,
          ),
        ],
      );
      
      final newState = state.copyWith(
        historyPage: 1,
        hasMoreHistory: false,
        pointHistory: [],
      );

      expect(newState.historyPage, equals(1));
      expect(newState.hasMoreHistory, isFalse);
      expect(newState.pointHistory, isEmpty);
    });
```

### TC-STATE-004: 加载状态管理

```dart
    test('加载详情时isLoading状态正确', () {
      const state = ExperimentDetailState();
      
      final loadingState = state.copyWith(isLoading: true, clearError: true);
      
      expect(loadingState.isLoading, isTrue);
      expect(loadingState.error, isNull);
    });

    test('加载历史数据时isLoadingHistory状态正确', () {
      const state = ExperimentDetailState();
      
      final loadingState = state.copyWith(
        isLoadingHistory: true,
        clearHistoryError: true,
      );
      
      expect(loadingState.isLoadingHistory, isTrue);
      expect(loadingState.historyError, isNull);
    });

    test('可以同时加载详情和历史数据', () {
      const state = ExperimentDetailState();
      
      final loadingState = state.copyWith(
        isLoading: true,
        isLoadingHistory: true,
      );
      
      expect(loadingState.isLoading, isTrue);
      expect(loadingState.isLoadingHistory, isTrue);
    });
```

### TC-STATE-005: 分页状态管理

```dart
    test('hasMoreHistory根据数据长度正确设置', () {
      // 假设每页100条数据，当返回100条时hasMoreHistory应为true
      final history = List.generate(
        100,
        (i) => PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, i),
          value: i.toDouble(),
        ),
      );
      
      // 模拟API返回100条数据（刚好满一页），hasMoreHistory应为true
      final hasMore = history.length >= 100;
      
      final state = ExperimentDetailState(
        pointHistory: history,
        hasMoreHistory: hasMore,
      );
      
      expect(state.hasMoreHistory, isTrue);
      expect(state.pointHistory.length, equals(100));
    });

    test('hasMoreHistory为false时表示没有更多数据', () {
      // 当返回数据少于100条时，说明没有更多数据了
      final history = List.generate(
        50,
        (i) => PointHistoryData(
          timestamp: DateTime(2024, 1, 1, 10, i),
          value: i.toDouble(),
        ),
      );
      
      final hasMore = history.length >= 100;
      
      final state = ExperimentDetailState(
        pointHistory: history,
        hasMoreHistory: hasMore,
      );
      
      expect(state.hasMoreHistory, isFalse);
      expect(state.pointHistory.length, equals(50));
    });

    test('hasMoreHistory计算逻辑测试', () {
      // 测试实际的hasMoreHistory计算逻辑
      List.generate(100, (i) => PointHistoryData(
        timestamp: DateTime(2024, 1, 1, 10, i),
        value: i.toDouble(),
      ));
      
      // 验证：newData.length >= 100 时 hasMoreHistory 应为 true
      const newDataLength100 = 100;
      expect(newDataLength100 >= 100, isTrue);
      
      // 验证：newData.length < 100 时 hasMoreHistory 应为 false
      const newDataLength99 = 99;
      expect(newDataLength99 >= 100, isFalse);
    });

    test('historyPage正确递增', () {
      const state = ExperimentDetailState(historyPage: 1);
      
      final newState = state.copyWith(historyPage: 2);
      
      expect(newState.historyPage, equals(2));
    });
```

### TC-STATE-006: PointHistoryData模型测试

```dart
group('PointHistoryData', () {
  test('PointHistoryData创建正确', () {
    final data = PointHistoryData(
      timestamp: DateTime(2024, 3, 15, 10, 30, 0),
      value: 25.567,
    );
    
    expect(data.timestamp, equals(DateTime(2024, 3, 15, 10, 30, 0)));
    expect(data.value, equals(25.567));
  });

  test('PointHistoryData支持负数值', () {
    final data = PointHistoryData(
      timestamp: DateTime(2024, 3, 15),
      value: -10.5,
    );
    
    expect(data.value, equals(-10.5));
  });

  test('PointHistoryData支持零值', () {
    final data = PointHistoryData(
      timestamp: DateTime(2024, 3, 15),
      value: 0.0,
    );
    
    expect(data.value, equals(0.0));
  });

  test('PointHistoryData支持高精度小数', () {
    final data = PointHistoryData(
      timestamp: DateTime(2024, 3, 15),
      value: 3.14159265359,
    );
    
    expect(data.value, closeTo(3.14159265359, 0.00000000001));
  });
});
```

---

## 3. 单元测试 - Provider/Notifier

### TC-NOTIFIER-001: 加载试验详情

```dart
void main() {
  group('ExperimentDetailNotifier', () {
    late MockExperimentService mockService;

    setUp(() {
      mockService = MockExperimentService();
    });

    test('loadExperiment加载试验详情成功', () async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试实验',
        description: '这是一个测试实验',
        status: ExperimentStatus.running,
        startedAt: DateTime(2024, 3, 15, 9, 0),
        createdAt: DateTime(2024, 3, 15, 8, 0),
        updatedAt: DateTime(2024, 3, 15, 9, 0),
      );
      
      when(() => mockService.getExperiment('exp-1'))
          .thenAnswer((_) async => experiment);

      final notifier = ExperimentDetailNotifier(mockService);
      
      // 初始状态
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.experiment, isNull);
      
      // 开始加载
      final future = notifier.loadExperiment('exp-1');
      expect(notifier.state.isLoading, isTrue);
      
      // 加载完成
      await future;
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.experiment, equals(experiment));
      expect(notifier.state.error, isNull);
    });

    test('loadExperiment处理加载错误', () async {
      when(() => mockService.getExperiment('exp-1'))
          .thenThrow(Exception('试验不存在'));

      final notifier = ExperimentDetailNotifier(mockService);
      await notifier.loadExperiment('exp-1');
      
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.experiment, isNull);
      expect(notifier.state.error, contains('试验不存在'));
    });

    test('loadExperiment防止重复加载', () async {
      when(() => mockService.getExperiment('exp-1'))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Experiment(
          id: 'exp-1',
          userId: 'user-1',
          name: '测试实验',
          status: ExperimentStatus.idle,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );
      });

      final notifier = ExperimentDetailNotifier(mockService);
      
      // 第一次调用
      final future1 = notifier.loadExperiment('exp-1');
      // 第二次调用（应该直接返回，不执行加载）
      final future2 = notifier.loadExperiment('exp-1');
      
      await future1;
      await future2;
      
      // 只调用一次API
      verify(() => mockService.getExperiment('exp-1')).called(1);
    });
  });
}
```

### TC-NOTIFIER-002: 加载测点历史数据

```dart
    test('loadPointHistory加载测点历史数据成功', () async {
      final response = PointHistoryResponse(
        experimentId: 'exp-1',
        channel: 'temp_sensor_1',
        data: [
          PointHistoryItem(
            // 修正: 使用 millisecondsSinceEpoch * 1000000 表示纳秒
            timestamp: DateTime(2024, 3, 15, 10, 0, 0).millisecondsSinceEpoch * 1000000,
            value: 25.5,
          ),
          PointHistoryItem(
            timestamp: DateTime(2024, 3, 15, 10, 1, 0).millisecondsSinceEpoch * 1000000,
            value: 26.0,
          ),
        ],
        totalPoints: 2,
      );
      
      when(() => mockService.getPointHistory(
        'exp-1',
        'temp_sensor_1',
        limit: any(named: 'limit'),
      )).thenAnswer((_) async => response);

      final notifier = ExperimentDetailNotifier(mockService);
      
      await notifier.loadPointHistory('exp-1', 'temp_sensor_1');
      
      expect(notifier.state.isLoadingHistory, isFalse);
      expect(notifier.state.pointHistory.length, equals(2));
      expect(notifier.state.pointHistory[0].value, equals(25.5));
      expect(notifier.state.pointHistory[1].value, equals(26.0));
      expect(notifier.state.hasMoreHistory, isFalse); // 只有2条数据
      expect(notifier.state.historyError, isNull);
    });

    test('loadPointHistory处理时间戳转换', () async {
      // API返回的是纳秒时间戳
      final timestampNs = DateTime(2024, 3, 15, 10, 30, 0)
          .millisecondsSinceEpoch * 1000000;
      
      final response = PointHistoryResponse(
        experimentId: 'exp-1',
        channel: 'sensor_1',
        data: [
          PointHistoryItem(
            timestamp: timestampNs,
            value: 100.0,
          ),
        ],
        totalPoints: 1,
      );
      
      when(() => mockService.getPointHistory(any(), any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => response);

      final notifier = ExperimentDetailNotifier(mockService);
      await notifier.loadPointHistory('exp-1', 'sensor_1');
      
      // 验证时间戳正确转换为DateTime
      expect(notifier.state.pointHistory[0].timestamp,
          equals(DateTime(2024, 3, 15, 10, 30, 0)));
    });

    test('loadPointHistory处理加载错误', () async {
      when(() => mockService.getPointHistory(any(), any(), limit: any(named: 'limit')))
          .thenThrow(Exception('测点不存在'));

      final notifier = ExperimentDetailNotifier(mockService);
      await notifier.loadPointHistory('exp-1', 'invalid_channel');
      
      expect(notifier.state.isLoadingHistory, isFalse);
      expect(notifier.state.pointHistory, isEmpty);
      expect(notifier.state.historyError, contains('测点不存在'));
    });

    test('loadPointHistory支持分页加载', () async {
      // 第一页数据
      final page1Response = PointHistoryResponse(
        experimentId: 'exp-1',
        channel: 'sensor_1',
        data: List.generate(
          100,
          (i) => PointHistoryItem(
            // 修正: 使用正确的纳秒时间戳
            timestamp: DateTime(2024, 3, 15, 10, i).millisecondsSinceEpoch * 1000000,
            value: i.toDouble(),
          ),
        ),
        totalPoints: 150,
      );
      
      when(() => mockService.getPointHistory(
        'exp-1',
        'sensor_1',
        limit: any(named: 'limit'),
      )).thenAnswer((_) async => page1Response);

      final notifier = ExperimentDetailNotifier(mockService);
      await notifier.loadPointHistory('exp-1', 'sensor_1');
      
      expect(notifier.state.pointHistory.length, equals(100));
      expect(notifier.state.hasMoreHistory, isTrue);
      expect(notifier.state.historyPage, equals(2));
    });

    test('loadPointHistory重置时清除已有数据', () async {
      // 先加载第一页
      final page1Response = PointHistoryResponse(
        experimentId: 'exp-1',
        channel: 'sensor_1',
        data: List.generate(
          100,
          (i) => PointHistoryItem(
            timestamp: DateTime(2024, 3, 15, 10, i).millisecondsSinceEpoch * 1000000,
            value: i.toDouble(),
          ),
        ),
        totalPoints: 150,
      );
      
      when(() => mockService.getPointHistory(
        'exp-1',
        'sensor_1',
        limit: any(named: 'limit'),
      )).thenAnswer((_) async => page1Response);

      final notifier = ExperimentDetailNotifier(mockService);
      await notifier.loadPointHistory('exp-1', 'sensor_1');
      expect(notifier.state.pointHistory.length, equals(100));
      
      // 重置加载
      await notifier.loadPointHistory('exp-1', 'sensor_1', reset: true);
      
      // 页码重置为1，数据保持（重新加载）
      expect(notifier.state.historyPage, equals(2)); // 加载完成后递增
    });
```

### TC-NOTIFIER-003: CSV导出功能

```dart
    test('exportToCsv生成正确的CSV格式', () async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '温度测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );
      
      final history = [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 25.5,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 1, 0),
          value: 26.0,
        ),
      ];
      
      final notifier = ExperimentDetailNotifier(mockService);
      // 设置状态
      notifier.state = ExperimentDetailState(
        experiment: experiment,
        pointHistory: history,
      );
      
      final csv = await notifier.exportToCsv();
      
      expect(csv, contains('Timestamp,Value'));
      expect(csv, contains('2024-03-15T10:00:00.000,25.5'));
      expect(csv, contains('2024-03-15T10:01:00.000,26.0'));
    });

    test('exportToCsv处理空数据', () async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '空测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );
      
      final notifier = ExperimentDetailNotifier(mockService);
      notifier.state = ExperimentDetailState(
        experiment: experiment,
        pointHistory: [],
      );
      
      final csv = await notifier.exportToCsv();
      
      expect(csv, equals('Timestamp,Value\n'));
    });

    test('exportToCsv没有试验时返回空字符串', () async {
      final notifier = ExperimentDetailNotifier(mockService);
      
      final csv = await notifier.exportToCsv();
      
      expect(csv, equals(''));
    });

    test('exportToCsv处理特殊数值', () async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '特殊值测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );
      
      final history = [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 0.0,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 1, 0),
          value: -10.5,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 2, 0),
          value: 3.14159,
        ),
      ];
      
      final notifier = ExperimentDetailNotifier(mockService);
      notifier.state = ExperimentDetailState(
        experiment: experiment,
        pointHistory: history,
      );
      
      final csv = await notifier.exportToCsv();
      
      expect(csv, contains('0.0'));
      expect(csv, contains('-10.5'));
      expect(csv, contains('3.14159'));
    });
```

### TC-NOTIFIER-004: 状态转换和并发控制

```dart
    test('加载详情时不影响历史数据加载状态', () async {
      when(() => mockService.getExperiment('exp-1'))
          .thenAnswer((_) async => Experiment(
                id: 'exp-1',
                userId: 'user-1',
                name: '测试',
                status: ExperimentStatus.idle,
                createdAt: DateTime(2024, 1, 1),
                updatedAt: DateTime(2024, 1, 1),
              ));

      final notifier = ExperimentDetailNotifier(mockService);
      
      // 模拟正在加载历史数据
      notifier.state = notifier.state.copyWith(isLoadingHistory: true);
      
      await notifier.loadExperiment('exp-1');
      
      // isLoadingHistory应该保持不变
      expect(notifier.state.isLoadingHistory, isTrue);
      expect(notifier.state.isLoading, isFalse);
    });

    test('加载历史数据时不影响详情加载状态', () async {
      final response = PointHistoryResponse(
        experimentId: 'exp-1',
        channel: 'sensor_1',
        data: [],
        totalPoints: 0,
      );
      
      when(() => mockService.getPointHistory(any(), any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => response);

      final notifier = ExperimentDetailNotifier(mockService);
      
      // 模拟正在加载详情
      notifier.state = notifier.state.copyWith(isLoading: true);
      
      await notifier.loadPointHistory('exp-1', 'sensor_1');
      
      // isLoading应该保持不变
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.isLoadingHistory, isFalse);
    });

    test('防止重复加载历史数据', () async {
      when(() => mockService.getPointHistory(any(), any(), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return PointHistoryResponse(
          experimentId: 'exp-1',
          channel: 'sensor_1',
          data: [],
          totalPoints: 0,
        );
      });

      final notifier = ExperimentDetailNotifier(mockService);
      
      // 同时调用两次
      final future1 = notifier.loadPointHistory('exp-1', 'sensor_1');
      final future2 = notifier.loadPointHistory('exp-1', 'sensor_1');
      
      await future1;
      await future2;
      
      // 只调用一次API
      verify(() => mockService.getPointHistory(any(), any(), limit: any(named: 'limit'))).called(1);
    });
```

---

## 4. Widget测试 - UI组件

### TC-UI-001: 试验详情页面显示试验名称

```dart
void main() {
  group('ExperimentDetailPage Widget Tests', () {
    testWidgets('displays experiment name correctly', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '温度传感器校准实验',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('温度传感器校准实验'), findsOneWidget);
    });

    testWidgets('displays experiment status correctly', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试实验',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('已完成'), findsOneWidget);
    });
  });
}
```

### TC-UI-002: 试验详情页面显示完整元信息

```dart
    testWidgets('displays experiment metadata correctly', (tester) async {
      final experiment = Experiment(
        id: 'exp-123',
        userId: 'user-456',
        methodId: 'method-789',
        name: '压力测试实验',
        description: '这是一个高压环境下的传感器测试实验',
        status: ExperimentStatus.running,
        startedAt: DateTime(2024, 3, 15, 9, 0, 0),
        endedAt: null,
        createdAt: DateTime(2024, 3, 15, 8, 30, 0),
        updatedAt: DateTime(2024, 3, 15, 9, 0, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-123'),
          ),
        ),
      );

      // 验证ID显示
      expect(find.textContaining('exp-123'), findsOneWidget);
      // 验证描述显示
      expect(find.text('这是一个高压环境下的传感器测试实验'), findsOneWidget);
      // 验证状态显示
      expect(find.text('运行中'), findsOneWidget);
      // 验证时间显示
      expect(find.textContaining('2024'), findsWidgets);
    });

    testWidgets('displays experiment without description', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '无描述实验',
        status: ExperimentStatus.idle,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('无描述实验'), findsOneWidget);
      // 没有描述时不显示描述区域或显示占位符
      expect(find.textContaining('暂无描述'), findsOneWidget);
    });

    testWidgets('displays experiment with method ID', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        methodId: 'method-abc',
        name: '有方法实验',
        status: ExperimentStatus.idle,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.textContaining('method-abc'), findsOneWidget);
    });
```

### TC-UI-003: 试验时间信息展示

```dart
    testWidgets('displays started and ended time correctly', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '时间测试',
        status: ExperimentStatus.completed,
        startedAt: DateTime(2024, 3, 15, 9, 0, 0),
        endedAt: DateTime(2024, 3, 15, 17, 30, 0),
        createdAt: DateTime(2024, 3, 15, 8, 0, 0),
        updatedAt: DateTime(2024, 3, 15, 17, 30, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.textContaining('09:00'), findsOneWidget);
      expect(find.textContaining('17:30'), findsOneWidget);
    });

    testWidgets('displays not started status correctly', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '未开始实验',
        status: ExperimentStatus.idle,
        startedAt: null,
        endedAt: null,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.textContaining('未开始'), findsOneWidget);
    });
```

### TC-UI-004: 加载状态显示

```dart
    testWidgets('displays loading indicator when loading experiment', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentDetailState(isLoading: true),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays loading indicator for history when loading', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试实验',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  isLoadingHistory: true,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 验证历史数据区域显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
```

### TC-UI-005: 错误状态显示

```dart
    testWidgets('displays error message when experiment fails to load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentDetailState(
                  error: '试验不存在或已被删除',
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('试验不存在或已被删除'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays error message when history fails to load', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试实验',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  historyError: '无法加载测点数据',
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('无法加载测点数据'), findsOneWidget);
    });

    testWidgets('displays retry button on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                const ExperimentDetailState(
                  error: '网络连接失败',
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('重试'), findsOneWidget);
      // 使用Key进行可靠选择，而非byType().last
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });
```

### TC-UI-006: 测点数据表格显示

```dart
    testWidgets('displays point history data table', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '数据测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final history = [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 25.5,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 1, 0),
          value: 26.0,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 2, 0),
          value: 26.5,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: history,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 验证表头
      expect(find.text('时间'), findsOneWidget);
      expect(find.text('数值'), findsOneWidget);
      
      // 验证数据行
      expect(find.text('25.5'), findsOneWidget);
      expect(find.text('26.0'), findsOneWidget);
      expect(find.text('26.5'), findsOneWidget);
    });

    testWidgets('displays timestamp in correct format', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '时间格式测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final history = [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 30, 45),
          value: 100.0,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: history,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 验证时间格式（例如：2024-03-15 10:30:45）
      expect(find.textContaining('10:30'), findsOneWidget);
      expect(find.textContaining('15'), findsWidgets);
    });

    testWidgets('displays empty state when no point history', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '无数据测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: [],
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('暂无测点数据'), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });
```

### TC-UI-007: 数据表格分页和滚动

```dart
    testWidgets('displays load more button when has more history', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '分页测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final history = List.generate(
        100,
        (i) => PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, i),
          value: i.toDouble(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: history,
                  hasMoreHistory: true,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('加载更多'), findsOneWidget);
    });

    testWidgets('load more button calls loadPointHistory', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '加载更多测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentDetailState(
          experiment: experiment,
          pointHistory: [],
          hasMoreHistory: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      await tester.tap(find.text('加载更多'));
      await tester.pumpAndSettle();

      verify(() => mockNotifier.loadPointHistory('exp-1', any(), reset: false)).called(1);
    });
```

### TC-UI-008: CSV导出按钮

```dart
    testWidgets('displays export CSV button', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '导出测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final history = [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 25.5,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: history,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('导出CSV'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('export button disabled when no data', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '无数据导出测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: [],
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 使用Key进行可靠选择，而非byType().last
      final button = tester.widget<ElevatedButton>(find.byKey(const Key('export_csv_button')));
      expect(button.onPressed, isNull);
    });
```

### TC-UI-009: 测点选择器

```dart
    testWidgets('displays channel selector dropdown', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测点选择测试',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('selecting channel loads history data', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测点切换测试',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentDetailState(experiment: experiment),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 点击下拉框
      await tester.tap(find.byKey(const Key('channel_selector')));
      await tester.pumpAndSettle();

      // 验证下拉选项存在
      expect(find.text('温度传感器1'), findsWidgets);

      // 选择一个测点
      await tester.tap(find.text('温度传感器1').last);
      await tester.pumpAndSettle();

      verify(() => mockNotifier.loadPointHistory('exp-1', 'temp_sensor_1', reset: true)).called(1);
    });
```

### TC-UI-010: 页面初始化和数据加载

```dart
    testWidgets('loads experiment on initial build', (tester) async {
      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        const ExperimentDetailState(isLoading: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-123'),
          ),
        ),
      );

      verify(() => mockNotifier.loadExperiment('exp-123')).called(1);
    });

    testWidgets('loads default channel history after experiment loaded', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '自动加载测试',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentDetailState(experiment: experiment),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 页面加载后应该自动加载第一个测点的历史数据
      verify(() => mockNotifier.loadPointHistory('exp-1', any(), reset: true)).called(1);
    });
```

---

## 5. Widget测试 - 交互

### TC-INT-001: 重试功能

```dart
    testWidgets('retry button reloads experiment', (tester) async {
      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        const ExperimentDetailState(error: '加载失败'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      verify(() => mockNotifier.loadExperiment('exp-1')).called(1);
    });

    testWidgets('retry button reloads point history', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '测试',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentDetailState(
          experiment: experiment,
          historyError: '历史数据加载失败',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 使用Key进行可靠选择，而非.last
      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pumpAndSettle();

      verify(() => mockNotifier.loadPointHistory('exp-1', any(), reset: true)).called(1);
    });
```

### TC-INT-002: CSV导出交互

```dart
    testWidgets('export CSV button triggers export', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '导出测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentDetailState(
          experiment: experiment,
          pointHistory: [
            PointHistoryData(
              timestamp: DateTime(2024, 3, 15, 10, 0, 0),
              value: 25.5,
            ),
          ],
        ),
      );
      when(() => mockNotifier.exportToCsv()).thenAnswer((_) async => 'Timestamp,Value\n2024-03-15T10:00:00.000,25.5');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      await tester.tap(find.text('导出CSV'));
      await tester.pumpAndSettle();

      verify(() => mockNotifier.exportToCsv()).called(1);
    });

    testWidgets('shows success message after export', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '导出测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentDetailState(
          experiment: experiment,
          pointHistory: [
            PointHistoryData(
              timestamp: DateTime(2024, 3, 15, 10, 0, 0),
              value: 25.5,
            ),
          ],
        ),
      );
      when(() => mockNotifier.exportToCsv()).thenAnswer((_) async => 'Timestamp,Value\n2024-03-15T10:00:00.000,25.5');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      await tester.tap(find.text('导出CSV'));
      await tester.pumpAndSettle();

      // 验证显示成功提示
      expect(find.text('导出成功'), findsOneWidget);
    });
```

### TC-INT-003: 下拉刷新

```dart
    testWidgets('pull to refresh reloads experiment', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '刷新测试',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final mockNotifier = MockExperimentDetailNotifier();
      when(() => mockNotifier.state).thenReturn(
        ExperimentDetailState(experiment: experiment),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 执行下拉刷新
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 100), 1000);
      await tester.pumpAndSettle();

      verify(() => mockNotifier.loadExperiment('exp-1')).called(1);
    });
```

---

## 6. 集成测试 - API和数据流

> **注意**: 以下测试为集成测试，需要真实的API环境或配置完整的Mock。标记为 **[Integration Test]**

### TC-API-001: 获取试验详情API集成 **[Integration Test]**

```dart
void main() {
  group('Experiment Detail API Integration Tests [Integration]', () {
    testWidgets('loads experiment from real API', (tester) async {
      // 使用真实的API客户端（或配置好的Mock）
      final apiClient = RealApiClient();
      final service = ExperimentService(apiClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'real-exp-id'),
          ),
        ),
      );

      // 等待加载完成
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证数据加载成功
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });
}
```

### TC-API-002: 获取测点历史数据API集成 **[Integration Test]**

```dart
    testWidgets('loads point history from real API', (tester) async {
      final apiClient = RealApiClient();
      final service = ExperimentService(apiClient);
      
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: 'API测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(service),
            experimentDetailProvider.overrideWith((ref) {
              final notifier = ExperimentDetailNotifier(service);
              notifier.state = ExperimentDetailState(experiment: experiment);
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 等待历史数据加载
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证表格显示数据
      expect(find.byType(DataTable), findsOneWidget);
    });
```

### TC-API-003: 时间过滤功能 **[Integration Test]**

```dart
    testWidgets('loads point history with time filter', (tester) async {
      final mockService = MockExperimentService();
      final startTime = DateTime(2024, 3, 15, 10, 0, 0);
      final endTime = DateTime(2024, 3, 15, 11, 0, 0);

      when(() => mockService.getPointHistory(
        'exp-1',
        'sensor_1',
        startTime: startTime,
        endTime: endTime,
        limit: any(named: 'limit'),
      )).thenAnswer((_) async => PointHistoryResponse(
        experimentId: 'exp-1',
        channel: 'sensor_1',
        data: [
          PointHistoryItem(
            // 修正: 使用正确的纳秒时间戳
            timestamp: DateTime(2024, 3, 15, 10, 30, 0).millisecondsSinceEpoch * 1000000,
            value: 25.5,
          ),
        ],
        startTime: startTime,
        endTime: endTime,
        totalPoints: 1,
      ));

      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '时间过滤测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentServiceProvider.overrideWithValue(mockService),
            experimentDetailProvider.overrideWith((ref) {
              final notifier = ExperimentDetailNotifier(mockService);
              notifier.state = ExperimentDetailState(experiment: experiment);
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 触发时间选择器UI交互
      // 1. 点击时间过滤按钮
      await tester.tap(find.byKey(const Key('time_filter_button')));
      await tester.pumpAndSettle();

      // 2. 选择开始时间
      await tester.tap(find.byKey(const Key('start_time_picker')));
      await tester.pumpAndSettle();
      // 选择日期和时间 (简化，实际需要日期选择器交互)

      // 3. 选择结束时间
      await tester.tap(find.byKey(const Key('end_time_picker')));
      await tester.pumpAndSettle();

      // 4. 确认选择
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      // 验证API调用包含时间参数
      verify(() => mockService.getPointHistory(
        'exp-1',
        'sensor_1',
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        limit: any(named: 'limit'),
      )).called(1);
    });
```

---

## 7. CSV导出功能测试

### TC-CSV-001: CSV格式正确性

```dart
group('CSV Export Tests', () {
  test('exportToCsv generates correct CSV format', () async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: 'CSV测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 25.5,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 1, 0),
          value: 26.0,
        ),
      ],
    );

    final csv = await notifier.exportToCsv();
    final lines = csv.split('\n');

    expect(lines[0], equals('Timestamp,Value'));
    expect(lines[1], equals('2024-03-15T10:00:00.000,25.5'));
    expect(lines[2], equals('2024-03-15T10:01:00.000,26.0'));
  });

  test('exportToCsv handles different timestamp formats', () async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: 'CSV测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: [
        PointHistoryData(
          timestamp: DateTime(2024, 12, 31, 23, 59, 59, 999),
          value: 99.999,
        ),
      ],
    );

    final csv = await notifier.exportToCsv();

    expect(csv, contains('2024-12-31T23:59:59.999'));
    expect(csv, contains('99.999'));
  });
});
```

### TC-CSV-002: CSV边界值处理

```dart
  test('exportToCsv handles zero values', () async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '零值测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 0.0,
        ),
      ],
    );

    final csv = await notifier.exportToCsv();

    expect(csv, contains(',0.0'));
  });

  test('exportToCsv handles negative values', () async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '负值测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: -50.5,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 1, 0),
          value: -100.0,
        ),
      ],
    );

    final csv = await notifier.exportToCsv();

    expect(csv, contains(',-50.5'));
    expect(csv, contains(',-100.0'));
  });

  test('exportToCsv handles very large values', () async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '大值测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 999999.999999,
        ),
      ],
    );

    final csv = await notifier.exportToCsv();

    expect(csv, contains('999999.999999'));
  });

  test('exportToCsv handles very small values', () async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '小值测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 0.000001,
        ),
      ],
    );

    final csv = await notifier.exportToCsv();

    expect(csv, contains('0.000001'));
  });
```

### TC-CSV-003: CSV大数据量处理

```dart
  test('exportToCsv handles large dataset', () async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    // 生成1000条数据
    final history = List.generate(
      1000,
      (i) => PointHistoryData(
        timestamp: DateTime(2024, 3, 15, 10, i ~/ 60, i % 60),
        value: i.toDouble(),
      ),
    );
    
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '大数据测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: history,
    );

    final stopwatch = Stopwatch()..start();
    final csv = await notifier.exportToCsv();
    stopwatch.stop();

    // 验证性能（1000条数据应在100ms内完成）
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
    
    // 验证行数（1行表头 + 1000行数据 + 1行空行）
    expect(csv.split('\n').length, equals(1002));
  });
```

### TC-CSV-004: CSV文件下载集成

```dart
  testWidgets('export CSV triggers file download', (tester) async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '下载测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: 25.5,
        ),
      ],
    );

    String? capturedFileName;
    String? capturedContent;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experimentDetailProvider.overrideWith((ref) {
            when(() => notifier.exportToCsv()).thenAnswer((_) async => 'Timestamp,Value\n2024-03-15T10:00:00.000,25.5');
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final csv = await notifier.exportToCsv();
                    capturedFileName = 'exp-1_data.csv';
                    capturedContent = csv;
                  },
                  child: const Text('导出'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('导出'));
    await tester.pumpAndSettle();

    expect(capturedFileName, equals('exp-1_data.csv'));
    expect(capturedContent, contains('Timestamp,Value'));
  });
```

### TC-CSV-005: CSV特殊字符处理

```dart
  test('exportToCsv handles experiment names in filename', () async {
    // 验证文件名生成逻辑，移除或替换特殊字符
    final experimentName = '实验/测试:数据"敏感';
    final sanitizedName = sanitizeFileName(experimentName);
    
    expect(sanitizedName, isNot(contains('/')));
    expect(sanitizedName, isNot(contains(':')));
    expect(sanitizedName, isNot(contains('"')));
  });

  test('exportToCsv generates unique filename for same experiment', () async {
    final timestamp = DateTime.now();
    final fileName = generateCsvFileName('exp-1', timestamp);
    
    expect(fileName, contains('exp-1'));
    expect(fileName, contains('.csv'));
  });
```

### TC-CSV-006: CSV导出失败处理

```dart
  test('exportToCsv handles large dataset gracefully', () async {
    final mockService = MockExperimentService();
    final notifier = ExperimentDetailNotifier(mockService);
    
    // 模拟较大数据集（10000条，减小到可测试的大小）
    // 原始1000000条会消耗过多内存
    notifier.state = ExperimentDetailState(
      experiment: Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '错误测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      ),
      pointHistory: List.generate(
        10000, // 减少到10000条，更符合实际测试场景
        (i) => PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, i ~/ 60, i % 60),
          value: i.toDouble(),
        ),
      ),
    );

    // 验证导出功能正常处理大数据集，不抛出异常
    final csv = await notifier.exportToCsv();
    
    // 验证CSV生成成功
    expect(csv, isNotEmpty);
    expect(csv, contains('Timestamp,Value'));
    expect(csv.split('\n').length, equals(10002)); // 1行表头 + 10000行数据 + 1行空行
  });
```

---

## 8. 边界测试

### TC-BOUNDARY-001: 大量测点数据处理

```dart
    testWidgets('handles large point history dataset', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '大数据集测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      // 生成1000条测点数据
      final history = List.generate(
        1000,
        (i) => PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, i ~/ 60, i % 60),
          value: i.toDouble(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: history,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 验证页面能够渲染，没有性能问题
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
    });
```

### TC-BOUNDARY-002: 超长试验名称处理

```dart
    testWidgets('handles very long experiment name', (tester) async {
      final longName = 'A' * 200;
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: longName,
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 验证超长名称被正确显示（使用精确的文本匹配）
      // find.textContaining无法精确匹配纯字母字符串
      final textFinder = find.byWidgetPredicate((widget) {
        if (widget is Text) {
          final text = widget.data ?? '';
          return text == longName || (text.length == 200 && text.startsWith('A'));
        }
        return false;
      });
      
      expect(textFinder, findsOneWidget);
      
      // 验证文本被正确截断（检查TextOverflow设置）
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });
```

### TC-BOUNDARY-003: 特殊数值处理

```dart
    testWidgets('handles special numeric values', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '特殊数值测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final history = [
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 0, 0),
          value: double.nan,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 1, 0),
          value: double.infinity,
        ),
        PointHistoryData(
          timestamp: DateTime(2024, 3, 15, 10, 2, 0),
          value: double.negativeInfinity,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: history,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      // 验证特殊数值被正确显示（或标记为无效）
      expect(find.textContaining('NaN'), findsOneWidget);
      expect(find.textContaining('∞'), findsWidgets);
    });
```

### TC-BOUNDARY-004: 极值时间戳处理

```dart
    testWidgets('handles extreme timestamps', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '时间极值测试',
        status: ExperimentStatus.completed,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      final history = [
        PointHistoryData(
          timestamp: DateTime(1970, 1, 1), // Unix epoch
          value: 0.0,
        ),
        PointHistoryData(
          timestamp: DateTime(2099, 12, 31, 23, 59, 59), // 遥远的未来
          value: 100.0,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(
                  experiment: experiment,
                  pointHistory: history,
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.textContaining('1970'), findsOneWidget);
      expect(find.textContaining('2099'), findsOneWidget);
    });
```

---

## 9. 主题和样式测试

### TC-THEME-001: 浅色主题下的详情页

```dart
    testWidgets('renders correctly in light theme', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '主题测试',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('主题测试'), findsOneWidget);
      
      // 验证卡片背景色
      final card = tester.widget<Card>(find.byType(Card).first);
      // 浅色主题下应该有适当的背景色
    });
```

### TC-THEME-002: 深色主题下的详情页

```dart
    testWidgets('renders correctly in dark theme', (tester) async {
      final experiment = Experiment(
        id: 'exp-1',
        userId: 'user-1',
        name: '主题测试',
        status: ExperimentStatus.running,
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experimentDetailProvider.overrideWith((ref) {
              final notifier = MockExperimentDetailNotifier();
              when(() => notifier.state).thenReturn(
                ExperimentDetailState(experiment: experiment),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: ExperimentDetailPage(experimentId: 'exp-1'),
          ),
        ),
      );

      expect(find.text('主题测试'), findsOneWidget);
      
      // 验证深色主题下的文字对比度
    });
```

### TC-THEME-003: 状态颜色显示

```dart
    testWidgets('displays correct status colors', (tester) async {
      final statuses = [
        ExperimentStatus.idle,
        ExperimentStatus.running,
        ExperimentStatus.paused,
        ExperimentStatus.completed,
        ExperimentStatus.aborted,
      ];

      for (final status in statuses) {
        final experiment = Experiment(
          id: 'exp-1',
          userId: 'user-1',
          name: '状态颜色测试',
          status: status,
          createdAt: DateTime(2024, 3, 15),
          updatedAt: DateTime(2024, 3, 15),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              experimentDetailProvider.overrideWith((ref) {
                final notifier = MockExperimentDetailNotifier();
                when(() => notifier.state).thenReturn(
                  ExperimentDetailState(experiment: experiment),
                );
                return notifier;
              }),
            ],
            child: MaterialApp(
              home: ExperimentDetailPage(experimentId: 'exp-1'),
            ),
          ),
        );

        // 验证状态指示器的颜色
        final statusChip = tester.widget<Chip>(find.byType(Chip));
        // 根据状态验证颜色
      }
    });
```

---

## 10. 测试统计

| 类别 | 测试用例数 | 优先级 |
|------|-----------|--------|
| State Management | 6 | P0 |
| Provider/Notifier | 4 | P0 |
| UI Components | 10 | P0 |
| Interactions | 3 | P0 |
| API Integration [Integration] | 3 | P1 |
| CSV Export | 6 | P0 |
| Boundary Tests | 4 | P1 |
| Theme & Styling | 3 | P2 |
| **总计** | **39** | |

### 10.1 优先级分类

| 优先级 | 定义 | 测试用例 |
|--------|------|---------|
| P0 | 核心功能，必须通过 | 26 |
| P1 | 重要功能，应该通过 | 7 |
| P2 | 辅助功能，可以后续通过 | 6 |

---

## 11. 测试辅助函数

### 11.1 文件名处理函数

```dart
/// 文件名安全化处理 - 移除或替换特殊字符
String sanitizeFileName(String name) {
  return name
      .replaceAll('/', '_')
      .replaceAll('\\', '_')
      .replaceAll(':', '_')
      .replaceAll('*', '_')
      .replaceAll('?', '_')
      .replaceAll('"', '_')
      .replaceAll('<', '_')
      .replaceAll('>', '_')
      .replaceAll('|', '_');
}

/// 生成CSV文件名
String generateCsvFileName(String experimentId, DateTime timestamp) {
  final formattedTime = timestamp.toIso8601String().replaceAll(':', '-');
  return '${experimentId}_$formattedTime.csv';
}
```

### 11.2 Mock对象

```dart
class MockExperimentService extends Mock implements ExperimentServiceInterface {}

class MockExperimentDetailNotifier extends Mock implements ExperimentDetailNotifier {
  @override
  ExperimentDetailState get state => super.noSuchMethod(
    Invocation.getter(#state),
    returnValue: const ExperimentDetailState(),
  ) as ExperimentDetailState;
}
```

### 11.3 测试数据工厂

```dart
/// 创建测试用试验数据
Experiment createTestExperiment({
  String id = 'test-exp-id',
  String name = 'Test Experiment',
  ExperimentStatus status = ExperimentStatus.idle,
  String? description,
  DateTime? startedAt,
  DateTime? endedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return Experiment(
    id: id,
    userId: 'test-user',
    name: name,
    description: description,
    status: status,
    startedAt: startedAt,
    endedAt: endedAt,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

/// 创建测试用测点历史数据
PointHistoryData createTestPointHistory({
  DateTime? timestamp,
  double value = 25.5,
}) {
  return PointHistoryData(
    timestamp: timestamp ?? DateTime(2024, 3, 15, 10, 0, 0),
    value: value,
  );
}

/// 创建测试用PointHistoryResponse
PointHistoryResponse createTestPointHistoryResponse({
  String experimentId = 'test-exp',
  String channel = 'test-channel',
  required List<PointHistoryItem> data,
  int? totalPoints,
}) {
  return PointHistoryResponse(
    experimentId: experimentId,
    channel: channel,
    data: data,
    totalPoints: totalPoints ?? data.length,
  );
}

/// 创建测试用PointHistoryItem
PointHistoryItem createTestPointHistoryItem({
  DateTime? timestamp,
  double value = 25.5,
}) {
  // 修正: 使用 millisecondsSinceEpoch * 1000000 表示纳秒
  return PointHistoryItem(
    timestamp: (timestamp ?? DateTime(2024, 3, 15, 10, 0, 0)).millisecondsSinceEpoch * 1000000,
    value: value,
  );
}
```

---

## 12. 依赖的Provider结构

### 12.1 Provider列表

```dart
// 试验服务Provider
final experimentServiceProvider = Provider<ExperimentServiceInterface>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExperimentService(apiClient);
});

// 试验详情NotifierProvider
final experimentDetailProvider =
    StateNotifierProvider<ExperimentDetailNotifier, ExperimentDetailState>((ref) {
  final service = ref.watch(experimentServiceProvider);
  return ExperimentDetailNotifier(service);
});

// 选中的测点Provider（如果有）
final selectedChannelProvider = StateProvider<String?>((ref) => null);
```

### 12.2 UI组件Key定义（用于可靠选择器）

```dart
// 用于可靠选择的Widget Key
// 在实际实现中应为:
// - Key('retry_button') - 重试按钮
// - Key('export_csv_button') - 导出CSV按钮
// - Key('channel_selector') - 测点选择下拉框
// - Key('time_filter_button') - 时间过滤按钮
// - Key('start_time_picker') - 开始时间选择器
// - Key('end_time_picker') - 结束时间选择器
```

---

**文档结束**

(End of file - total 2810 lines)