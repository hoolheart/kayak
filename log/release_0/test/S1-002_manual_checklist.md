# S1-002 手动测试执行清单

**任务**: Flutter前端工程初始化  
**日期**: _______________  
**测试人员**: _______________  
**测试环境**: _______________

---

## 执行前检查

- [ ] Flutter SDK 已安装 (`flutter doctor` 无关键错误)
- [ ] Flutter版本 >= 3.19.0
- [ ] 桌面支持已启用:
  - [ ] Windows: `flutter config --enable-windows-desktop`
  - [ ] macOS: `flutter config --enable-macos-desktop`
  - [ ] Linux: `flutter config --enable-linux-desktop`

---

## P0 必测项 (验收标准)

### □ TC-FLU-001: Windows桌面平台构建测试

**执行步骤**:
```bash
cd /home/hzhou/workspace/kayak/kayak-frontend
flutter pub get
flutter build windows
```

**结果**: ☐ 通过 ☐ 失败 ☐ 跳过  
**备注**: _______________

---

### □ TC-FLU-003: Linux桌面平台构建测试

**执行步骤**:
```bash
cd /home/hzhou/workspace/kayak/kayak-frontend
flutter pub get
flutter build linux
```

**结果**: ☐ 通过 ☐ 失败 ☐ 跳过  
**备注**: _______________

---

### □ TC-FLU-004: 桌面端热重载功能测试

**执行步骤**:
1. 运行 `flutter run -d linux`
2. 确认应用在10秒内启动
3. 修改 `lib/main.dart` 中的文本
4. 保存文件，确认热重载
5. 按 `R` 热重启
6. 按 `q` 退出

**结果**: ☐ 通过 ☐ 失败 ☐ 跳过  
**备注**: _______________

---

### □ TC-FLU-005: Material Design 3组件渲染测试

**检查项**:
- [ ] 应用使用 `useMaterial3: true`
- [ ] 组件使用MD3风格(圆角按钮、卡片等)
- [ ] 颜色主题符合MD3规范
- [ ] 字体排版符合MD3规范

**结果**: ☐ 通过 ☐ 失败 ☐ 跳过  
**备注**: _______________

---

### □ TC-FLU-007: 浅色主题默认显示测试

**检查项**:
- [ ] 默认启动为浅色主题
- [ ] 背景色为浅色
- [ ] 文字为深色，可读性好

**结果**: ☐ 通过 ☐ 失败 ☐ 跳过  
**备注**: _______________

---

### □ TC-FLU-008: 深色主题切换测试

**执行步骤**:
1. 启动应用
2. 找到主题切换按钮
3. 切换到深色主题
4. 检查所有UI元素适配

**检查项**:
- [ ] 主题切换功能可用
- [ ] 背景变为深色
- [ ] 文字变为浅色
- [ ] 所有组件正确适配

**结果**: ☐ 通过 ☐ 失败 ☐ 跳过  
**备注**: _______________

---

## P1 选测项

### □ TC-FLU-002: macOS桌面平台构建测试
**结果**: ☐ 通过 ☐ 失败 ☐ 跳过 (环境不支持)  
**备注**: _______________

### □ TC-FLU-006: 默认界面结构测试
**结果**: ☐ 通过 ☐ 失败 ☐ 跳过  
**备注**: _______________

### □ TC-FLU-009: 主题持久化测试
**结果**: ☐ 通过 ☐ 失败 ☐ 跳过  
**备注**: _______________

---

## 自动化测试

### □ 运行Widget测试

**执行步骤**:
```bash
cd /home/hzhou/workspace/kayak/kayak-frontend
flutter test
```

**结果**: ☐ 通过 ☐ 失败  
**通过率**: ______%  
**失败测试**: _______________

---

## 汇总

| 类别 | 通过 | 失败 | 跳过 | 总计 |
|------|------|------|------|------|
| P0测试 | | | | 6 |
| P1测试 | | | | 3 |
| 自动化 | | | | 1 |

### 整体评估

- [ ] **通过**: 所有P0测试通过，无Critical/High级别缺陷
- [ ] **有条件通过**: P0测试通过，存在Low级别缺陷
- [ ] **不通过**: 存在P0测试失败或Critical/High级别缺陷

### 遗留问题

| ID | 问题描述 | 严重程度 | 计划解决时间 |
|----|----------|----------|--------------|
| | | | |

### 签字

测试人员签字: _______________ 日期: _______________

开发人员确认: _______________ 日期: _______________

---

## 快速参考

### 常用命令
```bash
# 获取依赖
flutter pub get

# 运行应用 (桌面)
flutter run -d windows
flutter run -d macos
flutter run -d linux

# 运行测试
flutter test
flutter test --coverage

# 构建
flutter build windows
flutter build macos
flutter build linux

# 代码检查
flutter analyze
flutter format lib test
```

### 预期pubspec.yaml依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```
