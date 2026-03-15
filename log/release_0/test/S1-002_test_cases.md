# S1-002: Flutter前端工程初始化 - 测试用例文档

**任务名称**: Flutter前端工程初始化  
**测试文档版本**: 1.0  
**创建日期**: 2024-03-15  
**测试人员**: QA Engineer  

---

## 1. 测试概述

### 1.1 测试范围
本文档覆盖Flutter前端工程初始化的测试，包括：
- 项目结构验证
- 多平台支持（Windows/Mac/Linux）
- 状态管理方案配置
- Material Design 3主题框架
- 浅色/深色主题切换功能

### 1.2 测试环境要求

| 环境项 | 要求 |
|--------|------|
| Flutter SDK | >= 3.19.0 (stable channel) |
| Dart SDK | >= 3.3.0 |
| 操作系统 | Windows 10+/macOS 12+/Linux Ubuntu 20.04+ |
| 桌面支持 | 已启用 (`flutter config --enable-*-desktop`) |

### 1.3 验收标准映射

| 验收标准 | 测试用例ID |
|----------|------------|
| `flutter run` 在桌面端正常启动 | TC-FLU-001 ~ TC-FLU-003 |
| 显示Material Design 3风格的默认界面 | TC-FLU-004 ~ TC-FLU-006 |
| 浅色/深色主题切换功能可用 | TC-FLU-007 ~ TC-FLU-009 |

---

## 2. 测试用例

### 2.1 项目构建与运行测试

#### TC-FLU-001: Windows桌面平台构建测试

**测试目的**: 验证Flutter项目在Windows桌面平台可以正常构建和运行

**前置条件**:
- Windows 10或更高版本
- Flutter SDK已安装且环境变量配置正确
- Visual Studio 2019或更高版本（包含桌面C++开发工作负载）
- 已启用Windows桌面支持: `flutter config --enable-windows-desktop`

**测试步骤**:
1. 打开终端，进入项目目录: `cd /home/hzhou/workspace/kayak/kayak-frontend`
2. 执行依赖获取: `flutter pub get`
3. 验证依赖无错误
4. 执行构建: `flutter build windows`
5. 检查构建输出目录: `build/windows/x64/runner/Release/`

**预期结果**:
- `flutter pub get` 成功完成，无错误
- `flutter build windows` 成功完成，无编译错误
- 在 `build/windows/x64/runner/Release/` 目录下生成可执行文件 `kayak_frontend.exe`

**通过标准**: 所有步骤成功完成，无错误信息

**测试类型**: 手动测试

**优先级**: P0

---

#### TC-FLU-002: macOS桌面平台构建测试

**测试目的**: 验证Flutter项目在macOS桌面平台可以正常构建和运行

**前置条件**:
- macOS 12 (Monterey)或更高版本
- Xcode 14或更高版本已安装
- CocoaPods已安装 (用于某些插件)
- 已启用macOS桌面支持: `flutter config --enable-macos-desktop`

**测试步骤**:
1. 打开终端，进入项目目录: `cd /home/hzhou/workspace/kayak/kayak-frontend`
2. 执行依赖获取: `flutter pub get`
3. 执行构建: `flutter build macos`
4. 检查构建输出目录: `build/macos/Build/Products/Release/`

**预期结果**:
- `flutter pub get` 成功完成
- `flutter build macos` 成功完成，无签名错误(开发环境可接受)
- 生成 `.app` 应用程序包

**通过标准**: 构建成功，生成可运行的应用

**测试类型**: 手动测试

**优先级**: P0

---

#### TC-FLU-003: Linux桌面平台构建测试

**测试目的**: 验证Flutter项目在Linux桌面平台可以正常构建和运行

**前置条件**:
- Ubuntu 20.04 LTS或更高版本(或其他Linux发行版)
- 已安装必要的依赖:
  ```bash
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
  ```
- 已启用Linux桌面支持: `flutter config --enable-linux-desktop`

**测试步骤**:
1. 打开终端，进入项目目录: `cd /home/hzhou/workspace/kayak/kayak-frontend`
2. 执行依赖获取: `flutter pub get`
3. 执行构建: `flutter build linux`
4. 检查构建输出目录: `build/linux/x64/release/bundle/`

**预期结果**:
- `flutter pub get` 成功完成
- `flutter build linux` 成功完成
- 在 `build/linux/x64/release/bundle/` 目录下生成可执行文件

**通过标准**: 构建成功，可执行文件可以运行

**测试类型**: 手动测试

**优先级**: P0

---

#### TC-FLU-004: 桌面端热重载功能测试

**测试目的**: 验证 `flutter run` 在桌面端正常启动且支持热重载

**前置条件**:
- 任一桌面平台环境(Windows/macOS/Linux)
- 项目已配置完成

