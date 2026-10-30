## 0.1.1-dev.1

> Note: This release has breaking changes.

 - **FIX**(sqlite3): use Nip05.identifier in the local storage extensions.
 - **FIX**(sqlite3): use a local copy of the storage extensions moved out of ndk.
 - **FEAT**: add CacheManager.loadEventIdsWithCreatedAt for the NIP-77 local set (fixes #885).
 - **BREAKING** **FEAT**(nip05): key the NIP-05 cache by identifier and persist not found (fixes #838, fixes #936).

## 0.1.1-dev.0

 - **REFACTOR**(sqlite3): move schema into a migrations folder.
 - **PERF**(sqlite3): let tag filters drive single-kind queries.
 - **FIX**(sqlite3): wait for locks held by other connections.
 - **FEAT**(sqlite3): add ndk_sqlite3, a pure Dart SQLite cache manager.

## 0.1.0

 - Initial release.
