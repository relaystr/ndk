import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Events,
    Metadatas,
    ContactLists,
    UserRelayLists,
    RelaySets,
    Nip05s,
    FilterFetchedRangeRecords,
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add new columns for metadata tags and rawContent
          await m.addColumn(metadatas, metadatas.tagsJson);
          await m.addColumn(metadatas, metadatas.rawContentJson);
        }
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
      },
    );
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
