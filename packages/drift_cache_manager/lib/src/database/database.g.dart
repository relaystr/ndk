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

class $MetadatasTable extends Metadatas
    with TableInfo<$MetadatasTable, DbMetadata> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetadatasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
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
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pictureMeta = const VerificationMeta(
    'picture',
  );
  @override
  late final GeneratedColumn<String> picture = GeneratedColumn<String>(
    'picture',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerMeta = const VerificationMeta('banner');
  @override
  late final GeneratedColumn<String> banner = GeneratedColumn<String>(
    'banner',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _websiteMeta = const VerificationMeta(
    'website',
  );
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
    'website',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aboutMeta = const VerificationMeta('about');
  @override
  late final GeneratedColumn<String> about = GeneratedColumn<String>(
    'about',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nip05Meta = const VerificationMeta('nip05');
  @override
  late final GeneratedColumn<String> nip05 = GeneratedColumn<String>(
    'nip05',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lud16Meta = const VerificationMeta('lud16');
  @override
  late final GeneratedColumn<String> lud16 = GeneratedColumn<String>(
    'lud16',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lud06Meta = const VerificationMeta('lud06');
  @override
  late final GeneratedColumn<String> lud06 = GeneratedColumn<String>(
    'lud06',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refreshedTimestampMeta =
      const VerificationMeta('refreshedTimestamp');
  @override
  late final GeneratedColumn<int> refreshedTimestamp = GeneratedColumn<int>(
    'refreshed_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    pubKey,
    name,
    displayName,
    picture,
    banner,
    website,
    about,
    nip05,
    lud16,
    lud06,
    updatedAt,
    refreshedTimestamp,
    sourcesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metadatas';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbMetadata> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('picture')) {
      context.handle(
        _pictureMeta,
        picture.isAcceptableOrUnknown(data['picture']!, _pictureMeta),
      );
    }
    if (data.containsKey('banner')) {
      context.handle(
        _bannerMeta,
        banner.isAcceptableOrUnknown(data['banner']!, _bannerMeta),
      );
    }
    if (data.containsKey('website')) {
      context.handle(
        _websiteMeta,
        website.isAcceptableOrUnknown(data['website']!, _websiteMeta),
      );
    }
    if (data.containsKey('about')) {
      context.handle(
        _aboutMeta,
        about.isAcceptableOrUnknown(data['about']!, _aboutMeta),
      );
    }
    if (data.containsKey('nip05')) {
      context.handle(
        _nip05Meta,
        nip05.isAcceptableOrUnknown(data['nip05']!, _nip05Meta),
      );
    }
    if (data.containsKey('lud16')) {
      context.handle(
        _lud16Meta,
        lud16.isAcceptableOrUnknown(data['lud16']!, _lud16Meta),
      );
    }
    if (data.containsKey('lud06')) {
      context.handle(
        _lud06Meta,
        lud06.isAcceptableOrUnknown(data['lud06']!, _lud06Meta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('refreshed_timestamp')) {
      context.handle(
        _refreshedTimestampMeta,
        refreshedTimestamp.isAcceptableOrUnknown(
          data['refreshed_timestamp']!,
          _refreshedTimestampMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {pubKey};
  @override
  DbMetadata map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbMetadata(
      pubKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      picture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}picture'],
      ),
      banner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner'],
      ),
      website: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}website'],
      ),
      about: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}about'],
      ),
      nip05: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nip05'],
      ),
      lud16: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lud16'],
      ),
      lud06: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lud06'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      refreshedTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}refreshed_timestamp'],
      ),
      sourcesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources_json'],
      )!,
    );
  }

  @override
  $MetadatasTable createAlias(String alias) {
    return $MetadatasTable(attachedDatabase, alias);
  }
}

class DbMetadata extends DataClass implements Insertable<DbMetadata> {
  final String pubKey;
  final String? name;
  final String? displayName;
  final String? picture;
  final String? banner;
  final String? website;
  final String? about;
  final String? nip05;
  final String? lud16;
  final String? lud06;
  final int? updatedAt;
  final int? refreshedTimestamp;
  final String sourcesJson;
  const DbMetadata({
    required this.pubKey,
    this.name,
    this.displayName,
    this.picture,
    this.banner,
    this.website,
    this.about,
    this.nip05,
    this.lud16,
    this.lud06,
    this.updatedAt,
    this.refreshedTimestamp,
    required this.sourcesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pub_key'] = Variable<String>(pubKey);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || picture != null) {
      map['picture'] = Variable<String>(picture);
    }
    if (!nullToAbsent || banner != null) {
      map['banner'] = Variable<String>(banner);
    }
    if (!nullToAbsent || website != null) {
      map['website'] = Variable<String>(website);
    }
    if (!nullToAbsent || about != null) {
      map['about'] = Variable<String>(about);
    }
    if (!nullToAbsent || nip05 != null) {
      map['nip05'] = Variable<String>(nip05);
    }
    if (!nullToAbsent || lud16 != null) {
      map['lud16'] = Variable<String>(lud16);
    }
    if (!nullToAbsent || lud06 != null) {
      map['lud06'] = Variable<String>(lud06);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || refreshedTimestamp != null) {
      map['refreshed_timestamp'] = Variable<int>(refreshedTimestamp);
    }
    map['sources_json'] = Variable<String>(sourcesJson);
    return map;
  }

