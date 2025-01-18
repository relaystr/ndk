---
icon: arrow-up-right
---

[!badge variant="primary" text="low level"]

## Usage Example

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

## When to use

Broadcast schould be used when your usecase has no broadcasting method. \
Signing is done automatically, and you can specify a custom signer just for one broadcast. \
By default the inbox/outbox model is used for broadcasting looking at the event data (e.g. if its a reply) you can also specify specific relays to broadcast to.
