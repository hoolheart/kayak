// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_tree_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DeviceTreeState {
  List<DeviceTreeNode> get nodes => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isRefreshing => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of DeviceTreeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceTreeStateCopyWith<DeviceTreeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceTreeStateCopyWith<$Res> {
  factory $DeviceTreeStateCopyWith(
          DeviceTreeState value, $Res Function(DeviceTreeState) then) =
      _$DeviceTreeStateCopyWithImpl<$Res, DeviceTreeState>;
  @useResult
  $Res call(
      {List<DeviceTreeNode> nodes,
      bool isLoading,
      bool isRefreshing,
      String? error});
}

/// @nodoc
class _$DeviceTreeStateCopyWithImpl<$Res, $Val extends DeviceTreeState>
    implements $DeviceTreeStateCopyWith<$Res> {
  _$DeviceTreeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceTreeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodes = null,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      nodes: null == nodes
          ? _value.nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<DeviceTreeNode>,
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
}

/// @nodoc
abstract class _$$DeviceTreeStateImplCopyWith<$Res>
    implements $DeviceTreeStateCopyWith<$Res> {
  factory _$$DeviceTreeStateImplCopyWith(_$DeviceTreeStateImpl value,
          $Res Function(_$DeviceTreeStateImpl) then) =
      __$$DeviceTreeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<DeviceTreeNode> nodes,
      bool isLoading,
      bool isRefreshing,
      String? error});
}

/// @nodoc
class __$$DeviceTreeStateImplCopyWithImpl<$Res>
    extends _$DeviceTreeStateCopyWithImpl<$Res, _$DeviceTreeStateImpl>
    implements _$$DeviceTreeStateImplCopyWith<$Res> {
  __$$DeviceTreeStateImplCopyWithImpl(
      _$DeviceTreeStateImpl _value, $Res Function(_$DeviceTreeStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeviceTreeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodes = null,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
  }) {
    return _then(_$DeviceTreeStateImpl(
      nodes: null == nodes
          ? _value._nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<DeviceTreeNode>,
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

class _$DeviceTreeStateImpl implements _DeviceTreeState {
  const _$DeviceTreeStateImpl(
      {final List<DeviceTreeNode> nodes = const [],
      this.isLoading = false,
      this.isRefreshing = false,
      this.error})
      : _nodes = nodes;

  final List<DeviceTreeNode> _nodes;
  @override
  @JsonKey()
  List<DeviceTreeNode> get nodes {
    if (_nodes is EqualUnmodifiableListView) return _nodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodes);
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
  String toString() {
    return 'DeviceTreeState(nodes: $nodes, isLoading: $isLoading, isRefreshing: $isRefreshing, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceTreeStateImpl &&
            const DeepCollectionEquality().equals(other._nodes, _nodes) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_nodes),
      isLoading,
      isRefreshing,
      error);

  /// Create a copy of DeviceTreeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceTreeStateImplCopyWith<_$DeviceTreeStateImpl> get copyWith =>
      __$$DeviceTreeStateImplCopyWithImpl<_$DeviceTreeStateImpl>(
          this, _$identity);
}

abstract class _DeviceTreeState implements DeviceTreeState {
  const factory _DeviceTreeState(
      {final List<DeviceTreeNode> nodes,
      final bool isLoading,
      final bool isRefreshing,
      final String? error}) = _$DeviceTreeStateImpl;

  @override
  List<DeviceTreeNode> get nodes;
  @override
  bool get isLoading;
  @override
  bool get isRefreshing;
  @override
  String? get error;

  /// Create a copy of DeviceTreeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceTreeStateImplCopyWith<_$DeviceTreeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
