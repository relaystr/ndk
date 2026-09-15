import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_drift/ndk_drift.dart';

/// Opens a database seeded with the pre-v6 schema (dedicated metadatas and
/// contact_lists tables) so that opening it triggers the v5 -> v6 migration.
///
/// [version] seeds an older schema instead: below 5 the delivery tables do not
/// exist yet, and the migration has to create them rather than alter them.
NdkCacheDatabase openV5Database({
  List<String> metadataInserts = const [],
  List<String> contactListInserts = const [],
  int version = 5,
}) {
  return NdkCacheDatabase.forTesting(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('''
          CREATE TABLE events (
            id TEXT NOT NULL PRIMARY KEY,
            pub_key TEXT NOT NULL,
            kind INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            content TEXT NOT NULL,
            sig TEXT,
            valid_sig INTEGER,
            tags_json TEXT NOT NULL,
            sources_json TEXT NOT NULL
          );
        ''');
        db.execute('''
          CREATE TABLE metadatas (
            pub_key TEXT NOT NULL PRIMARY KEY,
            name TEXT,
            display_name TEXT,
            picture TEXT,
            banner TEXT,
            website TEXT,
            about TEXT,
            nip05 TEXT,
            lud16 TEXT,
            lud06 TEXT,
            updated_at INTEGER,
            refreshed_timestamp INTEGER,
            sources_json TEXT NOT NULL,
            tags_json TEXT NOT NULL DEFAULT '[]',
            raw_content_json TEXT
          );
        ''');
        db.execute('''
          CREATE TABLE contact_lists (
            pub_key TEXT NOT NULL PRIMARY KEY,
            contacts_json TEXT NOT NULL,
            contact_relays_json TEXT NOT NULL,
            petnames_json TEXT NOT NULL,
            followed_tags_json TEXT NOT NULL,
            followed_communities_json TEXT NOT NULL,
            followed_events_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            loaded_timestamp INTEGER,
            sources_json TEXT NOT NULL
          );
        ''');
        // Present in every real v5 database; DriftCacheManager touches them
        // on construction.
        db.execute('''
          CREATE TABLE wallets (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            supported_units_json TEXT NOT NULL,
            metadata_json TEXT NOT NULL
          );
        ''');
        db.execute('''
          CREATE TABLE key_values (
            key TEXT NOT NULL PRIMARY KEY,
            value TEXT
          );
        ''');
        if (version >= 5) {
          db.execute('''
            CREATE TABLE relay_delivery_targets_table (
              event_id TEXT NOT NULL,
              relay_url TEXT NOT NULL,
              reason TEXT NOT NULL,
              state TEXT NOT NULL,
              attempt_count INTEGER NOT NULL DEFAULT 0,
              last_attempt_at INTEGER,
              next_retry_at INTEGER,
              last_error TEXT,
              last_ok_message TEXT,
              PRIMARY KEY (event_id, relay_url)
            );
          ''');
        }
        for (final statement in metadataInserts) {
          db.execute(statement);
        }
        for (final statement in contactListInserts) {
          db.execute(statement);
        }
        db.execute('PRAGMA user_version = $version;');
      },
    ),
  );
}

