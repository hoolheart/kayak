// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workbench_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$WorkbenchFormState {
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get nameError => throw _privateConstructorUsedError;
  String? get descriptionError => throw _privateConstructorUsedError;
  bool get isSubmitting => throw _privateConstructorUsedError;
  bool get isSuccess => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of WorkbenchFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkbenchFormStateCopyWith<WorkbenchFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkbenchFormStateCopyWith<$Res> {
  factory $WorkbenchFormStateCopyWith(
          WorkbenchFormState value, $Res Function(WorkbenchFormState) then) =
      _$WorkbenchFormStateCopyWithImpl<$Res, WorkbenchFormState>;
  @useResult
  $Res call(
      {String name,
      String description,
      String? nameError,
      String? descriptionError,
      bool isSubmitting,
      bool isSuccess,
      String? errorMessage});
}

/// @nodoc
class _$WorkbenchFormStateCopyWithImpl<$Res, $Val extends WorkbenchFormState>
    implements $WorkbenchFormStateCopyWith<$Res> {
  _$WorkbenchFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkbenchFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? nameError = freezed,
    Object? descriptionError = freezed,
    Object? isSubmitting = null,
    Object? isSuccess = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      nameError: freezed == nameError
          ? _value.nameError
          : nameError // ignore: cast_nullable_to_non_nullable
              as String?,
      descriptionError: freezed == descriptionError
          ? _value.descriptionError
          : descriptionError // ignore: cast_nullable_to_non_nullable
              as String?,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkbenchFormStateImplCopyWith<$Res>
    implements $WorkbenchFormStateCopyWith<$Res> {
  factory _$$WorkbenchFormStateImplCopyWith(_$WorkbenchFormStateImpl value,
          $Res Function(_$WorkbenchFormStateImpl) then) =
      __$$WorkbenchFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String description,
      String? nameError,
      String? descriptionError,
      bool isSubmitting,
      bool isSuccess,
      String? errorMessage});
}

/// @nodoc
class __$$WorkbenchFormStateImplCopyWithImpl<$Res>
    extends _$WorkbenchFormStateCopyWithImpl<$Res, _$WorkbenchFormStateImpl>
    implements _$$WorkbenchFormStateImplCopyWith<$Res> {
  __$$WorkbenchFormStateImplCopyWithImpl(_$WorkbenchFormStateImpl _value,
      $Res Function(_$WorkbenchFormStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkbenchFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? nameError = freezed,
    Object? descriptionError = freezed,
    Object? isSubmitting = null,
    Object? isSuccess = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$WorkbenchFormStateImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      nameError: freezed == nameError
          ? _value.nameError
          : nameError // ignore: cast_nullable_to_non_nullable
              as String?,
      descriptionError: freezed == descriptionError
          ? _value.descriptionError
          : descriptionError // ignore: cast_nullable_to_non_nullable
              as String?,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$WorkbenchFormStateImpl extends _WorkbenchFormState {
  const _$WorkbenchFormStateImpl(
      {this.name = '',
      this.description = '',
      this.nameError,
      this.descriptionError,
      this.isSubmitting = false,
      this.isSuccess = false,
      this.errorMessage})
      : super._();

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String description;
  @override
  final String? nameError;
  @override
  final String? descriptionError;
  @override
  @JsonKey()
  final bool isSubmitting;
  @override
  @JsonKey()
  final bool isSuccess;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'WorkbenchFormState(name: $name, description: $description, nameError: $nameError, descriptionError: $descriptionError, isSubmitting: $isSubmitting, isSuccess: $isSuccess, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkbenchFormStateImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.nameError, nameError) ||
                other.nameError == nameError) &&
            (identical(other.descriptionError, descriptionError) ||
                other.descriptionError == descriptionError) &&
            (identical(other.isSubmitting, isSubmitting) ||
                other.isSubmitting == isSubmitting) &&
            (identical(other.isSuccess, isSuccess) ||
                other.isSuccess == isSuccess) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, description, nameError,
      descriptionError, isSubmitting, isSuccess, errorMessage);

  /// Create a copy of WorkbenchFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkbenchFormStateImplCopyWith<_$WorkbenchFormStateImpl> get copyWith =>
      __$$WorkbenchFormStateImplCopyWithImpl<_$WorkbenchFormStateImpl>(
          this, _$identity);
}

abstract class _WorkbenchFormState extends WorkbenchFormState {
  const factory _WorkbenchFormState(
      {final String name,
      final String description,
      final String? nameError,
      final String? descriptionError,
      final bool isSubmitting,
      final bool isSuccess,
      final String? errorMessage}) = _$WorkbenchFormStateImpl;
  const _WorkbenchFormState._() : super._();

  @override
  String get name;
  @override
  String get description;
  @override
  String? get nameError;
  @override
  String? get descriptionError;
  @override
  bool get isSubmitting;
  @override
  bool get isSuccess;
  @override
  String? get errorMessage;

  /// Create a copy of WorkbenchFormState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkbenchFormStateImplCopyWith<_$WorkbenchFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
