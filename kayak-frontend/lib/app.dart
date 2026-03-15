import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/core/locale_provider.dart';
import 'providers/core/theme_provider.dart';

class KayakApp extends ConsumerWidget {
  const KayakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      // 应用信息
      title: 'Kayak',
      debugShowCheckedModeBanner: false,

      // 路由配置
      routerConfig: router,

      // 主题配置
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // 国际化配置
      locale: locale,
      supportedLocales: const [
        Locale('en'), // 英文
        Locale('zh'), // 中文
        Locale('fr'), // 法文
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Material Design 3
      themeAnimationDuration: const Duration(milliseconds: 300),
    );
  }
}
