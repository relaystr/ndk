// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_set.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetRelaySetCollection on Isar {
  IsarCollection<String, RelaySet> get relaySets => this.collection();
}

const RelaySetSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'RelaySet',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'name',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'pubKey',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'relayMinCountPerPubkey',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'direction',
        type: IsarType.byte,
        enumMap: {"inbox": 0, "outbox": 1},
      ),
      IsarPropertySchema(
        name: 'items',
        type: IsarType.objectList,
        target: 'RelaySetItem',
      ),
      IsarPropertySchema(
        name: 'notCoveredPubkeys',
        type: IsarType.objectList,
        target: 'NotCoveredPubKey',
      ),
      IsarPropertySchema(
        name: 'id',
        type: IsarType.string,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<String, RelaySet>(
    serialize: serializeRelaySet,
    deserialize: deserializeRelaySet,
    deserializeProperty: deserializeRelaySetProp,
  ),
  embeddedSchemas: [
    RelaySetItemSchema,
    PubkeyMappingSchema,
    NotCoveredPubKeySchema
  ],
);

@isarProtected
int serializeRelaySet(IsarWriter writer, RelaySet object) {
  IsarCore.writeString(writer, 1, object.name);
  IsarCore.writeString(writer, 2, object.pubKey);
  IsarCore.writeLong(writer, 3, object.relayMinCountPerPubkey);
  IsarCore.writeByte(writer, 4, object.direction.index);
  {
    final list = object.items;
    final listWriter = IsarCore.beginList(writer, 5, list.length);
    for (var i = 0; i < list.length; i++) {
      {
        final value = list[i];
        final objectWriter = IsarCore.beginObject(listWriter, i);
        serializeRelaySetItem(objectWriter, value);
        IsarCore.endObject(listWriter, objectWriter);
      }
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.notCoveredPubkeys;
    final listWriter = IsarCore.beginList(writer, 6, list.length);
    for (var i = 0; i < list.length; i++) {
      {
        final value = list[i];
        final objectWriter = IsarCore.beginObject(listWriter, i);
        serializeNotCoveredPubKey(objectWriter, value);
        IsarCore.endObject(listWriter, objectWriter);
      }
    }
    IsarCore.endList(writer, listWriter);
  }
  IsarCore.writeString(writer, 7, object.id);
  return Isar.fastHash(object.id);
}

@isarProtected
RelaySet deserializeRelaySet(IsarReader reader) {
  final int _relayMinCountPerPubkey;
  _relayMinCountPerPubkey = IsarCore.readLong(reader, 3);
  final RelayDirection _direction;
  {
    if (IsarCore.readNull(reader, 4)) {
      _direction = RelayDirection.inbox;
    } else {
      _direction = _relaySetDirection[IsarCore.readByte(reader, 4)] ??
          RelayDirection.inbox;
    }
  }
  final List<RelaySetItem> _items;
  {
    final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _items = const <RelaySetItem>[];
      } else {
        final list = List<RelaySetItem>.filled(
            length,
            RelaySetItem(
              '',
              const <PubkeyMapping>[],
            ),
            growable: true);
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = RelaySetItem(
                '',
                const <PubkeyMapping>[],
              );
            } else {
              final embedded = deserializeRelaySetItem(objectReader);
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
  final List<NotCoveredPubKey> _notCoveredPubkeys;
  {
    final length = IsarCore.readList(reader, 6, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _notCoveredPubkeys = const <NotCoveredPubKey>[];
      } else {
        final list = List<NotCoveredPubKey>.filled(
            length,
            NotCoveredPubKey(
              '',
              -9223372036854775808,
            ),
            growable: true);
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = NotCoveredPubKey(
                '',
                -9223372036854775808,
              );
            } else {
              final embedded = deserializeNotCoveredPubKey(objectReader);
              IsarCore.freeReader(objectReader);
              list[i] = embedded;
            }
          }
        }
        IsarCore.freeReader(reader);
        _notCoveredPubkeys = list;
      }
    }
  }
  final object = RelaySet(
    relayMinCountPerPubkey: _relayMinCountPerPubkey,
    direction: _direction,
    items: _items,
    notCoveredPubkeys: _notCoveredPubkeys,
  );
  object.name = IsarCore.readString(reader, 1) ?? '';
  object.pubKey = IsarCore.readString(reader, 2) ?? '';
  return object;
}

