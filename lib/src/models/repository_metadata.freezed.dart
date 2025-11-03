// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repository_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RepositoryMetadata {

 String get name; String? get fullName; String? get description; bool get isPrivate; String? get defaultBranch; String? get language; List<String> get languages; int get stars; int get forks; int get fileCount; String? get commitSha; String get directoryTree;
/// Create a copy of RepositoryMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepositoryMetadataCopyWith<RepositoryMetadata> get copyWith => _$RepositoryMetadataCopyWithImpl<RepositoryMetadata>(this as RepositoryMetadata, _$identity);

  /// Serializes this RepositoryMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepositoryMetadata&&(identical(other.name, name) || other.name == name)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other.languages, languages)&&(identical(other.stars, stars) || other.stars == stars)&&(identical(other.forks, forks) || other.forks == forks)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.directoryTree, directoryTree) || other.directoryTree == directoryTree));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,fullName,description,isPrivate,defaultBranch,language,const DeepCollectionEquality().hash(languages),stars,forks,fileCount,commitSha,directoryTree);



}

/// @nodoc
abstract mixin class $RepositoryMetadataCopyWith<$Res>  {
  factory $RepositoryMetadataCopyWith(RepositoryMetadata value, $Res Function(RepositoryMetadata) _then) = _$RepositoryMetadataCopyWithImpl;
@useResult
$Res call({
 String name, String? fullName, String? description, bool isPrivate, String? defaultBranch, String? language, List<String> languages, int stars, int forks, int fileCount, String? commitSha, String directoryTree
});




}
/// @nodoc
class _$RepositoryMetadataCopyWithImpl<$Res>
    implements $RepositoryMetadataCopyWith<$Res> {
  _$RepositoryMetadataCopyWithImpl(this._self, this._then);

  final RepositoryMetadata _self;
  final $Res Function(RepositoryMetadata) _then;

/// Create a copy of RepositoryMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? fullName = freezed,Object? description = freezed,Object? isPrivate = null,Object? defaultBranch = freezed,Object? language = freezed,Object? languages = null,Object? stars = null,Object? forks = null,Object? fileCount = null,Object? commitSha = freezed,Object? directoryTree = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,defaultBranch: freezed == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,stars: null == stars ? _self.stars : stars // ignore: cast_nullable_to_non_nullable
as int,forks: null == forks ? _self.forks : forks // ignore: cast_nullable_to_non_nullable
as int,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,directoryTree: null == directoryTree ? _self.directoryTree : directoryTree // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RepositoryMetadata].
extension RepositoryMetadataPatterns on RepositoryMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepositoryMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepositoryMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepositoryMetadata value)  $default,){
final _that = this;
switch (_that) {
case _RepositoryMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepositoryMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _RepositoryMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? fullName,  String? description,  bool isPrivate,  String? defaultBranch,  String? language,  List<String> languages,  int stars,  int forks,  int fileCount,  String? commitSha,  String directoryTree)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepositoryMetadata() when $default != null:
return $default(_that.name,_that.fullName,_that.description,_that.isPrivate,_that.defaultBranch,_that.language,_that.languages,_that.stars,_that.forks,_that.fileCount,_that.commitSha,_that.directoryTree);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? fullName,  String? description,  bool isPrivate,  String? defaultBranch,  String? language,  List<String> languages,  int stars,  int forks,  int fileCount,  String? commitSha,  String directoryTree)  $default,) {final _that = this;
switch (_that) {
case _RepositoryMetadata():
return $default(_that.name,_that.fullName,_that.description,_that.isPrivate,_that.defaultBranch,_that.language,_that.languages,_that.stars,_that.forks,_that.fileCount,_that.commitSha,_that.directoryTree);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? fullName,  String? description,  bool isPrivate,  String? defaultBranch,  String? language,  List<String> languages,  int stars,  int forks,  int fileCount,  String? commitSha,  String directoryTree)?  $default,) {final _that = this;
switch (_that) {
case _RepositoryMetadata() when $default != null:
return $default(_that.name,_that.fullName,_that.description,_that.isPrivate,_that.defaultBranch,_that.language,_that.languages,_that.stars,_that.forks,_that.fileCount,_that.commitSha,_that.directoryTree);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RepositoryMetadata extends RepositoryMetadata {
  const _RepositoryMetadata({required this.name, this.fullName, this.description, this.isPrivate = false, this.defaultBranch, this.language, final  List<String> languages = const [], this.stars = 0, this.forks = 0, this.fileCount = 0, this.commitSha, this.directoryTree = ''}): _languages = languages,super._();
  factory _RepositoryMetadata.fromJson(Map<String, dynamic> json) => _$RepositoryMetadataFromJson(json);

@override final  String name;
@override final  String? fullName;
@override final  String? description;
@override@JsonKey() final  bool isPrivate;
@override final  String? defaultBranch;
@override final  String? language;
 final  List<String> _languages;
@override@JsonKey() List<String> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}

@override@JsonKey() final  int stars;
@override@JsonKey() final  int forks;
@override@JsonKey() final  int fileCount;
@override final  String? commitSha;
@override@JsonKey() final  String directoryTree;

/// Create a copy of RepositoryMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepositoryMetadataCopyWith<_RepositoryMetadata> get copyWith => __$RepositoryMetadataCopyWithImpl<_RepositoryMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepositoryMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepositoryMetadata&&(identical(other.name, name) || other.name == name)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other._languages, _languages)&&(identical(other.stars, stars) || other.stars == stars)&&(identical(other.forks, forks) || other.forks == forks)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.directoryTree, directoryTree) || other.directoryTree == directoryTree));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,fullName,description,isPrivate,defaultBranch,language,const DeepCollectionEquality().hash(_languages),stars,forks,fileCount,commitSha,directoryTree);



}

/// @nodoc
abstract mixin class _$RepositoryMetadataCopyWith<$Res> implements $RepositoryMetadataCopyWith<$Res> {
  factory _$RepositoryMetadataCopyWith(_RepositoryMetadata value, $Res Function(_RepositoryMetadata) _then) = __$RepositoryMetadataCopyWithImpl;
@override @useResult
$Res call({
 String name, String? fullName, String? description, bool isPrivate, String? defaultBranch, String? language, List<String> languages, int stars, int forks, int fileCount, String? commitSha, String directoryTree
});




}
/// @nodoc
class __$RepositoryMetadataCopyWithImpl<$Res>
    implements _$RepositoryMetadataCopyWith<$Res> {
  __$RepositoryMetadataCopyWithImpl(this._self, this._then);

  final _RepositoryMetadata _self;
  final $Res Function(_RepositoryMetadata) _then;

/// Create a copy of RepositoryMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? fullName = freezed,Object? description = freezed,Object? isPrivate = null,Object? defaultBranch = freezed,Object? language = freezed,Object? languages = null,Object? stars = null,Object? forks = null,Object? fileCount = null,Object? commitSha = freezed,Object? directoryTree = null,}) {
  return _then(_RepositoryMetadata(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,defaultBranch: freezed == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,stars: null == stars ? _self.stars : stars // ignore: cast_nullable_to_non_nullable
as int,forks: null == forks ? _self.forks : forks // ignore: cast_nullable_to_non_nullable
as int,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,directoryTree: null == directoryTree ? _self.directoryTree : directoryTree // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
