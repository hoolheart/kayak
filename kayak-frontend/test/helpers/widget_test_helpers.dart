import 'package:flutter/material.dart';
import 'package:kayak_frontend/generated/app_localizations.dart';

/// 带本地化的测试用 MaterialApp 包装器。
///
/// 使用方式：
/// ```dart
/// await tester.pumpWidget(wrapWithMaterial(
///   ErrorView(title: '错误', onRetry: () {}),
/// ));
/// ```
///
/// 可选 [screenSize] 参数用于测试响应式布局。
Widget wrapWithMaterial(
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
  Size? screenSize,
}) {
  Widget result = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    themeMode: themeMode,
    home: Scaffold(body: child),
  );

  if (screenSize != null) {
    result = MediaQuery(
      data: MediaQueryData(size: screenSize),
      child: result,
    );
  }

  return result;
}
