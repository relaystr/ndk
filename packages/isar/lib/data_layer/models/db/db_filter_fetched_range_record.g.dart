// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_filter_fetched_range_record.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetDbFilterFetchedRangeRecordCollection on Isar {
  IsarCollection<String, DbFilterFetchedRangeRecord>
      get dbFilterFetchedRangeRecords => this.collection();
}

const DbFilterFetchedRangeRecordSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'DbFilterFetchedRangeRecord',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'filterHash',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'relayUrl',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'rangeStart',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'rangeEnd',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'id',
        type: IsarType.string,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'filterHash',
        properties: [
          "filterHash",
        ],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'relayUrl',
        properties: [
          "relayUrl",
        ],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<String, DbFilterFetchedRangeRecord>(
    serialize: serializeDbFilterFetchedRangeRecord,
    deserialize: deserializeDbFilterFetchedRangeRecord,
    deserializeProperty: deserializeDbFilterFetchedRangeRecordProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeDbFilterFetchedRangeRecord(
    IsarWriter writer, DbFilterFetchedRangeRecord object) {
  IsarCore.writeString(writer, 1, object.filterHash);
  IsarCore.writeString(writer, 2, object.relayUrl);
  IsarCore.writeLong(writer, 3, object.rangeStart);
  IsarCore.writeLong(writer, 4, object.rangeEnd);
  IsarCore.writeString(writer, 5, object.id);
  return Isar.fastHash(object.id);
}

@isarProtected
DbFilterFetchedRangeRecord deserializeDbFilterFetchedRangeRecord(
    IsarReader reader) {
  final String _filterHash;
  _filterHash = IsarCore.readString(reader, 1) ?? '';
  final String _relayUrl;
  _relayUrl = IsarCore.readString(reader, 2) ?? '';
  final int _rangeStart;
  _rangeStart = IsarCore.readLong(reader, 3);
  final int _rangeEnd;
  _rangeEnd = IsarCore.readLong(reader, 4);
  final object = DbFilterFetchedRangeRecord(
    filterHash: _filterHash,
    relayUrl: _relayUrl,
    rangeStart: _rangeStart,
    rangeEnd: _rangeEnd,
  );
  return object;
}

@isarProtected
dynamic deserializeDbFilterFetchedRangeRecordProp(
    IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      return IsarCore.readLong(reader, 4);
    case 5:
      return IsarCore.readString(reader, 5) ?? '';
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _DbFilterFetchedRangeRecordUpdate {
  bool call({
    required String id,
    String? filterHash,
    String? relayUrl,
    int? rangeStart,
    int? rangeEnd,
  });
}

class _DbFilterFetchedRangeRecordUpdateImpl
    implements _DbFilterFetchedRangeRecordUpdate {
  const _DbFilterFetchedRangeRecordUpdateImpl(this.collection);

  final IsarCollection<String, DbFilterFetchedRangeRecord> collection;

  @override
  bool call({
    required String id,
    Object? filterHash = ignore,
    Object? relayUrl = ignore,
    Object? rangeStart = ignore,
    Object? rangeEnd = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (filterHash != ignore) 1: filterHash as String?,
          if (relayUrl != ignore) 2: relayUrl as String?,
          if (rangeStart != ignore) 3: rangeStart as int?,
          if (rangeEnd != ignore) 4: rangeEnd as int?,
        }) >
        0;
  }
}

sealed class _DbFilterFetchedRangeRecordUpdateAll {
  int call({
    required List<String> id,
    String? filterHash,
    String? relayUrl,
    int? rangeStart,
    int? rangeEnd,
  });
}

class _DbFilterFetchedRangeRecordUpdateAllImpl
    implements _DbFilterFetchedRangeRecordUpdateAll {
  const _DbFilterFetchedRangeRecordUpdateAllImpl(this.collection);

  final IsarCollection<String, DbFilterFetchedRangeRecord> collection;

  @override
  int call({
    required List<String> id,
    Object? filterHash = ignore,
    Object? relayUrl = ignore,
    Object? rangeStart = ignore,
    Object? rangeEnd = ignore,
  }) {
    return collection.updateProperties(id, {
      if (filterHash != ignore) 1: filterHash as String?,
      if (relayUrl != ignore) 2: relayUrl as String?,
      if (rangeStart != ignore) 3: rangeStart as int?,
      if (rangeEnd != ignore) 4: rangeEnd as int?,
    });
  }
}

extension DbFilterFetchedRangeRecordUpdate
    on IsarCollection<String, DbFilterFetchedRangeRecord> {
  _DbFilterFetchedRangeRecordUpdate get update =>
      _DbFilterFetchedRangeRecordUpdateImpl(this);

  _DbFilterFetchedRangeRecordUpdateAll get updateAll =>
      _DbFilterFetchedRangeRecordUpdateAllImpl(this);
}

sealed class _DbFilterFetchedRangeRecordQueryUpdate {
  int call({
    String? filterHash,
    String? relayUrl,
    int? rangeStart,
    int? rangeEnd,
  });
}

class _DbFilterFetchedRangeRecordQueryUpdateImpl
    implements _DbFilterFetchedRangeRecordQueryUpdate {
  const _DbFilterFetchedRangeRecordQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<DbFilterFetchedRangeRecord> query;
  final int? limit;

  @override
  int call({
    Object? filterHash = ignore,
    Object? relayUrl = ignore,
    Object? rangeStart = ignore,
    Object? rangeEnd = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (filterHash != ignore) 1: filterHash as String?,
      if (relayUrl != ignore) 2: relayUrl as String?,
      if (rangeStart != ignore) 3: rangeStart as int?,
      if (rangeEnd != ignore) 4: rangeEnd as int?,
    });
  }
}

