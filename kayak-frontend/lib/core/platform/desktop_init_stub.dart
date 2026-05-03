/// 桌面平台窗口管理初始化（Web 平台存根）
///
/// Web 平台编译时使用此存根替代真实的 window_manager 导入
/// 避免 dart:io 不可用的编译错误
library;

/// Web 平台存根：不执行任何窗口初始化操作
Future<void> initDesktopWindow() async {
  // Web 平台不需要窗口管理器
}