  MetadatasCompanion toCompanion(bool nullToAbsent) {
    return MetadatasCompanion(
      pubKey: Value(pubKey),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      picture: picture == null && nullToAbsent
          ? const Value.absent()
          : Value(picture),
      banner: banner == null && nullToAbsent
          ? const Value.absent()
          : Value(banner),
      website: website == null && nullToAbsent
          ? const Value.absent()
          : Value(website),
      about: about == null && nullToAbsent
          ? const Value.absent()
          : Value(about),
      nip05: nip05 == null && nullToAbsent
          ? const Value.absent()
          : Value(nip05),
      lud16: lud16 == null && nullToAbsent
          ? const Value.absent()
          : Value(lud16),
      lud06: lud06 == null && nullToAbsent
          ? const Value.absent()
          : Value(lud06),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      refreshedTimestamp: refreshedTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(refreshedTimestamp),
      sourcesJson: Value(sourcesJson),
    );
  }

  factory DbMetadata.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbMetadata(
      pubKey: serializer.fromJson<String>(json['pubKey']),
      name: serializer.fromJson<String?>(json['name']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      picture: serializer.fromJson<String?>(json['picture']),
      banner: serializer.fromJson<String?>(json['banner']),
      website: serializer.fromJson<String?>(json['website']),
      about: serializer.fromJson<String?>(json['about']),
      nip05: serializer.fromJson<String?>(json['nip05']),
      lud16: serializer.fromJson<String?>(json['lud16']),
      lud06: serializer.fromJson<String?>(json['lud06']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      refreshedTimestamp: serializer.fromJson<int?>(json['refreshedTimestamp']),
      sourcesJson: serializer.fromJson<String>(json['sourcesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubKey': serializer.toJson<String>(pubKey),
      'name': serializer.toJson<String?>(name),
      'displayName': serializer.toJson<String?>(displayName),
      'picture': serializer.toJson<String?>(picture),
      'banner': serializer.toJson<String?>(banner),
      'website': serializer.toJson<String?>(website),
      'about': serializer.toJson<String?>(about),
      'nip05': serializer.toJson<String?>(nip05),
      'lud16': serializer.toJson<String?>(lud16),
      'lud06': serializer.toJson<String?>(lud06),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'refreshedTimestamp': serializer.toJson<int?>(refreshedTimestamp),
      'sourcesJson': serializer.toJson<String>(sourcesJson),
    };
  }

  DbMetadata copyWith({
    String? pubKey,
    Value<String?> name = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    Value<String?> picture = const Value.absent(),
    Value<String?> banner = const Value.absent(),
    Value<String?> website = const Value.absent(),
    Value<String?> about = const Value.absent(),
    Value<String?> nip05 = const Value.absent(),
    Value<String?> lud16 = const Value.absent(),
    Value<String?> lud06 = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> refreshedTimestamp = const Value.absent(),
    String? sourcesJson,
  }) => DbMetadata(
    pubKey: pubKey ?? this.pubKey,
    name: name.present ? name.value : this.name,
    displayName: displayName.present ? displayName.value : this.displayName,
    picture: picture.present ? picture.value : this.picture,
    banner: banner.present ? banner.value : this.banner,
    website: website.present ? website.value : this.website,
    about: about.present ? about.value : this.about,
    nip05: nip05.present ? nip05.value : this.nip05,
    lud16: lud16.present ? lud16.value : this.lud16,
    lud06: lud06.present ? lud06.value : this.lud06,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    refreshedTimestamp: refreshedTimestamp.present
        ? refreshedTimestamp.value
        : this.refreshedTimestamp,
    sourcesJson: sourcesJson ?? this.sourcesJson,
  );
  DbMetadata copyWithCompanion(MetadatasCompanion data) {
    return DbMetadata(
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      name: data.name.present ? data.name.value : this.name,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      picture: data.picture.present ? data.picture.value : this.picture,
      banner: data.banner.present ? data.banner.value : this.banner,
      website: data.website.present ? data.website.value : this.website,
      about: data.about.present ? data.about.value : this.about,
      nip05: data.nip05.present ? data.nip05.value : this.nip05,
      lud16: data.lud16.present ? data.lud16.value : this.lud16,
      lud06: data.lud06.present ? data.lud06.value : this.lud06,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      refreshedTimestamp: data.refreshedTimestamp.present
          ? data.refreshedTimestamp.value
          : this.refreshedTimestamp,
      sourcesJson: data.sourcesJson.present
          ? data.sourcesJson.value
          : this.sourcesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbMetadata(')
          ..write('pubKey: $pubKey, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('picture: $picture, ')
          ..write('banner: $banner, ')
          ..write('website: $website, ')
          ..write('about: $about, ')
          ..write('nip05: $nip05, ')
          ..write('lud16: $lud16, ')
          ..write('lud06: $lud06, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('refreshedTimestamp: $refreshedTimestamp, ')
          ..write('sourcesJson: $sourcesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pubKey,
    name,
    displayName,
    picture,
    banner,
    website,
    about,
    nip05,
    lud16,
    lud06,
    updatedAt,
    refreshedTimestamp,
    sourcesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbMetadata &&
          other.pubKey == this.pubKey &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.picture == this.picture &&
          other.banner == this.banner &&
          other.website == this.website &&
          other.about == this.about &&
          other.nip05 == this.nip05 &&
          other.lud16 == this.lud16 &&
          other.lud06 == this.lud06 &&
          other.updatedAt == this.updatedAt &&
          other.refreshedTimestamp == this.refreshedTimestamp &&
          other.sourcesJson == this.sourcesJson);
}

class MetadatasCompanion extends UpdateCompanion<DbMetadata> {
  final Value<String> pubKey;
  final Value<String?> name;
  final Value<String?> displayName;
  final Value<String?> picture;
  final Value<String?> banner;
  final Value<String?> website;
  final Value<String?> about;
  final Value<String?> nip05;
  final Value<String?> lud16;
  final Value<String?> lud06;
  final Value<int?> updatedAt;
  final Value<int?> refreshedTimestamp;
  final Value<String> sourcesJson;
  final Value<int> rowid;
  const MetadatasCompanion({
    this.pubKey = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.picture = const Value.absent(),
    this.banner = const Value.absent(),
    this.website = const Value.absent(),
    this.about = const Value.absent(),
    this.nip05 = const Value.absent(),
    this.lud16 = const Value.absent(),
    this.lud06 = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.refreshedTimestamp = const Value.absent(),
    this.sourcesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetadatasCompanion.insert({
    required String pubKey,
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.picture = const Value.absent(),
    this.banner = const Value.absent(),
    this.website = const Value.absent(),
    this.about = const Value.absent(),
    this.nip05 = const Value.absent(),
    this.lud16 = const Value.absent(),
    this.lud06 = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.refreshedTimestamp = const Value.absent(),
    required String sourcesJson,
    this.rowid = const Value.absent(),
  }) : pubKey = Value(pubKey),
       sourcesJson = Value(sourcesJson);
  static Insertable<DbMetadata> custom({
    Expression<String>? pubKey,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? picture,
    Expression<String>? banner,
    Expression<String>? website,
    Expression<String>? about,
    Expression<String>? nip05,
    Expression<String>? lud16,
    Expression<String>? lud06,
    Expression<int>? updatedAt,
    Expression<int>? refreshedTimestamp,
    Expression<String>? sourcesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubKey != null) 'pub_key': pubKey,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (picture != null) 'picture': picture,
      if (banner != null) 'banner': banner,
      if (website != null) 'website': website,
      if (about != null) 'about': about,
      if (nip05 != null) 'nip05': nip05,
      if (lud16 != null) 'lud16': lud16,
      if (lud06 != null) 'lud06': lud06,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (refreshedTimestamp != null) 'refreshed_timestamp': refreshedTimestamp,
      if (sourcesJson != null) 'sources_json': sourcesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetadatasCompanion copyWith({
    Value<String>? pubKey,
    Value<String?>? name,
    Value<String?>? displayName,
    Value<String?>? picture,
    Value<String?>? banner,
    Value<String?>? website,
    Value<String?>? about,
    Value<String?>? nip05,
    Value<String?>? lud16,
    Value<String?>? lud06,
    Value<int?>? updatedAt,
    Value<int?>? refreshedTimestamp,
    Value<String>? sourcesJson,
    Value<int>? rowid,
  }) {
    return MetadatasCompanion(
      pubKey: pubKey ?? this.pubKey,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      picture: picture ?? this.picture,
      banner: banner ?? this.banner,
      website: website ?? this.website,
      about: about ?? this.about,
      nip05: nip05 ?? this.nip05,
      lud16: lud16 ?? this.lud16,
      lud06: lud06 ?? this.lud06,
      updatedAt: updatedAt ?? this.updatedAt,
      refreshedTimestamp: refreshedTimestamp ?? this.refreshedTimestamp,
      sourcesJson: sourcesJson ?? this.sourcesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (picture.present) {
      map['picture'] = Variable<String>(picture.value);
    }
    if (banner.present) {
      map['banner'] = Variable<String>(banner.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (about.present) {
      map['about'] = Variable<String>(about.value);
    }
    if (nip05.present) {
      map['nip05'] = Variable<String>(nip05.value);
    }
    if (lud16.present) {
      map['lud16'] = Variable<String>(lud16.value);
    }
    if (lud06.present) {
      map['lud06'] = Variable<String>(lud06.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (refreshedTimestamp.present) {
      map['refreshed_timestamp'] = Variable<int>(refreshedTimestamp.value);
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
    return (StringBuffer('MetadatasCompanion(')
          ..write('pubKey: $pubKey, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('picture: $picture, ')
          ..write('banner: $banner, ')
          ..write('website: $website, ')
          ..write('about: $about, ')
          ..write('nip05: $nip05, ')
          ..write('lud16: $lud16, ')
          ..write('lud06: $lud06, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('refreshedTimestamp: $refreshedTimestamp, ')
          ..write('sourcesJson: $sourcesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactListsTable extends ContactLists
    with TableInfo<$ContactListsTable, DbContactList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactsJsonMeta = const VerificationMeta(
    'contactsJson',
  );
  @override
  late final GeneratedColumn<String> contactsJson = GeneratedColumn<String>(
    'contacts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactRelaysJsonMeta = const VerificationMeta(
    'contactRelaysJson',
  );
  @override
  late final GeneratedColumn<String> contactRelaysJson =
      GeneratedColumn<String>(
        'contact_relays_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _petnamesJsonMeta = const VerificationMeta(
    'petnamesJson',
  );
  @override
  late final GeneratedColumn<String> petnamesJson = GeneratedColumn<String>(
    'petnames_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _followedTagsJsonMeta = const VerificationMeta(
    'followedTagsJson',
  );
  @override
  late final GeneratedColumn<String> followedTagsJson = GeneratedColumn<String>(
    'followed_tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _followedCommunitiesJsonMeta =
      const VerificationMeta('followedCommunitiesJson');
  @override
  late final GeneratedColumn<String> followedCommunitiesJson =
      GeneratedColumn<String>(
        'followed_communities_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _followedEventsJsonMeta =
      const VerificationMeta('followedEventsJson');
  @override
  late final GeneratedColumn<String> followedEventsJson =
      GeneratedColumn<String>(
        'followed_events_json',
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
  static const VerificationMeta _loadedTimestampMeta = const VerificationMeta(
    'loadedTimestamp',
  );
  @override
  late final GeneratedColumn<int> loadedTimestamp = GeneratedColumn<int>(
    'loaded_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    pubKey,
    contactsJson,
    contactRelaysJson,
    petnamesJson,
    followedTagsJson,
    followedCommunitiesJson,
    followedEventsJson,
    createdAt,
    loadedTimestamp,
    sourcesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbContactList> instance, {
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
    if (data.containsKey('contacts_json')) {
      context.handle(
        _contactsJsonMeta,
        contactsJson.isAcceptableOrUnknown(
          data['contacts_json']!,
          _contactsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactsJsonMeta);
    }
    if (data.containsKey('contact_relays_json')) {
      context.handle(
        _contactRelaysJsonMeta,
        contactRelaysJson.isAcceptableOrUnknown(
          data['contact_relays_json']!,
          _contactRelaysJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactRelaysJsonMeta);
    }
    if (data.containsKey('petnames_json')) {
      context.handle(
        _petnamesJsonMeta,
        petnamesJson.isAcceptableOrUnknown(
          data['petnames_json']!,
          _petnamesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_petnamesJsonMeta);
    }
    if (data.containsKey('followed_tags_json')) {
      context.handle(
        _followedTagsJsonMeta,
        followedTagsJson.isAcceptableOrUnknown(
          data['followed_tags_json']!,
          _followedTagsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_followedTagsJsonMeta);
    }
    if (data.containsKey('followed_communities_json')) {
      context.handle(
        _followedCommunitiesJsonMeta,
        followedCommunitiesJson.isAcceptableOrUnknown(
          data['followed_communities_json']!,
          _followedCommunitiesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_followedCommunitiesJsonMeta);
    }
    if (data.containsKey('followed_events_json')) {
      context.handle(
        _followedEventsJsonMeta,
        followedEventsJson.isAcceptableOrUnknown(
          data['followed_events_json']!,
          _followedEventsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_followedEventsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('loaded_timestamp')) {
      context.handle(
        _loadedTimestampMeta,
        loadedTimestamp.isAcceptableOrUnknown(
          data['loaded_timestamp']!,
          _loadedTimestampMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {pubKey};
  @override
  DbContactList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbContactList(
      pubKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_key'],
      )!,
      contactsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contacts_json'],
      )!,
      contactRelaysJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_relays_json'],
      )!,
      petnamesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}petnames_json'],
      )!,
      followedTagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followed_tags_json'],
      )!,
      followedCommunitiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followed_communities_json'],
      )!,
      followedEventsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followed_events_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      loadedTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loaded_timestamp'],
      ),
      sourcesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources_json'],
      )!,
    );
  }

  @override
  $ContactListsTable createAlias(String alias) {
    return $ContactListsTable(attachedDatabase, alias);
  }
}

class DbContactList extends DataClass implements Insertable<DbContactList> {
  final String pubKey;
  final String contactsJson;
  final String contactRelaysJson;
  final String petnamesJson;
  final String followedTagsJson;
  final String followedCommunitiesJson;
  final String followedEventsJson;
  final int createdAt;
  final int? loadedTimestamp;
  final String sourcesJson;
  const DbContactList({
    required this.pubKey,
    required this.contactsJson,
    required this.contactRelaysJson,
    required this.petnamesJson,
    required this.followedTagsJson,
    required this.followedCommunitiesJson,
    required this.followedEventsJson,
    required this.createdAt,
    this.loadedTimestamp,
    required this.sourcesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pub_key'] = Variable<String>(pubKey);
    map['contacts_json'] = Variable<String>(contactsJson);
    map['contact_relays_json'] = Variable<String>(contactRelaysJson);
    map['petnames_json'] = Variable<String>(petnamesJson);
    map['followed_tags_json'] = Variable<String>(followedTagsJson);
    map['followed_communities_json'] = Variable<String>(
      followedCommunitiesJson,
    );
    map['followed_events_json'] = Variable<String>(followedEventsJson);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || loadedTimestamp != null) {
      map['loaded_timestamp'] = Variable<int>(loadedTimestamp);
    }
    map['sources_json'] = Variable<String>(sourcesJson);
    return map;
  }

  ContactListsCompanion toCompanion(bool nullToAbsent) {
    return ContactListsCompanion(
      pubKey: Value(pubKey),
      contactsJson: Value(contactsJson),
      contactRelaysJson: Value(contactRelaysJson),
      petnamesJson: Value(petnamesJson),
      followedTagsJson: Value(followedTagsJson),
      followedCommunitiesJson: Value(followedCommunitiesJson),
      followedEventsJson: Value(followedEventsJson),
      createdAt: Value(createdAt),
      loadedTimestamp: loadedTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(loadedTimestamp),
      sourcesJson: Value(sourcesJson),
    );
  }

  factory DbContactList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbContactList(
      pubKey: serializer.fromJson<String>(json['pubKey']),
      contactsJson: serializer.fromJson<String>(json['contactsJson']),
      contactRelaysJson: serializer.fromJson<String>(json['contactRelaysJson']),
      petnamesJson: serializer.fromJson<String>(json['petnamesJson']),
      followedTagsJson: serializer.fromJson<String>(json['followedTagsJson']),
      followedCommunitiesJson: serializer.fromJson<String>(
        json['followedCommunitiesJson'],
      ),
      followedEventsJson: serializer.fromJson<String>(
        json['followedEventsJson'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      loadedTimestamp: serializer.fromJson<int?>(json['loadedTimestamp']),
      sourcesJson: serializer.fromJson<String>(json['sourcesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubKey': serializer.toJson<String>(pubKey),
      'contactsJson': serializer.toJson<String>(contactsJson),
      'contactRelaysJson': serializer.toJson<String>(contactRelaysJson),
      'petnamesJson': serializer.toJson<String>(petnamesJson),
      'followedTagsJson': serializer.toJson<String>(followedTagsJson),
      'followedCommunitiesJson': serializer.toJson<String>(
        followedCommunitiesJson,
      ),
      'followedEventsJson': serializer.toJson<String>(followedEventsJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'loadedTimestamp': serializer.toJson<int?>(loadedTimestamp),
      'sourcesJson': serializer.toJson<String>(sourcesJson),
    };
  }

  DbContactList copyWith({
    String? pubKey,
    String? contactsJson,
    String? contactRelaysJson,
    String? petnamesJson,
    String? followedTagsJson,
    String? followedCommunitiesJson,
    String? followedEventsJson,
    int? createdAt,
    Value<int?> loadedTimestamp = const Value.absent(),
    String? sourcesJson,
  }) => DbContactList(
    pubKey: pubKey ?? this.pubKey,
    contactsJson: contactsJson ?? this.contactsJson,
    contactRelaysJson: contactRelaysJson ?? this.contactRelaysJson,
    petnamesJson: petnamesJson ?? this.petnamesJson,
    followedTagsJson: followedTagsJson ?? this.followedTagsJson,
    followedCommunitiesJson:
        followedCommunitiesJson ?? this.followedCommunitiesJson,
    followedEventsJson: followedEventsJson ?? this.followedEventsJson,
    createdAt: createdAt ?? this.createdAt,
    loadedTimestamp: loadedTimestamp.present
        ? loadedTimestamp.value
        : this.loadedTimestamp,
    sourcesJson: sourcesJson ?? this.sourcesJson,
  );
  DbContactList copyWithCompanion(ContactListsCompanion data) {
    return DbContactList(
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      contactsJson: data.contactsJson.present
          ? data.contactsJson.value
          : this.contactsJson,
      contactRelaysJson: data.contactRelaysJson.present
          ? data.contactRelaysJson.value
          : this.contactRelaysJson,
      petnamesJson: data.petnamesJson.present
          ? data.petnamesJson.value
          : this.petnamesJson,
      followedTagsJson: data.followedTagsJson.present
          ? data.followedTagsJson.value
          : this.followedTagsJson,
      followedCommunitiesJson: data.followedCommunitiesJson.present
          ? data.followedCommunitiesJson.value
          : this.followedCommunitiesJson,
      followedEventsJson: data.followedEventsJson.present
          ? data.followedEventsJson.value
          : this.followedEventsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      loadedTimestamp: data.loadedTimestamp.present
          ? data.loadedTimestamp.value
          : this.loadedTimestamp,
      sourcesJson: data.sourcesJson.present
          ? data.sourcesJson.value
          : this.sourcesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbContactList(')
          ..write('pubKey: $pubKey, ')
          ..write('contactsJson: $contactsJson, ')
          ..write('contactRelaysJson: $contactRelaysJson, ')
          ..write('petnamesJson: $petnamesJson, ')
          ..write('followedTagsJson: $followedTagsJson, ')
          ..write('followedCommunitiesJson: $followedCommunitiesJson, ')
          ..write('followedEventsJson: $followedEventsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('loadedTimestamp: $loadedTimestamp, ')
          ..write('sourcesJson: $sourcesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pubKey,
    contactsJson,
    contactRelaysJson,
    petnamesJson,
    followedTagsJson,
    followedCommunitiesJson,
    followedEventsJson,
    createdAt,
    loadedTimestamp,
    sourcesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbContactList &&
          other.pubKey == this.pubKey &&
          other.contactsJson == this.contactsJson &&
          other.contactRelaysJson == this.contactRelaysJson &&
          other.petnamesJson == this.petnamesJson &&
          other.followedTagsJson == this.followedTagsJson &&
          other.followedCommunitiesJson == this.followedCommunitiesJson &&
          other.followedEventsJson == this.followedEventsJson &&
          other.createdAt == this.createdAt &&
          other.loadedTimestamp == this.loadedTimestamp &&
          other.sourcesJson == this.sourcesJson);
}

class ContactListsCompanion extends UpdateCompanion<DbContactList> {
  final Value<String> pubKey;
  final Value<String> contactsJson;
  final Value<String> contactRelaysJson;
  final Value<String> petnamesJson;
  final Value<String> followedTagsJson;
  final Value<String> followedCommunitiesJson;
  final Value<String> followedEventsJson;
  final Value<int> createdAt;
  final Value<int?> loadedTimestamp;
  final Value<String> sourcesJson;
  final Value<int> rowid;
  const ContactListsCompanion({
    this.pubKey = const Value.absent(),
    this.contactsJson = const Value.absent(),
    this.contactRelaysJson = const Value.absent(),
    this.petnamesJson = const Value.absent(),
    this.followedTagsJson = const Value.absent(),
    this.followedCommunitiesJson = const Value.absent(),
    this.followedEventsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.loadedTimestamp = const Value.absent(),
    this.sourcesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactListsCompanion.insert({
    required String pubKey,
    required String contactsJson,
    required String contactRelaysJson,
    required String petnamesJson,
    required String followedTagsJson,
    required String followedCommunitiesJson,
    required String followedEventsJson,
    required int createdAt,
    this.loadedTimestamp = const Value.absent(),
    required String sourcesJson,
    this.rowid = const Value.absent(),
  }) : pubKey = Value(pubKey),
       contactsJson = Value(contactsJson),
       contactRelaysJson = Value(contactRelaysJson),
       petnamesJson = Value(petnamesJson),
       followedTagsJson = Value(followedTagsJson),
       followedCommunitiesJson = Value(followedCommunitiesJson),
       followedEventsJson = Value(followedEventsJson),
       createdAt = Value(createdAt),
       sourcesJson = Value(sourcesJson);
  static Insertable<DbContactList> custom({
    Expression<String>? pubKey,
    Expression<String>? contactsJson,
    Expression<String>? contactRelaysJson,
    Expression<String>? petnamesJson,
    Expression<String>? followedTagsJson,
    Expression<String>? followedCommunitiesJson,
    Expression<String>? followedEventsJson,
    Expression<int>? createdAt,
    Expression<int>? loadedTimestamp,
    Expression<String>? sourcesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubKey != null) 'pub_key': pubKey,
      if (contactsJson != null) 'contacts_json': contactsJson,
      if (contactRelaysJson != null) 'contact_relays_json': contactRelaysJson,
      if (petnamesJson != null) 'petnames_json': petnamesJson,
      if (followedTagsJson != null) 'followed_tags_json': followedTagsJson,
      if (followedCommunitiesJson != null)
        'followed_communities_json': followedCommunitiesJson,
      if (followedEventsJson != null)
        'followed_events_json': followedEventsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (loadedTimestamp != null) 'loaded_timestamp': loadedTimestamp,
      if (sourcesJson != null) 'sources_json': sourcesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactListsCompanion copyWith({
    Value<String>? pubKey,
    Value<String>? contactsJson,
    Value<String>? contactRelaysJson,
    Value<String>? petnamesJson,
    Value<String>? followedTagsJson,
    Value<String>? followedCommunitiesJson,
    Value<String>? followedEventsJson,
    Value<int>? createdAt,
    Value<int?>? loadedTimestamp,
    Value<String>? sourcesJson,
    Value<int>? rowid,
  }) {
    return ContactListsCompanion(
      pubKey: pubKey ?? this.pubKey,
      contactsJson: contactsJson ?? this.contactsJson,
      contactRelaysJson: contactRelaysJson ?? this.contactRelaysJson,
      petnamesJson: petnamesJson ?? this.petnamesJson,
      followedTagsJson: followedTagsJson ?? this.followedTagsJson,
      followedCommunitiesJson:
          followedCommunitiesJson ?? this.followedCommunitiesJson,
      followedEventsJson: followedEventsJson ?? this.followedEventsJson,
      createdAt: createdAt ?? this.createdAt,
      loadedTimestamp: loadedTimestamp ?? this.loadedTimestamp,
      sourcesJson: sourcesJson ?? this.sourcesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (contactsJson.present) {
      map['contacts_json'] = Variable<String>(contactsJson.value);
    }
    if (contactRelaysJson.present) {
      map['contact_relays_json'] = Variable<String>(contactRelaysJson.value);
    }
    if (petnamesJson.present) {
      map['petnames_json'] = Variable<String>(petnamesJson.value);
    }
    if (followedTagsJson.present) {
      map['followed_tags_json'] = Variable<String>(followedTagsJson.value);
    }
    if (followedCommunitiesJson.present) {
      map['followed_communities_json'] = Variable<String>(
        followedCommunitiesJson.value,
      );
    }
    if (followedEventsJson.present) {
      map['followed_events_json'] = Variable<String>(followedEventsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (loadedTimestamp.present) {
      map['loaded_timestamp'] = Variable<int>(loadedTimestamp.value);
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
    return (StringBuffer('ContactListsCompanion(')
          ..write('pubKey: $pubKey, ')
          ..write('contactsJson: $contactsJson, ')
          ..write('contactRelaysJson: $contactRelaysJson, ')
          ..write('petnamesJson: $petnamesJson, ')
          ..write('followedTagsJson: $followedTagsJson, ')
          ..write('followedCommunitiesJson: $followedCommunitiesJson, ')
          ..write('followedEventsJson: $followedEventsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('loadedTimestamp: $loadedTimestamp, ')
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

abstract class _$NdkCacheDatabase extends GeneratedDatabase {
  _$NdkCacheDatabase(QueryExecutor e) : super(e);
  $NdkCacheDatabaseManager get managers => $NdkCacheDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $MetadatasTable metadatas = $MetadatasTable(this);
  late final $ContactListsTable contactLists = $ContactListsTable(this);
  late final $UserRelayListsTable userRelayLists = $UserRelayListsTable(this);
  late final $RelaySetsTable relaySets = $RelaySetsTable(this);
  late final $Nip05sTable nip05s = $Nip05sTable(this);
  late final $FilterFetchedRangeRecordsTable filterFetchedRangeRecords =
      $FilterFetchedRangeRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    events,
    metadatas,
    contactLists,
    userRelayLists,
    relaySets,
    nip05s,
    filterFetchedRangeRecords,
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
typedef $$MetadatasTableCreateCompanionBuilder =
    MetadatasCompanion Function({
      required String pubKey,
      Value<String?> name,
      Value<String?> displayName,
      Value<String?> picture,
      Value<String?> banner,
      Value<String?> website,
      Value<String?> about,
      Value<String?> nip05,
      Value<String?> lud16,
      Value<String?> lud06,
      Value<int?> updatedAt,
      Value<int?> refreshedTimestamp,
      required String sourcesJson,
      Value<int> rowid,
    });
typedef $$MetadatasTableUpdateCompanionBuilder =
    MetadatasCompanion Function({
      Value<String> pubKey,
      Value<String?> name,
      Value<String?> displayName,
      Value<String?> picture,
      Value<String?> banner,
      Value<String?> website,
      Value<String?> about,
      Value<String?> nip05,
      Value<String?> lud16,
      Value<String?> lud06,
      Value<int?> updatedAt,
      Value<int?> refreshedTimestamp,
      Value<String> sourcesJson,
      Value<int> rowid,
    });

class $$MetadatasTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $MetadatasTable> {
  $$MetadatasTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get picture => $composableBuilder(
    column: $table.picture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get banner => $composableBuilder(
    column: $table.banner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get about => $composableBuilder(
    column: $table.about,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nip05 => $composableBuilder(
    column: $table.nip05,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lud16 => $composableBuilder(
    column: $table.lud16,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lud06 => $composableBuilder(
    column: $table.lud06,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refreshedTimestamp => $composableBuilder(
    column: $table.refreshedTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetadatasTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $MetadatasTable> {
  $$MetadatasTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get picture => $composableBuilder(
    column: $table.picture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get banner => $composableBuilder(
    column: $table.banner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get about => $composableBuilder(
    column: $table.about,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nip05 => $composableBuilder(
    column: $table.nip05,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lud16 => $composableBuilder(
    column: $table.lud16,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lud06 => $composableBuilder(
    column: $table.lud06,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedTimestamp => $composableBuilder(
    column: $table.refreshedTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetadatasTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $MetadatasTable> {
  $$MetadatasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubKey =>
      $composableBuilder(column: $table.pubKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get picture =>
      $composableBuilder(column: $table.picture, builder: (column) => column);

  GeneratedColumn<String> get banner =>
      $composableBuilder(column: $table.banner, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<String> get about =>
      $composableBuilder(column: $table.about, builder: (column) => column);

  GeneratedColumn<String> get nip05 =>
      $composableBuilder(column: $table.nip05, builder: (column) => column);

  GeneratedColumn<String> get lud16 =>
      $composableBuilder(column: $table.lud16, builder: (column) => column);

  GeneratedColumn<String> get lud06 =>
      $composableBuilder(column: $table.lud06, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get refreshedTimestamp => $composableBuilder(
    column: $table.refreshedTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => column,
  );
}

class $$MetadatasTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $MetadatasTable,
          DbMetadata,
          $$MetadatasTableFilterComposer,
          $$MetadatasTableOrderingComposer,
          $$MetadatasTableAnnotationComposer,
          $$MetadatasTableCreateCompanionBuilder,
          $$MetadatasTableUpdateCompanionBuilder,
          (
            DbMetadata,
            BaseReferences<_$NdkCacheDatabase, $MetadatasTable, DbMetadata>,
          ),
          DbMetadata,
          PrefetchHooks Function()
        > {
  $$MetadatasTableTableManager(_$NdkCacheDatabase db, $MetadatasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetadatasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetadatasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetadatasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pubKey = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> picture = const Value.absent(),
                Value<String?> banner = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<String?> about = const Value.absent(),
                Value<String?> nip05 = const Value.absent(),
                Value<String?> lud16 = const Value.absent(),
                Value<String?> lud06 = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> refreshedTimestamp = const Value.absent(),
                Value<String> sourcesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetadatasCompanion(
                pubKey: pubKey,
                name: name,
                displayName: displayName,
                picture: picture,
                banner: banner,
                website: website,
                about: about,
                nip05: nip05,
                lud16: lud16,
                lud06: lud06,
                updatedAt: updatedAt,
                refreshedTimestamp: refreshedTimestamp,
                sourcesJson: sourcesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pubKey,
                Value<String?> name = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> picture = const Value.absent(),
                Value<String?> banner = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<String?> about = const Value.absent(),
                Value<String?> nip05 = const Value.absent(),
                Value<String?> lud16 = const Value.absent(),
                Value<String?> lud06 = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> refreshedTimestamp = const Value.absent(),
                required String sourcesJson,
                Value<int> rowid = const Value.absent(),
              }) => MetadatasCompanion.insert(
                pubKey: pubKey,
                name: name,
                displayName: displayName,
                picture: picture,
                banner: banner,
                website: website,
                about: about,
                nip05: nip05,
                lud16: lud16,
                lud06: lud06,
                updatedAt: updatedAt,
                refreshedTimestamp: refreshedTimestamp,
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

typedef $$MetadatasTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $MetadatasTable,
      DbMetadata,
      $$MetadatasTableFilterComposer,
      $$MetadatasTableOrderingComposer,
      $$MetadatasTableAnnotationComposer,
      $$MetadatasTableCreateCompanionBuilder,
      $$MetadatasTableUpdateCompanionBuilder,
      (
        DbMetadata,
        BaseReferences<_$NdkCacheDatabase, $MetadatasTable, DbMetadata>,
      ),
      DbMetadata,
      PrefetchHooks Function()
    >;
typedef $$ContactListsTableCreateCompanionBuilder =
    ContactListsCompanion Function({
      required String pubKey,
      required String contactsJson,
      required String contactRelaysJson,
      required String petnamesJson,
      required String followedTagsJson,
      required String followedCommunitiesJson,
      required String followedEventsJson,
      required int createdAt,
      Value<int?> loadedTimestamp,
      required String sourcesJson,
      Value<int> rowid,
    });
typedef $$ContactListsTableUpdateCompanionBuilder =
    ContactListsCompanion Function({
      Value<String> pubKey,
      Value<String> contactsJson,
      Value<String> contactRelaysJson,
      Value<String> petnamesJson,
      Value<String> followedTagsJson,
      Value<String> followedCommunitiesJson,
      Value<String> followedEventsJson,
      Value<int> createdAt,
      Value<int?> loadedTimestamp,
      Value<String> sourcesJson,
      Value<int> rowid,
    });

class $$ContactListsTableFilterComposer
    extends Composer<_$NdkCacheDatabase, $ContactListsTable> {
  $$ContactListsTableFilterComposer({
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

  ColumnFilters<String> get contactsJson => $composableBuilder(
    column: $table.contactsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactRelaysJson => $composableBuilder(
    column: $table.contactRelaysJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get petnamesJson => $composableBuilder(
    column: $table.petnamesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followedTagsJson => $composableBuilder(
    column: $table.followedTagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followedCommunitiesJson => $composableBuilder(
    column: $table.followedCommunitiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followedEventsJson => $composableBuilder(
    column: $table.followedEventsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loadedTimestamp => $composableBuilder(
    column: $table.loadedTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactListsTableOrderingComposer
    extends Composer<_$NdkCacheDatabase, $ContactListsTable> {
  $$ContactListsTableOrderingComposer({
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

  ColumnOrderings<String> get contactsJson => $composableBuilder(
    column: $table.contactsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactRelaysJson => $composableBuilder(
    column: $table.contactRelaysJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get petnamesJson => $composableBuilder(
    column: $table.petnamesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followedTagsJson => $composableBuilder(
    column: $table.followedTagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followedCommunitiesJson => $composableBuilder(
    column: $table.followedCommunitiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followedEventsJson => $composableBuilder(
    column: $table.followedEventsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loadedTimestamp => $composableBuilder(
    column: $table.loadedTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactListsTableAnnotationComposer
    extends Composer<_$NdkCacheDatabase, $ContactListsTable> {
  $$ContactListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubKey =>
      $composableBuilder(column: $table.pubKey, builder: (column) => column);

  GeneratedColumn<String> get contactsJson => $composableBuilder(
    column: $table.contactsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactRelaysJson => $composableBuilder(
    column: $table.contactRelaysJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get petnamesJson => $composableBuilder(
    column: $table.petnamesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followedTagsJson => $composableBuilder(
    column: $table.followedTagsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followedCommunitiesJson => $composableBuilder(
    column: $table.followedCommunitiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followedEventsJson => $composableBuilder(
    column: $table.followedEventsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get loadedTimestamp => $composableBuilder(
    column: $table.loadedTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => column,
  );
}

class $$ContactListsTableTableManager
    extends
        RootTableManager<
          _$NdkCacheDatabase,
          $ContactListsTable,
          DbContactList,
          $$ContactListsTableFilterComposer,
          $$ContactListsTableOrderingComposer,
          $$ContactListsTableAnnotationComposer,
          $$ContactListsTableCreateCompanionBuilder,
          $$ContactListsTableUpdateCompanionBuilder,
          (
            DbContactList,
            BaseReferences<
              _$NdkCacheDatabase,
              $ContactListsTable,
              DbContactList
            >,
          ),
          DbContactList,
          PrefetchHooks Function()
        > {
  $$ContactListsTableTableManager(
    _$NdkCacheDatabase db,
    $ContactListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pubKey = const Value.absent(),
                Value<String> contactsJson = const Value.absent(),
                Value<String> contactRelaysJson = const Value.absent(),
                Value<String> petnamesJson = const Value.absent(),
                Value<String> followedTagsJson = const Value.absent(),
                Value<String> followedCommunitiesJson = const Value.absent(),
                Value<String> followedEventsJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> loadedTimestamp = const Value.absent(),
                Value<String> sourcesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactListsCompanion(
                pubKey: pubKey,
                contactsJson: contactsJson,
                contactRelaysJson: contactRelaysJson,
                petnamesJson: petnamesJson,
                followedTagsJson: followedTagsJson,
                followedCommunitiesJson: followedCommunitiesJson,
                followedEventsJson: followedEventsJson,
                createdAt: createdAt,
                loadedTimestamp: loadedTimestamp,
                sourcesJson: sourcesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pubKey,
                required String contactsJson,
                required String contactRelaysJson,
                required String petnamesJson,
                required String followedTagsJson,
                required String followedCommunitiesJson,
                required String followedEventsJson,
                required int createdAt,
                Value<int?> loadedTimestamp = const Value.absent(),
                required String sourcesJson,
                Value<int> rowid = const Value.absent(),
              }) => ContactListsCompanion.insert(
                pubKey: pubKey,
                contactsJson: contactsJson,
                contactRelaysJson: contactRelaysJson,
                petnamesJson: petnamesJson,
                followedTagsJson: followedTagsJson,
                followedCommunitiesJson: followedCommunitiesJson,
                followedEventsJson: followedEventsJson,
                createdAt: createdAt,
                loadedTimestamp: loadedTimestamp,
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

typedef $$ContactListsTableProcessedTableManager =
    ProcessedTableManager<
      _$NdkCacheDatabase,
      $ContactListsTable,
      DbContactList,
      $$ContactListsTableFilterComposer,
      $$ContactListsTableOrderingComposer,
      $$ContactListsTableAnnotationComposer,
      $$ContactListsTableCreateCompanionBuilder,
      $$ContactListsTableUpdateCompanionBuilder,
      (
        DbContactList,
        BaseReferences<_$NdkCacheDatabase, $ContactListsTable, DbContactList>,
      ),
      DbContactList,
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

class $NdkCacheDatabaseManager {
  final _$NdkCacheDatabase _db;
  $NdkCacheDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$MetadatasTableTableManager get metadatas =>
      $$MetadatasTableTableManager(_db, _db.metadatas);
  $$ContactListsTableTableManager get contactLists =>
      $$ContactListsTableTableManager(_db, _db.contactLists);
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
}
