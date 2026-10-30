import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_drift/ndk_drift.dart';

void main() {
  test('v8 -> v9 rebuilds nip05s keyed by identifier', () async {
    final db = NdkCacheDatabase.forTesting(
      NativeDatabase.memory(
        setup: (db) {
          db.execute('''
            CREATE TABLE nip05s (
              pub_key TEXT NOT NULL PRIMARY KEY,
              nip05 TEXT NOT NULL,
              valid INTEGER NOT NULL,
              network_fetch_time INTEGER,
              relays_json TEXT NOT NULL
            );
          ''');
          db.execute(
            "INSERT INTO nip05s VALUES ('pubkey', 'alice@a.com', 0, 1, '[]');",
          );
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
          db.execute('PRAGMA user_version = 8;');
        },
      ),
    );
    final cacheManager = DriftCacheManager(db);

    expect(await cacheManager.loadNip05('alice@a.com'), isNull);

    for (final identifier in ['alice@a.com', 'alice@b.com']) {
      await cacheManager.saveNip05(
        Nip05(pubKey: 'pubkey', identifier: identifier, valid: true),
      );
    }
    await cacheManager.saveNip05(
      Nip05(pubKey: null, identifier: 'ghost@a.com'),
    );

    expect((await cacheManager.loadNip05('alice@a.com'))?.pubKey, 'pubkey');
    expect((await cacheManager.loadNip05('alice@b.com'))?.pubKey, 'pubkey');
    expect(await cacheManager.loadNip05('ghost@a.com'), isNotNull);

    await db.close();
  });
}
