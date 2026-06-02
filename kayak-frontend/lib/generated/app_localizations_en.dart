// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kayak';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get workbenches => 'Workbenches';

  @override
  String get methods => 'Methods';

  @override
  String get experiments => 'Experiments';

  @override
  String get analysis => 'Analysis';

  @override
  String get settings => 'Settings';

  @override
  String get workbenchList => 'Workbench List';

  @override
  String get methodList => 'Method List';

  @override
  String get experimentList => 'Experiment List';

  @override
  String get loginError => 'Invalid email or password';

  @override
  String get networkError => 'Network error, please check connection';

  @override
  String get sessionExpired => 'Session expired, please login again';

  @override
  String get errorBadRequest =>
      'Invalid request parameters, please check your input';

  @override
  String get errorForbidden =>
      'You don\'t have permission to perform this action';

  @override
  String get errorNotFound => 'Requested resource not found';

  @override
  String get errorConflict => 'Resource conflict, please check for duplicates';

  @override
  String get errorValidation =>
      'Data validation failed, please check your input';

  @override
  String get errorServer =>
      'Service temporarily unavailable, please try again later';

  @override
  String get errorDefault => 'Operation failed, please try again';

  @override
  String get noData => 'No data available';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get search => 'Search';

  @override
  String get submit => 'Submit';

  @override
  String get emailHint => 'Please enter your email';

  @override
  String get passwordHint => 'Please enter your password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get signIn => 'Sign In';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get usernameHint => 'Set a display name';

  @override
  String get usernameHelper => 'Leave blank to use email prefix';

  @override
  String get hasAccount => 'Already have an account? Login';

  @override
  String get registrationSuccess => 'Registration successful!';

  @override
  String get passwordStrength => 'Password strength';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordMinLength => 'At least 8 characters';

  @override
  String get passwordUppercaseLowercase =>
      'Contains uppercase & lowercase letters';

  @override
  String get passwordNumber => 'Contains a number';

  @override
  String get passwordSpecial => 'Contains a special character';

  @override
  String get usernameLengthError => 'Username must be 3-30 characters';

  @override
  String get usernameInvalidChars =>
      'Only letters, numbers, underscores and hyphens allowed';

  @override
  String get emailFormatError => 'Please enter a valid email address';

  @override
  String get passwordMinLengthError => 'Password must be at least 8 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get noAccountRegister => 'Don\'t have an account? Register';

  @override
  String get usernameOptional => 'Username (optional)';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileInfo => 'Profile Information';

  @override
  String get memberSince => 'Member since';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String get passwordChangeSuccess => 'Password changed successfully';

  @override
  String get currentPasswordRequired => 'Current password is required';

  @override
  String get newPasswordRequired => 'New password is required';

  @override
  String get newPasswordMinLength =>
      'New password must be at least 8 characters';

  @override
  String get passwordInfo => 'Password Settings';

  @override
  String get workbenchSearchHint => 'Search workbenches...';

  @override
  String get workbenchCreate => 'Create Workbench';

  @override
  String get workbenchEdit => 'Edit Workbench';

  @override
  String get workbenchName => 'Name';

  @override
  String get workbenchDescription => 'Description';

  @override
  String get workbenchNameHint => 'Please enter workbench name';

  @override
  String get workbenchDescriptionHint => 'Description (optional)';

  @override
  String get workbenchNameRequired => 'Workbench name is required';

  @override
  String get workbenchNameMaxLength => 'Name cannot exceed 255 characters';

  @override
  String get createWorkbenchSuccess => 'Workbench created successfully';

  @override
  String get updateWorkbenchSuccess => 'Workbench updated successfully';

  @override
  String get deleteWorkbenchSuccess => 'Workbench deleted successfully';

  @override
  String get deleteWorkbenchTitle => 'Delete workbench?';

  @override
  String deleteWorkbenchDescription(String name) {
    return 'Are you sure you want to delete workbench \"$name\"? This action cannot be undone. All devices and data under this workbench will be permanently deleted.';
  }

  @override
  String get loadMore => 'Load more';

  @override
  String totalCount(int count) {
    return '$count workbenches total';
  }

  @override
  String get searchNoResults => 'No matching workbenches found';

  @override
  String get searchNoResultsHint => 'Try modifying your search keywords';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get emptyWorkbenchTitle => 'No workbenches yet';

  @override
  String get emptyWorkbenchDescription =>
      'Create your first workbench by clicking the button below';

  @override
  String get emptyWorkbenchAction => 'Create your first workbench';

  @override
  String get workbenchDetail => 'Workbench Details';

  @override
  String get deviceTree => 'Device Tree';

  @override
  String get deviceDetail => 'Device Details';

  @override
  String get deviceTreePlaceholder => 'Will be implemented in the next Sprint';

  @override
  String get deviceDetailPlaceholder => 'Select a device to view details';

  @override
  String get workbenchNotFound => 'Workbench not found or has been deleted';

  @override
  String get addDevice => 'Add Device';

  @override
  String get createdAt => 'Created at';

  @override
  String get lastModified => 'Last modified';

  @override
  String get deleteWorkbenchConfirm => 'Confirm Delete';

  @override
  String get workbenchDetailShort => 'Details';

  @override
  String get deviceTreeTitle => 'Devices';

  @override
  String get noDevices => 'No devices yet';

  @override
  String get addDeviceDialogTitle => 'Add Device';

  @override
  String get editDeviceDialogTitle => 'Edit Device';

  @override
  String get deviceName => 'Device Name';

  @override
  String get deviceNameHint => 'Please enter device name';

  @override
  String get deviceNameRequired => 'Device name is required';

  @override
  String get deviceNameMaxLength => 'Name cannot exceed 255 characters';

  @override
  String get protocolType => 'Protocol Type';

  @override
  String get protocolTypeHint => 'Please select a protocol type';

  @override
  String get protocolTypeRequired => 'Protocol type is required';

  @override
  String get virtualDevice => 'Virtual Device';

  @override
  String get modbusTcp => 'Modbus TCP';

  @override
  String get modbusRtu => 'Modbus RTU';

  @override
  String get virtualMode => 'Virtual Mode';

  @override
  String get virtualModeHint => 'Please select a virtual mode';

  @override
  String get virtualModeRequired => 'Virtual mode is required';

  @override
  String get random => 'Random';

  @override
  String get sineWave => 'Sine Wave';

  @override
  String get fixedValue => 'Fixed Value';

  @override
  String get increment => 'Increment';

  @override
  String get dataType => 'Data Type';

  @override
  String get dataTypeHint => 'Please select a data type';

  @override
  String get dataTypeRequired => 'Data type is required';

  @override
  String get valueRange => 'Value Range';

  @override
  String get minValue => 'Min Value';

  @override
  String get maxValue => 'Max Value';

  @override
  String get updateInterval => 'Update Interval';

  @override
  String get ms => 'ms';

  @override
  String get hostAddress => 'Host Address';

  @override
  String get hostAddressHint => '192.168.1.100';

  @override
  String get hostAddressRequired => 'Host address is required';

  @override
  String get hostAddressInvalid => 'Please enter a valid IPv4 address';

  @override
  String get port => 'Port';

  @override
  String get portHint => '502';

  @override
  String get portRequired => 'Port is required';

  @override
  String get portInvalid => 'Port must be an integer between 1-65535';

  @override
  String get slaveId => 'Slave ID';

  @override
  String get slaveIdHint => '1';

  @override
  String get slaveIdInvalid => 'Slave ID must be an integer between 1-247';

  @override
  String get timeout => 'Timeout';

  @override
  String get timeoutHint => '5000';

  @override
  String get serialPort => 'Serial Port';

  @override
  String get serialPortHint => 'Please select a serial port';

  @override
  String get serialPortRequired => 'Serial port is required';

  @override
  String get baudRate => 'Baud Rate';

  @override
  String get baudRateHint => 'Please select a baud rate';

  @override
  String get dataBits => 'Data Bits';

  @override
  String get stopBits => 'Stop Bits';

  @override
  String get parity => 'Parity';

  @override
  String get none => 'None';

  @override
  String get oddParity => 'Odd';

  @override
  String get evenParity => 'Even';

  @override
  String get advancedInfo => 'Advanced Information';

  @override
  String get manufacturer => 'Manufacturer';

  @override
  String get manufacturerHint => 'e.g. Siemens';

  @override
  String get modelName => 'Model';

  @override
  String get modelHint => 'e.g. S7-1200';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get serialNumberHint => 'e.g. SN123456';

  @override
  String get deviceSaveSuccess => 'Device saved successfully';

  @override
  String get deviceDeleteTitle => 'Delete Device?';

  @override
  String deviceDeleteDescription(String name) {
    return 'Are you sure you want to delete device \"$name\"?';
  }

  @override
  String get deviceDeleteSuccess => 'Device deleted successfully';

  @override
  String get editDevice => 'Edit Device';

  @override
  String get addSubDevice => 'Add Sub-Device';

  @override
  String get deleteDevice => 'Delete Device';

  @override
  String get confirmDeleteDevice => 'Confirm Delete';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get protocolConfig => 'Protocol Configuration';

  @override
  String get validNumberRequired => 'Please enter a valid number';

  @override
  String get maxGreaterThanMin => 'Maximum must be greater than minimum';

  @override
  String get minIntervalMs => 'Interval cannot be less than 100ms';

  @override
  String get minTimeoutMs => 'Timeout cannot be less than 100ms';

  @override
  String get baudRateRequired => 'Baud rate is required';

  @override
  String get max255Chars => 'Cannot exceed 255 characters';

  @override
  String get pointListTitle => 'Points';

  @override
  String pointCount(int count) {
    return '$count points';
  }

  @override
  String get addPoint => 'Add Point';

  @override
  String get addFirstPoint => 'Add First Point';

  @override
  String get pointListEmpty => 'No points for this device';

  @override
  String get pointNameRequired => 'Point name is required';

  @override
  String get pointNameTooLong => 'Name must not exceed 255 characters';

  @override
  String get pointSaveSuccess => 'Point saved';

  @override
  String get pointDeleteSuccess => 'Point deleted';

  @override
  String pointDeleteConfirm(String name) {
    return 'Delete point \"$name\"?';
  }

  @override
  String get pointDeleteWarning => 'This action cannot be undone.';

  @override
  String get pointRangeInvalid => 'Max must be greater than min';

  @override
  String get pointStatusNormal => 'Normal';

  @override
  String get pointStatusTimeout => 'Timeout';

  @override
  String get pointStatusError => 'Error';

  @override
  String get refresh => 'Refresh';

  @override
  String get pointNameLabel => 'Name';

  @override
  String get pointNameHint => 'Enter point name';

  @override
  String get pointDataTypeLabel => 'Data Type';

  @override
  String get pointAccessTypeLabel => 'Access';

  @override
  String get pointUnitLabel => 'Unit';

  @override
  String get pointModbusConfig => 'Modbus Configuration';

  @override
  String get pointRegisterTypeLabel => 'Register Type';

  @override
  String get pointAddressLabel => 'Start Address';

  @override
  String get pointAddressRange => 'Address must be 0-65535';

  @override
  String get pointDataFormatLabel => 'Data Format';

  @override
  String get pointColumnName => 'Name';

  @override
  String get pointColumnType => 'Type';

  @override
  String get pointColumnAccess => 'Access';

  @override
  String get pointColumnUnit => 'Unit';

  @override
  String get pointColumnValue => 'Value';

  @override
  String get pointColumnAction => 'Actions';

  @override
  String get dataTypeNumber => 'Number';

  @override
  String get dataTypeInteger => 'Integer';

  @override
  String get dataTypeBoolean => 'Boolean';

  @override
  String get dataTypeString => 'String';

  @override
  String get accessTypeRo => 'Read Only';

  @override
  String get accessTypeWo => 'Write Only';

  @override
  String get accessTypeRw => 'Read & Write';

  @override
  String get booleanTrue => 'On';

  @override
  String get booleanFalse => 'Off';

  @override
  String get fieldRequired => 'Required';

  @override
  String get pointSaveFailed => 'Failed to save point';

  @override
  String get pointDeleteFailed => 'Failed to delete point';

  @override
  String get pointMinValueLabel => 'Min Value';

  @override
  String get pointMaxValueLabel => 'Max Value';

  @override
  String get pointDefaultValueLabel => 'Default Value';

  @override
  String get editPoint => 'Edit Point';

  @override
  String get addPointTitle => 'Add Point';

  @override
  String get statusIdle => 'Idle';

  @override
  String get statusLoaded => 'Loaded';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusAborted => 'Aborted';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterDateRange => 'Date';

  @override
  String get resetFilter => 'Reset Filters';

  @override
  String get noExperiments => 'No experiments yet';

  @override
  String get noExperimentsHint => 'Create your first experiment to get started';

  @override
  String get createFirstExperiment => 'Create First Experiment';

  @override
  String get noFilteredResults => 'No matching experiments';

  @override
  String get noFilteredResultsHint => 'Try adjusting your filter criteria';

  @override
  String get clearFilter => 'Clear Filters';

  @override
  String get loadFailed => 'Failed to load experiments';

  @override
  String get loadFailedHint => 'Please check your connection and try again';

  @override
  String totalRecords(int count) {
    return '$count records total';
  }

  @override
  String pageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get recordsPerPage => 'Rows per page';

  @override
  String get columnName => 'Name';

  @override
  String get columnMethod => 'Method';

  @override
  String get columnStatus => 'Status';

  @override
  String get columnStartTime => 'Start Time';

  @override
  String get columnDuration => 'Duration';

  @override
  String get columnActions => 'Actions';

  @override
  String get openConsole => 'Open Console';

  @override
  String get stopExperiment => 'Stop';

  @override
  String get confirmStopTitle => 'Confirm Stop';

  @override
  String confirmStopDesc(String name) {
    return 'Are you sure you want to stop experiment \"$name\"?';
  }

  @override
  String get experimentStopped => 'Experiment stopped';

  @override
  String stopFailed(String reason) {
    return 'Failed to stop experiment: $reason';
  }

  @override
  String get createExperiment => 'Create Experiment';

  @override
  String get notStarted => '—';

  @override
  String get methodNotSet => '—';

  @override
  String get createExperimentTitle => 'Create Experiment';

  @override
  String get stepSelectWorkbench => 'Select Workbench';

  @override
  String get stepSelectMethod => 'Select Method';

  @override
  String get stepConfigureParams => 'Configure Parameters';

  @override
  String get stepConfirm => 'Confirm';

  @override
  String get stepWorkbenchShort => 'Workbench';

  @override
  String get stepMethodShort => 'Method';

  @override
  String get stepParamsShort => 'Parameters';

  @override
  String get stepConfirmShort => 'Confirm';

  @override
  String get selectWorkbenchTitle => 'Select Workbench';

  @override
  String get selectWorkbenchSubtitle =>
      'Please select a workbench for this experiment';

  @override
  String get noWorkbenchesTitle => 'No workbenches yet';

  @override
  String get noWorkbenchesDescription =>
      'Create your first workbench by clicking the button below';

  @override
  String get createFirstWorkbench => 'Create Your First Workbench';

  @override
  String get loadWorkbenchesFailed => 'Failed to load workbenches';

  @override
  String get loadWorkbenchesFailedHint =>
      'Please check your network and try again';

  @override
  String deviceCount(int count) {
    return '$count devices';
  }

  @override
  String get selectMethodTitle => 'Select Method';

  @override
  String get selectMethodSubtitle =>
      'Please select a method for this experiment';

  @override
  String get noMethodsTitle => 'No methods available';

  @override
  String get noMethodsDescription => 'Please create an experiment method first';

  @override
  String get goToMethods => 'Go to Methods';

  @override
  String get loadMethodsFailed => 'Failed to load methods';

  @override
  String get loadMethodsFailedHint => 'Please check your network and try again';

  @override
  String paramCount(int count) {
    return '$count parameters';
  }

  @override
  String get configureParamsTitle => 'Configure Parameters';

  @override
  String get configureParamsSubtitle =>
      'Configure the parameters for the selected method';

  @override
  String get noParamsRequired => 'No parameters required';

  @override
  String get noParamsHint => 'Click Next to continue';

  @override
  String get confirmTitle => 'Confirm';

  @override
  String get confirmSubtitle => 'Please confirm the following information';

  @override
  String get summaryWorkbench => 'Workbench';

  @override
  String get summaryMethod => 'Experiment Method';

  @override
  String get summaryParams => 'Parameter Configuration';

  @override
  String get createWarning =>
      'The experiment will start running immediately after creation';

  @override
  String get nextStep => 'Next';

  @override
  String get previousStep => 'Back';

  @override
  String get creating => 'Creating...';

  @override
  String get createExperimentSuccess => 'Experiment created successfully';

  @override
  String createExperimentFailed(String reason) {
    return 'Failed to create experiment: $reason';
  }

  @override
  String get fieldRequiredValidation => 'This field is required';

  @override
  String get mustBeInteger => 'Must be an integer';

  @override
  String cannotBeLessThan(String min) {
    return 'Cannot be less than $min';
  }

  @override
  String cannotBeGreaterThan(String max) {
    return 'Cannot be greater than $max';
  }

  @override
  String get invalidFormat => 'Invalid format';

  @override
  String get unnamedWorkbench => 'Unnamed Workbench';

  @override
  String get unnamedMethod => 'Unnamed Method';

  @override
  String get createTooltipIncomplete =>
      'Please select a workbench and method first';

  @override
  String get paramsNotPersistedWarning =>
      'Note: Parameter values are for reference in this session only and will not be persisted in this version.';

  @override
  String get backToList => 'Back to list';

  @override
  String get statusLabel => 'Status';

  @override
  String get elapsedLabel => 'Elapsed';

  @override
  String get elapsedPaused => 'Paused';

  @override
  String get methodLabel => 'Method';

  @override
  String get experimentNotFound => 'Experiment not found';

  @override
  String get experimentNotFoundHint =>
      'Invalid experiment ID, please check the link or go back to the list';

  @override
  String get experimentNoPermission =>
      'No permission to access this experiment';

  @override
  String get actionLoad => 'Load';

  @override
  String get actionStart => 'Start';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionStop => 'Stop';

  @override
  String get wsDisconnected => 'Disconnected';

  @override
  String get wsConnecting => 'Connecting...';

  @override
  String get wsConnected => 'Connected';

  @override
  String get wsReconnecting => 'Reconnecting';

  @override
  String get wsFailed => 'Connection failed';

  @override
  String get wsReconnect => 'Reconnect';

  @override
  String get logEmptyTitle => 'Waiting for logs...';

  @override
  String get logEmptyHint => 'Logs will appear when experiment starts';

  @override
  String get newLogsLabel => 'new logs';

  @override
  String get filterAllLabel => 'All';

  @override
  String get clearLogsLabel => 'Clear';

  @override
  String get confirmStopAction => 'Confirm Stop';

  @override
  String get experimentStarted => 'Experiment started';

  @override
  String get experimentPaused => 'Experiment paused';

  @override
  String get experimentResumed => 'Experiment resumed';

  @override
  String get methodLoaded => 'Method loaded';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get statusCompletedHint => 'Experiment completed';

  @override
  String get statusRunningHint => 'Experiment running';

  @override
  String get statusAbortedHint => 'Experiment aborted';

  @override
  String get startedLabel => 'Started';

  @override
  String get endedLabel => 'Ended';

  @override
  String get totalDurationLabel => 'Total Duration';
}
