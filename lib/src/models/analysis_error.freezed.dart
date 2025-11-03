// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalysisError {

 String get path; String get message; DateTime get timestamp; String? get stackTrace;
/// Create a copy of AnalysisError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisErrorCopyWith<AnalysisError> get copyWith => _$AnalysisErrorCopyWithImpl<AnalysisError>(this as AnalysisError, _$identity);

  /// Serializes this AnalysisError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisError&&(identical(other.path, path) || other.path == path)&&(identical(other.message, message) || other.message == message)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,message,timestamp,stackTrace);

@override
String toString() {
  return 'AnalysisError(path: $path, message: $message, timestamp: $timestamp, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $AnalysisErrorCopyWith<$Res>  {
  factory $AnalysisErrorCopyWith(AnalysisError value, $Res Function(AnalysisError) _then) = _$AnalysisErrorCopyWithImpl;
@useResult
$Res call({
 String path, String message, DateTime timestamp, String? stackTrace
});




}
/// @nodoc
class _$AnalysisErrorCopyWithImpl<$Res>
    implements $AnalysisErrorCopyWith<$Res> {
  _$AnalysisErrorCopyWithImpl(this._self, this._then);

  final AnalysisError _self;
  final $Res Function(AnalysisError) _then;

/// Create a copy of AnalysisError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? message = null,Object? timestamp = null,Object? stackTrace = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalysisError].
extension AnalysisErrorPatterns on AnalysisError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalysisError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalysisError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalysisError value)  $default,){
final _that = this;
switch (_that) {
case _AnalysisError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalysisError value)?  $default,){
final _that = this;
switch (_that) {
case _AnalysisError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String message,  DateTime timestamp,  String? stackTrace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalysisError() when $default != null:
return $default(_that.path,_that.message,_that.timestamp,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String message,  DateTime timestamp,  String? stackTrace)  $default,) {final _that = this;
switch (_that) {
case _AnalysisError():
return $default(_that.path,_that.message,_that.timestamp,_that.stackTrace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String message,  DateTime timestamp,  String? stackTrace)?  $default,) {final _that = this;
switch (_that) {
case _AnalysisError() when $default != null:
return $default(_that.path,_that.message,_that.timestamp,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalysisError implements AnalysisError {
  const _AnalysisError({required this.path, required this.message, required this.timestamp, this.stackTrace});
  factory _AnalysisError.fromJson(Map<String, dynamic> json) => _$AnalysisErrorFromJson(json);

@override final  String path;
@override final  String message;
@override final  DateTime timestamp;
@override final  String? stackTrace;

/// Create a copy of AnalysisError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalysisErrorCopyWith<_AnalysisError> get copyWith => __$AnalysisErrorCopyWithImpl<_AnalysisError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalysisErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalysisError&&(identical(other.path, path) || other.path == path)&&(identical(other.message, message) || other.message == message)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,message,timestamp,stackTrace);

@override
String toString() {
  return 'AnalysisError(path: $path, message: $message, timestamp: $timestamp, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$AnalysisErrorCopyWith<$Res> implements $AnalysisErrorCopyWith<$Res> {
  factory _$AnalysisErrorCopyWith(_AnalysisError value, $Res Function(_AnalysisError) _then) = __$AnalysisErrorCopyWithImpl;
@override @useResult
$Res call({
 String path, String message, DateTime timestamp, String? stackTrace
});




}
/// @nodoc
class __$AnalysisErrorCopyWithImpl<$Res>
    implements _$AnalysisErrorCopyWith<$Res> {
  __$AnalysisErrorCopyWithImpl(this._self, this._then);

  final _AnalysisError _self;
  final $Res Function(_AnalysisError) _then;

/// Create a copy of AnalysisError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? message = null,Object? timestamp = null,Object? stackTrace = freezed,}) {
  return _then(_AnalysisError(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
