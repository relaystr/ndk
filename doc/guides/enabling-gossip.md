---
icon: broadcast
order: 99
---

The simplest way to enable inbox/outbox (gossip) is to use the `JIT` engine, as it does everything automatically.

```dart
  final ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: cache,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
```

For more granular control you can use the `RELAY_SETS` engine.

```dart
NdkEngine.RELAY_SETS,
```

To make use of gossip you need to pass a `RelaySet` to the usecase.

[!ref](/usecases/relay-sets.md)
