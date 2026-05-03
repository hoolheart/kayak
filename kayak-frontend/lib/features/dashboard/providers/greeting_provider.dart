/// 问候语状态 Provider
///
/// 根据系统时间返回对应的问候语、副标题和时间显示

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 问候语状态数据类
class GreetingState {
  final String displayName;
  final String subtitle;
  final String dateDisplay;

  const GreetingState({
    required this.displayName,
    required this.subtitle,
    required this.dateDisplay,
  });
}

/// 问候语生成 Provider
///
/// 根据系统时间动态生成：
/// - 5:00-12:00: "早上好"
/// - 12:00-18:00: "下午好"
/// - 18:00-5:00: "晚上好"
final greetingProvider = Provider<GreetingState>((ref) {
  final now = DateTime.now();
  final hour = now.hour;

  String greeting;
  if (hour >= 5 && hour < 12) {
    greeting = '早上好';
  } else if (hour >= 12 && hour < 18) {
    greeting = '下午好';
  } else {
    greeting = '晚上好';
  }

  const weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  return GreetingState(
    displayName: greeting,
    subtitle: '这里是您今天的研究概览',
    dateDisplay:
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 星期${weekdays[now.weekday % 7]}',
  );
});
