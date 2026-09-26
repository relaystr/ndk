# Architecture Decision Record: Local-first reads

Title: Local-first reads - return format for reads that render without waiting on the network

## status

proposed

Updated on 2026-08-17

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

## Scope

This is the return format of typed high-level reads: one read, one value, refined until it is
relay-confirmed. It does not redefine `requestNostrEvent` and `NdkResponse`, and it is not a
lifecycle for long-lived subscriptions.

Per-relay provenance stays out of it: which relays hold an event is a cache concern, already
answered by `CacheManager.addEventSource(s)` and `loadEventSources()`. Read-specific metadata
belongs in `T`, so a read that needs more than the origin declares a `T` that carries it.

## Main Proposal

```dart
class NdkDataResponse<T> {
  /// Emits a `cache` value first, then every newer `relays` value as it
  /// arrives. Closes after EOSE or timeout.
  final Stream<NdkValue<T>> stream;

  /// The last emitted value, relay-confirmed unless the read concludes on cache.
  Future<NdkValue<T>> get future;
}

class NdkValue<T> {
  final T? value;
  final DataOrigin origin;
}

enum DataOrigin { cache, relays }
```

A `cache` value is always emitted first, even when nothing is cached, so `value` is nullable
for every read and the origin disambiguates `null`:

| emission | meaning |
| --- | --- |
| `(value, cache)` | local value, not confirmed |
| `(null, cache)` | nothing local yet, still loading |
| `(value, relays)` | confirmed value |
| `(null, relays)` | confirmed: nothing exists |

"newer" follows NIP-01 replacement ordering, highest `created_at` and ties broken by lowest
`id`, not arrival order. A relay answer that is already superseded is never emitted, so the
last emitted value is the winning one and `future` completes with it.

A relay value equal to the cached one still emits once, because the origin change from `cache`
to `relays` is the confirmation. Relays repeating that same value do not emit again.

A regular event is immutable, so an ID query that hits the cache is already confirmed: `cache`
is terminal there and no relay answer refines it.

`stream` is backed by a `BehaviorSubject`, so `stream` and `future` can both be consumed and a
listener attached late still receives the latest value.

`NdkValue` may later carry `createdAt`, `receivedAt` and `hasPendingWrites`. Only metadata that
makes sense for every read belongs there, anything specific to one read belongs in `T`.

Two cases are reported as stream errors, never as `null`, since `(null, relays)` is what an
app acts on to create the missing data:

- the value exists but cannot be read, for instance it cannot be decrypted
- no relay was reachable, so absence cannot be concluded

`future` completes with the last emission, so it fails with the same errors, and it still carries
a `cache` origin when the timeout hits before any relay answered.

That error channel stays narrow: a `BehaviorSubject` replays only the last value or the last
error, so a non-fatal error would hide a good value from a late listener. One unreachable relay
is not an error while another answers, and an unreadable cache is not terminal.

## First use: private relay list (NIP-37 kind 10013)

```dart
// on Lists, requires a logged in account, no pubkey parameter
NdkDataResponse<List<String>> getPrivateUserRelays({Duration? timeout});
```

An omitted `timeout` uses the NDK default query timeout.

An empty list and no list are different answers:

| emission | meaning |
| --- | --- |
| `([], relays)` | the event exists and holds no relay |
| `(null, relays)` | no kind 10013 event exists |



## Consequences
Is a breaking change as the query API changes. 
Could be mitigated with the help of https://github.com/flutter/flutter/blob/master/docs/contributing/Data-driven-Fixes.md (preferred)
or https://pub.dev/packages/codemod 
Especially important for external projects depending on NDK



## Alternative proposals

Instead of 
```dart
enum DataOrigin { cache, relays }
``` 
use a `Metadata` obj allowing for more flexibility when adding more metadata in the future.
Depending on the use case, we could also include specialized metadata, e.g., for cache access counts or P2P transmission statistics.
Because richer metadata will be slower due to DB access, we should keep the default minimal.


## Final Notes
