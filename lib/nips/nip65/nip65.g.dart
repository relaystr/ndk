// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nip65.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetNip65Collection on Isar {
  IsarCollection<String, Nip65> get nip65s => this.collection();
}

const Nip65Schema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Nip65',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'urls',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'markers',
        type: IsarType.stringList,
        enumMap: {"readOnly": "r", "writeOnly": "w", "readWrite": "rw"},
      ),
      IsarPropertySchema(
        name: 'createdAt',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'id',
        type: IsarType.string,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<String, Nip65>(
    serialize: serializeNip65,
    deserialize: deserializeNip65,
    deserializeProperty: deserializeNip65Prop,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeNip65(IsarWriter writer, Nip65 object) {
  {
    final list = object.urls;
    final listWriter = IsarCore.beginList(writer, 1, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.markers;
    final listWriter = IsarCore.beginList(writer, 2, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i].asText);
    }
    IsarCore.endList(writer, listWriter);
  }
  IsarCore.writeLong(writer, 3, object.createdAt);
  IsarCore.writeString(writer, 4, object.id);
  return Isar.fastHash(object.id);
}

@isarProtected
Nip65 deserializeNip65(IsarReader reader) {
  final List<String> _urls;
  {
    final length = IsarCore.readList(reader, 1, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _urls = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        _urls = list;
      }
    }
  }
  final List<ReadWriteMarker> _markers;
  {
    final length = IsarCore.readList(reader, 2, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _markers = const <ReadWriteMarker>[];
      } else {
        final list = List<ReadWriteMarker>.filled(
            length, ReadWriteMarker.readOnly,
            growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = _nip65Markers[
                  IsarCore.readString(reader, i) ?? ReadWriteMarker.readOnly] ??
              ReadWriteMarker.readOnly;
        }
        IsarCore.freeReader(reader);
        _markers = list;
      }
    }
  }
  final object = Nip65(
    _urls,
    _markers,
  );
  object.createdAt = IsarCore.readLong(reader, 3);
  return object;
}

