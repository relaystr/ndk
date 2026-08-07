# Architecture Decision Record: Local-first reads

Title: Local-first reads - return format for reads that render without waiting on the network

## status

proposed

Updated on 05-08-2026

## contributors

- Main contributor(s): nogringo

- Reviewer(s): frnandu, 1leo

- Final decision made by: frnandu, 1leo, nogringo

## Context and Problem Statement

Reads must render immediately from what is known locally, and refine when relays answer. The
current reads do neither: `getSingleNip51List(kind, forceRefresh:)` returns the cache and never
refreshes it, or skips the cache and blocks on the network.

A read must also never let one state degrade into another. "not known yet" and "cannot be read"
must not look like "does not exist", because that is what an app acts on to create the missing
data, and for a replaceable event that overwrites what was already there.

## Main Proposal

```dart
class NdkDataResponse<T> {
  /// Emits a `cache` value first, then every newer `relays` value as it
  /// arrives, even when it holds the same value as the cache.
  /// Closes after EOSE or timeout.
  final Stream<NdkValue<T>> stream;

  /// The relay-confirmed value, so the last emitted one.
  Future<T> get future;
}

class NdkValue<T> {
  final T value;
  final DataOrigin origin;
}

enum DataOrigin { cache, relays }
```

A `cache` value is always emitted first, even when nothing is cached.

`stream` is backed by a `BehaviorSubject`, so `stream` and `future` can both be consumed and a
listener attached late still receives the latest value.

`NdkValue` may later carry `createdAt`, `receivedAt` and `hasPendingWrites`. Only metadata that
makes sense for every read belongs there, anything specific to one read belongs in `T`.

When the value can be absent, `T` is nullable and the origin disambiguates `null`:

| emission | meaning |
| --- | --- |
| `(value, cache)` | local value, not confirmed |
| `(null, cache)` | nothing local yet, still loading |
| `(value, relays)` | confirmed value |
| `(null, relays)` | confirmed: nothing exists |

Two cases are reported as stream errors, never as `null`, since `(null, relays)` is what an
app acts on to create the missing data:

- the value exists but cannot be read, for instance it cannot be decrypted
- no relay was reachable, so absence cannot be concluded

## First use: private relay list (NIP-37 kind 10013)

```dart
// on Lists, requires a logged in account, no pubkey parameter
NdkDataResponse<List<String>?> getPrivateUserRelays({Duration timeout});
```

An empty list and no list are different answers:

| emission | meaning |
| --- | --- |
| `([], relays)` | the event exists and holds no relay |
| `(null, relays)` | no kind 10013 event exists |
