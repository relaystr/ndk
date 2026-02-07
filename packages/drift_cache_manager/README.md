# Drift Cache Manager

A Drift-based cache manager for the NDK (Nostr Development Kit) library, providing persistent SQLite storage for Nostr protocol data.

## Features

- **Cross-Platform**: Works on Android, iOS, macOS, Windows, Linux, and Web
- **SQLite Storage**: Uses Drift for reliable SQLite database operations
- **NDK Integration**: Implements NDK's CacheManager interface
- **Debug/Release Separation**: Automatically uses separate databases for debug and release modes
- **Full Data Support**: Caches events, metadata, contact lists, relay lists, relay sets, NIP-05, and filter ranges

## Supported Platforms

| Platform | Storage |
|----------|---------|
| Android | SQLite |
| iOS | SQLite |
| macOS | SQLite |
| Windows | SQLite |
| Linux | SQLite |
| Web | IndexedDB (via sql.js) |

## Getting Started

```bash
flutter pub add drift_cache_manager
```

### Web Setup

For web support, download these files to your `web/` folder:
- `sqlite3.wasm` from [sql.js releases](https://github.com/simolus3/sqlite3.dart/releases)
- `drift_worker.js` from [drift releases](https://github.com/simolus3/drift/releases)

See [Drift web prerequisites](https://drift.simonbinder.eu/platforms/web/#prerequisites) for details.

## Usage

### Basic Setup

```dart
import 'package:drift_cache_manager/drift_cache_manager.dart';
import 'package:ndk/ndk.dart';

// Create cache manager (uses 'ndk_cache_debug' in debug, 'ndk_cache' in release)
final cacheManager = await DriftCacheManager.create();

// Or with a custom database name
final cacheManager = await DriftCacheManager.create(dbName: 'my_app_cache');

// Configure NDK with cache
final ndk = Ndk(
  NdkConfig(
    cache: cacheManager,
  ),
);
```

## Architecture

The cache manager uses Drift tables for each data type:

| Table | Primary Key | Description |
|-------|-------------|-------------|
| Events | id | Nostr events with tags stored as JSON |
| Metadatas | pubKey | User profile metadata |
| ContactLists | pubKey | User contact lists |
| UserRelayLists | pubKey | User relay configurations |
| RelaySets | id | Relay set configurations |
| Nip05s | pubKey | NIP-05 verification data |
| FilterFetchedRangeRecords | key | Query range tracking |
