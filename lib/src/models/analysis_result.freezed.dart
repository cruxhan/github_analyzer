// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AnalysisResult {

 RepositoryMetadata get metadata; List<SourceFile> get files; AnalysisStatistics get statistics; List<String> get mainFiles; Map<String, List<String>> get dependencies; List<AnalysisError> get errors;
/// Create a copy of AnalysisResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisResultCopyWith<AnalysisResult> get copyWith => _$AnalysisResultCopyWithImpl<AnalysisResult>(this as AnalysisResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisResult&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.files, files)&&(identical(other.statistics, statistics) || other.statistics == statistics)&&const DeepCollectionEquality().equals(other.mainFiles, mainFiles)&&const DeepCollectionEquality().equals(other.dependencies, dependencies)&&const DeepCollectionEquality().equals(other.errors, errors));
}


@override
int get hashCode => Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(files),statistics,const DeepCollectionEquality().hash(mainFiles),const DeepCollectionEquality().hash(dependencies),const DeepCollectionEquality().hash(errors));



}

/// @nodoc
abstract mixin class $AnalysisResultCopyWith<$Res>  {
  factory $AnalysisResultCopyWith(AnalysisResult value, $Res Function(AnalysisResult) _then) = _$AnalysisResultCopyWithImpl;
@useResult
$Res call({
 RepositoryMetadata metadata, List<SourceFile> files, AnalysisStatistics statistics, List<String> mainFiles, Map<String, List<String>> dependencies, List<AnalysisError> errors
});


$RepositoryMetadataCopyWith<$Res> get metadata;$AnalysisStatisticsCopyWith<$Res> get statistics;

}
/// @nodoc
class _$AnalysisResultCopyWithImpl<$Res>
    implements $AnalysisResultCopyWith<$Res> {
  _$AnalysisResultCopyWithImpl(this._self, this._then);

  final AnalysisResult _self;
  final $Res Function(AnalysisResult) _then;

/// Create a copy of AnalysisResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = null,Object? files = null,Object? statistics = null,Object? mainFiles = null,Object? dependencies = null,Object? errors = null,}) {
  return _then(_self.copyWith(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as RepositoryMetadata,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<SourceFile>,statistics: null == statistics ? _self.statistics : statistics // ignore: cast_nullable_to_non_nullable
as AnalysisStatistics,mainFiles: null == mainFiles ? _self.mainFiles : mainFiles // ignore: cast_nullable_to_non_nullable
as List<String>,dependencies: null == dependencies ? _self.dependencies : dependencies // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as List<AnalysisError>,
  ));
}
/// Create a copy of AnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepositoryMetadataCopyWith<$Res> get metadata {
  
  return $RepositoryMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}/// Create a copy of AnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnalysisStatisticsCopyWith<$Res> get statistics {
  
  return $AnalysisStatisticsCopyWith<$Res>(_self.statistics, (value) {
    return _then(_self.copyWith(statistics: value));
  });
}
}