extension DbFilterFetchedRangeRecordQueryUpdate
    on IsarQuery<DbFilterFetchedRangeRecord> {
  _DbFilterFetchedRangeRecordQueryUpdate get updateFirst =>
      _DbFilterFetchedRangeRecordQueryUpdateImpl(this, limit: 1);

  _DbFilterFetchedRangeRecordQueryUpdate get updateAll =>
      _DbFilterFetchedRangeRecordQueryUpdateImpl(this);
}

class _DbFilterFetchedRangeRecordQueryBuilderUpdateImpl
    implements _DbFilterFetchedRangeRecordQueryUpdate {
  const _DbFilterFetchedRangeRecordQueryBuilderUpdateImpl(this.query,
      {this.limit});

  final QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QOperations> query;
  final int? limit;

  @override
  int call({
    Object? filterHash = ignore,
    Object? relayUrl = ignore,
    Object? rangeStart = ignore,
    Object? rangeEnd = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (filterHash != ignore) 1: filterHash as String?,
        if (relayUrl != ignore) 2: relayUrl as String?,
        if (rangeStart != ignore) 3: rangeStart as int?,
        if (rangeEnd != ignore) 4: rangeEnd as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension DbFilterFetchedRangeRecordQueryBuilderUpdate on QueryBuilder<
    DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord, QOperations> {
  _DbFilterFetchedRangeRecordQueryUpdate get updateFirst =>
      _DbFilterFetchedRangeRecordQueryBuilderUpdateImpl(this, limit: 1);

  _DbFilterFetchedRangeRecordQueryUpdate get updateAll =>
      _DbFilterFetchedRangeRecordQueryBuilderUpdateImpl(this);
}

extension DbFilterFetchedRangeRecordQueryFilter on QueryBuilder<
    DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord, QFilterCondition> {
  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashGreaterThan(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashGreaterThanOrEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashLessThan(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashLessThanOrEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashBetween(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashStartsWith(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashEndsWith(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
          QAfterFilterCondition>
      filterHashContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
          QAfterFilterCondition>
      filterHashMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> filterHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlGreaterThan(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlGreaterThanOrEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlLessThan(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlLessThanOrEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlBetween(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlStartsWith(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlEndsWith(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
          QAfterFilterCondition>
      relayUrlContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
          QAfterFilterCondition>
      relayUrlMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> relayUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeStartEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeStartGreaterThan(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeStartGreaterThanOrEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeStartLessThan(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeStartLessThanOrEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeStartBetween(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeEndEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeEndGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeEndGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeEndLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeEndLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> rangeEndBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idGreaterThanOrEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idLessThanOrEqualTo(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idStartsWith(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idEndsWith(
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }
}

extension DbFilterFetchedRangeRecordQueryObject on QueryBuilder<
    DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord, QFilterCondition> {}

extension DbFilterFetchedRangeRecordQuerySortBy on QueryBuilder<
    DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord, QSortBy> {
  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByFilterHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByFilterHashDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByRelayUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByRelayUrlDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByRangeStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByRangeStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByRangeEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByRangeEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> sortByIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension DbFilterFetchedRangeRecordQuerySortThenBy on QueryBuilder<
    DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord, QSortThenBy> {
  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByFilterHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByFilterHashDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByRelayUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByRelayUrlDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByRangeStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByRangeStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByRangeEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByRangeEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterSortBy> thenByIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension DbFilterFetchedRangeRecordQueryWhereDistinct on QueryBuilder<
    DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord, QDistinct> {
  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterDistinct> distinctByFilterHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterDistinct> distinctByRelayUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterDistinct> distinctByRangeStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord,
      QAfterDistinct> distinctByRangeEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }
}

extension DbFilterFetchedRangeRecordQueryProperty1 on QueryBuilder<
    DbFilterFetchedRangeRecord, DbFilterFetchedRangeRecord, QProperty> {
  QueryBuilder<DbFilterFetchedRangeRecord, String, QAfterProperty>
      filterHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, String, QAfterProperty>
      relayUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, int, QAfterProperty>
      rangeStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, int, QAfterProperty>
      rangeEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, String, QAfterProperty>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension DbFilterFetchedRangeRecordQueryProperty2<R>
    on QueryBuilder<DbFilterFetchedRangeRecord, R, QAfterProperty> {
  QueryBuilder<DbFilterFetchedRangeRecord, (R, String), QAfterProperty>
      filterHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, (R, String), QAfterProperty>
      relayUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, (R, int), QAfterProperty>
      rangeStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, (R, int), QAfterProperty>
      rangeEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, (R, String), QAfterProperty>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension DbFilterFetchedRangeRecordQueryProperty3<R1, R2>
    on QueryBuilder<DbFilterFetchedRangeRecord, (R1, R2), QAfterProperty> {
  QueryBuilder<DbFilterFetchedRangeRecord, (R1, R2, String), QOperations>
      filterHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, (R1, R2, String), QOperations>
      relayUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, (R1, R2, int), QOperations>
      rangeStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, (R1, R2, int), QOperations>
      rangeEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<DbFilterFetchedRangeRecord, (R1, R2, String), QOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}
