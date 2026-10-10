# Architecture Decision Record: Local-first reads

Title: Local-first reads - return format for reads that render without waiting on the network

## status

proposed

Updated on 2026-09-30

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

The idea is to return a stream of all dedublicated events from the request, combined with limited metadata like the origin/source of the event (cache, relay x). However only the first event with the metadata available at the time is emitted, no updates its fire once (per event).
The proposal includes a second api to get the full metadata at any given time for an event.




current dm
```dart
class NdkResponse {
  /// The unique identifier for the request that generated this response.
  String requestId;

  /// A stream of [Nip01Event] objects returned by the request.
  ///
  /// This stream can be listened to for real-time processing of events
  /// as they arrive from the nostr request.
  final Stream<Nip01Event> stream;

  /// A future that resolves to a list of all [Nip01Event] objects
  /// once the request is complete (EOSE rcv).
  Future<List<Nip01Event>> get future => stream.toList();

  /// Creates a new [NdkResponse] instance.
  NdkResponse(this.requestId, this.stream);
}
```


option A
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

option B (combined)
```dart
class NdkResponse {
  /// The unique identifier for the request that generated this response.
  String requestId;


  final NdkDataResponse2 data;

  Future<List<Nip01Event>> get future => data.stream.toList();

}
```

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
  final Set<ResultOrigin> metdatada;
}

abstract class ResultOrigin { 
    // tbd shared metdatdata
 }

 class CacheHit implements ResultOrigin{
    /// tbd cache metadata
 }


 class RelayHit implements ResultOrigin{
    /// tbd relay metadata
    /// acc used, time to first result tbd
 }



```

## Consequences
Is a breaking change as the query API changes. 
Could be mitigated with the help of https://github.com/flutter/flutter/blob/master/docs/contributing/Data-driven-Fixes.md (preferred)
or https://pub.dev/packages/codemod 
Especially important for external projects depending on NDK
Other usecases needed to be refactored to the new pattern

## Alternative proposals

@see local-first-reads.md