// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AnalysisState {

/// 试验列表状态
 AsyncValue<List<Experiment>> get experiments;/// 当前选中的试验 ID
 String? get selectedExperimentId;/// 当前选中的试验关联的设备列表（null=未加载, [] = 空）
 List<Device>? get devices;/// 当前选中的设备 ID
 String? get selectedDeviceId;/// 当前设备下的测点列表
 List<Point>? get points;/// 已选测点 ID 集合
 Set<String> get selectedPointIds;/// 时间范围预设
 TimeRangePreset get timePreset;/// 自定义开始时间
 DateTime? get customStart;/// 自定义结束时间
 DateTime? get customEnd;/// 降采样点数
 int get downsample;/// 图表数据状态
 AsyncValue<ChartData?> get chartData;/// 是否显示数据表格
 bool get showDataTable;/// 是否正在加载数据（防重复提交）
 bool get isLoadingData;/// 被图例隐藏的测点 ID 集合
 Set<String> get hiddenPointIds;
/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisStateCopyWith<AnalysisState> get copyWith => _$AnalysisStateCopyWithImpl<AnalysisState>(this as AnalysisState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisState&&(identical(other.experiments, experiments) || other.experiments == experiments)&&(identical(other.selectedExperimentId, selectedExperimentId) || other.selectedExperimentId == selectedExperimentId)&&const DeepCollectionEquality().equals(other.devices, devices)&&(identical(other.selectedDeviceId, selectedDeviceId) || other.selectedDeviceId == selectedDeviceId)&&const DeepCollectionEquality().equals(other.points, points)&&const DeepCollectionEquality().equals(other.selectedPointIds, selectedPointIds)&&(identical(other.timePreset, timePreset) || other.timePreset == timePreset)&&(identical(other.customStart, customStart) || other.customStart == customStart)&&(identical(other.customEnd, customEnd) || other.customEnd == customEnd)&&(identical(other.downsample, downsample) || other.downsample == downsample)&&(identical(other.chartData, chartData) || other.chartData == chartData)&&(identical(other.showDataTable, showDataTable) || other.showDataTable == showDataTable)&&(identical(other.isLoadingData, isLoadingData) || other.isLoadingData == isLoadingData)&&const DeepCollectionEquality().equals(other.hiddenPointIds, hiddenPointIds));
}


@override
int get hashCode => Object.hash(runtimeType,experiments,selectedExperimentId,const DeepCollectionEquality().hash(devices),selectedDeviceId,const DeepCollectionEquality().hash(points),const DeepCollectionEquality().hash(selectedPointIds),timePreset,customStart,customEnd,downsample,chartData,showDataTable,isLoadingData,const DeepCollectionEquality().hash(hiddenPointIds));

@override
String toString() {
  return 'AnalysisState(experiments: $experiments, selectedExperimentId: $selectedExperimentId, devices: $devices, selectedDeviceId: $selectedDeviceId, points: $points, selectedPointIds: $selectedPointIds, timePreset: $timePreset, customStart: $customStart, customEnd: $customEnd, downsample: $downsample, chartData: $chartData, showDataTable: $showDataTable, isLoadingData: $isLoadingData, hiddenPointIds: $hiddenPointIds)';
}


}

