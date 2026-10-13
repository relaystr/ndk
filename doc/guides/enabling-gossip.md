---
icon: broadcast
order: 99
---

The default `COMBINED` engine does everything automatically: a request that names a `RelaySet` is served by the relay sets engine, and everything else by the `JIT` engine, which resolves relays on the fly from nip65 data. All of it runs over one shared connection pool.

```dart
  final ndkConfig = NdkConfig(
    cache: cache,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
```

If you want only one of the two behaviours for every request, you can pick the engine outright.

```dart
// every request, relay set or not, resolved on the fly from nip65
NdkEngine.JIT,

// every request resolved from the relay set you pass
NdkEngine.RELAY_SETS,
```

To make use of gossip you need to pass a `RelaySet` to the usecase.

[!ref](/usecases/relay-sets.md)

## Broadcast using Outbox

When you use ndk without getting `nip65` data first, you will get a warning like:

```text
broadcast - could not find nip65 data for ${eventToPublish.pubKey}, using DEFAULT_BOOTSTRAP_RELAYS for now.
Please ensure nip65Data exists to use the outbox model => UserRelayLists use case
```

When nip65 data is in the cache ndk picks it up automatically. To populate the cache, you can use the `UserRelayLists` use case.

```dart
await ndk.userRelayLists.getSingleUserRelayList("<pubKey>");
```

You don't have to save the result, it's enough to call the method so the data is in the cache.

### new account

If you are creating a new account, you can use the `UserRelayLists` use case to set the `RelaySet` for the new account.\
The data will be published to the nostr network and saved in the cache.

```dart
await ndk.userRelayLists.setInitialUserRelayList(UserRelayList(
 refreshedTimestamp: 0, // ok to init with 0
 createdAt: 0, // ok to init with 0
 pubKey: "<pubKey>",
 relays: {
      "wss://relay.readonly.example": ReadWriteMarker.readOnly,
      "wss://relay.writeonly.example": ReadWriteMarker.writeOnly,
      "wss://relay.readwrite.example": ReadWriteMarker.readWrite,
 },
))
```