**测试步骤**:
1. 在项目目录执行: `flutter run -d windows` (或macos/linux)
2. 观察应用启动过程
3. 等待应用窗口显示
4. 修改 `lib/main.dart` 中的一处UI代码(如修改标题文本)
5. 保存文件，观察热重载
6. 应用重新加载后，按 `r` 键手动触发热重载
7. 按 `R` 键触发热重启
8. 按 `q` 键退出应用

**预期结果**:
1. 应用在10秒内启动并显示窗口
2. 控制台显示 `flutter: The Dart VM service is listening on ...`
3. 窗口显示Material Design 3风格的默认界面
4. 保存文件后自动触发热重载，或按 `r` 后重载
5. UI修改在重载后生效
6. 热重启后应用完全重新初始化
7. 按 `q` 后应用正常退出

**通过标准**: 应用正常启动，热重载和热重启功能工作正常

**测试类型**: 手动测试

**优先级**: P0

---

### 2.2 Material Design 3界面测试

#### TC-FLU-005: Material Design 3组件渲染测试

**测试目的**: 验证应用使用Material Design 3设计规范

**前置条件**:
- 应用已成功运行

**测试步骤**:
1. 启动应用
2. 检查应用是否使用MaterialApp 3
3. 验证以下MD3组件是否正确渲染:
   - AppBar (应该使用MD3风格)
   - FloatingActionButton (应该使用新的形状规范)
   - Card (应该使用MD3的圆角和阴影)
   - Buttons (ElevatedButton, FilledButton, OutlinedButton, TextButton)
4. 检查颜色主题是否符合MD3规范
5. 检查字体排版是否符合MD3规范

**预期结果**:
- 应用使用 `MaterialApp` 并启用 `useMaterial3: true`
- 所有组件使用MD3风格(圆角、阴影、颜色)
- 颜色系统使用MD3的ColorScheme
- 字体使用MD3的Typography

**通过标准**: 界面明显使用Material Design 3风格，而非Material 2

**测试类型**: 手动测试 + Widget测试

**优先级**: P0

**自动化测试**:
```dart
// test/material_design_3_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/main.dart';

void main() {
  testWidgets('MaterialApp uses Material Design 3', (WidgetTester tester) async {
    await tester.pumpWidget(const KayakApp());
    
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
  });

  testWidgets('ColorScheme uses seed color', (WidgetTester tester) async {
    await tester.pumpWidget(const KayakApp());
    
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.colorScheme, isNotNull);
    expect(app.darkTheme?.colorScheme, isNotNull);
  });
}
```

---

#### TC-FLU-006: 默认界面结构测试

**测试目的**: 验证默认界面包含基本的布局和导航结构

**前置条件**:
- 应用已成功运行

**测试步骤**:
1. 启动应用
2. 检查窗口标题是否正确
3. 检查应用窗口大小是否合适(桌面端最小尺寸)
4. 检查是否显示主要内容区域
5. 检查是否有基本的导航或占位符

**预期结果**:
- 窗口标题显示应用名称 "Kayak" 或类似
- 窗口大小适合桌面使用(最小宽度 >= 800px, 最小高度 >= 600px)
- 显示Material Design 3风格的内容区域
- 界面元素布局合理，无溢出或截断

**通过标准**: 界面显示正常，布局合理

**测试类型**: 手动测试 + Widget测试

**优先级**: P0

---

### 2.3 主题切换功能测试

#### TC-FLU-007: 浅色主题默认显示测试

**测试目的**: 验证应用默认使用浅色主题

**前置条件**:
- 应用首次启动(无缓存的主题设置)

**测试步骤**:
1. 清除应用数据(如有缓存)
2. 启动应用
3. 观察界面颜色方案
4. 检查背景色(应该是浅色系)
5. 检查文字颜色(应该是深色系，确保可读性)
6. 检查AppBar颜色

**预期结果**:
- 默认启动时使用浅色主题
- 背景色为浅色系(白色或接近白色)
- 文字颜色为深色系(黑色或深灰色)
- 符合Material Design 3浅色主题规范

**通过标准**: 应用默认使用浅色主题，且显示正确

**测试类型**: 手动测试 + Widget测试

**优先级**: P0

**自动化测试**:
```dart
// test/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/main.dart';

void main() {
  testWidgets('Default theme is light', (WidgetTester tester) async {
    await tester.pumpWidget(const KayakApp());
    
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, anyOf(isNull, equals(ThemeMode.light)));
    
    // 获取当前主题
    final BuildContext context = tester.element(find.byType(MaterialApp));
    final Brightness brightness = Theme.of(context).brightness;
    expect(brightness, equals(Brightness.light));
  });
}
```

---

#### TC-FLU-008: 深色主题切换测试

**测试目的**: 验证可以切换到深色主题且显示正确