@isarProtected
dynamic deserializeNip65Prop(IsarReader reader, int property) {
  switch (property) {
    case 1:
      {
        final length = IsarCore.readList(reader, 1, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <String>[];
          } else {
            final list = List<String>.filled(length, '', growable: true);
            for (var i = 0; i < length; i++) {
              list[i] = IsarCore.readString(reader, i) ?? '';
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    case 2:
      {
        final length = IsarCore.readList(reader, 2, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <ReadWriteMarker>[];
          } else {
            final list = List<ReadWriteMarker>.filled(
                length, ReadWriteMarker.readOnly,
                growable: true);
            for (var i = 0; i < length; i++) {
              list[i] = _nip65Markers[IsarCore.readString(reader, i) ??
                      ReadWriteMarker.readOnly] ??
                  ReadWriteMarker.readOnly;
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      return IsarCore.readString(reader, 4) ?? '';
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _Nip65Update {
  bool call({
    required String id,
    int? createdAt,
  });
}

class _Nip65UpdateImpl implements _Nip65Update {
  const _Nip65UpdateImpl(this.collection);

  final IsarCollection<String, Nip65> collection;

  @override
  bool call({
    required String id,
    Object? createdAt = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (createdAt != ignore) 3: createdAt as int?,
        }) >
        0;
  }
}

sealed class _Nip65UpdateAll {
  int call({
    required List<String> id,
    int? createdAt,
  });
}

class _Nip65UpdateAllImpl implements _Nip65UpdateAll {
  const _Nip65UpdateAllImpl(this.collection);

  final IsarCollection<String, Nip65> collection;

  @override
  int call({
    required List<String> id,
    Object? createdAt = ignore,
  }) {
    return collection.updateProperties(id, {
      if (createdAt != ignore) 3: createdAt as int?,
    });
  }
}

extension Nip65Update on IsarCollection<String, Nip65> {
  _Nip65Update get update => _Nip65UpdateImpl(this);

  _Nip65UpdateAll get updateAll => _Nip65UpdateAllImpl(this);
}

sealed class _Nip65QueryUpdate {
  int call({
    int? createdAt,
  });
}

class _Nip65QueryUpdateImpl implements _Nip65QueryUpdate {
  const _Nip65QueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Nip65> query;
  final int? limit;

  @override
  int call({
    Object? createdAt = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (createdAt != ignore) 3: createdAt as int?,
    });
  }
}

extension Nip65QueryUpdate on IsarQuery<Nip65> {
  _Nip65QueryUpdate get updateFirst => _Nip65QueryUpdateImpl(this, limit: 1);

  _Nip65QueryUpdate get updateAll => _Nip65QueryUpdateImpl(this);
}

class _Nip65QueryBuilderUpdateImpl implements _Nip65QueryUpdate {
  const _Nip65QueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Nip65, Nip65, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? createdAt = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (createdAt != ignore) 3: createdAt as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension Nip65QueryBuilderUpdate on QueryBuilder<Nip65, Nip65, QOperations> {
  _Nip65QueryUpdate get updateFirst =>
      _Nip65QueryBuilderUpdateImpl(this, limit: 1);

  _Nip65QueryUpdate get updateAll => _Nip65QueryBuilderUpdateImpl(this);
}

const _nip65Markers = {
  r'r': ReadWriteMarker.readOnly,
  r'w': ReadWriteMarker.writeOnly,
  r'rw': ReadWriteMarker.readWrite,
};

extension Nip65QueryFilter on QueryBuilder<Nip65, Nip65, QFilterCondition> {
  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition>
      urlsElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition>
      urlsElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsIsEmpty() {
    return not().urlsIsNotEmpty();
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> urlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 1, value: null),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> markersElementEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> markersElementGreaterThan(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition>
      markersElementGreaterThanOrEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> markersElementLessThan(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition>
      markersElementLessThanOrEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> markersElementBetween(
    ReadWriteMarker lower,
    ReadWriteMarker upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower.asText,
          upper: upper.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> markersIsEmpty() {
    return not().markersIsNotEmpty();
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> markersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 2, value: null),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> createdAtEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> createdAtGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition>
      createdAtGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> createdAtLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> createdAtLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> createdAtBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }
}

extension Nip65QueryObject on QueryBuilder<Nip65, Nip65, QFilterCondition> {}

extension Nip65QuerySortBy on QueryBuilder<Nip65, Nip65, QSortBy> {
  QueryBuilder<Nip65, Nip65, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterSortBy> sortById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterSortBy> sortByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension Nip65QuerySortThenBy on QueryBuilder<Nip65, Nip65, QSortThenBy> {
  QueryBuilder<Nip65, Nip65, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterSortBy> thenById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterSortBy> thenByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension Nip65QueryWhereDistinct on QueryBuilder<Nip65, Nip65, QDistinct> {
  QueryBuilder<Nip65, Nip65, QAfterDistinct> distinctByUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterDistinct> distinctByMarkers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<Nip65, Nip65, QAfterDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }
}

extension Nip65QueryProperty1 on QueryBuilder<Nip65, Nip65, QProperty> {
  QueryBuilder<Nip65, List<String>, QAfterProperty> urlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Nip65, List<ReadWriteMarker>, QAfterProperty> markersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Nip65, int, QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Nip65, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension Nip65QueryProperty2<R> on QueryBuilder<Nip65, R, QAfterProperty> {
  QueryBuilder<Nip65, (R, List<String>), QAfterProperty> urlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Nip65, (R, List<ReadWriteMarker>), QAfterProperty>
      markersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Nip65, (R, int), QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Nip65, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension Nip65QueryProperty3<R1, R2>
    on QueryBuilder<Nip65, (R1, R2), QAfterProperty> {
  QueryBuilder<Nip65, (R1, R2, List<String>), QOperations> urlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Nip65, (R1, R2, List<ReadWriteMarker>), QOperations>
      markersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Nip65, (R1, R2, int), QOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Nip65, (R1, R2, String), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}
