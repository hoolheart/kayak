// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'protocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
ProtocolConfig _$ProtocolConfigFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'virtual':
          return VirtualConfig.fromJson(
            json
          );
                case 'modbusTcp':
          return ModbusTcpConfig.fromJson(
            json
          );
                case 'modbusRtu':
          return ModbusRtuConfig.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'ProtocolConfig',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$ProtocolConfig {



  /// Serializes this ProtocolConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProtocolConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProtocolConfig()';
}


}

/// @nodoc
class $ProtocolConfigCopyWith<$Res>  {
$ProtocolConfigCopyWith(ProtocolConfig _, $Res Function(ProtocolConfig) __);
}


/// Adds pattern-matching-related methods to [ProtocolConfig].
extension ProtocolConfigPatterns on ProtocolConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VirtualConfig value)?  virtual,TResult Function( ModbusTcpConfig value)?  modbusTcp,TResult Function( ModbusRtuConfig value)?  modbusRtu,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VirtualConfig() when virtual != null:
return virtual(_that);case ModbusTcpConfig() when modbusTcp != null:
return modbusTcp(_that);case ModbusRtuConfig() when modbusRtu != null:
return modbusRtu(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VirtualConfig value)  virtual,required TResult Function( ModbusTcpConfig value)  modbusTcp,required TResult Function( ModbusRtuConfig value)  modbusRtu,}){
final _that = this;
switch (_that) {
case VirtualConfig():
return virtual(_that);case ModbusTcpConfig():
return modbusTcp(_that);case ModbusRtuConfig():
return modbusRtu(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VirtualConfig value)?  virtual,TResult? Function( ModbusTcpConfig value)?  modbusTcp,TResult? Function( ModbusRtuConfig value)?  modbusRtu,}){
final _that = this;
switch (_that) {
case VirtualConfig() when virtual != null:
return virtual(_that);case ModbusTcpConfig() when modbusTcp != null:
return modbusTcp(_that);case ModbusRtuConfig() when modbusRtu != null:
return modbusRtu(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String mode, @JsonKey(name: 'data_type')  String dataType,  double? min,  double? max, @JsonKey(name: 'interval_ms')  int? intervalMs)?  virtual,TResult Function( String host,  int port, @JsonKey(name: 'slave_id')  int? slaveId, @JsonKey(name: 'timeout_ms')  int? timeoutMs)?  modbusTcp,TResult Function(@JsonKey(name: 'serial_port')  String serialPort, @JsonKey(name: 'baud_rate')  int? baudRate, @JsonKey(name: 'data_bits')  int? dataBits, @JsonKey(name: 'stop_bits')  int? stopBits,  String? parity, @JsonKey(name: 'slave_id')  int? slaveId, @JsonKey(name: 'timeout_ms')  int? timeoutMs)?  modbusRtu,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VirtualConfig() when virtual != null:
return virtual(_that.mode,_that.dataType,_that.min,_that.max,_that.intervalMs);case ModbusTcpConfig() when modbusTcp != null:
return modbusTcp(_that.host,_that.port,_that.slaveId,_that.timeoutMs);case ModbusRtuConfig() when modbusRtu != null:
return modbusRtu(_that.serialPort,_that.baudRate,_that.dataBits,_that.stopBits,_that.parity,_that.slaveId,_that.timeoutMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String mode, @JsonKey(name: 'data_type')  String dataType,  double? min,  double? max, @JsonKey(name: 'interval_ms')  int? intervalMs)  virtual,required TResult Function( String host,  int port, @JsonKey(name: 'slave_id')  int? slaveId, @JsonKey(name: 'timeout_ms')  int? timeoutMs)  modbusTcp,required TResult Function(@JsonKey(name: 'serial_port')  String serialPort, @JsonKey(name: 'baud_rate')  int? baudRate, @JsonKey(name: 'data_bits')  int? dataBits, @JsonKey(name: 'stop_bits')  int? stopBits,  String? parity, @JsonKey(name: 'slave_id')  int? slaveId, @JsonKey(name: 'timeout_ms')  int? timeoutMs)  modbusRtu,}) {final _that = this;
switch (_that) {
case VirtualConfig():
return virtual(_that.mode,_that.dataType,_that.min,_that.max,_that.intervalMs);case ModbusTcpConfig():
return modbusTcp(_that.host,_that.port,_that.slaveId,_that.timeoutMs);case ModbusRtuConfig():
return modbusRtu(_that.serialPort,_that.baudRate,_that.dataBits,_that.stopBits,_that.parity,_that.slaveId,_that.timeoutMs);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String mode, @JsonKey(name: 'data_type')  String dataType,  double? min,  double? max, @JsonKey(name: 'interval_ms')  int? intervalMs)?  virtual,TResult? Function( String host,  int port, @JsonKey(name: 'slave_id')  int? slaveId, @JsonKey(name: 'timeout_ms')  int? timeoutMs)?  modbusTcp,TResult? Function(@JsonKey(name: 'serial_port')  String serialPort, @JsonKey(name: 'baud_rate')  int? baudRate, @JsonKey(name: 'data_bits')  int? dataBits, @JsonKey(name: 'stop_bits')  int? stopBits,  String? parity, @JsonKey(name: 'slave_id')  int? slaveId, @JsonKey(name: 'timeout_ms')  int? timeoutMs)?  modbusRtu,}) {final _that = this;
switch (_that) {
case VirtualConfig() when virtual != null:
return virtual(_that.mode,_that.dataType,_that.min,_that.max,_that.intervalMs);case ModbusTcpConfig() when modbusTcp != null:
return modbusTcp(_that.host,_that.port,_that.slaveId,_that.timeoutMs);case ModbusRtuConfig() when modbusRtu != null:
return modbusRtu(_that.serialPort,_that.baudRate,_that.dataBits,_that.stopBits,_that.parity,_that.slaveId,_that.timeoutMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class VirtualConfig implements ProtocolConfig {
  const VirtualConfig({required this.mode, @JsonKey(name: 'data_type') required this.dataType, this.min, this.max, @JsonKey(name: 'interval_ms') this.intervalMs, final  String? $type}): $type = $type ?? 'virtual';
  factory VirtualConfig.fromJson(Map<String, dynamic> json) => _$VirtualConfigFromJson(json);

 final  String mode;
@JsonKey(name: 'data_type') final  String dataType;
 final  double? min;
 final  double? max;
@JsonKey(name: 'interval_ms') final  int? intervalMs;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ProtocolConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VirtualConfigCopyWith<VirtualConfig> get copyWith => _$VirtualConfigCopyWithImpl<VirtualConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VirtualConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VirtualConfig&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.dataType, dataType) || other.dataType == dataType)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&(identical(other.intervalMs, intervalMs) || other.intervalMs == intervalMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,dataType,min,max,intervalMs);

@override
String toString() {
  return 'ProtocolConfig.virtual(mode: $mode, dataType: $dataType, min: $min, max: $max, intervalMs: $intervalMs)';
}


}

/// @nodoc
abstract mixin class $VirtualConfigCopyWith<$Res> implements $ProtocolConfigCopyWith<$Res> {
  factory $VirtualConfigCopyWith(VirtualConfig value, $Res Function(VirtualConfig) _then) = _$VirtualConfigCopyWithImpl;
@useResult
$Res call({
 String mode,@JsonKey(name: 'data_type') String dataType, double? min, double? max,@JsonKey(name: 'interval_ms') int? intervalMs
});




}
/// @nodoc
class _$VirtualConfigCopyWithImpl<$Res>
    implements $VirtualConfigCopyWith<$Res> {
  _$VirtualConfigCopyWithImpl(this._self, this._then);

  final VirtualConfig _self;
  final $Res Function(VirtualConfig) _then;

/// Create a copy of ProtocolConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? dataType = null,Object? min = freezed,Object? max = freezed,Object? intervalMs = freezed,}) {
  return _then(VirtualConfig(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,dataType: null == dataType ? _self.dataType : dataType // ignore: cast_nullable_to_non_nullable
as String,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as double?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double?,intervalMs: freezed == intervalMs ? _self.intervalMs : intervalMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ModbusTcpConfig implements ProtocolConfig {
  const ModbusTcpConfig({required this.host, required this.port, @JsonKey(name: 'slave_id') this.slaveId, @JsonKey(name: 'timeout_ms') this.timeoutMs, final  String? $type}): $type = $type ?? 'modbusTcp';
  factory ModbusTcpConfig.fromJson(Map<String, dynamic> json) => _$ModbusTcpConfigFromJson(json);

 final  String host;
 final  int port;
@JsonKey(name: 'slave_id') final  int? slaveId;
@JsonKey(name: 'timeout_ms') final  int? timeoutMs;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ProtocolConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModbusTcpConfigCopyWith<ModbusTcpConfig> get copyWith => _$ModbusTcpConfigCopyWithImpl<ModbusTcpConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModbusTcpConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModbusTcpConfig&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.slaveId, slaveId) || other.slaveId == slaveId)&&(identical(other.timeoutMs, timeoutMs) || other.timeoutMs == timeoutMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,host,port,slaveId,timeoutMs);

@override
String toString() {
  return 'ProtocolConfig.modbusTcp(host: $host, port: $port, slaveId: $slaveId, timeoutMs: $timeoutMs)';
}


}

/// @nodoc
abstract mixin class $ModbusTcpConfigCopyWith<$Res> implements $ProtocolConfigCopyWith<$Res> {
  factory $ModbusTcpConfigCopyWith(ModbusTcpConfig value, $Res Function(ModbusTcpConfig) _then) = _$ModbusTcpConfigCopyWithImpl;
@useResult
$Res call({
 String host, int port,@JsonKey(name: 'slave_id') int? slaveId,@JsonKey(name: 'timeout_ms') int? timeoutMs
});




}
/// @nodoc
class _$ModbusTcpConfigCopyWithImpl<$Res>
    implements $ModbusTcpConfigCopyWith<$Res> {
  _$ModbusTcpConfigCopyWithImpl(this._self, this._then);

  final ModbusTcpConfig _self;
  final $Res Function(ModbusTcpConfig) _then;

/// Create a copy of ProtocolConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? host = null,Object? port = null,Object? slaveId = freezed,Object? timeoutMs = freezed,}) {
  return _then(ModbusTcpConfig(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,slaveId: freezed == slaveId ? _self.slaveId : slaveId // ignore: cast_nullable_to_non_nullable
as int?,timeoutMs: freezed == timeoutMs ? _self.timeoutMs : timeoutMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ModbusRtuConfig implements ProtocolConfig {
  const ModbusRtuConfig({@JsonKey(name: 'serial_port') required this.serialPort, @JsonKey(name: 'baud_rate') this.baudRate, @JsonKey(name: 'data_bits') this.dataBits, @JsonKey(name: 'stop_bits') this.stopBits, this.parity, @JsonKey(name: 'slave_id') this.slaveId, @JsonKey(name: 'timeout_ms') this.timeoutMs, final  String? $type}): $type = $type ?? 'modbusRtu';
  factory ModbusRtuConfig.fromJson(Map<String, dynamic> json) => _$ModbusRtuConfigFromJson(json);

@JsonKey(name: 'serial_port') final  String serialPort;
@JsonKey(name: 'baud_rate') final  int? baudRate;
@JsonKey(name: 'data_bits') final  int? dataBits;
@JsonKey(name: 'stop_bits') final  int? stopBits;
 final  String? parity;
@JsonKey(name: 'slave_id') final  int? slaveId;
@JsonKey(name: 'timeout_ms') final  int? timeoutMs;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ProtocolConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModbusRtuConfigCopyWith<ModbusRtuConfig> get copyWith => _$ModbusRtuConfigCopyWithImpl<ModbusRtuConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModbusRtuConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModbusRtuConfig&&(identical(other.serialPort, serialPort) || other.serialPort == serialPort)&&(identical(other.baudRate, baudRate) || other.baudRate == baudRate)&&(identical(other.dataBits, dataBits) || other.dataBits == dataBits)&&(identical(other.stopBits, stopBits) || other.stopBits == stopBits)&&(identical(other.parity, parity) || other.parity == parity)&&(identical(other.slaveId, slaveId) || other.slaveId == slaveId)&&(identical(other.timeoutMs, timeoutMs) || other.timeoutMs == timeoutMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serialPort,baudRate,dataBits,stopBits,parity,slaveId,timeoutMs);

@override
String toString() {
  return 'ProtocolConfig.modbusRtu(serialPort: $serialPort, baudRate: $baudRate, dataBits: $dataBits, stopBits: $stopBits, parity: $parity, slaveId: $slaveId, timeoutMs: $timeoutMs)';
}


}

/// @nodoc
abstract mixin class $ModbusRtuConfigCopyWith<$Res> implements $ProtocolConfigCopyWith<$Res> {
  factory $ModbusRtuConfigCopyWith(ModbusRtuConfig value, $Res Function(ModbusRtuConfig) _then) = _$ModbusRtuConfigCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'serial_port') String serialPort,@JsonKey(name: 'baud_rate') int? baudRate,@JsonKey(name: 'data_bits') int? dataBits,@JsonKey(name: 'stop_bits') int? stopBits, String? parity,@JsonKey(name: 'slave_id') int? slaveId,@JsonKey(name: 'timeout_ms') int? timeoutMs
});




}
/// @nodoc
class _$ModbusRtuConfigCopyWithImpl<$Res>
    implements $ModbusRtuConfigCopyWith<$Res> {
  _$ModbusRtuConfigCopyWithImpl(this._self, this._then);

  final ModbusRtuConfig _self;
  final $Res Function(ModbusRtuConfig) _then;

/// Create a copy of ProtocolConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? serialPort = null,Object? baudRate = freezed,Object? dataBits = freezed,Object? stopBits = freezed,Object? parity = freezed,Object? slaveId = freezed,Object? timeoutMs = freezed,}) {
  return _then(ModbusRtuConfig(
serialPort: null == serialPort ? _self.serialPort : serialPort // ignore: cast_nullable_to_non_nullable
as String,baudRate: freezed == baudRate ? _self.baudRate : baudRate // ignore: cast_nullable_to_non_nullable
as int?,dataBits: freezed == dataBits ? _self.dataBits : dataBits // ignore: cast_nullable_to_non_nullable
as int?,stopBits: freezed == stopBits ? _self.stopBits : stopBits // ignore: cast_nullable_to_non_nullable
as int?,parity: freezed == parity ? _self.parity : parity // ignore: cast_nullable_to_non_nullable
as String?,slaveId: freezed == slaveId ? _self.slaveId : slaveId // ignore: cast_nullable_to_non_nullable
as int?,timeoutMs: freezed == timeoutMs ? _self.timeoutMs : timeoutMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
