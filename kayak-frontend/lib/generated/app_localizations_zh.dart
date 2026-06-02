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
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get logout => '登出';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get username => '用户名';

  @override
  String get dashboard => '首页';

  @override
  String get workbenches => '工作台';

  @override
  String get methods => '方法';

  @override
  String get experiments => '试验';

  @override
  String get analysis => '分析';

  @override
  String get settings => '设置';

  @override
  String get workbenchList => '工作台列表';

  @override
  String get methodList => '方法列表';

  @override
  String get experimentList => '试验列表';

  @override
  String get loginError => '邮箱或密码错误';

  @override
  String get networkError => '网络错误，请检查连接';

  @override
  String get sessionExpired => '会话已过期，请重新登录';

  @override
  String get errorBadRequest => '请求参数有误，请检查输入';

  @override
  String get errorForbidden => '没有权限执行此操作';

  @override
  String get errorNotFound => '请求的资源不存在';

  @override
  String get errorConflict => '资源冲突，请检查是否已存在相同名称';

  @override
  String get errorValidation => '数据验证失败，请检查输入';

  @override
  String get errorServer => '服务暂时不可用，请稍后再试';

  @override
  String get errorDefault => '操作失败，请重试';

  @override
  String get noData => '暂无数据';

  @override
  String get loading => '加载中...';

  @override
  String get retry => '重试';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get create => '创建';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get search => '搜索';

  @override
  String get submit => '提交';

  @override
  String get emailHint => '请输入邮箱地址';

  @override
  String get passwordHint => '请输入密码';

  @override
  String get emailRequired => '请输入邮箱地址';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get noAccount => '还没有账号？立即注册';

  @override
  String get signIn => '登录';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get confirmPasswordHint => '请再次输入密码';

  @override
  String get passwordsDoNotMatch => '两次密码输入不一致';

  @override
  String get usernameHint => '设置一个显示名称';

  @override
  String get usernameHelper => '不填则使用邮箱前缀作为用户名';

  @override
  String get hasAccount => '已有账号？立即登录';

  @override
  String get registrationSuccess => '注册成功！';

  @override
  String get passwordStrength => '密码强度';

  @override
  String get passwordStrengthWeak => '弱';

  @override
  String get passwordStrengthMedium => '中';

  @override
  String get passwordStrengthGood => '良';

  @override
  String get passwordStrengthStrong => '强';

  @override
  String get passwordMinLength => '至少 8 个字符';

  @override
  String get passwordUppercaseLowercase => '包含大小写字母';

  @override
  String get passwordNumber => '包含数字';

  @override
  String get passwordSpecial => '包含特殊字符';

  @override
  String get usernameLengthError => '用户名长度需在 3-30 字符之间';

  @override
  String get usernameInvalidChars => '仅允许字母、数字、下划线和连字符';

  @override
  String get emailFormatError => '请输入有效的邮箱地址';

  @override
  String get passwordMinLengthError => '密码至少需要 8 个字符';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String get noAccountRegister => '还没有账号？立即注册';

  @override
  String get usernameOptional => '用户名（选填）';

  @override
  String get profile => '个人资料';

  @override
  String get editProfile => '编辑资料';

  @override
  String get profileInfo => '个人信息';

  @override
  String get memberSince => '注册于';

  @override
  String get changePassword => '修改密码';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get profileUpdateSuccess => '资料更新成功';

  @override
  String get passwordChangeSuccess => '密码修改成功';

  @override
  String get currentPasswordRequired => '请输入当前密码';

  @override
  String get newPasswordRequired => '请输入新密码';

  @override
  String get newPasswordMinLength => '新密码至少需要 8 个字符';

  @override
  String get passwordInfo => '密码设置';

  @override
  String get workbenchSearchHint => '搜索工作台...';

  @override
  String get workbenchCreate => '创建工作台';

  @override
  String get workbenchEdit => '编辑工作台';

  @override
  String get workbenchName => '名称';

  @override
  String get workbenchDescription => '描述';

  @override
  String get workbenchNameHint => '请输入工作台名称';

  @override
  String get workbenchDescriptionHint => '描述（选填）';

  @override
  String get workbenchNameRequired => '请输入工作台名称';

  @override
  String get workbenchNameMaxLength => '名称不能超过255个字符';

  @override
  String get createWorkbenchSuccess => '创建工作台成功';

  @override
  String get updateWorkbenchSuccess => '工作台已更新';

  @override
  String get deleteWorkbenchSuccess => '工作台已删除';

  @override
  String get deleteWorkbenchTitle => '删除工作台？';

  @override
  String deleteWorkbenchDescription(String name) {
    return '确定要删除工作台「$name」吗？此操作不可撤销，工作台下所有设备和数据将被永久删除。';
  }

  @override
  String get loadMore => '加载更多';

  @override
  String totalCount(int count) {
    return '共 $count 个工作台';
  }

  @override
  String get searchNoResults => '未找到匹配的工作台';

  @override
  String get searchNoResultsHint => '请尝试修改搜索关键词';

  @override
  String get clearSearch => '清除搜索';

  @override
  String get emptyWorkbenchTitle => '您还没有工作台';

  @override
  String get emptyWorkbenchDescription => '点击下方按钮创建您的第一个工作台';

  @override
  String get emptyWorkbenchAction => '创建第一个工作台';

  @override
  String get workbenchDetail => '工作台详情';

  @override
  String get deviceTree => '设备树';

  @override
  String get deviceDetail => '设备详情';

  @override
  String get deviceTreePlaceholder => '将在下一个 Sprint 实现';

  @override
  String get deviceDetailPlaceholder => '选择左侧设备查看详情';

  @override
  String get workbenchNotFound => '工作台不存在或已被删除';

  @override
  String get addDevice => '添加设备';

  @override
  String get createdAt => '创建于';

  @override
  String get lastModified => '最后修改';

  @override
  String get deleteWorkbenchConfirm => '确认删除';

  @override
  String get workbenchDetailShort => '详情';

  @override
  String get deviceTreeTitle => '设备';

  @override
  String get noDevices => '暂无设备';

  @override
  String get addDeviceDialogTitle => '添加设备';

  @override
  String get editDeviceDialogTitle => '编辑设备';

  @override
  String get deviceName => '设备名称';

  @override
  String get deviceNameHint => '请输入设备名称';

  @override
  String get deviceNameRequired => '请输入设备名称';

  @override
  String get deviceNameMaxLength => '名称不能超过255个字符';

  @override
  String get protocolType => '协议类型';

  @override
  String get protocolTypeHint => '请选择协议类型';

  @override
  String get protocolTypeRequired => '请选择协议类型';

  @override
  String get virtualDevice => '虚拟设备';

  @override
  String get modbusTcp => 'Modbus TCP';

  @override
  String get modbusRtu => 'Modbus RTU';

  @override
  String get virtualMode => '虚拟模式';

  @override
  String get virtualModeHint => '请选择虚拟模式';

  @override
  String get virtualModeRequired => '请选择虚拟模式';

  @override
  String get random => '随机';

  @override
  String get sineWave => '正弦波';

  @override
  String get fixedValue => '固定值';

  @override
  String get increment => '递增';

  @override
  String get dataType => '数据类型';

  @override
  String get dataTypeHint => '请选择数据类型';

  @override
  String get dataTypeRequired => '请选择数据类型';

  @override
  String get valueRange => '取值范围';

  @override
  String get minValue => '最小值';

  @override
  String get maxValue => '最大值';

  @override
  String get updateInterval => '更新间隔';

  @override
  String get ms => '毫秒';

  @override
  String get hostAddress => '主机地址';

  @override
  String get hostAddressHint => '192.168.1.100';

  @override
  String get hostAddressRequired => '请输入主机地址';

  @override
  String get hostAddressInvalid => '请输入有效的 IPv4 地址';

  @override
  String get port => '端口';

  @override
  String get portHint => '502';

  @override
  String get portRequired => '请输入端口';

  @override
  String get portInvalid => '端口必须为 1-65535 之间的整数';

  @override
  String get slaveId => '从站 ID';

  @override
  String get slaveIdHint => '1';

  @override
  String get slaveIdInvalid => '从站 ID 必须为 1-247 之间的整数';

  @override
  String get timeout => '超时';

  @override
  String get timeoutHint => '5000';

  @override
  String get serialPort => '串口';

  @override
  String get serialPortHint => '请选择串口';

  @override
  String get serialPortRequired => '请选择串口';

  @override
  String get baudRate => '波特率';

  @override
  String get baudRateHint => '请选择波特率';

  @override
  String get dataBits => '数据位';

  @override
  String get stopBits => '停止位';

  @override
  String get parity => '校验位';

  @override
  String get none => '无';

  @override
  String get oddParity => '奇校验';

  @override
  String get evenParity => '偶校验';

  @override
  String get advancedInfo => '高级信息';

  @override
  String get manufacturer => '制造商';

  @override
  String get manufacturerHint => '例如: Siemens';

  @override
  String get modelName => '型号';

  @override
  String get modelHint => '例如: S7-1200';

  @override
  String get serialNumber => '序列号';

  @override
  String get serialNumberHint => '例如: SN123456';

  @override
  String get deviceSaveSuccess => '设备保存成功';

  @override
  String get deviceDeleteTitle => '删除设备？';

  @override
  String deviceDeleteDescription(String name) {
    return '确定要删除设备「$name」吗？';
  }

  @override
  String get deviceDeleteSuccess => '设备已删除';

  @override
  String get editDevice => '编辑设备';

  @override
  String get addSubDevice => '添加子设备';

  @override
  String get deleteDevice => '删除设备';

  @override
  String get confirmDeleteDevice => '确认删除';

  @override
  String get basicInfo => '基础信息';

  @override
  String get protocolConfig => '协议配置';

  @override
  String get validNumberRequired => '请输入有效数字';

  @override
  String get maxGreaterThanMin => '最大值必须大于最小值';

  @override
  String get minIntervalMs => '更新间隔不能小于 100ms';

  @override
  String get minTimeoutMs => '超时时间不能小于 100ms';

  @override
  String get baudRateRequired => '请选择波特率';

  @override
  String get max255Chars => '最多 255 个字符';

  @override
  String get pointListTitle => '测点列表';

  @override
  String pointCount(int count) {
    return '共 $count 个测点';
  }

  @override
  String get addPoint => '添加测点';

  @override
  String get addFirstPoint => '添加第一个测点';

  @override
  String get pointListEmpty => '该设备下暂无测点';

  @override
  String get pointNameRequired => '请输入测点名称';

  @override
  String get pointNameTooLong => '名称不能超过 255 个字符';

  @override
  String get pointSaveSuccess => '测点已保存';

  @override
  String get pointDeleteSuccess => '测点已删除';

  @override
  String pointDeleteConfirm(String name) {
    return '确定要删除测点「$name」吗？';
  }

  @override
  String get pointDeleteWarning => '此操作不可撤销。';

  @override
  String get pointRangeInvalid => '最大值必须大于最小值';

  @override
  String get pointStatusNormal => '正常';

  @override
  String get pointStatusTimeout => '超时';

  @override
  String get pointStatusError => '异常';

  @override
  String get refresh => '刷新';

  @override
  String get pointNameLabel => '名称';

  @override
  String get pointNameHint => '请输入测点名称';

  @override
  String get pointDataTypeLabel => '数据类型';

  @override
  String get pointAccessTypeLabel => '访问权限';

  @override
  String get pointUnitLabel => '单位';

  @override
  String get pointModbusConfig => 'Modbus 配置';

  @override
  String get pointRegisterTypeLabel => '寄存器类型';

  @override
  String get pointAddressLabel => '起始地址';

  @override
  String get pointAddressRange => '起始地址必须在 0-65535 之间';

  @override
  String get pointDataFormatLabel => '数据格式';

  @override
  String get pointColumnName => '名称';

  @override
  String get pointColumnType => '类型';

  @override
  String get pointColumnAccess => '访问权限';

  @override
  String get pointColumnUnit => '单位';

  @override
  String get pointColumnValue => '当前值';

  @override
  String get pointColumnAction => '操作';

  @override
  String get dataTypeNumber => '浮点数';

  @override
  String get dataTypeInteger => '整数';

  @override
  String get dataTypeBoolean => '布尔值';

  @override
  String get dataTypeString => '字符串';

  @override
  String get accessTypeRo => '只读';

  @override
  String get accessTypeWo => '只写';

  @override
  String get accessTypeRw => '读写';

  @override
  String get booleanTrue => '开启';

  @override
  String get booleanFalse => '关闭';

  @override
  String get fieldRequired => '必填';

  @override
  String get pointSaveFailed => '测点保存失败';

  @override
  String get pointDeleteFailed => '测点删除失败';

  @override
  String get pointMinValueLabel => '最小值';

  @override
  String get pointMaxValueLabel => '最大值';

  @override
  String get pointDefaultValueLabel => '默认值';

  @override
  String get editPoint => '编辑测点';

  @override
  String get addPointTitle => '添加测点';

  @override
  String get statusIdle => '空闲';

  @override
  String get statusLoaded => '已载入';

  @override
  String get statusRunning => '运行中';

  @override
  String get statusPaused => '已暂停';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusAborted => '已中止';

  @override
  String get statusUnknown => '未知';

  @override
  String get allStatuses => '全部状态';

  @override
  String get filterStatus => '状态';

  @override
  String get filterDateRange => '时间';

  @override
  String get resetFilter => '重置筛选';

  @override
  String get noExperiments => '暂无试验';

  @override
  String get noExperimentsHint => '点击下方按钮创建您的第一个试验';

  @override
  String get createFirstExperiment => '创建第一个试验';

  @override
  String get noFilteredResults => '没有符合条件的试验';

  @override
  String get noFilteredResultsHint => '请尝试调整筛选条件';

  @override
  String get clearFilter => '清除筛选条件';

  @override
  String get loadFailed => '加载试验列表失败';

  @override
  String get loadFailedHint => '请检查网络连接后点击重试';

  @override
  String totalRecords(int count) {
    return '共 $count 条记录';
  }

  @override
  String pageOf(int current, int total) {
    return '第 $current 页，共 $total 页';
  }

  @override
  String get recordsPerPage => '每页条数';

  @override
  String get columnName => '名称';

  @override
  String get columnMethod => '方法';

  @override
  String get columnStatus => '状态';

  @override
  String get columnStartTime => '开始时间';

  @override
  String get columnDuration => '持续时间';

  @override
  String get columnActions => '操作';

  @override
  String get openConsole => '进入控制台';

  @override
  String get stopExperiment => '停止';

  @override
  String get confirmStopTitle => '确认停止';

  @override
  String confirmStopDesc(String name) {
    return '确定要停止试验「$name」吗？';
  }

  @override
  String get experimentStopped => '试验已停止';

  @override
  String stopFailed(String reason) {
    return '停止失败：$reason';
  }

  @override
  String get createExperiment => '创建试验';

  @override
  String get notStarted => '—';

  @override
  String get methodNotSet => '—';

  @override
  String get createExperimentTitle => '创建试验';

  @override
  String get stepSelectWorkbench => '选择工作台';

  @override
  String get stepSelectMethod => '选择方法';

  @override
  String get stepConfigureParams => '配置参数';

  @override
  String get stepConfirm => '确认创建';

  @override
  String get stepWorkbenchShort => '工作台';

  @override
  String get stepMethodShort => '方法';

  @override
  String get stepParamsShort => '参数';

  @override
  String get stepConfirmShort => '确认';

  @override
  String get selectWorkbenchTitle => '选择工作台';

  @override
  String get selectWorkbenchSubtitle => '请选择一个工作台用于本次试验';

  @override
  String get noWorkbenchesTitle => '您还没有工作台';

  @override
  String get noWorkbenchesDescription => '点击下方按钮创建您的第一个工作台';

  @override
  String get createFirstWorkbench => '创建第一个工作台';

  @override
  String get loadWorkbenchesFailed => '加载工作台列表失败';

  @override
  String get loadWorkbenchesFailedHint => '请检查网络后点击重试';

  @override
  String deviceCount(int count) {
    return '$count 台设备';
  }

  @override
  String get selectMethodTitle => '选择方法';

  @override
  String get selectMethodSubtitle => '请选择一个试验方法';

  @override
  String get noMethodsTitle => '暂无可用方法';

  @override
  String get noMethodsDescription => '请先创建试验方法';

  @override
  String get goToMethods => '前往方法管理';

  @override
  String get loadMethodsFailed => '加载方法列表失败';

  @override
  String get loadMethodsFailedHint => '请检查网络后点击重试';

  @override
  String paramCount(int count) {
    return '$count 个参数';
  }

  @override
  String get configureParamsTitle => '配置参数';

  @override
  String get configureParamsSubtitle => '请配置所选方法的参数';

  @override
  String get noParamsRequired => '该方法无需配置参数';

  @override
  String get noParamsHint => '点击下一步继续';

  @override
  String get confirmTitle => '确认创建';

  @override
  String get confirmSubtitle => '请确认以下信息无误';

  @override
  String get summaryWorkbench => '工作台';

  @override
  String get summaryMethod => '试验方法';

  @override
  String get summaryParams => '参数配置';

  @override
  String get createWarning => '创建后试验将立即开始运行';

  @override
  String get nextStep => '下一步';

  @override
  String get previousStep => '上一步';

  @override
  String get creating => '创建中...';

  @override
  String get createExperimentSuccess => '试验创建成功';

  @override
  String createExperimentFailed(String reason) {
    return '创建试验失败：$reason';
  }

  @override
  String get fieldRequiredValidation => '此字段为必填项';

  @override
  String get mustBeInteger => '必须为整数';

  @override
  String cannotBeLessThan(String min) {
    return '不能小于 $min';
  }

  @override
  String cannotBeGreaterThan(String max) {
    return '不能大于 $max';
  }

  @override
  String get invalidFormat => '格式不正确';

  @override
  String get unnamedWorkbench => '未命名工作台';

  @override
  String get unnamedMethod => '未命名方法';

  @override
  String get createTooltipIncomplete => '请先选择工作台和方法';

  @override
  String get paramsNotPersistedWarning => '注意：参数值仅供本次创建参考，当前版本暂不支持参数存储。';
}
