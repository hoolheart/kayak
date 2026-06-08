import '../../../generated/app_localizations.dart';

// ============================================================
// Greeting Utilities — 时间段问候语工具函数
// ============================================================

/// 根据指定或当前时间返回问候语 Key。
///
/// 根据当前系统时间自动选择问候语：
/// - 06:00-11:59 → 'goodMorning'
/// - 12:00-17:59 → 'goodAfternoon'
/// - 18:00-05:59 → 'goodEvening'
String getGreetingKey(DateTime dateTime) {
  final hour = dateTime.hour;
  if (hour >= 6 && hour < 12) return 'goodMorning';
  if (hour >= 12 && hour < 18) return 'goodAfternoon';
  return 'goodEvening';
}

/// 根据指定或当前时间返回问候语字符串。
String getGreeting(AppLocalizations loc, {DateTime? time}) {
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

/// 根据时间返回问候语 Key。
///
/// 用于非 Widget 场景（如 Provider、ViewModel）。
String getGreetingKeyFromTime([DateTime? time]) {
  final dateTime = time ?? DateTime.now();
  return getGreetingKey(dateTime);
}
