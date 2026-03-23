// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_tree_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DeviceTreeNode _$DeviceTreeNodeFromJson(Map<String, dynamic> json) {
  return _DeviceTreeNode.fromJson(json);
}

/// @nodoc
mixin _$DeviceTreeNode {
  Device get device => throw _privateConstructorUsedError;
  List<DeviceTreeNode> get children => throw _privateConstructorUsedError;
  bool get isExpanded => throw _privateConstructorUsedError;

  /// Serializes this DeviceTreeNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeviceTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceTreeNodeCopyWith<DeviceTreeNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceTreeNodeCopyWith<$Res> {
  factory $DeviceTreeNodeCopyWith(
          DeviceTreeNode value, $Res Function(DeviceTreeNode) then) =
      _$DeviceTreeNodeCopyWithImpl<$Res, DeviceTreeNode>;
  @useResult
  $Res call({Device device, List<DeviceTreeNode> children, bool isExpanded});

  $DeviceCopyWith<$Res> get device;
}

/// @nodoc
class _$DeviceTreeNodeCopyWithImpl<$Res, $Val extends DeviceTreeNode>
    implements $DeviceTreeNodeCopyWith<$Res> {
  _$DeviceTreeNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? device = null,
    Object? children = null,
    Object? isExpanded = null,
  }) {
    return _then(_value.copyWith(
      device: null == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as Device,
      children: null == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<DeviceTreeNode>,
      isExpanded: null == isExpanded
          ? _value.isExpanded
          : isExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of DeviceTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DeviceCopyWith<$Res> get device {
    return $DeviceCopyWith<$Res>(_value.device, (value) {
      return _then(_value.copyWith(device: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DeviceTreeNodeImplCopyWith<$Res>
    implements $DeviceTreeNodeCopyWith<$Res> {
  factory _$$DeviceTreeNodeImplCopyWith(_$DeviceTreeNodeImpl value,
          $Res Function(_$DeviceTreeNodeImpl) then) =
      __$$DeviceTreeNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Device device, List<DeviceTreeNode> children, bool isExpanded});

  @override
  $DeviceCopyWith<$Res> get device;
}

/// @nodoc
class __$$DeviceTreeNodeImplCopyWithImpl<$Res>
    extends _$DeviceTreeNodeCopyWithImpl<$Res, _$DeviceTreeNodeImpl>
    implements _$$DeviceTreeNodeImplCopyWith<$Res> {
  __$$DeviceTreeNodeImplCopyWithImpl(
      _$DeviceTreeNodeImpl _value, $Res Function(_$DeviceTreeNodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeviceTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? device = null,
    Object? children = null,
    Object? isExpanded = null,
  }) {
    return _then(_$DeviceTreeNodeImpl(
      device: null == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as Device,
      children: null == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<DeviceTreeNode>,
      isExpanded: null == isExpanded
          ? _value.isExpanded
          : isExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceTreeNodeImpl implements _DeviceTreeNode {
  const _$DeviceTreeNodeImpl(
      {required this.device,
      required final List<DeviceTreeNode> children,
      this.isExpanded = false})
      : _children = children;

  factory _$DeviceTreeNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceTreeNodeImplFromJson(json);

  @override
  final Device device;
  final List<DeviceTreeNode> _children;
  @override
  List<DeviceTreeNode> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  @override
  @JsonKey()
  final bool isExpanded;

  @override
  String toString() {
    return 'DeviceTreeNode(device: $device, children: $children, isExpanded: $isExpanded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceTreeNodeImpl &&
            (identical(other.device, device) || other.device == device) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            (identical(other.isExpanded, isExpanded) ||
                other.isExpanded == isExpanded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, device,
      const DeepCollectionEquality().hash(_children), isExpanded);

  /// Create a copy of DeviceTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceTreeNodeImplCopyWith<_$DeviceTreeNodeImpl> get copyWith =>
      __$$DeviceTreeNodeImplCopyWithImpl<_$DeviceTreeNodeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceTreeNodeImplToJson(
      this,
    );
  }
}

abstract class _DeviceTreeNode implements DeviceTreeNode {
  const factory _DeviceTreeNode(
      {required final Device device,
      required final List<DeviceTreeNode> children,
      final bool isExpanded}) = _$DeviceTreeNodeImpl;

  factory _DeviceTreeNode.fromJson(Map<String, dynamic> json) =
      _$DeviceTreeNodeImpl.fromJson;

  @override
  Device get device;
  @override
  List<DeviceTreeNode> get children;
  @override
  bool get isExpanded;

  /// Create a copy of DeviceTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceTreeNodeImplCopyWith<_$DeviceTreeNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
