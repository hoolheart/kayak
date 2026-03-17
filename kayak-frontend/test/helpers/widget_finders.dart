import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget查找辅助类
///
/// 提供封装Flutter测试finder的便捷方法
/// 支持按文本、Key、类型等多种方式查找Widget
class WidgetFinderHelpers {
  WidgetFinderHelpers._();

  /// 按文本内容查找Widget
  ///
  /// [text] - 要查找的精确文本
  /// [skipOffstage] - 是否跳过不在屏幕上的组件，默认true
  ///
  /// 返回匹配文本的Finder
  static Finder findByText(String text, {bool skipOffstage = true}) {
    return find.text(text, skipOffstage: skipOffstage);
  }

  /// 按Key查找Widget
  ///
  /// [key] - Key的字符串值，将包装为ValueKey
  /// [skipOffstage] - 是否跳过不在屏幕上的组件，默认true
  ///
  /// 返回匹配Key的Finder
  static Finder findByKey(String key, {bool skipOffstage = true}) {
    return find.byKey(ValueKey(key), skipOffstage: skipOffstage);
  }

  /// 按类型查找Widget
  ///
  /// [T] - 要查找的Widget类型
  /// [skipOffstage] - 是否跳过不在屏幕上的组件，默认true
  ///
  /// 返回匹配类型的Finder
  static Finder findByType<T extends Widget>({bool skipOffstage = true}) {
    return find.byType(T, skipOffstage: skipOffstage);
  }

  /// 按Widget类型和文本组合查找
  ///
  /// 查找包含特定文本的特定类型Widget
  /// [T] - Widget类型
  /// [text] - 文本内容
  static Finder findByTypeAndText<T extends Widget>(String text) {
    return find.ancestor(
      of: find.text(text),
      matching: find.byType(T),
    );
  }

  /// 查找包含特定文本的按钮
  ///
  /// 便捷方法，等同于find.widgetWithText(ElevatedButton, text)
  static Finder findButtonByText(String text) {
    return find.widgetWithText(ElevatedButton, text);
  }

  /// 通过hintText查找TextField
  ///
  /// [hint] - 输入框的提示文本
  static Finder findTextFieldByHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  /// 通过labelText查找TextField
  ///
  /// [label] - 输入框的标签文本
  static Finder findTextFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
  }

  /// 查找祖先Widget
  ///
  /// [finder] - 子Widget的finder
  /// [matching] - 祖先Widget的匹配条件
  static Finder findAncestor({
    required Finder finder,
    required Finder matching,
  }) {
    return find.ancestor(
      of: finder,
      matching: matching,
    );
  }

  /// 查找后代Widget
  ///
  /// [finder] - 父Widget的finder
  /// [matching] - 后代Widget的匹配条件
  static Finder findDescendant({
    required Finder finder,
    required Finder matching,
  }) {
    return find.descendant(
      of: finder,
      matching: matching,
    );
  }

  /// 查找具有特定图标和文本的Widget
  ///
  /// [icon] - 图标数据
  /// [text] - 文本内容
  static Finder findWidgetWithIconAndText(IconData icon, String text) {
    return find.widgetWithIcon(Widget, icon);
  }

  /// 查找特定精确数量的Widget
  ///
  /// [count] - 期望的数量
  static Matcher findsExactly(int count) {
    return findsNWidgets(count);
  }
}
