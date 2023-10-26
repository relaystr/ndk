// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_relay_list.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetUserRelayListCollection on Isar {
  IsarCollection<String, UserRelayList> get userRelayLists => this.collection();
}

const UserRelayListSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'UserRelayList',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'id',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'createdAt',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'refreshedTimestamp',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'items',
        type: IsarType.objectList,
        target: 'RelayListItem',
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<String, UserRelayList>(
    serialize: serializeUserRelayList,
    deserialize: deserializeUserRelayList,
    deserializeProperty: deserializeUserRelayListProp,
  ),
  embeddedSchemas: [RelayListItemSchema],
);

@isarProtected
int serializeUserRelayList(IsarWriter writer, UserRelayList object) {
  IsarCore.writeString(writer, 1, object.id);
  IsarCore.writeLong(writer, 2, object.createdAt);
  IsarCore.writeLong(writer, 3, object.refreshedTimestamp);
  {
    final list = object.items;
    final listWriter = IsarCore.beginList(writer, 4, list.length);
    for (var i = 0; i < list.length; i++) {
      {
        final value = list[i];
        final objectWriter = IsarCore.beginObject(listWriter, i);
        serializeRelayListItem(objectWriter, value);
        IsarCore.endObject(listWriter, objectWriter);
      }
    }
    IsarCore.endList(writer, listWriter);
  }
  return Isar.fastHash(object.id);
}

@isarProtected
UserRelayList deserializeUserRelayList(IsarReader reader) {
  final String _id;
  _id = IsarCore.readString(reader, 1) ?? '';
  final List<RelayListItem> _items;
  {
    final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _items = const <RelayListItem>[];
      } else {
        final list = List<RelayListItem>.filled(
            length,
            RelayListItem(
              '',
              ReadWriteMarker.readOnly,
            ),
            growable: true);
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = RelayListItem(
                '',
                ReadWriteMarker.readOnly,
              );
            } else {
              final embedded = deserializeRelayListItem(objectReader);
              IsarCore.freeReader(objectReader);
              list[i] = embedded;
            }
          }
        }
        IsarCore.freeReader(reader);
        _items = list;
      }
    }
  }
  final int _createdAt;
  _createdAt = IsarCore.readLong(reader, 2);
  final int _refreshedTimestamp;
  _refreshedTimestamp = IsarCore.readLong(reader, 3);
  final object = UserRelayList(
    _id,
    _items,
    _createdAt,
    _refreshedTimestamp,
  );
  return object;
}

@isarProtected
dynamic deserializeUserRelayListProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readLong(reader, 2);
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      {
        final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <RelayListItem>[];
          } else {
            final list = List<RelayListItem>.filled(
                length,
                RelayListItem(
                  '',
                  ReadWriteMarker.readOnly,
                ),
                growable: true);
            for (var i = 0; i < length; i++) {
              {
                final objectReader = IsarCore.readObject(reader, i);
                if (objectReader.isNull) {
                  list[i] = RelayListItem(
                    '',
                    ReadWriteMarker.readOnly,
                  );
                } else {
                  final embedded = deserializeRelayListItem(objectReader);
                  IsarCore.freeReader(objectReader);
                  list[i] = embedded;
                }
              }
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _UserRelayListUpdate {
  bool call({
    required String id,
    int? createdAt,
    int? refreshedTimestamp,
  });
}

class _UserRelayListUpdateImpl implements _UserRelayListUpdate {
  const _UserRelayListUpdateImpl(this.collection);

  final IsarCollection<String, UserRelayList> collection;

  @override
  bool call({
    required String id,
    Object? createdAt = ignore,
    Object? refreshedTimestamp = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (createdAt != ignore) 2: createdAt as int?,
          if (refreshedTimestamp != ignore) 3: refreshedTimestamp as int?,
        }) >
        0;
  }
}

sealed class _UserRelayListUpdateAll {
  int call({
    required List<String> id,
    int? createdAt,
    int? refreshedTimestamp,
  });
}

class _UserRelayListUpdateAllImpl implements _UserRelayListUpdateAll {
  const _UserRelayListUpdateAllImpl(this.collection);

  final IsarCollection<String, UserRelayList> collection;

  @override
  int call({
    required List<String> id,
    Object? createdAt = ignore,
    Object? refreshedTimestamp = ignore,
  }) {
    return collection.updateProperties(id, {
      if (createdAt != ignore) 2: createdAt as int?,
      if (refreshedTimestamp != ignore) 3: refreshedTimestamp as int?,
    });
  }
}

extension UserRelayListUpdate on IsarCollection<String, UserRelayList> {
  _UserRelayListUpdate get update => _UserRelayListUpdateImpl(this);

  _UserRelayListUpdateAll get updateAll => _UserRelayListUpdateAllImpl(this);
}

sealed class _UserRelayListQueryUpdate {
  int call({
    int? createdAt,
    int? refreshedTimestamp,
  });
}

class _UserRelayListQueryUpdateImpl implements _UserRelayListQueryUpdate {
  const _UserRelayListQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<UserRelayList> query;
  final int? limit;

  @override
  int call({
    Object? createdAt = ignore,
    Object? refreshedTimestamp = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (createdAt != ignore) 2: createdAt as int?,
      if (refreshedTimestamp != ignore) 3: refreshedTimestamp as int?,
    });
  }
}

extension UserRelayListQueryUpdate on IsarQuery<UserRelayList> {
  _UserRelayListQueryUpdate get updateFirst =>
      _UserRelayListQueryUpdateImpl(this, limit: 1);

  _UserRelayListQueryUpdate get updateAll =>
      _UserRelayListQueryUpdateImpl(this);
}

