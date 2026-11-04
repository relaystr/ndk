# Architecture Decision Record: Local-first reads

Title: Local-first reads - reworks apis with stream API

## status

proposed

Updated on 2026-11-04

## contributors

- Main contributor(s): nogringo

- Reviewer(s): frnandu, 1leo

- Final decision made by: frnandu, 1leo, nogringo

## Context and Problem Statement


A lot of ndk apis are a future, not a stream (e.g. Lists) with the cache logic hidden away (with forceRefresh control flag). 
These apis hide if a request is trusted (from network) or cache.


## Scope

Touching on all apis that only offer futures, starting with lists usecase

## Main Proposal

### (new) Streams 
Return a stream of all dedublicated events from the request, 
combined with limited metadata like the origin/source of the event (cache, relay x). 
However only the first event with the metadata available at the time is emitted, no updates its fire once (per event).
(optional) The proposal includes a second api to get the full metadata at any given time for an event.

### Futures
leave futures as they are for compatability and api simplicity


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
Because futures stay untouched no breaking changes

## Alternative proposals

@see local-first-reads.md