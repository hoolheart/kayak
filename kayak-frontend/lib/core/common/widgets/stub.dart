/// Web 平台存根 - 替代 window_manager 包
///
/// 当编译为 Web 时，此存根替代真实的 window_manager 包。
/// 提供与 window_manager 兼容的类型和 getter。
/// 所有方法均为空操作，因为 CustomTitleBar 在 Web 平台通过 kIsWeb 检查返回空 widget。
library;

/// 存根的窗口管理器实例
final StubWindowManager windowManager = StubWindowManager();

/// Web 存根 - 模拟 window_manager 的接口
class StubWindowManager {
  /// 确保初始化（空操作）
  Future<void> ensureInitialized() async {}

  /// 检查是否最大化（始终返回 false）
  Future<bool> isMaximized() async => false;

  /// 开始拖拽（空操作）
  void startDragging() {}

  /// 最小化窗口（空操作）
  void minimize() {}

  /// 最大化窗口（空操作）
  Future<void> maximize() async {}

  /// 取消最大化窗口（空操作）
  Future<void> unmaximize() async {}

  /// 关闭窗口（空操作）
  void close() {}
}
