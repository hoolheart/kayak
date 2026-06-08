import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';

/// 时间段问候语文本组件。
///
/// 根据当前系统时间自动选择问候语：
/// - 06:00-11:59 → "早上好" / "Good morning"
/// - 12:00-17:59 → "下午好" / "Good afternoon"
/// - 18:00-05:59 → "晚上好" / "Good evening"
///
/// 支持自定义时间（用于测试）。
class GreetingText extends StatelessWidget {
  const GreetingText({
    super.key,
    this.time,
    this.textAlign = TextAlign.start,
    this.style,
  });

  /// 用于测试的时间覆盖（为 null 时使用当前时间）。
  final DateTime? time;

  /// 文本对齐方式。
  final TextAlign textAlign;

  /// 文本样式，默认为 Headline Small。
  final TextStyle? style;

  /// 根据指定或当前时间返回问候语 Key。
  static String getGreetingKey(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 6 && hour < 12) return 'goodMorning';
    if (hour >= 12 && hour < 18) return 'goodAfternoon';
    return 'goodEvening';
  }

  /// 根据指定或当前时间返回问候语字符串。
  static String getGreeting(AppLocalizations loc, {DateTime? time}) {
    final dateTime = time ?? DateTime.now();
    final key = getGreetingKey(dateTime);
    switch (key) {
      case 'goodMorning':
        return loc.goodMorning;
      case 'goodAfternoon':
        return loc.goodAfternoon;
      case 'goodEvening':
        return loc.goodEvening;
      default:
        return loc.goodMorning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final greeting = getGreeting(loc, time: time);

    return Text(
      greeting,
      style: style,
      textAlign: textAlign,
    );
  }
}

/// 根据时间返回问候语 Key 的 Hook/Provider 版本。
///
/// 用于非 Widget 场景（如 Provider、ViewModel）。
String getGreetingKeyFromTime([DateTime? time]) {
  final dateTime = time ?? DateTime.now();
  return GreetingText.getGreetingKey(dateTime);
}