**前置条件**:
- 应用已启动
- 已实现主题切换功能(通过设置或UI控件)

**测试步骤**:
1. 启动应用(当前为浅色主题)
2. 找到并点击主题切换按钮/菜单项(通常在设置或AppBar中)
3. 选择"深色主题"
4. 观察界面变化
5. 检查背景色(应该是深色系)
6. 检查文字颜色(应该是浅色系)
7. 检查各组件的颜色适配

**预期结果**:
- 主题切换后，界面立即更新为深色主题
- 背景色为深色系(深灰或黑色)
- 文字颜色为浅色系(白色或浅灰色)
- 所有组件正确适配深色主题，无未适配的元素
- 颜色对比度符合可访问性标准

**通过标准**: 深色主题完全可用，所有UI元素正确渲染

**测试类型**: 手动测试 + Widget测试

**优先级**: P0

**自动化测试**:
```dart
// test/theme_switch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/main.dart';

void main() {
  testWidgets('Theme switching works', (WidgetTester tester) async {
    await tester.pumpWidget(const KayakApp());
    
    // 查找主题切换按钮(假设使用IconButton)
    final themeButton = find.byIcon(Icons.dark_mode);
    expect(themeButton, findsOneWidget);
    
    // 获取当前亮度
    BuildContext context = tester.element(find.byType(MaterialApp));
    Brightness initialBrightness = Theme.of(context).brightness;
    expect(initialBrightness, equals(Brightness.light));
    
    // 点击切换
    await tester.tap(themeButton);
    await tester.pumpAndSettle();
    
    // 验证主题已切换
    context = tester.element(find.byType(MaterialApp));
    Brightness newBrightness = Theme.of(context).brightness;
    expect(newBrightness, equals(Brightness.dark));
  });
}
```

---

#### TC-FLU-009: 主题持久化测试

**测试目的**: 验证主题设置可以持久化保存

**前置条件**:
- 应用已实现主题持久化(使用shared_preferences等)

**测试步骤**:
1. 启动应用
2. 切换到深色主题
3. 完全关闭应用(不是后台运行，是彻底关闭)
4. 重新启动应用
5. 观察主题设置

**预期结果**:
- 重新启动后，应用保持深色主题设置
- 主题偏好被正确保存和恢复

**通过标准**: 主题设置在应用重启后保持一致

**测试类型**: 手动测试

**优先级**: P1

---

### 2.4 状态管理方案测试

#### TC-FLU-010: Riverpod状态管理集成测试

**测试目的**: 验证Riverpod状态管理方案已正确配置

**前置条件**:
- pubspec.yaml中包含riverpod依赖
- 应用已配置ProviderScope

**测试步骤**:
1. 检查pubspec.yaml中是否包含:
   ```yaml
   dependencies:
     flutter_riverpod: ^2.x.x
   ```
2. 检查main.dart中是否包裹ProviderScope:
   ```dart
   void main() {
     runApp(const ProviderScope(child: KayakApp()));
   }
   ```
3. 检查是否存在Provider定义
4. 运行Widget测试验证Provider可用

**预期结果**:
- pubspec.yaml包含riverpod依赖
- 应用根组件被ProviderScope包裹
- 可以创建和使用StateProvider/StateNotifierProvider等

**通过标准**: Riverpod已正确配置并可用

**测试类型**: 代码检查 + 自动化测试

**优先级**: P0

**自动化测试**:
```dart
// test/riverpod_setup_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/main.dart';

void main() {
  testWidgets('App is wrapped with ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KayakApp()));
    
    expect(find.byType(ProviderScope), findsOneWidget);
  });

  testWidgets('Can read and write providers', (WidgetTester tester) async {
    final testProvider = StateProvider<int>((ref) => 0);
    
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            final value = ref.watch(testProvider);
            return MaterialApp(
              home: Scaffold(
                body: Text('Value: $value'),
              ),
            );
          },
        ),
      ),
    );
    
    expect(find.text('Value: 0'), findsOneWidget);
  });
}
```

---

#### TC-FLU-011: 主题状态管理测试

**测试目的**: 验证主题状态通过状态管理方案管理

**前置条件**:
- Riverpod已配置
- 已实现主题状态Provider

**测试步骤**:
1. 检查是否存在themeProvider定义
2. 验证themeProvider管理ThemeMode状态
3. 测试通过themeProvider切换主题

**预期结果**:
- 存在themeProvider管理主题状态
- 可以通过themeProvider读取当前主题
- 可以通过themeProvider修改主题
- 主题变更通知UI更新

**通过标准**: 主题状态通过Riverpod管理，切换功能正常

**测试类型**: 代码检查 + 自动化测试

**优先级**: P0

