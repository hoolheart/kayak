/// 视图模式Provider
///
/// 管理卡片/列表视图切换状态
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workbench_form_state.dart';

const String _viewModeKey = 'workbench_view_mode';

/// 视图模式Notifier
class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier() : super(ViewMode.card) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_viewModeKey);
    if (stored == 'list') {
      state = ViewMode.list;
    } else {
      state = ViewMode.card;
    }
  }

  Future<void> setViewMode(ViewMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _viewModeKey,
      mode == ViewMode.list ? 'list' : 'card',
    );
  }

  Future<void> toggle() async {
    await setViewMode(state == ViewMode.card ? ViewMode.list : ViewMode.card);
  }
}

/// Provider for ViewModeNotifier
final viewModeProvider =
    StateNotifierProvider<ViewModeNotifier, ViewMode>((ref) {
  return ViewModeNotifier();
});
