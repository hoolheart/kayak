/// 桌面平台窗口管理初始化
///
/// 仅在桌面平台（Linux/macOS/Windows）编译时使用
/// 导入真实的 window_manager 包
library;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 初始化桌面平台窗口管理器
Future<void> initDesktopWindow() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(800, 600),
    center: true,
    title: 'Kayak - 科学研究支持平台',
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
