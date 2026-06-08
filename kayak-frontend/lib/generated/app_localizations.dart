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

  /// Bad request error message
  ///
  /// In en, this message translates to:
  /// **'Invalid request parameters, please check your input'**
  String get errorBadRequest;

  /// Forbidden error message
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action'**
  String get errorForbidden;

  /// Not found error message
  ///
  /// In en, this message translates to:
  /// **'Requested resource not found'**
  String get errorNotFound;

  /// Conflict error message
  ///
  /// In en, this message translates to:
  /// **'Resource conflict, please check for duplicates'**
  String get errorConflict;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Data validation failed, please check your input'**
  String get errorValidation;

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable, please try again later'**
  String get errorServer;

  /// Default error message
  ///
  /// In en, this message translates to:
  /// **'Operation failed, please try again'**
  String get errorDefault;

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

  /// Search bar placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search workbenches...'**
  String get workbenchSearchHint;

  /// Create workbench dialog title
  ///
  /// In en, this message translates to:
  /// **'Create Workbench'**
  String get workbenchCreate;

  /// Edit workbench dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Workbench'**
  String get workbenchEdit;

  /// Workbench name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workbenchName;

  /// Workbench description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get workbenchDescription;

  /// Workbench name field hint
  ///
  /// In en, this message translates to:
  /// **'Please enter workbench name'**
  String get workbenchNameHint;

  /// Workbench description field hint
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get workbenchDescriptionHint;

  /// Workbench name validation error
  ///
  /// In en, this message translates to:
  /// **'Workbench name is required'**
  String get workbenchNameRequired;

  /// Workbench name max length validation error
  ///
  /// In en, this message translates to:
  /// **'Name cannot exceed 255 characters'**
  String get workbenchNameMaxLength;

  /// Create workbench success toast
  ///
  /// In en, this message translates to:
  /// **'Workbench created successfully'**
  String get createWorkbenchSuccess;

  /// Update workbench success toast
  ///
  /// In en, this message translates to:
  /// **'Workbench updated successfully'**
  String get updateWorkbenchSuccess;

  /// Delete workbench success toast
  ///
  /// In en, this message translates to:
  /// **'Workbench deleted successfully'**
  String get deleteWorkbenchSuccess;

  /// Delete workbench confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete workbench?'**
  String get deleteWorkbenchTitle;

  /// Delete workbench confirmation dialog description
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete workbench \"{name}\"? This action cannot be undone. All devices and data under this workbench will be permanently deleted.'**
  String deleteWorkbenchDescription(String name);

  /// Load more pagination button
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// Total workbench count label
  ///
  /// In en, this message translates to:
  /// **'{count} workbenches total'**
  String totalCount(int count);

  /// Search no results message
  ///
  /// In en, this message translates to:
  /// **'No matching workbenches found'**
  String get searchNoResults;

  /// Search no results hint
  ///
  /// In en, this message translates to:
  /// **'Try modifying your search keywords'**
  String get searchNoResultsHint;

  /// Clear search button
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No workbenches yet'**
  String get emptyWorkbenchTitle;

  /// Empty state description
  ///
  /// In en, this message translates to:
  /// **'Create your first workbench by clicking the button below'**
  String get emptyWorkbenchDescription;

  /// Empty state action button
  ///
  /// In en, this message translates to:
  /// **'Create your first workbench'**
  String get emptyWorkbenchAction;

  /// Workbench detail page title
  ///
  /// In en, this message translates to:
  /// **'Workbench Details'**
  String get workbenchDetail;

  /// Device tree panel title
  ///
  /// In en, this message translates to:
  /// **'Device Tree'**
  String get deviceTree;

  /// Device detail panel title
  ///
  /// In en, this message translates to:
  /// **'Device Details'**
  String get deviceDetail;

  /// Device tree placeholder description
  ///
  /// In en, this message translates to:
  /// **'Will be implemented in the next Sprint'**
  String get deviceTreePlaceholder;

  /// Device detail placeholder description
  ///
  /// In en, this message translates to:
  /// **'Select a device to view details'**
  String get deviceDetailPlaceholder;

  /// Workbench not found error message
  ///
  /// In en, this message translates to:
  /// **'Workbench not found or has been deleted'**
  String get workbenchNotFound;

  /// Add device button
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDevice;

  /// Created at label
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// Last modified label
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get lastModified;

  /// Delete confirmation button label
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get deleteWorkbenchConfirm;

  /// Mobile short title
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get workbenchDetailShort;

  /// Device tree panel title
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get deviceTreeTitle;

  /// Device tree empty state
  ///
  /// In en, this message translates to:
  /// **'No devices yet'**
  String get noDevices;

  /// Add device dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDeviceDialogTitle;

  /// Edit device dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Device'**
  String get editDeviceDialogTitle;

  /// Device name field label
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// Device name field hint
  ///
  /// In en, this message translates to:
  /// **'Please enter device name'**
  String get deviceNameHint;

  /// Device name validation error
  ///
  /// In en, this message translates to:
  /// **'Device name is required'**
  String get deviceNameRequired;

  /// Device name max length validation
  ///
  /// In en, this message translates to:
  /// **'Name cannot exceed 255 characters'**
  String get deviceNameMaxLength;

  /// Protocol type field label
  ///
  /// In en, this message translates to:
  /// **'Protocol Type'**
  String get protocolType;

  /// Protocol type selection hint
  ///
  /// In en, this message translates to:
  /// **'Please select a protocol type'**
  String get protocolTypeHint;

  /// Protocol type validation error
  ///
  /// In en, this message translates to:
  /// **'Protocol type is required'**
  String get protocolTypeRequired;

  /// Virtual device protocol option
  ///
  /// In en, this message translates to:
  /// **'Virtual Device'**
  String get virtualDevice;

  /// Modbus TCP protocol option
  ///
  /// In en, this message translates to:
  /// **'Modbus TCP'**
  String get modbusTcp;

  /// Modbus RTU protocol option
  ///
  /// In en, this message translates to:
  /// **'Modbus RTU'**
  String get modbusRtu;

  /// Virtual mode field label
  ///
  /// In en, this message translates to:
  /// **'Virtual Mode'**
  String get virtualMode;

  /// Virtual mode selection hint
  ///
  /// In en, this message translates to:
  /// **'Please select a virtual mode'**
  String get virtualModeHint;

  /// Virtual mode validation error
  ///
  /// In en, this message translates to:
  /// **'Virtual mode is required'**
  String get virtualModeRequired;

  /// Random mode
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// Sine wave mode
  ///
  /// In en, this message translates to:
  /// **'Sine Wave'**
  String get sineWave;

  /// Fixed value mode
  ///
  /// In en, this message translates to:
  /// **'Fixed Value'**
  String get fixedValue;

  /// Increment mode
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get increment;

  /// Data type field label
  ///
  /// In en, this message translates to:
  /// **'Data Type'**
  String get dataType;

  /// Data type selection hint
  ///
  /// In en, this message translates to:
  /// **'Please select a data type'**
  String get dataTypeHint;

  /// Data type validation error
  ///
  /// In en, this message translates to:
  /// **'Data type is required'**
  String get dataTypeRequired;

  /// Value range field label
  ///
  /// In en, this message translates to:
  /// **'Value Range'**
  String get valueRange;

  /// Minimum value field label
  ///
  /// In en, this message translates to:
  /// **'Min Value'**
  String get minValue;

  /// Maximum value field label
  ///
  /// In en, this message translates to:
  /// **'Max Value'**
  String get maxValue;

  /// Update interval field label
  ///
  /// In en, this message translates to:
  /// **'Update Interval'**
  String get updateInterval;

  /// Milliseconds unit
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get ms;

  /// Host address field label
  ///
  /// In en, this message translates to:
  /// **'Host Address'**
  String get hostAddress;

  /// Host address field hint
  ///
  /// In en, this message translates to:
  /// **'192.168.1.100'**
  String get hostAddressHint;

  /// Host address validation error
  ///
  /// In en, this message translates to:
  /// **'Host address is required'**
  String get hostAddressRequired;

  /// Host address format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid IPv4 address'**
  String get hostAddressInvalid;

  /// Port field label
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// Port field hint
  ///
  /// In en, this message translates to:
  /// **'502'**
  String get portHint;

  /// Port validation error
  ///
  /// In en, this message translates to:
  /// **'Port is required'**
  String get portRequired;

  /// Port range validation error
  ///
  /// In en, this message translates to:
  /// **'Port must be an integer between 1-65535'**
  String get portInvalid;

  /// Slave ID field label
  ///
  /// In en, this message translates to:
  /// **'Slave ID'**
  String get slaveId;

  /// Slave ID field hint
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get slaveIdHint;

  /// Slave ID validation error
  ///
  /// In en, this message translates to:
  /// **'Slave ID must be an integer between 1-247'**
  String get slaveIdInvalid;

  /// Timeout field label
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get timeout;

  /// Timeout field hint
  ///
  /// In en, this message translates to:
  /// **'5000'**
  String get timeoutHint;

  /// Serial port field label
  ///
  /// In en, this message translates to:
  /// **'Serial Port'**
  String get serialPort;

  /// Serial port selection hint
  ///
  /// In en, this message translates to:
  /// **'Please select a serial port'**
  String get serialPortHint;

  /// Serial port validation error
  ///
  /// In en, this message translates to:
  /// **'Serial port is required'**
  String get serialPortRequired;

  /// Baud rate field label
  ///
  /// In en, this message translates to:
  /// **'Baud Rate'**
  String get baudRate;

  /// Baud rate selection hint
  ///
  /// In en, this message translates to:
  /// **'Please select a baud rate'**
  String get baudRateHint;

  /// Data bits field label
  ///
  /// In en, this message translates to:
  /// **'Data Bits'**
  String get dataBits;

  /// Stop bits field label
  ///
  /// In en, this message translates to:
  /// **'Stop Bits'**
  String get stopBits;

  /// Parity field label
  ///
  /// In en, this message translates to:
  /// **'Parity'**
  String get parity;

  /// None option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Odd parity option
  ///
  /// In en, this message translates to:
  /// **'Odd'**
  String get oddParity;

  /// Even parity option
  ///
  /// In en, this message translates to:
  /// **'Even'**
  String get evenParity;

  /// Advanced information section title
  ///
  /// In en, this message translates to:
  /// **'Advanced Information'**
  String get advancedInfo;

  /// Manufacturer field label
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get manufacturer;

  /// Manufacturer field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Siemens'**
  String get manufacturerHint;

  /// Model field label
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelName;

  /// Model field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. S7-1200'**
  String get modelHint;

  /// Serial number field label
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// Serial number field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. SN123456'**
  String get serialNumberHint;

  /// Device save success toast
  ///
  /// In en, this message translates to:
  /// **'Device saved successfully'**
  String get deviceSaveSuccess;

  /// Delete device confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Device?'**
  String get deviceDeleteTitle;

  /// Delete device confirmation dialog description
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete device \"{name}\"?'**
  String deviceDeleteDescription(String name);

  /// Device delete success toast
  ///
  /// In en, this message translates to:
  /// **'Device deleted successfully'**
  String get deviceDeleteSuccess;

  /// Edit device action button
  ///
  /// In en, this message translates to:
  /// **'Edit Device'**
  String get editDevice;

  /// Add sub-device action button
  ///
  /// In en, this message translates to:
  /// **'Add Sub-Device'**
  String get addSubDevice;

  /// Delete device action button
  ///
  /// In en, this message translates to:
  /// **'Delete Device'**
  String get deleteDevice;

  /// Confirm delete device button
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteDevice;

  /// Basic information section title
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// Protocol configuration section title
  ///
  /// In en, this message translates to:
  /// **'Protocol Configuration'**
  String get protocolConfig;

  /// Valid number validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get validNumberRequired;

  /// Max must be greater than min validation error
  ///
  /// In en, this message translates to:
  /// **'Maximum must be greater than minimum'**
  String get maxGreaterThanMin;

  /// Min interval validation error
  ///
  /// In en, this message translates to:
  /// **'Interval cannot be less than 100ms'**
  String get minIntervalMs;

  /// Min timeout validation error
  ///
  /// In en, this message translates to:
  /// **'Timeout cannot be less than 100ms'**
  String get minTimeoutMs;

  /// Baud rate required validation error
  ///
  /// In en, this message translates to:
  /// **'Baud rate is required'**
  String get baudRateRequired;

  /// Max 255 characters validation error
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed 255 characters'**
  String get max255Chars;

  /// Point list widget title
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointListTitle;

  /// Point count text in header
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String pointCount(int count);

  /// Add point button
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get addPoint;

  /// Add first point button in empty state
  ///
  /// In en, this message translates to:
  /// **'Add First Point'**
  String get addFirstPoint;

  /// Empty state text for point list
  ///
  /// In en, this message translates to:
  /// **'No points for this device'**
  String get pointListEmpty;

  /// Point name required validation error
  ///
  /// In en, this message translates to:
  /// **'Point name is required'**
  String get pointNameRequired;

  /// Point name max length validation error
  ///
  /// In en, this message translates to:
  /// **'Name must not exceed 255 characters'**
  String get pointNameTooLong;

  /// Point save success toast message
  ///
  /// In en, this message translates to:
  /// **'Point saved'**
  String get pointSaveSuccess;

  /// Point delete success toast message
  ///
  /// In en, this message translates to:
  /// **'Point deleted'**
  String get pointDeleteSuccess;

  /// Delete point confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete point \"{name}\"?'**
  String pointDeleteConfirm(String name);

  /// Delete point confirmation dialog description
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get pointDeleteWarning;

  /// Range validation error
  ///
  /// In en, this message translates to:
  /// **'Max must be greater than min'**
  String get pointRangeInvalid;

  /// Point status normal tooltip
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get pointStatusNormal;

  /// Point status timeout tooltip
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get pointStatusTimeout;

  /// Point status error tooltip
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get pointStatusError;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Point name field label in form
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pointNameLabel;

  /// Point name field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter point name'**
  String get pointNameHint;

  /// Data type field label in form
  ///
  /// In en, this message translates to:
  /// **'Data Type'**
  String get pointDataTypeLabel;

  /// Access type field label in form
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get pointAccessTypeLabel;

  /// Unit field label in form
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get pointUnitLabel;

  /// Modbus configuration section title
  ///
  /// In en, this message translates to:
  /// **'Modbus Configuration'**
  String get pointModbusConfig;

  /// Register type field label
  ///
  /// In en, this message translates to:
  /// **'Register Type'**
  String get pointRegisterTypeLabel;

  /// Start address field label
  ///
  /// In en, this message translates to:
  /// **'Start Address'**
  String get pointAddressLabel;

  /// Address range validation error
  ///
  /// In en, this message translates to:
  /// **'Address must be 0-65535'**
  String get pointAddressRange;

  /// Data format field label
  ///
  /// In en, this message translates to:
  /// **'Data Format'**
  String get pointDataFormatLabel;

  /// Table column header for name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pointColumnName;

  /// Table column header for type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get pointColumnType;

  /// Table column header for access
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get pointColumnAccess;

  /// Table column header for unit
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get pointColumnUnit;

  /// Table column header for value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get pointColumnValue;

  /// Table column header for actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get pointColumnAction;

  /// Data type option: number
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get dataTypeNumber;

  /// Data type option: integer
  ///
  /// In en, this message translates to:
  /// **'Integer'**
  String get dataTypeInteger;

  /// Data type option: boolean
  ///
  /// In en, this message translates to:
  /// **'Boolean'**
  String get dataTypeBoolean;

  /// Data type option: string
  ///
  /// In en, this message translates to:
  /// **'String'**
  String get dataTypeString;

  /// Access type option: read only
  ///
  /// In en, this message translates to:
  /// **'Read Only'**
  String get accessTypeRo;

  /// Access type option: write only
  ///
  /// In en, this message translates to:
  /// **'Write Only'**
  String get accessTypeWo;

  /// Access type option: read and write
  ///
  /// In en, this message translates to:
  /// **'Read & Write'**
  String get accessTypeRw;

  /// Boolean true display text
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get booleanTrue;

  /// Boolean false display text
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get booleanFalse;

  /// Generic form field required validation error
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// Point save failure toast message
  ///
  /// In en, this message translates to:
  /// **'Failed to save point'**
  String get pointSaveFailed;

  /// Point delete failure toast message
  ///
  /// In en, this message translates to:
  /// **'Failed to delete point'**
  String get pointDeleteFailed;

  /// Min value field label in form
  ///
  /// In en, this message translates to:
  /// **'Min Value'**
  String get pointMinValueLabel;

  /// Max value field label in form
  ///
  /// In en, this message translates to:
  /// **'Max Value'**
  String get pointMaxValueLabel;

  /// Default value field label in form
  ///
  /// In en, this message translates to:
  /// **'Default Value'**
  String get pointDefaultValueLabel;

  /// Edit point dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Point'**
  String get editPoint;

  /// Add point dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get addPointTitle;

  /// Experiment status: idle
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get statusIdle;

  /// Experiment status: loaded
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get statusLoaded;

  /// Experiment status: running
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// Experiment status: paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// Experiment status: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Experiment status: aborted
  ///
  /// In en, this message translates to:
  /// **'Aborted'**
  String get statusAborted;

  /// Experiment status: unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// Dropdown option to show all experiment statuses
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// Filter bar status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// Filter bar date range label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDateRange;

  /// Reset filter button
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilter;

  /// Empty state title for experiment list
  ///
  /// In en, this message translates to:
  /// **'No experiments yet'**
  String get noExperiments;

  /// Empty state description for experiment list
  ///
  /// In en, this message translates to:
  /// **'Create your first experiment to get started'**
  String get noExperimentsHint;

  /// Empty state create experiment button
  ///
  /// In en, this message translates to:
  /// **'Create First Experiment'**
  String get createFirstExperiment;

  /// No results after filtering
  ///
  /// In en, this message translates to:
  /// **'No matching experiments'**
  String get noFilteredResults;

  /// No results hint after filtering
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter criteria'**
  String get noFilteredResultsHint;

  /// Clear all filters button
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilter;

  /// Error state title
  ///
  /// In en, this message translates to:
  /// **'Failed to load experiments'**
  String get loadFailed;

  /// Error state hint
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again'**
  String get loadFailedHint;

  /// Total record count label
  ///
  /// In en, this message translates to:
  /// **'{count} records total'**
  String totalRecords(int count);

  /// Page indicator for mobile
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOf(int current, int total);

  /// Page size selector label
  ///
  /// In en, this message translates to:
  /// **'Rows per page'**
  String get recordsPerPage;

  /// Table column: experiment name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get columnName;

  /// Table column: method name
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get columnMethod;

  /// Table column: status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get columnStatus;

  /// Table column: start time
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get columnStartTime;

  /// Table column: duration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get columnDuration;

  /// Table column: actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get columnActions;

  /// Open experiment console action
  ///
  /// In en, this message translates to:
  /// **'Open Console'**
  String get openConsole;

  /// Stop experiment action
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopExperiment;

  /// Stop confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Stop'**
  String get confirmStopTitle;

  /// Stop confirmation dialog description
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop experiment \"{name}\"?'**
  String confirmStopDesc(String name);

  /// Stop success toast
  ///
  /// In en, this message translates to:
  /// **'Experiment stopped'**
  String get experimentStopped;

  /// Stop failure toast
  ///
  /// In en, this message translates to:
  /// **'Failed to stop experiment: {reason}'**
  String stopFailed(String reason);

  /// Create experiment button
  ///
  /// In en, this message translates to:
  /// **'Create Experiment'**
  String get createExperiment;

  /// Placeholder for not started time
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get notStarted;

  /// Placeholder for no method set
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get methodNotSet;

  /// Experiment create page title
  ///
  /// In en, this message translates to:
  /// **'Create Experiment'**
  String get createExperimentTitle;

  /// Stepper step 1 label
  ///
  /// In en, this message translates to:
  /// **'Select Workbench'**
  String get stepSelectWorkbench;

  /// Stepper step 2 label
  ///
  /// In en, this message translates to:
  /// **'Select Method'**
  String get stepSelectMethod;

  /// Stepper step 3 label
  ///
  /// In en, this message translates to:
  /// **'Configure Parameters'**
  String get stepConfigureParams;

  /// Stepper step 4 label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get stepConfirm;

  /// Stepper step 1 short label (mobile)
  ///
  /// In en, this message translates to:
  /// **'Workbench'**
  String get stepWorkbenchShort;

  /// Stepper step 2 short label (mobile)
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get stepMethodShort;

  /// Stepper step 3 short label (mobile)
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get stepParamsShort;

  /// Stepper step 4 short label (mobile)
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get stepConfirmShort;

  /// Step 1 section title
  ///
  /// In en, this message translates to:
  /// **'Select Workbench'**
  String get selectWorkbenchTitle;

  /// Step 1 section subtitle
  ///
  /// In en, this message translates to:
  /// **'Please select a workbench for this experiment'**
  String get selectWorkbenchSubtitle;

  /// Morning greeting (06:00-11:59)
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// Afternoon greeting (12:00-17:59)
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// Evening greeting (18:00-05:59)
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// Quick action card title: experiment console
  ///
  /// In en, this message translates to:
  /// **'Experiment Console'**
  String get quickActionExperimentConsole;

  /// Quick action card subtitle: experiment console
  ///
  /// In en, this message translates to:
  /// **'Manage and run experiments'**
  String get quickActionExperimentConsoleSub;

  /// Quick action card title: methods
  ///
  /// In en, this message translates to:
  /// **'Methods'**
  String get quickActionMethods;

  /// Quick action card subtitle: methods
  ///
  /// In en, this message translates to:
  /// **'Configure standard methods'**
  String get quickActionMethodsSub;

  /// Quick action card title: workbenches
  ///
  /// In en, this message translates to:
  /// **'Workbenches'**
  String get quickActionWorkbenches;

  /// Quick action card subtitle: workbenches
  ///
  /// In en, this message translates to:
  /// **'Manage workbenches and devices'**
  String get quickActionWorkbenchesSub;

  /// Quick action card title: data analysis
  ///
  /// In en, this message translates to:
  /// **'Data Analysis'**
  String get quickActionDataAnalysis;

  /// Quick action card subtitle: data analysis
  ///
  /// In en, this message translates to:
  /// **'View experiment data'**
  String get quickActionDataAnalysisSub;

  /// Stats overview label: workbenches
  ///
  /// In en, this message translates to:
  /// **'Workbenches'**
  String get statsWorkbenchesLabel;

  /// Stats overview label: devices
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get statsDevicesLabel;

  /// Stats overview label: experiments
  ///
  /// In en, this message translates to:
  /// **'Experiments'**
  String get statsExperimentsLabel;

  /// Recent workbenches section header
  ///
  /// In en, this message translates to:
  /// **'Recent Workbenches'**
  String get recentWorkbenches;

  /// View all link text
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// Relative time: less than 1 minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Relative time: N minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// Relative time: N hours ago
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// Relative time: N days ago
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Relative time: N weeks ago
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(int count);

  /// Relative time: N months ago
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(int count);

  /// Error title for stats overview section
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics'**
  String get dashboardStatsError;

  /// Error description for stats overview section
  ///
  /// In en, this message translates to:
  /// **'Please check your network and retry'**
  String get dashboardStatsErrorHint;

  /// Error title for recent workbenches section
  ///
  /// In en, this message translates to:
  /// **'Failed to load workbenches'**
  String get dashboardRecentError;

  /// Error description for recent workbenches section
  ///
  /// In en, this message translates to:
  /// **'Please check your network and retry'**
  String get dashboardRecentErrorHint;

  /// Empty state title for recent workbenches
  ///
  /// In en, this message translates to:
  /// **'No workbenches yet'**
  String get dashboardRecentEmpty;

  /// Empty state description for recent workbenches
  ///
  /// In en, this message translates to:
  /// **'Create your first workbench to get started'**
  String get dashboardRecentEmptyHint;

  /// Empty state action button for recent workbenches
  ///
  /// In en, this message translates to:
  /// **'Create Your First Workbench'**
  String get dashboardRecentEmptyAction;

  /// Device count label on workbench card
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String deviceCountWithUnit(int count);

  /// Retry button for stats section
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLoadStats;

  /// Retry button for recent workbenches section
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLoadRecent;

  /// Greeting text with username
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {username}'**
  String greetingWithName(String greeting, String username);

  /// Step 1 empty state title
  ///
  /// In en, this message translates to:
  /// **'No workbenches yet'**
  String get noWorkbenchesTitle;

  /// Step 1 empty state description
  ///
  /// In en, this message translates to:
  /// **'Create your first workbench by clicking the button below'**
  String get noWorkbenchesDescription;

  /// Step 1 empty state action button
  ///
  /// In en, this message translates to:
  /// **'Create Your First Workbench'**
  String get createFirstWorkbench;

  /// Step 1 error state title
  ///
  /// In en, this message translates to:
  /// **'Failed to load workbenches'**
  String get loadWorkbenchesFailed;

  /// Step 1 error state hint
  ///
  /// In en, this message translates to:
  /// **'Please check your network and try again'**
  String get loadWorkbenchesFailedHint;

  /// Device count on workbench card
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String deviceCount(int count);

  /// Step 2 section title
  ///
  /// In en, this message translates to:
  /// **'Select Method'**
  String get selectMethodTitle;

  /// Step 2 section subtitle
  ///
  /// In en, this message translates to:
  /// **'Please select a method for this experiment'**
  String get selectMethodSubtitle;

  /// Step 2 empty state title
  ///
  /// In en, this message translates to:
  /// **'No methods available'**
  String get noMethodsTitle;

  /// Step 2 empty state description
  ///
  /// In en, this message translates to:
  /// **'Please create an experiment method first'**
  String get noMethodsDescription;

  /// Step 2 empty state action button
  ///
  /// In en, this message translates to:
  /// **'Go to Methods'**
  String get goToMethods;

  /// Step 2 error state title
  ///
  /// In en, this message translates to:
  /// **'Failed to load methods'**
  String get loadMethodsFailed;

  /// Step 2 error state hint
  ///
  /// In en, this message translates to:
  /// **'Please check your network and try again'**
  String get loadMethodsFailedHint;

  /// Method parameter count on card
  ///
  /// In en, this message translates to:
  /// **'{count} parameters'**
  String paramCount(int count);

  /// Step 3 section title
  ///
  /// In en, this message translates to:
  /// **'Configure Parameters'**
  String get configureParamsTitle;

  /// Step 3 section subtitle
  ///
  /// In en, this message translates to:
  /// **'Configure the parameters for the selected method'**
  String get configureParamsSubtitle;

  /// Info banner when method has no parameters
  ///
  /// In en, this message translates to:
  /// **'No parameters required'**
  String get noParamsRequired;

  /// Info banner hint text
  ///
  /// In en, this message translates to:
  /// **'Click Next to continue'**
  String get noParamsHint;

  /// Step 4 section title
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmTitle;

  /// Step 4 section subtitle
  ///
  /// In en, this message translates to:
  /// **'Please confirm the following information'**
  String get confirmSubtitle;

  /// Summary section label for workbench
  ///
  /// In en, this message translates to:
  /// **'Workbench'**
  String get summaryWorkbench;

  /// Summary section label for method
  ///
  /// In en, this message translates to:
  /// **'Experiment Method'**
  String get summaryMethod;

  /// Summary section label for parameters
  ///
  /// In en, this message translates to:
  /// **'Parameter Configuration'**
  String get summaryParams;

  /// Warning text before creation
  ///
  /// In en, this message translates to:
  /// **'The experiment will start running immediately after creation'**
  String get createWarning;

  /// Next step button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// Previous step button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get previousStep;

  /// Creating button loading state
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// Create experiment success toast
  ///
  /// In en, this message translates to:
  /// **'Experiment created successfully'**
  String get createExperimentSuccess;

  /// Create experiment failure toast
  ///
  /// In en, this message translates to:
  /// **'Failed to create experiment: {reason}'**
  String createExperimentFailed(String reason);

  /// Validation error for required form field
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequiredValidation;

  /// Integer type validation error
  ///
  /// In en, this message translates to:
  /// **'Must be an integer'**
  String get mustBeInteger;

  /// Range validation: less than minimum
  ///
  /// In en, this message translates to:
  /// **'Cannot be less than {min}'**
  String cannotBeLessThan(String min);

  /// Range validation: greater than maximum
  ///
  /// In en, this message translates to:
  /// **'Cannot be greater than {max}'**
  String cannotBeGreaterThan(String max);

  /// Generic format validation error
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get invalidFormat;

  /// Fallback when workbench name is null
  ///
  /// In en, this message translates to:
  /// **'Unnamed Workbench'**
  String get unnamedWorkbench;

  /// Fallback when method name is null
  ///
  /// In en, this message translates to:
  /// **'Unnamed Method'**
  String get unnamedMethod;

  /// Tooltip when create button is disabled
  ///
  /// In en, this message translates to:
  /// **'Please select a workbench and method first'**
  String get createTooltipIncomplete;

  /// Warning in Step 3 and Step 4 that parameters are not persisted yet
  ///
  /// In en, this message translates to:
  /// **'Note: Parameter values are for reference in this session only and will not be persisted in this version.'**
  String get paramsNotPersistedWarning;

  /// Back button tooltip on experiment console
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get backToList;

  /// Status label in experiment console
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// Timer label for running experiments
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get elapsedLabel;

  /// Timer label when experiment is paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get elapsedPaused;

  /// Method label in experiment info card
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get methodLabel;

  /// Error title when experiment is not found
  ///
  /// In en, this message translates to:
  /// **'Experiment not found'**
  String get experimentNotFound;

  /// Error description when experiment is not found
  ///
  /// In en, this message translates to:
  /// **'Invalid experiment ID, please check the link or go back to the list'**
  String get experimentNotFoundHint;

  /// Error title when user lacks permission
  ///
  /// In en, this message translates to:
  /// **'No permission to access this experiment'**
  String get experimentNoPermission;

  /// Load method button on experiment console
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get actionLoad;

  /// Start experiment button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// Pause experiment button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// Resume experiment button
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// Stop experiment button
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// WebSocket disconnected status
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get wsDisconnected;

  /// WebSocket connecting status
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get wsConnecting;

  /// WebSocket connected status
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get wsConnected;

  /// WebSocket reconnecting status
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get wsReconnecting;

  /// WebSocket connection failed status
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get wsFailed;

  /// WebSocket reconnect button
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get wsReconnect;

  /// Empty log state title
  ///
  /// In en, this message translates to:
  /// **'Waiting for logs...'**
  String get logEmptyTitle;

  /// Empty log state description
  ///
  /// In en, this message translates to:
  /// **'Logs will appear when experiment starts'**
  String get logEmptyHint;

  /// Label for new logs floating button
  ///
  /// In en, this message translates to:
  /// **'new logs'**
  String get newLogsLabel;

  /// Log level filter: show all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAllLabel;

  /// Clear logs button label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLogsLabel;

  /// Stop confirmation button label
  ///
  /// In en, this message translates to:
  /// **'Confirm Stop'**
  String get confirmStopAction;

  /// Start experiment success toast
  ///
  /// In en, this message translates to:
  /// **'Experiment started'**
  String get experimentStarted;

  /// Pause experiment success toast
  ///
  /// In en, this message translates to:
  /// **'Experiment paused'**
  String get experimentPaused;

  /// Resume experiment success toast
  ///
  /// In en, this message translates to:
  /// **'Experiment resumed'**
  String get experimentResumed;

  /// Load method success toast
  ///
  /// In en, this message translates to:
  /// **'Method loaded'**
  String get methodLoaded;

  /// Generic operation failure toast
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// Status subtitle when experiment is completed
  ///
  /// In en, this message translates to:
  /// **'Experiment completed'**
  String get statusCompletedHint;

  /// Status subtitle when experiment is running
  ///
  /// In en, this message translates to:
  /// **'Experiment running'**
  String get statusRunningHint;

  /// Status subtitle when experiment is aborted
  ///
  /// In en, this message translates to:
  /// **'Experiment aborted'**
  String get statusAbortedHint;

  /// Start time label in completed info
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get startedLabel;

  /// End time label in completed info
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get endedLabel;

  /// Total duration label in completed info
  ///
  /// In en, this message translates to:
  /// **'Total Duration'**
  String get totalDurationLabel;
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
