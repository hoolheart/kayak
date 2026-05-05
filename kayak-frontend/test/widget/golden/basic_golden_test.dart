import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

/// 基础Golden测试套件
///
/// 测试TestApp包装器在浅色/深色主题下的视觉表现
/// 使用简单的Material组件验证Golden测试框架配置正确
///
/// Golden 测试因字体渲染差异仅支持 macOS 平台。
/// CI 中通过 `--exclude-tags golden` 跳过。
void main() {
  group('TestApp Golden Tests', () {
    testWidgets('Golden - TestApp Light Theme', (tester) async {
      // 设置固定屏幕尺寸（桌面端）
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 构建测试页面（浅色主题）
      await tester.pumpWidget(
        TestApp.light(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Test Page'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome to Kayak'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 等待所有动画完成
      await tester.pumpAndSettle();

      // 验证Golden图片
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../../golden_files/light/test_app_light_desktop.png',
        ),
      );
    }, skip: !Platform.isMacOS, tags: 'golden');

    testWidgets('Golden - TestApp Dark Theme', (tester) async {
      // 设置固定屏幕尺寸（桌面端）
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 构建测试页面（深色主题）
      await tester.pumpWidget(
        TestApp.dark(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Test Page'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome to Kayak'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 等待所有动画完成
      await tester.pumpAndSettle();

      // 验证Golden图片
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../golden_files/dark/test_app_dark_desktop.png'),
      );
    }, skip: !Platform.isMacOS, tags: 'golden');

    testWidgets('Golden - TestApp Mobile Light', (tester) async {
      // 设置移动端屏幕尺寸
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        TestApp.light(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Test Page'),
            ),
            body: const Center(
              child: Text('Mobile View'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../golden_files/light/test_app_light_mobile.png'),
      );
    }, skip: !Platform.isMacOS, tags: 'golden');

    testWidgets('Golden - TestApp Mobile Dark', (tester) async {
      // 设置移动端屏幕尺寸
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        TestApp.dark(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Test Page'),
            ),
            body: const Center(
              child: Text('Mobile View'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../golden_files/dark/test_app_dark_mobile.png'),
      );
    }, skip: !Platform.isMacOS, tags: 'golden');

    testWidgets('Golden - Card Component Light', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        TestApp.light(
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings),
                    SizedBox(height: 8),
                    Text('Card Title'),
                    Text('Card subtitle text'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Card),
        matchesGoldenFile('../../golden_files/light/card_component_light.png'),
      );
    }, skip: !Platform.isMacOS, tags: 'golden');

    testWidgets('Golden - Card Component Dark', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        TestApp.dark(
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings),
                    SizedBox(height: 8),
                    Text('Card Title'),
                    Text('Card subtitle text'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Card),
        matchesGoldenFile('../../golden_files/dark/card_component_dark.png'),
      );
    }, skip: !Platform.isMacOS, tags: 'golden');
  });
}
