// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalysisProgress {

 AnalysisPhase get phase; double get progress; String? get message; String? get currentFile; int? get processedFiles; int? get totalFiles; DateTime get timestamp;
/// Create a copy of AnalysisProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisProgressCopyWith<AnalysisProgress> get copyWith => _$AnalysisProgressCopyWithImpl<AnalysisProgress>(this as AnalysisProgress, _$identity);

  /// Serializes this AnalysisProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisProgress&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile)&&(identical(other.processedFiles, processedFiles) || other.processedFiles == processedFiles)&&(identical(other.totalFiles, totalFiles) || other.totalFiles == totalFiles)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phase,progress,message,currentFile,processedFiles,totalFiles,timestamp);



}

/// @nodoc
abstract mixin class $AnalysisProgressCopyWith<$Res>  {
  factory $AnalysisProgressCopyWith(AnalysisProgress value, $Res Function(AnalysisProgress) _then) = _$AnalysisProgressCopyWithImpl;
@useResult
$Res call({
 AnalysisPhase phase, double progress, String? message, String? currentFile, int? processedFiles, int? totalFiles, DateTime timestamp
});




}
/// @nodoc
class _$AnalysisProgressCopyWithImpl<$Res>
    implements $AnalysisProgressCopyWith<$Res> {
  _$AnalysisProgressCopyWithImpl(this._self, this._then);

  final AnalysisProgress _self;
  final $Res Function(AnalysisProgress) _then;

/// Create a copy of AnalysisProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? progress = null,Object? message = freezed,Object? currentFile = freezed,Object? processedFiles = freezed,Object? totalFiles = freezed,Object? timestamp = null,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AnalysisPhase,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,processedFiles: freezed == processedFiles ? _self.processedFiles : processedFiles // ignore: cast_nullable_to_non_nullable
as int?,totalFiles: freezed == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as int?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalysisProgress].
extension AnalysisProgressPatterns on AnalysisProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalysisProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalysisProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalysisProgress value)  $default,){
final _that = this;
switch (_that) {
case _AnalysisProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalysisProgress value)?  $default,){
final _that = this;
switch (_that) {
case _AnalysisProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AnalysisPhase phase,  double progress,  String? message,  String? currentFile,  int? processedFiles,  int? totalFiles,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalysisProgress() when $default != null:
return $default(_that.phase,_that.progress,_that.message,_that.currentFile,_that.processedFiles,_that.totalFiles,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AnalysisPhase phase,  double progress,  String? message,  String? currentFile,  int? processedFiles,  int? totalFiles,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _AnalysisProgress():
return $default(_that.phase,_that.progress,_that.message,_that.currentFile,_that.processedFiles,_that.totalFiles,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AnalysisPhase phase,  double progress,  String? message,  String? currentFile,  int? processedFiles,  int? totalFiles,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _AnalysisProgress() when $default != null:
return $default(_that.phase,_that.progress,_that.message,_that.currentFile,_that.processedFiles,_that.totalFiles,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalysisProgress extends AnalysisProgress {
  const _AnalysisProgress({required this.phase, required this.progress, this.message, this.currentFile, this.processedFiles, this.totalFiles, required this.timestamp}): super._();
  factory _AnalysisProgress.fromJson(Map<String, dynamic> json) => _$AnalysisProgressFromJson(json);

@override final  AnalysisPhase phase;
@override final  double progress;
@override final  String? message;
@override final  String? currentFile;
@override final  int? processedFiles;
@override final  int? totalFiles;
@override final  DateTime timestamp;

/// Create a copy of AnalysisProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalysisProgressCopyWith<_AnalysisProgress> get copyWith => __$AnalysisProgressCopyWithImpl<_AnalysisProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalysisProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalysisProgress&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile)&&(identical(other.processedFiles, processedFiles) || other.processedFiles == processedFiles)&&(identical(other.totalFiles, totalFiles) || other.totalFiles == totalFiles)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phase,progress,message,currentFile,processedFiles,totalFiles,timestamp);



}

/// @nodoc
abstract mixin class _$AnalysisProgressCopyWith<$Res> implements $AnalysisProgressCopyWith<$Res> {
  factory _$AnalysisProgressCopyWith(_AnalysisProgress value, $Res Function(_AnalysisProgress) _then) = __$AnalysisProgressCopyWithImpl;
@override @useResult
$Res call({
 AnalysisPhase phase, double progress, String? message, String? currentFile, int? processedFiles, int? totalFiles, DateTime timestamp
});




}
/// @nodoc
class __$AnalysisProgressCopyWithImpl<$Res>
    implements _$AnalysisProgressCopyWith<$Res> {
  __$AnalysisProgressCopyWithImpl(this._self, this._then);

  final _AnalysisProgress _self;
  final $Res Function(_AnalysisProgress) _then;

/// Create a copy of AnalysisProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? progress = null,Object? message = freezed,Object? currentFile = freezed,Object? processedFiles = freezed,Object? totalFiles = freezed,Object? timestamp = null,}) {
  return _then(_AnalysisProgress(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AnalysisPhase,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,processedFiles: freezed == processedFiles ? _self.processedFiles : processedFiles // ignore: cast_nullable_to_non_nullable
as int?,totalFiles: freezed == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as int?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
