// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, DbEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sigMeta = const VerificationMeta('sig');
  @override
  late final GeneratedColumn<String> sig = GeneratedColumn<String>(
    'sig',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validSigMeta = const VerificationMeta(
    'validSig',
  );
  @override
  late final GeneratedColumn<bool> validSig = GeneratedColumn<bool>(
    'valid_sig',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("valid_sig" IN (0, 1))',
    ),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcesJsonMeta = const VerificationMeta(
    'sourcesJson',
  );
  @override
  late final GeneratedColumn<String> sourcesJson = GeneratedColumn<String>(
    'sources_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pubKey,
    kind,
    createdAt,
    content,
    sig,
    validSig,
    tagsJson,
    sourcesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pub_key')) {
      context.handle(
        _pubKeyMeta,
        pubKey.isAcceptableOrUnknown(data['pub_key']!, _pubKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sig')) {
      context.handle(
        _sigMeta,
        sig.isAcceptableOrUnknown(data['sig']!, _sigMeta),
      );
    }
    if (data.containsKey('valid_sig')) {
      context.handle(
        _validSigMeta,
        validSig.isAcceptableOrUnknown(data['valid_sig']!, _validSigMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsJsonMeta);
    }
    if (data.containsKey('sources_json')) {
      context.handle(
        _sourcesJsonMeta,
        sourcesJson.isAcceptableOrUnknown(
          data['sources_json']!,
          _sourcesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcesJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pubKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      sig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sig'],
      ),
      validSig: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}valid_sig'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      sourcesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources_json'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class DbEvent extends DataClass implements Insertable<DbEvent> {
  final String id;
  final String pubKey;
  final int kind;
  final int createdAt;
  final String content;
  final String? sig;
  final bool? validSig;
  final String tagsJson;
  final String sourcesJson;
  const DbEvent({
    required this.id,
    required this.pubKey,
    required this.kind,
    required this.createdAt,
    required this.content,
    this.sig,
    this.validSig,
    required this.tagsJson,
    required this.sourcesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pub_key'] = Variable<String>(pubKey);
    map['kind'] = Variable<int>(kind);
    map['created_at'] = Variable<int>(createdAt);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || sig != null) {
      map['sig'] = Variable<String>(sig);
    }
    if (!nullToAbsent || validSig != null) {
      map['valid_sig'] = Variable<bool>(validSig);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['sources_json'] = Variable<String>(sourcesJson);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      pubKey: Value(pubKey),
      kind: Value(kind),
      createdAt: Value(createdAt),
      content: Value(content),
      sig: sig == null && nullToAbsent ? const Value.absent() : Value(sig),
      validSig: validSig == null && nullToAbsent
          ? const Value.absent()
          : Value(validSig),
      tagsJson: Value(tagsJson),
      sourcesJson: Value(sourcesJson),
    );
  }

  factory DbEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbEvent(
      id: serializer.fromJson<String>(json['id']),
      pubKey: serializer.fromJson<String>(json['pubKey']),
      kind: serializer.fromJson<int>(json['kind']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      content: serializer.fromJson<String>(json['content']),
      sig: serializer.fromJson<String?>(json['sig']),
      validSig: serializer.fromJson<bool?>(json['validSig']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      sourcesJson: serializer.fromJson<String>(json['sourcesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pubKey': serializer.toJson<String>(pubKey),
      'kind': serializer.toJson<int>(kind),
      'createdAt': serializer.toJson<int>(createdAt),
      'content': serializer.toJson<String>(content),
      'sig': serializer.toJson<String?>(sig),
      'validSig': serializer.toJson<bool?>(validSig),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'sourcesJson': serializer.toJson<String>(sourcesJson),
    };
  }

  DbEvent copyWith({
    String? id,
    String? pubKey,
    int? kind,
    int? createdAt,
    String? content,
    Value<String?> sig = const Value.absent(),
    Value<bool?> validSig = const Value.absent(),
    String? tagsJson,
    String? sourcesJson,
  }) => DbEvent(
    id: id ?? this.id,
    pubKey: pubKey ?? this.pubKey,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
    content: content ?? this.content,
    sig: sig.present ? sig.value : this.sig,
    validSig: validSig.present ? validSig.value : this.validSig,
    tagsJson: tagsJson ?? this.tagsJson,
    sourcesJson: sourcesJson ?? this.sourcesJson,
  );
  DbEvent copyWithCompanion(EventsCompanion data) {
    return DbEvent(
      id: data.id.present ? data.id.value : this.id,
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      content: data.content.present ? data.content.value : this.content,
      sig: data.sig.present ? data.sig.value : this.sig,
      validSig: data.validSig.present ? data.validSig.value : this.validSig,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      sourcesJson: data.sourcesJson.present
          ? data.sourcesJson.value
          : this.sourcesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbEvent(')
          ..write('id: $id, ')
          ..write('pubKey: $pubKey, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('content: $content, ')
          ..write('sig: $sig, ')
          ..write('validSig: $validSig, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('sourcesJson: $sourcesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pubKey,
    kind,
    createdAt,
    content,
    sig,
    validSig,
    tagsJson,
    sourcesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbEvent &&
          other.id == this.id &&
          other.pubKey == this.pubKey &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt &&
          other.content == this.content &&
          other.sig == this.sig &&
          other.validSig == this.validSig &&
          other.tagsJson == this.tagsJson &&
          other.sourcesJson == this.sourcesJson);
}

class EventsCompanion extends UpdateCompanion<DbEvent> {
  final Value<String> id;
  final Value<String> pubKey;
  final Value<int> kind;
  final Value<int> createdAt;
  final Value<String> content;
  final Value<String?> sig;
  final Value<bool?> validSig;
  final Value<String> tagsJson;
  final Value<String> sourcesJson;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.pubKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.content = const Value.absent(),
    this.sig = const Value.absent(),
    this.validSig = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.sourcesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String pubKey,
    required int kind,
    required int createdAt,
    required String content,
    this.sig = const Value.absent(),
    this.validSig = const Value.absent(),
    required String tagsJson,
    required String sourcesJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pubKey = Value(pubKey),
       kind = Value(kind),
       createdAt = Value(createdAt),
       content = Value(content),
       tagsJson = Value(tagsJson),
       sourcesJson = Value(sourcesJson);
  static Insertable<DbEvent> custom({
    Expression<String>? id,
    Expression<String>? pubKey,
    Expression<int>? kind,
    Expression<int>? createdAt,
    Expression<String>? content,
    Expression<String>? sig,
    Expression<bool>? validSig,
    Expression<String>? tagsJson,
    Expression<String>? sourcesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pubKey != null) 'pub_key': pubKey,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (content != null) 'content': content,
      if (sig != null) 'sig': sig,
      if (validSig != null) 'valid_sig': validSig,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (sourcesJson != null) 'sources_json': sourcesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? id,
    Value<String>? pubKey,
    Value<int>? kind,
    Value<int>? createdAt,
    Value<String>? content,
    Value<String?>? sig,
    Value<bool?>? validSig,
    Value<String>? tagsJson,
    Value<String>? sourcesJson,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      pubKey: pubKey ?? this.pubKey,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      sig: sig ?? this.sig,
      validSig: validSig ?? this.validSig,
      tagsJson: tagsJson ?? this.tagsJson,
      sourcesJson: sourcesJson ?? this.sourcesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sig.present) {
      map['sig'] = Variable<String>(sig.value);
    }
    if (validSig.present) {
      map['valid_sig'] = Variable<bool>(validSig.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (sourcesJson.present) {
      map['sources_json'] = Variable<String>(sourcesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('pubKey: $pubKey, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('content: $content, ')
          ..write('sig: $sig, ')
          ..write('validSig: $validSig, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('sourcesJson: $sourcesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserRelayListsTable extends UserRelayLists
    with TableInfo<$UserRelayListsTable, DbUserRelayList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRelayListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshedTimestampMeta =
      const VerificationMeta('refreshedTimestamp');
  @override
  late final GeneratedColumn<int> refreshedTimestamp = GeneratedColumn<int>(
    'refreshed_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relaysJsonMeta = const VerificationMeta(
    'relaysJson',
  );
  @override
  late final GeneratedColumn<String> relaysJson = GeneratedColumn<String>(
    'relays_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    pubKey,
    createdAt,
    refreshedTimestamp,
    relaysJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_relay_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbUserRelayList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pub_key')) {
      context.handle(
        _pubKeyMeta,
        pubKey.isAcceptableOrUnknown(data['pub_key']!, _pubKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('refreshed_timestamp')) {
      context.handle(
        _refreshedTimestampMeta,
        refreshedTimestamp.isAcceptableOrUnknown(
          data['refreshed_timestamp']!,
          _refreshedTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshedTimestampMeta);
    }
    if (data.containsKey('relays_json')) {
      context.handle(
        _relaysJsonMeta,
        relaysJson.isAcceptableOrUnknown(data['relays_json']!, _relaysJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_relaysJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pubKey};
  @override
  DbUserRelayList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbUserRelayList(
      pubKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      refreshedTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}refreshed_timestamp'],
      )!,
      relaysJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relays_json'],
      )!,
    );
  }

  @override
  $UserRelayListsTable createAlias(String alias) {
    return $UserRelayListsTable(attachedDatabase, alias);
  }
}

class DbUserRelayList extends DataClass implements Insertable<DbUserRelayList> {
  final String pubKey;
  final int createdAt;
  final int refreshedTimestamp;
  final String relaysJson;
  const DbUserRelayList({
    required this.pubKey,
    required this.createdAt,
    required this.refreshedTimestamp,
    required this.relaysJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pub_key'] = Variable<String>(pubKey);
    map['created_at'] = Variable<int>(createdAt);
    map['refreshed_timestamp'] = Variable<int>(refreshedTimestamp);
    map['relays_json'] = Variable<String>(relaysJson);
    return map;
  }

  UserRelayListsCompanion toCompanion(bool nullToAbsent) {
    return UserRelayListsCompanion(
      pubKey: Value(pubKey),
      createdAt: Value(createdAt),
      refreshedTimestamp: Value(refreshedTimestamp),
      relaysJson: Value(relaysJson),
    );
  }

  factory DbUserRelayList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbUserRelayList(
      pubKey: serializer.fromJson<String>(json['pubKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      refreshedTimestamp: serializer.fromJson<int>(json['refreshedTimestamp']),
      relaysJson: serializer.fromJson<String>(json['relaysJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubKey': serializer.toJson<String>(pubKey),
      'createdAt': serializer.toJson<int>(createdAt),
      'refreshedTimestamp': serializer.toJson<int>(refreshedTimestamp),
      'relaysJson': serializer.toJson<String>(relaysJson),
    };
  }

  DbUserRelayList copyWith({
    String? pubKey,
    int? createdAt,
    int? refreshedTimestamp,
    String? relaysJson,
  }) => DbUserRelayList(
    pubKey: pubKey ?? this.pubKey,
    createdAt: createdAt ?? this.createdAt,
    refreshedTimestamp: refreshedTimestamp ?? this.refreshedTimestamp,
    relaysJson: relaysJson ?? this.relaysJson,
  );
  DbUserRelayList copyWithCompanion(UserRelayListsCompanion data) {
    return DbUserRelayList(
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      refreshedTimestamp: data.refreshedTimestamp.present
          ? data.refreshedTimestamp.value
          : this.refreshedTimestamp,
      relaysJson: data.relaysJson.present
          ? data.relaysJson.value
          : this.relaysJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbUserRelayList(')
          ..write('pubKey: $pubKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('refreshedTimestamp: $refreshedTimestamp, ')
          ..write('relaysJson: $relaysJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(pubKey, createdAt, refreshedTimestamp, relaysJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbUserRelayList &&
          other.pubKey == this.pubKey &&
          other.createdAt == this.createdAt &&
          other.refreshedTimestamp == this.refreshedTimestamp &&
          other.relaysJson == this.relaysJson);
}

class UserRelayListsCompanion extends UpdateCompanion<DbUserRelayList> {
  final Value<String> pubKey;
  final Value<int> createdAt;
  final Value<int> refreshedTimestamp;
  final Value<String> relaysJson;
  final Value<int> rowid;
  const UserRelayListsCompanion({
    this.pubKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.refreshedTimestamp = const Value.absent(),
    this.relaysJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserRelayListsCompanion.insert({
    required String pubKey,
    required int createdAt,
    required int refreshedTimestamp,
    required String relaysJson,
    this.rowid = const Value.absent(),
  }) : pubKey = Value(pubKey),
       createdAt = Value(createdAt),
       refreshedTimestamp = Value(refreshedTimestamp),
       relaysJson = Value(relaysJson);
  static Insertable<DbUserRelayList> custom({
    Expression<String>? pubKey,
    Expression<int>? createdAt,
    Expression<int>? refreshedTimestamp,
    Expression<String>? relaysJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubKey != null) 'pub_key': pubKey,
      if (createdAt != null) 'created_at': createdAt,
      if (refreshedTimestamp != null) 'refreshed_timestamp': refreshedTimestamp,
      if (relaysJson != null) 'relays_json': relaysJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserRelayListsCompanion copyWith({
    Value<String>? pubKey,
    Value<int>? createdAt,
    Value<int>? refreshedTimestamp,
    Value<String>? relaysJson,
    Value<int>? rowid,
  }) {
    return UserRelayListsCompanion(
      pubKey: pubKey ?? this.pubKey,
      createdAt: createdAt ?? this.createdAt,
      refreshedTimestamp: refreshedTimestamp ?? this.refreshedTimestamp,
      relaysJson: relaysJson ?? this.relaysJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (refreshedTimestamp.present) {
      map['refreshed_timestamp'] = Variable<int>(refreshedTimestamp.value);
    }
    if (relaysJson.present) {
      map['relays_json'] = Variable<String>(relaysJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserRelayListsCompanion(')
          ..write('pubKey: $pubKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('refreshedTimestamp: $refreshedTimestamp, ')
          ..write('relaysJson: $relaysJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelaySetsTable extends RelaySets
    with TableInfo<$RelaySetsTable, DbRelaySet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelaySetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relayMinCountPerPubkeyMeta =
      const VerificationMeta('relayMinCountPerPubkey');
  @override
  late final GeneratedColumn<int> relayMinCountPerPubkey = GeneratedColumn<int>(
    'relay_min_count_per_pubkey',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relaysMapJsonMeta = const VerificationMeta(
    'relaysMapJson',
  );
  @override
  late final GeneratedColumn<String> relaysMapJson = GeneratedColumn<String>(
    'relays_map_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fallbackToBootstrapRelaysMeta =
      const VerificationMeta('fallbackToBootstrapRelays');
  @override
  late final GeneratedColumn<bool> fallbackToBootstrapRelays =
      GeneratedColumn<bool>(
        'fallback_to_bootstrap_relays',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("fallback_to_bootstrap_relays" IN (0, 1))',
        ),
      );
  static const VerificationMeta _notCoveredPubkeysJsonMeta =
      const VerificationMeta('notCoveredPubkeysJson');
  @override
  late final GeneratedColumn<String> notCoveredPubkeysJson =
      GeneratedColumn<String>(
        'not_covered_pubkeys_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    pubKey,
    relayMinCountPerPubkey,
    direction,
    relaysMapJson,
    fallbackToBootstrapRelays,
    notCoveredPubkeysJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relay_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbRelaySet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('pub_key')) {
      context.handle(
        _pubKeyMeta,
        pubKey.isAcceptableOrUnknown(data['pub_key']!, _pubKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubKeyMeta);
    }
    if (data.containsKey('relay_min_count_per_pubkey')) {
      context.handle(
        _relayMinCountPerPubkeyMeta,
        relayMinCountPerPubkey.isAcceptableOrUnknown(
          data['relay_min_count_per_pubkey']!,
          _relayMinCountPerPubkeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relayMinCountPerPubkeyMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('relays_map_json')) {
      context.handle(
        _relaysMapJsonMeta,
        relaysMapJson.isAcceptableOrUnknown(
          data['relays_map_json']!,
          _relaysMapJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relaysMapJsonMeta);
    }
    if (data.containsKey('fallback_to_bootstrap_relays')) {
      context.handle(
        _fallbackToBootstrapRelaysMeta,
        fallbackToBootstrapRelays.isAcceptableOrUnknown(
          data['fallback_to_bootstrap_relays']!,
          _fallbackToBootstrapRelaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fallbackToBootstrapRelaysMeta);
    }
    if (data.containsKey('not_covered_pubkeys_json')) {
      context.handle(
        _notCoveredPubkeysJsonMeta,
        notCoveredPubkeysJson.isAcceptableOrUnknown(
          data['not_covered_pubkeys_json']!,
          _notCoveredPubkeysJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notCoveredPubkeysJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbRelaySet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbRelaySet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      pubKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_key'],
      )!,
      relayMinCountPerPubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}relay_min_count_per_pubkey'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
      relaysMapJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relays_map_json'],
      )!,
      fallbackToBootstrapRelays: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fallback_to_bootstrap_relays'],
      )!,
      notCoveredPubkeysJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}not_covered_pubkeys_json'],
      )!,
    );
  }

  @override
  $RelaySetsTable createAlias(String alias) {
    return $RelaySetsTable(attachedDatabase, alias);
  }
}

class DbRelaySet extends DataClass implements Insertable<DbRelaySet> {
  final String id;
  final String name;
  final String pubKey;
  final int relayMinCountPerPubkey;
  final int direction;
  final String relaysMapJson;
  final bool fallbackToBootstrapRelays;
  final String notCoveredPubkeysJson;
  const DbRelaySet({
    required this.id,
    required this.name,
    required this.pubKey,
    required this.relayMinCountPerPubkey,
    required this.direction,
    required this.relaysMapJson,
    required this.fallbackToBootstrapRelays,
    required this.notCoveredPubkeysJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['pub_key'] = Variable<String>(pubKey);
    map['relay_min_count_per_pubkey'] = Variable<int>(relayMinCountPerPubkey);
    map['direction'] = Variable<int>(direction);
    map['relays_map_json'] = Variable<String>(relaysMapJson);
    map['fallback_to_bootstrap_relays'] = Variable<bool>(
      fallbackToBootstrapRelays,
    );
    map['not_covered_pubkeys_json'] = Variable<String>(notCoveredPubkeysJson);
    return map;
  }

  RelaySetsCompanion toCompanion(bool nullToAbsent) {
    return RelaySetsCompanion(
      id: Value(id),
      name: Value(name),
      pubKey: Value(pubKey),
      relayMinCountPerPubkey: Value(relayMinCountPerPubkey),
      direction: Value(direction),
      relaysMapJson: Value(relaysMapJson),
      fallbackToBootstrapRelays: Value(fallbackToBootstrapRelays),
      notCoveredPubkeysJson: Value(notCoveredPubkeysJson),
    );
  }

  factory DbRelaySet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbRelaySet(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      pubKey: serializer.fromJson<String>(json['pubKey']),
      relayMinCountPerPubkey: serializer.fromJson<int>(
        json['relayMinCountPerPubkey'],
      ),
      direction: serializer.fromJson<int>(json['direction']),
      relaysMapJson: serializer.fromJson<String>(json['relaysMapJson']),
      fallbackToBootstrapRelays: serializer.fromJson<bool>(
        json['fallbackToBootstrapRelays'],
      ),
      notCoveredPubkeysJson: serializer.fromJson<String>(
        json['notCoveredPubkeysJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'pubKey': serializer.toJson<String>(pubKey),
      'relayMinCountPerPubkey': serializer.toJson<int>(relayMinCountPerPubkey),
      'direction': serializer.toJson<int>(direction),
      'relaysMapJson': serializer.toJson<String>(relaysMapJson),
      'fallbackToBootstrapRelays': serializer.toJson<bool>(
        fallbackToBootstrapRelays,
      ),
      'notCoveredPubkeysJson': serializer.toJson<String>(notCoveredPubkeysJson),
    };
  }

  DbRelaySet copyWith({
    String? id,
    String? name,
    String? pubKey,
    int? relayMinCountPerPubkey,
    int? direction,
    String? relaysMapJson,
    bool? fallbackToBootstrapRelays,
    String? notCoveredPubkeysJson,
  }) => DbRelaySet(
    id: id ?? this.id,
    name: name ?? this.name,
    pubKey: pubKey ?? this.pubKey,
    relayMinCountPerPubkey:
        relayMinCountPerPubkey ?? this.relayMinCountPerPubkey,
    direction: direction ?? this.direction,
    relaysMapJson: relaysMapJson ?? this.relaysMapJson,
    fallbackToBootstrapRelays:
        fallbackToBootstrapRelays ?? this.fallbackToBootstrapRelays,
    notCoveredPubkeysJson: notCoveredPubkeysJson ?? this.notCoveredPubkeysJson,
  );
  DbRelaySet copyWithCompanion(RelaySetsCompanion data) {
    return DbRelaySet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      relayMinCountPerPubkey: data.relayMinCountPerPubkey.present
          ? data.relayMinCountPerPubkey.value
          : this.relayMinCountPerPubkey,
      direction: data.direction.present ? data.direction.value : this.direction,
      relaysMapJson: data.relaysMapJson.present
          ? data.relaysMapJson.value
          : this.relaysMapJson,
      fallbackToBootstrapRelays: data.fallbackToBootstrapRelays.present
          ? data.fallbackToBootstrapRelays.value
          : this.fallbackToBootstrapRelays,
      notCoveredPubkeysJson: data.notCoveredPubkeysJson.present
          ? data.notCoveredPubkeysJson.value
          : this.notCoveredPubkeysJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbRelaySet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pubKey: $pubKey, ')
          ..write('relayMinCountPerPubkey: $relayMinCountPerPubkey, ')
          ..write('direction: $direction, ')
          ..write('relaysMapJson: $relaysMapJson, ')
          ..write('fallbackToBootstrapRelays: $fallbackToBootstrapRelays, ')
          ..write('notCoveredPubkeysJson: $notCoveredPubkeysJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    pubKey,
    relayMinCountPerPubkey,
    direction,
    relaysMapJson,
    fallbackToBootstrapRelays,
    notCoveredPubkeysJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbRelaySet &&
          other.id == this.id &&
          other.name == this.name &&
          other.pubKey == this.pubKey &&
          other.relayMinCountPerPubkey == this.relayMinCountPerPubkey &&
          other.direction == this.direction &&
          other.relaysMapJson == this.relaysMapJson &&
          other.fallbackToBootstrapRelays == this.fallbackToBootstrapRelays &&
          other.notCoveredPubkeysJson == this.notCoveredPubkeysJson);
}

class RelaySetsCompanion extends UpdateCompanion<DbRelaySet> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> pubKey;
  final Value<int> relayMinCountPerPubkey;
  final Value<int> direction;
  final Value<String> relaysMapJson;
  final Value<bool> fallbackToBootstrapRelays;
  final Value<String> notCoveredPubkeysJson;
  final Value<int> rowid;
  const RelaySetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.pubKey = const Value.absent(),
    this.relayMinCountPerPubkey = const Value.absent(),
    this.direction = const Value.absent(),
    this.relaysMapJson = const Value.absent(),
    this.fallbackToBootstrapRelays = const Value.absent(),
    this.notCoveredPubkeysJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelaySetsCompanion.insert({
    required String id,
    required String name,
    required String pubKey,
    required int relayMinCountPerPubkey,
    required int direction,
    required String relaysMapJson,
    required bool fallbackToBootstrapRelays,
    required String notCoveredPubkeysJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       pubKey = Value(pubKey),
       relayMinCountPerPubkey = Value(relayMinCountPerPubkey),
       direction = Value(direction),
       relaysMapJson = Value(relaysMapJson),
       fallbackToBootstrapRelays = Value(fallbackToBootstrapRelays),
       notCoveredPubkeysJson = Value(notCoveredPubkeysJson);
  static Insertable<DbRelaySet> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? pubKey,
    Expression<int>? relayMinCountPerPubkey,
    Expression<int>? direction,
    Expression<String>? relaysMapJson,
    Expression<bool>? fallbackToBootstrapRelays,
    Expression<String>? notCoveredPubkeysJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (pubKey != null) 'pub_key': pubKey,
      if (relayMinCountPerPubkey != null)
        'relay_min_count_per_pubkey': relayMinCountPerPubkey,
      if (direction != null) 'direction': direction,
      if (relaysMapJson != null) 'relays_map_json': relaysMapJson,
      if (fallbackToBootstrapRelays != null)
        'fallback_to_bootstrap_relays': fallbackToBootstrapRelays,
      if (notCoveredPubkeysJson != null)
        'not_covered_pubkeys_json': notCoveredPubkeysJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelaySetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? pubKey,
    Value<int>? relayMinCountPerPubkey,
    Value<int>? direction,
    Value<String>? relaysMapJson,
    Value<bool>? fallbackToBootstrapRelays,
    Value<String>? notCoveredPubkeysJson,
    Value<int>? rowid,
  }) {
    return RelaySetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      pubKey: pubKey ?? this.pubKey,
      relayMinCountPerPubkey:
          relayMinCountPerPubkey ?? this.relayMinCountPerPubkey,
      direction: direction ?? this.direction,
      relaysMapJson: relaysMapJson ?? this.relaysMapJson,
      fallbackToBootstrapRelays:
          fallbackToBootstrapRelays ?? this.fallbackToBootstrapRelays,
      notCoveredPubkeysJson:
          notCoveredPubkeysJson ?? this.notCoveredPubkeysJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (relayMinCountPerPubkey.present) {
      map['relay_min_count_per_pubkey'] = Variable<int>(
        relayMinCountPerPubkey.value,
      );
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    if (relaysMapJson.present) {
      map['relays_map_json'] = Variable<String>(relaysMapJson.value);
    }
    if (fallbackToBootstrapRelays.present) {
      map['fallback_to_bootstrap_relays'] = Variable<bool>(
        fallbackToBootstrapRelays.value,
      );
    }
    if (notCoveredPubkeysJson.present) {
      map['not_covered_pubkeys_json'] = Variable<String>(
        notCoveredPubkeysJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelaySetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pubKey: $pubKey, ')
          ..write('relayMinCountPerPubkey: $relayMinCountPerPubkey, ')
          ..write('direction: $direction, ')
          ..write('relaysMapJson: $relaysMapJson, ')
          ..write('fallbackToBootstrapRelays: $fallbackToBootstrapRelays, ')
          ..write('notCoveredPubkeysJson: $notCoveredPubkeysJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $Nip05sTable extends Nip05s with TableInfo<$Nip05sTable, DbNip05> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $Nip05sTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nip05Meta = const VerificationMeta('nip05');
  @override
  late final GeneratedColumn<String> nip05 = GeneratedColumn<String>(
    'nip05',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validMeta = const VerificationMeta('valid');
  @override
  late final GeneratedColumn<bool> valid = GeneratedColumn<bool>(
    'valid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("valid" IN (0, 1))',
    ),
  );
  static const VerificationMeta _networkFetchTimeMeta = const VerificationMeta(
    'networkFetchTime',
  );
  @override
  late final GeneratedColumn<int> networkFetchTime = GeneratedColumn<int>(
    'network_fetch_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relaysJsonMeta = const VerificationMeta(
    'relaysJson',
  );
  @override
  late final GeneratedColumn<String> relaysJson = GeneratedColumn<String>(
    'relays_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    pubKey,
    nip05,
    valid,
    networkFetchTime,
    relaysJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nip05s';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbNip05> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pub_key')) {
      context.handle(
        _pubKeyMeta,
        pubKey.isAcceptableOrUnknown(data['pub_key']!, _pubKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubKeyMeta);
    }
    if (data.containsKey('nip05')) {
      context.handle(
        _nip05Meta,
        nip05.isAcceptableOrUnknown(data['nip05']!, _nip05Meta),
      );
    } else if (isInserting) {
      context.missing(_nip05Meta);
    }
    if (data.containsKey('valid')) {
      context.handle(
        _validMeta,
        valid.isAcceptableOrUnknown(data['valid']!, _validMeta),
      );
    } else if (isInserting) {
      context.missing(_validMeta);
    }
    if (data.containsKey('network_fetch_time')) {
      context.handle(
        _networkFetchTimeMeta,
        networkFetchTime.isAcceptableOrUnknown(
          data['network_fetch_time']!,
          _networkFetchTimeMeta,
        ),
      );
    }
    if (data.containsKey('relays_json')) {
      context.handle(
        _relaysJsonMeta,
        relaysJson.isAcceptableOrUnknown(data['relays_json']!, _relaysJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_relaysJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pubKey};
  @override
  DbNip05 map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbNip05(
      pubKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_key'],
      )!,
      nip05: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nip05'],
      )!,
      valid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}valid'],
      )!,
      networkFetchTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}network_fetch_time'],
      ),
      relaysJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relays_json'],
      )!,
    );
  }

  @override
  $Nip05sTable createAlias(String alias) {
    return $Nip05sTable(attachedDatabase, alias);
  }
}

class DbNip05 extends DataClass implements Insertable<DbNip05> {
  final String pubKey;
  final String nip05;
  final bool valid;
  final int? networkFetchTime;
  final String relaysJson;
  const DbNip05({
    required this.pubKey,
    required this.nip05,
    required this.valid,
    this.networkFetchTime,
    required this.relaysJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pub_key'] = Variable<String>(pubKey);
    map['nip05'] = Variable<String>(nip05);
    map['valid'] = Variable<bool>(valid);
    if (!nullToAbsent || networkFetchTime != null) {
      map['network_fetch_time'] = Variable<int>(networkFetchTime);
    }
    map['relays_json'] = Variable<String>(relaysJson);
    return map;
  }

  Nip05sCompanion toCompanion(bool nullToAbsent) {
    return Nip05sCompanion(
      pubKey: Value(pubKey),
      nip05: Value(nip05),
      valid: Value(valid),
      networkFetchTime: networkFetchTime == null && nullToAbsent
          ? const Value.absent()
          : Value(networkFetchTime),
      relaysJson: Value(relaysJson),
    );
  }

  factory DbNip05.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbNip05(
      pubKey: serializer.fromJson<String>(json['pubKey']),
      nip05: serializer.fromJson<String>(json['nip05']),
      valid: serializer.fromJson<bool>(json['valid']),
      networkFetchTime: serializer.fromJson<int?>(json['networkFetchTime']),
      relaysJson: serializer.fromJson<String>(json['relaysJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubKey': serializer.toJson<String>(pubKey),
      'nip05': serializer.toJson<String>(nip05),
      'valid': serializer.toJson<bool>(valid),
      'networkFetchTime': serializer.toJson<int?>(networkFetchTime),
      'relaysJson': serializer.toJson<String>(relaysJson),
    };
  }

  DbNip05 copyWith({
    String? pubKey,
    String? nip05,
    bool? valid,
    Value<int?> networkFetchTime = const Value.absent(),
    String? relaysJson,
  }) => DbNip05(
    pubKey: pubKey ?? this.pubKey,
    nip05: nip05 ?? this.nip05,
    valid: valid ?? this.valid,
    networkFetchTime: networkFetchTime.present
        ? networkFetchTime.value
        : this.networkFetchTime,
    relaysJson: relaysJson ?? this.relaysJson,
  );
  DbNip05 copyWithCompanion(Nip05sCompanion data) {
    return DbNip05(
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      nip05: data.nip05.present ? data.nip05.value : this.nip05,
      valid: data.valid.present ? data.valid.value : this.valid,
      networkFetchTime: data.networkFetchTime.present
          ? data.networkFetchTime.value
          : this.networkFetchTime,
      relaysJson: data.relaysJson.present
          ? data.relaysJson.value
          : this.relaysJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbNip05(')
          ..write('pubKey: $pubKey, ')
          ..write('nip05: $nip05, ')
          ..write('valid: $valid, ')
          ..write('networkFetchTime: $networkFetchTime, ')
          ..write('relaysJson: $relaysJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(pubKey, nip05, valid, networkFetchTime, relaysJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbNip05 &&
          other.pubKey == this.pubKey &&
          other.nip05 == this.nip05 &&
          other.valid == this.valid &&
          other.networkFetchTime == this.networkFetchTime &&
          other.relaysJson == this.relaysJson);
}

class Nip05sCompanion extends UpdateCompanion<DbNip05> {
  final Value<String> pubKey;
  final Value<String> nip05;
  final Value<bool> valid;
  final Value<int?> networkFetchTime;
  final Value<String> relaysJson;
  final Value<int> rowid;
  const Nip05sCompanion({
    this.pubKey = const Value.absent(),
    this.nip05 = const Value.absent(),
    this.valid = const Value.absent(),
    this.networkFetchTime = const Value.absent(),
    this.relaysJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  Nip05sCompanion.insert({
    required String pubKey,
    required String nip05,
    required bool valid,
    this.networkFetchTime = const Value.absent(),
    required String relaysJson,
    this.rowid = const Value.absent(),
  }) : pubKey = Value(pubKey),
       nip05 = Value(nip05),
       valid = Value(valid),
       relaysJson = Value(relaysJson);
  static Insertable<DbNip05> custom({
    Expression<String>? pubKey,
    Expression<String>? nip05,
    Expression<bool>? valid,
    Expression<int>? networkFetchTime,
    Expression<String>? relaysJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubKey != null) 'pub_key': pubKey,
      if (nip05 != null) 'nip05': nip05,
      if (valid != null) 'valid': valid,
      if (networkFetchTime != null) 'network_fetch_time': networkFetchTime,
      if (relaysJson != null) 'relays_json': relaysJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  Nip05sCompanion copyWith({
    Value<String>? pubKey,
    Value<String>? nip05,
    Value<bool>? valid,
    Value<int?>? networkFetchTime,
    Value<String>? relaysJson,
    Value<int>? rowid,
  }) {
    return Nip05sCompanion(
      pubKey: pubKey ?? this.pubKey,
      nip05: nip05 ?? this.nip05,
      valid: valid ?? this.valid,
      networkFetchTime: networkFetchTime ?? this.networkFetchTime,
      relaysJson: relaysJson ?? this.relaysJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (nip05.present) {
      map['nip05'] = Variable<String>(nip05.value);
    }
    if (valid.present) {
      map['valid'] = Variable<bool>(valid.value);
    }
    if (networkFetchTime.present) {
      map['network_fetch_time'] = Variable<int>(networkFetchTime.value);
    }
    if (relaysJson.present) {
      map['relays_json'] = Variable<String>(relaysJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('Nip05sCompanion(')
          ..write('pubKey: $pubKey, ')
          ..write('nip05: $nip05, ')
          ..write('valid: $valid, ')
          ..write('networkFetchTime: $networkFetchTime, ')
          ..write('relaysJson: $relaysJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilterFetchedRangeRecordsTable extends FilterFetchedRangeRecords
    with
        TableInfo<$FilterFetchedRangeRecordsTable, DbFilterFetchedRangeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilterFetchedRangeRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filterHashMeta = const VerificationMeta(
    'filterHash',
  );
  @override
  late final GeneratedColumn<String> filterHash = GeneratedColumn<String>(
    'filter_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relayUrlMeta = const VerificationMeta(
    'relayUrl',
  );
  @override
  late final GeneratedColumn<String> relayUrl = GeneratedColumn<String>(
    'relay_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeStartMeta = const VerificationMeta(
    'rangeStart',
  );
  @override
  late final GeneratedColumn<int> rangeStart = GeneratedColumn<int>(
    'range_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeEndMeta = const VerificationMeta(
    'rangeEnd',
  );
  @override
  late final GeneratedColumn<int> rangeEnd = GeneratedColumn<int>(
    'range_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    filterHash,
    relayUrl,
    rangeStart,
    rangeEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'filter_fetched_range_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbFilterFetchedRangeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('filter_hash')) {
      context.handle(
        _filterHashMeta,
        filterHash.isAcceptableOrUnknown(data['filter_hash']!, _filterHashMeta),
      );
    } else if (isInserting) {
      context.missing(_filterHashMeta);
    }
    if (data.containsKey('relay_url')) {
      context.handle(
        _relayUrlMeta,
        relayUrl.isAcceptableOrUnknown(data['relay_url']!, _relayUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_relayUrlMeta);
    }
    if (data.containsKey('range_start')) {
      context.handle(
        _rangeStartMeta,
        rangeStart.isAcceptableOrUnknown(data['range_start']!, _rangeStartMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeStartMeta);
    }
    if (data.containsKey('range_end')) {
      context.handle(
        _rangeEndMeta,
        rangeEnd.isAcceptableOrUnknown(data['range_end']!, _rangeEndMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeEndMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DbFilterFetchedRangeRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbFilterFetchedRangeRecord(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      filterHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_hash'],
      )!,
      relayUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_url'],
      )!,
      rangeStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}range_start'],
      )!,
      rangeEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}range_end'],
      )!,
    );
  }

  @override
  $FilterFetchedRangeRecordsTable createAlias(String alias) {
    return $FilterFetchedRangeRecordsTable(attachedDatabase, alias);
  }
}

class DbFilterFetchedRangeRecord extends DataClass
    implements Insertable<DbFilterFetchedRangeRecord> {
  final String key;
  final String filterHash;
  final String relayUrl;
  final int rangeStart;
  final int rangeEnd;
  const DbFilterFetchedRangeRecord({
    required this.key,
    required this.filterHash,
    required this.relayUrl,
    required this.rangeStart,
    required this.rangeEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['filter_hash'] = Variable<String>(filterHash);
    map['relay_url'] = Variable<String>(relayUrl);
    map['range_start'] = Variable<int>(rangeStart);
    map['range_end'] = Variable<int>(rangeEnd);
    return map;
  }

  FilterFetchedRangeRecordsCompanion toCompanion(bool nullToAbsent) {
    return FilterFetchedRangeRecordsCompanion(
      key: Value(key),
      filterHash: Value(filterHash),
      relayUrl: Value(relayUrl),
      rangeStart: Value(rangeStart),
      rangeEnd: Value(rangeEnd),
    );
  }

  factory DbFilterFetchedRangeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbFilterFetchedRangeRecord(
      key: serializer.fromJson<String>(json['key']),
      filterHash: serializer.fromJson<String>(json['filterHash']),
      relayUrl: serializer.fromJson<String>(json['relayUrl']),
      rangeStart: serializer.fromJson<int>(json['rangeStart']),
      rangeEnd: serializer.fromJson<int>(json['rangeEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'filterHash': serializer.toJson<String>(filterHash),
      'relayUrl': serializer.toJson<String>(relayUrl),
      'rangeStart': serializer.toJson<int>(rangeStart),
      'rangeEnd': serializer.toJson<int>(rangeEnd),
    };
  }

  DbFilterFetchedRangeRecord copyWith({
    String? key,
    String? filterHash,
    String? relayUrl,
    int? rangeStart,
    int? rangeEnd,
  }) => DbFilterFetchedRangeRecord(
    key: key ?? this.key,
    filterHash: filterHash ?? this.filterHash,
    relayUrl: relayUrl ?? this.relayUrl,
    rangeStart: rangeStart ?? this.rangeStart,
    rangeEnd: rangeEnd ?? this.rangeEnd,
  );
  DbFilterFetchedRangeRecord copyWithCompanion(
    FilterFetchedRangeRecordsCompanion data,
  ) {
    return DbFilterFetchedRangeRecord(
      key: data.key.present ? data.key.value : this.key,
      filterHash: data.filterHash.present
          ? data.filterHash.value
          : this.filterHash,
      relayUrl: data.relayUrl.present ? data.relayUrl.value : this.relayUrl,
      rangeStart: data.rangeStart.present
          ? data.rangeStart.value
          : this.rangeStart,
      rangeEnd: data.rangeEnd.present ? data.rangeEnd.value : this.rangeEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbFilterFetchedRangeRecord(')
          ..write('key: $key, ')
          ..write('filterHash: $filterHash, ')
          ..write('relayUrl: $relayUrl, ')
          ..write('rangeStart: $rangeStart, ')
          ..write('rangeEnd: $rangeEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, filterHash, relayUrl, rangeStart, rangeEnd);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbFilterFetchedRangeRecord &&
          other.key == this.key &&
          other.filterHash == this.filterHash &&
          other.relayUrl == this.relayUrl &&
          other.rangeStart == this.rangeStart &&
          other.rangeEnd == this.rangeEnd);
}

class FilterFetchedRangeRecordsCompanion
    extends UpdateCompanion<DbFilterFetchedRangeRecord> {
  final Value<String> key;
  final Value<String> filterHash;
  final Value<String> relayUrl;
  final Value<int> rangeStart;
  final Value<int> rangeEnd;
  final Value<int> rowid;
  const FilterFetchedRangeRecordsCompanion({
    this.key = const Value.absent(),
    this.filterHash = const Value.absent(),
    this.relayUrl = const Value.absent(),
    this.rangeStart = const Value.absent(),
    this.rangeEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilterFetchedRangeRecordsCompanion.insert({
    required String key,
    required String filterHash,
    required String relayUrl,
    required int rangeStart,
    required int rangeEnd,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       filterHash = Value(filterHash),
       relayUrl = Value(relayUrl),
       rangeStart = Value(rangeStart),
       rangeEnd = Value(rangeEnd);
  static Insertable<DbFilterFetchedRangeRecord> custom({
    Expression<String>? key,
    Expression<String>? filterHash,
    Expression<String>? relayUrl,
    Expression<int>? rangeStart,
    Expression<int>? rangeEnd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (filterHash != null) 'filter_hash': filterHash,
      if (relayUrl != null) 'relay_url': relayUrl,
      if (rangeStart != null) 'range_start': rangeStart,
      if (rangeEnd != null) 'range_end': rangeEnd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilterFetchedRangeRecordsCompanion copyWith({
    Value<String>? key,
    Value<String>? filterHash,
    Value<String>? relayUrl,
    Value<int>? rangeStart,
    Value<int>? rangeEnd,
    Value<int>? rowid,
  }) {
    return FilterFetchedRangeRecordsCompanion(
      key: key ?? this.key,
      filterHash: filterHash ?? this.filterHash,
      relayUrl: relayUrl ?? this.relayUrl,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (filterHash.present) {
      map['filter_hash'] = Variable<String>(filterHash.value);
    }
    if (relayUrl.present) {
      map['relay_url'] = Variable<String>(relayUrl.value);
    }
    if (rangeStart.present) {
      map['range_start'] = Variable<int>(rangeStart.value);
    }
    if (rangeEnd.present) {
      map['range_end'] = Variable<int>(rangeEnd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilterFetchedRangeRecordsCompanion(')
          ..write('key: $key, ')
          ..write('filterHash: $filterHash, ')
          ..write('relayUrl: $relayUrl, ')
          ..write('rangeStart: $rangeStart, ')
          ..write('rangeEnd: $rangeEnd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventSourcesTableTable extends EventSourcesTable
    with TableInfo<$EventSourcesTableTable, DbEventSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventSourcesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relayUrlMeta = const VerificationMeta(
    'relayUrl',
  );
  @override
  late final GeneratedColumn<String> relayUrl = GeneratedColumn<String>(
    'relay_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, relayUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_sources_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbEventSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('relay_url')) {
      context.handle(
        _relayUrlMeta,
        relayUrl.isAcceptableOrUnknown(data['relay_url']!, _relayUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_relayUrlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, relayUrl};
  @override
  DbEventSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbEventSource(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      relayUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_url'],
      )!,
    );
  }

  @override
  $EventSourcesTableTable createAlias(String alias) {
    return $EventSourcesTableTable(attachedDatabase, alias);
  }
}

class DbEventSource extends DataClass implements Insertable<DbEventSource> {
  final String eventId;
  final String relayUrl;
  const DbEventSource({required this.eventId, required this.relayUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['relay_url'] = Variable<String>(relayUrl);
    return map;
  }

  EventSourcesTableCompanion toCompanion(bool nullToAbsent) {
    return EventSourcesTableCompanion(
      eventId: Value(eventId),
      relayUrl: Value(relayUrl),
    );
  }

  factory DbEventSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbEventSource(
      eventId: serializer.fromJson<String>(json['eventId']),
      relayUrl: serializer.fromJson<String>(json['relayUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'relayUrl': serializer.toJson<String>(relayUrl),
    };
  }

  DbEventSource copyWith({String? eventId, String? relayUrl}) => DbEventSource(
    eventId: eventId ?? this.eventId,
    relayUrl: relayUrl ?? this.relayUrl,
  );
  DbEventSource copyWithCompanion(EventSourcesTableCompanion data) {
    return DbEventSource(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      relayUrl: data.relayUrl.present ? data.relayUrl.value : this.relayUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbEventSource(')
          ..write('eventId: $eventId, ')
          ..write('relayUrl: $relayUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, relayUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbEventSource &&
          other.eventId == this.eventId &&
          other.relayUrl == this.relayUrl);
}

class EventSourcesTableCompanion extends UpdateCompanion<DbEventSource> {
  final Value<String> eventId;
  final Value<String> relayUrl;
  final Value<int> rowid;
  const EventSourcesTableCompanion({
    this.eventId = const Value.absent(),
    this.relayUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventSourcesTableCompanion.insert({
    required String eventId,
    required String relayUrl,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       relayUrl = Value(relayUrl);
  static Insertable<DbEventSource> custom({
    Expression<String>? eventId,
    Expression<String>? relayUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (relayUrl != null) 'relay_url': relayUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventSourcesTableCompanion copyWith({
    Value<String>? eventId,
    Value<String>? relayUrl,
    Value<int>? rowid,
  }) {
    return EventSourcesTableCompanion(
      eventId: eventId ?? this.eventId,
      relayUrl: relayUrl ?? this.relayUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (relayUrl.present) {
      map['relay_url'] = Variable<String>(relayUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventSourcesTableCompanion(')
          ..write('eventId: $eventId, ')
          ..write('relayUrl: $relayUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventDeliveryRecordsTableTable extends EventDeliveryRecordsTable
    with TableInfo<$EventDeliveryRecordsTableTable, DbEventDeliveryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventDeliveryRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signedAtMeta = const VerificationMeta(
    'signedAt',
  );
  @override
  late final GeneratedColumn<int> signedAt = GeneratedColumn<int>(
    'signed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiresNetworkSignerMeta =
      const VerificationMeta('requiresNetworkSigner');
  @override
  late final GeneratedColumn<bool> requiresNetworkSigner =
      GeneratedColumn<bool>(
        'requires_network_signer',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requires_network_signer" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    status,
    createdAt,
    updatedAt,
    signedAt,
    completedAt,
    requiresNetworkSigner,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_delivery_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbEventDeliveryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('signed_at')) {
      context.handle(
        _signedAtMeta,
        signedAt.isAcceptableOrUnknown(data['signed_at']!, _signedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('requires_network_signer')) {
      context.handle(
        _requiresNetworkSignerMeta,
        requiresNetworkSigner.isAcceptableOrUnknown(
          data['requires_network_signer']!,
          _requiresNetworkSignerMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  DbEventDeliveryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbEventDeliveryRecord(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      signedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}signed_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      requiresNetworkSigner: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_network_signer'],
      )!,
    );
  }

  @override
  $EventDeliveryRecordsTableTable createAlias(String alias) {
    return $EventDeliveryRecordsTableTable(attachedDatabase, alias);
  }
}

class DbEventDeliveryRecord extends DataClass
    implements Insertable<DbEventDeliveryRecord> {
  final String eventId;
  final String status;
  final int createdAt;
  final int updatedAt;
  final int? signedAt;
  final int? completedAt;
  final bool requiresNetworkSigner;
  const DbEventDeliveryRecord({
    required this.eventId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.signedAt,
    this.completedAt,
    required this.requiresNetworkSigner,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || signedAt != null) {
      map['signed_at'] = Variable<int>(signedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['requires_network_signer'] = Variable<bool>(requiresNetworkSigner);
    return map;
  }

  EventDeliveryRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return EventDeliveryRecordsTableCompanion(
      eventId: Value(eventId),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      signedAt: signedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(signedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      requiresNetworkSigner: Value(requiresNetworkSigner),
    );
  }

  factory DbEventDeliveryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbEventDeliveryRecord(
      eventId: serializer.fromJson<String>(json['eventId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      signedAt: serializer.fromJson<int?>(json['signedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      requiresNetworkSigner: serializer.fromJson<bool>(
        json['requiresNetworkSigner'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'signedAt': serializer.toJson<int?>(signedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'requiresNetworkSigner': serializer.toJson<bool>(requiresNetworkSigner),
    };
  }

  DbEventDeliveryRecord copyWith({
    String? eventId,
    String? status,
    int? createdAt,
    int? updatedAt,
    Value<int?> signedAt = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
    bool? requiresNetworkSigner,
  }) => DbEventDeliveryRecord(
    eventId: eventId ?? this.eventId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    signedAt: signedAt.present ? signedAt.value : this.signedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    requiresNetworkSigner: requiresNetworkSigner ?? this.requiresNetworkSigner,
  );
  DbEventDeliveryRecord copyWithCompanion(
    EventDeliveryRecordsTableCompanion data,
  ) {
    return DbEventDeliveryRecord(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      signedAt: data.signedAt.present ? data.signedAt.value : this.signedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      requiresNetworkSigner: data.requiresNetworkSigner.present
          ? data.requiresNetworkSigner.value
          : this.requiresNetworkSigner,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbEventDeliveryRecord(')
          ..write('eventId: $eventId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('signedAt: $signedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('requiresNetworkSigner: $requiresNetworkSigner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    status,
    createdAt,
    updatedAt,
    signedAt,
    completedAt,
    requiresNetworkSigner,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbEventDeliveryRecord &&
          other.eventId == this.eventId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.signedAt == this.signedAt &&
          other.completedAt == this.completedAt &&
          other.requiresNetworkSigner == this.requiresNetworkSigner);
}

class EventDeliveryRecordsTableCompanion
    extends UpdateCompanion<DbEventDeliveryRecord> {
  final Value<String> eventId;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> signedAt;
  final Value<int?> completedAt;
  final Value<bool> requiresNetworkSigner;
  final Value<int> rowid;
  const EventDeliveryRecordsTableCompanion({
    this.eventId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.signedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.requiresNetworkSigner = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventDeliveryRecordsTableCompanion.insert({
    required String eventId,
    required String status,
    required int createdAt,
    required int updatedAt,
    this.signedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.requiresNetworkSigner = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DbEventDeliveryRecord> custom({
    Expression<String>? eventId,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? signedAt,
    Expression<int>? completedAt,
    Expression<bool>? requiresNetworkSigner,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (signedAt != null) 'signed_at': signedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (requiresNetworkSigner != null)
        'requires_network_signer': requiresNetworkSigner,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventDeliveryRecordsTableCompanion copyWith({
    Value<String>? eventId,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? signedAt,
    Value<int?>? completedAt,
    Value<bool>? requiresNetworkSigner,
    Value<int>? rowid,
  }) {
    return EventDeliveryRecordsTableCompanion(
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      signedAt: signedAt ?? this.signedAt,
      completedAt: completedAt ?? this.completedAt,
      requiresNetworkSigner:
          requiresNetworkSigner ?? this.requiresNetworkSigner,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (signedAt.present) {
      map['signed_at'] = Variable<int>(signedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (requiresNetworkSigner.present) {
      map['requires_network_signer'] = Variable<bool>(
        requiresNetworkSigner.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventDeliveryRecordsTableCompanion(')
          ..write('eventId: $eventId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('signedAt: $signedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('requiresNetworkSigner: $requiresNetworkSigner, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelayDeliveryTargetsTableTable extends RelayDeliveryTargetsTable
    with TableInfo<$RelayDeliveryTargetsTableTable, DbRelayDeliveryTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelayDeliveryTargetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relayUrlMeta = const VerificationMeta(
    'relayUrl',
  );
  @override
  late final GeneratedColumn<String> relayUrl = GeneratedColumn<String>(
    'relay_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<int> nextRetryAt = GeneratedColumn<int>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastOkMessageMeta = const VerificationMeta(
    'lastOkMessage',
  );
  @override
  late final GeneratedColumn<String> lastOkMessage = GeneratedColumn<String>(
    'last_ok_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    relayUrl,
    reason,
    state,
    attemptCount,
    lastAttemptAt,
    nextRetryAt,
    lastError,
    lastOkMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relay_delivery_targets_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbRelayDeliveryTarget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('relay_url')) {
      context.handle(
        _relayUrlMeta,
        relayUrl.isAcceptableOrUnknown(data['relay_url']!, _relayUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_relayUrlMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_ok_message')) {
      context.handle(
        _lastOkMessageMeta,
        lastOkMessage.isAcceptableOrUnknown(
          data['last_ok_message']!,
          _lastOkMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, relayUrl};
  @override
  DbRelayDeliveryTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbRelayDeliveryTarget(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      relayUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_url'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_retry_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastOkMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_ok_message'],
      ),
    );
  }

  @override
  $RelayDeliveryTargetsTableTable createAlias(String alias) {
    return $RelayDeliveryTargetsTableTable(attachedDatabase, alias);
  }
}

class DbRelayDeliveryTarget extends DataClass
    implements Insertable<DbRelayDeliveryTarget> {
  final String eventId;
  final String relayUrl;
  final String reason;
  final String state;
  final int attemptCount;
  final int? lastAttemptAt;
  final int? nextRetryAt;
  final String? lastError;
  final String? lastOkMessage;
  const DbRelayDeliveryTarget({
    required this.eventId,
    required this.relayUrl,
    required this.reason,
    required this.state,
    required this.attemptCount,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.lastError,
    this.lastOkMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['relay_url'] = Variable<String>(relayUrl);
    map['reason'] = Variable<String>(reason);
    map['state'] = Variable<String>(state);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<int>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastOkMessage != null) {
      map['last_ok_message'] = Variable<String>(lastOkMessage);
    }
    return map;
  }

  RelayDeliveryTargetsTableCompanion toCompanion(bool nullToAbsent) {
    return RelayDeliveryTargetsTableCompanion(
      eventId: Value(eventId),
      relayUrl: Value(relayUrl),
      reason: Value(reason),
      state: Value(state),
      attemptCount: Value(attemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastOkMessage: lastOkMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOkMessage),
    );
  }

  factory DbRelayDeliveryTarget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbRelayDeliveryTarget(
      eventId: serializer.fromJson<String>(json['eventId']),
      relayUrl: serializer.fromJson<String>(json['relayUrl']),
      reason: serializer.fromJson<String>(json['reason']),
      state: serializer.fromJson<String>(json['state']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      nextRetryAt: serializer.fromJson<int?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastOkMessage: serializer.fromJson<String?>(json['lastOkMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'relayUrl': serializer.toJson<String>(relayUrl),
      'reason': serializer.toJson<String>(reason),
      'state': serializer.toJson<String>(state),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'nextRetryAt': serializer.toJson<int?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'lastOkMessage': serializer.toJson<String?>(lastOkMessage),
    };
  }

  DbRelayDeliveryTarget copyWith({
    String? eventId,
    String? relayUrl,
    String? reason,
    String? state,
    int? attemptCount,
    Value<int?> lastAttemptAt = const Value.absent(),
    Value<int?> nextRetryAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> lastOkMessage = const Value.absent(),
  }) => DbRelayDeliveryTarget(
    eventId: eventId ?? this.eventId,
    relayUrl: relayUrl ?? this.relayUrl,
    reason: reason ?? this.reason,
    state: state ?? this.state,
    attemptCount: attemptCount ?? this.attemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastOkMessage: lastOkMessage.present
        ? lastOkMessage.value
        : this.lastOkMessage,
  );
  DbRelayDeliveryTarget copyWithCompanion(
    RelayDeliveryTargetsTableCompanion data,
  ) {
    return DbRelayDeliveryTarget(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      relayUrl: data.relayUrl.present ? data.relayUrl.value : this.relayUrl,
      reason: data.reason.present ? data.reason.value : this.reason,
      state: data.state.present ? data.state.value : this.state,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastOkMessage: data.lastOkMessage.present
          ? data.lastOkMessage.value
          : this.lastOkMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbRelayDeliveryTarget(')
          ..write('eventId: $eventId, ')
          ..write('relayUrl: $relayUrl, ')
          ..write('reason: $reason, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('lastOkMessage: $lastOkMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    relayUrl,
    reason,
    state,
    attemptCount,
    lastAttemptAt,
    nextRetryAt,
    lastError,
    lastOkMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbRelayDeliveryTarget &&
          other.eventId == this.eventId &&
          other.relayUrl == this.relayUrl &&
          other.reason == this.reason &&
          other.state == this.state &&
          other.attemptCount == this.attemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.lastOkMessage == this.lastOkMessage);
}

class RelayDeliveryTargetsTableCompanion
    extends UpdateCompanion<DbRelayDeliveryTarget> {
  final Value<String> eventId;
  final Value<String> relayUrl;
  final Value<String> reason;
  final Value<String> state;
  final Value<int> attemptCount;
  final Value<int?> lastAttemptAt;
  final Value<int?> nextRetryAt;
  final Value<String?> lastError;
  final Value<String?> lastOkMessage;
  final Value<int> rowid;
  const RelayDeliveryTargetsTableCompanion({
    this.eventId = const Value.absent(),
    this.relayUrl = const Value.absent(),
    this.reason = const Value.absent(),
    this.state = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastOkMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelayDeliveryTargetsTableCompanion.insert({
    required String eventId,
    required String relayUrl,
    required String reason,
    required String state,
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastOkMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       relayUrl = Value(relayUrl),
       reason = Value(reason),
       state = Value(state);
  static Insertable<DbRelayDeliveryTarget> custom({
    Expression<String>? eventId,
    Expression<String>? relayUrl,
    Expression<String>? reason,
    Expression<String>? state,
    Expression<int>? attemptCount,
    Expression<int>? lastAttemptAt,
    Expression<int>? nextRetryAt,
    Expression<String>? lastError,
    Expression<String>? lastOkMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (relayUrl != null) 'relay_url': relayUrl,
      if (reason != null) 'reason': reason,
      if (state != null) 'state': state,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (lastOkMessage != null) 'last_ok_message': lastOkMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelayDeliveryTargetsTableCompanion copyWith({
    Value<String>? eventId,
    Value<String>? relayUrl,
    Value<String>? reason,
    Value<String>? state,
    Value<int>? attemptCount,
    Value<int?>? lastAttemptAt,
    Value<int?>? nextRetryAt,
    Value<String?>? lastError,
    Value<String?>? lastOkMessage,
    Value<int>? rowid,
  }) {
    return RelayDeliveryTargetsTableCompanion(
      eventId: eventId ?? this.eventId,
      relayUrl: relayUrl ?? this.relayUrl,
      reason: reason ?? this.reason,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      lastOkMessage: lastOkMessage ?? this.lastOkMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (relayUrl.present) {
      map['relay_url'] = Variable<String>(relayUrl.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<int>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastOkMessage.present) {
      map['last_ok_message'] = Variable<String>(lastOkMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelayDeliveryTargetsTableCompanion(')
          ..write('eventId: $eventId, ')
          ..write('relayUrl: $relayUrl, ')
          ..write('reason: $reason, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('lastOkMessage: $lastOkMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashuProofsTable extends CashuProofs
    with TableInfo<$CashuProofsTable, DbCashuProof> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashuProofsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _YMeta = const VerificationMeta('Y');
  @override
  late final GeneratedColumn<String> Y = GeneratedColumn<String>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keysetIdMeta = const VerificationMeta(
    'keysetId',
  );
  @override
  late final GeneratedColumn<String> keysetId = GeneratedColumn<String>(
    'keyset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secretMeta = const VerificationMeta('secret');
  @override
  late final GeneratedColumn<String> secret = GeneratedColumn<String>(
    'secret',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unblindedSigMeta = const VerificationMeta(
    'unblindedSig',
  );
  @override
  late final GeneratedColumn<String> unblindedSig = GeneratedColumn<String>(
    'unblinded_sig',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mintUrlMeta = const VerificationMeta(
    'mintUrl',
  );
  @override
  late final GeneratedColumn<String> mintUrl = GeneratedColumn<String>(
    'mint_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    Y,
    keysetId,
    amount,
    secret,
    unblindedSig,
    state,
    mintUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cashu_proofs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbCashuProof> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('y')) {
      context.handle(_YMeta, Y.isAcceptableOrUnknown(data['y']!, _YMeta));
    } else if (isInserting) {
      context.missing(_YMeta);
    }
    if (data.containsKey('keyset_id')) {
      context.handle(
        _keysetIdMeta,
        keysetId.isAcceptableOrUnknown(data['keyset_id']!, _keysetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_keysetIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('secret')) {
      context.handle(
        _secretMeta,
        secret.isAcceptableOrUnknown(data['secret']!, _secretMeta),
      );
    } else if (isInserting) {
      context.missing(_secretMeta);
    }
    if (data.containsKey('unblinded_sig')) {
      context.handle(
        _unblindedSigMeta,
        unblindedSig.isAcceptableOrUnknown(
          data['unblinded_sig']!,
          _unblindedSigMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unblindedSigMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('mint_url')) {
      context.handle(
        _mintUrlMeta,
        mintUrl.isAcceptableOrUnknown(data['mint_url']!, _mintUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_mintUrlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {Y};
  @override
  DbCashuProof map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCashuProof(
      Y: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}y'],
      )!,
      keysetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keyset_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      secret: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret'],
      )!,
      unblindedSig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unblinded_sig'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      mintUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mint_url'],
      )!,
    );
  }

  @override
  $CashuProofsTable createAlias(String alias) {
    return $CashuProofsTable(attachedDatabase, alias);
  }
}

class DbCashuProof extends DataClass implements Insertable<DbCashuProof> {
  final String Y;
  final String keysetId;
  final int amount;
  final String secret;
  final String unblindedSig;
  final String state;
  final String mintUrl;
  const DbCashuProof({
    required this.Y,
    required this.keysetId,
    required this.amount,
    required this.secret,
    required this.unblindedSig,
    required this.state,
    required this.mintUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['y'] = Variable<String>(Y);
    map['keyset_id'] = Variable<String>(keysetId);
    map['amount'] = Variable<int>(amount);
    map['secret'] = Variable<String>(secret);
    map['unblinded_sig'] = Variable<String>(unblindedSig);
    map['state'] = Variable<String>(state);
    map['mint_url'] = Variable<String>(mintUrl);
    return map;
  }

  CashuProofsCompanion toCompanion(bool nullToAbsent) {
    return CashuProofsCompanion(
      Y: Value(Y),
      keysetId: Value(keysetId),
      amount: Value(amount),
      secret: Value(secret),
      unblindedSig: Value(unblindedSig),
      state: Value(state),
      mintUrl: Value(mintUrl),
    );
  }

  factory DbCashuProof.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCashuProof(
      Y: serializer.fromJson<String>(json['Y']),
      keysetId: serializer.fromJson<String>(json['keysetId']),
      amount: serializer.fromJson<int>(json['amount']),
      secret: serializer.fromJson<String>(json['secret']),
      unblindedSig: serializer.fromJson<String>(json['unblindedSig']),
      state: serializer.fromJson<String>(json['state']),
      mintUrl: serializer.fromJson<String>(json['mintUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'Y': serializer.toJson<String>(Y),
      'keysetId': serializer.toJson<String>(keysetId),
      'amount': serializer.toJson<int>(amount),
      'secret': serializer.toJson<String>(secret),
      'unblindedSig': serializer.toJson<String>(unblindedSig),
      'state': serializer.toJson<String>(state),
      'mintUrl': serializer.toJson<String>(mintUrl),
    };
  }

  DbCashuProof copyWith({
    String? Y,
    String? keysetId,
    int? amount,
    String? secret,
    String? unblindedSig,
    String? state,
    String? mintUrl,
  }) => DbCashuProof(
    Y: Y ?? this.Y,
    keysetId: keysetId ?? this.keysetId,
    amount: amount ?? this.amount,
    secret: secret ?? this.secret,
    unblindedSig: unblindedSig ?? this.unblindedSig,
    state: state ?? this.state,
    mintUrl: mintUrl ?? this.mintUrl,
  );
  DbCashuProof copyWithCompanion(CashuProofsCompanion data) {
    return DbCashuProof(
      Y: data.Y.present ? data.Y.value : this.Y,
      keysetId: data.keysetId.present ? data.keysetId.value : this.keysetId,
      amount: data.amount.present ? data.amount.value : this.amount,
      secret: data.secret.present ? data.secret.value : this.secret,
      unblindedSig: data.unblindedSig.present
          ? data.unblindedSig.value
          : this.unblindedSig,
      state: data.state.present ? data.state.value : this.state,
      mintUrl: data.mintUrl.present ? data.mintUrl.value : this.mintUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCashuProof(')
          ..write('Y: $Y, ')
          ..write('keysetId: $keysetId, ')
          ..write('amount: $amount, ')
          ..write('secret: $secret, ')
          ..write('unblindedSig: $unblindedSig, ')
          ..write('state: $state, ')
          ..write('mintUrl: $mintUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(Y, keysetId, amount, secret, unblindedSig, state, mintUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCashuProof &&
          other.Y == this.Y &&
          other.keysetId == this.keysetId &&
          other.amount == this.amount &&
          other.secret == this.secret &&
          other.unblindedSig == this.unblindedSig &&
          other.state == this.state &&
          other.mintUrl == this.mintUrl);
}

class CashuProofsCompanion extends UpdateCompanion<DbCashuProof> {
  final Value<String> Y;
  final Value<String> keysetId;
  final Value<int> amount;
  final Value<String> secret;
  final Value<String> unblindedSig;
  final Value<String> state;
  final Value<String> mintUrl;
  final Value<int> rowid;
  const CashuProofsCompanion({
    this.Y = const Value.absent(),
    this.keysetId = const Value.absent(),
    this.amount = const Value.absent(),
    this.secret = const Value.absent(),
    this.unblindedSig = const Value.absent(),
    this.state = const Value.absent(),
    this.mintUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashuProofsCompanion.insert({
    required String Y,
    required String keysetId,
    required int amount,
    required String secret,
    required String unblindedSig,
    required String state,
    required String mintUrl,
    this.rowid = const Value.absent(),
  }) : Y = Value(Y),
       keysetId = Value(keysetId),
       amount = Value(amount),
       secret = Value(secret),
       unblindedSig = Value(unblindedSig),
       state = Value(state),
       mintUrl = Value(mintUrl);
  static Insertable<DbCashuProof> custom({
    Expression<String>? Y,
    Expression<String>? keysetId,
    Expression<int>? amount,
    Expression<String>? secret,
    Expression<String>? unblindedSig,
    Expression<String>? state,
    Expression<String>? mintUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (Y != null) 'y': Y,
      if (keysetId != null) 'keyset_id': keysetId,
      if (amount != null) 'amount': amount,
      if (secret != null) 'secret': secret,
      if (unblindedSig != null) 'unblinded_sig': unblindedSig,
      if (state != null) 'state': state,
      if (mintUrl != null) 'mint_url': mintUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashuProofsCompanion copyWith({
    Value<String>? Y,
    Value<String>? keysetId,
    Value<int>? amount,
    Value<String>? secret,
    Value<String>? unblindedSig,
    Value<String>? state,
    Value<String>? mintUrl,
    Value<int>? rowid,
  }) {
    return CashuProofsCompanion(
      Y: Y ?? this.Y,
      keysetId: keysetId ?? this.keysetId,
      amount: amount ?? this.amount,
      secret: secret ?? this.secret,
      unblindedSig: unblindedSig ?? this.unblindedSig,
      state: state ?? this.state,
      mintUrl: mintUrl ?? this.mintUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (Y.present) {
      map['y'] = Variable<String>(Y.value);
    }
    if (keysetId.present) {
      map['keyset_id'] = Variable<String>(keysetId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (secret.present) {
      map['secret'] = Variable<String>(secret.value);
    }
    if (unblindedSig.present) {
      map['unblinded_sig'] = Variable<String>(unblindedSig.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (mintUrl.present) {
      map['mint_url'] = Variable<String>(mintUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashuProofsCompanion(')
          ..write('Y: $Y, ')
          ..write('keysetId: $keysetId, ')
          ..write('amount: $amount, ')
          ..write('secret: $secret, ')
          ..write('unblindedSig: $unblindedSig, ')
          ..write('state: $state, ')
          ..write('mintUrl: $mintUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashuKeysetsTable extends CashuKeysets
    with TableInfo<$CashuKeysetsTable, DbCashuKeyset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashuKeysetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mintUrlMeta = const VerificationMeta(
    'mintUrl',
  );
  @override
  late final GeneratedColumn<String> mintUrl = GeneratedColumn<String>(
    'mint_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _inputFeePPKMeta = const VerificationMeta(
    'inputFeePPK',
  );
  @override
  late final GeneratedColumn<int> inputFeePPK = GeneratedColumn<int>(
    'input_fee_p_p_k',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mintKeyPairsJsonMeta = const VerificationMeta(
    'mintKeyPairsJson',
  );
  @override
  late final GeneratedColumn<String> mintKeyPairsJson = GeneratedColumn<String>(
    'mint_key_pairs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mintUrl,
    unit,
    active,
    inputFeePPK,
    mintKeyPairsJson,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cashu_keysets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbCashuKeyset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mint_url')) {
      context.handle(
        _mintUrlMeta,
        mintUrl.isAcceptableOrUnknown(data['mint_url']!, _mintUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_mintUrlMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('input_fee_p_p_k')) {
      context.handle(
        _inputFeePPKMeta,
        inputFeePPK.isAcceptableOrUnknown(
          data['input_fee_p_p_k']!,
          _inputFeePPKMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputFeePPKMeta);
    }
    if (data.containsKey('mint_key_pairs_json')) {
      context.handle(
        _mintKeyPairsJsonMeta,
        mintKeyPairsJson.isAcceptableOrUnknown(
          data['mint_key_pairs_json']!,
          _mintKeyPairsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mintKeyPairsJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, mintUrl};
  @override
  DbCashuKeyset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCashuKeyset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mintUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mint_url'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      inputFeePPK: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_fee_p_p_k'],
      )!,
      mintKeyPairsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mint_key_pairs_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      ),
    );
  }

  @override
  $CashuKeysetsTable createAlias(String alias) {
    return $CashuKeysetsTable(attachedDatabase, alias);
  }
}

class DbCashuKeyset extends DataClass implements Insertable<DbCashuKeyset> {
  final String id;
  final String mintUrl;
  final String unit;
  final bool active;
  final int inputFeePPK;
  final String mintKeyPairsJson;
  final int? fetchedAt;
  const DbCashuKeyset({
    required this.id,
    required this.mintUrl,
    required this.unit,
    required this.active,
    required this.inputFeePPK,
    required this.mintKeyPairsJson,
    this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mint_url'] = Variable<String>(mintUrl);
    map['unit'] = Variable<String>(unit);
    map['active'] = Variable<bool>(active);
    map['input_fee_p_p_k'] = Variable<int>(inputFeePPK);
    map['mint_key_pairs_json'] = Variable<String>(mintKeyPairsJson);
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<int>(fetchedAt);
    }
    return map;
  }

  CashuKeysetsCompanion toCompanion(bool nullToAbsent) {
    return CashuKeysetsCompanion(
      id: Value(id),
      mintUrl: Value(mintUrl),
      unit: Value(unit),
      active: Value(active),
      inputFeePPK: Value(inputFeePPK),
      mintKeyPairsJson: Value(mintKeyPairsJson),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
    );
  }

  factory DbCashuKeyset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCashuKeyset(
      id: serializer.fromJson<String>(json['id']),
      mintUrl: serializer.fromJson<String>(json['mintUrl']),
      unit: serializer.fromJson<String>(json['unit']),
      active: serializer.fromJson<bool>(json['active']),
      inputFeePPK: serializer.fromJson<int>(json['inputFeePPK']),
      mintKeyPairsJson: serializer.fromJson<String>(json['mintKeyPairsJson']),
      fetchedAt: serializer.fromJson<int?>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mintUrl': serializer.toJson<String>(mintUrl),
      'unit': serializer.toJson<String>(unit),
      'active': serializer.toJson<bool>(active),
      'inputFeePPK': serializer.toJson<int>(inputFeePPK),
      'mintKeyPairsJson': serializer.toJson<String>(mintKeyPairsJson),
      'fetchedAt': serializer.toJson<int?>(fetchedAt),
    };
  }

  DbCashuKeyset copyWith({
    String? id,
    String? mintUrl,
    String? unit,
    bool? active,
    int? inputFeePPK,
    String? mintKeyPairsJson,
    Value<int?> fetchedAt = const Value.absent(),
  }) => DbCashuKeyset(
    id: id ?? this.id,
    mintUrl: mintUrl ?? this.mintUrl,
    unit: unit ?? this.unit,
    active: active ?? this.active,
    inputFeePPK: inputFeePPK ?? this.inputFeePPK,
    mintKeyPairsJson: mintKeyPairsJson ?? this.mintKeyPairsJson,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
  );
  DbCashuKeyset copyWithCompanion(CashuKeysetsCompanion data) {
    return DbCashuKeyset(
      id: data.id.present ? data.id.value : this.id,
      mintUrl: data.mintUrl.present ? data.mintUrl.value : this.mintUrl,
      unit: data.unit.present ? data.unit.value : this.unit,
      active: data.active.present ? data.active.value : this.active,
      inputFeePPK: data.inputFeePPK.present
          ? data.inputFeePPK.value
          : this.inputFeePPK,
      mintKeyPairsJson: data.mintKeyPairsJson.present
          ? data.mintKeyPairsJson.value
          : this.mintKeyPairsJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCashuKeyset(')
          ..write('id: $id, ')
          ..write('mintUrl: $mintUrl, ')
          ..write('unit: $unit, ')
          ..write('active: $active, ')
          ..write('inputFeePPK: $inputFeePPK, ')
          ..write('mintKeyPairsJson: $mintKeyPairsJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mintUrl,
    unit,
    active,
    inputFeePPK,
    mintKeyPairsJson,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCashuKeyset &&
          other.id == this.id &&
          other.mintUrl == this.mintUrl &&
          other.unit == this.unit &&
          other.active == this.active &&
          other.inputFeePPK == this.inputFeePPK &&
          other.mintKeyPairsJson == this.mintKeyPairsJson &&
          other.fetchedAt == this.fetchedAt);
}

class CashuKeysetsCompanion extends UpdateCompanion<DbCashuKeyset> {
  final Value<String> id;
  final Value<String> mintUrl;
  final Value<String> unit;
  final Value<bool> active;
  final Value<int> inputFeePPK;
  final Value<String> mintKeyPairsJson;
  final Value<int?> fetchedAt;
  final Value<int> rowid;
  const CashuKeysetsCompanion({
    this.id = const Value.absent(),
    this.mintUrl = const Value.absent(),
    this.unit = const Value.absent(),
    this.active = const Value.absent(),
    this.inputFeePPK = const Value.absent(),
    this.mintKeyPairsJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashuKeysetsCompanion.insert({
    required String id,
    required String mintUrl,
    required String unit,
    required bool active,
    required int inputFeePPK,
    required String mintKeyPairsJson,
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mintUrl = Value(mintUrl),
       unit = Value(unit),
       active = Value(active),
       inputFeePPK = Value(inputFeePPK),
       mintKeyPairsJson = Value(mintKeyPairsJson);
  static Insertable<DbCashuKeyset> custom({
    Expression<String>? id,
    Expression<String>? mintUrl,
    Expression<String>? unit,
    Expression<bool>? active,
    Expression<int>? inputFeePPK,
    Expression<String>? mintKeyPairsJson,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mintUrl != null) 'mint_url': mintUrl,
      if (unit != null) 'unit': unit,
      if (active != null) 'active': active,
      if (inputFeePPK != null) 'input_fee_p_p_k': inputFeePPK,
      if (mintKeyPairsJson != null) 'mint_key_pairs_json': mintKeyPairsJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashuKeysetsCompanion copyWith({
    Value<String>? id,
    Value<String>? mintUrl,
    Value<String>? unit,
    Value<bool>? active,
    Value<int>? inputFeePPK,
    Value<String>? mintKeyPairsJson,
    Value<int?>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CashuKeysetsCompanion(
      id: id ?? this.id,
      mintUrl: mintUrl ?? this.mintUrl,
      unit: unit ?? this.unit,
      active: active ?? this.active,
      inputFeePPK: inputFeePPK ?? this.inputFeePPK,
      mintKeyPairsJson: mintKeyPairsJson ?? this.mintKeyPairsJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mintUrl.present) {
      map['mint_url'] = Variable<String>(mintUrl.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (inputFeePPK.present) {
      map['input_fee_p_p_k'] = Variable<int>(inputFeePPK.value);
    }
    if (mintKeyPairsJson.present) {
      map['mint_key_pairs_json'] = Variable<String>(mintKeyPairsJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashuKeysetsCompanion(')
          ..write('id: $id, ')
          ..write('mintUrl: $mintUrl, ')
          ..write('unit: $unit, ')
          ..write('active: $active, ')
          ..write('inputFeePPK: $inputFeePPK, ')
          ..write('mintKeyPairsJson: $mintKeyPairsJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashuMintInfosTable extends CashuMintInfos
    with TableInfo<$CashuMintInfosTable, DbCashuMintInfo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashuMintInfosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlsJsonMeta = const VerificationMeta(
    'urlsJson',
  );
  @override
  late final GeneratedColumn<String> urlsJson = GeneratedColumn<String>(
    'urls_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
    'pubkey',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionLongMeta = const VerificationMeta(
    'descriptionLong',
  );
  @override
  late final GeneratedColumn<String> descriptionLong = GeneratedColumn<String>(
    'description_long',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactJsonMeta = const VerificationMeta(
    'contactJson',
  );
  @override
  late final GeneratedColumn<String> contactJson = GeneratedColumn<String>(
    'contact_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motdMeta = const VerificationMeta('motd');
  @override
  late final GeneratedColumn<String> motd = GeneratedColumn<String>(
    'motd',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tosUrlMeta = const VerificationMeta('tosUrl');
  @override
  late final GeneratedColumn<String> tosUrl = GeneratedColumn<String>(
    'tos_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nutsJsonMeta = const VerificationMeta(
    'nutsJson',
  );
  @override
  late final GeneratedColumn<String> nutsJson = GeneratedColumn<String>(
    'nuts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    urlsJson,
    name,
    pubkey,
    version,
    description,
    descriptionLong,
    contactJson,
    motd,
    iconUrl,
    time,
    tosUrl,
    nutsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cashu_mint_infos';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbCashuMintInfo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('urls_json')) {
      context.handle(
        _urlsJsonMeta,
        urlsJson.isAcceptableOrUnknown(data['urls_json']!, _urlsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_urlsJsonMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('pubkey')) {
      context.handle(
        _pubkeyMeta,
        pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('description_long')) {
      context.handle(
        _descriptionLongMeta,
        descriptionLong.isAcceptableOrUnknown(
          data['description_long']!,
          _descriptionLongMeta,
        ),
      );
    }
    if (data.containsKey('contact_json')) {
      context.handle(
        _contactJsonMeta,
        contactJson.isAcceptableOrUnknown(
          data['contact_json']!,
          _contactJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactJsonMeta);
    }
    if (data.containsKey('motd')) {
      context.handle(
        _motdMeta,
        motd.isAcceptableOrUnknown(data['motd']!, _motdMeta),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('tos_url')) {
      context.handle(
        _tosUrlMeta,
        tosUrl.isAcceptableOrUnknown(data['tos_url']!, _tosUrlMeta),
      );
    }
    if (data.containsKey('nuts_json')) {
      context.handle(
        _nutsJsonMeta,
        nutsJson.isAcceptableOrUnknown(data['nuts_json']!, _nutsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_nutsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbCashuMintInfo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCashuMintInfo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      urlsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}urls_json'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      pubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubkey'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      descriptionLong: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_long'],
      ),
      contactJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_json'],
      )!,
      motd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motd'],
      ),
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time'],
      ),
      tosUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tos_url'],
      ),
      nutsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nuts_json'],
      )!,
    );
  }

  @override
  $CashuMintInfosTable createAlias(String alias) {
    return $CashuMintInfosTable(attachedDatabase, alias);
  }
}

class DbCashuMintInfo extends DataClass implements Insertable<DbCashuMintInfo> {
  final String id;
  final String urlsJson;
  final String? name;
  final String? pubkey;
  final String? version;
  final String? description;
  final String? descriptionLong;
  final String contactJson;
  final String? motd;
  final String? iconUrl;
  final int? time;
  final String? tosUrl;
  final String nutsJson;
  const DbCashuMintInfo({
    required this.id,
    required this.urlsJson,
    this.name,
    this.pubkey,
    this.version,
    this.description,
    this.descriptionLong,
    required this.contactJson,
    this.motd,
    this.iconUrl,
    this.time,
    this.tosUrl,
    required this.nutsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['urls_json'] = Variable<String>(urlsJson);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || pubkey != null) {
      map['pubkey'] = Variable<String>(pubkey);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || descriptionLong != null) {
      map['description_long'] = Variable<String>(descriptionLong);
    }
    map['contact_json'] = Variable<String>(contactJson);
    if (!nullToAbsent || motd != null) {
      map['motd'] = Variable<String>(motd);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<int>(time);
    }
    if (!nullToAbsent || tosUrl != null) {
      map['tos_url'] = Variable<String>(tosUrl);
    }
    map['nuts_json'] = Variable<String>(nutsJson);
    return map;
  }

  CashuMintInfosCompanion toCompanion(bool nullToAbsent) {
    return CashuMintInfosCompanion(
      id: Value(id),
      urlsJson: Value(urlsJson),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      pubkey: pubkey == null && nullToAbsent
          ? const Value.absent()
          : Value(pubkey),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      descriptionLong: descriptionLong == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionLong),
      contactJson: Value(contactJson),
      motd: motd == null && nullToAbsent ? const Value.absent() : Value(motd),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      tosUrl: tosUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(tosUrl),
      nutsJson: Value(nutsJson),
    );
  }

  factory DbCashuMintInfo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCashuMintInfo(
      id: serializer.fromJson<String>(json['id']),
      urlsJson: serializer.fromJson<String>(json['urlsJson']),
      name: serializer.fromJson<String?>(json['name']),
      pubkey: serializer.fromJson<String?>(json['pubkey']),
      version: serializer.fromJson<String?>(json['version']),
      description: serializer.fromJson<String?>(json['description']),
      descriptionLong: serializer.fromJson<String?>(json['descriptionLong']),
      contactJson: serializer.fromJson<String>(json['contactJson']),
      motd: serializer.fromJson<String?>(json['motd']),
      iconUrl: serializer.fromJson<String?>(json['iconUrl']),
      time: serializer.fromJson<int?>(json['time']),
      tosUrl: serializer.fromJson<String?>(json['tosUrl']),
      nutsJson: serializer.fromJson<String>(json['nutsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'urlsJson': serializer.toJson<String>(urlsJson),
      'name': serializer.toJson<String?>(name),
      'pubkey': serializer.toJson<String?>(pubkey),
      'version': serializer.toJson<String?>(version),
      'description': serializer.toJson<String?>(description),
      'descriptionLong': serializer.toJson<String?>(descriptionLong),
      'contactJson': serializer.toJson<String>(contactJson),
      'motd': serializer.toJson<String?>(motd),
      'iconUrl': serializer.toJson<String?>(iconUrl),
      'time': serializer.toJson<int?>(time),
      'tosUrl': serializer.toJson<String?>(tosUrl),
      'nutsJson': serializer.toJson<String>(nutsJson),
    };
  }

  DbCashuMintInfo copyWith({
    String? id,
    String? urlsJson,
    Value<String?> name = const Value.absent(),
    Value<String?> pubkey = const Value.absent(),
    Value<String?> version = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> descriptionLong = const Value.absent(),
    String? contactJson,
    Value<String?> motd = const Value.absent(),
    Value<String?> iconUrl = const Value.absent(),
    Value<int?> time = const Value.absent(),
    Value<String?> tosUrl = const Value.absent(),
    String? nutsJson,
  }) => DbCashuMintInfo(
    id: id ?? this.id,
    urlsJson: urlsJson ?? this.urlsJson,
    name: name.present ? name.value : this.name,
    pubkey: pubkey.present ? pubkey.value : this.pubkey,
    version: version.present ? version.value : this.version,
    description: description.present ? description.value : this.description,
    descriptionLong: descriptionLong.present
        ? descriptionLong.value
        : this.descriptionLong,
    contactJson: contactJson ?? this.contactJson,
    motd: motd.present ? motd.value : this.motd,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
    time: time.present ? time.value : this.time,
    tosUrl: tosUrl.present ? tosUrl.value : this.tosUrl,
    nutsJson: nutsJson ?? this.nutsJson,
  );
  DbCashuMintInfo copyWithCompanion(CashuMintInfosCompanion data) {
    return DbCashuMintInfo(
      id: data.id.present ? data.id.value : this.id,
      urlsJson: data.urlsJson.present ? data.urlsJson.value : this.urlsJson,
      name: data.name.present ? data.name.value : this.name,
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
      version: data.version.present ? data.version.value : this.version,
      description: data.description.present
          ? data.description.value
          : this.description,
      descriptionLong: data.descriptionLong.present
          ? data.descriptionLong.value
          : this.descriptionLong,
      contactJson: data.contactJson.present
          ? data.contactJson.value
          : this.contactJson,
      motd: data.motd.present ? data.motd.value : this.motd,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      time: data.time.present ? data.time.value : this.time,
      tosUrl: data.tosUrl.present ? data.tosUrl.value : this.tosUrl,
      nutsJson: data.nutsJson.present ? data.nutsJson.value : this.nutsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCashuMintInfo(')
          ..write('id: $id, ')
          ..write('urlsJson: $urlsJson, ')
          ..write('name: $name, ')
          ..write('pubkey: $pubkey, ')
          ..write('version: $version, ')
          ..write('description: $description, ')
          ..write('descriptionLong: $descriptionLong, ')
          ..write('contactJson: $contactJson, ')
          ..write('motd: $motd, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('time: $time, ')
          ..write('tosUrl: $tosUrl, ')
          ..write('nutsJson: $nutsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    urlsJson,
    name,
    pubkey,
    version,
    description,
    descriptionLong,
    contactJson,
    motd,
    iconUrl,
    time,
    tosUrl,
    nutsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCashuMintInfo &&
          other.id == this.id &&
          other.urlsJson == this.urlsJson &&
          other.name == this.name &&
          other.pubkey == this.pubkey &&
          other.version == this.version &&
          other.description == this.description &&
          other.descriptionLong == this.descriptionLong &&
          other.contactJson == this.contactJson &&
          other.motd == this.motd &&
          other.iconUrl == this.iconUrl &&
          other.time == this.time &&
          other.tosUrl == this.tosUrl &&
          other.nutsJson == this.nutsJson);
}

class CashuMintInfosCompanion extends UpdateCompanion<DbCashuMintInfo> {
  final Value<String> id;
  final Value<String> urlsJson;
  final Value<String?> name;
  final Value<String?> pubkey;
  final Value<String?> version;
  final Value<String?> description;
  final Value<String?> descriptionLong;
  final Value<String> contactJson;
  final Value<String?> motd;
  final Value<String?> iconUrl;
  final Value<int?> time;
  final Value<String?> tosUrl;
  final Value<String> nutsJson;
  final Value<int> rowid;
  const CashuMintInfosCompanion({
    this.id = const Value.absent(),
    this.urlsJson = const Value.absent(),
    this.name = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.version = const Value.absent(),
    this.description = const Value.absent(),
    this.descriptionLong = const Value.absent(),
    this.contactJson = const Value.absent(),
    this.motd = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.time = const Value.absent(),
    this.tosUrl = const Value.absent(),
    this.nutsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashuMintInfosCompanion.insert({
    required String id,
    required String urlsJson,
    this.name = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.version = const Value.absent(),
    this.description = const Value.absent(),
    this.descriptionLong = const Value.absent(),
    required String contactJson,
    this.motd = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.time = const Value.absent(),
    this.tosUrl = const Value.absent(),
    required String nutsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       urlsJson = Value(urlsJson),
       contactJson = Value(contactJson),
       nutsJson = Value(nutsJson);
  static Insertable<DbCashuMintInfo> custom({
    Expression<String>? id,
    Expression<String>? urlsJson,
    Expression<String>? name,
    Expression<String>? pubkey,
    Expression<String>? version,
    Expression<String>? description,
    Expression<String>? descriptionLong,
    Expression<String>? contactJson,
    Expression<String>? motd,
    Expression<String>? iconUrl,
    Expression<int>? time,
    Expression<String>? tosUrl,
    Expression<String>? nutsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (urlsJson != null) 'urls_json': urlsJson,
      if (name != null) 'name': name,
      if (pubkey != null) 'pubkey': pubkey,
      if (version != null) 'version': version,
      if (description != null) 'description': description,
      if (descriptionLong != null) 'description_long': descriptionLong,
      if (contactJson != null) 'contact_json': contactJson,
      if (motd != null) 'motd': motd,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (time != null) 'time': time,
      if (tosUrl != null) 'tos_url': tosUrl,
      if (nutsJson != null) 'nuts_json': nutsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashuMintInfosCompanion copyWith({
    Value<String>? id,
    Value<String>? urlsJson,
    Value<String?>? name,
    Value<String?>? pubkey,
    Value<String?>? version,
    Value<String?>? description,
    Value<String?>? descriptionLong,
    Value<String>? contactJson,
    Value<String?>? motd,
    Value<String?>? iconUrl,
    Value<int?>? time,
    Value<String?>? tosUrl,
    Value<String>? nutsJson,
    Value<int>? rowid,
  }) {
    return CashuMintInfosCompanion(
      id: id ?? this.id,
      urlsJson: urlsJson ?? this.urlsJson,
      name: name ?? this.name,
      pubkey: pubkey ?? this.pubkey,
      version: version ?? this.version,
      description: description ?? this.description,
      descriptionLong: descriptionLong ?? this.descriptionLong,
      contactJson: contactJson ?? this.contactJson,
      motd: motd ?? this.motd,
      iconUrl: iconUrl ?? this.iconUrl,
      time: time ?? this.time,
      tosUrl: tosUrl ?? this.tosUrl,
      nutsJson: nutsJson ?? this.nutsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (urlsJson.present) {
      map['urls_json'] = Variable<String>(urlsJson.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (descriptionLong.present) {
      map['description_long'] = Variable<String>(descriptionLong.value);
    }
    if (contactJson.present) {
      map['contact_json'] = Variable<String>(contactJson.value);
    }
    if (motd.present) {
      map['motd'] = Variable<String>(motd.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (tosUrl.present) {
      map['tos_url'] = Variable<String>(tosUrl.value);
    }
    if (nutsJson.present) {
      map['nuts_json'] = Variable<String>(nutsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashuMintInfosCompanion(')
          ..write('id: $id, ')
          ..write('urlsJson: $urlsJson, ')
          ..write('name: $name, ')
          ..write('pubkey: $pubkey, ')
          ..write('version: $version, ')
          ..write('description: $description, ')
          ..write('descriptionLong: $descriptionLong, ')
          ..write('contactJson: $contactJson, ')
          ..write('motd: $motd, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('time: $time, ')
          ..write('tosUrl: $tosUrl, ')
          ..write('nutsJson: $nutsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashuSecretCountersTable extends CashuSecretCounters
    with TableInfo<$CashuSecretCountersTable, DbCashuSecretCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashuSecretCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mintUrlMeta = const VerificationMeta(
    'mintUrl',
  );
  @override
  late final GeneratedColumn<String> mintUrl = GeneratedColumn<String>(
    'mint_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keysetIdMeta = const VerificationMeta(
    'keysetId',
  );
  @override
  late final GeneratedColumn<String> keysetId = GeneratedColumn<String>(
    'keyset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterMeta = const VerificationMeta(
    'counter',
  );
  @override
  late final GeneratedColumn<int> counter = GeneratedColumn<int>(
    'counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, mintUrl, keysetId, counter];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cashu_secret_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbCashuSecretCounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mint_url')) {
      context.handle(
        _mintUrlMeta,
        mintUrl.isAcceptableOrUnknown(data['mint_url']!, _mintUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_mintUrlMeta);
    }
    if (data.containsKey('keyset_id')) {
      context.handle(
        _keysetIdMeta,
        keysetId.isAcceptableOrUnknown(data['keyset_id']!, _keysetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_keysetIdMeta);
    }
    if (data.containsKey('counter')) {
      context.handle(
        _counterMeta,
        counter.isAcceptableOrUnknown(data['counter']!, _counterMeta),
      );
    } else if (isInserting) {
      context.missing(_counterMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbCashuSecretCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCashuSecretCounter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mintUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mint_url'],
      )!,
      keysetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keyset_id'],
      )!,
      counter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counter'],
      )!,
    );
  }

  @override
  $CashuSecretCountersTable createAlias(String alias) {
    return $CashuSecretCountersTable(attachedDatabase, alias);
  }
}

class DbCashuSecretCounter extends DataClass
    implements Insertable<DbCashuSecretCounter> {
  final String id;
  final String mintUrl;
  final String keysetId;
  final int counter;
  const DbCashuSecretCounter({
    required this.id,
    required this.mintUrl,
    required this.keysetId,
    required this.counter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mint_url'] = Variable<String>(mintUrl);
    map['keyset_id'] = Variable<String>(keysetId);
    map['counter'] = Variable<int>(counter);
    return map;
  }

  CashuSecretCountersCompanion toCompanion(bool nullToAbsent) {
    return CashuSecretCountersCompanion(
      id: Value(id),
      mintUrl: Value(mintUrl),
      keysetId: Value(keysetId),
      counter: Value(counter),
    );
  }

  factory DbCashuSecretCounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCashuSecretCounter(
      id: serializer.fromJson<String>(json['id']),
      mintUrl: serializer.fromJson<String>(json['mintUrl']),
      keysetId: serializer.fromJson<String>(json['keysetId']),
      counter: serializer.fromJson<int>(json['counter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mintUrl': serializer.toJson<String>(mintUrl),
      'keysetId': serializer.toJson<String>(keysetId),
      'counter': serializer.toJson<int>(counter),
    };
  }

  DbCashuSecretCounter copyWith({
    String? id,
    String? mintUrl,
    String? keysetId,
    int? counter,
  }) => DbCashuSecretCounter(
    id: id ?? this.id,
    mintUrl: mintUrl ?? this.mintUrl,
    keysetId: keysetId ?? this.keysetId,
    counter: counter ?? this.counter,
  );
  DbCashuSecretCounter copyWithCompanion(CashuSecretCountersCompanion data) {
    return DbCashuSecretCounter(
      id: data.id.present ? data.id.value : this.id,
      mintUrl: data.mintUrl.present ? data.mintUrl.value : this.mintUrl,
      keysetId: data.keysetId.present ? data.keysetId.value : this.keysetId,
      counter: data.counter.present ? data.counter.value : this.counter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCashuSecretCounter(')
          ..write('id: $id, ')
          ..write('mintUrl: $mintUrl, ')
          ..write('keysetId: $keysetId, ')
          ..write('counter: $counter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mintUrl, keysetId, counter);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCashuSecretCounter &&
          other.id == this.id &&
          other.mintUrl == this.mintUrl &&
          other.keysetId == this.keysetId &&
          other.counter == this.counter);
}

class CashuSecretCountersCompanion
    extends UpdateCompanion<DbCashuSecretCounter> {
  final Value<String> id;
  final Value<String> mintUrl;
  final Value<String> keysetId;
  final Value<int> counter;
  final Value<int> rowid;
  const CashuSecretCountersCompanion({
    this.id = const Value.absent(),
    this.mintUrl = const Value.absent(),
    this.keysetId = const Value.absent(),
    this.counter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashuSecretCountersCompanion.insert({
    required String id,
    required String mintUrl,
    required String keysetId,
    required int counter,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mintUrl = Value(mintUrl),
       keysetId = Value(keysetId),
       counter = Value(counter);
  static Insertable<DbCashuSecretCounter> custom({
    Expression<String>? id,
    Expression<String>? mintUrl,
    Expression<String>? keysetId,
    Expression<int>? counter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mintUrl != null) 'mint_url': mintUrl,
      if (keysetId != null) 'keyset_id': keysetId,
      if (counter != null) 'counter': counter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashuSecretCountersCompanion copyWith({
    Value<String>? id,
    Value<String>? mintUrl,
    Value<String>? keysetId,
    Value<int>? counter,
    Value<int>? rowid,
  }) {
    return CashuSecretCountersCompanion(
      id: id ?? this.id,
      mintUrl: mintUrl ?? this.mintUrl,
      keysetId: keysetId ?? this.keysetId,
      counter: counter ?? this.counter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mintUrl.present) {
      map['mint_url'] = Variable<String>(mintUrl.value);
    }
    if (keysetId.present) {
      map['keyset_id'] = Variable<String>(keysetId.value);
    }
    if (counter.present) {
      map['counter'] = Variable<int>(counter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashuSecretCountersCompanion(')
          ..write('id: $id, ')
          ..write('mintUrl: $mintUrl, ')
          ..write('keysetId: $keysetId, ')
          ..write('counter: $counter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, DbKeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbKeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DbKeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbKeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class DbKeyValue extends DataClass implements Insertable<DbKeyValue> {
  final String key;
  final String? value;
  const DbKeyValue({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory DbKeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbKeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  DbKeyValue copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => DbKeyValue(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  DbKeyValue copyWithCompanion(KeyValuesCompanion data) {
    return DbKeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbKeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbKeyValue &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<DbKeyValue> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<DbKeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalletsTable extends Wallets with TableInfo<$WalletsTable, DbWallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supportedUnitsJsonMeta =
      const VerificationMeta('supportedUnitsJson');
  @override
  late final GeneratedColumn<String> supportedUnitsJson =
      GeneratedColumn<String>(
        'supported_units_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    supportedUnitsJson,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbWallet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('supported_units_json')) {
      context.handle(
        _supportedUnitsJsonMeta,
        supportedUnitsJson.isAcceptableOrUnknown(
          data['supported_units_json']!,
          _supportedUnitsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_supportedUnitsJsonMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbWallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbWallet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      supportedUnitsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supported_units_json'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }
}

class DbWallet extends DataClass implements Insertable<DbWallet> {
  final String id;
  final String name;
  final String type;
  final String supportedUnitsJson;
  final String metadataJson;
  const DbWallet({
    required this.id,
    required this.name,
    required this.type,
    required this.supportedUnitsJson,
    required this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['supported_units_json'] = Variable<String>(supportedUnitsJson);
    map['metadata_json'] = Variable<String>(metadataJson);
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      supportedUnitsJson: Value(supportedUnitsJson),
      metadataJson: Value(metadataJson),
    );
  }

  factory DbWallet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbWallet(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      supportedUnitsJson: serializer.fromJson<String>(
        json['supportedUnitsJson'],
      ),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'supportedUnitsJson': serializer.toJson<String>(supportedUnitsJson),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  DbWallet copyWith({
    String? id,
    String? name,
    String? type,
    String? supportedUnitsJson,
    String? metadataJson,
  }) => DbWallet(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    supportedUnitsJson: supportedUnitsJson ?? this.supportedUnitsJson,
    metadataJson: metadataJson ?? this.metadataJson,
  );
  DbWallet copyWithCompanion(WalletsCompanion data) {
    return DbWallet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      supportedUnitsJson: data.supportedUnitsJson.present
          ? data.supportedUnitsJson.value
          : this.supportedUnitsJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbWallet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('supportedUnitsJson: $supportedUnitsJson, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, supportedUnitsJson, metadataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbWallet &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.supportedUnitsJson == this.supportedUnitsJson &&
          other.metadataJson == this.metadataJson);
}

class WalletsCompanion extends UpdateCompanion<DbWallet> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> supportedUnitsJson;
  final Value<String> metadataJson;
  final Value<int> rowid;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.supportedUnitsJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletsCompanion.insert({
    required String id,
    required String name,
    required String type,
    required String supportedUnitsJson,
    required String metadataJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       supportedUnitsJson = Value(supportedUnitsJson),
       metadataJson = Value(metadataJson);
  static Insertable<DbWallet> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? supportedUnitsJson,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (supportedUnitsJson != null)
        'supported_units_json': supportedUnitsJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? supportedUnitsJson,
    Value<String>? metadataJson,
    Value<int>? rowid,
  }) {
    return WalletsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      supportedUnitsJson: supportedUnitsJson ?? this.supportedUnitsJson,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (supportedUnitsJson.present) {
      map['supported_units_json'] = Variable<String>(supportedUnitsJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('supportedUnitsJson: $supportedUnitsJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalletTransactionsTable extends WalletTransactions
    with TableInfo<$WalletTransactionsTable, DbWalletTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeAmountMeta = const VerificationMeta(
    'changeAmount',
  );
  @override
  late final GeneratedColumn<int> changeAmount = GeneratedColumn<int>(
    'change_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionMsgMeta = const VerificationMeta(
    'completionMsg',
  );
  @override
  late final GeneratedColumn<String> completionMsg = GeneratedColumn<String>(
    'completion_msg',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<int> transactionDate = GeneratedColumn<int>(
    'transaction_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initiatedDateMeta = const VerificationMeta(
    'initiatedDate',
  );
  @override
  late final GeneratedColumn<int> initiatedDate = GeneratedColumn<int>(
    'initiated_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    walletId,
    changeAmount,
    unit,
    type,
    state,
    completionMsg,
    transactionDate,
    initiatedDate,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallet_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbWalletTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('change_amount')) {
      context.handle(
        _changeAmountMeta,
        changeAmount.isAcceptableOrUnknown(
          data['change_amount']!,
          _changeAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changeAmountMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('completion_msg')) {
      context.handle(
        _completionMsgMeta,
        completionMsg.isAcceptableOrUnknown(
          data['completion_msg']!,
          _completionMsgMeta,
        ),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    }
    if (data.containsKey('initiated_date')) {
      context.handle(
        _initiatedDateMeta,
        initiatedDate.isAcceptableOrUnknown(
          data['initiated_date']!,
          _initiatedDateMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, walletId};
  @override
  DbWalletTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbWalletTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      )!,
      changeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_amount'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      completionMsg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_msg'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_date'],
      ),
      initiatedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initiated_date'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
    );
  }

  @override
  $WalletTransactionsTable createAlias(String alias) {
    return $WalletTransactionsTable(attachedDatabase, alias);
  }
}

class DbWalletTransaction extends DataClass
    implements Insertable<DbWalletTransaction> {
  final String id;
  final String walletId;
  final int changeAmount;
  final String unit;
  final String type;
  final String state;
  final String? completionMsg;
  final int? transactionDate;
  final int? initiatedDate;
  final String metadataJson;
  const DbWalletTransaction({
    required this.id,
    required this.walletId,
    required this.changeAmount,
    required this.unit,
    required this.type,
    required this.state,
    this.completionMsg,
    this.transactionDate,
    this.initiatedDate,
    required this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['wallet_id'] = Variable<String>(walletId);
    map['change_amount'] = Variable<int>(changeAmount);
    map['unit'] = Variable<String>(unit);
    map['type'] = Variable<String>(type);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || completionMsg != null) {
      map['completion_msg'] = Variable<String>(completionMsg);
    }
    if (!nullToAbsent || transactionDate != null) {
      map['transaction_date'] = Variable<int>(transactionDate);
    }
    if (!nullToAbsent || initiatedDate != null) {
      map['initiated_date'] = Variable<int>(initiatedDate);
    }
    map['metadata_json'] = Variable<String>(metadataJson);
    return map;
  }

  WalletTransactionsCompanion toCompanion(bool nullToAbsent) {
    return WalletTransactionsCompanion(
      id: Value(id),
      walletId: Value(walletId),
      changeAmount: Value(changeAmount),
      unit: Value(unit),
      type: Value(type),
      state: Value(state),
      completionMsg: completionMsg == null && nullToAbsent
          ? const Value.absent()
          : Value(completionMsg),
      transactionDate: transactionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionDate),
      initiatedDate: initiatedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(initiatedDate),
      metadataJson: Value(metadataJson),
    );
  }

  factory DbWalletTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbWalletTransaction(
      id: serializer.fromJson<String>(json['id']),
      walletId: serializer.fromJson<String>(json['walletId']),
      changeAmount: serializer.fromJson<int>(json['changeAmount']),
      unit: serializer.fromJson<String>(json['unit']),
      type: serializer.fromJson<String>(json['type']),
      state: serializer.fromJson<String>(json['state']),
      completionMsg: serializer.fromJson<String?>(json['completionMsg']),
      transactionDate: serializer.fromJson<int?>(json['transactionDate']),
      initiatedDate: serializer.fromJson<int?>(json['initiatedDate']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'walletId': serializer.toJson<String>(walletId),
      'changeAmount': serializer.toJson<int>(changeAmount),
      'unit': serializer.toJson<String>(unit),
      'type': serializer.toJson<String>(type),
      'state': serializer.toJson<String>(state),
      'completionMsg': serializer.toJson<String?>(completionMsg),
      'transactionDate': serializer.toJson<int?>(transactionDate),
      'initiatedDate': serializer.toJson<int?>(initiatedDate),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  DbWalletTransaction copyWith({
    String? id,
    String? walletId,
    int? changeAmount,
    String? unit,
    String? type,
    String? state,
    Value<String?> completionMsg = const Value.absent(),
    Value<int?> transactionDate = const Value.absent(),
    Value<int?> initiatedDate = const Value.absent(),
    String? metadataJson,
  }) => DbWalletTransaction(
    id: id ?? this.id,
    walletId: walletId ?? this.walletId,
    changeAmount: changeAmount ?? this.changeAmount,
    unit: unit ?? this.unit,
    type: type ?? this.type,
    state: state ?? this.state,
    completionMsg: completionMsg.present
        ? completionMsg.value
        : this.completionMsg,
    transactionDate: transactionDate.present
        ? transactionDate.value
        : this.transactionDate,
    initiatedDate: initiatedDate.present
        ? initiatedDate.value
        : this.initiatedDate,
    metadataJson: metadataJson ?? this.metadataJson,
  );
  DbWalletTransaction copyWithCompanion(WalletTransactionsCompanion data) {
    return DbWalletTransaction(
      id: data.id.present ? data.id.value : this.id,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      changeAmount: data.changeAmount.present
          ? data.changeAmount.value
          : this.changeAmount,
      unit: data.unit.present ? data.unit.value : this.unit,
      type: data.type.present ? data.type.value : this.type,
      state: data.state.present ? data.state.value : this.state,
      completionMsg: data.completionMsg.present
          ? data.completionMsg.value
          : this.completionMsg,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      initiatedDate: data.initiatedDate.present
          ? data.initiatedDate.value
          : this.initiatedDate,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbWalletTransaction(')
          ..write('id: $id, ')
          ..write('walletId: $walletId, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('unit: $unit, ')
          ..write('type: $type, ')
          ..write('state: $state, ')
          ..write('completionMsg: $completionMsg, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('initiatedDate: $initiatedDate, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    walletId,
    changeAmount,
    unit,
    type,
    state,
    completionMsg,
    transactionDate,
    initiatedDate,
    metadataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbWalletTransaction &&
          other.id == this.id &&
          other.walletId == this.walletId &&
          other.changeAmount == this.changeAmount &&
          other.unit == this.unit &&
          other.type == this.type &&
          other.state == this.state &&
          other.completionMsg == this.completionMsg &&
          other.transactionDate == this.transactionDate &&
          other.initiatedDate == this.initiatedDate &&
          other.metadataJson == this.metadataJson);
}

class WalletTransactionsCompanion extends UpdateCompanion<DbWalletTransaction> {
  final Value<String> id;
  final Value<String> walletId;
  final Value<int> changeAmount;
  final Value<String> unit;
  final Value<String> type;
  final Value<String> state;
  final Value<String?> completionMsg;
  final Value<int?> transactionDate;
  final Value<int?> initiatedDate;
  final Value<String> metadataJson;
  final Value<int> rowid;
  const WalletTransactionsCompanion({
    this.id = const Value.absent(),
    this.walletId = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.unit = const Value.absent(),
    this.type = const Value.absent(),
    this.state = const Value.absent(),
    this.completionMsg = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.initiatedDate = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletTransactionsCompanion.insert({
    required String id,
    required String walletId,
    required int changeAmount,
    required String unit,
    required String type,
    required String state,
    this.completionMsg = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.initiatedDate = const Value.absent(),
    required String metadataJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       walletId = Value(walletId),
       changeAmount = Value(changeAmount),
       unit = Value(unit),
       type = Value(type),
       state = Value(state),
       metadataJson = Value(metadataJson);
  static Insertable<DbWalletTransaction> custom({
    Expression<String>? id,
    Expression<String>? walletId,
    Expression<int>? changeAmount,
    Expression<String>? unit,
    Expression<String>? type,
    Expression<String>? state,
    Expression<String>? completionMsg,
    Expression<int>? transactionDate,
    Expression<int>? initiatedDate,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (walletId != null) 'wallet_id': walletId,
      if (changeAmount != null) 'change_amount': changeAmount,
      if (unit != null) 'unit': unit,
      if (type != null) 'type': type,
      if (state != null) 'state': state,
      if (completionMsg != null) 'completion_msg': completionMsg,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (initiatedDate != null) 'initiated_date': initiatedDate,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? walletId,
    Value<int>? changeAmount,
    Value<String>? unit,
    Value<String>? type,
    Value<String>? state,
    Value<String?>? completionMsg,
    Value<int?>? transactionDate,
    Value<int?>? initiatedDate,
    Value<String>? metadataJson,
    Value<int>? rowid,
  }) {
    return WalletTransactionsCompanion(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      changeAmount: changeAmount ?? this.changeAmount,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      state: state ?? this.state,
      completionMsg: completionMsg ?? this.completionMsg,
      transactionDate: transactionDate ?? this.transactionDate,
      initiatedDate: initiatedDate ?? this.initiatedDate,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (changeAmount.present) {
      map['change_amount'] = Variable<int>(changeAmount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (completionMsg.present) {
      map['completion_msg'] = Variable<String>(completionMsg.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<int>(transactionDate.value);
    }
    if (initiatedDate.present) {
      map['initiated_date'] = Variable<int>(initiatedDate.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('walletId: $walletId, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('unit: $unit, ')
          ..write('type: $type, ')
          ..write('state: $state, ')
          ..write('completionMsg: $completionMsg, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('initiatedDate: $initiatedDate, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NdkCacheDatabase extends GeneratedDatabase {
  _$NdkCacheDatabase(QueryExecutor e) : super(e);
  $NdkCacheDatabaseManager get managers => $NdkCacheDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $UserRelayListsTable userRelayLists = $UserRelayListsTable(this);
  late final $RelaySetsTable relaySets = $RelaySetsTable(this);
  late final $Nip05sTable nip05s = $Nip05sTable(this);
  late final $FilterFetchedRangeRecordsTable filterFetchedRangeRecords =
      $FilterFetchedRangeRecordsTable(this);
  late final $EventSourcesTableTable eventSourcesTable =
      $EventSourcesTableTable(this);
  late final $EventDeliveryRecordsTableTable eventDeliveryRecordsTable =
      $EventDeliveryRecordsTableTable(this);
  late final $RelayDeliveryTargetsTableTable relayDeliveryTargetsTable =
      $RelayDeliveryTargetsTableTable(this);
  late final $CashuProofsTable cashuProofs = $CashuProofsTable(this);
  late final $CashuKeysetsTable cashuKeysets = $CashuKeysetsTable(this);
  late final $CashuMintInfosTable cashuMintInfos = $CashuMintInfosTable(this);
  late final $CashuSecretCountersTable cashuSecretCounters =
      $CashuSecretCountersTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $WalletTransactionsTable walletTransactions =
      $WalletTransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    events,
    userRelayLists,
    relaySets,
    nip05s,
    filterFetchedRangeRecords,
    eventSourcesTable,
    eventDeliveryRecordsTable,
    relayDeliveryTargetsTable,
    cashuProofs,
    cashuKeysets,
    cashuMintInfos,
    cashuSecretCounters,
    keyValues,
    wallets,
    walletTransactions,
  ];
}

typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      required String id,
      required String pubKey,
      required int kind,
      required int createdAt,
      required String content,
      Value<String?> sig,
      Value<bool?> validSig,
      required String tagsJson,
      required String sourcesJson,
      Value<int> rowid,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<String> id,
      Value<String> pubKey,
      Value<int> kind,
      Value<int> createdAt,
      Value<String> content,
      Value<String?> sig,
      Value<bool?> validSig,
      Value<String> tagsJson,
      Value<String> sourcesJson,
      Value<int> rowid,
    });

class $$EventsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sig => $composableBuilder(
    column: $table.sig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get validSig => $composableBuilder(
    column: $table.validSig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sig => $composableBuilder(
    column: $table.sig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get validSig => $composableBuilder(
    column: $table.validSig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pubKey =>
      $composableBuilder(column: $table.pubKey, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get sig =>
      $composableBuilder(column: $table.sig, builder: (column) => column);

  GeneratedColumn<bool> get validSig =>
      $composableBuilder(column: $table.validSig, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => column,
  );
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $EventsTable,
          DbEvent,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (DbEvent, BaseReferences<_$NdkCacheDatabase, $EventsTable, DbEvent>),
          DbEvent,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$NdkCacheDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pubKey = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> sig = const Value.absent(),
                Value<bool?> validSig = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> sourcesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                pubKey: pubKey,
                kind: kind,
                createdAt: createdAt,
                content: content,
                sig: sig,
                validSig: validSig,
                tagsJson: tagsJson,
                sourcesJson: sourcesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pubKey,
                required int kind,
                required int createdAt,
                required String content,
                Value<String?> sig = const Value.absent(),
                Value<bool?> validSig = const Value.absent(),
                required String tagsJson,
                required String sourcesJson,
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                pubKey: pubKey,
                kind: kind,
                createdAt: createdAt,
                content: content,
                sig: sig,
                validSig: validSig,
                tagsJson: tagsJson,
                sourcesJson: sourcesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $EventsTable,
      DbEvent,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (DbEvent, BaseReferences<_$NdkCacheDatabase, $EventsTable, DbEvent>),
      DbEvent,
      PrefetchHooks Function()
    >;
typedef $$UserRelayListsTableCreateCompanionBuilder =
    UserRelayListsCompanion Function({
      required String pubKey,
      required int createdAt,
      required int refreshedTimestamp,
      required String relaysJson,
      Value<int> rowid,
    });
typedef $$UserRelayListsTableUpdateCompanionBuilder =
    UserRelayListsCompanion Function({
      Value<String> pubKey,
      Value<int> createdAt,
      Value<int> refreshedTimestamp,
      Value<String> relaysJson,
      Value<int> rowid,
    });

class $$UserRelayListsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $UserRelayListsTable> {
  $$UserRelayListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refreshedTimestamp => $composableBuilder(
    column: $table.refreshedTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relaysJson => $composableBuilder(
    column: $table.relaysJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserRelayListsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $UserRelayListsTable> {
  $$UserRelayListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedTimestamp => $composableBuilder(
    column: $table.refreshedTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relaysJson => $composableBuilder(
    column: $table.relaysJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserRelayListsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $UserRelayListsTable> {
  $$UserRelayListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubKey =>
      $composableBuilder(column: $table.pubKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get refreshedTimestamp => $composableBuilder(
    column: $table.refreshedTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relaysJson => $composableBuilder(
    column: $table.relaysJson,
    builder: (column) => column,
  );
}

class $$UserRelayListsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $UserRelayListsTable,
          DbUserRelayList,
          $$UserRelayListsTableFilterComposer,
          $$UserRelayListsTableOrderingComposer,
          $$UserRelayListsTableAnnotationComposer,
          $$UserRelayListsTableCreateCompanionBuilder,
          $$UserRelayListsTableUpdateCompanionBuilder,
          (
            DbUserRelayList,
            BaseReferences<
              _$NdkCacheDatabase,
              $UserRelayListsTable,
              DbUserRelayList
            >,
          ),
          DbUserRelayList,
          PrefetchHooks Function()
        > {
  $$UserRelayListsTableTableManager(
    _$NdkCacheDatabase db,
    $UserRelayListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRelayListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRelayListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserRelayListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pubKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> refreshedTimestamp = const Value.absent(),
                Value<String> relaysJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserRelayListsCompanion(
                pubKey: pubKey,
                createdAt: createdAt,
                refreshedTimestamp: refreshedTimestamp,
                relaysJson: relaysJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pubKey,
                required int createdAt,
                required int refreshedTimestamp,
                required String relaysJson,
                Value<int> rowid = const Value.absent(),
              }) => UserRelayListsCompanion.insert(
                pubKey: pubKey,
                createdAt: createdAt,
                refreshedTimestamp: refreshedTimestamp,
                relaysJson: relaysJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserRelayListsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $UserRelayListsTable,
      DbUserRelayList,
      $$UserRelayListsTableFilterComposer,
      $$UserRelayListsTableOrderingComposer,
      $$UserRelayListsTableAnnotationComposer,
      $$UserRelayListsTableCreateCompanionBuilder,
      $$UserRelayListsTableUpdateCompanionBuilder,
      (
        DbUserRelayList,
        BaseReferences<
          _$NdkCacheDatabase,
          $UserRelayListsTable,
          DbUserRelayList
        >,
      ),
      DbUserRelayList,
      PrefetchHooks Function()
    >;
typedef $$RelaySetsTableCreateCompanionBuilder =
    RelaySetsCompanion Function({
      required String id,
      required String name,
      required String pubKey,
      required int relayMinCountPerPubkey,
      required int direction,
      required String relaysMapJson,
      required bool fallbackToBootstrapRelays,
      required String notCoveredPubkeysJson,
      Value<int> rowid,
    });
typedef $$RelaySetsTableUpdateCompanionBuilder =
    RelaySetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> pubKey,
      Value<int> relayMinCountPerPubkey,
      Value<int> direction,
      Value<String> relaysMapJson,
      Value<bool> fallbackToBootstrapRelays,
      Value<String> notCoveredPubkeysJson,
      Value<int> rowid,
    });

class $$RelaySetsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $RelaySetsTable> {
  $$RelaySetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relayMinCountPerPubkey => $composableBuilder(
    column: $table.relayMinCountPerPubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relaysMapJson => $composableBuilder(
    column: $table.relaysMapJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fallbackToBootstrapRelays => $composableBuilder(
    column: $table.fallbackToBootstrapRelays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notCoveredPubkeysJson => $composableBuilder(
    column: $table.notCoveredPubkeysJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RelaySetsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $RelaySetsTable> {
  $$RelaySetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relayMinCountPerPubkey => $composableBuilder(
    column: $table.relayMinCountPerPubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relaysMapJson => $composableBuilder(
    column: $table.relaysMapJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fallbackToBootstrapRelays => $composableBuilder(
    column: $table.fallbackToBootstrapRelays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notCoveredPubkeysJson => $composableBuilder(
    column: $table.notCoveredPubkeysJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RelaySetsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $RelaySetsTable> {
  $$RelaySetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get pubKey =>
      $composableBuilder(column: $table.pubKey, builder: (column) => column);

  GeneratedColumn<int> get relayMinCountPerPubkey => $composableBuilder(
    column: $table.relayMinCountPerPubkey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get relaysMapJson => $composableBuilder(
    column: $table.relaysMapJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fallbackToBootstrapRelays => $composableBuilder(
    column: $table.fallbackToBootstrapRelays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notCoveredPubkeysJson => $composableBuilder(
    column: $table.notCoveredPubkeysJson,
    builder: (column) => column,
  );
}

class $$RelaySetsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $RelaySetsTable,
          DbRelaySet,
          $$RelaySetsTableFilterComposer,
          $$RelaySetsTableOrderingComposer,
          $$RelaySetsTableAnnotationComposer,
          $$RelaySetsTableCreateCompanionBuilder,
          $$RelaySetsTableUpdateCompanionBuilder,
          (
            DbRelaySet,
            BaseReferences<_$NdkCacheDatabase, $RelaySetsTable, DbRelaySet>,
          ),
          DbRelaySet,
          PrefetchHooks Function()
        > {
  $$RelaySetsTableTableManager(_$NdkCacheDatabase db, $RelaySetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelaySetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelaySetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelaySetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> pubKey = const Value.absent(),
                Value<int> relayMinCountPerPubkey = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<String> relaysMapJson = const Value.absent(),
                Value<bool> fallbackToBootstrapRelays = const Value.absent(),
                Value<String> notCoveredPubkeysJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelaySetsCompanion(
                id: id,
                name: name,
                pubKey: pubKey,
                relayMinCountPerPubkey: relayMinCountPerPubkey,
                direction: direction,
                relaysMapJson: relaysMapJson,
                fallbackToBootstrapRelays: fallbackToBootstrapRelays,
                notCoveredPubkeysJson: notCoveredPubkeysJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String pubKey,
                required int relayMinCountPerPubkey,
                required int direction,
                required String relaysMapJson,
                required bool fallbackToBootstrapRelays,
                required String notCoveredPubkeysJson,
                Value<int> rowid = const Value.absent(),
              }) => RelaySetsCompanion.insert(
                id: id,
                name: name,
                pubKey: pubKey,
                relayMinCountPerPubkey: relayMinCountPerPubkey,
                direction: direction,
                relaysMapJson: relaysMapJson,
                fallbackToBootstrapRelays: fallbackToBootstrapRelays,
                notCoveredPubkeysJson: notCoveredPubkeysJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RelaySetsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $RelaySetsTable,
      DbRelaySet,
      $$RelaySetsTableFilterComposer,
      $$RelaySetsTableOrderingComposer,
      $$RelaySetsTableAnnotationComposer,
      $$RelaySetsTableCreateCompanionBuilder,
      $$RelaySetsTableUpdateCompanionBuilder,
      (
        DbRelaySet,
        BaseReferences<_$NdkCacheDatabase, $RelaySetsTable, DbRelaySet>,
      ),
      DbRelaySet,
      PrefetchHooks Function()
    >;
typedef $$Nip05sTableCreateCompanionBuilder =
    Nip05sCompanion Function({
      required String pubKey,
      required String nip05,
      required bool valid,
      Value<int?> networkFetchTime,
      required String relaysJson,
      Value<int> rowid,
    });
typedef $$Nip05sTableUpdateCompanionBuilder =
    Nip05sCompanion Function({
      Value<String> pubKey,
      Value<String> nip05,
      Value<bool> valid,
      Value<int?> networkFetchTime,
      Value<String> relaysJson,
      Value<int> rowid,
    });

class $$Nip05sTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $Nip05sTable> {
  $$Nip05sTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nip05 => $composableBuilder(
    column: $table.nip05,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get valid => $composableBuilder(
    column: $table.valid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get networkFetchTime => $composableBuilder(
    column: $table.networkFetchTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relaysJson => $composableBuilder(
    column: $table.relaysJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$Nip05sTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $Nip05sTable> {
  $$Nip05sTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nip05 => $composableBuilder(
    column: $table.nip05,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get valid => $composableBuilder(
    column: $table.valid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get networkFetchTime => $composableBuilder(
    column: $table.networkFetchTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relaysJson => $composableBuilder(
    column: $table.relaysJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$Nip05sTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $Nip05sTable> {
  $$Nip05sTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubKey =>
      $composableBuilder(column: $table.pubKey, builder: (column) => column);

  GeneratedColumn<String> get nip05 =>
      $composableBuilder(column: $table.nip05, builder: (column) => column);

  GeneratedColumn<bool> get valid =>
      $composableBuilder(column: $table.valid, builder: (column) => column);

  GeneratedColumn<int> get networkFetchTime => $composableBuilder(
    column: $table.networkFetchTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relaysJson => $composableBuilder(
    column: $table.relaysJson,
    builder: (column) => column,
  );
}

class $$Nip05sTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $Nip05sTable,
          DbNip05,
          $$Nip05sTableFilterComposer,
          $$Nip05sTableOrderingComposer,
          $$Nip05sTableAnnotationComposer,
          $$Nip05sTableCreateCompanionBuilder,
          $$Nip05sTableUpdateCompanionBuilder,
          (DbNip05, BaseReferences<_$NdkCacheDatabase, $Nip05sTable, DbNip05>),
          DbNip05,
          PrefetchHooks Function()
        > {
  $$Nip05sTableTableManager(_$NdkCacheDatabase db, $Nip05sTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$Nip05sTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$Nip05sTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$Nip05sTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pubKey = const Value.absent(),
                Value<String> nip05 = const Value.absent(),
                Value<bool> valid = const Value.absent(),
                Value<int?> networkFetchTime = const Value.absent(),
                Value<String> relaysJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => Nip05sCompanion(
                pubKey: pubKey,
                nip05: nip05,
                valid: valid,
                networkFetchTime: networkFetchTime,
                relaysJson: relaysJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pubKey,
                required String nip05,
                required bool valid,
                Value<int?> networkFetchTime = const Value.absent(),
                required String relaysJson,
                Value<int> rowid = const Value.absent(),
              }) => Nip05sCompanion.insert(
                pubKey: pubKey,
                nip05: nip05,
                valid: valid,
                networkFetchTime: networkFetchTime,
                relaysJson: relaysJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$Nip05sTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $Nip05sTable,
      DbNip05,
      $$Nip05sTableFilterComposer,
      $$Nip05sTableOrderingComposer,
      $$Nip05sTableAnnotationComposer,
      $$Nip05sTableCreateCompanionBuilder,
      $$Nip05sTableUpdateCompanionBuilder,
      (DbNip05, BaseReferences<_$NdkCacheDatabase, $Nip05sTable, DbNip05>),
      DbNip05,
      PrefetchHooks Function()
    >;
typedef $$FilterFetchedRangeRecordsTableCreateCompanionBuilder =
    FilterFetchedRangeRecordsCompanion Function({
      required String key,
      required String filterHash,
      required String relayUrl,
      required int rangeStart,
      required int rangeEnd,
      Value<int> rowid,
    });
typedef $$FilterFetchedRangeRecordsTableUpdateCompanionBuilder =
    FilterFetchedRangeRecordsCompanion Function({
      Value<String> key,
      Value<String> filterHash,
      Value<String> relayUrl,
      Value<int> rangeStart,
      Value<int> rangeEnd,
      Value<int> rowid,
    });

class $$FilterFetchedRangeRecordsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $FilterFetchedRangeRecordsTable> {
  $$FilterFetchedRangeRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterHash => $composableBuilder(
    column: $table.filterHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayUrl => $composableBuilder(
    column: $table.relayUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rangeEnd => $composableBuilder(
    column: $table.rangeEnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilterFetchedRangeRecordsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $FilterFetchedRangeRecordsTable> {
  $$FilterFetchedRangeRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterHash => $composableBuilder(
    column: $table.filterHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayUrl => $composableBuilder(
    column: $table.relayUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rangeEnd => $composableBuilder(
    column: $table.rangeEnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilterFetchedRangeRecordsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $FilterFetchedRangeRecordsTable> {
  $$FilterFetchedRangeRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get filterHash => $composableBuilder(
    column: $table.filterHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relayUrl =>
      $composableBuilder(column: $table.relayUrl, builder: (column) => column);

  GeneratedColumn<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rangeEnd =>
      $composableBuilder(column: $table.rangeEnd, builder: (column) => column);
}

class $$FilterFetchedRangeRecordsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $FilterFetchedRangeRecordsTable,
          DbFilterFetchedRangeRecord,
          $$FilterFetchedRangeRecordsTableFilterComposer,
          $$FilterFetchedRangeRecordsTableOrderingComposer,
          $$FilterFetchedRangeRecordsTableAnnotationComposer,
          $$FilterFetchedRangeRecordsTableCreateCompanionBuilder,
          $$FilterFetchedRangeRecordsTableUpdateCompanionBuilder,
          (
            DbFilterFetchedRangeRecord,
            BaseReferences<
              _$NdkCacheDatabase,
              $FilterFetchedRangeRecordsTable,
              DbFilterFetchedRangeRecord
            >,
          ),
          DbFilterFetchedRangeRecord,
          PrefetchHooks Function()
        > {
  $$FilterFetchedRangeRecordsTableTableManager(
    _$NdkCacheDatabase db,
    $FilterFetchedRangeRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilterFetchedRangeRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FilterFetchedRangeRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FilterFetchedRangeRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> filterHash = const Value.absent(),
                Value<String> relayUrl = const Value.absent(),
                Value<int> rangeStart = const Value.absent(),
                Value<int> rangeEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilterFetchedRangeRecordsCompanion(
                key: key,
                filterHash: filterHash,
                relayUrl: relayUrl,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String filterHash,
                required String relayUrl,
                required int rangeStart,
                required int rangeEnd,
                Value<int> rowid = const Value.absent(),
              }) => FilterFetchedRangeRecordsCompanion.insert(
                key: key,
                filterHash: filterHash,
                relayUrl: relayUrl,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilterFetchedRangeRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $FilterFetchedRangeRecordsTable,
      DbFilterFetchedRangeRecord,
      $$FilterFetchedRangeRecordsTableFilterComposer,
      $$FilterFetchedRangeRecordsTableOrderingComposer,
      $$FilterFetchedRangeRecordsTableAnnotationComposer,
      $$FilterFetchedRangeRecordsTableCreateCompanionBuilder,
      $$FilterFetchedRangeRecordsTableUpdateCompanionBuilder,
      (
        DbFilterFetchedRangeRecord,
        BaseReferences<
          _$NdkCacheDatabase,
          $FilterFetchedRangeRecordsTable,
          DbFilterFetchedRangeRecord
        >,
      ),
      DbFilterFetchedRangeRecord,
      PrefetchHooks Function()
    >;
typedef $$EventSourcesTableTableCreateCompanionBuilder =
    EventSourcesTableCompanion Function({
      required String eventId,
      required String relayUrl,
      Value<int> rowid,
    });
typedef $$EventSourcesTableTableUpdateCompanionBuilder =
    EventSourcesTableCompanion Function({
      Value<String> eventId,
      Value<String> relayUrl,
      Value<int> rowid,
    });

class $$EventSourcesTableTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $EventSourcesTableTable> {
  $$EventSourcesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayUrl => $composableBuilder(
    column: $table.relayUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventSourcesTableTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $EventSourcesTableTable> {
  $$EventSourcesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayUrl => $composableBuilder(
    column: $table.relayUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventSourcesTableTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $EventSourcesTableTable> {
  $$EventSourcesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get relayUrl =>
      $composableBuilder(column: $table.relayUrl, builder: (column) => column);
}

class $$EventSourcesTableTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $EventSourcesTableTable,
          DbEventSource,
          $$EventSourcesTableTableFilterComposer,
          $$EventSourcesTableTableOrderingComposer,
          $$EventSourcesTableTableAnnotationComposer,
          $$EventSourcesTableTableCreateCompanionBuilder,
          $$EventSourcesTableTableUpdateCompanionBuilder,
          (
            DbEventSource,
            BaseReferences<
              _$NdkCacheDatabase,
              $EventSourcesTableTable,
              DbEventSource
            >,
          ),
          DbEventSource,
          PrefetchHooks Function()
        > {
  $$EventSourcesTableTableTableManager(
    _$NdkCacheDatabase db,
    $EventSourcesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventSourcesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventSourcesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventSourcesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> relayUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventSourcesTableCompanion(
                eventId: eventId,
                relayUrl: relayUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String relayUrl,
                Value<int> rowid = const Value.absent(),
              }) => EventSourcesTableCompanion.insert(
                eventId: eventId,
                relayUrl: relayUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventSourcesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $EventSourcesTableTable,
      DbEventSource,
      $$EventSourcesTableTableFilterComposer,
      $$EventSourcesTableTableOrderingComposer,
      $$EventSourcesTableTableAnnotationComposer,
      $$EventSourcesTableTableCreateCompanionBuilder,
      $$EventSourcesTableTableUpdateCompanionBuilder,
      (
        DbEventSource,
        BaseReferences<
          _$NdkCacheDatabase,
          $EventSourcesTableTable,
          DbEventSource
        >,
      ),
      DbEventSource,
      PrefetchHooks Function()
    >;
typedef $$EventDeliveryRecordsTableTableCreateCompanionBuilder =
    EventDeliveryRecordsTableCompanion Function({
      required String eventId,
      required String status,
      required int createdAt,
      required int updatedAt,
      Value<int?> signedAt,
      Value<int?> completedAt,
      Value<bool> requiresNetworkSigner,
      Value<int> rowid,
    });
typedef $$EventDeliveryRecordsTableTableUpdateCompanionBuilder =
    EventDeliveryRecordsTableCompanion Function({
      Value<String> eventId,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> signedAt,
      Value<int?> completedAt,
      Value<bool> requiresNetworkSigner,
      Value<int> rowid,
    });

class $$EventDeliveryRecordsTableTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $EventDeliveryRecordsTableTable> {
  $$EventDeliveryRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get signedAt => $composableBuilder(
    column: $table.signedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresNetworkSigner => $composableBuilder(
    column: $table.requiresNetworkSigner,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventDeliveryRecordsTableTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $EventDeliveryRecordsTableTable> {
  $$EventDeliveryRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get signedAt => $composableBuilder(
    column: $table.signedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresNetworkSigner => $composableBuilder(
    column: $table.requiresNetworkSigner,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventDeliveryRecordsTableTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $EventDeliveryRecordsTableTable> {
  $$EventDeliveryRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get signedAt =>
      $composableBuilder(column: $table.signedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get requiresNetworkSigner => $composableBuilder(
    column: $table.requiresNetworkSigner,
    builder: (column) => column,
  );
}

class $$EventDeliveryRecordsTableTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $EventDeliveryRecordsTableTable,
          DbEventDeliveryRecord,
          $$EventDeliveryRecordsTableTableFilterComposer,
          $$EventDeliveryRecordsTableTableOrderingComposer,
          $$EventDeliveryRecordsTableTableAnnotationComposer,
          $$EventDeliveryRecordsTableTableCreateCompanionBuilder,
          $$EventDeliveryRecordsTableTableUpdateCompanionBuilder,
          (
            DbEventDeliveryRecord,
            BaseReferences<
              _$NdkCacheDatabase,
              $EventDeliveryRecordsTableTable,
              DbEventDeliveryRecord
            >,
          ),
          DbEventDeliveryRecord,
          PrefetchHooks Function()
        > {
  $$EventDeliveryRecordsTableTableTableManager(
    _$NdkCacheDatabase db,
    $EventDeliveryRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventDeliveryRecordsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EventDeliveryRecordsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EventDeliveryRecordsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> signedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<bool> requiresNetworkSigner = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventDeliveryRecordsTableCompanion(
                eventId: eventId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                signedAt: signedAt,
                completedAt: completedAt,
                requiresNetworkSigner: requiresNetworkSigner,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String status,
                required int createdAt,
                required int updatedAt,
                Value<int?> signedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<bool> requiresNetworkSigner = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventDeliveryRecordsTableCompanion.insert(
                eventId: eventId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                signedAt: signedAt,
                completedAt: completedAt,
                requiresNetworkSigner: requiresNetworkSigner,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventDeliveryRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $EventDeliveryRecordsTableTable,
      DbEventDeliveryRecord,
      $$EventDeliveryRecordsTableTableFilterComposer,
      $$EventDeliveryRecordsTableTableOrderingComposer,
      $$EventDeliveryRecordsTableTableAnnotationComposer,
      $$EventDeliveryRecordsTableTableCreateCompanionBuilder,
      $$EventDeliveryRecordsTableTableUpdateCompanionBuilder,
      (
        DbEventDeliveryRecord,
        BaseReferences<
          _$NdkCacheDatabase,
          $EventDeliveryRecordsTableTable,
          DbEventDeliveryRecord
        >,
      ),
      DbEventDeliveryRecord,
      PrefetchHooks Function()
    >;
typedef $$RelayDeliveryTargetsTableTableCreateCompanionBuilder =
    RelayDeliveryTargetsTableCompanion Function({
      required String eventId,
      required String relayUrl,
      required String reason,
      required String state,
      Value<int> attemptCount,
      Value<int?> lastAttemptAt,
      Value<int?> nextRetryAt,
      Value<String?> lastError,
      Value<String?> lastOkMessage,
      Value<int> rowid,
    });
typedef $$RelayDeliveryTargetsTableTableUpdateCompanionBuilder =
    RelayDeliveryTargetsTableCompanion Function({
      Value<String> eventId,
      Value<String> relayUrl,
      Value<String> reason,
      Value<String> state,
      Value<int> attemptCount,
      Value<int?> lastAttemptAt,
      Value<int?> nextRetryAt,
      Value<String?> lastError,
      Value<String?> lastOkMessage,
      Value<int> rowid,
    });

class $$RelayDeliveryTargetsTableTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $RelayDeliveryTargetsTableTable> {
  $$RelayDeliveryTargetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayUrl => $composableBuilder(
    column: $table.relayUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastOkMessage => $composableBuilder(
    column: $table.lastOkMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RelayDeliveryTargetsTableTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $RelayDeliveryTargetsTableTable> {
  $$RelayDeliveryTargetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayUrl => $composableBuilder(
    column: $table.relayUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastOkMessage => $composableBuilder(
    column: $table.lastOkMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RelayDeliveryTargetsTableTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $RelayDeliveryTargetsTableTable> {
  $$RelayDeliveryTargetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get relayUrl =>
      $composableBuilder(column: $table.relayUrl, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get lastOkMessage => $composableBuilder(
    column: $table.lastOkMessage,
    builder: (column) => column,
  );
}

class $$RelayDeliveryTargetsTableTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $RelayDeliveryTargetsTableTable,
          DbRelayDeliveryTarget,
          $$RelayDeliveryTargetsTableTableFilterComposer,
          $$RelayDeliveryTargetsTableTableOrderingComposer,
          $$RelayDeliveryTargetsTableTableAnnotationComposer,
          $$RelayDeliveryTargetsTableTableCreateCompanionBuilder,
          $$RelayDeliveryTargetsTableTableUpdateCompanionBuilder,
          (
            DbRelayDeliveryTarget,
            BaseReferences<
              _$NdkCacheDatabase,
              $RelayDeliveryTargetsTableTable,
              DbRelayDeliveryTarget
            >,
          ),
          DbRelayDeliveryTarget,
          PrefetchHooks Function()
        > {
  $$RelayDeliveryTargetsTableTableTableManager(
    _$NdkCacheDatabase db,
    $RelayDeliveryTargetsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelayDeliveryTargetsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RelayDeliveryTargetsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RelayDeliveryTargetsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> relayUrl = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> lastOkMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelayDeliveryTargetsTableCompanion(
                eventId: eventId,
                relayUrl: relayUrl,
                reason: reason,
                state: state,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                lastOkMessage: lastOkMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String relayUrl,
                required String reason,
                required String state,
                Value<int> attemptCount = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> lastOkMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelayDeliveryTargetsTableCompanion.insert(
                eventId: eventId,
                relayUrl: relayUrl,
                reason: reason,
                state: state,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                lastOkMessage: lastOkMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RelayDeliveryTargetsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $RelayDeliveryTargetsTableTable,
      DbRelayDeliveryTarget,
      $$RelayDeliveryTargetsTableTableFilterComposer,
      $$RelayDeliveryTargetsTableTableOrderingComposer,
      $$RelayDeliveryTargetsTableTableAnnotationComposer,
      $$RelayDeliveryTargetsTableTableCreateCompanionBuilder,
      $$RelayDeliveryTargetsTableTableUpdateCompanionBuilder,
      (
        DbRelayDeliveryTarget,
        BaseReferences<
          _$NdkCacheDatabase,
          $RelayDeliveryTargetsTableTable,
          DbRelayDeliveryTarget
        >,
      ),
      DbRelayDeliveryTarget,
      PrefetchHooks Function()
    >;
typedef $$CashuProofsTableCreateCompanionBuilder =
    CashuProofsCompanion Function({
      required String Y,
      required String keysetId,
      required int amount,
      required String secret,
      required String unblindedSig,
      required String state,
      required String mintUrl,
      Value<int> rowid,
    });
typedef $$CashuProofsTableUpdateCompanionBuilder =
    CashuProofsCompanion Function({
      Value<String> Y,
      Value<String> keysetId,
      Value<int> amount,
      Value<String> secret,
      Value<String> unblindedSig,
      Value<String> state,
      Value<String> mintUrl,
      Value<int> rowid,
    });

class $$CashuProofsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $CashuProofsTable> {
  $$CashuProofsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get Y => $composableBuilder(
    column: $table.Y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keysetId => $composableBuilder(
    column: $table.keysetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secret => $composableBuilder(
    column: $table.secret,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unblindedSig => $composableBuilder(
    column: $table.unblindedSig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mintUrl => $composableBuilder(
    column: $table.mintUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashuProofsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $CashuProofsTable> {
  $$CashuProofsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get Y => $composableBuilder(
    column: $table.Y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keysetId => $composableBuilder(
    column: $table.keysetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secret => $composableBuilder(
    column: $table.secret,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unblindedSig => $composableBuilder(
    column: $table.unblindedSig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mintUrl => $composableBuilder(
    column: $table.mintUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashuProofsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $CashuProofsTable> {
  $$CashuProofsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get Y =>
      $composableBuilder(column: $table.Y, builder: (column) => column);

  GeneratedColumn<String> get keysetId =>
      $composableBuilder(column: $table.keysetId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get secret =>
      $composableBuilder(column: $table.secret, builder: (column) => column);

  GeneratedColumn<String> get unblindedSig => $composableBuilder(
    column: $table.unblindedSig,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get mintUrl =>
      $composableBuilder(column: $table.mintUrl, builder: (column) => column);
}

class $$CashuProofsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $CashuProofsTable,
          DbCashuProof,
          $$CashuProofsTableFilterComposer,
          $$CashuProofsTableOrderingComposer,
          $$CashuProofsTableAnnotationComposer,
          $$CashuProofsTableCreateCompanionBuilder,
          $$CashuProofsTableUpdateCompanionBuilder,
          (
            DbCashuProof,
            BaseReferences<_$NdkCacheDatabase, $CashuProofsTable, DbCashuProof>,
          ),
          DbCashuProof,
          PrefetchHooks Function()
        > {
  $$CashuProofsTableTableManager(_$NdkCacheDatabase db, $CashuProofsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashuProofsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashuProofsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashuProofsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> Y = const Value.absent(),
                Value<String> keysetId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> secret = const Value.absent(),
                Value<String> unblindedSig = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> mintUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashuProofsCompanion(
                Y: Y,
                keysetId: keysetId,
                amount: amount,
                secret: secret,
                unblindedSig: unblindedSig,
                state: state,
                mintUrl: mintUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String Y,
                required String keysetId,
                required int amount,
                required String secret,
                required String unblindedSig,
                required String state,
                required String mintUrl,
                Value<int> rowid = const Value.absent(),
              }) => CashuProofsCompanion.insert(
                Y: Y,
                keysetId: keysetId,
                amount: amount,
                secret: secret,
                unblindedSig: unblindedSig,
                state: state,
                mintUrl: mintUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashuProofsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $CashuProofsTable,
      DbCashuProof,
      $$CashuProofsTableFilterComposer,
      $$CashuProofsTableOrderingComposer,
      $$CashuProofsTableAnnotationComposer,
      $$CashuProofsTableCreateCompanionBuilder,
      $$CashuProofsTableUpdateCompanionBuilder,
      (
        DbCashuProof,
        BaseReferences<_$NdkCacheDatabase, $CashuProofsTable, DbCashuProof>,
      ),
      DbCashuProof,
      PrefetchHooks Function()
    >;
typedef $$CashuKeysetsTableCreateCompanionBuilder =
    CashuKeysetsCompanion Function({
      required String id,
      required String mintUrl,
      required String unit,
      required bool active,
      required int inputFeePPK,
      required String mintKeyPairsJson,
      Value<int?> fetchedAt,
      Value<int> rowid,
    });
typedef $$CashuKeysetsTableUpdateCompanionBuilder =
    CashuKeysetsCompanion Function({
      Value<String> id,
      Value<String> mintUrl,
      Value<String> unit,
      Value<bool> active,
      Value<int> inputFeePPK,
      Value<String> mintKeyPairsJson,
      Value<int?> fetchedAt,
      Value<int> rowid,
    });

class $$CashuKeysetsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $CashuKeysetsTable> {
  $$CashuKeysetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mintUrl => $composableBuilder(
    column: $table.mintUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputFeePPK => $composableBuilder(
    column: $table.inputFeePPK,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mintKeyPairsJson => $composableBuilder(
    column: $table.mintKeyPairsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashuKeysetsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $CashuKeysetsTable> {
  $$CashuKeysetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mintUrl => $composableBuilder(
    column: $table.mintUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputFeePPK => $composableBuilder(
    column: $table.inputFeePPK,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mintKeyPairsJson => $composableBuilder(
    column: $table.mintKeyPairsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashuKeysetsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $CashuKeysetsTable> {
  $$CashuKeysetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mintUrl =>
      $composableBuilder(column: $table.mintUrl, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get inputFeePPK => $composableBuilder(
    column: $table.inputFeePPK,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mintKeyPairsJson => $composableBuilder(
    column: $table.mintKeyPairsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CashuKeysetsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $CashuKeysetsTable,
          DbCashuKeyset,
          $$CashuKeysetsTableFilterComposer,
          $$CashuKeysetsTableOrderingComposer,
          $$CashuKeysetsTableAnnotationComposer,
          $$CashuKeysetsTableCreateCompanionBuilder,
          $$CashuKeysetsTableUpdateCompanionBuilder,
          (
            DbCashuKeyset,
            BaseReferences<
              _$NdkCacheDatabase,
              $CashuKeysetsTable,
              DbCashuKeyset
            >,
          ),
          DbCashuKeyset,
          PrefetchHooks Function()
        > {
  $$CashuKeysetsTableTableManager(
    _$NdkCacheDatabase db,
    $CashuKeysetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashuKeysetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashuKeysetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashuKeysetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mintUrl = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> inputFeePPK = const Value.absent(),
                Value<String> mintKeyPairsJson = const Value.absent(),
                Value<int?> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashuKeysetsCompanion(
                id: id,
                mintUrl: mintUrl,
                unit: unit,
                active: active,
                inputFeePPK: inputFeePPK,
                mintKeyPairsJson: mintKeyPairsJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mintUrl,
                required String unit,
                required bool active,
                required int inputFeePPK,
                required String mintKeyPairsJson,
                Value<int?> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashuKeysetsCompanion.insert(
                id: id,
                mintUrl: mintUrl,
                unit: unit,
                active: active,
                inputFeePPK: inputFeePPK,
                mintKeyPairsJson: mintKeyPairsJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashuKeysetsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $CashuKeysetsTable,
      DbCashuKeyset,
      $$CashuKeysetsTableFilterComposer,
      $$CashuKeysetsTableOrderingComposer,
      $$CashuKeysetsTableAnnotationComposer,
      $$CashuKeysetsTableCreateCompanionBuilder,
      $$CashuKeysetsTableUpdateCompanionBuilder,
      (
        DbCashuKeyset,
        BaseReferences<_$NdkCacheDatabase, $CashuKeysetsTable, DbCashuKeyset>,
      ),
      DbCashuKeyset,
      PrefetchHooks Function()
    >;
typedef $$CashuMintInfosTableCreateCompanionBuilder =
    CashuMintInfosCompanion Function({
      required String id,
      required String urlsJson,
      Value<String?> name,
      Value<String?> pubkey,
      Value<String?> version,
      Value<String?> description,
      Value<String?> descriptionLong,
      required String contactJson,
      Value<String?> motd,
      Value<String?> iconUrl,
      Value<int?> time,
      Value<String?> tosUrl,
      required String nutsJson,
      Value<int> rowid,
    });
typedef $$CashuMintInfosTableUpdateCompanionBuilder =
    CashuMintInfosCompanion Function({
      Value<String> id,
      Value<String> urlsJson,
      Value<String?> name,
      Value<String?> pubkey,
      Value<String?> version,
      Value<String?> description,
      Value<String?> descriptionLong,
      Value<String> contactJson,
      Value<String?> motd,
      Value<String?> iconUrl,
      Value<int?> time,
      Value<String?> tosUrl,
      Value<String> nutsJson,
      Value<int> rowid,
    });

class $$CashuMintInfosTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $CashuMintInfosTable> {
  $$CashuMintInfosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urlsJson => $composableBuilder(
    column: $table.urlsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionLong => $composableBuilder(
    column: $table.descriptionLong,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactJson => $composableBuilder(
    column: $table.contactJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motd => $composableBuilder(
    column: $table.motd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tosUrl => $composableBuilder(
    column: $table.tosUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nutsJson => $composableBuilder(
    column: $table.nutsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashuMintInfosTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $CashuMintInfosTable> {
  $$CashuMintInfosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urlsJson => $composableBuilder(
    column: $table.urlsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionLong => $composableBuilder(
    column: $table.descriptionLong,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactJson => $composableBuilder(
    column: $table.contactJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motd => $composableBuilder(
    column: $table.motd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tosUrl => $composableBuilder(
    column: $table.tosUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nutsJson => $composableBuilder(
    column: $table.nutsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashuMintInfosTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $CashuMintInfosTable> {
  $$CashuMintInfosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get urlsJson =>
      $composableBuilder(column: $table.urlsJson, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionLong => $composableBuilder(
    column: $table.descriptionLong,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactJson => $composableBuilder(
    column: $table.contactJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motd =>
      $composableBuilder(column: $table.motd, builder: (column) => column);

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get tosUrl =>
      $composableBuilder(column: $table.tosUrl, builder: (column) => column);

  GeneratedColumn<String> get nutsJson =>
      $composableBuilder(column: $table.nutsJson, builder: (column) => column);
}

class $$CashuMintInfosTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $CashuMintInfosTable,
          DbCashuMintInfo,
          $$CashuMintInfosTableFilterComposer,
          $$CashuMintInfosTableOrderingComposer,
          $$CashuMintInfosTableAnnotationComposer,
          $$CashuMintInfosTableCreateCompanionBuilder,
          $$CashuMintInfosTableUpdateCompanionBuilder,
          (
            DbCashuMintInfo,
            BaseReferences<
              _$NdkCacheDatabase,
              $CashuMintInfosTable,
              DbCashuMintInfo
            >,
          ),
          DbCashuMintInfo,
          PrefetchHooks Function()
        > {
  $$CashuMintInfosTableTableManager(
    _$NdkCacheDatabase db,
    $CashuMintInfosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashuMintInfosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashuMintInfosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashuMintInfosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> urlsJson = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> pubkey = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> descriptionLong = const Value.absent(),
                Value<String> contactJson = const Value.absent(),
                Value<String?> motd = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<int?> time = const Value.absent(),
                Value<String?> tosUrl = const Value.absent(),
                Value<String> nutsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashuMintInfosCompanion(
                id: id,
                urlsJson: urlsJson,
                name: name,
                pubkey: pubkey,
                version: version,
                description: description,
                descriptionLong: descriptionLong,
                contactJson: contactJson,
                motd: motd,
                iconUrl: iconUrl,
                time: time,
                tosUrl: tosUrl,
                nutsJson: nutsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String urlsJson,
                Value<String?> name = const Value.absent(),
                Value<String?> pubkey = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> descriptionLong = const Value.absent(),
                required String contactJson,
                Value<String?> motd = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<int?> time = const Value.absent(),
                Value<String?> tosUrl = const Value.absent(),
                required String nutsJson,
                Value<int> rowid = const Value.absent(),
              }) => CashuMintInfosCompanion.insert(
                id: id,
                urlsJson: urlsJson,
                name: name,
                pubkey: pubkey,
                version: version,
                description: description,
                descriptionLong: descriptionLong,
                contactJson: contactJson,
                motd: motd,
                iconUrl: iconUrl,
                time: time,
                tosUrl: tosUrl,
                nutsJson: nutsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashuMintInfosTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $CashuMintInfosTable,
      DbCashuMintInfo,
      $$CashuMintInfosTableFilterComposer,
      $$CashuMintInfosTableOrderingComposer,
      $$CashuMintInfosTableAnnotationComposer,
      $$CashuMintInfosTableCreateCompanionBuilder,
      $$CashuMintInfosTableUpdateCompanionBuilder,
      (
        DbCashuMintInfo,
        BaseReferences<
          _$NdkCacheDatabase,
          $CashuMintInfosTable,
          DbCashuMintInfo
        >,
      ),
      DbCashuMintInfo,
      PrefetchHooks Function()
    >;
typedef $$CashuSecretCountersTableCreateCompanionBuilder =
    CashuSecretCountersCompanion Function({
      required String id,
      required String mintUrl,
      required String keysetId,
      required int counter,
      Value<int> rowid,
    });
typedef $$CashuSecretCountersTableUpdateCompanionBuilder =
    CashuSecretCountersCompanion Function({
      Value<String> id,
      Value<String> mintUrl,
      Value<String> keysetId,
      Value<int> counter,
      Value<int> rowid,
    });

class $$CashuSecretCountersTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $CashuSecretCountersTable> {
  $$CashuSecretCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mintUrl => $composableBuilder(
    column: $table.mintUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keysetId => $composableBuilder(
    column: $table.keysetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashuSecretCountersTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $CashuSecretCountersTable> {
  $$CashuSecretCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mintUrl => $composableBuilder(
    column: $table.mintUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keysetId => $composableBuilder(
    column: $table.keysetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashuSecretCountersTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $CashuSecretCountersTable> {
  $$CashuSecretCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mintUrl =>
      $composableBuilder(column: $table.mintUrl, builder: (column) => column);

  GeneratedColumn<String> get keysetId =>
      $composableBuilder(column: $table.keysetId, builder: (column) => column);

  GeneratedColumn<int> get counter =>
      $composableBuilder(column: $table.counter, builder: (column) => column);
}

class $$CashuSecretCountersTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $CashuSecretCountersTable,
          DbCashuSecretCounter,
          $$CashuSecretCountersTableFilterComposer,
          $$CashuSecretCountersTableOrderingComposer,
          $$CashuSecretCountersTableAnnotationComposer,
          $$CashuSecretCountersTableCreateCompanionBuilder,
          $$CashuSecretCountersTableUpdateCompanionBuilder,
          (
            DbCashuSecretCounter,
            BaseReferences<
              _$NdkCacheDatabase,
              $CashuSecretCountersTable,
              DbCashuSecretCounter
            >,
          ),
          DbCashuSecretCounter,
          PrefetchHooks Function()
        > {
  $$CashuSecretCountersTableTableManager(
    _$NdkCacheDatabase db,
    $CashuSecretCountersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashuSecretCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashuSecretCountersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CashuSecretCountersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mintUrl = const Value.absent(),
                Value<String> keysetId = const Value.absent(),
                Value<int> counter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashuSecretCountersCompanion(
                id: id,
                mintUrl: mintUrl,
                keysetId: keysetId,
                counter: counter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mintUrl,
                required String keysetId,
                required int counter,
                Value<int> rowid = const Value.absent(),
              }) => CashuSecretCountersCompanion.insert(
                id: id,
                mintUrl: mintUrl,
                keysetId: keysetId,
                counter: counter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashuSecretCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $CashuSecretCountersTable,
      DbCashuSecretCounter,
      $$CashuSecretCountersTableFilterComposer,
      $$CashuSecretCountersTableOrderingComposer,
      $$CashuSecretCountersTableAnnotationComposer,
      $$CashuSecretCountersTableCreateCompanionBuilder,
      $$CashuSecretCountersTableUpdateCompanionBuilder,
      (
        DbCashuSecretCounter,
        BaseReferences<
          _$NdkCacheDatabase,
          $CashuSecretCountersTable,
          DbCashuSecretCounter
        >,
      ),
      DbCashuSecretCounter,
      PrefetchHooks Function()
    >;
typedef $$KeyValuesTableCreateCompanionBuilder =
    KeyValuesCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$KeyValuesTableUpdateCompanionBuilder =
    KeyValuesCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$KeyValuesTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $KeyValuesTable,
          DbKeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (
            DbKeyValue,
            BaseReferences<_$NdkCacheDatabase, $KeyValuesTable, DbKeyValue>,
          ),
          DbKeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$NdkCacheDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $KeyValuesTable,
      DbKeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (
        DbKeyValue,
        BaseReferences<_$NdkCacheDatabase, $KeyValuesTable, DbKeyValue>,
      ),
      DbKeyValue,
      PrefetchHooks Function()
    >;
typedef $$WalletsTableCreateCompanionBuilder =
    WalletsCompanion Function({
      required String id,
      required String name,
      required String type,
      required String supportedUnitsJson,
      required String metadataJson,
      Value<int> rowid,
    });
typedef $$WalletsTableUpdateCompanionBuilder =
    WalletsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String> supportedUnitsJson,
      Value<String> metadataJson,
      Value<int> rowid,
    });

class $$WalletsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportedUnitsJson => $composableBuilder(
    column: $table.supportedUnitsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WalletsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportedUnitsJson => $composableBuilder(
    column: $table.supportedUnitsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get supportedUnitsJson => $composableBuilder(
    column: $table.supportedUnitsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );
}

class $$WalletsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $WalletsTable,
          DbWallet,
          $$WalletsTableFilterComposer,
          $$WalletsTableOrderingComposer,
          $$WalletsTableAnnotationComposer,
          $$WalletsTableCreateCompanionBuilder,
          $$WalletsTableUpdateCompanionBuilder,
          (
            DbWallet,
            BaseReferences<_$NdkCacheDatabase, $WalletsTable, DbWallet>,
          ),
          DbWallet,
          PrefetchHooks Function()
        > {
  $$WalletsTableTableManager(_$NdkCacheDatabase db, $WalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> supportedUnitsJson = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletsCompanion(
                id: id,
                name: name,
                type: type,
                supportedUnitsJson: supportedUnitsJson,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required String supportedUnitsJson,
                required String metadataJson,
                Value<int> rowid = const Value.absent(),
              }) => WalletsCompanion.insert(
                id: id,
                name: name,
                type: type,
                supportedUnitsJson: supportedUnitsJson,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $WalletsTable,
      DbWallet,
      $$WalletsTableFilterComposer,
      $$WalletsTableOrderingComposer,
      $$WalletsTableAnnotationComposer,
      $$WalletsTableCreateCompanionBuilder,
      $$WalletsTableUpdateCompanionBuilder,
      (DbWallet, BaseReferences<_$NdkCacheDatabase, $WalletsTable, DbWallet>),
      DbWallet,
      PrefetchHooks Function()
    >;
typedef $$WalletTransactionsTableCreateCompanionBuilder =
    WalletTransactionsCompanion Function({
      required String id,
      required String walletId,
      required int changeAmount,
      required String unit,
      required String type,
      required String state,
      Value<String?> completionMsg,
      Value<int?> transactionDate,
      Value<int?> initiatedDate,
      required String metadataJson,
      Value<int> rowid,
    });
typedef $$WalletTransactionsTableUpdateCompanionBuilder =
    WalletTransactionsCompanion Function({
      Value<String> id,
      Value<String> walletId,
      Value<int> changeAmount,
      Value<String> unit,
      Value<String> type,
      Value<String> state,
      Value<String?> completionMsg,
      Value<int?> transactionDate,
      Value<int?> initiatedDate,
      Value<String> metadataJson,
      Value<int> rowid,
    });

class $$WalletTransactionsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $WalletTransactionsTable> {
  $$WalletTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get walletId => $composableBuilder(
    column: $table.walletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completionMsg => $composableBuilder(
    column: $table.completionMsg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initiatedDate => $composableBuilder(
    column: $table.initiatedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WalletTransactionsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $WalletTransactionsTable> {
  $$WalletTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletId => $composableBuilder(
    column: $table.walletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completionMsg => $composableBuilder(
    column: $table.completionMsg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initiatedDate => $composableBuilder(
    column: $table.initiatedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletTransactionsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $WalletTransactionsTable> {
  $$WalletTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get walletId =>
      $composableBuilder(column: $table.walletId, builder: (column) => column);

  GeneratedColumn<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get completionMsg => $composableBuilder(
    column: $table.completionMsg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get initiatedDate => $composableBuilder(
    column: $table.initiatedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );
}

class $$WalletTransactionsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $WalletTransactionsTable,
          DbWalletTransaction,
          $$WalletTransactionsTableFilterComposer,
          $$WalletTransactionsTableOrderingComposer,
          $$WalletTransactionsTableAnnotationComposer,
          $$WalletTransactionsTableCreateCompanionBuilder,
          $$WalletTransactionsTableUpdateCompanionBuilder,
          (
            DbWalletTransaction,
            BaseReferences<
              _$NdkCacheDatabase,
              $WalletTransactionsTable,
              DbWalletTransaction
            >,
          ),
          DbWalletTransaction,
          PrefetchHooks Function()
        > {
  $$WalletTransactionsTableTableManager(
    _$NdkCacheDatabase db,
    $WalletTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> walletId = const Value.absent(),
                Value<int> changeAmount = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> completionMsg = const Value.absent(),
                Value<int?> transactionDate = const Value.absent(),
                Value<int?> initiatedDate = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletTransactionsCompanion(
                id: id,
                walletId: walletId,
                changeAmount: changeAmount,
                unit: unit,
                type: type,
                state: state,
                completionMsg: completionMsg,
                transactionDate: transactionDate,
                initiatedDate: initiatedDate,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String walletId,
                required int changeAmount,
                required String unit,
                required String type,
                required String state,
                Value<String?> completionMsg = const Value.absent(),
                Value<int?> transactionDate = const Value.absent(),
                Value<int?> initiatedDate = const Value.absent(),
                required String metadataJson,
                Value<int> rowid = const Value.absent(),
              }) => WalletTransactionsCompanion.insert(
                id: id,
                walletId: walletId,
                changeAmount: changeAmount,
                unit: unit,
                type: type,
                state: state,
                completionMsg: completionMsg,
                transactionDate: transactionDate,
                initiatedDate: initiatedDate,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WalletTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $WalletTransactionsTable,
      DbWalletTransaction,
      $$WalletTransactionsTableFilterComposer,
      $$WalletTransactionsTableOrderingComposer,
      $$WalletTransactionsTableAnnotationComposer,
      $$WalletTransactionsTableCreateCompanionBuilder,
      $$WalletTransactionsTableUpdateCompanionBuilder,
      (
        DbWalletTransaction,
        BaseReferences<
          _$NdkCacheDatabase,
          $WalletTransactionsTable,
          DbWalletTransaction
        >,
      ),
      DbWalletTransaction,
      PrefetchHooks Function()
    >;

class $NdkCacheDatabaseManager {
  final _$NdkCacheDatabase _db;
  $NdkCacheDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$UserRelayListsTableTableManager get userRelayLists =>
      $$UserRelayListsTableTableManager(_db, _db.userRelayLists);
  $$RelaySetsTableTableManager get relaySets =>
      $$RelaySetsTableTableManager(_db, _db.relaySets);
  $$Nip05sTableTableManager get nip05s =>
      $$Nip05sTableTableManager(_db, _db.nip05s);
  $$FilterFetchedRangeRecordsTableTableManager get filterFetchedRangeRecords =>
      $$FilterFetchedRangeRecordsTableTableManager(
        _db,
        _db.filterFetchedRangeRecords,
      );
  $$EventSourcesTableTableTableManager get eventSourcesTable =>
      $$EventSourcesTableTableTableManager(_db, _db.eventSourcesTable);
  $$EventDeliveryRecordsTableTableTableManager get eventDeliveryRecordsTable =>
      $$EventDeliveryRecordsTableTableTableManager(
        _db,
        _db.eventDeliveryRecordsTable,
      );
  $$RelayDeliveryTargetsTableTableTableManager get relayDeliveryTargetsTable =>
      $$RelayDeliveryTargetsTableTableTableManager(
        _db,
        _db.relayDeliveryTargetsTable,
      );
  $$CashuProofsTableTableManager get cashuProofs =>
      $$CashuProofsTableTableManager(_db, _db.cashuProofs);
  $$CashuKeysetsTableTableManager get cashuKeysets =>
      $$CashuKeysetsTableTableManager(_db, _db.cashuKeysets);
  $$CashuMintInfosTableTableManager get cashuMintInfos =>
      $$CashuMintInfosTableTableManager(_db, _db.cashuMintInfos);
  $$CashuSecretCountersTableTableManager get cashuSecretCounters =>
      $$CashuSecretCountersTableTableManager(_db, _db.cashuSecretCounters);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$WalletTransactionsTableTableManager get walletTransactions =>
      $$WalletTransactionsTableTableManager(_db, _db.walletTransactions);
}