void main() {
  const alice = 'alicePubKey';
  const bob = 'bobPubKey';

  test('v5 -> v6 migrates legacy metadata rows into events', () async {
    final db = openV5Database(
      metadataInserts: [
        '''
      INSERT INTO metadatas
        (pub_key, name, display_name, picture, about, updated_at,
         sources_json, tags_json, raw_content_json)
      VALUES
        ('$alice', 'alice', 'Alice', 'https://pic', 'hi', 1700000000,
         '["wss://relay1"]', '[]',
         '{"name":"alice","display_name":"Alice","picture":"https://pic","about":"hi"}');
      ''',
      ],
    );
    final cacheManager = DriftCacheManager(db);

    final metadata = await cacheManager.loadMetadata(alice);
    expect(metadata, isNotNull);
    expect(metadata!.name, 'alice');
    expect(metadata.displayName, 'Alice');
    expect(metadata.picture, 'https://pic');
    expect(metadata.about, 'hi');
    expect(metadata.updatedAt, 1700000000);

    await db.close();
  });

  test(
    'v5 -> v6 migrates legacy metadata without raw content from columns',
    () async {
      final db = openV5Database(
        metadataInserts: [
          '''
      INSERT INTO metadatas
        (pub_key, name, nip05, updated_at, sources_json, tags_json)
      VALUES
        ('$bob', 'bob', 'bob@example.com', 1700000001, '[]', '[]');
      ''',
        ],
      );
      final cacheManager = DriftCacheManager(db);

      final metadata = await cacheManager.loadMetadata(bob);
      expect(metadata, isNotNull);
      expect(metadata!.name, 'bob');
      expect(metadata.nip05, 'bob@example.com');

      await db.close();
    },
  );

  test('v5 -> v6 migrates legacy contact lists into events', () async {
    final db = openV5Database(
      contactListInserts: [
        '''
      INSERT INTO contact_lists
        (pub_key, contacts_json, contact_relays_json, petnames_json,
         followed_tags_json, followed_communities_json, followed_events_json,
         created_at, sources_json)
      VALUES
        ('$alice', '["$bob"]', '["wss://relay1"]', '["bobby"]',
         '["nostr"]', '[]', '[]', 1700000000, '["wss://relay1"]');
      ''',
      ],
    );
    final cacheManager = DriftCacheManager(db);

    final contactList = await cacheManager.loadContactList(alice);
    expect(contactList, isNotNull);
    expect(contactList!.contacts, [bob]);
    expect(contactList.contactRelays, ['wss://relay1']);
    expect(contactList.petnames, ['bobby']);
    expect(contactList.followedTags, ['nostr']);
    expect(contactList.createdAt, 1700000000);

    await db.close();
  });

  test('v5 -> v6 drops the legacy tables after copying', () async {
    final db = openV5Database();
    // Force the migration to run before inspecting sqlite_master.
    await db.customSelect('SELECT 1').get();

    final legacyTables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('metadatas', 'contact_lists')",
        )
        .get();
    expect(legacyTables, isEmpty);

    await db.close();
  });

  test('newer signed event wins over a projected legacy row', () async {
    final db = openV5Database(
      metadataInserts: [
        '''
      INSERT INTO metadatas
        (pub_key, name, updated_at, sources_json, tags_json, raw_content_json)
      VALUES
        ('$alice', 'old-name', 1700000000, '[]', '[]', '{"name":"old-name"}');
      ''',
      ],
    );
    final cacheManager = DriftCacheManager(db);

    await cacheManager.saveEvent(
      Nip01Event(
        pubKey: alice,
        kind: Metadata.kKind,
        tags: [],
        content: '{"name":"new-name"}',
        createdAt: 1700000500,
      ),
    );

    final metadata = await cacheManager.loadMetadata(alice);
    expect(metadata!.name, 'new-name');

    await db.close();
  });

  test('legacy rows without a usable timestamp are skipped', () async {
    final db = openV5Database(
      metadataInserts: [
        '''
      INSERT INTO metadatas (pub_key, name, sources_json, tags_json)
      VALUES ('$alice', 'no-timestamp', '[]', '[]');
      ''',
      ],
    );
    final cacheManager = DriftCacheManager(db);

    expect(await cacheManager.loadMetadata(alice), isNull);

    await db.close();
  });

  /// A database older than the delivery tables has them created from today's
  /// definition, auth_canonical included, so the v7 step must not add it again.
  test(
    'v4 -> latest creates the delivery tables instead of altering them',
    () async {
      final db = openV5Database(version: 4);
      final cacheManager = DriftCacheManager(db);

      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-1',
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
          authCanonical: 'require:alicePubKey',
        ),
      );

      final targets = await cacheManager.loadRelayDeliveryTargets(
        eventId: 'event-1',
      );
      expect(targets.single.authCanonical, 'require:alicePubKey');

      await db.close();
    },
  );
}
