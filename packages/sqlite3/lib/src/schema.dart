import 'package:sqlite3/sqlite3.dart';

const _schemaVersion = 1;

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
    if (version < 1) db.execute(_v1);
    db.userVersion = _schemaVersion;
    db.execute('COMMIT');
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}

// conflict_key and expiration are derived at insert time so that visibility
// and eviction run in SQL. event_tags and deletion_targets follow their event
// through ON DELETE CASCADE, the other event sidecars can exist before it.
const _v1 = '''
CREATE TABLE events (
  id TEXT NOT NULL PRIMARY KEY,
  pub_key TEXT NOT NULL,
  kind INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  content TEXT NOT NULL,
  tags TEXT NOT NULL,
  sig TEXT,
  valid_sig INTEGER,
  sources TEXT NOT NULL,
  conflict_key TEXT,
  expiration INTEGER
) STRICT;
CREATE INDEX events_pub_key_kind_created_at ON events (pub_key, kind, created_at);
CREATE INDEX events_kind_created_at ON events (kind, created_at);
CREATE INDEX events_created_at ON events (created_at);
CREATE INDEX events_conflict_key ON events (conflict_key, created_at)
  WHERE conflict_key IS NOT NULL;
CREATE INDEX events_expiration ON events (expiration)
  WHERE expiration IS NOT NULL;

CREATE TABLE event_tags (
  event_id TEXT NOT NULL REFERENCES events (id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  value TEXT
) STRICT;
CREATE INDEX event_tags_name_value ON event_tags (name, value, event_id);
CREATE INDEX event_tags_event_id ON event_tags (event_id);

CREATE TABLE deletion_targets (
  deletion_id TEXT NOT NULL REFERENCES events (id) ON DELETE CASCADE,
  pub_key TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  event_id TEXT,
  conflict_key TEXT
) STRICT;
CREATE INDEX deletion_targets_event_id ON deletion_targets (event_id, pub_key)
  WHERE event_id IS NOT NULL;
CREATE INDEX deletion_targets_conflict_key
  ON deletion_targets (conflict_key, pub_key, created_at)
  WHERE conflict_key IS NOT NULL;
CREATE INDEX deletion_targets_deletion_id ON deletion_targets (deletion_id);

CREATE TABLE event_sources (
  event_id TEXT NOT NULL,
  relay_url TEXT NOT NULL,
  PRIMARY KEY (event_id, relay_url)
) STRICT, WITHOUT ROWID;

CREATE TABLE event_delivery_records (
  event_id TEXT NOT NULL PRIMARY KEY,
  status TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  completed_at INTEGER,
  record TEXT NOT NULL
) STRICT;
CREATE INDEX event_delivery_records_status ON event_delivery_records (status);

CREATE TABLE relay_delivery_targets (
  event_id TEXT NOT NULL,
  relay_url TEXT NOT NULL,
  state TEXT NOT NULL,
  next_retry_at INTEGER,
  target TEXT NOT NULL,
  PRIMARY KEY (event_id, relay_url)
) STRICT;
CREATE INDEX relay_delivery_targets_state ON relay_delivery_targets (state);

CREATE TABLE decrypted_payloads (
  event_id TEXT NOT NULL,
  viewer_pub_key TEXT NOT NULL,
  status TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  record TEXT NOT NULL,
  PRIMARY KEY (event_id, viewer_pub_key)
) STRICT;
CREATE INDEX decrypted_payloads_viewer_pub_key
  ON decrypted_payloads (viewer_pub_key, updated_at);

CREATE TABLE user_relay_lists (
  pub_key TEXT NOT NULL PRIMARY KEY,
  data TEXT NOT NULL
) STRICT;

CREATE TABLE relay_sets (
  id TEXT NOT NULL PRIMARY KEY,
  data TEXT NOT NULL
) STRICT;

CREATE TABLE nip05s (
  pub_key TEXT NOT NULL PRIMARY KEY,
  nip05 TEXT NOT NULL,
  data TEXT NOT NULL
) STRICT;
CREATE INDEX nip05s_nip05 ON nip05s (nip05);

CREATE TABLE filter_fetched_ranges (
  key TEXT NOT NULL PRIMARY KEY,
  filter_hash TEXT NOT NULL,
  relay_url TEXT NOT NULL,
  range_start INTEGER NOT NULL,
  range_end INTEGER NOT NULL
) STRICT;
CREATE INDEX filter_fetched_ranges_filter_hash
  ON filter_fetched_ranges (filter_hash, relay_url);
CREATE INDEX filter_fetched_ranges_relay_url ON filter_fetched_ranges (relay_url);

CREATE TABLE cashu_keysets (
  id TEXT NOT NULL,
  mint_url TEXT NOT NULL,
  data TEXT NOT NULL,
  PRIMARY KEY (id, mint_url)
) STRICT;

CREATE TABLE cashu_proofs (
  y TEXT NOT NULL PRIMARY KEY,
  mint_url TEXT NOT NULL,
  keyset_id TEXT NOT NULL,
  state TEXT NOT NULL,
  amount INTEGER NOT NULL,
  secret TEXT NOT NULL,
  unblinded_sig TEXT NOT NULL
) STRICT;
CREATE INDEX cashu_proofs_mint_url_state ON cashu_proofs (mint_url, state);

CREATE TABLE cashu_mint_infos (
  id TEXT NOT NULL PRIMARY KEY,
  data TEXT NOT NULL
) STRICT;

CREATE TABLE cashu_secret_counters (
  mint_url TEXT NOT NULL,
  keyset_id TEXT NOT NULL,
  counter INTEGER NOT NULL,
  PRIMARY KEY (mint_url, keyset_id)
) STRICT;

CREATE TABLE wallets (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  supported_units TEXT NOT NULL,
  metadata TEXT NOT NULL
) STRICT;

CREATE TABLE wallet_transactions (
  id TEXT NOT NULL,
  wallet_id TEXT NOT NULL,
  change_amount INTEGER NOT NULL,
  unit TEXT NOT NULL,
  type TEXT NOT NULL,
  state TEXT NOT NULL,
  completion_msg TEXT,
  transaction_date INTEGER,
  initiated_date INTEGER,
  metadata TEXT NOT NULL,
  PRIMARY KEY (id, wallet_id)
) STRICT;

CREATE TABLE key_values (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT
) STRICT;
''';
