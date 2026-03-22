// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workbench.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Workbench _$WorkbenchFromJson(Map<String, dynamic> json) {
  return _Workbench.fromJson(json);
}

/// @nodoc
mixin _$Workbench {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'ownerType')
  String get ownerType => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Workbench to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Workbench
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkbenchCopyWith<Workbench> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkbenchCopyWith<$Res> {
  factory $WorkbenchCopyWith(Workbench value, $Res Function(Workbench) then) =
      _$WorkbenchCopyWithImpl<$Res, Workbench>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String ownerId,
      @JsonKey(name: 'ownerType') String ownerType,
      String status,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$WorkbenchCopyWithImpl<$Res, $Val extends Workbench>
    implements $WorkbenchCopyWith<$Res> {
  _$WorkbenchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Workbench
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? ownerId = null,
    Object? ownerType = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerType: null == ownerType
          ? _value.ownerType
          : ownerType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkbenchImplCopyWith<$Res>
    implements $WorkbenchCopyWith<$Res> {
  factory _$$WorkbenchImplCopyWith(
          _$WorkbenchImpl value, $Res Function(_$WorkbenchImpl) then) =
      __$$WorkbenchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String ownerId,
      @JsonKey(name: 'ownerType') String ownerType,
      String status,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$WorkbenchImplCopyWithImpl<$Res>
    extends _$WorkbenchCopyWithImpl<$Res, _$WorkbenchImpl>
    implements _$$WorkbenchImplCopyWith<$Res> {
  __$$WorkbenchImplCopyWithImpl(
      _$WorkbenchImpl _value, $Res Function(_$WorkbenchImpl) _then)
      : super(_value, _then);

  /// Create a copy of Workbench
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? ownerId = null,
    Object? ownerType = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$WorkbenchImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerType: null == ownerType
          ? _value.ownerType
          : ownerType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkbenchImpl implements _Workbench {
  const _$WorkbenchImpl(
      {required this.id,
      required this.name,
      this.description,
      required this.ownerId,
      @JsonKey(name: 'ownerType') required this.ownerType,
      required this.status,
      required this.createdAt,
      required this.updatedAt});

  factory _$WorkbenchImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkbenchImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String ownerId;
  @override
  @JsonKey(name: 'ownerType')
  final String ownerType;
  @override
  final String status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Workbench(id: $id, name: $name, description: $description, ownerId: $ownerId, ownerType: $ownerType, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkbenchImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.ownerType, ownerType) ||
                other.ownerType == ownerType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, ownerId,
      ownerType, status, createdAt, updatedAt);

  /// Create a copy of Workbench
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkbenchImplCopyWith<_$WorkbenchImpl> get copyWith =>
      __$$WorkbenchImplCopyWithImpl<_$WorkbenchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkbenchImplToJson(
      this,
    );
  }
}

abstract class _Workbench implements Workbench {
  const factory _Workbench(
      {required final String id,
      required final String name,
      final String? description,
      required final String ownerId,
      @JsonKey(name: 'ownerType') required final String ownerType,
      required final String status,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$WorkbenchImpl;

  factory _Workbench.fromJson(Map<String, dynamic> json) =
      _$WorkbenchImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get ownerId;
  @override
  @JsonKey(name: 'ownerType')
  String get ownerType;
  @override
  String get status;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Workbench
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkbenchImplCopyWith<_$WorkbenchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PagedWorkbenchResponse _$PagedWorkbenchResponseFromJson(
    Map<String, dynamic> json) {
  return _PagedWorkbenchResponse.fromJson(json);
}

/// @nodoc
mixin _$PagedWorkbenchResponse {
  List<Workbench> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;

  /// Serializes this PagedWorkbenchResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PagedWorkbenchResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PagedWorkbenchResponseCopyWith<PagedWorkbenchResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PagedWorkbenchResponseCopyWith<$Res> {
  factory $PagedWorkbenchResponseCopyWith(PagedWorkbenchResponse value,
          $Res Function(PagedWorkbenchResponse) then) =
      _$PagedWorkbenchResponseCopyWithImpl<$Res, PagedWorkbenchResponse>;
  @useResult
  $Res call({List<Workbench> items, int total, int page, int size});
}

/// @nodoc
class _$PagedWorkbenchResponseCopyWithImpl<$Res,
        $Val extends PagedWorkbenchResponse>
    implements $PagedWorkbenchResponseCopyWith<$Res> {
  _$PagedWorkbenchResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PagedWorkbenchResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? size = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Workbench>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PagedWorkbenchResponseImplCopyWith<$Res>
    implements $PagedWorkbenchResponseCopyWith<$Res> {
  factory _$$PagedWorkbenchResponseImplCopyWith(
          _$PagedWorkbenchResponseImpl value,
          $Res Function(_$PagedWorkbenchResponseImpl) then) =
      __$$PagedWorkbenchResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Workbench> items, int total, int page, int size});
}

/// @nodoc
class __$$PagedWorkbenchResponseImplCopyWithImpl<$Res>
    extends _$PagedWorkbenchResponseCopyWithImpl<$Res,
        _$PagedWorkbenchResponseImpl>
    implements _$$PagedWorkbenchResponseImplCopyWith<$Res> {
  __$$PagedWorkbenchResponseImplCopyWithImpl(
      _$PagedWorkbenchResponseImpl _value,
      $Res Function(_$PagedWorkbenchResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of PagedWorkbenchResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? size = null,
  }) {
    return _then(_$PagedWorkbenchResponseImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Workbench>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PagedWorkbenchResponseImpl implements _PagedWorkbenchResponse {
  const _$PagedWorkbenchResponseImpl(
      {required final List<Workbench> items,
      required this.total,
      required this.page,
      required this.size})
      : _items = items;

  factory _$PagedWorkbenchResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PagedWorkbenchResponseImplFromJson(json);

  final List<Workbench> _items;
  @override
  List<Workbench> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int size;

  @override
  String toString() {
    return 'PagedWorkbenchResponse(items: $items, total: $total, page: $page, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PagedWorkbenchResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.size, size) || other.size == size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), total, page, size);

  /// Create a copy of PagedWorkbenchResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PagedWorkbenchResponseImplCopyWith<_$PagedWorkbenchResponseImpl>
      get copyWith => __$$PagedWorkbenchResponseImplCopyWithImpl<
          _$PagedWorkbenchResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PagedWorkbenchResponseImplToJson(
      this,
    );
  }
}

abstract class _PagedWorkbenchResponse implements PagedWorkbenchResponse {
  const factory _PagedWorkbenchResponse(
      {required final List<Workbench> items,
      required final int total,
      required final int page,
      required final int size}) = _$PagedWorkbenchResponseImpl;

  factory _PagedWorkbenchResponse.fromJson(Map<String, dynamic> json) =
      _$PagedWorkbenchResponseImpl.fromJson;

  @override
  List<Workbench> get items;
  @override
  int get total;
  @override
  int get page;
  @override
  int get size;

  /// Create a copy of PagedWorkbenchResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PagedWorkbenchResponseImplCopyWith<_$PagedWorkbenchResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CreateWorkbenchRequest _$CreateWorkbenchRequestFromJson(
    Map<String, dynamic> json) {
  return _CreateWorkbenchRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateWorkbenchRequest {
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'ownerType')
  String? get ownerType => throw _privateConstructorUsedError;

  /// Serializes this CreateWorkbenchRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateWorkbenchRequestCopyWith<CreateWorkbenchRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateWorkbenchRequestCopyWith<$Res> {
  factory $CreateWorkbenchRequestCopyWith(CreateWorkbenchRequest value,
          $Res Function(CreateWorkbenchRequest) then) =
      _$CreateWorkbenchRequestCopyWithImpl<$Res, CreateWorkbenchRequest>;
  @useResult
  $Res call(
      {String name,
      String? description,
      @JsonKey(name: 'ownerType') String? ownerType});
}

/// @nodoc
class _$CreateWorkbenchRequestCopyWithImpl<$Res,
        $Val extends CreateWorkbenchRequest>
    implements $CreateWorkbenchRequestCopyWith<$Res> {
  _$CreateWorkbenchRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = freezed,
    Object? ownerType = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerType: freezed == ownerType
          ? _value.ownerType
          : ownerType // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CreateWorkbenchRequestImplCopyWith<$Res>
    implements $CreateWorkbenchRequestCopyWith<$Res> {
  factory _$$CreateWorkbenchRequestImplCopyWith(
          _$CreateWorkbenchRequestImpl value,
          $Res Function(_$CreateWorkbenchRequestImpl) then) =
      __$$CreateWorkbenchRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String? description,
      @JsonKey(name: 'ownerType') String? ownerType});
}

/// @nodoc
class __$$CreateWorkbenchRequestImplCopyWithImpl<$Res>
    extends _$CreateWorkbenchRequestCopyWithImpl<$Res,
        _$CreateWorkbenchRequestImpl>
    implements _$$CreateWorkbenchRequestImplCopyWith<$Res> {
  __$$CreateWorkbenchRequestImplCopyWithImpl(
      _$CreateWorkbenchRequestImpl _value,
      $Res Function(_$CreateWorkbenchRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of CreateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = freezed,
    Object? ownerType = freezed,
  }) {
    return _then(_$CreateWorkbenchRequestImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerType: freezed == ownerType
          ? _value.ownerType
          : ownerType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateWorkbenchRequestImpl implements _CreateWorkbenchRequest {
  const _$CreateWorkbenchRequestImpl(
      {required this.name,
      this.description,
      @JsonKey(name: 'ownerType') this.ownerType});

  factory _$CreateWorkbenchRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateWorkbenchRequestImplFromJson(json);

  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'ownerType')
  final String? ownerType;

  @override
  String toString() {
    return 'CreateWorkbenchRequest(name: $name, description: $description, ownerType: $ownerType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateWorkbenchRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.ownerType, ownerType) ||
                other.ownerType == ownerType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, description, ownerType);

  /// Create a copy of CreateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateWorkbenchRequestImplCopyWith<_$CreateWorkbenchRequestImpl>
      get copyWith => __$$CreateWorkbenchRequestImplCopyWithImpl<
          _$CreateWorkbenchRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateWorkbenchRequestImplToJson(
      this,
    );
  }
}

abstract class _CreateWorkbenchRequest implements CreateWorkbenchRequest {
  const factory _CreateWorkbenchRequest(
          {required final String name,
          final String? description,
          @JsonKey(name: 'ownerType') final String? ownerType}) =
      _$CreateWorkbenchRequestImpl;

  factory _CreateWorkbenchRequest.fromJson(Map<String, dynamic> json) =
      _$CreateWorkbenchRequestImpl.fromJson;

  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'ownerType')
  String? get ownerType;

  /// Create a copy of CreateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateWorkbenchRequestImplCopyWith<_$CreateWorkbenchRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UpdateWorkbenchRequest _$UpdateWorkbenchRequestFromJson(
    Map<String, dynamic> json) {
  return _UpdateWorkbenchRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdateWorkbenchRequest {
  String? get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this UpdateWorkbenchRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateWorkbenchRequestCopyWith<UpdateWorkbenchRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateWorkbenchRequestCopyWith<$Res> {
  factory $UpdateWorkbenchRequestCopyWith(UpdateWorkbenchRequest value,
          $Res Function(UpdateWorkbenchRequest) then) =
      _$UpdateWorkbenchRequestCopyWithImpl<$Res, UpdateWorkbenchRequest>;
  @useResult
  $Res call({String? name, String? description});
}

/// @nodoc
class _$UpdateWorkbenchRequestCopyWithImpl<$Res,
        $Val extends UpdateWorkbenchRequest>
    implements $UpdateWorkbenchRequestCopyWith<$Res> {
  _$UpdateWorkbenchRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateWorkbenchRequestImplCopyWith<$Res>
    implements $UpdateWorkbenchRequestCopyWith<$Res> {
  factory _$$UpdateWorkbenchRequestImplCopyWith(
          _$UpdateWorkbenchRequestImpl value,
          $Res Function(_$UpdateWorkbenchRequestImpl) then) =
      __$$UpdateWorkbenchRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? name, String? description});
}

/// @nodoc
class __$$UpdateWorkbenchRequestImplCopyWithImpl<$Res>
    extends _$UpdateWorkbenchRequestCopyWithImpl<$Res,
        _$UpdateWorkbenchRequestImpl>
    implements _$$UpdateWorkbenchRequestImplCopyWith<$Res> {
  __$$UpdateWorkbenchRequestImplCopyWithImpl(
      _$UpdateWorkbenchRequestImpl _value,
      $Res Function(_$UpdateWorkbenchRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of UpdateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? description = freezed,
  }) {
    return _then(_$UpdateWorkbenchRequestImpl(
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateWorkbenchRequestImpl implements _UpdateWorkbenchRequest {
  const _$UpdateWorkbenchRequestImpl({this.name, this.description});

  factory _$UpdateWorkbenchRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateWorkbenchRequestImplFromJson(json);

  @override
  final String? name;
  @override
  final String? description;

  @override
  String toString() {
    return 'UpdateWorkbenchRequest(name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateWorkbenchRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, description);

  /// Create a copy of UpdateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateWorkbenchRequestImplCopyWith<_$UpdateWorkbenchRequestImpl>
      get copyWith => __$$UpdateWorkbenchRequestImplCopyWithImpl<
          _$UpdateWorkbenchRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateWorkbenchRequestImplToJson(
      this,
    );
  }
}

abstract class _UpdateWorkbenchRequest implements UpdateWorkbenchRequest {
  const factory _UpdateWorkbenchRequest(
      {final String? name,
      final String? description}) = _$UpdateWorkbenchRequestImpl;

  factory _UpdateWorkbenchRequest.fromJson(Map<String, dynamic> json) =
      _$UpdateWorkbenchRequestImpl.fromJson;

  @override
  String? get name;
  @override
  String? get description;

  /// Create a copy of UpdateWorkbenchRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateWorkbenchRequestImplCopyWith<_$UpdateWorkbenchRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}
