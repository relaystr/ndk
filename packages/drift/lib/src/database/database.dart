import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:ndk/ndk.dart' show ContactList, Metadata, Nip01Event;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Events,
    UserRelayLists,
    RelaySets,
    Nip05s,
    FilterFetchedRangeRecords,
    EventSourcesTable,
    EventDeliveryRecordsTable,
    RelayDeliveryTargetsTable,
    // Cashu tables
    CashuProofs,
    CashuKeysets,
    CashuMintInfos,
    CashuSecretCounters,
    KeyValues,
    Wallets,
    WalletTransactions,
  ],
)
class NdkCacheDatabase extends _$NdkCacheDatabase {
  NdkCacheDatabase({String? dbName})
    : super(
        _openConnection(
          dbName ?? (kDebugMode ? 'ndk_cache_debug' : 'ndk_cache'),
        ),
      );

  NdkCacheDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          // Add Cashu tables
          await m.createTable(cashuProofs);
          await m.createTable(cashuKeysets);
          await m.createTable(cashuMintInfos);
          await m.createTable(cashuSecretCounters);
          await m.createTable(wallets);
          await m.createTable(walletTransactions);
        }
        if (from < 4) {
          // Add key-value table for settings
          await m.createTable(keyValues);
        }
        if (from < 5) {
          // Add event source provenance and delivery tracking tables
          await m.createTable(eventSourcesTable);
          await m.createTable(eventDeliveryRecordsTable);
          await m.createTable(relayDeliveryTargetsTable);
        }
        if (from < 6) {
          // Metadata and contact-list projections are derived from generic
          // events now. Copy legacy rows into the events table so cached
          // profiles and follow lists survive the upgrade, then drop the
          // legacy tables.
          await _migrateLegacyMetadatas();
          await _migrateLegacyContactLists();
        }
      },
    );
  }

  /// Copies rows of the pre-v6 `metadatas` table into the events table as
  /// projected kind-0 events (unsigned, `sig` stays null).
  Future<void> _migrateLegacyMetadatas() async {
    if (!await _legacyTableExists('metadatas')) return;
    final rows = await customSelect('SELECT * FROM metadatas').get();
    for (final row in rows) {
      final updatedAt = row.readNullable<int>('updated_at');
      // Without the original created_at the event cannot be ordered against
      // relay data, so such rows are dropped.
      if (updatedAt == null || updatedAt <= 0) continue;
      var content = row.readNullable<String>('raw_content_json');
      if (content == null || content.isEmpty) {
        final json = <String, dynamic>{};
        for (final field in const [
          'name',
          'display_name',
          'picture',
          'banner',
          'website',
          'about',
          'nip05',
          'lud16',
          'lud06',
        ]) {
          final value = row.readNullable<String>(field);
          if (value != null) json[field] = value;
        }
        content = jsonEncode(json);
      }
      await _insertProjectedEvent(
        Nip01Event(
          pubKey: row.read<String>('pub_key'),
          kind: Metadata.kKind,
          tags: _decodeTagList(row.readNullable<String>('tags_json')),
          content: content,
          createdAt: updatedAt,
        ),
        sources: _decodeStringList(row.readNullable<String>('sources_json')),
      );
    }
    await customStatement('DROP TABLE metadatas');
  }

  /// Copies rows of the pre-v6 `contact_lists` table into the events table as
  /// projected kind-3 events (unsigned, `sig` stays null).
  Future<void> _migrateLegacyContactLists() async {
    if (!await _legacyTableExists('contact_lists')) return;
    final rows = await customSelect('SELECT * FROM contact_lists').get();
    for (final row in rows) {
      final createdAt = row.read<int>('created_at');
      if (createdAt <= 0) continue;
      final contactList = ContactList(
        pubKey: row.read<String>('pub_key'),
        contacts: _decodeStringList(row.readNullable<String>('contacts_json')),
      )
        ..contactRelays =
            _decodeStringList(row.readNullable<String>('contact_relays_json'))
        ..petnames = _decodeStringList(row.readNullable<String>('petnames_json'))
        ..followedTags =
            _decodeStringList(row.readNullable<String>('followed_tags_json'))
        ..followedCommunities = _decodeStringList(
            row.readNullable<String>('followed_communities_json'))
        ..followedEvents =
            _decodeStringList(row.readNullable<String>('followed_events_json'))
        ..createdAt = createdAt;
      await _insertProjectedEvent(
        contactList.toEvent(),
        sources: _decodeStringList(row.readNullable<String>('sources_json')),
      );
    }
    await customStatement('DROP TABLE contact_lists');
  }

  Future<bool> _legacyTableExists(String name) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _insertProjectedEvent(
    Nip01Event event, {
    required List<String> sources,
  }) async {
    await into(events).insert(
      EventsCompanion.insert(
        id: event.id,
        pubKey: event.pubKey,
        kind: event.kind,
        createdAt: event.createdAt,
        content: event.content,
        sig: Value(event.sig),
        validSig: Value(event.validSig),
        tagsJson: jsonEncode(event.tags),
        sourcesJson: jsonEncode(sources),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  List<String> _decodeStringList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(json) as List);
    } catch (_) {
      return [];
    }
  }

  List<List<String>> _decodeTagList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List)
          .map((tag) => List<String>.from(tag as List))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static QueryExecutor _openConnection(String dbName) {
    return driftDatabase(
      name: dbName,
      native: DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
