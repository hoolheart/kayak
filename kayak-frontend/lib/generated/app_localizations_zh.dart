// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Kayak';

  @override
  String get welcomeMessage => '欢迎使用 Kayak';

  @override
  String get subtitle => '科学研究支持平台';

  @override
  String get enterWorkbench => '进入工作台';

  @override
  String get settings => '设置';

  @override
  String get toggleTheme => '切换主题';
}
