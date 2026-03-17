import 'dart:io';
import 'package:flutter/material.dart';

/// Golden测试配置
///
/// 提供Golden测试的全局配置和工具方法
class GoldenTestConfig {
  GoldenTestConfig._();

  /// 默认像素差异阈值（0.0 - 1.0）
  static const double defaultThreshold = 0.01;

  /// Golden文件根目录
  static const String goldenFilesDir = 'test/golden_files';

  /// 配置Golden文件比较器
  ///
  /// [threshold] - 允许的像素差异比例
  ///
  /// 注意：这个方法在flutter_test_config.dart中通过全局设置goldenFileComparator来使用
  static void configureGoldenFileComparator(
      {double threshold = defaultThreshold}) {
    // 配置信息，实际比较器设置在 flutter_test_config.dart 中
    // 这里仅作为配置文档
  }

  /// 加载应用字体（确保文本渲染一致）
  ///
  /// 注意：项目当前使用系统默认字体（pubspec.yaml中字体被注释）
  /// 如果使用自定义字体，请在flutter_test_config.dart中调用此方法
  static Future<void> loadAppFonts() async {
    // 由于项目使用系统默认字体，此方法为空实现
    // 如果使用自定义字体，需要添加golden_toolkit的loadAppFonts调用
  }

  /// 生成Golden文件名
  ///
  /// [name] - 基础名称
  /// [theme] - 主题模式
  /// [device] - 设备类型
  /// [suffix] - 可选后缀
  static String generateGoldenFileName(
    String name, {
    ThemeMode? theme,
    String? device,
    String? suffix,
  }) {
    final buffer = StringBuffer(name);

    if (theme != null) {
      buffer.write('_${theme.name}');
    }

    if (device != null && device.isNotEmpty) {
      buffer.write('_$device');
    }

    if (suffix != null && suffix.isNotEmpty) {
      buffer.write('_$suffix');
    }

    buffer.write('.png');
    return buffer.toString();
  }

  /// 确保Golden文件目录存在
  static void ensureGoldenDirectoryExists() {
    final directories = [
      '$goldenFilesDir/light',
      '$goldenFilesDir/dark',
      '$goldenFilesDir/components',
    ];

    for (final dir in directories) {
      final directory = Directory(dir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
    }
  }

  /// Golden文件完整路径
  static String getGoldenFilePath(String fileName) {
    return '$goldenFilesDir/$fileName';
  }

  /// 检查Golden文件是否存在
  static bool goldenFileExists(String fileName) {
    final file = File(getGoldenFilePath(fileName));
    return file.existsSync();
  }

  /// 获取主题对应的子目录
  static String getThemeSubdirectory(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'light'; // 默认使用light目录
    }
  }

  /// 常用设备尺寸定义
  static const Map<String, Size> deviceSizes = {
    'mobile': Size(375, 812), // iPhone X
    'tablet': Size(768, 1024), // iPad
    'desktop': Size(1280, 800), // Standard desktop
    'wide': Size(1920, 1080), // Full HD
  };

  /// 获取设备尺寸
  static Size? getDeviceSize(String device) {
    return deviceSizes[device];
  }
}
