import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Kayak'**
  String get appTitle;

  /// Login button/label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button/label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Logout button/label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Dashboard navigation label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Workbenches navigation label
  ///
  /// In en, this message translates to:
  /// **'Workbenches'**
  String get workbenches;

  /// Methods navigation label
  ///
  /// In en, this message translates to:
  /// **'Methods'**
  String get methods;

  /// Experiments navigation label
  ///
  /// In en, this message translates to:
  /// **'Experiments'**
  String get experiments;

  /// Analysis navigation label
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// Settings navigation label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Workbench list page title
  ///
  /// In en, this message translates to:
  /// **'Workbench List'**
  String get workbenchList;

  /// Method list page title
  ///
  /// In en, this message translates to:
  /// **'Method List'**
  String get methodList;

  /// Experiment list page title
  ///
  /// In en, this message translates to:
  /// **'Experiment List'**
  String get experimentList;

  /// Login error message
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get loginError;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error, please check connection'**
  String get networkError;

  /// Session expired message
  ///
  /// In en, this message translates to:
  /// **'Session expired, please login again'**
  String get sessionExpired;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Retry action button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Confirm action button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Cancel action button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete action button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Create action button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Edit action button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Save action button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Search action button
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Submit action button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Email field hint text
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailHint;

  /// Password field hint text
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordHint;

  /// Email field validation error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Password field validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Link text to navigate to register page
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccount;

  /// Sign in button label
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordHint;

  /// Passwords do not match validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Username field hint text
  ///
  /// In en, this message translates to:
  /// **'Set a display name'**
  String get usernameHint;

  /// Username field helper text
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use email prefix'**
  String get usernameHelper;

  /// Link text to navigate to login page
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get hasAccount;

  /// Registration success toast message
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccess;

  /// Password strength indicator label
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get passwordStrength;

  /// Password strength level: weak
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// Password strength level: medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordStrengthMedium;

  /// Password strength level: good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordStrengthGood;

  /// Password strength level: strong
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// Password requirement: minimum length
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordMinLength;

  /// Password requirement: uppercase and lowercase
  ///
  /// In en, this message translates to:
  /// **'Contains uppercase & lowercase letters'**
  String get passwordUppercaseLowercase;

  /// Password requirement: contains a number
  ///
  /// In en, this message translates to:
  /// **'Contains a number'**
  String get passwordNumber;

  /// Password requirement: special character
  ///
  /// In en, this message translates to:
  /// **'Contains a special character'**
  String get passwordSpecial;

  /// Username length validation error
  ///
  /// In en, this message translates to:
  /// **'Username must be 3-30 characters'**
  String get usernameLengthError;

  /// Username invalid characters error
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, underscores and hyphens allowed'**
  String get usernameInvalidChars;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailFormatError;

  /// Password minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLengthError;

  /// Tooltip for password visibility toggle to show password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Tooltip for password visibility toggle to hide password
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Link text to navigate to register page from login
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccountRegister;

  /// Username field label with optional indicator
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get usernameOptional;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Edit profile section title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Profile information section title
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInfo;

  /// Label for account registration date
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// Change password section title
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Current password field label
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// New password field label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Profile update success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdateSuccess;

  /// Password change success message
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangeSuccess;

  /// Current password field validation error
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// New password field validation error
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// New password minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 8 characters'**
  String get newPasswordMinLength;

  /// Password settings section title
  ///
  /// In en, this message translates to:
  /// **'Password Settings'**
  String get passwordInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
