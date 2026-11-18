import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_drift/ndk_drift.dart';

void main() {
  test('v9 -> v10 backfills the visibility state of stored events', () async {
    final pubKey = 'a' * 64;
    Nip01Event event(int kind, int createdAt, [List<List<String>>? tags]) =>
        Nip01Event(
          pubKey: pubKey,
          kind: kind,
          tags: tags ?? [],
          content: '',
          createdAt: createdAt,
        );
    final note = event(1, 100, [
      ['t', 'Nostr'],
    ]);
    final oldProfile = event(0, 100);
    final profile = event(0, 200);
    final deletedNote = event(1, 100);
    final deletion = event(5, 200, [
      ['e', deletedNote.id],
    ]);
    final expiredNote = event(1, 100, [
      ['expiration', '1'],
    ]);

    final db = NdkCacheDatabase.forTesting(
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
          for (final e in [
            note,
            oldProfile,
            profile,
            deletedNote,
            deletion,
            expiredNote,
          ]) {
            db.execute(
              "INSERT INTO events VALUES (?, ?, ?, ?, '', NULL, NULL, ?, '[]')",
              [e.id, e.pubKey, e.kind, e.createdAt, jsonEncode(e.tags)],
            );
          }
          // DriftCacheManager touches them on construction
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
          db.execute('PRAGMA user_version = 9;');
        },
      ),
    );
    final cacheManager = DriftCacheManager(db);

    expect(
      (await cacheManager.loadEvents(pubKeys: [pubKey])).map((e) => e.id),
      unorderedEquals([note.id, profile.id, deletion.id]),
    );
    expect(
      (await cacheManager.loadEvents(
        tags: {
          't': ['nostr'],
        },
      )).map((e) => e.id),
      [note.id],
    );
    expect(
      {
        for (final hidden in await cacheManager.loadHiddenEvents())
          hidden.event.id: hidden.reasons,
      },
      {
        oldProfile.id: {HiddenEventReason.superseded},
        deletedNote.id: {HiddenEventReason.deleted},
        expiredNote.id: {HiddenEventReason.expired},
      },
    );

    await db.close();
  });
}