/// @nodoc
abstract mixin class $AnalysisStateCopyWith<$Res>  {
  factory $AnalysisStateCopyWith(AnalysisState value, $Res Function(AnalysisState) _then) = _$AnalysisStateCopyWithImpl;
@useResult
$Res call({
 AsyncValue<List<Experiment>> experiments, String? selectedExperimentId, List<Device>? devices, String? selectedDeviceId, List<Point>? points, Set<String> selectedPointIds, TimeRangePreset timePreset, DateTime? customStart, DateTime? customEnd, int downsample, AsyncValue<ChartData?> chartData, bool showDataTable, bool isLoadingData, Set<String> hiddenPointIds
});




}
/// @nodoc
class _$AnalysisStateCopyWithImpl<$Res>
    implements $AnalysisStateCopyWith<$Res> {
  _$AnalysisStateCopyWithImpl(this._self, this._then);

  final AnalysisState _self;
  final $Res Function(AnalysisState) _then;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? experiments = null,Object? selectedExperimentId = freezed,Object? devices = freezed,Object? selectedDeviceId = freezed,Object? points = freezed,Object? selectedPointIds = null,Object? timePreset = null,Object? customStart = freezed,Object? customEnd = freezed,Object? downsample = null,Object? chartData = null,Object? showDataTable = null,Object? isLoadingData = null,Object? hiddenPointIds = null,}) {
  return _then(_self.copyWith(
experiments: null == experiments ? _self.experiments : experiments // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<Experiment>>,selectedExperimentId: freezed == selectedExperimentId ? _self.selectedExperimentId : selectedExperimentId // ignore: cast_nullable_to_non_nullable
as String?,devices: freezed == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<Device>?,selectedDeviceId: freezed == selectedDeviceId ? _self.selectedDeviceId : selectedDeviceId // ignore: cast_nullable_to_non_nullable
as String?,points: freezed == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<Point>?,selectedPointIds: null == selectedPointIds ? _self.selectedPointIds : selectedPointIds // ignore: cast_nullable_to_non_nullable
as Set<String>,timePreset: null == timePreset ? _self.timePreset : timePreset // ignore: cast_nullable_to_non_nullable
as TimeRangePreset,customStart: freezed == customStart ? _self.customStart : customStart // ignore: cast_nullable_to_non_nullable
as DateTime?,customEnd: freezed == customEnd ? _self.customEnd : customEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,downsample: null == downsample ? _self.downsample : downsample // ignore: cast_nullable_to_non_nullable
as int,chartData: null == chartData ? _self.chartData : chartData // ignore: cast_nullable_to_non_nullable
as AsyncValue<ChartData?>,showDataTable: null == showDataTable ? _self.showDataTable : showDataTable // ignore: cast_nullable_to_non_nullable
as bool,isLoadingData: null == isLoadingData ? _self.isLoadingData : isLoadingData // ignore: cast_nullable_to_non_nullable
as bool,hiddenPointIds: null == hiddenPointIds ? _self.hiddenPointIds : hiddenPointIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalysisState].
extension AnalysisStatePatterns on AnalysisState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalysisState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalysisState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalysisState value)  $default,){
final _that = this;
switch (_that) {
case _AnalysisState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalysisState value)?  $default,){
final _that = this;
switch (_that) {
case _AnalysisState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AsyncValue<List<Experiment>> experiments,  String? selectedExperimentId,  List<Device>? devices,  String? selectedDeviceId,  List<Point>? points,  Set<String> selectedPointIds,  TimeRangePreset timePreset,  DateTime? customStart,  DateTime? customEnd,  int downsample,  AsyncValue<ChartData?> chartData,  bool showDataTable,  bool isLoadingData,  Set<String> hiddenPointIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalysisState() when $default != null:
return $default(_that.experiments,_that.selectedExperimentId,_that.devices,_that.selectedDeviceId,_that.points,_that.selectedPointIds,_that.timePreset,_that.customStart,_that.customEnd,_that.downsample,_that.chartData,_that.showDataTable,_that.isLoadingData,_that.hiddenPointIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AsyncValue<List<Experiment>> experiments,  String? selectedExperimentId,  List<Device>? devices,  String? selectedDeviceId,  List<Point>? points,  Set<String> selectedPointIds,  TimeRangePreset timePreset,  DateTime? customStart,  DateTime? customEnd,  int downsample,  AsyncValue<ChartData?> chartData,  bool showDataTable,  bool isLoadingData,  Set<String> hiddenPointIds)  $default,) {final _that = this;
switch (_that) {
case _AnalysisState():
return $default(_that.experiments,_that.selectedExperimentId,_that.devices,_that.selectedDeviceId,_that.points,_that.selectedPointIds,_that.timePreset,_that.customStart,_that.customEnd,_that.downsample,_that.chartData,_that.showDataTable,_that.isLoadingData,_that.hiddenPointIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AsyncValue<List<Experiment>> experiments,  String? selectedExperimentId,  List<Device>? devices,  String? selectedDeviceId,  List<Point>? points,  Set<String> selectedPointIds,  TimeRangePreset timePreset,  DateTime? customStart,  DateTime? customEnd,  int downsample,  AsyncValue<ChartData?> chartData,  bool showDataTable,  bool isLoadingData,  Set<String> hiddenPointIds)?  $default,) {final _that = this;
switch (_that) {
case _AnalysisState() when $default != null:
return $default(_that.experiments,_that.selectedExperimentId,_that.devices,_that.selectedDeviceId,_that.points,_that.selectedPointIds,_that.timePreset,_that.customStart,_that.customEnd,_that.downsample,_that.chartData,_that.showDataTable,_that.isLoadingData,_that.hiddenPointIds);case _:
  return null;

}
}

}

/// @nodoc


class _AnalysisState implements AnalysisState {
  const _AnalysisState({this.experiments = const AsyncLoading<List<Experiment>>(), this.selectedExperimentId, final  List<Device>? devices, this.selectedDeviceId, final  List<Point>? points, final  Set<String> selectedPointIds = const {}, this.timePreset = TimeRangePreset.oneHour, this.customStart, this.customEnd, this.downsample = 1000, this.chartData = const AsyncData<ChartData?>(null), this.showDataTable = false, this.isLoadingData = false, final  Set<String> hiddenPointIds = const {}}): _devices = devices,_points = points,_selectedPointIds = selectedPointIds,_hiddenPointIds = hiddenPointIds;
  

/// 试验列表状态
@override@JsonKey() final  AsyncValue<List<Experiment>> experiments;
/// 当前选中的试验 ID
@override final  String? selectedExperimentId;
/// 当前选中的试验关联的设备列表（null=未加载, [] = 空）
 final  List<Device>? _devices;
/// 当前选中的试验关联的设备列表（null=未加载, [] = 空）
@override List<Device>? get devices {
  final value = _devices;
  if (value == null) return null;
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// 当前选中的设备 ID
@override final  String? selectedDeviceId;
/// 当前设备下的测点列表
 final  List<Point>? _points;
/// 当前设备下的测点列表
@override List<Point>? get points {
  final value = _points;
  if (value == null) return null;
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// 已选测点 ID 集合
 final  Set<String> _selectedPointIds;
/// 已选测点 ID 集合
@override@JsonKey() Set<String> get selectedPointIds {
  if (_selectedPointIds is EqualUnmodifiableSetView) return _selectedPointIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedPointIds);
}

/// 时间范围预设
@override@JsonKey() final  TimeRangePreset timePreset;
/// 自定义开始时间
@override final  DateTime? customStart;
/// 自定义结束时间
@override final  DateTime? customEnd;
/// 降采样点数
@override@JsonKey() final  int downsample;
/// 图表数据状态
@override@JsonKey() final  AsyncValue<ChartData?> chartData;
/// 是否显示数据表格
@override@JsonKey() final  bool showDataTable;
/// 是否正在加载数据（防重复提交）
@override@JsonKey() final  bool isLoadingData;
/// 被图例隐藏的测点 ID 集合
 final  Set<String> _hiddenPointIds;
/// 被图例隐藏的测点 ID 集合
@override@JsonKey() Set<String> get hiddenPointIds {
  if (_hiddenPointIds is EqualUnmodifiableSetView) return _hiddenPointIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_hiddenPointIds);
}


/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalysisStateCopyWith<_AnalysisState> get copyWith => __$AnalysisStateCopyWithImpl<_AnalysisState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalysisState&&(identical(other.experiments, experiments) || other.experiments == experiments)&&(identical(other.selectedExperimentId, selectedExperimentId) || other.selectedExperimentId == selectedExperimentId)&&const DeepCollectionEquality().equals(other._devices, _devices)&&(identical(other.selectedDeviceId, selectedDeviceId) || other.selectedDeviceId == selectedDeviceId)&&const DeepCollectionEquality().equals(other._points, _points)&&const DeepCollectionEquality().equals(other._selectedPointIds, _selectedPointIds)&&(identical(other.timePreset, timePreset) || other.timePreset == timePreset)&&(identical(other.customStart, customStart) || other.customStart == customStart)&&(identical(other.customEnd, customEnd) || other.customEnd == customEnd)&&(identical(other.downsample, downsample) || other.downsample == downsample)&&(identical(other.chartData, chartData) || other.chartData == chartData)&&(identical(other.showDataTable, showDataTable) || other.showDataTable == showDataTable)&&(identical(other.isLoadingData, isLoadingData) || other.isLoadingData == isLoadingData)&&const DeepCollectionEquality().equals(other._hiddenPointIds, _hiddenPointIds));
}


