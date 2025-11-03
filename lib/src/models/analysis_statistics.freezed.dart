// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalysisStatistics {

 int get totalFiles; int get totalLines; int get totalSize; Map<String, int> get languageDistribution; int get binaryFiles; int get sourceFiles; int get configFiles; int get documentationFiles;
/// Create a copy of AnalysisStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisStatisticsCopyWith<AnalysisStatistics> get copyWith => _$AnalysisStatisticsCopyWithImpl<AnalysisStatistics>(this as AnalysisStatistics, _$identity);

  /// Serializes this AnalysisStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisStatistics&&(identical(other.totalFiles, totalFiles) || other.totalFiles == totalFiles)&&(identical(other.totalLines, totalLines) || other.totalLines == totalLines)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&const DeepCollectionEquality().equals(other.languageDistribution, languageDistribution)&&(identical(other.binaryFiles, binaryFiles) || other.binaryFiles == binaryFiles)&&(identical(other.sourceFiles, sourceFiles) || other.sourceFiles == sourceFiles)&&(identical(other.configFiles, configFiles) || other.configFiles == configFiles)&&(identical(other.documentationFiles, documentationFiles) || other.documentationFiles == documentationFiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalFiles,totalLines,totalSize,const DeepCollectionEquality().hash(languageDistribution),binaryFiles,sourceFiles,configFiles,documentationFiles);



}

