// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exegesis_final_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WordOccurrence _$WordOccurrenceFromJson(Map<String, dynamic> json) {
  return _WordOccurrence.fromJson(json);
}

/// @nodoc
mixin _$WordOccurrence {
  String get reference => throw _privateConstructorUsedError;
  String get context => throw _privateConstructorUsedError;

  /// Serializes this WordOccurrence to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WordOccurrence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WordOccurrenceCopyWith<WordOccurrence> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WordOccurrenceCopyWith<$Res> {
  factory $WordOccurrenceCopyWith(
          WordOccurrence value, $Res Function(WordOccurrence) then) =
      _$WordOccurrenceCopyWithImpl<$Res, WordOccurrence>;
  @useResult
  $Res call({String reference, String context});
}

/// @nodoc
class _$WordOccurrenceCopyWithImpl<$Res, $Val extends WordOccurrence>
    implements $WordOccurrenceCopyWith<$Res> {
  _$WordOccurrenceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WordOccurrence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? context = null,
  }) {
    return _then(_value.copyWith(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WordOccurrenceImplCopyWith<$Res>
    implements $WordOccurrenceCopyWith<$Res> {
  factory _$$WordOccurrenceImplCopyWith(_$WordOccurrenceImpl value,
          $Res Function(_$WordOccurrenceImpl) then) =
      __$$WordOccurrenceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reference, String context});
}

/// @nodoc
class __$$WordOccurrenceImplCopyWithImpl<$Res>
    extends _$WordOccurrenceCopyWithImpl<$Res, _$WordOccurrenceImpl>
    implements _$$WordOccurrenceImplCopyWith<$Res> {
  __$$WordOccurrenceImplCopyWithImpl(
      _$WordOccurrenceImpl _value, $Res Function(_$WordOccurrenceImpl) _then)
      : super(_value, _then);

  /// Create a copy of WordOccurrence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? context = null,
  }) {
    return _then(_$WordOccurrenceImpl(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WordOccurrenceImpl implements _WordOccurrence {
  const _$WordOccurrenceImpl({required this.reference, required this.context});

  factory _$WordOccurrenceImpl.fromJson(Map<String, dynamic> json) =>
      _$$WordOccurrenceImplFromJson(json);

  @override
  final String reference;
  @override
  final String context;

  @override
  String toString() {
    return 'WordOccurrence(reference: $reference, context: $context)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WordOccurrenceImpl &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.context, context) || other.context == context));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reference, context);

  /// Create a copy of WordOccurrence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WordOccurrenceImplCopyWith<_$WordOccurrenceImpl> get copyWith =>
      __$$WordOccurrenceImplCopyWithImpl<_$WordOccurrenceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WordOccurrenceImplToJson(
      this,
    );
  }
}

abstract class _WordOccurrence implements WordOccurrence {
  const factory _WordOccurrence(
      {required final String reference,
      required final String context}) = _$WordOccurrenceImpl;

  factory _WordOccurrence.fromJson(Map<String, dynamic> json) =
      _$WordOccurrenceImpl.fromJson;

  @override
  String get reference;
  @override
  String get context;

  /// Create a copy of WordOccurrence
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WordOccurrenceImplCopyWith<_$WordOccurrenceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WordStudyItem _$WordStudyItemFromJson(Map<String, dynamic> json) {
  return _WordStudyItem.fromJson(json);
}

/// @nodoc
mixin _$WordStudyItem {
  String get englishWord => throw _privateConstructorUsedError;
  String? get verseRef => throw _privateConstructorUsedError;
  String get originalWord => throw _privateConstructorUsedError;
  String get transliteration => throw _privateConstructorUsedError;
  String get strongsNumber => throw _privateConstructorUsedError;
  String get lexicalDefinition => throw _privateConstructorUsedError;
  String get meaningInThisContext => throw _privateConstructorUsedError;
  String get discoveryNote => throw _privateConstructorUsedError;
  List<WordOccurrence> get otherOccurrences =>
      throw _privateConstructorUsedError;

  /// Serializes this WordStudyItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WordStudyItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WordStudyItemCopyWith<WordStudyItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WordStudyItemCopyWith<$Res> {
  factory $WordStudyItemCopyWith(
          WordStudyItem value, $Res Function(WordStudyItem) then) =
      _$WordStudyItemCopyWithImpl<$Res, WordStudyItem>;
  @useResult
  $Res call(
      {String englishWord,
      String? verseRef,
      String originalWord,
      String transliteration,
      String strongsNumber,
      String lexicalDefinition,
      String meaningInThisContext,
      String discoveryNote,
      List<WordOccurrence> otherOccurrences});
}

/// @nodoc
class _$WordStudyItemCopyWithImpl<$Res, $Val extends WordStudyItem>
    implements $WordStudyItemCopyWith<$Res> {
  _$WordStudyItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WordStudyItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? englishWord = null,
    Object? verseRef = freezed,
    Object? originalWord = null,
    Object? transliteration = null,
    Object? strongsNumber = null,
    Object? lexicalDefinition = null,
    Object? meaningInThisContext = null,
    Object? discoveryNote = null,
    Object? otherOccurrences = null,
  }) {
    return _then(_value.copyWith(
      englishWord: null == englishWord
          ? _value.englishWord
          : englishWord // ignore: cast_nullable_to_non_nullable
              as String,
      verseRef: freezed == verseRef
          ? _value.verseRef
          : verseRef // ignore: cast_nullable_to_non_nullable
              as String?,
      originalWord: null == originalWord
          ? _value.originalWord
          : originalWord // ignore: cast_nullable_to_non_nullable
              as String,
      transliteration: null == transliteration
          ? _value.transliteration
          : transliteration // ignore: cast_nullable_to_non_nullable
              as String,
      strongsNumber: null == strongsNumber
          ? _value.strongsNumber
          : strongsNumber // ignore: cast_nullable_to_non_nullable
              as String,
      lexicalDefinition: null == lexicalDefinition
          ? _value.lexicalDefinition
          : lexicalDefinition // ignore: cast_nullable_to_non_nullable
              as String,
      meaningInThisContext: null == meaningInThisContext
          ? _value.meaningInThisContext
          : meaningInThisContext // ignore: cast_nullable_to_non_nullable
              as String,
      discoveryNote: null == discoveryNote
          ? _value.discoveryNote
          : discoveryNote // ignore: cast_nullable_to_non_nullable
              as String,
      otherOccurrences: null == otherOccurrences
          ? _value.otherOccurrences
          : otherOccurrences // ignore: cast_nullable_to_non_nullable
              as List<WordOccurrence>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WordStudyItemImplCopyWith<$Res>
    implements $WordStudyItemCopyWith<$Res> {
  factory _$$WordStudyItemImplCopyWith(
          _$WordStudyItemImpl value, $Res Function(_$WordStudyItemImpl) then) =
      __$$WordStudyItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String englishWord,
      String? verseRef,
      String originalWord,
      String transliteration,
      String strongsNumber,
      String lexicalDefinition,
      String meaningInThisContext,
      String discoveryNote,
      List<WordOccurrence> otherOccurrences});
}

/// @nodoc
class __$$WordStudyItemImplCopyWithImpl<$Res>
    extends _$WordStudyItemCopyWithImpl<$Res, _$WordStudyItemImpl>
    implements _$$WordStudyItemImplCopyWith<$Res> {
  __$$WordStudyItemImplCopyWithImpl(
      _$WordStudyItemImpl _value, $Res Function(_$WordStudyItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of WordStudyItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? englishWord = null,
    Object? verseRef = freezed,
    Object? originalWord = null,
    Object? transliteration = null,
    Object? strongsNumber = null,
    Object? lexicalDefinition = null,
    Object? meaningInThisContext = null,
    Object? discoveryNote = null,
    Object? otherOccurrences = null,
  }) {
    return _then(_$WordStudyItemImpl(
      englishWord: null == englishWord
          ? _value.englishWord
          : englishWord // ignore: cast_nullable_to_non_nullable
              as String,
      verseRef: freezed == verseRef
          ? _value.verseRef
          : verseRef // ignore: cast_nullable_to_non_nullable
              as String?,
      originalWord: null == originalWord
          ? _value.originalWord
          : originalWord // ignore: cast_nullable_to_non_nullable
              as String,
      transliteration: null == transliteration
          ? _value.transliteration
          : transliteration // ignore: cast_nullable_to_non_nullable
              as String,
      strongsNumber: null == strongsNumber
          ? _value.strongsNumber
          : strongsNumber // ignore: cast_nullable_to_non_nullable
              as String,
      lexicalDefinition: null == lexicalDefinition
          ? _value.lexicalDefinition
          : lexicalDefinition // ignore: cast_nullable_to_non_nullable
              as String,
      meaningInThisContext: null == meaningInThisContext
          ? _value.meaningInThisContext
          : meaningInThisContext // ignore: cast_nullable_to_non_nullable
              as String,
      discoveryNote: null == discoveryNote
          ? _value.discoveryNote
          : discoveryNote // ignore: cast_nullable_to_non_nullable
              as String,
      otherOccurrences: null == otherOccurrences
          ? _value._otherOccurrences
          : otherOccurrences // ignore: cast_nullable_to_non_nullable
              as List<WordOccurrence>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WordStudyItemImpl implements _WordStudyItem {
  const _$WordStudyItemImpl(
      {required this.englishWord,
      this.verseRef,
      required this.originalWord,
      required this.transliteration,
      required this.strongsNumber,
      required this.lexicalDefinition,
      required this.meaningInThisContext,
      required this.discoveryNote,
      final List<WordOccurrence> otherOccurrences = const []})
      : _otherOccurrences = otherOccurrences;

  factory _$WordStudyItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$WordStudyItemImplFromJson(json);

  @override
  final String englishWord;
  @override
  final String? verseRef;
  @override
  final String originalWord;
  @override
  final String transliteration;
  @override
  final String strongsNumber;
  @override
  final String lexicalDefinition;
  @override
  final String meaningInThisContext;
  @override
  final String discoveryNote;
  final List<WordOccurrence> _otherOccurrences;
  @override
  @JsonKey()
  List<WordOccurrence> get otherOccurrences {
    if (_otherOccurrences is EqualUnmodifiableListView)
      return _otherOccurrences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_otherOccurrences);
  }

  @override
  String toString() {
    return 'WordStudyItem(englishWord: $englishWord, verseRef: $verseRef, originalWord: $originalWord, transliteration: $transliteration, strongsNumber: $strongsNumber, lexicalDefinition: $lexicalDefinition, meaningInThisContext: $meaningInThisContext, discoveryNote: $discoveryNote, otherOccurrences: $otherOccurrences)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WordStudyItemImpl &&
            (identical(other.englishWord, englishWord) ||
                other.englishWord == englishWord) &&
            (identical(other.verseRef, verseRef) ||
                other.verseRef == verseRef) &&
            (identical(other.originalWord, originalWord) ||
                other.originalWord == originalWord) &&
            (identical(other.transliteration, transliteration) ||
                other.transliteration == transliteration) &&
            (identical(other.strongsNumber, strongsNumber) ||
                other.strongsNumber == strongsNumber) &&
            (identical(other.lexicalDefinition, lexicalDefinition) ||
                other.lexicalDefinition == lexicalDefinition) &&
            (identical(other.meaningInThisContext, meaningInThisContext) ||
                other.meaningInThisContext == meaningInThisContext) &&
            (identical(other.discoveryNote, discoveryNote) ||
                other.discoveryNote == discoveryNote) &&
            const DeepCollectionEquality()
                .equals(other._otherOccurrences, _otherOccurrences));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      englishWord,
      verseRef,
      originalWord,
      transliteration,
      strongsNumber,
      lexicalDefinition,
      meaningInThisContext,
      discoveryNote,
      const DeepCollectionEquality().hash(_otherOccurrences));

  /// Create a copy of WordStudyItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WordStudyItemImplCopyWith<_$WordStudyItemImpl> get copyWith =>
      __$$WordStudyItemImplCopyWithImpl<_$WordStudyItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WordStudyItemImplToJson(
      this,
    );
  }
}

abstract class _WordStudyItem implements WordStudyItem {
  const factory _WordStudyItem(
      {required final String englishWord,
      final String? verseRef,
      required final String originalWord,
      required final String transliteration,
      required final String strongsNumber,
      required final String lexicalDefinition,
      required final String meaningInThisContext,
      required final String discoveryNote,
      final List<WordOccurrence> otherOccurrences}) = _$WordStudyItemImpl;

  factory _WordStudyItem.fromJson(Map<String, dynamic> json) =
      _$WordStudyItemImpl.fromJson;

  @override
  String get englishWord;
  @override
  String? get verseRef;
  @override
  String get originalWord;
  @override
  String get transliteration;
  @override
  String get strongsNumber;
  @override
  String get lexicalDefinition;
  @override
  String get meaningInThisContext;
  @override
  String get discoveryNote;
  @override
  List<WordOccurrence> get otherOccurrences;

  /// Create a copy of WordStudyItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WordStudyItemImplCopyWith<_$WordStudyItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MorphItem _$MorphItemFromJson(Map<String, dynamic> json) {
  return _MorphItem.fromJson(json);
}

/// @nodoc
mixin _$MorphItem {
  String get word => throw _privateConstructorUsedError;
  String get originalWord => throw _privateConstructorUsedError;
  String get strongsNumber => throw _privateConstructorUsedError;
  String get partOfSpeech => throw _privateConstructorUsedError;
  String? get tense => throw _privateConstructorUsedError;
  String? get voice => throw _privateConstructorUsedError;
  String? get mood => throw _privateConstructorUsedError;
  String? get personNumber => throw _privateConstructorUsedError;
  String get plainEnglishExplanation => throw _privateConstructorUsedError;

  /// Serializes this MorphItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MorphItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MorphItemCopyWith<MorphItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MorphItemCopyWith<$Res> {
  factory $MorphItemCopyWith(MorphItem value, $Res Function(MorphItem) then) =
      _$MorphItemCopyWithImpl<$Res, MorphItem>;
  @useResult
  $Res call(
      {String word,
      String originalWord,
      String strongsNumber,
      String partOfSpeech,
      String? tense,
      String? voice,
      String? mood,
      String? personNumber,
      String plainEnglishExplanation});
}

/// @nodoc
class _$MorphItemCopyWithImpl<$Res, $Val extends MorphItem>
    implements $MorphItemCopyWith<$Res> {
  _$MorphItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MorphItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? originalWord = null,
    Object? strongsNumber = null,
    Object? partOfSpeech = null,
    Object? tense = freezed,
    Object? voice = freezed,
    Object? mood = freezed,
    Object? personNumber = freezed,
    Object? plainEnglishExplanation = null,
  }) {
    return _then(_value.copyWith(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      originalWord: null == originalWord
          ? _value.originalWord
          : originalWord // ignore: cast_nullable_to_non_nullable
              as String,
      strongsNumber: null == strongsNumber
          ? _value.strongsNumber
          : strongsNumber // ignore: cast_nullable_to_non_nullable
              as String,
      partOfSpeech: null == partOfSpeech
          ? _value.partOfSpeech
          : partOfSpeech // ignore: cast_nullable_to_non_nullable
              as String,
      tense: freezed == tense
          ? _value.tense
          : tense // ignore: cast_nullable_to_non_nullable
              as String?,
      voice: freezed == voice
          ? _value.voice
          : voice // ignore: cast_nullable_to_non_nullable
              as String?,
      mood: freezed == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String?,
      personNumber: freezed == personNumber
          ? _value.personNumber
          : personNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      plainEnglishExplanation: null == plainEnglishExplanation
          ? _value.plainEnglishExplanation
          : plainEnglishExplanation // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MorphItemImplCopyWith<$Res>
    implements $MorphItemCopyWith<$Res> {
  factory _$$MorphItemImplCopyWith(
          _$MorphItemImpl value, $Res Function(_$MorphItemImpl) then) =
      __$$MorphItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String word,
      String originalWord,
      String strongsNumber,
      String partOfSpeech,
      String? tense,
      String? voice,
      String? mood,
      String? personNumber,
      String plainEnglishExplanation});
}

/// @nodoc
class __$$MorphItemImplCopyWithImpl<$Res>
    extends _$MorphItemCopyWithImpl<$Res, _$MorphItemImpl>
    implements _$$MorphItemImplCopyWith<$Res> {
  __$$MorphItemImplCopyWithImpl(
      _$MorphItemImpl _value, $Res Function(_$MorphItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of MorphItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? originalWord = null,
    Object? strongsNumber = null,
    Object? partOfSpeech = null,
    Object? tense = freezed,
    Object? voice = freezed,
    Object? mood = freezed,
    Object? personNumber = freezed,
    Object? plainEnglishExplanation = null,
  }) {
    return _then(_$MorphItemImpl(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      originalWord: null == originalWord
          ? _value.originalWord
          : originalWord // ignore: cast_nullable_to_non_nullable
              as String,
      strongsNumber: null == strongsNumber
          ? _value.strongsNumber
          : strongsNumber // ignore: cast_nullable_to_non_nullable
              as String,
      partOfSpeech: null == partOfSpeech
          ? _value.partOfSpeech
          : partOfSpeech // ignore: cast_nullable_to_non_nullable
              as String,
      tense: freezed == tense
          ? _value.tense
          : tense // ignore: cast_nullable_to_non_nullable
              as String?,
      voice: freezed == voice
          ? _value.voice
          : voice // ignore: cast_nullable_to_non_nullable
              as String?,
      mood: freezed == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String?,
      personNumber: freezed == personNumber
          ? _value.personNumber
          : personNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      plainEnglishExplanation: null == plainEnglishExplanation
          ? _value.plainEnglishExplanation
          : plainEnglishExplanation // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MorphItemImpl implements _MorphItem {
  const _$MorphItemImpl(
      {required this.word,
      required this.originalWord,
      required this.strongsNumber,
      required this.partOfSpeech,
      this.tense,
      this.voice,
      this.mood,
      this.personNumber,
      required this.plainEnglishExplanation});

  factory _$MorphItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MorphItemImplFromJson(json);

  @override
  final String word;
  @override
  final String originalWord;
  @override
  final String strongsNumber;
  @override
  final String partOfSpeech;
  @override
  final String? tense;
  @override
  final String? voice;
  @override
  final String? mood;
  @override
  final String? personNumber;
  @override
  final String plainEnglishExplanation;

  @override
  String toString() {
    return 'MorphItem(word: $word, originalWord: $originalWord, strongsNumber: $strongsNumber, partOfSpeech: $partOfSpeech, tense: $tense, voice: $voice, mood: $mood, personNumber: $personNumber, plainEnglishExplanation: $plainEnglishExplanation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MorphItemImpl &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.originalWord, originalWord) ||
                other.originalWord == originalWord) &&
            (identical(other.strongsNumber, strongsNumber) ||
                other.strongsNumber == strongsNumber) &&
            (identical(other.partOfSpeech, partOfSpeech) ||
                other.partOfSpeech == partOfSpeech) &&
            (identical(other.tense, tense) || other.tense == tense) &&
            (identical(other.voice, voice) || other.voice == voice) &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.personNumber, personNumber) ||
                other.personNumber == personNumber) &&
            (identical(
                    other.plainEnglishExplanation, plainEnglishExplanation) ||
                other.plainEnglishExplanation == plainEnglishExplanation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      word,
      originalWord,
      strongsNumber,
      partOfSpeech,
      tense,
      voice,
      mood,
      personNumber,
      plainEnglishExplanation);

  /// Create a copy of MorphItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MorphItemImplCopyWith<_$MorphItemImpl> get copyWith =>
      __$$MorphItemImplCopyWithImpl<_$MorphItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MorphItemImplToJson(
      this,
    );
  }
}

abstract class _MorphItem implements MorphItem {
  const factory _MorphItem(
      {required final String word,
      required final String originalWord,
      required final String strongsNumber,
      required final String partOfSpeech,
      final String? tense,
      final String? voice,
      final String? mood,
      final String? personNumber,
      required final String plainEnglishExplanation}) = _$MorphItemImpl;

  factory _MorphItem.fromJson(Map<String, dynamic> json) =
      _$MorphItemImpl.fromJson;

  @override
  String get word;
  @override
  String get originalWord;
  @override
  String get strongsNumber;
  @override
  String get partOfSpeech;
  @override
  String? get tense;
  @override
  String? get voice;
  @override
  String? get mood;
  @override
  String? get personNumber;
  @override
  String get plainEnglishExplanation;

  /// Create a copy of MorphItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MorphItemImplCopyWith<_$MorphItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConfusedWord _$ConfusedWordFromJson(Map<String, dynamic> json) {
  return _ConfusedWord.fromJson(json);
}

/// @nodoc
mixin _$ConfusedWord {
  String get word => throw _privateConstructorUsedError;
  String get strongsNumber => throw _privateConstructorUsedError;
  String get meaningDifference => throw _privateConstructorUsedError;
  String get exampleVerse => throw _privateConstructorUsedError;

  /// Serializes this ConfusedWord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConfusedWord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConfusedWordCopyWith<ConfusedWord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConfusedWordCopyWith<$Res> {
  factory $ConfusedWordCopyWith(
          ConfusedWord value, $Res Function(ConfusedWord) then) =
      _$ConfusedWordCopyWithImpl<$Res, ConfusedWord>;
  @useResult
  $Res call(
      {String word,
      String strongsNumber,
      String meaningDifference,
      String exampleVerse});
}

/// @nodoc
class _$ConfusedWordCopyWithImpl<$Res, $Val extends ConfusedWord>
    implements $ConfusedWordCopyWith<$Res> {
  _$ConfusedWordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConfusedWord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? strongsNumber = null,
    Object? meaningDifference = null,
    Object? exampleVerse = null,
  }) {
    return _then(_value.copyWith(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      strongsNumber: null == strongsNumber
          ? _value.strongsNumber
          : strongsNumber // ignore: cast_nullable_to_non_nullable
              as String,
      meaningDifference: null == meaningDifference
          ? _value.meaningDifference
          : meaningDifference // ignore: cast_nullable_to_non_nullable
              as String,
      exampleVerse: null == exampleVerse
          ? _value.exampleVerse
          : exampleVerse // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConfusedWordImplCopyWith<$Res>
    implements $ConfusedWordCopyWith<$Res> {
  factory _$$ConfusedWordImplCopyWith(
          _$ConfusedWordImpl value, $Res Function(_$ConfusedWordImpl) then) =
      __$$ConfusedWordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String word,
      String strongsNumber,
      String meaningDifference,
      String exampleVerse});
}

/// @nodoc
class __$$ConfusedWordImplCopyWithImpl<$Res>
    extends _$ConfusedWordCopyWithImpl<$Res, _$ConfusedWordImpl>
    implements _$$ConfusedWordImplCopyWith<$Res> {
  __$$ConfusedWordImplCopyWithImpl(
      _$ConfusedWordImpl _value, $Res Function(_$ConfusedWordImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConfusedWord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? strongsNumber = null,
    Object? meaningDifference = null,
    Object? exampleVerse = null,
  }) {
    return _then(_$ConfusedWordImpl(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      strongsNumber: null == strongsNumber
          ? _value.strongsNumber
          : strongsNumber // ignore: cast_nullable_to_non_nullable
              as String,
      meaningDifference: null == meaningDifference
          ? _value.meaningDifference
          : meaningDifference // ignore: cast_nullable_to_non_nullable
              as String,
      exampleVerse: null == exampleVerse
          ? _value.exampleVerse
          : exampleVerse // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConfusedWordImpl implements _ConfusedWord {
  const _$ConfusedWordImpl(
      {required this.word,
      required this.strongsNumber,
      required this.meaningDifference,
      required this.exampleVerse});

  factory _$ConfusedWordImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConfusedWordImplFromJson(json);

  @override
  final String word;
  @override
  final String strongsNumber;
  @override
  final String meaningDifference;
  @override
  final String exampleVerse;

  @override
  String toString() {
    return 'ConfusedWord(word: $word, strongsNumber: $strongsNumber, meaningDifference: $meaningDifference, exampleVerse: $exampleVerse)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConfusedWordImpl &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.strongsNumber, strongsNumber) ||
                other.strongsNumber == strongsNumber) &&
            (identical(other.meaningDifference, meaningDifference) ||
                other.meaningDifference == meaningDifference) &&
            (identical(other.exampleVerse, exampleVerse) ||
                other.exampleVerse == exampleVerse));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, word, strongsNumber, meaningDifference, exampleVerse);

  /// Create a copy of ConfusedWord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConfusedWordImplCopyWith<_$ConfusedWordImpl> get copyWith =>
      __$$ConfusedWordImplCopyWithImpl<_$ConfusedWordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConfusedWordImplToJson(
      this,
    );
  }
}

abstract class _ConfusedWord implements ConfusedWord {
  const factory _ConfusedWord(
      {required final String word,
      required final String strongsNumber,
      required final String meaningDifference,
      required final String exampleVerse}) = _$ConfusedWordImpl;

  factory _ConfusedWord.fromJson(Map<String, dynamic> json) =
      _$ConfusedWordImpl.fromJson;

  @override
  String get word;
  @override
  String get strongsNumber;
  @override
  String get meaningDifference;
  @override
  String get exampleVerse;

  /// Create a copy of ConfusedWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConfusedWordImplCopyWith<_$ConfusedWordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SemanticItem _$SemanticItemFromJson(Map<String, dynamic> json) {
  return _SemanticItem.fromJson(json);
}

/// @nodoc
mixin _$SemanticItem {
  String get englishWord => throw _privateConstructorUsedError;
  String get disambiguation => throw _privateConstructorUsedError;
  String get wordUsedHere => throw _privateConstructorUsedError;
  String get wordUsedHereStrongs => throw _privateConstructorUsedError;
  List<ConfusedWord> get confusedWith => throw _privateConstructorUsedError;

  /// Serializes this SemanticItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SemanticItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SemanticItemCopyWith<SemanticItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SemanticItemCopyWith<$Res> {
  factory $SemanticItemCopyWith(
          SemanticItem value, $Res Function(SemanticItem) then) =
      _$SemanticItemCopyWithImpl<$Res, SemanticItem>;
  @useResult
  $Res call(
      {String englishWord,
      String disambiguation,
      String wordUsedHere,
      String wordUsedHereStrongs,
      List<ConfusedWord> confusedWith});
}

/// @nodoc
class _$SemanticItemCopyWithImpl<$Res, $Val extends SemanticItem>
    implements $SemanticItemCopyWith<$Res> {
  _$SemanticItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SemanticItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? englishWord = null,
    Object? disambiguation = null,
    Object? wordUsedHere = null,
    Object? wordUsedHereStrongs = null,
    Object? confusedWith = null,
  }) {
    return _then(_value.copyWith(
      englishWord: null == englishWord
          ? _value.englishWord
          : englishWord // ignore: cast_nullable_to_non_nullable
              as String,
      disambiguation: null == disambiguation
          ? _value.disambiguation
          : disambiguation // ignore: cast_nullable_to_non_nullable
              as String,
      wordUsedHere: null == wordUsedHere
          ? _value.wordUsedHere
          : wordUsedHere // ignore: cast_nullable_to_non_nullable
              as String,
      wordUsedHereStrongs: null == wordUsedHereStrongs
          ? _value.wordUsedHereStrongs
          : wordUsedHereStrongs // ignore: cast_nullable_to_non_nullable
              as String,
      confusedWith: null == confusedWith
          ? _value.confusedWith
          : confusedWith // ignore: cast_nullable_to_non_nullable
              as List<ConfusedWord>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SemanticItemImplCopyWith<$Res>
    implements $SemanticItemCopyWith<$Res> {
  factory _$$SemanticItemImplCopyWith(
          _$SemanticItemImpl value, $Res Function(_$SemanticItemImpl) then) =
      __$$SemanticItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String englishWord,
      String disambiguation,
      String wordUsedHere,
      String wordUsedHereStrongs,
      List<ConfusedWord> confusedWith});
}

/// @nodoc
class __$$SemanticItemImplCopyWithImpl<$Res>
    extends _$SemanticItemCopyWithImpl<$Res, _$SemanticItemImpl>
    implements _$$SemanticItemImplCopyWith<$Res> {
  __$$SemanticItemImplCopyWithImpl(
      _$SemanticItemImpl _value, $Res Function(_$SemanticItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of SemanticItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? englishWord = null,
    Object? disambiguation = null,
    Object? wordUsedHere = null,
    Object? wordUsedHereStrongs = null,
    Object? confusedWith = null,
  }) {
    return _then(_$SemanticItemImpl(
      englishWord: null == englishWord
          ? _value.englishWord
          : englishWord // ignore: cast_nullable_to_non_nullable
              as String,
      disambiguation: null == disambiguation
          ? _value.disambiguation
          : disambiguation // ignore: cast_nullable_to_non_nullable
              as String,
      wordUsedHere: null == wordUsedHere
          ? _value.wordUsedHere
          : wordUsedHere // ignore: cast_nullable_to_non_nullable
              as String,
      wordUsedHereStrongs: null == wordUsedHereStrongs
          ? _value.wordUsedHereStrongs
          : wordUsedHereStrongs // ignore: cast_nullable_to_non_nullable
              as String,
      confusedWith: null == confusedWith
          ? _value._confusedWith
          : confusedWith // ignore: cast_nullable_to_non_nullable
              as List<ConfusedWord>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SemanticItemImpl implements _SemanticItem {
  const _$SemanticItemImpl(
      {required this.englishWord,
      required this.disambiguation,
      required this.wordUsedHere,
      required this.wordUsedHereStrongs,
      final List<ConfusedWord> confusedWith = const []})
      : _confusedWith = confusedWith;

  factory _$SemanticItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SemanticItemImplFromJson(json);

  @override
  final String englishWord;
  @override
  final String disambiguation;
  @override
  final String wordUsedHere;
  @override
  final String wordUsedHereStrongs;
  final List<ConfusedWord> _confusedWith;
  @override
  @JsonKey()
  List<ConfusedWord> get confusedWith {
    if (_confusedWith is EqualUnmodifiableListView) return _confusedWith;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_confusedWith);
  }

  @override
  String toString() {
    return 'SemanticItem(englishWord: $englishWord, disambiguation: $disambiguation, wordUsedHere: $wordUsedHere, wordUsedHereStrongs: $wordUsedHereStrongs, confusedWith: $confusedWith)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SemanticItemImpl &&
            (identical(other.englishWord, englishWord) ||
                other.englishWord == englishWord) &&
            (identical(other.disambiguation, disambiguation) ||
                other.disambiguation == disambiguation) &&
            (identical(other.wordUsedHere, wordUsedHere) ||
                other.wordUsedHere == wordUsedHere) &&
            (identical(other.wordUsedHereStrongs, wordUsedHereStrongs) ||
                other.wordUsedHereStrongs == wordUsedHereStrongs) &&
            const DeepCollectionEquality()
                .equals(other._confusedWith, _confusedWith));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      englishWord,
      disambiguation,
      wordUsedHere,
      wordUsedHereStrongs,
      const DeepCollectionEquality().hash(_confusedWith));

  /// Create a copy of SemanticItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SemanticItemImplCopyWith<_$SemanticItemImpl> get copyWith =>
      __$$SemanticItemImplCopyWithImpl<_$SemanticItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SemanticItemImplToJson(
      this,
    );
  }
}

abstract class _SemanticItem implements SemanticItem {
  const factory _SemanticItem(
      {required final String englishWord,
      required final String disambiguation,
      required final String wordUsedHere,
      required final String wordUsedHereStrongs,
      final List<ConfusedWord> confusedWith}) = _$SemanticItemImpl;

  factory _SemanticItem.fromJson(Map<String, dynamic> json) =
      _$SemanticItemImpl.fromJson;

  @override
  String get englishWord;
  @override
  String get disambiguation;
  @override
  String get wordUsedHere;
  @override
  String get wordUsedHereStrongs;
  @override
  List<ConfusedWord> get confusedWith;

  /// Create a copy of SemanticItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SemanticItemImplCopyWith<_$SemanticItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DevelopmentMention _$DevelopmentMentionFromJson(Map<String, dynamic> json) {
  return _DevelopmentMention.fromJson(json);
}

/// @nodoc
mixin _$DevelopmentMention {
  String get reference => throw _privateConstructorUsedError;
  String get development => throw _privateConstructorUsedError;

  /// Serializes this DevelopmentMention to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DevelopmentMention
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DevelopmentMentionCopyWith<DevelopmentMention> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DevelopmentMentionCopyWith<$Res> {
  factory $DevelopmentMentionCopyWith(
          DevelopmentMention value, $Res Function(DevelopmentMention) then) =
      _$DevelopmentMentionCopyWithImpl<$Res, DevelopmentMention>;
  @useResult
  $Res call({String reference, String development});
}

/// @nodoc
class _$DevelopmentMentionCopyWithImpl<$Res, $Val extends DevelopmentMention>
    implements $DevelopmentMentionCopyWith<$Res> {
  _$DevelopmentMentionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DevelopmentMention
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? development = null,
  }) {
    return _then(_value.copyWith(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      development: null == development
          ? _value.development
          : development // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DevelopmentMentionImplCopyWith<$Res>
    implements $DevelopmentMentionCopyWith<$Res> {
  factory _$$DevelopmentMentionImplCopyWith(_$DevelopmentMentionImpl value,
          $Res Function(_$DevelopmentMentionImpl) then) =
      __$$DevelopmentMentionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reference, String development});
}

/// @nodoc
class __$$DevelopmentMentionImplCopyWithImpl<$Res>
    extends _$DevelopmentMentionCopyWithImpl<$Res, _$DevelopmentMentionImpl>
    implements _$$DevelopmentMentionImplCopyWith<$Res> {
  __$$DevelopmentMentionImplCopyWithImpl(_$DevelopmentMentionImpl _value,
      $Res Function(_$DevelopmentMentionImpl) _then)
      : super(_value, _then);

  /// Create a copy of DevelopmentMention
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? development = null,
  }) {
    return _then(_$DevelopmentMentionImpl(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      development: null == development
          ? _value.development
          : development // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DevelopmentMentionImpl implements _DevelopmentMention {
  const _$DevelopmentMentionImpl(
      {required this.reference, required this.development});

  factory _$DevelopmentMentionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DevelopmentMentionImplFromJson(json);

  @override
  final String reference;
  @override
  final String development;

  @override
  String toString() {
    return 'DevelopmentMention(reference: $reference, development: $development)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DevelopmentMentionImpl &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.development, development) ||
                other.development == development));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reference, development);

  /// Create a copy of DevelopmentMention
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DevelopmentMentionImplCopyWith<_$DevelopmentMentionImpl> get copyWith =>
      __$$DevelopmentMentionImplCopyWithImpl<_$DevelopmentMentionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DevelopmentMentionImplToJson(
      this,
    );
  }
}

abstract class _DevelopmentMention implements DevelopmentMention {
  const factory _DevelopmentMention(
      {required final String reference,
      required final String development}) = _$DevelopmentMentionImpl;

  factory _DevelopmentMention.fromJson(Map<String, dynamic> json) =
      _$DevelopmentMentionImpl.fromJson;

  @override
  String get reference;
  @override
  String get development;

  /// Create a copy of DevelopmentMention
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DevelopmentMentionImplCopyWith<_$DevelopmentMentionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FirstMentionDetail _$FirstMentionDetailFromJson(Map<String, dynamic> json) {
  return _FirstMentionDetail.fromJson(json);
}

/// @nodoc
mixin _$FirstMentionDetail {
  String get reference => throw _privateConstructorUsedError;
  String? get verseText => throw _privateConstructorUsedError;
  String get whatItEstablishes => throw _privateConstructorUsedError;

  /// Serializes this FirstMentionDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FirstMentionDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FirstMentionDetailCopyWith<FirstMentionDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FirstMentionDetailCopyWith<$Res> {
  factory $FirstMentionDetailCopyWith(
          FirstMentionDetail value, $Res Function(FirstMentionDetail) then) =
      _$FirstMentionDetailCopyWithImpl<$Res, FirstMentionDetail>;
  @useResult
  $Res call({String reference, String? verseText, String whatItEstablishes});
}

/// @nodoc
class _$FirstMentionDetailCopyWithImpl<$Res, $Val extends FirstMentionDetail>
    implements $FirstMentionDetailCopyWith<$Res> {
  _$FirstMentionDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FirstMentionDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? verseText = freezed,
    Object? whatItEstablishes = null,
  }) {
    return _then(_value.copyWith(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      verseText: freezed == verseText
          ? _value.verseText
          : verseText // ignore: cast_nullable_to_non_nullable
              as String?,
      whatItEstablishes: null == whatItEstablishes
          ? _value.whatItEstablishes
          : whatItEstablishes // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FirstMentionDetailImplCopyWith<$Res>
    implements $FirstMentionDetailCopyWith<$Res> {
  factory _$$FirstMentionDetailImplCopyWith(_$FirstMentionDetailImpl value,
          $Res Function(_$FirstMentionDetailImpl) then) =
      __$$FirstMentionDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reference, String? verseText, String whatItEstablishes});
}

/// @nodoc
class __$$FirstMentionDetailImplCopyWithImpl<$Res>
    extends _$FirstMentionDetailCopyWithImpl<$Res, _$FirstMentionDetailImpl>
    implements _$$FirstMentionDetailImplCopyWith<$Res> {
  __$$FirstMentionDetailImplCopyWithImpl(_$FirstMentionDetailImpl _value,
      $Res Function(_$FirstMentionDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of FirstMentionDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? verseText = freezed,
    Object? whatItEstablishes = null,
  }) {
    return _then(_$FirstMentionDetailImpl(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      verseText: freezed == verseText
          ? _value.verseText
          : verseText // ignore: cast_nullable_to_non_nullable
              as String?,
      whatItEstablishes: null == whatItEstablishes
          ? _value.whatItEstablishes
          : whatItEstablishes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FirstMentionDetailImpl implements _FirstMentionDetail {
  const _$FirstMentionDetailImpl(
      {required this.reference,
      this.verseText,
      required this.whatItEstablishes});

  factory _$FirstMentionDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$FirstMentionDetailImplFromJson(json);

  @override
  final String reference;
  @override
  final String? verseText;
  @override
  final String whatItEstablishes;

  @override
  String toString() {
    return 'FirstMentionDetail(reference: $reference, verseText: $verseText, whatItEstablishes: $whatItEstablishes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FirstMentionDetailImpl &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.verseText, verseText) ||
                other.verseText == verseText) &&
            (identical(other.whatItEstablishes, whatItEstablishes) ||
                other.whatItEstablishes == whatItEstablishes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, reference, verseText, whatItEstablishes);

  /// Create a copy of FirstMentionDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FirstMentionDetailImplCopyWith<_$FirstMentionDetailImpl> get copyWith =>
      __$$FirstMentionDetailImplCopyWithImpl<_$FirstMentionDetailImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FirstMentionDetailImplToJson(
      this,
    );
  }
}

abstract class _FirstMentionDetail implements FirstMentionDetail {
  const factory _FirstMentionDetail(
      {required final String reference,
      final String? verseText,
      required final String whatItEstablishes}) = _$FirstMentionDetailImpl;

  factory _FirstMentionDetail.fromJson(Map<String, dynamic> json) =
      _$FirstMentionDetailImpl.fromJson;

  @override
  String get reference;
  @override
  String? get verseText;
  @override
  String get whatItEstablishes;

  /// Create a copy of FirstMentionDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FirstMentionDetailImplCopyWith<_$FirstMentionDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MentionItem _$MentionItemFromJson(Map<String, dynamic> json) {
  return _MentionItem.fromJson(json);
}

/// @nodoc
mixin _$MentionItem {
  String get concept => throw _privateConstructorUsedError;
  FirstMentionDetail get firstMention => throw _privateConstructorUsedError;
  List<DevelopmentMention> get developmentMentions =>
      throw _privateConstructorUsedError;
  String? get emphasisPattern => throw _privateConstructorUsedError;

  /// Serializes this MentionItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MentionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MentionItemCopyWith<MentionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MentionItemCopyWith<$Res> {
  factory $MentionItemCopyWith(
          MentionItem value, $Res Function(MentionItem) then) =
      _$MentionItemCopyWithImpl<$Res, MentionItem>;
  @useResult
  $Res call(
      {String concept,
      FirstMentionDetail firstMention,
      List<DevelopmentMention> developmentMentions,
      String? emphasisPattern});

  $FirstMentionDetailCopyWith<$Res> get firstMention;
}

/// @nodoc
class _$MentionItemCopyWithImpl<$Res, $Val extends MentionItem>
    implements $MentionItemCopyWith<$Res> {
  _$MentionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MentionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? concept = null,
    Object? firstMention = null,
    Object? developmentMentions = null,
    Object? emphasisPattern = freezed,
  }) {
    return _then(_value.copyWith(
      concept: null == concept
          ? _value.concept
          : concept // ignore: cast_nullable_to_non_nullable
              as String,
      firstMention: null == firstMention
          ? _value.firstMention
          : firstMention // ignore: cast_nullable_to_non_nullable
              as FirstMentionDetail,
      developmentMentions: null == developmentMentions
          ? _value.developmentMentions
          : developmentMentions // ignore: cast_nullable_to_non_nullable
              as List<DevelopmentMention>,
      emphasisPattern: freezed == emphasisPattern
          ? _value.emphasisPattern
          : emphasisPattern // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of MentionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FirstMentionDetailCopyWith<$Res> get firstMention {
    return $FirstMentionDetailCopyWith<$Res>(_value.firstMention, (value) {
      return _then(_value.copyWith(firstMention: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MentionItemImplCopyWith<$Res>
    implements $MentionItemCopyWith<$Res> {
  factory _$$MentionItemImplCopyWith(
          _$MentionItemImpl value, $Res Function(_$MentionItemImpl) then) =
      __$$MentionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String concept,
      FirstMentionDetail firstMention,
      List<DevelopmentMention> developmentMentions,
      String? emphasisPattern});

  @override
  $FirstMentionDetailCopyWith<$Res> get firstMention;
}

/// @nodoc
class __$$MentionItemImplCopyWithImpl<$Res>
    extends _$MentionItemCopyWithImpl<$Res, _$MentionItemImpl>
    implements _$$MentionItemImplCopyWith<$Res> {
  __$$MentionItemImplCopyWithImpl(
      _$MentionItemImpl _value, $Res Function(_$MentionItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of MentionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? concept = null,
    Object? firstMention = null,
    Object? developmentMentions = null,
    Object? emphasisPattern = freezed,
  }) {
    return _then(_$MentionItemImpl(
      concept: null == concept
          ? _value.concept
          : concept // ignore: cast_nullable_to_non_nullable
              as String,
      firstMention: null == firstMention
          ? _value.firstMention
          : firstMention // ignore: cast_nullable_to_non_nullable
              as FirstMentionDetail,
      developmentMentions: null == developmentMentions
          ? _value._developmentMentions
          : developmentMentions // ignore: cast_nullable_to_non_nullable
              as List<DevelopmentMention>,
      emphasisPattern: freezed == emphasisPattern
          ? _value.emphasisPattern
          : emphasisPattern // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MentionItemImpl implements _MentionItem {
  const _$MentionItemImpl(
      {required this.concept,
      required this.firstMention,
      final List<DevelopmentMention> developmentMentions = const [],
      this.emphasisPattern})
      : _developmentMentions = developmentMentions;

  factory _$MentionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MentionItemImplFromJson(json);

  @override
  final String concept;
  @override
  final FirstMentionDetail firstMention;
  final List<DevelopmentMention> _developmentMentions;
  @override
  @JsonKey()
  List<DevelopmentMention> get developmentMentions {
    if (_developmentMentions is EqualUnmodifiableListView)
      return _developmentMentions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_developmentMentions);
  }

  @override
  final String? emphasisPattern;

  @override
  String toString() {
    return 'MentionItem(concept: $concept, firstMention: $firstMention, developmentMentions: $developmentMentions, emphasisPattern: $emphasisPattern)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MentionItemImpl &&
            (identical(other.concept, concept) || other.concept == concept) &&
            (identical(other.firstMention, firstMention) ||
                other.firstMention == firstMention) &&
            const DeepCollectionEquality()
                .equals(other._developmentMentions, _developmentMentions) &&
            (identical(other.emphasisPattern, emphasisPattern) ||
                other.emphasisPattern == emphasisPattern));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      concept,
      firstMention,
      const DeepCollectionEquality().hash(_developmentMentions),
      emphasisPattern);

  /// Create a copy of MentionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MentionItemImplCopyWith<_$MentionItemImpl> get copyWith =>
      __$$MentionItemImplCopyWithImpl<_$MentionItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MentionItemImplToJson(
      this,
    );
  }
}

abstract class _MentionItem implements MentionItem {
  const factory _MentionItem(
      {required final String concept,
      required final FirstMentionDetail firstMention,
      final List<DevelopmentMention> developmentMentions,
      final String? emphasisPattern}) = _$MentionItemImpl;

  factory _MentionItem.fromJson(Map<String, dynamic> json) =
      _$MentionItemImpl.fromJson;

  @override
  String get concept;
  @override
  FirstMentionDetail get firstMention;
  @override
  List<DevelopmentMention> get developmentMentions;
  @override
  String? get emphasisPattern;

  /// Create a copy of MentionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MentionItemImplCopyWith<_$MentionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LogicalConnector _$LogicalConnectorFromJson(Map<String, dynamic> json) {
  return _LogicalConnector.fromJson(json);
}

/// @nodoc
mixin _$LogicalConnector {
  String get word => throw _privateConstructorUsedError;
  String get originalWord => throw _privateConstructorUsedError;
  String get significance => throw _privateConstructorUsedError;

  /// Serializes this LogicalConnector to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LogicalConnector
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LogicalConnectorCopyWith<LogicalConnector> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogicalConnectorCopyWith<$Res> {
  factory $LogicalConnectorCopyWith(
          LogicalConnector value, $Res Function(LogicalConnector) then) =
      _$LogicalConnectorCopyWithImpl<$Res, LogicalConnector>;
  @useResult
  $Res call({String word, String originalWord, String significance});
}

/// @nodoc
class _$LogicalConnectorCopyWithImpl<$Res, $Val extends LogicalConnector>
    implements $LogicalConnectorCopyWith<$Res> {
  _$LogicalConnectorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LogicalConnector
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? originalWord = null,
    Object? significance = null,
  }) {
    return _then(_value.copyWith(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      originalWord: null == originalWord
          ? _value.originalWord
          : originalWord // ignore: cast_nullable_to_non_nullable
              as String,
      significance: null == significance
          ? _value.significance
          : significance // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LogicalConnectorImplCopyWith<$Res>
    implements $LogicalConnectorCopyWith<$Res> {
  factory _$$LogicalConnectorImplCopyWith(_$LogicalConnectorImpl value,
          $Res Function(_$LogicalConnectorImpl) then) =
      __$$LogicalConnectorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String word, String originalWord, String significance});
}

/// @nodoc
class __$$LogicalConnectorImplCopyWithImpl<$Res>
    extends _$LogicalConnectorCopyWithImpl<$Res, _$LogicalConnectorImpl>
    implements _$$LogicalConnectorImplCopyWith<$Res> {
  __$$LogicalConnectorImplCopyWithImpl(_$LogicalConnectorImpl _value,
      $Res Function(_$LogicalConnectorImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogicalConnector
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? originalWord = null,
    Object? significance = null,
  }) {
    return _then(_$LogicalConnectorImpl(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      originalWord: null == originalWord
          ? _value.originalWord
          : originalWord // ignore: cast_nullable_to_non_nullable
              as String,
      significance: null == significance
          ? _value.significance
          : significance // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LogicalConnectorImpl implements _LogicalConnector {
  const _$LogicalConnectorImpl(
      {required this.word,
      required this.originalWord,
      required this.significance});

  factory _$LogicalConnectorImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogicalConnectorImplFromJson(json);

  @override
  final String word;
  @override
  final String originalWord;
  @override
  final String significance;

  @override
  String toString() {
    return 'LogicalConnector(word: $word, originalWord: $originalWord, significance: $significance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogicalConnectorImpl &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.originalWord, originalWord) ||
                other.originalWord == originalWord) &&
            (identical(other.significance, significance) ||
                other.significance == significance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, word, originalWord, significance);

  /// Create a copy of LogicalConnector
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LogicalConnectorImplCopyWith<_$LogicalConnectorImpl> get copyWith =>
      __$$LogicalConnectorImplCopyWithImpl<_$LogicalConnectorImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LogicalConnectorImplToJson(
      this,
    );
  }
}

abstract class _LogicalConnector implements LogicalConnector {
  const factory _LogicalConnector(
      {required final String word,
      required final String originalWord,
      required final String significance}) = _$LogicalConnectorImpl;

  factory _LogicalConnector.fromJson(Map<String, dynamic> json) =
      _$LogicalConnectorImpl.fromJson;

  @override
  String get word;
  @override
  String get originalWord;
  @override
  String get significance;

  /// Create a copy of LogicalConnector
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LogicalConnectorImplCopyWith<_$LogicalConnectorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiscourseAnalysis _$DiscourseAnalysisFromJson(Map<String, dynamic> json) {
  return _DiscourseAnalysis.fromJson(json);
}

/// @nodoc
mixin _$DiscourseAnalysis {
  String get rhetoricalFunction => throw _privateConstructorUsedError;
  List<LogicalConnector> get logicalConnectors =>
      throw _privateConstructorUsedError;
  String get authorIntent => throw _privateConstructorUsedError;

  /// Serializes this DiscourseAnalysis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiscourseAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiscourseAnalysisCopyWith<DiscourseAnalysis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscourseAnalysisCopyWith<$Res> {
  factory $DiscourseAnalysisCopyWith(
          DiscourseAnalysis value, $Res Function(DiscourseAnalysis) then) =
      _$DiscourseAnalysisCopyWithImpl<$Res, DiscourseAnalysis>;
  @useResult
  $Res call(
      {String rhetoricalFunction,
      List<LogicalConnector> logicalConnectors,
      String authorIntent});
}

/// @nodoc
class _$DiscourseAnalysisCopyWithImpl<$Res, $Val extends DiscourseAnalysis>
    implements $DiscourseAnalysisCopyWith<$Res> {
  _$DiscourseAnalysisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiscourseAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rhetoricalFunction = null,
    Object? logicalConnectors = null,
    Object? authorIntent = null,
  }) {
    return _then(_value.copyWith(
      rhetoricalFunction: null == rhetoricalFunction
          ? _value.rhetoricalFunction
          : rhetoricalFunction // ignore: cast_nullable_to_non_nullable
              as String,
      logicalConnectors: null == logicalConnectors
          ? _value.logicalConnectors
          : logicalConnectors // ignore: cast_nullable_to_non_nullable
              as List<LogicalConnector>,
      authorIntent: null == authorIntent
          ? _value.authorIntent
          : authorIntent // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiscourseAnalysisImplCopyWith<$Res>
    implements $DiscourseAnalysisCopyWith<$Res> {
  factory _$$DiscourseAnalysisImplCopyWith(_$DiscourseAnalysisImpl value,
          $Res Function(_$DiscourseAnalysisImpl) then) =
      __$$DiscourseAnalysisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String rhetoricalFunction,
      List<LogicalConnector> logicalConnectors,
      String authorIntent});
}

/// @nodoc
class __$$DiscourseAnalysisImplCopyWithImpl<$Res>
    extends _$DiscourseAnalysisCopyWithImpl<$Res, _$DiscourseAnalysisImpl>
    implements _$$DiscourseAnalysisImplCopyWith<$Res> {
  __$$DiscourseAnalysisImplCopyWithImpl(_$DiscourseAnalysisImpl _value,
      $Res Function(_$DiscourseAnalysisImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiscourseAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rhetoricalFunction = null,
    Object? logicalConnectors = null,
    Object? authorIntent = null,
  }) {
    return _then(_$DiscourseAnalysisImpl(
      rhetoricalFunction: null == rhetoricalFunction
          ? _value.rhetoricalFunction
          : rhetoricalFunction // ignore: cast_nullable_to_non_nullable
              as String,
      logicalConnectors: null == logicalConnectors
          ? _value._logicalConnectors
          : logicalConnectors // ignore: cast_nullable_to_non_nullable
              as List<LogicalConnector>,
      authorIntent: null == authorIntent
          ? _value.authorIntent
          : authorIntent // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiscourseAnalysisImpl implements _DiscourseAnalysis {
  const _$DiscourseAnalysisImpl(
      {required this.rhetoricalFunction,
      final List<LogicalConnector> logicalConnectors = const [],
      required this.authorIntent})
      : _logicalConnectors = logicalConnectors;

  factory _$DiscourseAnalysisImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiscourseAnalysisImplFromJson(json);

  @override
  final String rhetoricalFunction;
  final List<LogicalConnector> _logicalConnectors;
  @override
  @JsonKey()
  List<LogicalConnector> get logicalConnectors {
    if (_logicalConnectors is EqualUnmodifiableListView)
      return _logicalConnectors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_logicalConnectors);
  }

  @override
  final String authorIntent;

  @override
  String toString() {
    return 'DiscourseAnalysis(rhetoricalFunction: $rhetoricalFunction, logicalConnectors: $logicalConnectors, authorIntent: $authorIntent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscourseAnalysisImpl &&
            (identical(other.rhetoricalFunction, rhetoricalFunction) ||
                other.rhetoricalFunction == rhetoricalFunction) &&
            const DeepCollectionEquality()
                .equals(other._logicalConnectors, _logicalConnectors) &&
            (identical(other.authorIntent, authorIntent) ||
                other.authorIntent == authorIntent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rhetoricalFunction,
      const DeepCollectionEquality().hash(_logicalConnectors), authorIntent);

  /// Create a copy of DiscourseAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscourseAnalysisImplCopyWith<_$DiscourseAnalysisImpl> get copyWith =>
      __$$DiscourseAnalysisImplCopyWithImpl<_$DiscourseAnalysisImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiscourseAnalysisImplToJson(
      this,
    );
  }
}

abstract class _DiscourseAnalysis implements DiscourseAnalysis {
  const factory _DiscourseAnalysis(
      {required final String rhetoricalFunction,
      final List<LogicalConnector> logicalConnectors,
      required final String authorIntent}) = _$DiscourseAnalysisImpl;

  factory _DiscourseAnalysis.fromJson(Map<String, dynamic> json) =
      _$DiscourseAnalysisImpl.fromJson;

  @override
  String get rhetoricalFunction;
  @override
  List<LogicalConnector> get logicalConnectors;
  @override
  String get authorIntent;

  /// Create a copy of DiscourseAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscourseAnalysisImplCopyWith<_$DiscourseAnalysisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CrossRef _$CrossRefFromJson(Map<String, dynamic> json) {
  return _CrossRef.fromJson(json);
}

/// @nodoc
mixin _$CrossRef {
  String get reference => throw _privateConstructorUsedError;
  String? get verseText => throw _privateConstructorUsedError;
  String get connectionType => throw _privateConstructorUsedError;
  String get specificContribution => throw _privateConstructorUsedError;

  /// Serializes this CrossRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CrossRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CrossRefCopyWith<CrossRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CrossRefCopyWith<$Res> {
  factory $CrossRefCopyWith(CrossRef value, $Res Function(CrossRef) then) =
      _$CrossRefCopyWithImpl<$Res, CrossRef>;
  @useResult
  $Res call(
      {String reference,
      String? verseText,
      String connectionType,
      String specificContribution});
}

/// @nodoc
class _$CrossRefCopyWithImpl<$Res, $Val extends CrossRef>
    implements $CrossRefCopyWith<$Res> {
  _$CrossRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CrossRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? verseText = freezed,
    Object? connectionType = null,
    Object? specificContribution = null,
  }) {
    return _then(_value.copyWith(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      verseText: freezed == verseText
          ? _value.verseText
          : verseText // ignore: cast_nullable_to_non_nullable
              as String?,
      connectionType: null == connectionType
          ? _value.connectionType
          : connectionType // ignore: cast_nullable_to_non_nullable
              as String,
      specificContribution: null == specificContribution
          ? _value.specificContribution
          : specificContribution // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CrossRefImplCopyWith<$Res>
    implements $CrossRefCopyWith<$Res> {
  factory _$$CrossRefImplCopyWith(
          _$CrossRefImpl value, $Res Function(_$CrossRefImpl) then) =
      __$$CrossRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String reference,
      String? verseText,
      String connectionType,
      String specificContribution});
}

/// @nodoc
class __$$CrossRefImplCopyWithImpl<$Res>
    extends _$CrossRefCopyWithImpl<$Res, _$CrossRefImpl>
    implements _$$CrossRefImplCopyWith<$Res> {
  __$$CrossRefImplCopyWithImpl(
      _$CrossRefImpl _value, $Res Function(_$CrossRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of CrossRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? verseText = freezed,
    Object? connectionType = null,
    Object? specificContribution = null,
  }) {
    return _then(_$CrossRefImpl(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      verseText: freezed == verseText
          ? _value.verseText
          : verseText // ignore: cast_nullable_to_non_nullable
              as String?,
      connectionType: null == connectionType
          ? _value.connectionType
          : connectionType // ignore: cast_nullable_to_non_nullable
              as String,
      specificContribution: null == specificContribution
          ? _value.specificContribution
          : specificContribution // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CrossRefImpl implements _CrossRef {
  const _$CrossRefImpl(
      {required this.reference,
      this.verseText,
      required this.connectionType,
      required this.specificContribution});

  factory _$CrossRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$CrossRefImplFromJson(json);

  @override
  final String reference;
  @override
  final String? verseText;
  @override
  final String connectionType;
  @override
  final String specificContribution;

  @override
  String toString() {
    return 'CrossRef(reference: $reference, verseText: $verseText, connectionType: $connectionType, specificContribution: $specificContribution)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CrossRefImpl &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.verseText, verseText) ||
                other.verseText == verseText) &&
            (identical(other.connectionType, connectionType) ||
                other.connectionType == connectionType) &&
            (identical(other.specificContribution, specificContribution) ||
                other.specificContribution == specificContribution));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, reference, verseText, connectionType, specificContribution);

  /// Create a copy of CrossRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CrossRefImplCopyWith<_$CrossRefImpl> get copyWith =>
      __$$CrossRefImplCopyWithImpl<_$CrossRefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CrossRefImplToJson(
      this,
    );
  }
}

abstract class _CrossRef implements CrossRef {
  const factory _CrossRef(
      {required final String reference,
      final String? verseText,
      required final String connectionType,
      required final String specificContribution}) = _$CrossRefImpl;

  factory _CrossRef.fromJson(Map<String, dynamic> json) =
      _$CrossRefImpl.fromJson;

  @override
  String get reference;
  @override
  String? get verseText;
  @override
  String get connectionType;
  @override
  String get specificContribution;

  /// Create a copy of CrossRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CrossRefImplCopyWith<_$CrossRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Allusion _$AllusionFromJson(Map<String, dynamic> json) {
  return _Allusion.fromJson(json);
}

/// @nodoc
mixin _$Allusion {
  String get sourceText => throw _privateConstructorUsedError;
  String? get sourceVerseText => throw _privateConstructorUsedError;
  String get allusionText => throw _privateConstructorUsedError;
  String get howToHearIt => throw _privateConstructorUsedError;

  /// Serializes this Allusion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Allusion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AllusionCopyWith<Allusion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AllusionCopyWith<$Res> {
  factory $AllusionCopyWith(Allusion value, $Res Function(Allusion) then) =
      _$AllusionCopyWithImpl<$Res, Allusion>;
  @useResult
  $Res call(
      {String sourceText,
      String? sourceVerseText,
      String allusionText,
      String howToHearIt});
}

/// @nodoc
class _$AllusionCopyWithImpl<$Res, $Val extends Allusion>
    implements $AllusionCopyWith<$Res> {
  _$AllusionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Allusion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceText = null,
    Object? sourceVerseText = freezed,
    Object? allusionText = null,
    Object? howToHearIt = null,
  }) {
    return _then(_value.copyWith(
      sourceText: null == sourceText
          ? _value.sourceText
          : sourceText // ignore: cast_nullable_to_non_nullable
              as String,
      sourceVerseText: freezed == sourceVerseText
          ? _value.sourceVerseText
          : sourceVerseText // ignore: cast_nullable_to_non_nullable
              as String?,
      allusionText: null == allusionText
          ? _value.allusionText
          : allusionText // ignore: cast_nullable_to_non_nullable
              as String,
      howToHearIt: null == howToHearIt
          ? _value.howToHearIt
          : howToHearIt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AllusionImplCopyWith<$Res>
    implements $AllusionCopyWith<$Res> {
  factory _$$AllusionImplCopyWith(
          _$AllusionImpl value, $Res Function(_$AllusionImpl) then) =
      __$$AllusionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sourceText,
      String? sourceVerseText,
      String allusionText,
      String howToHearIt});
}

/// @nodoc
class __$$AllusionImplCopyWithImpl<$Res>
    extends _$AllusionCopyWithImpl<$Res, _$AllusionImpl>
    implements _$$AllusionImplCopyWith<$Res> {
  __$$AllusionImplCopyWithImpl(
      _$AllusionImpl _value, $Res Function(_$AllusionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Allusion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceText = null,
    Object? sourceVerseText = freezed,
    Object? allusionText = null,
    Object? howToHearIt = null,
  }) {
    return _then(_$AllusionImpl(
      sourceText: null == sourceText
          ? _value.sourceText
          : sourceText // ignore: cast_nullable_to_non_nullable
              as String,
      sourceVerseText: freezed == sourceVerseText
          ? _value.sourceVerseText
          : sourceVerseText // ignore: cast_nullable_to_non_nullable
              as String?,
      allusionText: null == allusionText
          ? _value.allusionText
          : allusionText // ignore: cast_nullable_to_non_nullable
              as String,
      howToHearIt: null == howToHearIt
          ? _value.howToHearIt
          : howToHearIt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AllusionImpl implements _Allusion {
  const _$AllusionImpl(
      {required this.sourceText,
      this.sourceVerseText,
      required this.allusionText,
      required this.howToHearIt});

  factory _$AllusionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AllusionImplFromJson(json);

  @override
  final String sourceText;
  @override
  final String? sourceVerseText;
  @override
  final String allusionText;
  @override
  final String howToHearIt;

  @override
  String toString() {
    return 'Allusion(sourceText: $sourceText, sourceVerseText: $sourceVerseText, allusionText: $allusionText, howToHearIt: $howToHearIt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AllusionImpl &&
            (identical(other.sourceText, sourceText) ||
                other.sourceText == sourceText) &&
            (identical(other.sourceVerseText, sourceVerseText) ||
                other.sourceVerseText == sourceVerseText) &&
            (identical(other.allusionText, allusionText) ||
                other.allusionText == allusionText) &&
            (identical(other.howToHearIt, howToHearIt) ||
                other.howToHearIt == howToHearIt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, sourceText, sourceVerseText, allusionText, howToHearIt);

  /// Create a copy of Allusion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AllusionImplCopyWith<_$AllusionImpl> get copyWith =>
      __$$AllusionImplCopyWithImpl<_$AllusionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AllusionImplToJson(
      this,
    );
  }
}

abstract class _Allusion implements Allusion {
  const factory _Allusion(
      {required final String sourceText,
      final String? sourceVerseText,
      required final String allusionText,
      required final String howToHearIt}) = _$AllusionImpl;

  factory _Allusion.fromJson(Map<String, dynamic> json) =
      _$AllusionImpl.fromJson;

  @override
  String get sourceText;
  @override
  String? get sourceVerseText;
  @override
  String get allusionText;
  @override
  String get howToHearIt;

  /// Create a copy of Allusion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AllusionImplCopyWith<_$AllusionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TextualNote _$TextualNoteFromJson(Map<String, dynamic> json) {
  return _TextualNote.fromJson(json);
}

/// @nodoc
mixin _$TextualNote {
  bool get include => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this TextualNote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TextualNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TextualNoteCopyWith<TextualNote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TextualNoteCopyWith<$Res> {
  factory $TextualNoteCopyWith(
          TextualNote value, $Res Function(TextualNote) then) =
      _$TextualNoteCopyWithImpl<$Res, TextualNote>;
  @useResult
  $Res call({bool include, String? notes});
}

/// @nodoc
class _$TextualNoteCopyWithImpl<$Res, $Val extends TextualNote>
    implements $TextualNoteCopyWith<$Res> {
  _$TextualNoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TextualNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? include = null,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      include: null == include
          ? _value.include
          : include // ignore: cast_nullable_to_non_nullable
              as bool,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TextualNoteImplCopyWith<$Res>
    implements $TextualNoteCopyWith<$Res> {
  factory _$$TextualNoteImplCopyWith(
          _$TextualNoteImpl value, $Res Function(_$TextualNoteImpl) then) =
      __$$TextualNoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool include, String? notes});
}

/// @nodoc
class __$$TextualNoteImplCopyWithImpl<$Res>
    extends _$TextualNoteCopyWithImpl<$Res, _$TextualNoteImpl>
    implements _$$TextualNoteImplCopyWith<$Res> {
  __$$TextualNoteImplCopyWithImpl(
      _$TextualNoteImpl _value, $Res Function(_$TextualNoteImpl) _then)
      : super(_value, _then);

  /// Create a copy of TextualNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? include = null,
    Object? notes = freezed,
  }) {
    return _then(_$TextualNoteImpl(
      include: null == include
          ? _value.include
          : include // ignore: cast_nullable_to_non_nullable
              as bool,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TextualNoteImpl implements _TextualNote {
  const _$TextualNoteImpl({this.include = false, this.notes});

  factory _$TextualNoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$TextualNoteImplFromJson(json);

  @override
  @JsonKey()
  final bool include;
  @override
  final String? notes;

  @override
  String toString() {
    return 'TextualNote(include: $include, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextualNoteImpl &&
            (identical(other.include, include) || other.include == include) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, include, notes);

  /// Create a copy of TextualNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TextualNoteImplCopyWith<_$TextualNoteImpl> get copyWith =>
      __$$TextualNoteImplCopyWithImpl<_$TextualNoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TextualNoteImplToJson(
      this,
    );
  }
}

abstract class _TextualNote implements TextualNote {
  const factory _TextualNote({final bool include, final String? notes}) =
      _$TextualNoteImpl;

  factory _TextualNote.fromJson(Map<String, dynamic> json) =
      _$TextualNoteImpl.fromJson;

  @override
  bool get include;
  @override
  String? get notes;

  /// Create a copy of TextualNote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TextualNoteImplCopyWith<_$TextualNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Misreading _$MisreadingFromJson(Map<String, dynamic> json) {
  return _Misreading.fromJson(json);
}

/// @nodoc
mixin _$Misreading {
  String get commonMisreading => throw _privateConstructorUsedError;
  String get whyItIsWrong => throw _privateConstructorUsedError;
  String get whatItActuallyMeans => throw _privateConstructorUsedError;

  /// Serializes this Misreading to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Misreading
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MisreadingCopyWith<Misreading> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MisreadingCopyWith<$Res> {
  factory $MisreadingCopyWith(
          Misreading value, $Res Function(Misreading) then) =
      _$MisreadingCopyWithImpl<$Res, Misreading>;
  @useResult
  $Res call(
      {String commonMisreading,
      String whyItIsWrong,
      String whatItActuallyMeans});
}

/// @nodoc
class _$MisreadingCopyWithImpl<$Res, $Val extends Misreading>
    implements $MisreadingCopyWith<$Res> {
  _$MisreadingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Misreading
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commonMisreading = null,
    Object? whyItIsWrong = null,
    Object? whatItActuallyMeans = null,
  }) {
    return _then(_value.copyWith(
      commonMisreading: null == commonMisreading
          ? _value.commonMisreading
          : commonMisreading // ignore: cast_nullable_to_non_nullable
              as String,
      whyItIsWrong: null == whyItIsWrong
          ? _value.whyItIsWrong
          : whyItIsWrong // ignore: cast_nullable_to_non_nullable
              as String,
      whatItActuallyMeans: null == whatItActuallyMeans
          ? _value.whatItActuallyMeans
          : whatItActuallyMeans // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MisreadingImplCopyWith<$Res>
    implements $MisreadingCopyWith<$Res> {
  factory _$$MisreadingImplCopyWith(
          _$MisreadingImpl value, $Res Function(_$MisreadingImpl) then) =
      __$$MisreadingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String commonMisreading,
      String whyItIsWrong,
      String whatItActuallyMeans});
}

/// @nodoc
class __$$MisreadingImplCopyWithImpl<$Res>
    extends _$MisreadingCopyWithImpl<$Res, _$MisreadingImpl>
    implements _$$MisreadingImplCopyWith<$Res> {
  __$$MisreadingImplCopyWithImpl(
      _$MisreadingImpl _value, $Res Function(_$MisreadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of Misreading
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commonMisreading = null,
    Object? whyItIsWrong = null,
    Object? whatItActuallyMeans = null,
  }) {
    return _then(_$MisreadingImpl(
      commonMisreading: null == commonMisreading
          ? _value.commonMisreading
          : commonMisreading // ignore: cast_nullable_to_non_nullable
              as String,
      whyItIsWrong: null == whyItIsWrong
          ? _value.whyItIsWrong
          : whyItIsWrong // ignore: cast_nullable_to_non_nullable
              as String,
      whatItActuallyMeans: null == whatItActuallyMeans
          ? _value.whatItActuallyMeans
          : whatItActuallyMeans // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MisreadingImpl implements _Misreading {
  const _$MisreadingImpl(
      {required this.commonMisreading,
      required this.whyItIsWrong,
      required this.whatItActuallyMeans});

  factory _$MisreadingImpl.fromJson(Map<String, dynamic> json) =>
      _$$MisreadingImplFromJson(json);

  @override
  final String commonMisreading;
  @override
  final String whyItIsWrong;
  @override
  final String whatItActuallyMeans;

  @override
  String toString() {
    return 'Misreading(commonMisreading: $commonMisreading, whyItIsWrong: $whyItIsWrong, whatItActuallyMeans: $whatItActuallyMeans)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MisreadingImpl &&
            (identical(other.commonMisreading, commonMisreading) ||
                other.commonMisreading == commonMisreading) &&
            (identical(other.whyItIsWrong, whyItIsWrong) ||
                other.whyItIsWrong == whyItIsWrong) &&
            (identical(other.whatItActuallyMeans, whatItActuallyMeans) ||
                other.whatItActuallyMeans == whatItActuallyMeans));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, commonMisreading, whyItIsWrong, whatItActuallyMeans);

  /// Create a copy of Misreading
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MisreadingImplCopyWith<_$MisreadingImpl> get copyWith =>
      __$$MisreadingImplCopyWithImpl<_$MisreadingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MisreadingImplToJson(
      this,
    );
  }
}

abstract class _Misreading implements Misreading {
  const factory _Misreading(
      {required final String commonMisreading,
      required final String whyItIsWrong,
      required final String whatItActuallyMeans}) = _$MisreadingImpl;

  factory _Misreading.fromJson(Map<String, dynamic> json) =
      _$MisreadingImpl.fromJson;

  @override
  String get commonMisreading;
  @override
  String get whyItIsWrong;
  @override
  String get whatItActuallyMeans;

  /// Create a copy of Misreading
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MisreadingImplCopyWith<_$MisreadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CulturalKey _$CulturalKeyFromJson(Map<String, dynamic> json) {
  return _CulturalKey.fromJson(json);
}

/// @nodoc
mixin _$CulturalKey {
  String get item => throw _privateConstructorUsedError;
  String get howItShapesReading => throw _privateConstructorUsedError;

  /// Serializes this CulturalKey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CulturalKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CulturalKeyCopyWith<CulturalKey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CulturalKeyCopyWith<$Res> {
  factory $CulturalKeyCopyWith(
          CulturalKey value, $Res Function(CulturalKey) then) =
      _$CulturalKeyCopyWithImpl<$Res, CulturalKey>;
  @useResult
  $Res call({String item, String howItShapesReading});
}

/// @nodoc
class _$CulturalKeyCopyWithImpl<$Res, $Val extends CulturalKey>
    implements $CulturalKeyCopyWith<$Res> {
  _$CulturalKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CulturalKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = null,
    Object? howItShapesReading = null,
  }) {
    return _then(_value.copyWith(
      item: null == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as String,
      howItShapesReading: null == howItShapesReading
          ? _value.howItShapesReading
          : howItShapesReading // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CulturalKeyImplCopyWith<$Res>
    implements $CulturalKeyCopyWith<$Res> {
  factory _$$CulturalKeyImplCopyWith(
          _$CulturalKeyImpl value, $Res Function(_$CulturalKeyImpl) then) =
      __$$CulturalKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String item, String howItShapesReading});
}

/// @nodoc
class __$$CulturalKeyImplCopyWithImpl<$Res>
    extends _$CulturalKeyCopyWithImpl<$Res, _$CulturalKeyImpl>
    implements _$$CulturalKeyImplCopyWith<$Res> {
  __$$CulturalKeyImplCopyWithImpl(
      _$CulturalKeyImpl _value, $Res Function(_$CulturalKeyImpl) _then)
      : super(_value, _then);

  /// Create a copy of CulturalKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = null,
    Object? howItShapesReading = null,
  }) {
    return _then(_$CulturalKeyImpl(
      item: null == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as String,
      howItShapesReading: null == howItShapesReading
          ? _value.howItShapesReading
          : howItShapesReading // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CulturalKeyImpl implements _CulturalKey {
  const _$CulturalKeyImpl(
      {required this.item, required this.howItShapesReading});

  factory _$CulturalKeyImpl.fromJson(Map<String, dynamic> json) =>
      _$$CulturalKeyImplFromJson(json);

  @override
  final String item;
  @override
  final String howItShapesReading;

  @override
  String toString() {
    return 'CulturalKey(item: $item, howItShapesReading: $howItShapesReading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CulturalKeyImpl &&
            (identical(other.item, item) || other.item == item) &&
            (identical(other.howItShapesReading, howItShapesReading) ||
                other.howItShapesReading == howItShapesReading));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, item, howItShapesReading);

  /// Create a copy of CulturalKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CulturalKeyImplCopyWith<_$CulturalKeyImpl> get copyWith =>
      __$$CulturalKeyImplCopyWithImpl<_$CulturalKeyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CulturalKeyImplToJson(
      this,
    );
  }
}

abstract class _CulturalKey implements CulturalKey {
  const factory _CulturalKey(
      {required final String item,
      required final String howItShapesReading}) = _$CulturalKeyImpl;

  factory _CulturalKey.fromJson(Map<String, dynamic> json) =
      _$CulturalKeyImpl.fromJson;

  @override
  String get item;
  @override
  String get howItShapesReading;

  /// Create a copy of CulturalKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CulturalKeyImplCopyWith<_$CulturalKeyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HistoricalCulturalSetting _$HistoricalCulturalSettingFromJson(
    Map<String, dynamic> json) {
  return _HistoricalCulturalSetting.fromJson(json);
}

/// @nodoc
mixin _$HistoricalCulturalSetting {
  String get world => throw _privateConstructorUsedError;
  List<CulturalKey> get specificCulturalKeys =>
      throw _privateConstructorUsedError;

  /// Serializes this HistoricalCulturalSetting to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HistoricalCulturalSetting
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HistoricalCulturalSettingCopyWith<HistoricalCulturalSetting> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HistoricalCulturalSettingCopyWith<$Res> {
  factory $HistoricalCulturalSettingCopyWith(HistoricalCulturalSetting value,
          $Res Function(HistoricalCulturalSetting) then) =
      _$HistoricalCulturalSettingCopyWithImpl<$Res, HistoricalCulturalSetting>;
  @useResult
  $Res call({String world, List<CulturalKey> specificCulturalKeys});
}

/// @nodoc
class _$HistoricalCulturalSettingCopyWithImpl<$Res,
        $Val extends HistoricalCulturalSetting>
    implements $HistoricalCulturalSettingCopyWith<$Res> {
  _$HistoricalCulturalSettingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HistoricalCulturalSetting
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? world = null,
    Object? specificCulturalKeys = null,
  }) {
    return _then(_value.copyWith(
      world: null == world
          ? _value.world
          : world // ignore: cast_nullable_to_non_nullable
              as String,
      specificCulturalKeys: null == specificCulturalKeys
          ? _value.specificCulturalKeys
          : specificCulturalKeys // ignore: cast_nullable_to_non_nullable
              as List<CulturalKey>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HistoricalCulturalSettingImplCopyWith<$Res>
    implements $HistoricalCulturalSettingCopyWith<$Res> {
  factory _$$HistoricalCulturalSettingImplCopyWith(
          _$HistoricalCulturalSettingImpl value,
          $Res Function(_$HistoricalCulturalSettingImpl) then) =
      __$$HistoricalCulturalSettingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String world, List<CulturalKey> specificCulturalKeys});
}

/// @nodoc
class __$$HistoricalCulturalSettingImplCopyWithImpl<$Res>
    extends _$HistoricalCulturalSettingCopyWithImpl<$Res,
        _$HistoricalCulturalSettingImpl>
    implements _$$HistoricalCulturalSettingImplCopyWith<$Res> {
  __$$HistoricalCulturalSettingImplCopyWithImpl(
      _$HistoricalCulturalSettingImpl _value,
      $Res Function(_$HistoricalCulturalSettingImpl) _then)
      : super(_value, _then);

  /// Create a copy of HistoricalCulturalSetting
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? world = null,
    Object? specificCulturalKeys = null,
  }) {
    return _then(_$HistoricalCulturalSettingImpl(
      world: null == world
          ? _value.world
          : world // ignore: cast_nullable_to_non_nullable
              as String,
      specificCulturalKeys: null == specificCulturalKeys
          ? _value._specificCulturalKeys
          : specificCulturalKeys // ignore: cast_nullable_to_non_nullable
              as List<CulturalKey>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HistoricalCulturalSettingImpl implements _HistoricalCulturalSetting {
  const _$HistoricalCulturalSettingImpl(
      {required this.world,
      final List<CulturalKey> specificCulturalKeys = const []})
      : _specificCulturalKeys = specificCulturalKeys;

  factory _$HistoricalCulturalSettingImpl.fromJson(Map<String, dynamic> json) =>
      _$$HistoricalCulturalSettingImplFromJson(json);

  @override
  final String world;
  final List<CulturalKey> _specificCulturalKeys;
  @override
  @JsonKey()
  List<CulturalKey> get specificCulturalKeys {
    if (_specificCulturalKeys is EqualUnmodifiableListView)
      return _specificCulturalKeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_specificCulturalKeys);
  }

  @override
  String toString() {
    return 'HistoricalCulturalSetting(world: $world, specificCulturalKeys: $specificCulturalKeys)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoricalCulturalSettingImpl &&
            (identical(other.world, world) || other.world == world) &&
            const DeepCollectionEquality()
                .equals(other._specificCulturalKeys, _specificCulturalKeys));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, world,
      const DeepCollectionEquality().hash(_specificCulturalKeys));

  /// Create a copy of HistoricalCulturalSetting
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoricalCulturalSettingImplCopyWith<_$HistoricalCulturalSettingImpl>
      get copyWith => __$$HistoricalCulturalSettingImplCopyWithImpl<
          _$HistoricalCulturalSettingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HistoricalCulturalSettingImplToJson(
      this,
    );
  }
}

abstract class _HistoricalCulturalSetting implements HistoricalCulturalSetting {
  const factory _HistoricalCulturalSetting(
          {required final String world,
          final List<CulturalKey> specificCulturalKeys}) =
      _$HistoricalCulturalSettingImpl;

  factory _HistoricalCulturalSetting.fromJson(Map<String, dynamic> json) =
      _$HistoricalCulturalSettingImpl.fromJson;

  @override
  String get world;
  @override
  List<CulturalKey> get specificCulturalKeys;

  /// Create a copy of HistoricalCulturalSetting
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoricalCulturalSettingImplCopyWith<_$HistoricalCulturalSettingImpl>
      get copyWith => throw _privateConstructorUsedError;
}

LiteraryContext _$LiteraryContextFromJson(Map<String, dynamic> json) {
  return _LiteraryContext.fromJson(json);
}

/// @nodoc
mixin _$LiteraryContext {
  String get genre => throw _privateConstructorUsedError;
  String get immediateBefore => throw _privateConstructorUsedError;
  String get immediateAfter => throw _privateConstructorUsedError;
  String get structuralRole => throw _privateConstructorUsedError;
  String get passageFlow => throw _privateConstructorUsedError;

  /// Serializes this LiteraryContext to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LiteraryContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiteraryContextCopyWith<LiteraryContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiteraryContextCopyWith<$Res> {
  factory $LiteraryContextCopyWith(
          LiteraryContext value, $Res Function(LiteraryContext) then) =
      _$LiteraryContextCopyWithImpl<$Res, LiteraryContext>;
  @useResult
  $Res call(
      {String genre,
      String immediateBefore,
      String immediateAfter,
      String structuralRole,
      String passageFlow});
}

/// @nodoc
class _$LiteraryContextCopyWithImpl<$Res, $Val extends LiteraryContext>
    implements $LiteraryContextCopyWith<$Res> {
  _$LiteraryContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiteraryContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? genre = null,
    Object? immediateBefore = null,
    Object? immediateAfter = null,
    Object? structuralRole = null,
    Object? passageFlow = null,
  }) {
    return _then(_value.copyWith(
      genre: null == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as String,
      immediateBefore: null == immediateBefore
          ? _value.immediateBefore
          : immediateBefore // ignore: cast_nullable_to_non_nullable
              as String,
      immediateAfter: null == immediateAfter
          ? _value.immediateAfter
          : immediateAfter // ignore: cast_nullable_to_non_nullable
              as String,
      structuralRole: null == structuralRole
          ? _value.structuralRole
          : structuralRole // ignore: cast_nullable_to_non_nullable
              as String,
      passageFlow: null == passageFlow
          ? _value.passageFlow
          : passageFlow // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LiteraryContextImplCopyWith<$Res>
    implements $LiteraryContextCopyWith<$Res> {
  factory _$$LiteraryContextImplCopyWith(_$LiteraryContextImpl value,
          $Res Function(_$LiteraryContextImpl) then) =
      __$$LiteraryContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String genre,
      String immediateBefore,
      String immediateAfter,
      String structuralRole,
      String passageFlow});
}

/// @nodoc
class __$$LiteraryContextImplCopyWithImpl<$Res>
    extends _$LiteraryContextCopyWithImpl<$Res, _$LiteraryContextImpl>
    implements _$$LiteraryContextImplCopyWith<$Res> {
  __$$LiteraryContextImplCopyWithImpl(
      _$LiteraryContextImpl _value, $Res Function(_$LiteraryContextImpl) _then)
      : super(_value, _then);

  /// Create a copy of LiteraryContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? genre = null,
    Object? immediateBefore = null,
    Object? immediateAfter = null,
    Object? structuralRole = null,
    Object? passageFlow = null,
  }) {
    return _then(_$LiteraryContextImpl(
      genre: null == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as String,
      immediateBefore: null == immediateBefore
          ? _value.immediateBefore
          : immediateBefore // ignore: cast_nullable_to_non_nullable
              as String,
      immediateAfter: null == immediateAfter
          ? _value.immediateAfter
          : immediateAfter // ignore: cast_nullable_to_non_nullable
              as String,
      structuralRole: null == structuralRole
          ? _value.structuralRole
          : structuralRole // ignore: cast_nullable_to_non_nullable
              as String,
      passageFlow: null == passageFlow
          ? _value.passageFlow
          : passageFlow // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LiteraryContextImpl implements _LiteraryContext {
  const _$LiteraryContextImpl(
      {required this.genre,
      required this.immediateBefore,
      required this.immediateAfter,
      required this.structuralRole,
      required this.passageFlow});

  factory _$LiteraryContextImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiteraryContextImplFromJson(json);

  @override
  final String genre;
  @override
  final String immediateBefore;
  @override
  final String immediateAfter;
  @override
  final String structuralRole;
  @override
  final String passageFlow;

  @override
  String toString() {
    return 'LiteraryContext(genre: $genre, immediateBefore: $immediateBefore, immediateAfter: $immediateAfter, structuralRole: $structuralRole, passageFlow: $passageFlow)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiteraryContextImpl &&
            (identical(other.genre, genre) || other.genre == genre) &&
            (identical(other.immediateBefore, immediateBefore) ||
                other.immediateBefore == immediateBefore) &&
            (identical(other.immediateAfter, immediateAfter) ||
                other.immediateAfter == immediateAfter) &&
            (identical(other.structuralRole, structuralRole) ||
                other.structuralRole == structuralRole) &&
            (identical(other.passageFlow, passageFlow) ||
                other.passageFlow == passageFlow));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, genre, immediateBefore,
      immediateAfter, structuralRole, passageFlow);

  /// Create a copy of LiteraryContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiteraryContextImplCopyWith<_$LiteraryContextImpl> get copyWith =>
      __$$LiteraryContextImplCopyWithImpl<_$LiteraryContextImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LiteraryContextImplToJson(
      this,
    );
  }
}

abstract class _LiteraryContext implements LiteraryContext {
  const factory _LiteraryContext(
      {required final String genre,
      required final String immediateBefore,
      required final String immediateAfter,
      required final String structuralRole,
      required final String passageFlow}) = _$LiteraryContextImpl;

  factory _LiteraryContext.fromJson(Map<String, dynamic> json) =
      _$LiteraryContextImpl.fromJson;

  @override
  String get genre;
  @override
  String get immediateBefore;
  @override
  String get immediateAfter;
  @override
  String get structuralRole;
  @override
  String get passageFlow;

  /// Create a copy of LiteraryContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiteraryContextImplCopyWith<_$LiteraryContextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LanguageWord _$LanguageWordFromJson(Map<String, dynamic> json) {
  return _LanguageWord.fromJson(json);
}

/// @nodoc
mixin _$LanguageWord {
  String get word => throw _privateConstructorUsedError;
  String get originalScript => throw _privateConstructorUsedError;
  String get transliteration => throw _privateConstructorUsedError;
  String get strongsNumber => throw _privateConstructorUsedError;
  String get fullSemanticRange => throw _privateConstructorUsedError;

  /// Serializes this LanguageWord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LanguageWord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LanguageWordCopyWith<LanguageWord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LanguageWordCopyWith<$Res> {
  factory $LanguageWordCopyWith(
          LanguageWord value, $Res Function(LanguageWord) then) =
      _$LanguageWordCopyWithImpl<$Res, LanguageWord>;
  @useResult
  $Res call(
      {String word,
      String originalScript,
      String transliteration,
      String strongsNumber,
      String fullSemanticRange});
}

/// @nodoc
class _$LanguageWordCopyWithImpl<$Res, $Val extends LanguageWord>
    implements $LanguageWordCopyWith<$Res> {
  _$LanguageWordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LanguageWord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? originalScript = null,
    Object? transliteration = null,
    Object? strongsNumber = null,
    Object? fullSemanticRange = null,
  }) {
    return _then(_value.copyWith(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      originalScript: null == originalScript
          ? _value.originalScript
          : originalScript // ignore: cast_nullable_to_non_nullable
              as String,
      transliteration: null == transliteration
          ? _value.transliteration
          : transliteration // ignore: cast_nullable_to_non_nullable
              as String,
      strongsNumber: null == strongsNumber
          ? _value.strongsNumber
          : strongsNumber // ignore: cast_nullable_to_non_nullable
              as String,
      fullSemanticRange: null == fullSemanticRange
          ? _value.fullSemanticRange
          : fullSemanticRange // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LanguageWordImplCopyWith<$Res>
    implements $LanguageWordCopyWith<$Res> {
  factory _$$LanguageWordImplCopyWith(
          _$LanguageWordImpl value, $Res Function(_$LanguageWordImpl) then) =
      __$$LanguageWordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String word,
      String originalScript,
      String transliteration,
      String strongsNumber,
      String fullSemanticRange});
}

/// @nodoc
class __$$LanguageWordImplCopyWithImpl<$Res>
    extends _$LanguageWordCopyWithImpl<$Res, _$LanguageWordImpl>
    implements _$$LanguageWordImplCopyWith<$Res> {
  __$$LanguageWordImplCopyWithImpl(
      _$LanguageWordImpl _value, $Res Function(_$LanguageWordImpl) _then)
      : super(_value, _then);

  /// Create a copy of LanguageWord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? originalScript = null,
    Object? transliteration = null,
    Object? strongsNumber = null,
    Object? fullSemanticRange = null,
  }) {
    return _then(_$LanguageWordImpl(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      originalScript: null == originalScript
          ? _value.originalScript
          : originalScript // ignore: cast_nullable_to_non_nullable
              as String,
      transliteration: null == transliteration
          ? _value.transliteration
          : transliteration // ignore: cast_nullable_to_non_nullable
              as String,
      strongsNumber: null == strongsNumber
          ? _value.strongsNumber
          : strongsNumber // ignore: cast_nullable_to_non_nullable
              as String,
      fullSemanticRange: null == fullSemanticRange
          ? _value.fullSemanticRange
          : fullSemanticRange // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LanguageWordImpl implements _LanguageWord {
  const _$LanguageWordImpl(
      {required this.word,
      required this.originalScript,
      required this.transliteration,
      required this.strongsNumber,
      required this.fullSemanticRange});

  factory _$LanguageWordImpl.fromJson(Map<String, dynamic> json) =>
      _$$LanguageWordImplFromJson(json);

  @override
  final String word;
  @override
  final String originalScript;
  @override
  final String transliteration;
  @override
  final String strongsNumber;
  @override
  final String fullSemanticRange;

  @override
  String toString() {
    return 'LanguageWord(word: $word, originalScript: $originalScript, transliteration: $transliteration, strongsNumber: $strongsNumber, fullSemanticRange: $fullSemanticRange)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LanguageWordImpl &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.originalScript, originalScript) ||
                other.originalScript == originalScript) &&
            (identical(other.transliteration, transliteration) ||
                other.transliteration == transliteration) &&
            (identical(other.strongsNumber, strongsNumber) ||
                other.strongsNumber == strongsNumber) &&
            (identical(other.fullSemanticRange, fullSemanticRange) ||
                other.fullSemanticRange == fullSemanticRange));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, word, originalScript,
      transliteration, strongsNumber, fullSemanticRange);

  /// Create a copy of LanguageWord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LanguageWordImplCopyWith<_$LanguageWordImpl> get copyWith =>
      __$$LanguageWordImplCopyWithImpl<_$LanguageWordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LanguageWordImplToJson(
      this,
    );
  }
}

abstract class _LanguageWord implements LanguageWord {
  const factory _LanguageWord(
      {required final String word,
      required final String originalScript,
      required final String transliteration,
      required final String strongsNumber,
      required final String fullSemanticRange}) = _$LanguageWordImpl;

  factory _LanguageWord.fromJson(Map<String, dynamic> json) =
      _$LanguageWordImpl.fromJson;

  @override
  String get word;
  @override
  String get originalScript;
  @override
  String get transliteration;
  @override
  String get strongsNumber;
  @override
  String get fullSemanticRange;

  /// Create a copy of LanguageWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LanguageWordImplCopyWith<_$LanguageWordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConceptDefinition _$ConceptDefinitionFromJson(Map<String, dynamic> json) {
  return _ConceptDefinition.fromJson(json);
}

/// @nodoc
mixin _$ConceptDefinition {
  LanguageWord get hebrewWord => throw _privateConstructorUsedError;
  LanguageWord get greekWord => throw _privateConstructorUsedError;
  String get semanticDisambiguation => throw _privateConstructorUsedError;
  String get modernVsAncient => throw _privateConstructorUsedError;

  /// Serializes this ConceptDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConceptDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConceptDefinitionCopyWith<ConceptDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConceptDefinitionCopyWith<$Res> {
  factory $ConceptDefinitionCopyWith(
          ConceptDefinition value, $Res Function(ConceptDefinition) then) =
      _$ConceptDefinitionCopyWithImpl<$Res, ConceptDefinition>;
  @useResult
  $Res call(
      {LanguageWord hebrewWord,
      LanguageWord greekWord,
      String semanticDisambiguation,
      String modernVsAncient});

  $LanguageWordCopyWith<$Res> get hebrewWord;
  $LanguageWordCopyWith<$Res> get greekWord;
}

/// @nodoc
class _$ConceptDefinitionCopyWithImpl<$Res, $Val extends ConceptDefinition>
    implements $ConceptDefinitionCopyWith<$Res> {
  _$ConceptDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConceptDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hebrewWord = null,
    Object? greekWord = null,
    Object? semanticDisambiguation = null,
    Object? modernVsAncient = null,
  }) {
    return _then(_value.copyWith(
      hebrewWord: null == hebrewWord
          ? _value.hebrewWord
          : hebrewWord // ignore: cast_nullable_to_non_nullable
              as LanguageWord,
      greekWord: null == greekWord
          ? _value.greekWord
          : greekWord // ignore: cast_nullable_to_non_nullable
              as LanguageWord,
      semanticDisambiguation: null == semanticDisambiguation
          ? _value.semanticDisambiguation
          : semanticDisambiguation // ignore: cast_nullable_to_non_nullable
              as String,
      modernVsAncient: null == modernVsAncient
          ? _value.modernVsAncient
          : modernVsAncient // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of ConceptDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LanguageWordCopyWith<$Res> get hebrewWord {
    return $LanguageWordCopyWith<$Res>(_value.hebrewWord, (value) {
      return _then(_value.copyWith(hebrewWord: value) as $Val);
    });
  }

  /// Create a copy of ConceptDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LanguageWordCopyWith<$Res> get greekWord {
    return $LanguageWordCopyWith<$Res>(_value.greekWord, (value) {
      return _then(_value.copyWith(greekWord: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConceptDefinitionImplCopyWith<$Res>
    implements $ConceptDefinitionCopyWith<$Res> {
  factory _$$ConceptDefinitionImplCopyWith(_$ConceptDefinitionImpl value,
          $Res Function(_$ConceptDefinitionImpl) then) =
      __$$ConceptDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {LanguageWord hebrewWord,
      LanguageWord greekWord,
      String semanticDisambiguation,
      String modernVsAncient});

  @override
  $LanguageWordCopyWith<$Res> get hebrewWord;
  @override
  $LanguageWordCopyWith<$Res> get greekWord;
}

/// @nodoc
class __$$ConceptDefinitionImplCopyWithImpl<$Res>
    extends _$ConceptDefinitionCopyWithImpl<$Res, _$ConceptDefinitionImpl>
    implements _$$ConceptDefinitionImplCopyWith<$Res> {
  __$$ConceptDefinitionImplCopyWithImpl(_$ConceptDefinitionImpl _value,
      $Res Function(_$ConceptDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConceptDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hebrewWord = null,
    Object? greekWord = null,
    Object? semanticDisambiguation = null,
    Object? modernVsAncient = null,
  }) {
    return _then(_$ConceptDefinitionImpl(
      hebrewWord: null == hebrewWord
          ? _value.hebrewWord
          : hebrewWord // ignore: cast_nullable_to_non_nullable
              as LanguageWord,
      greekWord: null == greekWord
          ? _value.greekWord
          : greekWord // ignore: cast_nullable_to_non_nullable
              as LanguageWord,
      semanticDisambiguation: null == semanticDisambiguation
          ? _value.semanticDisambiguation
          : semanticDisambiguation // ignore: cast_nullable_to_non_nullable
              as String,
      modernVsAncient: null == modernVsAncient
          ? _value.modernVsAncient
          : modernVsAncient // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConceptDefinitionImpl implements _ConceptDefinition {
  const _$ConceptDefinitionImpl(
      {required this.hebrewWord,
      required this.greekWord,
      required this.semanticDisambiguation,
      required this.modernVsAncient});

  factory _$ConceptDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConceptDefinitionImplFromJson(json);

  @override
  final LanguageWord hebrewWord;
  @override
  final LanguageWord greekWord;
  @override
  final String semanticDisambiguation;
  @override
  final String modernVsAncient;

  @override
  String toString() {
    return 'ConceptDefinition(hebrewWord: $hebrewWord, greekWord: $greekWord, semanticDisambiguation: $semanticDisambiguation, modernVsAncient: $modernVsAncient)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConceptDefinitionImpl &&
            (identical(other.hebrewWord, hebrewWord) ||
                other.hebrewWord == hebrewWord) &&
            (identical(other.greekWord, greekWord) ||
                other.greekWord == greekWord) &&
            (identical(other.semanticDisambiguation, semanticDisambiguation) ||
                other.semanticDisambiguation == semanticDisambiguation) &&
            (identical(other.modernVsAncient, modernVsAncient) ||
                other.modernVsAncient == modernVsAncient));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, hebrewWord, greekWord,
      semanticDisambiguation, modernVsAncient);

  /// Create a copy of ConceptDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConceptDefinitionImplCopyWith<_$ConceptDefinitionImpl> get copyWith =>
      __$$ConceptDefinitionImplCopyWithImpl<_$ConceptDefinitionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConceptDefinitionImplToJson(
      this,
    );
  }
}

abstract class _ConceptDefinition implements ConceptDefinition {
  const factory _ConceptDefinition(
      {required final LanguageWord hebrewWord,
      required final LanguageWord greekWord,
      required final String semanticDisambiguation,
      required final String modernVsAncient}) = _$ConceptDefinitionImpl;

  factory _ConceptDefinition.fromJson(Map<String, dynamic> json) =
      _$ConceptDefinitionImpl.fromJson;

  @override
  LanguageWord get hebrewWord;
  @override
  LanguageWord get greekWord;
  @override
  String get semanticDisambiguation;
  @override
  String get modernVsAncient;

  /// Create a copy of ConceptDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConceptDefinitionImplCopyWith<_$ConceptDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TopicFirstMention _$TopicFirstMentionFromJson(Map<String, dynamic> json) {
  return _TopicFirstMention.fromJson(json);
}

/// @nodoc
mixin _$TopicFirstMention {
  String get reference => throw _privateConstructorUsedError;
  String? get verseText => throw _privateConstructorUsedError;
  String get whatItEstablishes => throw _privateConstructorUsedError;

  /// Serializes this TopicFirstMention to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopicFirstMention
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopicFirstMentionCopyWith<TopicFirstMention> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopicFirstMentionCopyWith<$Res> {
  factory $TopicFirstMentionCopyWith(
          TopicFirstMention value, $Res Function(TopicFirstMention) then) =
      _$TopicFirstMentionCopyWithImpl<$Res, TopicFirstMention>;
  @useResult
  $Res call({String reference, String? verseText, String whatItEstablishes});
}

/// @nodoc
class _$TopicFirstMentionCopyWithImpl<$Res, $Val extends TopicFirstMention>
    implements $TopicFirstMentionCopyWith<$Res> {
  _$TopicFirstMentionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopicFirstMention
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? verseText = freezed,
    Object? whatItEstablishes = null,
  }) {
    return _then(_value.copyWith(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      verseText: freezed == verseText
          ? _value.verseText
          : verseText // ignore: cast_nullable_to_non_nullable
              as String?,
      whatItEstablishes: null == whatItEstablishes
          ? _value.whatItEstablishes
          : whatItEstablishes // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TopicFirstMentionImplCopyWith<$Res>
    implements $TopicFirstMentionCopyWith<$Res> {
  factory _$$TopicFirstMentionImplCopyWith(_$TopicFirstMentionImpl value,
          $Res Function(_$TopicFirstMentionImpl) then) =
      __$$TopicFirstMentionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reference, String? verseText, String whatItEstablishes});
}

/// @nodoc
class __$$TopicFirstMentionImplCopyWithImpl<$Res>
    extends _$TopicFirstMentionCopyWithImpl<$Res, _$TopicFirstMentionImpl>
    implements _$$TopicFirstMentionImplCopyWith<$Res> {
  __$$TopicFirstMentionImplCopyWithImpl(_$TopicFirstMentionImpl _value,
      $Res Function(_$TopicFirstMentionImpl) _then)
      : super(_value, _then);

  /// Create a copy of TopicFirstMention
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? verseText = freezed,
    Object? whatItEstablishes = null,
  }) {
    return _then(_$TopicFirstMentionImpl(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      verseText: freezed == verseText
          ? _value.verseText
          : verseText // ignore: cast_nullable_to_non_nullable
              as String?,
      whatItEstablishes: null == whatItEstablishes
          ? _value.whatItEstablishes
          : whatItEstablishes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TopicFirstMentionImpl implements _TopicFirstMention {
  const _$TopicFirstMentionImpl(
      {required this.reference,
      this.verseText,
      required this.whatItEstablishes});

  factory _$TopicFirstMentionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopicFirstMentionImplFromJson(json);

  @override
  final String reference;
  @override
  final String? verseText;
  @override
  final String whatItEstablishes;

  @override
  String toString() {
    return 'TopicFirstMention(reference: $reference, verseText: $verseText, whatItEstablishes: $whatItEstablishes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopicFirstMentionImpl &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.verseText, verseText) ||
                other.verseText == verseText) &&
            (identical(other.whatItEstablishes, whatItEstablishes) ||
                other.whatItEstablishes == whatItEstablishes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, reference, verseText, whatItEstablishes);

  /// Create a copy of TopicFirstMention
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopicFirstMentionImplCopyWith<_$TopicFirstMentionImpl> get copyWith =>
      __$$TopicFirstMentionImplCopyWithImpl<_$TopicFirstMentionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopicFirstMentionImplToJson(
      this,
    );
  }
}

abstract class _TopicFirstMention implements TopicFirstMention {
  const factory _TopicFirstMention(
      {required final String reference,
      final String? verseText,
      required final String whatItEstablishes}) = _$TopicFirstMentionImpl;

  factory _TopicFirstMention.fromJson(Map<String, dynamic> json) =
      _$TopicFirstMentionImpl.fromJson;

  @override
  String get reference;
  @override
  String? get verseText;
  @override
  String get whatItEstablishes;

  /// Create a copy of TopicFirstMention
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopicFirstMentionImplCopyWith<_$TopicFirstMentionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DefiningPassage _$DefiningPassageFromJson(Map<String, dynamic> json) {
  return _DefiningPassage.fromJson(json);
}

/// @nodoc
mixin _$DefiningPassage {
  String get reference => throw _privateConstructorUsedError;
  String? get verseText => throw _privateConstructorUsedError;
  String get whyDefinitive => throw _privateConstructorUsedError;
  String get historicalCulturalContext => throw _privateConstructorUsedError;
  List<WordStudyItem> get wordStudy => throw _privateConstructorUsedError;
  String? get morphologicalNote => throw _privateConstructorUsedError;
  String get whatThisPassageSays => throw _privateConstructorUsedError;
  String? get connectionsToOtherDefiningPassages =>
      throw _privateConstructorUsedError;

  /// Serializes this DefiningPassage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DefiningPassage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DefiningPassageCopyWith<DefiningPassage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DefiningPassageCopyWith<$Res> {
  factory $DefiningPassageCopyWith(
          DefiningPassage value, $Res Function(DefiningPassage) then) =
      _$DefiningPassageCopyWithImpl<$Res, DefiningPassage>;
  @useResult
  $Res call(
      {String reference,
      String? verseText,
      String whyDefinitive,
      String historicalCulturalContext,
      List<WordStudyItem> wordStudy,
      String? morphologicalNote,
      String whatThisPassageSays,
      String? connectionsToOtherDefiningPassages});
}

/// @nodoc
class _$DefiningPassageCopyWithImpl<$Res, $Val extends DefiningPassage>
    implements $DefiningPassageCopyWith<$Res> {
  _$DefiningPassageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DefiningPassage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? verseText = freezed,
    Object? whyDefinitive = null,
    Object? historicalCulturalContext = null,
    Object? wordStudy = null,
    Object? morphologicalNote = freezed,
    Object? whatThisPassageSays = null,
    Object? connectionsToOtherDefiningPassages = freezed,
  }) {
    return _then(_value.copyWith(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      verseText: freezed == verseText
          ? _value.verseText
          : verseText // ignore: cast_nullable_to_non_nullable
              as String?,
      whyDefinitive: null == whyDefinitive
          ? _value.whyDefinitive
          : whyDefinitive // ignore: cast_nullable_to_non_nullable
              as String,
      historicalCulturalContext: null == historicalCulturalContext
          ? _value.historicalCulturalContext
          : historicalCulturalContext // ignore: cast_nullable_to_non_nullable
              as String,
      wordStudy: null == wordStudy
          ? _value.wordStudy
          : wordStudy // ignore: cast_nullable_to_non_nullable
              as List<WordStudyItem>,
      morphologicalNote: freezed == morphologicalNote
          ? _value.morphologicalNote
          : morphologicalNote // ignore: cast_nullable_to_non_nullable
              as String?,
      whatThisPassageSays: null == whatThisPassageSays
          ? _value.whatThisPassageSays
          : whatThisPassageSays // ignore: cast_nullable_to_non_nullable
              as String,
      connectionsToOtherDefiningPassages: freezed ==
              connectionsToOtherDefiningPassages
          ? _value.connectionsToOtherDefiningPassages
          : connectionsToOtherDefiningPassages // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DefiningPassageImplCopyWith<$Res>
    implements $DefiningPassageCopyWith<$Res> {
  factory _$$DefiningPassageImplCopyWith(_$DefiningPassageImpl value,
          $Res Function(_$DefiningPassageImpl) then) =
      __$$DefiningPassageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String reference,
      String? verseText,
      String whyDefinitive,
      String historicalCulturalContext,
      List<WordStudyItem> wordStudy,
      String? morphologicalNote,
      String whatThisPassageSays,
      String? connectionsToOtherDefiningPassages});
}

/// @nodoc
class __$$DefiningPassageImplCopyWithImpl<$Res>
    extends _$DefiningPassageCopyWithImpl<$Res, _$DefiningPassageImpl>
    implements _$$DefiningPassageImplCopyWith<$Res> {
  __$$DefiningPassageImplCopyWithImpl(
      _$DefiningPassageImpl _value, $Res Function(_$DefiningPassageImpl) _then)
      : super(_value, _then);

  /// Create a copy of DefiningPassage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reference = null,
    Object? verseText = freezed,
    Object? whyDefinitive = null,
    Object? historicalCulturalContext = null,
    Object? wordStudy = null,
    Object? morphologicalNote = freezed,
    Object? whatThisPassageSays = null,
    Object? connectionsToOtherDefiningPassages = freezed,
  }) {
    return _then(_$DefiningPassageImpl(
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      verseText: freezed == verseText
          ? _value.verseText
          : verseText // ignore: cast_nullable_to_non_nullable
              as String?,
      whyDefinitive: null == whyDefinitive
          ? _value.whyDefinitive
          : whyDefinitive // ignore: cast_nullable_to_non_nullable
              as String,
      historicalCulturalContext: null == historicalCulturalContext
          ? _value.historicalCulturalContext
          : historicalCulturalContext // ignore: cast_nullable_to_non_nullable
              as String,
      wordStudy: null == wordStudy
          ? _value._wordStudy
          : wordStudy // ignore: cast_nullable_to_non_nullable
              as List<WordStudyItem>,
      morphologicalNote: freezed == morphologicalNote
          ? _value.morphologicalNote
          : morphologicalNote // ignore: cast_nullable_to_non_nullable
              as String?,
      whatThisPassageSays: null == whatThisPassageSays
          ? _value.whatThisPassageSays
          : whatThisPassageSays // ignore: cast_nullable_to_non_nullable
              as String,
      connectionsToOtherDefiningPassages: freezed ==
              connectionsToOtherDefiningPassages
          ? _value.connectionsToOtherDefiningPassages
          : connectionsToOtherDefiningPassages // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DefiningPassageImpl implements _DefiningPassage {
  const _$DefiningPassageImpl(
      {required this.reference,
      this.verseText,
      required this.whyDefinitive,
      required this.historicalCulturalContext,
      final List<WordStudyItem> wordStudy = const [],
      this.morphologicalNote,
      required this.whatThisPassageSays,
      this.connectionsToOtherDefiningPassages})
      : _wordStudy = wordStudy;

  factory _$DefiningPassageImpl.fromJson(Map<String, dynamic> json) =>
      _$$DefiningPassageImplFromJson(json);

  @override
  final String reference;
  @override
  final String? verseText;
  @override
  final String whyDefinitive;
  @override
  final String historicalCulturalContext;
  final List<WordStudyItem> _wordStudy;
  @override
  @JsonKey()
  List<WordStudyItem> get wordStudy {
    if (_wordStudy is EqualUnmodifiableListView) return _wordStudy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wordStudy);
  }

  @override
  final String? morphologicalNote;
  @override
  final String whatThisPassageSays;
  @override
  final String? connectionsToOtherDefiningPassages;

  @override
  String toString() {
    return 'DefiningPassage(reference: $reference, verseText: $verseText, whyDefinitive: $whyDefinitive, historicalCulturalContext: $historicalCulturalContext, wordStudy: $wordStudy, morphologicalNote: $morphologicalNote, whatThisPassageSays: $whatThisPassageSays, connectionsToOtherDefiningPassages: $connectionsToOtherDefiningPassages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DefiningPassageImpl &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.verseText, verseText) ||
                other.verseText == verseText) &&
            (identical(other.whyDefinitive, whyDefinitive) ||
                other.whyDefinitive == whyDefinitive) &&
            (identical(other.historicalCulturalContext,
                    historicalCulturalContext) ||
                other.historicalCulturalContext == historicalCulturalContext) &&
            const DeepCollectionEquality()
                .equals(other._wordStudy, _wordStudy) &&
            (identical(other.morphologicalNote, morphologicalNote) ||
                other.morphologicalNote == morphologicalNote) &&
            (identical(other.whatThisPassageSays, whatThisPassageSays) ||
                other.whatThisPassageSays == whatThisPassageSays) &&
            (identical(other.connectionsToOtherDefiningPassages,
                    connectionsToOtherDefiningPassages) ||
                other.connectionsToOtherDefiningPassages ==
                    connectionsToOtherDefiningPassages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      reference,
      verseText,
      whyDefinitive,
      historicalCulturalContext,
      const DeepCollectionEquality().hash(_wordStudy),
      morphologicalNote,
      whatThisPassageSays,
      connectionsToOtherDefiningPassages);

  /// Create a copy of DefiningPassage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DefiningPassageImplCopyWith<_$DefiningPassageImpl> get copyWith =>
      __$$DefiningPassageImplCopyWithImpl<_$DefiningPassageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DefiningPassageImplToJson(
      this,
    );
  }
}

abstract class _DefiningPassage implements DefiningPassage {
  const factory _DefiningPassage(
          {required final String reference,
          final String? verseText,
          required final String whyDefinitive,
          required final String historicalCulturalContext,
          final List<WordStudyItem> wordStudy,
          final String? morphologicalNote,
          required final String whatThisPassageSays,
          final String? connectionsToOtherDefiningPassages}) =
      _$DefiningPassageImpl;

  factory _DefiningPassage.fromJson(Map<String, dynamic> json) =
      _$DefiningPassageImpl.fromJson;

  @override
  String get reference;
  @override
  String? get verseText;
  @override
  String get whyDefinitive;
  @override
  String get historicalCulturalContext;
  @override
  List<WordStudyItem> get wordStudy;
  @override
  String? get morphologicalNote;
  @override
  String get whatThisPassageSays;
  @override
  String? get connectionsToOtherDefiningPassages;

  /// Create a copy of DefiningPassage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DefiningPassageImplCopyWith<_$DefiningPassageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Distortion _$DistortionFromJson(Map<String, dynamic> json) {
  return _Distortion.fromJson(json);
}

/// @nodoc
mixin _$Distortion {
  String get distortion => throw _privateConstructorUsedError;
  String get howItEnters => throw _privateConstructorUsedError;
  String get linguisticCorrection => throw _privateConstructorUsedError;

  /// Serializes this Distortion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Distortion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DistortionCopyWith<Distortion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DistortionCopyWith<$Res> {
  factory $DistortionCopyWith(
          Distortion value, $Res Function(Distortion) then) =
      _$DistortionCopyWithImpl<$Res, Distortion>;
  @useResult
  $Res call(
      {String distortion, String howItEnters, String linguisticCorrection});
}

/// @nodoc
class _$DistortionCopyWithImpl<$Res, $Val extends Distortion>
    implements $DistortionCopyWith<$Res> {
  _$DistortionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Distortion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? distortion = null,
    Object? howItEnters = null,
    Object? linguisticCorrection = null,
  }) {
    return _then(_value.copyWith(
      distortion: null == distortion
          ? _value.distortion
          : distortion // ignore: cast_nullable_to_non_nullable
              as String,
      howItEnters: null == howItEnters
          ? _value.howItEnters
          : howItEnters // ignore: cast_nullable_to_non_nullable
              as String,
      linguisticCorrection: null == linguisticCorrection
          ? _value.linguisticCorrection
          : linguisticCorrection // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DistortionImplCopyWith<$Res>
    implements $DistortionCopyWith<$Res> {
  factory _$$DistortionImplCopyWith(
          _$DistortionImpl value, $Res Function(_$DistortionImpl) then) =
      __$$DistortionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String distortion, String howItEnters, String linguisticCorrection});
}

/// @nodoc
class __$$DistortionImplCopyWithImpl<$Res>
    extends _$DistortionCopyWithImpl<$Res, _$DistortionImpl>
    implements _$$DistortionImplCopyWith<$Res> {
  __$$DistortionImplCopyWithImpl(
      _$DistortionImpl _value, $Res Function(_$DistortionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Distortion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? distortion = null,
    Object? howItEnters = null,
    Object? linguisticCorrection = null,
  }) {
    return _then(_$DistortionImpl(
      distortion: null == distortion
          ? _value.distortion
          : distortion // ignore: cast_nullable_to_non_nullable
              as String,
      howItEnters: null == howItEnters
          ? _value.howItEnters
          : howItEnters // ignore: cast_nullable_to_non_nullable
              as String,
      linguisticCorrection: null == linguisticCorrection
          ? _value.linguisticCorrection
          : linguisticCorrection // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DistortionImpl implements _Distortion {
  const _$DistortionImpl(
      {required this.distortion,
      required this.howItEnters,
      required this.linguisticCorrection});

  factory _$DistortionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DistortionImplFromJson(json);

  @override
  final String distortion;
  @override
  final String howItEnters;
  @override
  final String linguisticCorrection;

  @override
  String toString() {
    return 'Distortion(distortion: $distortion, howItEnters: $howItEnters, linguisticCorrection: $linguisticCorrection)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DistortionImpl &&
            (identical(other.distortion, distortion) ||
                other.distortion == distortion) &&
            (identical(other.howItEnters, howItEnters) ||
                other.howItEnters == howItEnters) &&
            (identical(other.linguisticCorrection, linguisticCorrection) ||
                other.linguisticCorrection == linguisticCorrection));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, distortion, howItEnters, linguisticCorrection);

  /// Create a copy of Distortion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DistortionImplCopyWith<_$DistortionImpl> get copyWith =>
      __$$DistortionImplCopyWithImpl<_$DistortionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DistortionImplToJson(
      this,
    );
  }
}

abstract class _Distortion implements Distortion {
  const factory _Distortion(
      {required final String distortion,
      required final String howItEnters,
      required final String linguisticCorrection}) = _$DistortionImpl;

  factory _Distortion.fromJson(Map<String, dynamic> json) =
      _$DistortionImpl.fromJson;

  @override
  String get distortion;
  @override
  String get howItEnters;
  @override
  String get linguisticCorrection;

  /// Create a copy of Distortion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DistortionImplCopyWith<_$DistortionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VerseExegesis _$VerseExegesisFromJson(Map<String, dynamic> json) {
  return _VerseExegesis.fromJson(json);
}

/// @nodoc
mixin _$VerseExegesis {
  String get id => throw _privateConstructorUsedError;
  ExegesisSource get source => throw _privateConstructorUsedError;
  String get subject =>
      throw _privateConstructorUsedError; // formatted ref string e.g. "John 3:16"
  String get translation =>
      throw _privateConstructorUsedError; // ESV / NIV / KJV / NASB / NLT
  List<Map<String, dynamic>> get verseRefsJson =>
      throw _privateConstructorUsedError; // serialized VerseRef list
// ── Layer 1: The Orienting Insight ──
  String get bigPicture =>
      throw _privateConstructorUsedError; // ── Layer 2: Historical & Cultural Setting ──
  HistoricalCulturalSetting get historicalCulturalSetting =>
      throw _privateConstructorUsedError; // ── Layer 3: Literary & Structural Context ──
  LiteraryContext get literaryContext =>
      throw _privateConstructorUsedError; // ── Layer 4: Original Language Word Study ──
  List<WordStudyItem> get wordStudy =>
      throw _privateConstructorUsedError; // ── Layer 5: Morphological Analysis ──
  List<MorphItem> get morphologicalAnalysis =>
      throw _privateConstructorUsedError; // ── Layer 6: Semantic Disambiguation (conditional) ──
  List<SemanticItem> get semanticDisambiguation =>
      throw _privateConstructorUsedError; // ── Layer 7: First & Significant Mentions ──
  List<MentionItem> get mentionAnalysis =>
      throw _privateConstructorUsedError; // ── Layer 8: Discourse Analysis ──
  DiscourseAnalysis get discourseAnalysis =>
      throw _privateConstructorUsedError; // ── Layer 9: Cross-References ──
  List<CrossRef> get crossReferences =>
      throw _privateConstructorUsedError; // ── Layer 10: Intertextual Allusions (conditional) ──
  List<Allusion>? get intertextualAllusions =>
      throw _privateConstructorUsedError; // ── Layer 11: Textual Apparatus Notes (conditional) ──
  TextualNote? get textualApparatusNotes =>
      throw _privateConstructorUsedError; // ── Layer 12: The Implied Theological Claim ──
  String get impliedTheologicalClaim =>
      throw _privateConstructorUsedError; // ── Layer 13: What This Text Cannot Mean ──
  List<Misreading> get whatItCannotMean =>
      throw _privateConstructorUsedError; // ── Layer 14: From Text to Life ──
  String get fromTextToLife =>
      throw _privateConstructorUsedError; // ── Final: Something To Sit With ──
  String get somethingToSitWith =>
      throw _privateConstructorUsedError; // ── Metadata ──
  String? get contextSummary => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this VerseExegesis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VerseExegesisCopyWith<VerseExegesis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerseExegesisCopyWith<$Res> {
  factory $VerseExegesisCopyWith(
          VerseExegesis value, $Res Function(VerseExegesis) then) =
      _$VerseExegesisCopyWithImpl<$Res, VerseExegesis>;
  @useResult
  $Res call(
      {String id,
      ExegesisSource source,
      String subject,
      String translation,
      List<Map<String, dynamic>> verseRefsJson,
      String bigPicture,
      HistoricalCulturalSetting historicalCulturalSetting,
      LiteraryContext literaryContext,
      List<WordStudyItem> wordStudy,
      List<MorphItem> morphologicalAnalysis,
      List<SemanticItem> semanticDisambiguation,
      List<MentionItem> mentionAnalysis,
      DiscourseAnalysis discourseAnalysis,
      List<CrossRef> crossReferences,
      List<Allusion>? intertextualAllusions,
      TextualNote? textualApparatusNotes,
      String impliedTheologicalClaim,
      List<Misreading> whatItCannotMean,
      String fromTextToLife,
      String somethingToSitWith,
      String? contextSummary,
      DateTime createdAt});

  $HistoricalCulturalSettingCopyWith<$Res> get historicalCulturalSetting;
  $LiteraryContextCopyWith<$Res> get literaryContext;
  $DiscourseAnalysisCopyWith<$Res> get discourseAnalysis;
  $TextualNoteCopyWith<$Res>? get textualApparatusNotes;
}

/// @nodoc
class _$VerseExegesisCopyWithImpl<$Res, $Val extends VerseExegesis>
    implements $VerseExegesisCopyWith<$Res> {
  _$VerseExegesisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? subject = null,
    Object? translation = null,
    Object? verseRefsJson = null,
    Object? bigPicture = null,
    Object? historicalCulturalSetting = null,
    Object? literaryContext = null,
    Object? wordStudy = null,
    Object? morphologicalAnalysis = null,
    Object? semanticDisambiguation = null,
    Object? mentionAnalysis = null,
    Object? discourseAnalysis = null,
    Object? crossReferences = null,
    Object? intertextualAllusions = freezed,
    Object? textualApparatusNotes = freezed,
    Object? impliedTheologicalClaim = null,
    Object? whatItCannotMean = null,
    Object? fromTextToLife = null,
    Object? somethingToSitWith = null,
    Object? contextSummary = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ExegesisSource,
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      translation: null == translation
          ? _value.translation
          : translation // ignore: cast_nullable_to_non_nullable
              as String,
      verseRefsJson: null == verseRefsJson
          ? _value.verseRefsJson
          : verseRefsJson // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      bigPicture: null == bigPicture
          ? _value.bigPicture
          : bigPicture // ignore: cast_nullable_to_non_nullable
              as String,
      historicalCulturalSetting: null == historicalCulturalSetting
          ? _value.historicalCulturalSetting
          : historicalCulturalSetting // ignore: cast_nullable_to_non_nullable
              as HistoricalCulturalSetting,
      literaryContext: null == literaryContext
          ? _value.literaryContext
          : literaryContext // ignore: cast_nullable_to_non_nullable
              as LiteraryContext,
      wordStudy: null == wordStudy
          ? _value.wordStudy
          : wordStudy // ignore: cast_nullable_to_non_nullable
              as List<WordStudyItem>,
      morphologicalAnalysis: null == morphologicalAnalysis
          ? _value.morphologicalAnalysis
          : morphologicalAnalysis // ignore: cast_nullable_to_non_nullable
              as List<MorphItem>,
      semanticDisambiguation: null == semanticDisambiguation
          ? _value.semanticDisambiguation
          : semanticDisambiguation // ignore: cast_nullable_to_non_nullable
              as List<SemanticItem>,
      mentionAnalysis: null == mentionAnalysis
          ? _value.mentionAnalysis
          : mentionAnalysis // ignore: cast_nullable_to_non_nullable
              as List<MentionItem>,
      discourseAnalysis: null == discourseAnalysis
          ? _value.discourseAnalysis
          : discourseAnalysis // ignore: cast_nullable_to_non_nullable
              as DiscourseAnalysis,
      crossReferences: null == crossReferences
          ? _value.crossReferences
          : crossReferences // ignore: cast_nullable_to_non_nullable
              as List<CrossRef>,
      intertextualAllusions: freezed == intertextualAllusions
          ? _value.intertextualAllusions
          : intertextualAllusions // ignore: cast_nullable_to_non_nullable
              as List<Allusion>?,
      textualApparatusNotes: freezed == textualApparatusNotes
          ? _value.textualApparatusNotes
          : textualApparatusNotes // ignore: cast_nullable_to_non_nullable
              as TextualNote?,
      impliedTheologicalClaim: null == impliedTheologicalClaim
          ? _value.impliedTheologicalClaim
          : impliedTheologicalClaim // ignore: cast_nullable_to_non_nullable
              as String,
      whatItCannotMean: null == whatItCannotMean
          ? _value.whatItCannotMean
          : whatItCannotMean // ignore: cast_nullable_to_non_nullable
              as List<Misreading>,
      fromTextToLife: null == fromTextToLife
          ? _value.fromTextToLife
          : fromTextToLife // ignore: cast_nullable_to_non_nullable
              as String,
      somethingToSitWith: null == somethingToSitWith
          ? _value.somethingToSitWith
          : somethingToSitWith // ignore: cast_nullable_to_non_nullable
              as String,
      contextSummary: freezed == contextSummary
          ? _value.contextSummary
          : contextSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HistoricalCulturalSettingCopyWith<$Res> get historicalCulturalSetting {
    return $HistoricalCulturalSettingCopyWith<$Res>(
        _value.historicalCulturalSetting, (value) {
      return _then(_value.copyWith(historicalCulturalSetting: value) as $Val);
    });
  }

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiteraryContextCopyWith<$Res> get literaryContext {
    return $LiteraryContextCopyWith<$Res>(_value.literaryContext, (value) {
      return _then(_value.copyWith(literaryContext: value) as $Val);
    });
  }

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DiscourseAnalysisCopyWith<$Res> get discourseAnalysis {
    return $DiscourseAnalysisCopyWith<$Res>(_value.discourseAnalysis, (value) {
      return _then(_value.copyWith(discourseAnalysis: value) as $Val);
    });
  }

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TextualNoteCopyWith<$Res>? get textualApparatusNotes {
    if (_value.textualApparatusNotes == null) {
      return null;
    }

    return $TextualNoteCopyWith<$Res>(_value.textualApparatusNotes!, (value) {
      return _then(_value.copyWith(textualApparatusNotes: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VerseExegesisImplCopyWith<$Res>
    implements $VerseExegesisCopyWith<$Res> {
  factory _$$VerseExegesisImplCopyWith(
          _$VerseExegesisImpl value, $Res Function(_$VerseExegesisImpl) then) =
      __$$VerseExegesisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      ExegesisSource source,
      String subject,
      String translation,
      List<Map<String, dynamic>> verseRefsJson,
      String bigPicture,
      HistoricalCulturalSetting historicalCulturalSetting,
      LiteraryContext literaryContext,
      List<WordStudyItem> wordStudy,
      List<MorphItem> morphologicalAnalysis,
      List<SemanticItem> semanticDisambiguation,
      List<MentionItem> mentionAnalysis,
      DiscourseAnalysis discourseAnalysis,
      List<CrossRef> crossReferences,
      List<Allusion>? intertextualAllusions,
      TextualNote? textualApparatusNotes,
      String impliedTheologicalClaim,
      List<Misreading> whatItCannotMean,
      String fromTextToLife,
      String somethingToSitWith,
      String? contextSummary,
      DateTime createdAt});

  @override
  $HistoricalCulturalSettingCopyWith<$Res> get historicalCulturalSetting;
  @override
  $LiteraryContextCopyWith<$Res> get literaryContext;
  @override
  $DiscourseAnalysisCopyWith<$Res> get discourseAnalysis;
  @override
  $TextualNoteCopyWith<$Res>? get textualApparatusNotes;
}

/// @nodoc
class __$$VerseExegesisImplCopyWithImpl<$Res>
    extends _$VerseExegesisCopyWithImpl<$Res, _$VerseExegesisImpl>
    implements _$$VerseExegesisImplCopyWith<$Res> {
  __$$VerseExegesisImplCopyWithImpl(
      _$VerseExegesisImpl _value, $Res Function(_$VerseExegesisImpl) _then)
      : super(_value, _then);

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? subject = null,
    Object? translation = null,
    Object? verseRefsJson = null,
    Object? bigPicture = null,
    Object? historicalCulturalSetting = null,
    Object? literaryContext = null,
    Object? wordStudy = null,
    Object? morphologicalAnalysis = null,
    Object? semanticDisambiguation = null,
    Object? mentionAnalysis = null,
    Object? discourseAnalysis = null,
    Object? crossReferences = null,
    Object? intertextualAllusions = freezed,
    Object? textualApparatusNotes = freezed,
    Object? impliedTheologicalClaim = null,
    Object? whatItCannotMean = null,
    Object? fromTextToLife = null,
    Object? somethingToSitWith = null,
    Object? contextSummary = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$VerseExegesisImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ExegesisSource,
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      translation: null == translation
          ? _value.translation
          : translation // ignore: cast_nullable_to_non_nullable
              as String,
      verseRefsJson: null == verseRefsJson
          ? _value._verseRefsJson
          : verseRefsJson // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      bigPicture: null == bigPicture
          ? _value.bigPicture
          : bigPicture // ignore: cast_nullable_to_non_nullable
              as String,
      historicalCulturalSetting: null == historicalCulturalSetting
          ? _value.historicalCulturalSetting
          : historicalCulturalSetting // ignore: cast_nullable_to_non_nullable
              as HistoricalCulturalSetting,
      literaryContext: null == literaryContext
          ? _value.literaryContext
          : literaryContext // ignore: cast_nullable_to_non_nullable
              as LiteraryContext,
      wordStudy: null == wordStudy
          ? _value._wordStudy
          : wordStudy // ignore: cast_nullable_to_non_nullable
              as List<WordStudyItem>,
      morphologicalAnalysis: null == morphologicalAnalysis
          ? _value._morphologicalAnalysis
          : morphologicalAnalysis // ignore: cast_nullable_to_non_nullable
              as List<MorphItem>,
      semanticDisambiguation: null == semanticDisambiguation
          ? _value._semanticDisambiguation
          : semanticDisambiguation // ignore: cast_nullable_to_non_nullable
              as List<SemanticItem>,
      mentionAnalysis: null == mentionAnalysis
          ? _value._mentionAnalysis
          : mentionAnalysis // ignore: cast_nullable_to_non_nullable
              as List<MentionItem>,
      discourseAnalysis: null == discourseAnalysis
          ? _value.discourseAnalysis
          : discourseAnalysis // ignore: cast_nullable_to_non_nullable
              as DiscourseAnalysis,
      crossReferences: null == crossReferences
          ? _value._crossReferences
          : crossReferences // ignore: cast_nullable_to_non_nullable
              as List<CrossRef>,
      intertextualAllusions: freezed == intertextualAllusions
          ? _value._intertextualAllusions
          : intertextualAllusions // ignore: cast_nullable_to_non_nullable
              as List<Allusion>?,
      textualApparatusNotes: freezed == textualApparatusNotes
          ? _value.textualApparatusNotes
          : textualApparatusNotes // ignore: cast_nullable_to_non_nullable
              as TextualNote?,
      impliedTheologicalClaim: null == impliedTheologicalClaim
          ? _value.impliedTheologicalClaim
          : impliedTheologicalClaim // ignore: cast_nullable_to_non_nullable
              as String,
      whatItCannotMean: null == whatItCannotMean
          ? _value._whatItCannotMean
          : whatItCannotMean // ignore: cast_nullable_to_non_nullable
              as List<Misreading>,
      fromTextToLife: null == fromTextToLife
          ? _value.fromTextToLife
          : fromTextToLife // ignore: cast_nullable_to_non_nullable
              as String,
      somethingToSitWith: null == somethingToSitWith
          ? _value.somethingToSitWith
          : somethingToSitWith // ignore: cast_nullable_to_non_nullable
              as String,
      contextSummary: freezed == contextSummary
          ? _value.contextSummary
          : contextSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VerseExegesisImpl extends _VerseExegesis {
  const _$VerseExegesisImpl(
      {required this.id,
      required this.source,
      required this.subject,
      required this.translation,
      final List<Map<String, dynamic>> verseRefsJson = const [],
      required this.bigPicture,
      required this.historicalCulturalSetting,
      required this.literaryContext,
      final List<WordStudyItem> wordStudy = const [],
      final List<MorphItem> morphologicalAnalysis = const [],
      final List<SemanticItem> semanticDisambiguation = const [],
      final List<MentionItem> mentionAnalysis = const [],
      required this.discourseAnalysis,
      final List<CrossRef> crossReferences = const [],
      final List<Allusion>? intertextualAllusions,
      this.textualApparatusNotes,
      required this.impliedTheologicalClaim,
      final List<Misreading> whatItCannotMean = const [],
      required this.fromTextToLife,
      required this.somethingToSitWith,
      this.contextSummary,
      required this.createdAt})
      : _verseRefsJson = verseRefsJson,
        _wordStudy = wordStudy,
        _morphologicalAnalysis = morphologicalAnalysis,
        _semanticDisambiguation = semanticDisambiguation,
        _mentionAnalysis = mentionAnalysis,
        _crossReferences = crossReferences,
        _intertextualAllusions = intertextualAllusions,
        _whatItCannotMean = whatItCannotMean,
        super._();

  factory _$VerseExegesisImpl.fromJson(Map<String, dynamic> json) =>
      _$$VerseExegesisImplFromJson(json);

  @override
  final String id;
  @override
  final ExegesisSource source;
  @override
  final String subject;
// formatted ref string e.g. "John 3:16"
  @override
  final String translation;
// ESV / NIV / KJV / NASB / NLT
  final List<Map<String, dynamic>> _verseRefsJson;
// ESV / NIV / KJV / NASB / NLT
  @override
  @JsonKey()
  List<Map<String, dynamic>> get verseRefsJson {
    if (_verseRefsJson is EqualUnmodifiableListView) return _verseRefsJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_verseRefsJson);
  }

// serialized VerseRef list
// ── Layer 1: The Orienting Insight ──
  @override
  final String bigPicture;
// ── Layer 2: Historical & Cultural Setting ──
  @override
  final HistoricalCulturalSetting historicalCulturalSetting;
// ── Layer 3: Literary & Structural Context ──
  @override
  final LiteraryContext literaryContext;
// ── Layer 4: Original Language Word Study ──
  final List<WordStudyItem> _wordStudy;
// ── Layer 4: Original Language Word Study ──
  @override
  @JsonKey()
  List<WordStudyItem> get wordStudy {
    if (_wordStudy is EqualUnmodifiableListView) return _wordStudy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wordStudy);
  }

// ── Layer 5: Morphological Analysis ──
  final List<MorphItem> _morphologicalAnalysis;
// ── Layer 5: Morphological Analysis ──
  @override
  @JsonKey()
  List<MorphItem> get morphologicalAnalysis {
    if (_morphologicalAnalysis is EqualUnmodifiableListView)
      return _morphologicalAnalysis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_morphologicalAnalysis);
  }

// ── Layer 6: Semantic Disambiguation (conditional) ──
  final List<SemanticItem> _semanticDisambiguation;
// ── Layer 6: Semantic Disambiguation (conditional) ──
  @override
  @JsonKey()
  List<SemanticItem> get semanticDisambiguation {
    if (_semanticDisambiguation is EqualUnmodifiableListView)
      return _semanticDisambiguation;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_semanticDisambiguation);
  }

// ── Layer 7: First & Significant Mentions ──
  final List<MentionItem> _mentionAnalysis;
// ── Layer 7: First & Significant Mentions ──
  @override
  @JsonKey()
  List<MentionItem> get mentionAnalysis {
    if (_mentionAnalysis is EqualUnmodifiableListView) return _mentionAnalysis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mentionAnalysis);
  }

// ── Layer 8: Discourse Analysis ──
  @override
  final DiscourseAnalysis discourseAnalysis;
// ── Layer 9: Cross-References ──
  final List<CrossRef> _crossReferences;
// ── Layer 9: Cross-References ──
  @override
  @JsonKey()
  List<CrossRef> get crossReferences {
    if (_crossReferences is EqualUnmodifiableListView) return _crossReferences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_crossReferences);
  }

// ── Layer 10: Intertextual Allusions (conditional) ──
  final List<Allusion>? _intertextualAllusions;
// ── Layer 10: Intertextual Allusions (conditional) ──
  @override
  List<Allusion>? get intertextualAllusions {
    final value = _intertextualAllusions;
    if (value == null) return null;
    if (_intertextualAllusions is EqualUnmodifiableListView)
      return _intertextualAllusions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// ── Layer 11: Textual Apparatus Notes (conditional) ──
  @override
  final TextualNote? textualApparatusNotes;
// ── Layer 12: The Implied Theological Claim ──
  @override
  final String impliedTheologicalClaim;
// ── Layer 13: What This Text Cannot Mean ──
  final List<Misreading> _whatItCannotMean;
// ── Layer 13: What This Text Cannot Mean ──
  @override
  @JsonKey()
  List<Misreading> get whatItCannotMean {
    if (_whatItCannotMean is EqualUnmodifiableListView)
      return _whatItCannotMean;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_whatItCannotMean);
  }

// ── Layer 14: From Text to Life ──
  @override
  final String fromTextToLife;
// ── Final: Something To Sit With ──
  @override
  final String somethingToSitWith;
// ── Metadata ──
  @override
  final String? contextSummary;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'VerseExegesis(id: $id, source: $source, subject: $subject, translation: $translation, verseRefsJson: $verseRefsJson, bigPicture: $bigPicture, historicalCulturalSetting: $historicalCulturalSetting, literaryContext: $literaryContext, wordStudy: $wordStudy, morphologicalAnalysis: $morphologicalAnalysis, semanticDisambiguation: $semanticDisambiguation, mentionAnalysis: $mentionAnalysis, discourseAnalysis: $discourseAnalysis, crossReferences: $crossReferences, intertextualAllusions: $intertextualAllusions, textualApparatusNotes: $textualApparatusNotes, impliedTheologicalClaim: $impliedTheologicalClaim, whatItCannotMean: $whatItCannotMean, fromTextToLife: $fromTextToLife, somethingToSitWith: $somethingToSitWith, contextSummary: $contextSummary, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerseExegesisImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.translation, translation) ||
                other.translation == translation) &&
            const DeepCollectionEquality()
                .equals(other._verseRefsJson, _verseRefsJson) &&
            (identical(other.bigPicture, bigPicture) ||
                other.bigPicture == bigPicture) &&
            (identical(other.historicalCulturalSetting,
                    historicalCulturalSetting) ||
                other.historicalCulturalSetting == historicalCulturalSetting) &&
            (identical(other.literaryContext, literaryContext) ||
                other.literaryContext == literaryContext) &&
            const DeepCollectionEquality()
                .equals(other._wordStudy, _wordStudy) &&
            const DeepCollectionEquality()
                .equals(other._morphologicalAnalysis, _morphologicalAnalysis) &&
            const DeepCollectionEquality().equals(
                other._semanticDisambiguation, _semanticDisambiguation) &&
            const DeepCollectionEquality()
                .equals(other._mentionAnalysis, _mentionAnalysis) &&
            (identical(other.discourseAnalysis, discourseAnalysis) ||
                other.discourseAnalysis == discourseAnalysis) &&
            const DeepCollectionEquality()
                .equals(other._crossReferences, _crossReferences) &&
            const DeepCollectionEquality()
                .equals(other._intertextualAllusions, _intertextualAllusions) &&
            (identical(other.textualApparatusNotes, textualApparatusNotes) ||
                other.textualApparatusNotes == textualApparatusNotes) &&
            (identical(
                    other.impliedTheologicalClaim, impliedTheologicalClaim) ||
                other.impliedTheologicalClaim == impliedTheologicalClaim) &&
            const DeepCollectionEquality()
                .equals(other._whatItCannotMean, _whatItCannotMean) &&
            (identical(other.fromTextToLife, fromTextToLife) ||
                other.fromTextToLife == fromTextToLife) &&
            (identical(other.somethingToSitWith, somethingToSitWith) ||
                other.somethingToSitWith == somethingToSitWith) &&
            (identical(other.contextSummary, contextSummary) ||
                other.contextSummary == contextSummary) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        source,
        subject,
        translation,
        const DeepCollectionEquality().hash(_verseRefsJson),
        bigPicture,
        historicalCulturalSetting,
        literaryContext,
        const DeepCollectionEquality().hash(_wordStudy),
        const DeepCollectionEquality().hash(_morphologicalAnalysis),
        const DeepCollectionEquality().hash(_semanticDisambiguation),
        const DeepCollectionEquality().hash(_mentionAnalysis),
        discourseAnalysis,
        const DeepCollectionEquality().hash(_crossReferences),
        const DeepCollectionEquality().hash(_intertextualAllusions),
        textualApparatusNotes,
        impliedTheologicalClaim,
        const DeepCollectionEquality().hash(_whatItCannotMean),
        fromTextToLife,
        somethingToSitWith,
        contextSummary,
        createdAt
      ]);

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VerseExegesisImplCopyWith<_$VerseExegesisImpl> get copyWith =>
      __$$VerseExegesisImplCopyWithImpl<_$VerseExegesisImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VerseExegesisImplToJson(
      this,
    );
  }
}

abstract class _VerseExegesis extends VerseExegesis {
  const factory _VerseExegesis(
      {required final String id,
      required final ExegesisSource source,
      required final String subject,
      required final String translation,
      final List<Map<String, dynamic>> verseRefsJson,
      required final String bigPicture,
      required final HistoricalCulturalSetting historicalCulturalSetting,
      required final LiteraryContext literaryContext,
      final List<WordStudyItem> wordStudy,
      final List<MorphItem> morphologicalAnalysis,
      final List<SemanticItem> semanticDisambiguation,
      final List<MentionItem> mentionAnalysis,
      required final DiscourseAnalysis discourseAnalysis,
      final List<CrossRef> crossReferences,
      final List<Allusion>? intertextualAllusions,
      final TextualNote? textualApparatusNotes,
      required final String impliedTheologicalClaim,
      final List<Misreading> whatItCannotMean,
      required final String fromTextToLife,
      required final String somethingToSitWith,
      final String? contextSummary,
      required final DateTime createdAt}) = _$VerseExegesisImpl;
  const _VerseExegesis._() : super._();

  factory _VerseExegesis.fromJson(Map<String, dynamic> json) =
      _$VerseExegesisImpl.fromJson;

  @override
  String get id;
  @override
  ExegesisSource get source;
  @override
  String get subject; // formatted ref string e.g. "John 3:16"
  @override
  String get translation; // ESV / NIV / KJV / NASB / NLT
  @override
  List<Map<String, dynamic>> get verseRefsJson; // serialized VerseRef list
// ── Layer 1: The Orienting Insight ──
  @override
  String get bigPicture; // ── Layer 2: Historical & Cultural Setting ──
  @override
  HistoricalCulturalSetting
      get historicalCulturalSetting; // ── Layer 3: Literary & Structural Context ──
  @override
  LiteraryContext
      get literaryContext; // ── Layer 4: Original Language Word Study ──
  @override
  List<WordStudyItem> get wordStudy; // ── Layer 5: Morphological Analysis ──
  @override
  List<MorphItem>
      get morphologicalAnalysis; // ── Layer 6: Semantic Disambiguation (conditional) ──
  @override
  List<SemanticItem>
      get semanticDisambiguation; // ── Layer 7: First & Significant Mentions ──
  @override
  List<MentionItem> get mentionAnalysis; // ── Layer 8: Discourse Analysis ──
  @override
  DiscourseAnalysis get discourseAnalysis; // ── Layer 9: Cross-References ──
  @override
  List<CrossRef>
      get crossReferences; // ── Layer 10: Intertextual Allusions (conditional) ──
  @override
  List<Allusion>?
      get intertextualAllusions; // ── Layer 11: Textual Apparatus Notes (conditional) ──
  @override
  TextualNote?
      get textualApparatusNotes; // ── Layer 12: The Implied Theological Claim ──
  @override
  String
      get impliedTheologicalClaim; // ── Layer 13: What This Text Cannot Mean ──
  @override
  List<Misreading> get whatItCannotMean; // ── Layer 14: From Text to Life ──
  @override
  String get fromTextToLife; // ── Final: Something To Sit With ──
  @override
  String get somethingToSitWith; // ── Metadata ──
  @override
  String? get contextSummary;
  @override
  DateTime get createdAt;

  /// Create a copy of VerseExegesis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VerseExegesisImplCopyWith<_$VerseExegesisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TopicExegesis _$TopicExegesisFromJson(Map<String, dynamic> json) {
  return _TopicExegesis.fromJson(json);
}

/// @nodoc
mixin _$TopicExegesis {
  String get id => throw _privateConstructorUsedError;
  ExegesisSource get source => throw _privateConstructorUsedError;
  String get subject =>
      throw _privateConstructorUsedError; // the topic name e.g. "Grace"
// ── Layer 1: The Orienting Insight ──
  String get bigPicture =>
      throw _privateConstructorUsedError; // ── Concept Definition (Hebrew + Greek) ──
  ConceptDefinition get conceptDefinition =>
      throw _privateConstructorUsedError; // ── First Mention ──
  TopicFirstMention get firstMention =>
      throw _privateConstructorUsedError; // ── 3–5 Defining Passage Studies ──
  List<DefiningPassage> get definingPassages =>
      throw _privateConstructorUsedError; // ── Canonical Progression ──
  String get canonicalProgression =>
      throw _privateConstructorUsedError; // ── Common Distortions ──
  List<Distortion> get commonDistortions =>
      throw _privateConstructorUsedError; // ── Layer 12: Implied Theological Claim ──
  String get impliedTheologicalClaim =>
      throw _privateConstructorUsedError; // ── Layer 13: What This Cannot Mean ──
  List<Misreading> get whatItCannotMean =>
      throw _privateConstructorUsedError; // ── Layer 14: From Text to Life ──
  String get fromTextToLife =>
      throw _privateConstructorUsedError; // ── Final: Something To Sit With ──
  String get somethingToSitWith =>
      throw _privateConstructorUsedError; // ── Metadata ──
  String? get contextSummary => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this TopicExegesis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopicExegesis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopicExegesisCopyWith<TopicExegesis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopicExegesisCopyWith<$Res> {
  factory $TopicExegesisCopyWith(
          TopicExegesis value, $Res Function(TopicExegesis) then) =
      _$TopicExegesisCopyWithImpl<$Res, TopicExegesis>;
  @useResult
  $Res call(
      {String id,
      ExegesisSource source,
      String subject,
      String bigPicture,
      ConceptDefinition conceptDefinition,
      TopicFirstMention firstMention,
      List<DefiningPassage> definingPassages,
      String canonicalProgression,
      List<Distortion> commonDistortions,
      String impliedTheologicalClaim,
      List<Misreading> whatItCannotMean,
      String fromTextToLife,
      String somethingToSitWith,
      String? contextSummary,
      DateTime createdAt});

  $ConceptDefinitionCopyWith<$Res> get conceptDefinition;
  $TopicFirstMentionCopyWith<$Res> get firstMention;
}

/// @nodoc
class _$TopicExegesisCopyWithImpl<$Res, $Val extends TopicExegesis>
    implements $TopicExegesisCopyWith<$Res> {
  _$TopicExegesisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopicExegesis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? subject = null,
    Object? bigPicture = null,
    Object? conceptDefinition = null,
    Object? firstMention = null,
    Object? definingPassages = null,
    Object? canonicalProgression = null,
    Object? commonDistortions = null,
    Object? impliedTheologicalClaim = null,
    Object? whatItCannotMean = null,
    Object? fromTextToLife = null,
    Object? somethingToSitWith = null,
    Object? contextSummary = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ExegesisSource,
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      bigPicture: null == bigPicture
          ? _value.bigPicture
          : bigPicture // ignore: cast_nullable_to_non_nullable
              as String,
      conceptDefinition: null == conceptDefinition
          ? _value.conceptDefinition
          : conceptDefinition // ignore: cast_nullable_to_non_nullable
              as ConceptDefinition,
      firstMention: null == firstMention
          ? _value.firstMention
          : firstMention // ignore: cast_nullable_to_non_nullable
              as TopicFirstMention,
      definingPassages: null == definingPassages
          ? _value.definingPassages
          : definingPassages // ignore: cast_nullable_to_non_nullable
              as List<DefiningPassage>,
      canonicalProgression: null == canonicalProgression
          ? _value.canonicalProgression
          : canonicalProgression // ignore: cast_nullable_to_non_nullable
              as String,
      commonDistortions: null == commonDistortions
          ? _value.commonDistortions
          : commonDistortions // ignore: cast_nullable_to_non_nullable
              as List<Distortion>,
      impliedTheologicalClaim: null == impliedTheologicalClaim
          ? _value.impliedTheologicalClaim
          : impliedTheologicalClaim // ignore: cast_nullable_to_non_nullable
              as String,
      whatItCannotMean: null == whatItCannotMean
          ? _value.whatItCannotMean
          : whatItCannotMean // ignore: cast_nullable_to_non_nullable
              as List<Misreading>,
      fromTextToLife: null == fromTextToLife
          ? _value.fromTextToLife
          : fromTextToLife // ignore: cast_nullable_to_non_nullable
              as String,
      somethingToSitWith: null == somethingToSitWith
          ? _value.somethingToSitWith
          : somethingToSitWith // ignore: cast_nullable_to_non_nullable
              as String,
      contextSummary: freezed == contextSummary
          ? _value.contextSummary
          : contextSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  /// Create a copy of TopicExegesis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConceptDefinitionCopyWith<$Res> get conceptDefinition {
    return $ConceptDefinitionCopyWith<$Res>(_value.conceptDefinition, (value) {
      return _then(_value.copyWith(conceptDefinition: value) as $Val);
    });
  }

  /// Create a copy of TopicExegesis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TopicFirstMentionCopyWith<$Res> get firstMention {
    return $TopicFirstMentionCopyWith<$Res>(_value.firstMention, (value) {
      return _then(_value.copyWith(firstMention: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TopicExegesisImplCopyWith<$Res>
    implements $TopicExegesisCopyWith<$Res> {
  factory _$$TopicExegesisImplCopyWith(
          _$TopicExegesisImpl value, $Res Function(_$TopicExegesisImpl) then) =
      __$$TopicExegesisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      ExegesisSource source,
      String subject,
      String bigPicture,
      ConceptDefinition conceptDefinition,
      TopicFirstMention firstMention,
      List<DefiningPassage> definingPassages,
      String canonicalProgression,
      List<Distortion> commonDistortions,
      String impliedTheologicalClaim,
      List<Misreading> whatItCannotMean,
      String fromTextToLife,
      String somethingToSitWith,
      String? contextSummary,
      DateTime createdAt});

  @override
  $ConceptDefinitionCopyWith<$Res> get conceptDefinition;
  @override
  $TopicFirstMentionCopyWith<$Res> get firstMention;
}

/// @nodoc
class __$$TopicExegesisImplCopyWithImpl<$Res>
    extends _$TopicExegesisCopyWithImpl<$Res, _$TopicExegesisImpl>
    implements _$$TopicExegesisImplCopyWith<$Res> {
  __$$TopicExegesisImplCopyWithImpl(
      _$TopicExegesisImpl _value, $Res Function(_$TopicExegesisImpl) _then)
      : super(_value, _then);

  /// Create a copy of TopicExegesis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? subject = null,
    Object? bigPicture = null,
    Object? conceptDefinition = null,
    Object? firstMention = null,
    Object? definingPassages = null,
    Object? canonicalProgression = null,
    Object? commonDistortions = null,
    Object? impliedTheologicalClaim = null,
    Object? whatItCannotMean = null,
    Object? fromTextToLife = null,
    Object? somethingToSitWith = null,
    Object? contextSummary = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$TopicExegesisImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ExegesisSource,
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      bigPicture: null == bigPicture
          ? _value.bigPicture
          : bigPicture // ignore: cast_nullable_to_non_nullable
              as String,
      conceptDefinition: null == conceptDefinition
          ? _value.conceptDefinition
          : conceptDefinition // ignore: cast_nullable_to_non_nullable
              as ConceptDefinition,
      firstMention: null == firstMention
          ? _value.firstMention
          : firstMention // ignore: cast_nullable_to_non_nullable
              as TopicFirstMention,
      definingPassages: null == definingPassages
          ? _value._definingPassages
          : definingPassages // ignore: cast_nullable_to_non_nullable
              as List<DefiningPassage>,
      canonicalProgression: null == canonicalProgression
          ? _value.canonicalProgression
          : canonicalProgression // ignore: cast_nullable_to_non_nullable
              as String,
      commonDistortions: null == commonDistortions
          ? _value._commonDistortions
          : commonDistortions // ignore: cast_nullable_to_non_nullable
              as List<Distortion>,
      impliedTheologicalClaim: null == impliedTheologicalClaim
          ? _value.impliedTheologicalClaim
          : impliedTheologicalClaim // ignore: cast_nullable_to_non_nullable
              as String,
      whatItCannotMean: null == whatItCannotMean
          ? _value._whatItCannotMean
          : whatItCannotMean // ignore: cast_nullable_to_non_nullable
              as List<Misreading>,
      fromTextToLife: null == fromTextToLife
          ? _value.fromTextToLife
          : fromTextToLife // ignore: cast_nullable_to_non_nullable
              as String,
      somethingToSitWith: null == somethingToSitWith
          ? _value.somethingToSitWith
          : somethingToSitWith // ignore: cast_nullable_to_non_nullable
              as String,
      contextSummary: freezed == contextSummary
          ? _value.contextSummary
          : contextSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TopicExegesisImpl extends _TopicExegesis {
  const _$TopicExegesisImpl(
      {required this.id,
      required this.source,
      required this.subject,
      required this.bigPicture,
      required this.conceptDefinition,
      required this.firstMention,
      final List<DefiningPassage> definingPassages = const [],
      required this.canonicalProgression,
      final List<Distortion> commonDistortions = const [],
      required this.impliedTheologicalClaim,
      final List<Misreading> whatItCannotMean = const [],
      required this.fromTextToLife,
      required this.somethingToSitWith,
      this.contextSummary,
      required this.createdAt})
      : _definingPassages = definingPassages,
        _commonDistortions = commonDistortions,
        _whatItCannotMean = whatItCannotMean,
        super._();

  factory _$TopicExegesisImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopicExegesisImplFromJson(json);

  @override
  final String id;
  @override
  final ExegesisSource source;
  @override
  final String subject;
// the topic name e.g. "Grace"
// ── Layer 1: The Orienting Insight ──
  @override
  final String bigPicture;
// ── Concept Definition (Hebrew + Greek) ──
  @override
  final ConceptDefinition conceptDefinition;
// ── First Mention ──
  @override
  final TopicFirstMention firstMention;
// ── 3–5 Defining Passage Studies ──
  final List<DefiningPassage> _definingPassages;
// ── 3–5 Defining Passage Studies ──
  @override
  @JsonKey()
  List<DefiningPassage> get definingPassages {
    if (_definingPassages is EqualUnmodifiableListView)
      return _definingPassages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_definingPassages);
  }

// ── Canonical Progression ──
  @override
  final String canonicalProgression;
// ── Common Distortions ──
  final List<Distortion> _commonDistortions;
// ── Common Distortions ──
  @override
  @JsonKey()
  List<Distortion> get commonDistortions {
    if (_commonDistortions is EqualUnmodifiableListView)
      return _commonDistortions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_commonDistortions);
  }

// ── Layer 12: Implied Theological Claim ──
  @override
  final String impliedTheologicalClaim;
// ── Layer 13: What This Cannot Mean ──
  final List<Misreading> _whatItCannotMean;
// ── Layer 13: What This Cannot Mean ──
  @override
  @JsonKey()
  List<Misreading> get whatItCannotMean {
    if (_whatItCannotMean is EqualUnmodifiableListView)
      return _whatItCannotMean;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_whatItCannotMean);
  }

// ── Layer 14: From Text to Life ──
  @override
  final String fromTextToLife;
// ── Final: Something To Sit With ──
  @override
  final String somethingToSitWith;
// ── Metadata ──
  @override
  final String? contextSummary;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'TopicExegesis(id: $id, source: $source, subject: $subject, bigPicture: $bigPicture, conceptDefinition: $conceptDefinition, firstMention: $firstMention, definingPassages: $definingPassages, canonicalProgression: $canonicalProgression, commonDistortions: $commonDistortions, impliedTheologicalClaim: $impliedTheologicalClaim, whatItCannotMean: $whatItCannotMean, fromTextToLife: $fromTextToLife, somethingToSitWith: $somethingToSitWith, contextSummary: $contextSummary, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopicExegesisImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.bigPicture, bigPicture) ||
                other.bigPicture == bigPicture) &&
            (identical(other.conceptDefinition, conceptDefinition) ||
                other.conceptDefinition == conceptDefinition) &&
            (identical(other.firstMention, firstMention) ||
                other.firstMention == firstMention) &&
            const DeepCollectionEquality()
                .equals(other._definingPassages, _definingPassages) &&
            (identical(other.canonicalProgression, canonicalProgression) ||
                other.canonicalProgression == canonicalProgression) &&
            const DeepCollectionEquality()
                .equals(other._commonDistortions, _commonDistortions) &&
            (identical(
                    other.impliedTheologicalClaim, impliedTheologicalClaim) ||
                other.impliedTheologicalClaim == impliedTheologicalClaim) &&
            const DeepCollectionEquality()
                .equals(other._whatItCannotMean, _whatItCannotMean) &&
            (identical(other.fromTextToLife, fromTextToLife) ||
                other.fromTextToLife == fromTextToLife) &&
            (identical(other.somethingToSitWith, somethingToSitWith) ||
                other.somethingToSitWith == somethingToSitWith) &&
            (identical(other.contextSummary, contextSummary) ||
                other.contextSummary == contextSummary) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      source,
      subject,
      bigPicture,
      conceptDefinition,
      firstMention,
      const DeepCollectionEquality().hash(_definingPassages),
      canonicalProgression,
      const DeepCollectionEquality().hash(_commonDistortions),
      impliedTheologicalClaim,
      const DeepCollectionEquality().hash(_whatItCannotMean),
      fromTextToLife,
      somethingToSitWith,
      contextSummary,
      createdAt);

  /// Create a copy of TopicExegesis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopicExegesisImplCopyWith<_$TopicExegesisImpl> get copyWith =>
      __$$TopicExegesisImplCopyWithImpl<_$TopicExegesisImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopicExegesisImplToJson(
      this,
    );
  }
}

abstract class _TopicExegesis extends TopicExegesis {
  const factory _TopicExegesis(
      {required final String id,
      required final ExegesisSource source,
      required final String subject,
      required final String bigPicture,
      required final ConceptDefinition conceptDefinition,
      required final TopicFirstMention firstMention,
      final List<DefiningPassage> definingPassages,
      required final String canonicalProgression,
      final List<Distortion> commonDistortions,
      required final String impliedTheologicalClaim,
      final List<Misreading> whatItCannotMean,
      required final String fromTextToLife,
      required final String somethingToSitWith,
      final String? contextSummary,
      required final DateTime createdAt}) = _$TopicExegesisImpl;
  const _TopicExegesis._() : super._();

  factory _TopicExegesis.fromJson(Map<String, dynamic> json) =
      _$TopicExegesisImpl.fromJson;

  @override
  String get id;
  @override
  ExegesisSource get source;
  @override
  String get subject; // the topic name e.g. "Grace"
// ── Layer 1: The Orienting Insight ──
  @override
  String get bigPicture; // ── Concept Definition (Hebrew + Greek) ──
  @override
  ConceptDefinition get conceptDefinition; // ── First Mention ──
  @override
  TopicFirstMention get firstMention; // ── 3–5 Defining Passage Studies ──
  @override
  List<DefiningPassage> get definingPassages; // ── Canonical Progression ──
  @override
  String get canonicalProgression; // ── Common Distortions ──
  @override
  List<Distortion>
      get commonDistortions; // ── Layer 12: Implied Theological Claim ──
  @override
  String get impliedTheologicalClaim; // ── Layer 13: What This Cannot Mean ──
  @override
  List<Misreading> get whatItCannotMean; // ── Layer 14: From Text to Life ──
  @override
  String get fromTextToLife; // ── Final: Something To Sit With ──
  @override
  String get somethingToSitWith; // ── Metadata ──
  @override
  String? get contextSummary;
  @override
  DateTime get createdAt;

  /// Create a copy of TopicExegesis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopicExegesisImplCopyWith<_$TopicExegesisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