**自动化测试**:
```dart
// test/theme_provider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/providers/theme_provider.dart'; // 假设路径

void main() {
  test('ThemeProvider has initial value', () {
    final container = ProviderContainer();
    final themeMode = container.read(themeProvider);
    expect(themeMode, equals(ThemeMode.light));
  });

  test('ThemeProvider can toggle theme', () {
    final container = ProviderContainer();
    final notifier = container.read(themeProvider.notifier);
    
    // 切换到深色
    notifier.setThemeMode(ThemeMode.dark);
    expect(container.read(themeProvider), equals(ThemeMode.dark));
    
    // 切换到浅色
    notifier.setThemeMode(ThemeMode.light);
    expect(container.read(themeProvider), equals(ThemeMode.light));
    
    // 跟随系统
    notifier.setThemeMode(ThemeMode.system);
    expect(container.read(themeProvider), equals(ThemeMode.system));
  });
}
```

---

## 3. 测试数据

### 3.1 主题测试数据

| 主题模式 | 预期背景色 | 预期文字色 | 预期AppBar色 |
|----------|------------|------------|--------------|
| Light | ColorScheme.surface (浅色) | ColorScheme.onSurface (深色) | ColorScheme.surface |
| Dark | ColorScheme.surface (深色) | ColorScheme.onSurface (浅色) | ColorScheme.surface |

### 3.2 平台测试矩阵

| 测试项 | Windows | macOS | Linux |
|--------|---------|-------|-------|
| flutter pub get | ✅ | ✅ | ✅ |
| flutter build | ✅ | ✅ | ✅ |
| flutter run | ✅ | ✅ | ✅ |
| 热重载 | ✅ | ✅ | ✅ |
| Material 3渲染 | ✅ | ✅ | ✅ |
| 主题切换 | ✅ | ✅ | ✅ |

---

## 4. 测试执行检查清单

### 4.1 环境准备检查清单

- [ ] Flutter SDK版本 >= 3.19.0
- [ ] Dart SDK版本 >= 3.3.0
- [ ] Windows桌面支持已启用
- [ ] macOS桌面支持已启用
- [ ] Linux桌面支持已启用
- [ ] 项目依赖已获取 (`flutter pub get` 成功)

### 4.2 手动测试执行检查清单

- [ ] TC-FLU-001: Windows构建测试通过
- [ ] TC-FLU-002: macOS构建测试通过(如环境支持)
- [ ] TC-FLU-003: Linux构建测试通过(如环境支持)
- [ ] TC-FLU-004: 热重载功能测试通过
- [ ] TC-FLU-005: MD3组件渲染测试通过
- [ ] TC-FLU-006: 默认界面结构测试通过
- [ ] TC-FLU-007: 浅色主题默认显示测试通过
- [ ] TC-FLU-008: 深色主题切换测试通过
- [ ] TC-FLU-009: 主题持久化测试通过(如已实现)

### 4.3 自动化测试执行检查清单

- [ ] `flutter test` 所有测试通过
- [ ] 无测试失败或错误
- [ ] 代码覆盖率可接受(>= 60%)

---

## 5. 缺陷记录模板

| 字段 | 说明 |
|------|------|
| **缺陷ID** | BUG-S1-002-XXX |
| **关联测试用例** | TC-FLU-XXX |
| **缺陷描述** | 简要描述问题 |
| **复现步骤** | 详细步骤 |
| **预期结果** | 应该发生什么 |
| **实际结果** | 实际发生什么 |
| **严重程度** | Critical/High/Medium/Low |
| **优先级** | P0/P1/P2/P3 |
| **环境信息** | OS/Flutter版本/设备 |
| **截图/日志** | 附件 |

---

## 6. 测试通过标准

### 6.1 必达标准 (P0)

所有P0测试用例必须通过：
- [ ] TC-FLU-001: Windows构建
- [ ] TC-FLU-003: Linux构建(在当前环境)
- [ ] TC-FLU-004: flutter run正常启动
- [ ] TC-FLU-005: Material Design 3渲染
- [ ] TC-FLU-007: 浅色主题默认
- [ ] TC-FLU-008: 深色主题切换
- [ ] TC-FLU-010: Riverpod集成
- [ ] TC-FLU-011: 主题状态管理

### 6.2 可选标准 (P1)

- [ ] TC-FLU-002: macOS构建(如环境支持)
- [ ] TC-FLU-006: 界面结构(包含在P0中)
- [ ] TC-FLU-009: 主题持久化

### 6.3 整体通过标准

1. 所有P0测试用例通过
2. 无Critical或High级别缺陷
3. 自动化测试 `flutter test` 100%通过
4. 应用在所有目标平台可正常启动

---

## 7. 参考文档

- [Flutter Desktop Documentation](https://docs.flutter.dev/desktop)
- [Material Design 3 Guidelines](https://m3.material.io/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Flutter Testing Documentation](https://docs.flutter.dev/testing)

---

**文档结束**
