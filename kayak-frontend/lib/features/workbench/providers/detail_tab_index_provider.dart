/// Tab索引状态Provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab索引枚举
enum DetailTab {
  deviceList, // 设备列表 (index: 0)
  settings, // 设置 (index: 1)
}

/// Tab索引Notifier
class DetailTabIndexNotifier extends StateNotifier<int> {
  DetailTabIndexNotifier() : super(0); // 默认选中"设备列表"

  void setTabIndex(int index) {
    state = index;
  }

  void goToDeviceList() => setTabIndex(DetailTab.deviceList.index);
  void goToSettings() => setTabIndex(DetailTab.settings.index);
}

/// Provider for DetailTabIndexNotifier
final detailTabIndexProvider =
    StateNotifierProvider<DetailTabIndexNotifier, int>((ref) {
  return DetailTabIndexNotifier();
});
