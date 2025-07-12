# Sembast Cache Manager

A Sembast-based cache manager specifically designed for the NDK (Nostr Development Kit) library. Provides persistent storage for Nostr protocol data including events, relay information, user profiles, and network responses.

## Features

- **Persistent Caching**: Uses Sembast database for reliable local storage
- **TTL Support**: Configurable time-to-live for cached entries
- **NDK Integration**: Implements NDK's CacheManager interface
- **Multiple Data Types**: Supports events, user profiles, relay lists, and NIP-05 data
- **Background Cleanup**: Automatic expiration management
- **Performance Optimized**: Efficient querying and deduplication

## Getting started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  sembast_cache_manager: ^1.0.0
  ndk: ^0.4.0
  sembast: ^3.8.5+1
```

Then run:
```bash
dart pub get
```

## Usage

### Basic Setup

```dart
import 'package:sembast_cache_manager/sembast_cache_manager.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:ndk/ndk.dart';

// Initialize Sembast database
final database = await databaseFactoryIo.openDatabase('cache.db');

// Create cache manager
final cacheManager = SembastCacheManager(database);

// Configure NDK with cache
final ndkConfig = NdkConfig(
  cache: cacheManager,
  eventSigner: eventSigner,
  eventVerifier: eventVerifier,
);

final ndk = Ndk(ndkConfig);
```

### Cache Operations

```dart
// Save and load events
await cacheManager.saveEvent(event);
final cachedEvent = await cacheManager.loadEvent(eventId);

// Save and load user metadata
await cacheManager.saveUserMetadata(metadata);
final userMeta = await cacheManager.loadUserMetadata(pubkey);

// Query events with filters
final events = await cacheManager.loadEvents(
  filter: NostrFilter(kinds: [1], limit: 10)
);

// NIP-05 verification cache
await cacheManager.saveNip05(nip05);
final verification = await cacheManager.loadNip05(internetIdentifier);
```

### Configuration

```dart
final config = CacheConfig(
  eventTtl: Duration(hours: 24),
  profileTtl: Duration(days: 7),
  relayTtl: Duration(hours: 1),
  maxEvents: 10000,
  cleanupInterval: Duration(hours: 1),
);

final cacheManager = SembastCacheManager(database, config: config);
```

## Architecture

The cache manager organizes data into separate Sembast stores:

- **Events Store**: Nostr events indexed by event ID
- **Profiles Store**: User metadata indexed by pubkey
- **Relays Store**: Relay information indexed by URL
- **NIP-05 Store**: Identity verification data

Each cached entry includes:
- Original data
- Timestamp for TTL calculation
- Metadata for filtering and querying

## Additional information

- **Repository**: [GitHub](https://github.com/nogringo/sembast-cache-manager)
- **Issues**: Report bugs and feature requests on GitHub
- **NDK Compatibility**: Designed for NDK v0.4.0+
- **License**: MIT

For more examples, see the `/example` folder in the repository.