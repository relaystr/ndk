// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_list.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetNip02ContactListCollection on Isar {
  IsarCollection<String, Nip02ContactList> get nip02ContactLists =>
      this.collection();
}

const Nip02ContactListSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Nip02ContactList',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'contacts',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'contactRelays',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'petnames',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'followedTags',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'followedCommunities',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'followedEvents',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'relaysInContent',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'markersInContent',
        type: IsarType.stringList,
        enumMap: {"readOnly": "r", "writeOnly": "w", "readWrite": "rw"},
      ),
      IsarPropertySchema(
        name: 'createdAt',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'loadedTimestamp',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'sources',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'id',
        type: IsarType.string,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<String, Nip02ContactList>(
    serialize: serializeNip02ContactList,
    deserialize: deserializeNip02ContactList,
    deserializeProperty: deserializeNip02ContactListProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeNip02ContactList(IsarWriter writer, Nip02ContactList object) {
  {
    final list = object.contacts;
    final listWriter = IsarCore.beginList(writer, 1, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.contactRelays;
    final listWriter = IsarCore.beginList(writer, 2, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.petnames;
    final listWriter = IsarCore.beginList(writer, 3, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.followedTags;
    final listWriter = IsarCore.beginList(writer, 4, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.followedCommunities;
    final listWriter = IsarCore.beginList(writer, 5, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.followedEvents;
    final listWriter = IsarCore.beginList(writer, 6, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.relaysInContent;
    final listWriter = IsarCore.beginList(writer, 7, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final list = object.markersInContent;
    final listWriter = IsarCore.beginList(writer, 8, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i].asText);
    }
    IsarCore.endList(writer, listWriter);
  }
  IsarCore.writeLong(writer, 9, object.createdAt);
  IsarCore.writeLong(
      writer, 10, object.loadedTimestamp ?? -9223372036854775808);
  {
    final list = object.sources;
    final listWriter = IsarCore.beginList(writer, 11, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  IsarCore.writeString(writer, 12, object.id);
  return Isar.fastHash(object.id);
}

@isarProtected
Nip02ContactList deserializeNip02ContactList(IsarReader reader) {
  final object = Nip02ContactList();
  {
    final length = IsarCore.readList(reader, 1, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.contacts = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.contacts = list;
      }
    }
  }
  {
    final length = IsarCore.readList(reader, 2, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.contactRelays = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.contactRelays = list;
      }
    }
  }
  {
    final length = IsarCore.readList(reader, 3, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.petnames = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.petnames = list;
      }
    }
  }
  {
    final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.followedTags = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.followedTags = list;
      }
    }
  }
  {
    final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.followedCommunities = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.followedCommunities = list;
      }
    }
  }
  {
    final length = IsarCore.readList(reader, 6, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.followedEvents = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.followedEvents = list;
      }
    }
  }
  {
    final length = IsarCore.readList(reader, 7, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.relaysInContent = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.relaysInContent = list;
      }
    }
  }
  {
    final length = IsarCore.readList(reader, 8, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.markersInContent = const <ReadWriteMarker>[];
      } else {
        final list = List<ReadWriteMarker>.filled(
            length, ReadWriteMarker.readOnly,
            growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = _nip02ContactListMarkersInContent[
                  IsarCore.readString(reader, i) ?? ReadWriteMarker.readOnly] ??
              ReadWriteMarker.readOnly;
        }
        IsarCore.freeReader(reader);
        object.markersInContent = list;
      }
    }
  }
  object.createdAt = IsarCore.readLong(reader, 9);
  {
    final value = IsarCore.readLong(reader, 10);
    if (value == -9223372036854775808) {
      object.loadedTimestamp = null;
    } else {
      object.loadedTimestamp = value;
    }
  }
  {
    final length = IsarCore.readList(reader, 11, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        object.sources = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        object.sources = list;
      }
    }
  }
  return object;
}

