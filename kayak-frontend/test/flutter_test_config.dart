import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// 自定义 Golden 文件比较器，支持像素容差
///
/// 默认的 LocalFileComparator 要求像素完全匹配。
/// 此比较器允许指定比例的像素差异（默认 5%），
/// 以适应不同平台（macOS vs Linux）字体渲染的微小差异。
class ToleranceLocalFileComparator extends LocalFileComparator {
  /// 允许的像素差异比例（0.0 - 1.0）
  /// 默认 0.05 即 5% 的像素可以不同
  final double tolerance;

  ToleranceLocalFileComparator(
    Uri testFile, {
    this.tolerance = 0.05,
  }) : super(testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    // 优先尝试精确比较（快速路径）
    final exactResult = await super.compare(imageBytes, golden);
    if (exactResult) return true;

    // 精确比较失败时，尝试容差比较
    try {
      final goldenBytes = await getGoldenBytes(golden);
      return _compareWithTolerance(
        imageBytes,
        Uint8List.fromList(goldenBytes),
      );
    } catch (e) {
      // 无法读取 golden 文件或解码失败
      print('Golden tolerance comparison failed: $e');
      return false;
    }
  }

  /// 以像素级别比较两张图片，允许一定比例的像素差异
  Future<bool> _compareWithTolerance(
    Uint8List testBytes,
    Uint8List goldenBytes,
  ) async {
    final testImage = await _decodeImage(testBytes);
    final goldenImage = await _decodeImage(goldenBytes);

    // 尺寸不同直接失败
    if (testImage.width != goldenImage.width ||
        testImage.height != goldenImage.height) {
      testImage.dispose();
      goldenImage.dispose();
      return false;
    }

    final testData = await testImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final goldenData = await goldenImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    testImage.dispose();
    goldenImage.dispose();

    if (testData == null || goldenData == null) return false;

    final totalPixels = testData.lengthInBytes ~/ 4;
    if (totalPixels == 0) return true;

    int differentPixels = 0;
    for (int i = 0; i < testData.lengthInBytes; i += 4) {
      // 比较 RGBA 四个通道（忽略微小差异）
      final rDiff = (testData.getUint8(i) - goldenData.getUint8(i)).abs();
      final gDiff =
          (testData.getUint8(i + 1) - goldenData.getUint8(i + 1)).abs();
      final bDiff =
          (testData.getUint8(i + 2) - goldenData.getUint8(i + 2)).abs();
      final aDiff =
          (testData.getUint8(i + 3) - goldenData.getUint8(i + 3)).abs();

      // 任何通道差异超过阈值则计为不同像素
      if (rDiff > 10 || gDiff > 10 || bDiff > 10 || aDiff > 10) {
        differentPixels++;
      }
    }

    final diffRatio = differentPixels / totalPixels;
    return diffRatio <= tolerance;
  }

  /// 将 PNG 字节数据解码为 [ui.Image]
  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image image) {
      completer.complete(image);
    });
    return completer.future;
  }
}

/// Flutter测试框架配置
///
/// 此函数在测试框架启动时自动调用
/// 用于配置Golden测试、加载字体等全局设置
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // 配置Golden文件比较器（允许 5% 像素差异容忍度）
  // 注意：LocalFileComparator接收参考文件的URI，不是目录
  goldenFileComparator = ToleranceLocalFileComparator(
    Uri.parse('test/widget/golden/basic_golden_test.dart'),
    tolerance: 0.05, // 5% 像素差异容忍度
  );

  // 加载字体确保文本渲染一致性
  // 注意：项目当前使用系统默认字体（pubspec.yaml中字体被注释）
  // 如果使用自定义字体，取消下面一行的注释并导入golden_toolkit
  // await loadAppFonts();

  // 执行测试主函数
  return testMain();
}
