# Setup

## Install

```yaml
# pubspec.yaml
dependencies:
  ndk: ^0.8.4-dev.1
```

```bash
dart pub add ndk
# or
flutter pub add ndk
```

## Minimum init

```dart
import 'package:ndk/ndk.dart';

final ndk = Ndk(
  NdkConfig(
    eventVerifier: Bip340EventVerifier(), // or RustEventVerifier() for better perf
    cache: MemCacheManager(),             // or SembastCacheManager() for persistence
  ),
);
```

## NdkConfig reference

| Field | Type | Default | Notes |
| ----- | ---- | ------- | ----- |
| `eventVerifier` | `EventVerifier` | **required** | `Bip340EventVerifier` or `RustEventVerifier` |
| `cache` | `CacheManager` | **required** | `MemCacheManager` or `SembastCacheManager` |
| `engine` | `NdkEngine` | `RELAY_SETS` | `RELAY_SETS` (inbox/outbox) or `JIT` |
| `bootstrapRelays` | `List<String>` | DEFAULT_BOOTSTRAP_RELAYS | Connect on start |
| `ignoreRelays` | `List<String>` | `[]` | Skip for inbox/outbox |
| `eventSignerFactory` | `LocalEventSignerFactory` | `Bip340EventSignerFactory()` | Key signing |
| `walletsRepo` | `WalletsRepo?` | `null` | Required for wallet persistence |
| `defaultQueryTimeout` | `Duration` | 5s | Per-query timeout |
| `defaultBroadcastTimeout` | `Duration` | — | Broadcast timeout |
| `logLevel` | `LogLevel` | warning | Logging verbosity |
| `cashuUserSeedphrase` | `CashuUserSeedphrase?` | `null` | Required for Cashu |
| `fetchedRangesEnabled` | `bool` | `false` | Track fetched time ranges per relay |
| `eagerAuth` | `bool` | `false` | AUTH on challenge vs on auth-required |

## Engine modes

```dart
// RELAY_SETS (default) — inbox/outbox model, uses nip65 relay lists
NdkEngine.RELAY_SETS

// JIT — Just-In-Time relay discovery
NdkEngine.JIT
```

## Cache options

```dart
// In-memory (no persistence)
cache: MemCacheManager()

// Sembast (file-based persistence, dart:io only)
cache: SembastCacheManager(path: '/path/to/db')
```

## Cleanup

```dart
// Close all relays/subscriptions before app exit
await ndk.destroy();
```
