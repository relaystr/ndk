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
  int get schemaVersion => 1;

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
