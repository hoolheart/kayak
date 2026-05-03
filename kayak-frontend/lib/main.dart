import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform/desktop_init_real.dart'
    if (dart.library.html) 'core/platform/desktop_init_stub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化桌面窗口管理器（Web 平台使用存根实现）
  await initDesktopWindow();

  // 设置首选方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ProviderScope(child: KayakApp()));
}
