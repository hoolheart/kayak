import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 测试应用包装器
///
/// 为Widget测试提供一致的应用环境
/// 包括主题、本地化、Provider等配置
class TestApp extends StatelessWidget {
  /// 要测试的子Widget
  final Widget child;

  /// 主题模式（浅色/深色/跟随系统）
  final ThemeMode themeMode;

  /// Provider覆盖列表
  final List<Override> overrides;

  /// 本地化
  final Locale? locale;

  /// 是否显示Debug标记
  final bool showDebugBanner;

  const TestApp({
    super.key,
    required this.child,
    this.themeMode = ThemeMode.light,
    this.overrides = const [],
    this.locale,
    this.showDebugBanner = false,
  });

  /// 工厂构造函数：浅色主题
  factory TestApp.light({
    required Widget child,
    List<Override> overrides = const [],
    Locale? locale,
  }) {
    return TestApp(
      themeMode: ThemeMode.light,
      overrides: overrides,
      locale: locale,
      child: child,
    );
  }

  /// 工厂构造函数：深色主题
  factory TestApp.dark({
    required Widget child,
    List<Override> overrides = const [],
    Locale? locale,
  }) {
    return TestApp(
      themeMode: ThemeMode.dark,
      overrides: overrides,
      locale: locale,
      child: child,
    );
  }

  /// 工厂构造函数：带Provider覆盖
  factory TestApp.withProvider({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
    required List<Override> overrides,
    Locale? locale,
  }) {
    return TestApp(
      themeMode: themeMode,
      overrides: overrides,
      locale: locale,
      child: child,
    );
  }

  /// 工厂构造函数：指定尺寸（用于响应式测试）
  factory TestApp.sized({
    required Widget child,
    required Size size,
    ThemeMode themeMode = ThemeMode.light,
    List<Override> overrides = const [],
    Locale? locale,
  }) {
    return TestApp(
      themeMode: themeMode,
      overrides: overrides,
      locale: locale,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: showDebugBanner,
      themeMode: themeMode,
      locale: locale,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: child,
    );

    if (overrides.isNotEmpty) {
      return ProviderScope(
        overrides: overrides,
        child: app,
      );
    }

    return app;
  }
}
