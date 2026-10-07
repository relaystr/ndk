import 'package:sqlite3/sqlite3.dart';

import 'migrations/v1.dart';

// Append only: _migrations[i] upgrades user_version i to i + 1, so a shipped
// migration must never be edited.
const _migrations = [v1];
final _schemaVersion = _migrations.length;

/// Brings [db] to the current schema, tracked with `PRAGMA user_version`.
void migrate(Database db) {
  final version = db.userVersion;
  if (version > _schemaVersion) {
    throw StateError(
      'Database schema version $version is newer than $_schemaVersion, '
      'it was written by a newer ndk_sqlite3',
    );
  }
  if (version == _schemaVersion) return;

  db.execute('BEGIN IMMEDIATE');
  try {
    for (final migration in _migrations.skip(version)) {
      db.execute(migration);
    }
    db.userVersion = _schemaVersion;
    db.execute('COMMIT');
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}
