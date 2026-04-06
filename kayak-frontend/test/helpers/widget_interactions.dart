import 'package:flutter_test/flutter_test.dart';
import 'widget_finders.dart';

/// Widget交互辅助类
///
/// 封装Widget测试中的常见交互操作
/// 提供链式调用友好的API设计
class WidgetInteractionHelpers {
  WidgetInteractionHelpers._();

  /// 点击指定Finder的Widget
  ///
  /// [tester] - WidgetTester实例
  /// [finder] - 要点击的Widget的Finder
  /// [warnIfMissed] - 如果未点击到是否警告，默认true
  static Future<void> tap(
    WidgetTester tester,
    Finder finder, {
    bool warnIfMissed = true,
  }) async {
    await tester.tap(finder, warnIfMissed: warnIfMissed);
    await tester.pump();
  }

  /// 通过文本点击Widget
  ///
  /// 自动查找包含指定文本的Widget并点击
  static Future<void> tapByText(WidgetTester tester, String text) async {
    await tap(tester, WidgetFinderHelpers.findByText(text));
  }

  /// 通过Key点击Widget
  ///
  /// [key] - Widget的Key字符串
  static Future<void> tapByKey(WidgetTester tester, String key) async {
    await tap(tester, WidgetFinderHelpers.findByKey(key));
  }

  /// 在TextField中输入文本
  ///
  /// 自动先点击获取焦点，然后输入文本
  /// [finder] - TextField的Finder
  /// [text] - 要输入的文本
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// 通过Key在TextField中输入文本
  static Future<void> enterTextByKey(
    WidgetTester tester,
    String key,
    String text,
  ) async {
    await enterText(tester, WidgetFinderHelpers.findByKey(key), text);
  }

  /// 通过hint文本在TextField中输入
  static Future<void> enterTextByHint(
    WidgetTester tester,
    String hint,
    String text,
  ) async {
    await enterText(
      tester,
      WidgetFinderHelpers.findTextFieldByHint(hint),
      text,
    );
  }

  /// 通过label文本在TextField中输入
  static Future<void> enterTextByLabel(
    WidgetTester tester,
    String label,
    String text,
  ) async {
    await enterText(
      tester,
      WidgetFinderHelpers.findTextFieldByLabel(label),
      text,
    );
  }

  /// 滚动列表
  ///
  /// [tester] - WidgetTester实例
  /// [finder] - 可滚动Widget的Finder
  /// [offset] - 滚动偏移量（正值向下，负值向上）
  static Future<void> scroll(
    WidgetTester tester,
    Finder finder,
    double offset,
  ) async {
    await tester.drag(finder, Offset(0, -offset));
    await tester.pumpAndSettle();
  }

  /// 滚动直到指定Widget可见
  ///
  /// [tester] - WidgetTester实例
  /// [item] - 要滚动到的Widget的Finder
  /// [scrollable] - 可滚动容器的Finder
  /// [delta] - 每次滚动的距离
  /// [maxScrolls] - 最大滚动次数
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder item,
    Finder scrollable, {
    double delta = 100.0,
    int maxScrolls = 50,
  }) async {
    await tester.scrollUntilVisible(
      item,
      delta,
      scrollable: scrollable,
      maxScrolls: maxScrolls,
    );
    await tester.pumpAndSettle();
  }

  /// 长按Widget
  static Future<void> longPress(WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  /// 拖拽Widget
  ///
  /// [finder] - 要拖拽的Widget
  /// [offset] - 拖拽的偏移量
  static Future<void> drag(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// 拖拽列表项以重新排序
  static Future<void> dragAndDrop(
    WidgetTester tester,
    Finder source,
    Finder target,
  ) async {
    final gesture = await tester.startGesture(tester.getCenter(source));
    await gesture.moveTo(tester.getCenter(target));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// 等待指定时长
  static Future<void> wait(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
  }

  /// 等待所有动画完成
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// 多次触发pump以推进动画
  ///
  /// [duration] - 总时长
  /// [interval] - 每次pump的间隔
  static Future<void> pumpFor(
    WidgetTester tester,
    Duration duration, {
    Duration interval = const Duration(milliseconds: 16),
  }) async {
    final steps = duration.inMilliseconds ~/ interval.inMilliseconds;
    for (var i = 0; i < steps; i++) {
      await tester.pump(interval);
    }
  }

  /// 清空TextField内容
  static Future<void> clearTextField(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, '');
    await tester.pump();
  }
}
