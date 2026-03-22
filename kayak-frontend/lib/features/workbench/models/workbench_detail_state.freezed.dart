// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workbench_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$WorkbenchDetailState {
  Workbench? get workbench => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isRefreshing => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of WorkbenchDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkbenchDetailStateCopyWith<WorkbenchDetailState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkbenchDetailStateCopyWith<$Res> {
  factory $WorkbenchDetailStateCopyWith(WorkbenchDetailState value,
          $Res Function(WorkbenchDetailState) then) =
      _$WorkbenchDetailStateCopyWithImpl<$Res, WorkbenchDetailState>;
  @useResult
  $Res call(
      {Workbench? workbench, bool isLoading, bool isRefreshing, String? error});

  $WorkbenchCopyWith<$Res>? get workbench;
}

/// @nodoc
class _$WorkbenchDetailStateCopyWithImpl<$Res,
        $Val extends WorkbenchDetailState>
    implements $WorkbenchDetailStateCopyWith<$Res> {
  _$WorkbenchDetailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkbenchDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workbench = freezed,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      workbench: freezed == workbench
          ? _value.workbench
          : workbench // ignore: cast_nullable_to_non_nullable
              as Workbench?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRefreshing: null == isRefreshing
          ? _value.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of WorkbenchDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WorkbenchCopyWith<$Res>? get workbench {
    if (_value.workbench == null) {
      return null;
    }

    return $WorkbenchCopyWith<$Res>(_value.workbench!, (value) {
      return _then(_value.copyWith(workbench: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WorkbenchDetailStateImplCopyWith<$Res>
    implements $WorkbenchDetailStateCopyWith<$Res> {
  factory _$$WorkbenchDetailStateImplCopyWith(_$WorkbenchDetailStateImpl value,
          $Res Function(_$WorkbenchDetailStateImpl) then) =
      __$$WorkbenchDetailStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Workbench? workbench, bool isLoading, bool isRefreshing, String? error});

  @override
  $WorkbenchCopyWith<$Res>? get workbench;
}

/// @nodoc
class __$$WorkbenchDetailStateImplCopyWithImpl<$Res>
    extends _$WorkbenchDetailStateCopyWithImpl<$Res, _$WorkbenchDetailStateImpl>
    implements _$$WorkbenchDetailStateImplCopyWith<$Res> {
  __$$WorkbenchDetailStateImplCopyWithImpl(_$WorkbenchDetailStateImpl _value,
      $Res Function(_$WorkbenchDetailStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkbenchDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workbench = freezed,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
  }) {
    return _then(_$WorkbenchDetailStateImpl(
      workbench: freezed == workbench
          ? _value.workbench
          : workbench // ignore: cast_nullable_to_non_nullable
              as Workbench?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRefreshing: null == isRefreshing
          ? _value.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$WorkbenchDetailStateImpl implements _WorkbenchDetailState {
  const _$WorkbenchDetailStateImpl(
      {this.workbench,
      this.isLoading = false,
      this.isRefreshing = false,
      this.error});

  @override
  final Workbench? workbench;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isRefreshing;
  @override
  final String? error;

  @override
  String toString() {
    return 'WorkbenchDetailState(workbench: $workbench, isLoading: $isLoading, isRefreshing: $isRefreshing, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkbenchDetailStateImpl &&
            (identical(other.workbench, workbench) ||
                other.workbench == workbench) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, workbench, isLoading, isRefreshing, error);

  /// Create a copy of WorkbenchDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkbenchDetailStateImplCopyWith<_$WorkbenchDetailStateImpl>
      get copyWith =>
          __$$WorkbenchDetailStateImplCopyWithImpl<_$WorkbenchDetailStateImpl>(
              this, _$identity);
}

abstract class _WorkbenchDetailState implements WorkbenchDetailState {
  const factory _WorkbenchDetailState(
      {final Workbench? workbench,
      final bool isLoading,
      final bool isRefreshing,
      final String? error}) = _$WorkbenchDetailStateImpl;

  @override
  Workbench? get workbench;
  @override
  bool get isLoading;
  @override
  bool get isRefreshing;
  @override
  String? get error;

  /// Create a copy of WorkbenchDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkbenchDetailStateImplCopyWith<_$WorkbenchDetailStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
