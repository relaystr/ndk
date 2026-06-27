---
icon: arrow-up-right
---

[!badge variant="primary" text="low level"]

## Example

```dart
  final myBroadcast = ndk.broadcast.broadcast(
      nostrEvent: Nip01Event(
        pubKey:
            '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d',
        kind: 1,
        tags: [],
        content: 'Hello, World!',
      ),
    );
    final result = await myBroadcast.broadcastDoneFuture;
    for (final relayResponse in result) {
      print(
          "broadcast on ${relayResponse.relayUrl}:  ${relayResponse.broadcastSuccessful}");
    }

```

!!!
You might encounter a warning about missing `nip65` data. You can ignore this warning to use NDK with your specified/default relays.\
If you want to use the outbox model, check out the [enabling gossip](/guides/enabling-gossip.md#broadcast-using-outbox) guide (recommended).
!!!

## When to use

Broadcast should be used when your use case has no broadcasting method. \
Signing is done automatically, and you can specify a custom signer just for one broadcast. \
By default, the inbox/outbox model is used for broadcasting looking at the event data (e.g. if it's a reply) you can also specify specific relays to broadcast to.

## Local-first behavior

NDK keeps delivery state for locally created events in the configured cache backend.

That means:

- an event may be visible locally before every relay accepts it
- pending delivery can survive app restarts when the cache backend is persistent
- retries can continue later when relays are reachable again
- replaceable events only keep retrying the newest visible version

With `MemCacheManager`, this state exists while the process is alive. With a persistent `CacheManager`, it also survives restarts.

## Retry behavior

Background delivery retries are not identical for every event.

Current behavior includes:

- replaceable events retry as latest-state-only delivery
- ephemeral events are not kept for retry
- some control-style events can use faster retry behavior
- relay responses classified as permanent failure stop retry for that relay target
- relay responses classified as transient failure remain retryable

## Delivery policy

NDK uses an internal `DeliveryPolicy` for local-first broadcast retry handling.

Current policy selection is automatic:

- ephemeral events use `doNotRetry`
- deletion events use `highPriorityControl`
- replaceable and addressable events use `latestStateOnly`
- other events use `persistentEventual`

This policy is currently **not configurable** through `ndk.broadcast.broadcast()`,
`NdkConfig`, or a per-event override.

That means:

- you cannot choose a custom retry/backoff profile for one broadcast
- you cannot inject your own delivery policy classifier
- the practical way to influence policy today is through the event kind you publish

Examples:

- `kind:5` deletions get faster control-style retries
- replaceable kinds only keep retrying the newest visible version
- ephemeral kinds are not persisted for background retry

## Relay targeting

Broadcast targeting can include more than author outbox relays.

Depending on the event, NDK may target:

- explicit relays
- author write relays
- inbox/read relays needed for replies and reactions

Delivery targets are tracked separately from source provenance.
