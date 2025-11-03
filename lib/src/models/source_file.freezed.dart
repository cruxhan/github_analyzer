// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SourceFile {

 String get path; String? get content; int get size; String? get language; bool get isBinary; int get lineCount; bool get isSourceCode; bool get isConfiguration; bool get isDocumentation; DateTime get timestamp;
/// Create a copy of SourceFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceFileCopyWith<SourceFile> get copyWith => _$SourceFileCopyWithImpl<SourceFile>(this as SourceFile, _$identity);

  /// Serializes this SourceFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceFile&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content)&&(identical(other.size, size) || other.size == size)&&(identical(other.language, language) || other.language == language)&&(identical(other.isBinary, isBinary) || other.isBinary == isBinary)&&(identical(other.lineCount, lineCount) || other.lineCount == lineCount)&&(identical(other.isSourceCode, isSourceCode) || other.isSourceCode == isSourceCode)&&(identical(other.isConfiguration, isConfiguration) || other.isConfiguration == isConfiguration)&&(identical(other.isDocumentation, isDocumentation) || other.isDocumentation == isDocumentation)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,content,size,language,isBinary,lineCount,isSourceCode,isConfiguration,isDocumentation,timestamp);



}

/// @nodoc
abstract mixin class $SourceFileCopyWith<$Res>  {
  factory $SourceFileCopyWith(SourceFile value, $Res Function(SourceFile) _then) = _$SourceFileCopyWithImpl;
@useResult
$Res call({
 String path, String? content, int size, String? language, bool isBinary, int lineCount, bool isSourceCode, bool isConfiguration, bool isDocumentation, DateTime timestamp
});




}
/// @nodoc
class _$SourceFileCopyWithImpl<$Res>
    implements $SourceFileCopyWith<$Res> {
  _$SourceFileCopyWithImpl(this._self, this._then);

  final SourceFile _self;
  final $Res Function(SourceFile) _then;

/// Create a copy of SourceFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? content = freezed,Object? size = null,Object? language = freezed,Object? isBinary = null,Object? lineCount = null,Object? isSourceCode = null,Object? isConfiguration = null,Object? isDocumentation = null,Object? timestamp = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,isBinary: null == isBinary ? _self.isBinary : isBinary // ignore: cast_nullable_to_non_nullable
as bool,lineCount: null == lineCount ? _self.lineCount : lineCount // ignore: cast_nullable_to_non_nullable
as int,isSourceCode: null == isSourceCode ? _self.isSourceCode : isSourceCode // ignore: cast_nullable_to_non_nullable
as bool,isConfiguration: null == isConfiguration ? _self.isConfiguration : isConfiguration // ignore: cast_nullable_to_non_nullable
as bool,isDocumentation: null == isDocumentation ? _self.isDocumentation : isDocumentation // ignore: cast_nullable_to_non_nullable
as bool,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceFile].
extension SourceFilePatterns on SourceFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceFile value)  $default,){
final _that = this;
switch (_that) {
case _SourceFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceFile value)?  $default,){
final _that = this;
switch (_that) {
case _SourceFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String? content,  int size,  String? language,  bool isBinary,  int lineCount,  bool isSourceCode,  bool isConfiguration,  bool isDocumentation,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourceFile() when $default != null:
return $default(_that.path,_that.content,_that.size,_that.language,_that.isBinary,_that.lineCount,_that.isSourceCode,_that.isConfiguration,_that.isDocumentation,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String? content,  int size,  String? language,  bool isBinary,  int lineCount,  bool isSourceCode,  bool isConfiguration,  bool isDocumentation,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _SourceFile():
return $default(_that.path,_that.content,_that.size,_that.language,_that.isBinary,_that.lineCount,_that.isSourceCode,_that.isConfiguration,_that.isDocumentation,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String? content,  int size,  String? language,  bool isBinary,  int lineCount,  bool isSourceCode,  bool isConfiguration,  bool isDocumentation,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _SourceFile() when $default != null:
return $default(_that.path,_that.content,_that.size,_that.language,_that.isBinary,_that.lineCount,_that.isSourceCode,_that.isConfiguration,_that.isDocumentation,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SourceFile extends SourceFile {
  const _SourceFile({required this.path, this.content, required this.size, this.language, required this.isBinary, required this.lineCount, required this.isSourceCode, required this.isConfiguration, required this.isDocumentation, required this.timestamp}): super._();
  factory _SourceFile.fromJson(Map<String, dynamic> json) => _$SourceFileFromJson(json);

@override final  String path;
@override final  String? content;
@override final  int size;
@override final  String? language;
@override final  bool isBinary;
@override final  int lineCount;
@override final  bool isSourceCode;
@override final  bool isConfiguration;
@override final  bool isDocumentation;
@override final  DateTime timestamp;

/// Create a copy of SourceFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceFileCopyWith<_SourceFile> get copyWith => __$SourceFileCopyWithImpl<_SourceFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceFile&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content)&&(identical(other.size, size) || other.size == size)&&(identical(other.language, language) || other.language == language)&&(identical(other.isBinary, isBinary) || other.isBinary == isBinary)&&(identical(other.lineCount, lineCount) || other.lineCount == lineCount)&&(identical(other.isSourceCode, isSourceCode) || other.isSourceCode == isSourceCode)&&(identical(other.isConfiguration, isConfiguration) || other.isConfiguration == isConfiguration)&&(identical(other.isDocumentation, isDocumentation) || other.isDocumentation == isDocumentation)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,content,size,language,isBinary,lineCount,isSourceCode,isConfiguration,isDocumentation,timestamp);



}

/// @nodoc
abstract mixin class _$SourceFileCopyWith<$Res> implements $SourceFileCopyWith<$Res> {
  factory _$SourceFileCopyWith(_SourceFile value, $Res Function(_SourceFile) _then) = __$SourceFileCopyWithImpl;
@override @useResult
$Res call({
 String path, String? content, int size, String? language, bool isBinary, int lineCount, bool isSourceCode, bool isConfiguration, bool isDocumentation, DateTime timestamp
});




}
/// @nodoc
class __$SourceFileCopyWithImpl<$Res>
    implements _$SourceFileCopyWith<$Res> {
  __$SourceFileCopyWithImpl(this._self, this._then);

  final _SourceFile _self;
  final $Res Function(_SourceFile) _then;

/// Create a copy of SourceFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? content = freezed,Object? size = null,Object? language = freezed,Object? isBinary = null,Object? lineCount = null,Object? isSourceCode = null,Object? isConfiguration = null,Object? isDocumentation = null,Object? timestamp = null,}) {
  return _then(_SourceFile(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,isBinary: null == isBinary ? _self.isBinary : isBinary // ignore: cast_nullable_to_non_nullable
as bool,lineCount: null == lineCount ? _self.lineCount : lineCount // ignore: cast_nullable_to_non_nullable
as int,isSourceCode: null == isSourceCode ? _self.isSourceCode : isSourceCode // ignore: cast_nullable_to_non_nullable
as bool,isConfiguration: null == isConfiguration ? _self.isConfiguration : isConfiguration // ignore: cast_nullable_to_non_nullable
as bool,isDocumentation: null == isDocumentation ? _self.isDocumentation : isDocumentation // ignore: cast_nullable_to_non_nullable
as bool,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