@override
int get hashCode => Object.hash(runtimeType,experiments,selectedExperimentId,const DeepCollectionEquality().hash(_devices),selectedDeviceId,const DeepCollectionEquality().hash(_points),const DeepCollectionEquality().hash(_selectedPointIds),timePreset,customStart,customEnd,downsample,chartData,showDataTable,isLoadingData,const DeepCollectionEquality().hash(_hiddenPointIds));

@override
String toString() {
  return 'AnalysisState(experiments: $experiments, selectedExperimentId: $selectedExperimentId, devices: $devices, selectedDeviceId: $selectedDeviceId, points: $points, selectedPointIds: $selectedPointIds, timePreset: $timePreset, customStart: $customStart, customEnd: $customEnd, downsample: $downsample, chartData: $chartData, showDataTable: $showDataTable, isLoadingData: $isLoadingData, hiddenPointIds: $hiddenPointIds)';
}


}

/// @nodoc
abstract mixin class _$AnalysisStateCopyWith<$Res> implements $AnalysisStateCopyWith<$Res> {
  factory _$AnalysisStateCopyWith(_AnalysisState value, $Res Function(_AnalysisState) _then) = __$AnalysisStateCopyWithImpl;
@override @useResult
$Res call({
 AsyncValue<List<Experiment>> experiments, String? selectedExperimentId, List<Device>? devices, String? selectedDeviceId, List<Point>? points, Set<String> selectedPointIds, TimeRangePreset timePreset, DateTime? customStart, DateTime? customEnd, int downsample, AsyncValue<ChartData?> chartData, bool showDataTable, bool isLoadingData, Set<String> hiddenPointIds
});




}
/// @nodoc
class __$AnalysisStateCopyWithImpl<$Res>
    implements _$AnalysisStateCopyWith<$Res> {
  __$AnalysisStateCopyWithImpl(this._self, this._then);

  final _AnalysisState _self;
  final $Res Function(_AnalysisState) _then;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? experiments = null,Object? selectedExperimentId = freezed,Object? devices = freezed,Object? selectedDeviceId = freezed,Object? points = freezed,Object? selectedPointIds = null,Object? timePreset = null,Object? customStart = freezed,Object? customEnd = freezed,Object? downsample = null,Object? chartData = null,Object? showDataTable = null,Object? isLoadingData = null,Object? hiddenPointIds = null,}) {
  return _then(_AnalysisState(
experiments: null == experiments ? _self.experiments : experiments // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<Experiment>>,selectedExperimentId: freezed == selectedExperimentId ? _self.selectedExperimentId : selectedExperimentId // ignore: cast_nullable_to_non_nullable
as String?,devices: freezed == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<Device>?,selectedDeviceId: freezed == selectedDeviceId ? _self.selectedDeviceId : selectedDeviceId // ignore: cast_nullable_to_non_nullable
as String?,points: freezed == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<Point>?,selectedPointIds: null == selectedPointIds ? _self._selectedPointIds : selectedPointIds // ignore: cast_nullable_to_non_nullable
as Set<String>,timePreset: null == timePreset ? _self.timePreset : timePreset // ignore: cast_nullable_to_non_nullable
as TimeRangePreset,customStart: freezed == customStart ? _self.customStart : customStart // ignore: cast_nullable_to_non_nullable
as DateTime?,customEnd: freezed == customEnd ? _self.customEnd : customEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,downsample: null == downsample ? _self.downsample : downsample // ignore: cast_nullable_to_non_nullable
as int,chartData: null == chartData ? _self.chartData : chartData // ignore: cast_nullable_to_non_nullable
as AsyncValue<ChartData?>,showDataTable: null == showDataTable ? _self.showDataTable : showDataTable // ignore: cast_nullable_to_non_nullable
as bool,isLoadingData: null == isLoadingData ? _self.isLoadingData : isLoadingData // ignore: cast_nullable_to_non_nullable
as bool,hiddenPointIds: null == hiddenPointIds ? _self._hiddenPointIds : hiddenPointIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