@isarProtected
dynamic deserializeRelaySetProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      {
        if (IsarCore.readNull(reader, 4)) {
          return RelayDirection.inbox;
        } else {
          return _relaySetDirection[IsarCore.readByte(reader, 4)] ??
              RelayDirection.inbox;
        }
      }
    case 5:
      {
        final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <RelaySetItem>[];
          } else {
            final list = List<RelaySetItem>.filled(
                length,
                RelaySetItem(
                  '',
                  const <PubkeyMapping>[],
                ),
                growable: true);
            for (var i = 0; i < length; i++) {
              {
                final objectReader = IsarCore.readObject(reader, i);
                if (objectReader.isNull) {
                  list[i] = RelaySetItem(
                    '',
                    const <PubkeyMapping>[],
                  );
                } else {
                  final embedded = deserializeRelaySetItem(objectReader);
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
    case 6:
      {
        final length = IsarCore.readList(reader, 6, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <NotCoveredPubKey>[];
          } else {
            final list = List<NotCoveredPubKey>.filled(
                length,
                NotCoveredPubKey(
                  '',
                  -9223372036854775808,
                ),
                growable: true);
            for (var i = 0; i < length; i++) {
              {
                final objectReader = IsarCore.readObject(reader, i);
                if (objectReader.isNull) {
                  list[i] = NotCoveredPubKey(
                    '',
                    -9223372036854775808,
                  );
                } else {
                  final embedded = deserializeNotCoveredPubKey(objectReader);
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
    case 7:
      return IsarCore.readString(reader, 7) ?? '';
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _RelaySetUpdate {
  bool call({
    required String id,
    String? name,
    String? pubKey,
    int? relayMinCountPerPubkey,
    RelayDirection? direction,
  });
}

class _RelaySetUpdateImpl implements _RelaySetUpdate {
  const _RelaySetUpdateImpl(this.collection);

  final IsarCollection<String, RelaySet> collection;

  @override
  bool call({
    required String id,
    Object? name = ignore,
    Object? pubKey = ignore,
    Object? relayMinCountPerPubkey = ignore,
    Object? direction = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (name != ignore) 1: name as String?,
          if (pubKey != ignore) 2: pubKey as String?,
          if (relayMinCountPerPubkey != ignore)
            3: relayMinCountPerPubkey as int?,
          if (direction != ignore) 4: direction as RelayDirection?,
        }) >
        0;
  }
}

sealed class _RelaySetUpdateAll {
  int call({
    required List<String> id,
    String? name,
    String? pubKey,
    int? relayMinCountPerPubkey,
    RelayDirection? direction,
  });
}

class _RelaySetUpdateAllImpl implements _RelaySetUpdateAll {
  const _RelaySetUpdateAllImpl(this.collection);

  final IsarCollection<String, RelaySet> collection;

  @override
  int call({
    required List<String> id,
    Object? name = ignore,
    Object? pubKey = ignore,
    Object? relayMinCountPerPubkey = ignore,
    Object? direction = ignore,
  }) {
    return collection.updateProperties(id, {
      if (name != ignore) 1: name as String?,
      if (pubKey != ignore) 2: pubKey as String?,
      if (relayMinCountPerPubkey != ignore) 3: relayMinCountPerPubkey as int?,
      if (direction != ignore) 4: direction as RelayDirection?,
    });
  }
}

extension RelaySetUpdate on IsarCollection<String, RelaySet> {
  _RelaySetUpdate get update => _RelaySetUpdateImpl(this);

  _RelaySetUpdateAll get updateAll => _RelaySetUpdateAllImpl(this);
}

sealed class _RelaySetQueryUpdate {
  int call({
    String? name,
    String? pubKey,
    int? relayMinCountPerPubkey,
    RelayDirection? direction,
  });
}

class _RelaySetQueryUpdateImpl implements _RelaySetQueryUpdate {
  const _RelaySetQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<RelaySet> query;
  final int? limit;

  @override
  int call({
    Object? name = ignore,
    Object? pubKey = ignore,
    Object? relayMinCountPerPubkey = ignore,
    Object? direction = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (name != ignore) 1: name as String?,
      if (pubKey != ignore) 2: pubKey as String?,
      if (relayMinCountPerPubkey != ignore) 3: relayMinCountPerPubkey as int?,
      if (direction != ignore) 4: direction as RelayDirection?,
    });
  }
}

extension RelaySetQueryUpdate on IsarQuery<RelaySet> {
  _RelaySetQueryUpdate get updateFirst =>
      _RelaySetQueryUpdateImpl(this, limit: 1);

  _RelaySetQueryUpdate get updateAll => _RelaySetQueryUpdateImpl(this);
}

class _RelaySetQueryBuilderUpdateImpl implements _RelaySetQueryUpdate {
  const _RelaySetQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<RelaySet, RelaySet, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? name = ignore,
    Object? pubKey = ignore,
    Object? relayMinCountPerPubkey = ignore,
    Object? direction = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (name != ignore) 1: name as String?,
        if (pubKey != ignore) 2: pubKey as String?,
        if (relayMinCountPerPubkey != ignore) 3: relayMinCountPerPubkey as int?,
        if (direction != ignore) 4: direction as RelayDirection?,
      });
    } finally {
      q.close();
    }
  }
}

extension RelaySetQueryBuilderUpdate
    on QueryBuilder<RelaySet, RelaySet, QOperations> {
  _RelaySetQueryUpdate get updateFirst =>
      _RelaySetQueryBuilderUpdateImpl(this, limit: 1);

  _RelaySetQueryUpdate get updateAll => _RelaySetQueryBuilderUpdateImpl(this);
}

const _relaySetDirection = {
  0: RelayDirection.inbox,
  1: RelayDirection.outbox,
};

extension RelaySetQueryFilter
    on QueryBuilder<RelaySet, RelaySet, QFilterCondition> {
  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      nameGreaterThanOrEqualTo(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameLessThanOrEqualTo(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameContains(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      pubKeyGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      pubKeyLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> pubKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      relayMinCountPerPubkeyEqualTo(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      relayMinCountPerPubkeyGreaterThan(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      relayMinCountPerPubkeyGreaterThanOrEqualTo(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      relayMinCountPerPubkeyLessThan(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      relayMinCountPerPubkeyLessThanOrEqualTo(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      relayMinCountPerPubkeyBetween(
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

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> directionEqualTo(
    RelayDirection value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> directionGreaterThan(
    RelayDirection value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      directionGreaterThanOrEqualTo(
    RelayDirection value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> directionLessThan(
    RelayDirection value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      directionLessThanOrEqualTo(
    RelayDirection value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> directionBetween(
    RelayDirection lower,
    RelayDirection upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> itemsIsEmpty() {
    return not().itemsIsNotEmpty();
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 5, value: null),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      notCoveredPubkeysIsEmpty() {
    return not().notCoveredPubkeysIsNotEmpty();
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      notCoveredPubkeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 6, value: null),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 7,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 7,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 7,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 7,
          value: '',
        ),
      );
    });
  }
}

extension RelaySetQueryObject
    on QueryBuilder<RelaySet, RelaySet, QFilterCondition> {}

extension RelaySetQuerySortBy on QueryBuilder<RelaySet, RelaySet, QSortBy> {
  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> sortByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> sortByNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> sortByPubKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> sortByPubKeyDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy>
      sortByRelayMinCountPerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy>
      sortByRelayMinCountPerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> sortByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> sortByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> sortById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        7,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> sortByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        7,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension RelaySetQuerySortThenBy
    on QueryBuilder<RelaySet, RelaySet, QSortThenBy> {
  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> thenByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> thenByNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> thenByPubKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> thenByPubKeyDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy>
      thenByRelayMinCountPerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy>
      thenByRelayMinCountPerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> thenByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> thenByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> thenById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterSortBy> thenByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension RelaySetQueryWhereDistinct
    on QueryBuilder<RelaySet, RelaySet, QDistinct> {
  QueryBuilder<RelaySet, RelaySet, QAfterDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterDistinct> distinctByPubKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterDistinct>
      distinctByRelayMinCountPerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<RelaySet, RelaySet, QAfterDistinct> distinctByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }
}

extension RelaySetQueryProperty1
    on QueryBuilder<RelaySet, RelaySet, QProperty> {
  QueryBuilder<RelaySet, String, QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<RelaySet, String, QAfterProperty> pubKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<RelaySet, int, QAfterProperty> relayMinCountPerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<RelaySet, RelayDirection, QAfterProperty> directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<RelaySet, List<RelaySetItem>, QAfterProperty> itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<RelaySet, List<NotCoveredPubKey>, QAfterProperty>
      notCoveredPubkeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<RelaySet, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }
}

extension RelaySetQueryProperty2<R>
    on QueryBuilder<RelaySet, R, QAfterProperty> {
  QueryBuilder<RelaySet, (R, String), QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<RelaySet, (R, String), QAfterProperty> pubKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<RelaySet, (R, int), QAfterProperty>
      relayMinCountPerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<RelaySet, (R, RelayDirection), QAfterProperty>
      directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<RelaySet, (R, List<RelaySetItem>), QAfterProperty>
      itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<RelaySet, (R, List<NotCoveredPubKey>), QAfterProperty>
      notCoveredPubkeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<RelaySet, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }
}

extension RelaySetQueryProperty3<R1, R2>
    on QueryBuilder<RelaySet, (R1, R2), QAfterProperty> {
  QueryBuilder<RelaySet, (R1, R2, String), QOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<RelaySet, (R1, R2, String), QOperations> pubKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<RelaySet, (R1, R2, int), QOperations>
      relayMinCountPerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<RelaySet, (R1, R2, RelayDirection), QOperations>
      directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<RelaySet, (R1, R2, List<RelaySetItem>), QOperations>
      itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<RelaySet, (R1, R2, List<NotCoveredPubKey>), QOperations>
      notCoveredPubkeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<RelaySet, (R1, R2, String), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }
}

// **************************************************************************
// _IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

const RelaySetItemSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'RelaySetItem',
    embedded: true,
    properties: [
      IsarPropertySchema(
        name: 'url',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'pubKeyMappings',
        type: IsarType.objectList,
        target: 'PubkeyMapping',
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, RelaySetItem>(
    serialize: serializeRelaySetItem,
    deserialize: deserializeRelaySetItem,
  ),
);

@isarProtected
int serializeRelaySetItem(IsarWriter writer, RelaySetItem object) {
  IsarCore.writeString(writer, 1, object.url);
  {
    final list = object.pubKeyMappings;
    final listWriter = IsarCore.beginList(writer, 2, list.length);
    for (var i = 0; i < list.length; i++) {
      {
        final value = list[i];
        final objectWriter = IsarCore.beginObject(listWriter, i);
        serializePubkeyMapping(objectWriter, value);
        IsarCore.endObject(listWriter, objectWriter);
      }
    }
    IsarCore.endList(writer, listWriter);
  }
  return 0;
}

@isarProtected
RelaySetItem deserializeRelaySetItem(IsarReader reader) {
  final String _url;
  _url = IsarCore.readString(reader, 1) ?? '';
  final List<PubkeyMapping> _pubKeyMappings;
  {
    final length = IsarCore.readList(reader, 2, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _pubKeyMappings = const <PubkeyMapping>[];
      } else {
        final list = List<PubkeyMapping>.filled(
            length,
            PubkeyMapping(
              pubKey: '',
              rwMarker: ReadWriteMarker.readOnly,
            ),
            growable: true);
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = PubkeyMapping(
                pubKey: '',
                rwMarker: ReadWriteMarker.readOnly,
              );
            } else {
              final embedded = deserializePubkeyMapping(objectReader);
              IsarCore.freeReader(objectReader);
              list[i] = embedded;
            }
          }
        }
        IsarCore.freeReader(reader);
        _pubKeyMappings = list;
      }
    }
  }
  final object = RelaySetItem(
    _url,
    _pubKeyMappings,
  );
  return object;
}

extension RelaySetItemQueryFilter
    on QueryBuilder<RelaySetItem, RelaySetItem, QFilterCondition> {
  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition> urlEqualTo(
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition> urlLessThan(
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition> urlBetween(
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition> urlStartsWith(
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition> urlEndsWith(
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition> urlContains(
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition> urlMatches(
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition>
      pubKeyMappingsIsEmpty() {
    return not().pubKeyMappingsIsNotEmpty();
  }

  QueryBuilder<RelaySetItem, RelaySetItem, QAfterFilterCondition>
      pubKeyMappingsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 2, value: null),
      );
    });
  }
}

extension RelaySetItemQueryObject
    on QueryBuilder<RelaySetItem, RelaySetItem, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

const NotCoveredPubKeySchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'NotCoveredPubKey',
    embedded: true,
    properties: [
      IsarPropertySchema(
        name: 'pubKey',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'coverage',
        type: IsarType.long,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, NotCoveredPubKey>(
    serialize: serializeNotCoveredPubKey,
    deserialize: deserializeNotCoveredPubKey,
  ),
);

@isarProtected
int serializeNotCoveredPubKey(IsarWriter writer, NotCoveredPubKey object) {
  IsarCore.writeString(writer, 1, object.pubKey);
  IsarCore.writeLong(writer, 2, object.coverage);
  return 0;
}

@isarProtected
NotCoveredPubKey deserializeNotCoveredPubKey(IsarReader reader) {
  final String _pubKey;
  _pubKey = IsarCore.readString(reader, 1) ?? '';
  final int _coverage;
  _coverage = IsarCore.readLong(reader, 2);
  final object = NotCoveredPubKey(
    _pubKey,
    _coverage,
  );
  return object;
}

extension NotCoveredPubKeyQueryFilter
    on QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QFilterCondition> {
  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyEqualTo(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyGreaterThan(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyGreaterThanOrEqualTo(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyLessThan(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyLessThanOrEqualTo(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyBetween(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyStartsWith(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyEndsWith(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      pubKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      coverageEqualTo(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      coverageGreaterThan(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      coverageGreaterThanOrEqualTo(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      coverageLessThan(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      coverageLessThanOrEqualTo(
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

  QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QAfterFilterCondition>
      coverageBetween(
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
}

extension NotCoveredPubKeyQueryObject
    on QueryBuilder<NotCoveredPubKey, NotCoveredPubKey, QFilterCondition> {}