/// Adds pattern-matching-related methods to [AnalysisResult].
extension AnalysisResultPatterns on AnalysisResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalysisResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalysisResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalysisResult value)  $default,){
final _that = this;
switch (_that) {
case _AnalysisResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalysisResult value)?  $default,){
final _that = this;
switch (_that) {
case _AnalysisResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RepositoryMetadata metadata,  List<SourceFile> files,  AnalysisStatistics statistics,  List<String> mainFiles,  Map<String, List<String>> dependencies,  List<AnalysisError> errors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalysisResult() when $default != null:
return $default(_that.metadata,_that.files,_that.statistics,_that.mainFiles,_that.dependencies,_that.errors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RepositoryMetadata metadata,  List<SourceFile> files,  AnalysisStatistics statistics,  List<String> mainFiles,  Map<String, List<String>> dependencies,  List<AnalysisError> errors)  $default,) {final _that = this;
switch (_that) {
case _AnalysisResult():
return $default(_that.metadata,_that.files,_that.statistics,_that.mainFiles,_that.dependencies,_that.errors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RepositoryMetadata metadata,  List<SourceFile> files,  AnalysisStatistics statistics,  List<String> mainFiles,  Map<String, List<String>> dependencies,  List<AnalysisError> errors)?  $default,) {final _that = this;
switch (_that) {
case _AnalysisResult() when $default != null:
return $default(_that.metadata,_that.files,_that.statistics,_that.mainFiles,_that.dependencies,_that.errors);case _:
  return null;

}
}

}

/// @nodoc


class _AnalysisResult extends AnalysisResult {
  const _AnalysisResult({required this.metadata, required final  List<SourceFile> files, required this.statistics, required final  List<String> mainFiles, required final  Map<String, List<String>> dependencies, final  List<AnalysisError> errors = const []}): _files = files,_mainFiles = mainFiles,_dependencies = dependencies,_errors = errors,super._();
  

@override final  RepositoryMetadata metadata;
 final  List<SourceFile> _files;
@override List<SourceFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

@override final  AnalysisStatistics statistics;
 final  List<String> _mainFiles;
@override List<String> get mainFiles {
  if (_mainFiles is EqualUnmodifiableListView) return _mainFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mainFiles);
}

 final  Map<String, List<String>> _dependencies;
@override Map<String, List<String>> get dependencies {
  if (_dependencies is EqualUnmodifiableMapView) return _dependencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dependencies);
}

 final  List<AnalysisError> _errors;
@override@JsonKey() List<AnalysisError> get errors {
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errors);
}


/// Create a copy of AnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalysisResultCopyWith<_AnalysisResult> get copyWith => __$AnalysisResultCopyWithImpl<_AnalysisResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalysisResult&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other._files, _files)&&(identical(other.statistics, statistics) || other.statistics == statistics)&&const DeepCollectionEquality().equals(other._mainFiles, _mainFiles)&&const DeepCollectionEquality().equals(other._dependencies, _dependencies)&&const DeepCollectionEquality().equals(other._errors, _errors));
}


@override
int get hashCode => Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(_files),statistics,const DeepCollectionEquality().hash(_mainFiles),const DeepCollectionEquality().hash(_dependencies),const DeepCollectionEquality().hash(_errors));



}

/// @nodoc
abstract mixin class _$AnalysisResultCopyWith<$Res> implements $AnalysisResultCopyWith<$Res> {
  factory _$AnalysisResultCopyWith(_AnalysisResult value, $Res Function(_AnalysisResult) _then) = __$AnalysisResultCopyWithImpl;
@override @useResult
$Res call({
 RepositoryMetadata metadata, List<SourceFile> files, AnalysisStatistics statistics, List<String> mainFiles, Map<String, List<String>> dependencies, List<AnalysisError> errors
});


@override $RepositoryMetadataCopyWith<$Res> get metadata;@override $AnalysisStatisticsCopyWith<$Res> get statistics;

}
/// @nodoc
class __$AnalysisResultCopyWithImpl<$Res>
    implements _$AnalysisResultCopyWith<$Res> {
  __$AnalysisResultCopyWithImpl(this._self, this._then);

  final _AnalysisResult _self;
  final $Res Function(_AnalysisResult) _then;

/// Create a copy of AnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metadata = null,Object? files = null,Object? statistics = null,Object? mainFiles = null,Object? dependencies = null,Object? errors = null,}) {
  return _then(_AnalysisResult(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as RepositoryMetadata,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<SourceFile>,statistics: null == statistics ? _self.statistics : statistics // ignore: cast_nullable_to_non_nullable
as AnalysisStatistics,mainFiles: null == mainFiles ? _self._mainFiles : mainFiles // ignore: cast_nullable_to_non_nullable
as List<String>,dependencies: null == dependencies ? _self._dependencies : dependencies // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,errors: null == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<AnalysisError>,
  ));
}

/// Create a copy of AnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepositoryMetadataCopyWith<$Res> get metadata {
  
  return $RepositoryMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}/// Create a copy of AnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnalysisStatisticsCopyWith<$Res> get statistics {
  
  return $AnalysisStatisticsCopyWith<$Res>(_self.statistics, (value) {
    return _then(_self.copyWith(statistics: value));
  });
}
}

// dart format on
