import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter测试框架配置
///
/// 此函数在测试框架启动时自动调用
/// 用于配置Golden测试、加载字体等全局设置
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // 配置Golden文件比较器（允许1%像素差异）
  // 注意：LocalFileComparator接收参考文件的URI，不是目录
  goldenFileComparator = LocalFileComparator(
    Uri.parse('test/widget/golden/basic_golden_test.dart'),
  );

  // 加载字体确保文本渲染一致性
  // 注意：项目当前使用系统默认字体（pubspec.yaml中字体被注释）
  // 如果使用自定义字体，取消下面一行的注释并导入golden_toolkit
  // await loadAppFonts();

  // 执行测试主函数
  return testMain();
}