/// @nodoc
abstract mixin class $AnalysisStatisticsCopyWith<$Res>  {
  factory $AnalysisStatisticsCopyWith(AnalysisStatistics value, $Res Function(AnalysisStatistics) _then) = _$AnalysisStatisticsCopyWithImpl;
@useResult
$Res call({
 int totalFiles, int totalLines, int totalSize, Map<String, int> languageDistribution, int binaryFiles, int sourceFiles, int configFiles, int documentationFiles
});




}
/// @nodoc
class _$AnalysisStatisticsCopyWithImpl<$Res>
    implements $AnalysisStatisticsCopyWith<$Res> {
  _$AnalysisStatisticsCopyWithImpl(this._self, this._then);

  final AnalysisStatistics _self;
  final $Res Function(AnalysisStatistics) _then;

/// Create a copy of AnalysisStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalFiles = null,Object? totalLines = null,Object? totalSize = null,Object? languageDistribution = null,Object? binaryFiles = null,Object? sourceFiles = null,Object? configFiles = null,Object? documentationFiles = null,}) {
  return _then(_self.copyWith(
totalFiles: null == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as int,totalLines: null == totalLines ? _self.totalLines : totalLines // ignore: cast_nullable_to_non_nullable
as int,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,languageDistribution: null == languageDistribution ? _self.languageDistribution : languageDistribution // ignore: cast_nullable_to_non_nullable
as Map<String, int>,binaryFiles: null == binaryFiles ? _self.binaryFiles : binaryFiles // ignore: cast_nullable_to_non_nullable
as int,sourceFiles: null == sourceFiles ? _self.sourceFiles : sourceFiles // ignore: cast_nullable_to_non_nullable
as int,configFiles: null == configFiles ? _self.configFiles : configFiles // ignore: cast_nullable_to_non_nullable
as int,documentationFiles: null == documentationFiles ? _self.documentationFiles : documentationFiles // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalysisStatistics].
extension AnalysisStatisticsPatterns on AnalysisStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalysisStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalysisStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalysisStatistics value)  $default,){
final _that = this;
switch (_that) {
case _AnalysisStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalysisStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _AnalysisStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalFiles,  int totalLines,  int totalSize,  Map<String, int> languageDistribution,  int binaryFiles,  int sourceFiles,  int configFiles,  int documentationFiles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalysisStatistics() when $default != null:
return $default(_that.totalFiles,_that.totalLines,_that.totalSize,_that.languageDistribution,_that.binaryFiles,_that.sourceFiles,_that.configFiles,_that.documentationFiles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalFiles,  int totalLines,  int totalSize,  Map<String, int> languageDistribution,  int binaryFiles,  int sourceFiles,  int configFiles,  int documentationFiles)  $default,) {final _that = this;
switch (_that) {
case _AnalysisStatistics():
return $default(_that.totalFiles,_that.totalLines,_that.totalSize,_that.languageDistribution,_that.binaryFiles,_that.sourceFiles,_that.configFiles,_that.documentationFiles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalFiles,  int totalLines,  int totalSize,  Map<String, int> languageDistribution,  int binaryFiles,  int sourceFiles,  int configFiles,  int documentationFiles)?  $default,) {final _that = this;
switch (_that) {
case _AnalysisStatistics() when $default != null:
return $default(_that.totalFiles,_that.totalLines,_that.totalSize,_that.languageDistribution,_that.binaryFiles,_that.sourceFiles,_that.configFiles,_that.documentationFiles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalysisStatistics extends AnalysisStatistics {
  const _AnalysisStatistics({this.totalFiles = 0, this.totalLines = 0, this.totalSize = 0, final  Map<String, int> languageDistribution = const {}, this.binaryFiles = 0, this.sourceFiles = 0, this.configFiles = 0, this.documentationFiles = 0}): _languageDistribution = languageDistribution,super._();
  factory _AnalysisStatistics.fromJson(Map<String, dynamic> json) => _$AnalysisStatisticsFromJson(json);

@override@JsonKey() final  int totalFiles;
@override@JsonKey() final  int totalLines;
@override@JsonKey() final  int totalSize;
 final  Map<String, int> _languageDistribution;
@override@JsonKey() Map<String, int> get languageDistribution {
  if (_languageDistribution is EqualUnmodifiableMapView) return _languageDistribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_languageDistribution);
}

@override@JsonKey() final  int binaryFiles;
@override@JsonKey() final  int sourceFiles;
@override@JsonKey() final  int configFiles;
@override@JsonKey() final  int documentationFiles;

/// Create a copy of AnalysisStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalysisStatisticsCopyWith<_AnalysisStatistics> get copyWith => __$AnalysisStatisticsCopyWithImpl<_AnalysisStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalysisStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalysisStatistics&&(identical(other.totalFiles, totalFiles) || other.totalFiles == totalFiles)&&(identical(other.totalLines, totalLines) || other.totalLines == totalLines)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&const DeepCollectionEquality().equals(other._languageDistribution, _languageDistribution)&&(identical(other.binaryFiles, binaryFiles) || other.binaryFiles == binaryFiles)&&(identical(other.sourceFiles, sourceFiles) || other.sourceFiles == sourceFiles)&&(identical(other.configFiles, configFiles) || other.configFiles == configFiles)&&(identical(other.documentationFiles, documentationFiles) || other.documentationFiles == documentationFiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalFiles,totalLines,totalSize,const DeepCollectionEquality().hash(_languageDistribution),binaryFiles,sourceFiles,configFiles,documentationFiles);



}

/// @nodoc
abstract mixin class _$AnalysisStatisticsCopyWith<$Res> implements $AnalysisStatisticsCopyWith<$Res> {
  factory _$AnalysisStatisticsCopyWith(_AnalysisStatistics value, $Res Function(_AnalysisStatistics) _then) = __$AnalysisStatisticsCopyWithImpl;
@override @useResult
$Res call({
 int totalFiles, int totalLines, int totalSize, Map<String, int> languageDistribution, int binaryFiles, int sourceFiles, int configFiles, int documentationFiles
});




}
/// @nodoc
class __$AnalysisStatisticsCopyWithImpl<$Res>
    implements _$AnalysisStatisticsCopyWith<$Res> {
  __$AnalysisStatisticsCopyWithImpl(this._self, this._then);

  final _AnalysisStatistics _self;
  final $Res Function(_AnalysisStatistics) _then;

/// Create a copy of AnalysisStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalFiles = null,Object? totalLines = null,Object? totalSize = null,Object? languageDistribution = null,Object? binaryFiles = null,Object? sourceFiles = null,Object? configFiles = null,Object? documentationFiles = null,}) {
  return _then(_AnalysisStatistics(
totalFiles: null == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as int,totalLines: null == totalLines ? _self.totalLines : totalLines // ignore: cast_nullable_to_non_nullable
as int,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,languageDistribution: null == languageDistribution ? _self._languageDistribution : languageDistribution // ignore: cast_nullable_to_non_nullable
as Map<String, int>,binaryFiles: null == binaryFiles ? _self.binaryFiles : binaryFiles // ignore: cast_nullable_to_non_nullable
as int,sourceFiles: null == sourceFiles ? _self.sourceFiles : sourceFiles // ignore: cast_nullable_to_non_nullable
as int,configFiles: null == configFiles ? _self.configFiles : configFiles // ignore: cast_nullable_to_non_nullable
as int,documentationFiles: null == documentationFiles ? _self.documentationFiles : documentationFiles // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
