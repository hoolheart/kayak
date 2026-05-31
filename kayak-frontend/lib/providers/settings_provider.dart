import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 实例的 Provider。
///
/// 必须在应用启动时通过 [ProviderScope] overrides 注入实际实例：
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final prefs = await SharedPreferences.getInstance();
///   runApp(ProviderScope(
///     overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
///     child: KayakApp(),
///   ));
/// }
/// ```
///
/// 在测试中通过 [ProviderContainer] overrides 注入 mock：
/// ```dart
/// SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
/// final prefs = await SharedPreferences.getInstance();
/// final container = ProviderContainer(overrides: [
///   sharedPreferencesProvider.overrideWithValue(prefs),
/// ]);
/// ```
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden. '
    'Initialize in main.dart with actual SharedPreferences instance.',
  );
});

/// 主题模式 Notifier。
///
/// 使用 Riverpod 3.x [Notifier] API，纯同步操作。
/// 管理 [ThemeMode] 状态并通过 [SharedPreferences] 持久化。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  /// SharedPreferences 中存储主题模式的 Key
  static const String _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final storedValue = prefs.getString(_themeModeKey);
      if (storedValue == null) return ThemeMode.system;
      return ThemeMode.values.firstWhere(
        (e) => e.name == storedValue,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      // SharedPreferences 不可用时回退到默认值
      return ThemeMode.system;
    }
  }

  /// 设置主题模式并持久化到 SharedPreferences。
  ///
  /// [mode] 支持 [ThemeMode.system]、[ThemeMode.light]、[ThemeMode.dark]。
  /// 状态变更立即生效，同步更新 [state] 和存储。
  void setTheme(ThemeMode mode) {
    state = mode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString(_themeModeKey, mode.name);
    } catch (_) {
      // 持久化失败时静默处理，状态已更新到内存中
    }
  }
}

/// 主题模式的 Provider。
///
/// 通过 [NotifierProvider] 暴露 [ThemeModeNotifier]，
/// 支持读写访问：
/// ```dart
/// // 读取
/// final mode = ref.watch(themeModeProvider);
/// // 写入
/// ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
/// ```
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
