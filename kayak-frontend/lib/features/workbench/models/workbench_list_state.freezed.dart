// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workbench_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$WorkbenchListState {
  List<Workbench> get workbenches => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isRefreshing => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;

  /// Create a copy of WorkbenchListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkbenchListStateCopyWith<WorkbenchListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkbenchListStateCopyWith<$Res> {
  factory $WorkbenchListStateCopyWith(
          WorkbenchListState value, $Res Function(WorkbenchListState) then) =
      _$WorkbenchListStateCopyWithImpl<$Res, WorkbenchListState>;
  @useResult
  $Res call(
      {List<Workbench> workbenches,
      bool isLoading,
      bool isRefreshing,
      String? error,
      int currentPage,
      int pageSize,
      bool hasMore});
}

/// @nodoc
class _$WorkbenchListStateCopyWithImpl<$Res, $Val extends WorkbenchListState>
    implements $WorkbenchListStateCopyWith<$Res> {
  _$WorkbenchListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkbenchListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workbenches = null,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
    Object? currentPage = null,
    Object? pageSize = null,
    Object? hasMore = null,
  }) {
    return _then(_value.copyWith(
      workbenches: null == workbenches
          ? _value.workbenches
          : workbenches // ignore: cast_nullable_to_non_nullable
              as List<Workbench>,
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
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkbenchListStateImplCopyWith<$Res>
    implements $WorkbenchListStateCopyWith<$Res> {
  factory _$$WorkbenchListStateImplCopyWith(_$WorkbenchListStateImpl value,
          $Res Function(_$WorkbenchListStateImpl) then) =
      __$$WorkbenchListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Workbench> workbenches,
      bool isLoading,
      bool isRefreshing,
      String? error,
      int currentPage,
      int pageSize,
      bool hasMore});
}

/// @nodoc
class __$$WorkbenchListStateImplCopyWithImpl<$Res>
    extends _$WorkbenchListStateCopyWithImpl<$Res, _$WorkbenchListStateImpl>
    implements _$$WorkbenchListStateImplCopyWith<$Res> {
  __$$WorkbenchListStateImplCopyWithImpl(_$WorkbenchListStateImpl _value,
      $Res Function(_$WorkbenchListStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkbenchListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workbenches = null,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
    Object? currentPage = null,
    Object? pageSize = null,
    Object? hasMore = null,
  }) {
    return _then(_$WorkbenchListStateImpl(
      workbenches: null == workbenches
          ? _value._workbenches
          : workbenches // ignore: cast_nullable_to_non_nullable
              as List<Workbench>,
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
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$WorkbenchListStateImpl implements _WorkbenchListState {
  const _$WorkbenchListStateImpl(
      {final List<Workbench> workbenches = const [],
      this.isLoading = false,
      this.isRefreshing = false,
      this.error,
      this.currentPage = 1,
      this.pageSize = 20,
      this.hasMore = true})
      : _workbenches = workbenches;

  final List<Workbench> _workbenches;
  @override
  @JsonKey()
  List<Workbench> get workbenches {
    if (_workbenches is EqualUnmodifiableListView) return _workbenches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workbenches);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isRefreshing;
  @override
  final String? error;
  @override
  @JsonKey()
  final int currentPage;
  @override
  @JsonKey()
  final int pageSize;
  @override
  @JsonKey()
  final bool hasMore;

  @override
  String toString() {
    return 'WorkbenchListState(workbenches: $workbenches, isLoading: $isLoading, isRefreshing: $isRefreshing, error: $error, currentPage: $currentPage, pageSize: $pageSize, hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkbenchListStateImpl &&
            const DeepCollectionEquality()
                .equals(other._workbenches, _workbenches) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_workbenches),
      isLoading,
      isRefreshing,
      error,
      currentPage,
      pageSize,
      hasMore);

  /// Create a copy of WorkbenchListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkbenchListStateImplCopyWith<_$WorkbenchListStateImpl> get copyWith =>
      __$$WorkbenchListStateImplCopyWithImpl<_$WorkbenchListStateImpl>(
          this, _$identity);
}

abstract class _WorkbenchListState implements WorkbenchListState {
  const factory _WorkbenchListState(
      {final List<Workbench> workbenches,
      final bool isLoading,
      final bool isRefreshing,
      final String? error,
      final int currentPage,
      final int pageSize,
      final bool hasMore}) = _$WorkbenchListStateImpl;

  @override
  List<Workbench> get workbenches;
  @override
  bool get isLoading;
  @override
  bool get isRefreshing;
  @override
  String? get error;
  @override
  int get currentPage;
  @override
  int get pageSize;
  @override
  bool get hasMore;

  /// Create a copy of WorkbenchListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkbenchListStateImplCopyWith<_$WorkbenchListStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