@isarProtected
dynamic deserializeNip02ContactListProp(IsarReader reader, int property) {
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
    case 3:
      {
        final length = IsarCore.readList(reader, 3, IsarCore.readerPtrPtr);
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
    case 4:
      {
        final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
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
    case 5:
      {
        final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
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
    case 6:
      {
        final length = IsarCore.readList(reader, 6, IsarCore.readerPtrPtr);
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
    case 7:
      {
        final length = IsarCore.readList(reader, 7, IsarCore.readerPtrPtr);
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
    case 8:
      {
        final length = IsarCore.readList(reader, 8, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <ReadWriteMarker>[];
          } else {
            final list = List<ReadWriteMarker>.filled(
                length, ReadWriteMarker.readOnly,
                growable: true);
            for (var i = 0; i < length; i++) {
              list[i] = _nip02ContactListMarkersInContent[
                      IsarCore.readString(reader, i) ??
                          ReadWriteMarker.readOnly] ??
                  ReadWriteMarker.readOnly;
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    case 9:
      return IsarCore.readLong(reader, 9);
    case 10:
      {
        final value = IsarCore.readLong(reader, 10);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 11:
      {
        final length = IsarCore.readList(reader, 11, IsarCore.readerPtrPtr);
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
    case 12:
      return IsarCore.readString(reader, 12) ?? '';
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _Nip02ContactListUpdate {
  bool call({
    required String id,
    int? createdAt,
    int? loadedTimestamp,
  });
}

class _Nip02ContactListUpdateImpl implements _Nip02ContactListUpdate {
  const _Nip02ContactListUpdateImpl(this.collection);

  final IsarCollection<String, Nip02ContactList> collection;

  @override
  bool call({
    required String id,
    Object? createdAt = ignore,
    Object? loadedTimestamp = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (createdAt != ignore) 9: createdAt as int?,
          if (loadedTimestamp != ignore) 10: loadedTimestamp as int?,
        }) >
        0;
  }
}

sealed class _Nip02ContactListUpdateAll {
  int call({
    required List<String> id,
    int? createdAt,
    int? loadedTimestamp,
  });
}

class _Nip02ContactListUpdateAllImpl implements _Nip02ContactListUpdateAll {
  const _Nip02ContactListUpdateAllImpl(this.collection);

  final IsarCollection<String, Nip02ContactList> collection;

  @override
  int call({
    required List<String> id,
    Object? createdAt = ignore,
    Object? loadedTimestamp = ignore,
  }) {
    return collection.updateProperties(id, {
      if (createdAt != ignore) 9: createdAt as int?,
      if (loadedTimestamp != ignore) 10: loadedTimestamp as int?,
    });
  }
}

extension Nip02ContactListUpdate on IsarCollection<String, Nip02ContactList> {
  _Nip02ContactListUpdate get update => _Nip02ContactListUpdateImpl(this);

  _Nip02ContactListUpdateAll get updateAll =>
      _Nip02ContactListUpdateAllImpl(this);
}

sealed class _Nip02ContactListQueryUpdate {
  int call({
    int? createdAt,
    int? loadedTimestamp,
  });
}

class _Nip02ContactListQueryUpdateImpl implements _Nip02ContactListQueryUpdate {
  const _Nip02ContactListQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Nip02ContactList> query;
  final int? limit;

  @override
  int call({
    Object? createdAt = ignore,
    Object? loadedTimestamp = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (createdAt != ignore) 9: createdAt as int?,
      if (loadedTimestamp != ignore) 10: loadedTimestamp as int?,
    });
  }
}

extension Nip02ContactListQueryUpdate on IsarQuery<Nip02ContactList> {
  _Nip02ContactListQueryUpdate get updateFirst =>
      _Nip02ContactListQueryUpdateImpl(this, limit: 1);

  _Nip02ContactListQueryUpdate get updateAll =>
      _Nip02ContactListQueryUpdateImpl(this);
}

class _Nip02ContactListQueryBuilderUpdateImpl
    implements _Nip02ContactListQueryUpdate {
  const _Nip02ContactListQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Nip02ContactList, Nip02ContactList, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? createdAt = ignore,
    Object? loadedTimestamp = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (createdAt != ignore) 9: createdAt as int?,
        if (loadedTimestamp != ignore) 10: loadedTimestamp as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension Nip02ContactListQueryBuilderUpdate
    on QueryBuilder<Nip02ContactList, Nip02ContactList, QOperations> {
  _Nip02ContactListQueryUpdate get updateFirst =>
      _Nip02ContactListQueryBuilderUpdateImpl(this, limit: 1);

  _Nip02ContactListQueryUpdate get updateAll =>
      _Nip02ContactListQueryBuilderUpdateImpl(this);
}

const _nip02ContactListMarkersInContent = {
  r'r': ReadWriteMarker.readOnly,
  r'w': ReadWriteMarker.writeOnly,
  r'rw': ReadWriteMarker.readWrite,
};

extension Nip02ContactListQueryFilter
    on QueryBuilder<Nip02ContactList, Nip02ContactList, QFilterCondition> {
  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementGreaterThan(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementGreaterThanOrEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementLessThan(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementLessThanOrEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementBetween(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementStartsWith(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementEndsWith(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsIsEmpty() {
    return not().contactsIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 1, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementGreaterThan(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementGreaterThanOrEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementLessThan(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementLessThanOrEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementBetween(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementStartsWith(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementEndsWith(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysIsEmpty() {
    return not().contactRelaysIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      contactRelaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 2, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesIsEmpty() {
    return not().petnamesIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      petnamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 3, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementGreaterThan(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementGreaterThanOrEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementLessThan(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementLessThanOrEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementBetween(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementStartsWith(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementEndsWith(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsIsEmpty() {
    return not().followedTagsIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 4, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesIsEmpty() {
    return not().followedCommunitiesIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedCommunitiesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 5, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 6,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 6,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 6,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 6,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsIsEmpty() {
    return not().followedEventsIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      followedEventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 6, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementGreaterThan(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementGreaterThanOrEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementLessThan(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementLessThanOrEqualTo(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementBetween(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementStartsWith(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementEndsWith(
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementContains(String value,
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementMatches(String pattern,
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

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 7,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 7,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentIsEmpty() {
    return not().relaysInContentIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      relaysInContentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 7, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      markersInContentElementEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 8,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      markersInContentElementGreaterThan(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      markersInContentElementGreaterThanOrEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      markersInContentElementLessThan(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 8,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      markersInContentElementLessThanOrEqualTo(
    ReadWriteMarker value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
          value: value.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      markersInContentElementBetween(
    ReadWriteMarker lower,
    ReadWriteMarker upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
          lower: lower.asText,
          upper: upper.asText,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      markersInContentIsEmpty() {
    return not().markersInContentIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      markersInContentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 8, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      createdAtEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      createdAtGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      createdAtGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      createdAtLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      createdAtLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      createdAtBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 9,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      loadedTimestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      loadedTimestampIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      loadedTimestampEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      loadedTimestampGreaterThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      loadedTimestampGreaterThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      loadedTimestampLessThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      loadedTimestampLessThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      loadedTimestampBetween(
    int? lower,
    int? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 10,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 11,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 11,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 11,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 11,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesIsEmpty() {
    return not().sourcesIsNotEmpty();
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      sourcesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 11, value: null),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 12,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 12,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 12,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 12,
          value: '',
        ),
      );
    });
  }
}

extension Nip02ContactListQueryObject
    on QueryBuilder<Nip02ContactList, Nip02ContactList, QFilterCondition> {}

extension Nip02ContactListQuerySortBy
    on QueryBuilder<Nip02ContactList, Nip02ContactList, QSortBy> {
  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy>
      sortByLoadedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy>
      sortByLoadedTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy> sortById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        12,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy> sortByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        12,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension Nip02ContactListQuerySortThenBy
    on QueryBuilder<Nip02ContactList, Nip02ContactList, QSortThenBy> {
  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy>
      thenByLoadedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy>
      thenByLoadedTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy> thenById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterSortBy> thenByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension Nip02ContactListQueryWhereDistinct
    on QueryBuilder<Nip02ContactList, Nip02ContactList, QDistinct> {
  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByContacts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByContactRelays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByPetnames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByFollowedTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByFollowedCommunities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByFollowedEvents() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByRelaysInContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByMarkersInContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(9);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctByLoadedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(10);
    });
  }

  QueryBuilder<Nip02ContactList, Nip02ContactList, QAfterDistinct>
      distinctBySources() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(11);
    });
  }
}

extension Nip02ContactListQueryProperty1
    on QueryBuilder<Nip02ContactList, Nip02ContactList, QProperty> {
  QueryBuilder<Nip02ContactList, List<String>, QAfterProperty>
      contactsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Nip02ContactList, List<String>, QAfterProperty>
      contactRelaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Nip02ContactList, List<String>, QAfterProperty>
      petnamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Nip02ContactList, List<String>, QAfterProperty>
      followedTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Nip02ContactList, List<String>, QAfterProperty>
      followedCommunitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Nip02ContactList, List<String>, QAfterProperty>
      followedEventsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Nip02ContactList, List<String>, QAfterProperty>
      relaysInContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<Nip02ContactList, List<ReadWriteMarker>, QAfterProperty>
      markersInContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<Nip02ContactList, int, QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<Nip02ContactList, int?, QAfterProperty>
      loadedTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<Nip02ContactList, List<String>, QAfterProperty>
      sourcesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<Nip02ContactList, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }
}

extension Nip02ContactListQueryProperty2<R>
    on QueryBuilder<Nip02ContactList, R, QAfterProperty> {
  QueryBuilder<Nip02ContactList, (R, List<String>), QAfterProperty>
      contactsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Nip02ContactList, (R, List<String>), QAfterProperty>
      contactRelaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Nip02ContactList, (R, List<String>), QAfterProperty>
      petnamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Nip02ContactList, (R, List<String>), QAfterProperty>
      followedTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Nip02ContactList, (R, List<String>), QAfterProperty>
      followedCommunitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Nip02ContactList, (R, List<String>), QAfterProperty>
      followedEventsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Nip02ContactList, (R, List<String>), QAfterProperty>
      relaysInContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<Nip02ContactList, (R, List<ReadWriteMarker>), QAfterProperty>
      markersInContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<Nip02ContactList, (R, int), QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<Nip02ContactList, (R, int?), QAfterProperty>
      loadedTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<Nip02ContactList, (R, List<String>), QAfterProperty>
      sourcesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<Nip02ContactList, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }
}

extension Nip02ContactListQueryProperty3<R1, R2>
    on QueryBuilder<Nip02ContactList, (R1, R2), QAfterProperty> {
  QueryBuilder<Nip02ContactList, (R1, R2, List<String>), QOperations>
      contactsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, List<String>), QOperations>
      contactRelaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, List<String>), QOperations>
      petnamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, List<String>), QOperations>
      followedTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, List<String>), QOperations>
      followedCommunitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, List<String>), QOperations>
      followedEventsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, List<String>), QOperations>
      relaysInContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, List<ReadWriteMarker>), QOperations>
      markersInContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, int), QOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, int?), QOperations>
      loadedTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, List<String>), QOperations>
      sourcesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<Nip02ContactList, (R1, R2, String), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }
}
