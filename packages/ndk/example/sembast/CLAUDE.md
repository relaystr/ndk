# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Sembast-based cache manager specifically designed for the NDK (Nostr Development Kit) library. The cache manager provides persistent storage for Nostr protocol data including events, relay information, user profiles, and network responses.

## Development Setup

```bash
# Get dependencies
dart pub get

# Run tests
dart test

# Analyze code
dart analyze

# Format code
dart format .

# Run example
dart run example/main.dart
```

## Architecture Overview

The cache manager implements a pluggable cache interface for NDK with the following key components:

### Core Components
- **NdkCacheManager**: Main cache interface implementation
- **SembastStore**: Wrapper around Sembast database operations
- **CacheEntry**: Data structure with TTL and metadata
- **CacheConfig**: Configuration for TTL, sizes, and cleanup policies

### Data Types to Cache
- **Events**: Nostr events with filters and metadata
- **User Profiles**: NIP-05 addresses and profile data
- **Relay Information**: Relay URLs, capabilities, and status
- **Network Responses**: Raw API responses for performance
- **Subscriptions**: Active subscription states

## Sembast Implementation Patterns

### Store Organization
```dart
// Separate stores for different data types
var eventStore = stringMapStoreFactory.store('events');
var profileStore = stringMapStoreFactory.store('profiles');
var relayStore = stringMapStoreFactory.store('relays');
```

### Key Strategies
- Events: Use event ID as key
- Profiles: Use pubkey as key  
- Relays: Use relay URL as key
- Subscriptions: Use subscription ID as key

### Data Structure
```dart
{
  'data': actualData,
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'ttl': 3600000, // TTL in milliseconds
  'metadata': {...}
}
```

### Expiration Management
- Implement background cleanup for expired entries
- Use compound queries to find expired records
- Support different TTL policies per data type

## NDK Cache Manager Interface

The cache manager must implement NDK's `CacheManager` abstract class. Based on existing implementations:

### Required Interface
```dart
abstract class CacheManager {
  // Core cache operations
  Future<void> saveEvent(Nip01Event event);
  Future<Nip01Event?> loadEvent(String eventId);
  Future<List<Nip01Event>> loadEvents({required NostrFilter filter});
  
  // User metadata operations
  Future<void> saveUserMetadata(UserMetadata metadata);
  Future<UserMetadata?> loadUserMetadata(String pubkey);
  
  // Contact list operations
  Future<void> saveUserContactList(UserContactList contactList);
  Future<UserContactList?> loadUserContactList(String pubkey);
  
  // Relay operations
  Future<void> saveUserRelayList(UserRelayList relayList);
  Future<UserRelayList?> loadUserRelayList(String pubkey);
  
  // NIP-05 verification
  Future<void> saveNip05(Nip05 nip05);
  Future<Nip05?> loadNip05(String internetIdentifier);
  
  // Cleanup operations
  Future<void> removeAllEvents();
  Future<void> removeEvent(String eventId);
}
```

### Integration Pattern
```dart
final ndkConfig = NdkConfig(
  cache: SembastCacheManager(database), // Your implementation
  eventSigner: eventSigner,
  eventVerifier: eventVerifier,
);
final ndk = Ndk(ndkConfig);
```

### Key Implementation Notes
- NDK leverages cache extensively to avoid redundant operations
- Cache is checked before signature verification for performance
- Events are deduplicated using the cache
- Supports complex NostrFilter queries for event retrieval
- Must handle async operations efficiently