class _UserRelayListQueryBuilderUpdateImpl
    implements _UserRelayListQueryUpdate {
  const _UserRelayListQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<UserRelayList, UserRelayList, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? createdAt = ignore,
    Object? refreshedTimestamp = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (createdAt != ignore) 2: createdAt as int?,
        if (refreshedTimestamp != ignore) 3: refreshedTimestamp as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension UserRelayListQueryBuilderUpdate
    on QueryBuilder<UserRelayList, UserRelayList, QOperations> {
  _UserRelayListQueryUpdate get updateFirst =>
      _UserRelayListQueryBuilderUpdateImpl(this, limit: 1);

  _UserRelayListQueryUpdate get updateAll =>
      _UserRelayListQueryBuilderUpdateImpl(this);
}

extension UserRelayListQueryFilter
    on QueryBuilder<UserRelayList, UserRelayList, QFilterCondition> {
  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      idLessThanOrEqualTo(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      idStartsWith(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition> idEndsWith(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition> idContains(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition> idMatches(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      createdAtEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      createdAtGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      createdAtGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      createdAtLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      createdAtLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      createdAtBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      refreshedTimestampEqualTo(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      refreshedTimestampGreaterThan(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      refreshedTimestampGreaterThanOrEqualTo(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      refreshedTimestampLessThan(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      refreshedTimestampLessThanOrEqualTo(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      refreshedTimestampBetween(
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

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      itemsIsEmpty() {
    return not().itemsIsNotEmpty();
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterFilterCondition>
      itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 4, value: null),
      );
    });
  }
}

extension UserRelayListQueryObject
    on QueryBuilder<UserRelayList, UserRelayList, QFilterCondition> {}

extension UserRelayListQuerySortBy
    on QueryBuilder<UserRelayList, UserRelayList, QSortBy> {
  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy> sortById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy> sortByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy>
      sortByRefreshedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy>
      sortByRefreshedTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }
}

extension UserRelayListQuerySortThenBy
    on QueryBuilder<UserRelayList, UserRelayList, QSortThenBy> {
  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy> thenById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy> thenByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy>
      thenByRefreshedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterSortBy>
      thenByRefreshedTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }
}

extension UserRelayListQueryWhereDistinct
    on QueryBuilder<UserRelayList, UserRelayList, QDistinct> {
  QueryBuilder<UserRelayList, UserRelayList, QAfterDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<UserRelayList, UserRelayList, QAfterDistinct>
      distinctByRefreshedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }
}

extension UserRelayListQueryProperty1
    on QueryBuilder<UserRelayList, UserRelayList, QProperty> {
  QueryBuilder<UserRelayList, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserRelayList, int, QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserRelayList, int, QAfterProperty>
      refreshedTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserRelayList, List<RelayListItem>, QAfterProperty>
      itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension UserRelayListQueryProperty2<R>
    on QueryBuilder<UserRelayList, R, QAfterProperty> {
  QueryBuilder<UserRelayList, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserRelayList, (R, int), QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserRelayList, (R, int), QAfterProperty>
      refreshedTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserRelayList, (R, List<RelayListItem>), QAfterProperty>
      itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension UserRelayListQueryProperty3<R1, R2>
    on QueryBuilder<UserRelayList, (R1, R2), QAfterProperty> {
  QueryBuilder<UserRelayList, (R1, R2, String), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserRelayList, (R1, R2, int), QOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserRelayList, (R1, R2, int), QOperations>
      refreshedTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserRelayList, (R1, R2, List<RelayListItem>), QOperations>
      itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

// **************************************************************************
// _IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

const RelayListItemSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'RelayListItem',
    embedded: true,
    properties: [
      IsarPropertySchema(
        name: 'url',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'marker',
        type: IsarType.byte,
        enumMap: {"readOnly": 0, "writeOnly": 1, "readWrite": 2},
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, RelayListItem>(
    serialize: serializeRelayListItem,
    deserialize: deserializeRelayListItem,
  ),
);

@isarProtected
int serializeRelayListItem(IsarWriter writer, RelayListItem object) {
  IsarCore.writeString(writer, 1, object.url);
  IsarCore.writeByte(writer, 2, object.marker.index);
  return 0;
}

@isarProtected
RelayListItem deserializeRelayListItem(IsarReader reader) {
  final String _url;
  _url = IsarCore.readString(reader, 1) ?? '';
  final ReadWriteMarker _marker;
  {
    if (IsarCore.readNull(reader, 2)) {
      _marker = ReadWriteMarker.readOnly;
    } else {
      _marker = _relayListItemMarker[IsarCore.readByte(reader, 2)] ??
          ReadWriteMarker.readOnly;
    }
  }
  final object = RelayListItem(
    _url,
    _marker,
  );
  return object;
}

const _relayListItemMarker = {
  0: ReadWriteMarker.readOnly,
  1: ReadWriteMarker.writeOnly,
  2: ReadWriteMarker.readWrite,
};

extension RelayListItemQueryFilter
    on QueryBuilder<RelayListItem, RelayListItem, QFilterCondition> {
  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition> urlEqualTo(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      urlGreaterThan(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      urlGreaterThanOrEqualTo(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition> urlLessThan(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      urlLessThanOrEqualTo(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition> urlBetween(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      urlStartsWith(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition> urlEndsWith(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition> urlContains(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition> urlMatches(
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

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      markerEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      markerGreaterThan(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      markerGreaterThanOrEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      markerLessThan(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      markerLessThanOrEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelayListItem, RelayListItem, QAfterFilterCondition>
      markerBetween(
    ReadWriteMarker lower,
    ReadWriteMarker upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }
}

extension RelayListItemQueryObject
    on QueryBuilder<RelayListItem, RelayListItem, QFilterCondition> {}
