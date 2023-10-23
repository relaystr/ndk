// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pubkey_mapping.dart';

// **************************************************************************
// _IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

const PubkeyMappingSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'PubkeyMapping',
    embedded: true,
    properties: [
      IsarPropertySchema(
        name: 'pubKey',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'rwMarker',
        type: IsarType.string,
        enumMap: {"readOnly": "r", "writeOnly": "w", "readWrite": "rw"},
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, PubkeyMapping>(
    serialize: serializePubkeyMapping,
    deserialize: deserializePubkeyMapping,
  ),
);

@isarProtected
int serializePubkeyMapping(IsarWriter writer, PubkeyMapping object) {
  IsarCore.writeString(writer, 1, object.pubKey);
  IsarCore.writeString(writer, 2, object.rwMarker.asText);
  return 0;
}

@isarProtected
PubkeyMapping deserializePubkeyMapping(IsarReader reader) {
  final String _pubKey;
  _pubKey = IsarCore.readString(reader, 1) ?? '';
  final ReadWriteMarker _rwMarker;
  _rwMarker = _pubkeyMappingRwMarker[
          IsarCore.readString(reader, 2) ?? ReadWriteMarker.readOnly] ??
      ReadWriteMarker.readOnly;
  final object = PubkeyMapping(
    pubKey: _pubKey,
    rwMarker: _rwMarker,
  );
  return object;
}

const _pubkeyMappingRwMarker = {
  r'r': ReadWriteMarker.readOnly,
  r'w': ReadWriteMarker.writeOnly,
  r'rw': ReadWriteMarker.readWrite,
};

extension PubkeyMappingQueryFilter
    on QueryBuilder<PubkeyMapping, PubkeyMapping, QFilterCondition> {
  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
      rwMarkerEqualTo(
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
      rwMarkerGreaterThan(
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
      rwMarkerGreaterThanOrEqualTo(
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
      rwMarkerLessThan(
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
      rwMarkerLessThanOrEqualTo(
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

  QueryBuilder<PubkeyMapping, PubkeyMapping, QAfterFilterCondition>
      rwMarkerBetween(
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
}

extension PubkeyMappingQueryObject
    on QueryBuilder<PubkeyMapping, PubkeyMapping, QFilterCondition> {}
