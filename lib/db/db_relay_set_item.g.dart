// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_relay_set_item.dart';

// **************************************************************************
// _IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

const DbRelaySetItemSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'DbRelaySetItem',
    embedded: true,
    properties: [
      IsarPropertySchema(
        name: 'url',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'pubKeyMappings',
        type: IsarType.objectList,
        target: 'DbPubkeyMapping',
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, DbRelaySetItem>(
    serialize: serializeDbRelaySetItem,
    deserialize: deserializeDbRelaySetItem,
  ),
);

@isarProtected
int serializeDbRelaySetItem(IsarWriter writer, DbRelaySetItem object) {
  IsarCore.writeString(writer, 1, object.url);
  {
    final list = object.pubKeyMappings;
    final listWriter = IsarCore.beginList(writer, 2, list.length);
    for (var i = 0; i < list.length; i++) {
      {
        final value = list[i];
        final objectWriter = IsarCore.beginObject(listWriter, i);
        serializeDbPubkeyMapping(objectWriter, value);
        IsarCore.endObject(listWriter, objectWriter);
      }
    }
    IsarCore.endList(writer, listWriter);
  }
  return 0;
}

@isarProtected
DbRelaySetItem deserializeDbRelaySetItem(IsarReader reader) {
  final String _url;
  _url = IsarCore.readString(reader, 1) ?? '';
  final List<DbPubkeyMapping> _pubKeyMappings;
  {
    final length = IsarCore.readList(reader, 2, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _pubKeyMappings = const <DbPubkeyMapping>[];
      } else {
        final list = List<DbPubkeyMapping>.filled(
            length,
            DbPubkeyMapping(
              pubKey: '',
              marker: '',
            ),
            growable: true);
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = DbPubkeyMapping(
                pubKey: '',
                marker: '',
              );
            } else {
              final embedded = deserializeDbPubkeyMapping(objectReader);
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
  final object = DbRelaySetItem(
    _url,
    _pubKeyMappings,
  );
  return object;
}

extension DbRelaySetItemQueryFilter
    on QueryBuilder<DbRelaySetItem, DbRelaySetItem, QFilterCondition> {
  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
      urlEqualTo(
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
      urlLessThan(
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
      urlBetween(
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
      urlEndsWith(
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
      urlContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
      urlMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
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

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
      pubKeyMappingsIsEmpty() {
    return not().pubKeyMappingsIsNotEmpty();
  }

  QueryBuilder<DbRelaySetItem, DbRelaySetItem, QAfterFilterCondition>
      pubKeyMappingsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 2, value: null),
      );
    });
  }
}

extension DbRelaySetItemQueryObject
    on QueryBuilder<DbRelaySetItem, DbRelaySetItem, QFilterCondition> {}
