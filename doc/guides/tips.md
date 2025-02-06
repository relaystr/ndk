---
icon: info
order: 0
---

## how to keep the ndk obj global

If you have a relatively simple app you can initialize ndk in your main method and pass down ndk on the widget tree.\
For more more complex applications we recommend using [riverpod](<[test](https://pub.dev/packages/riverpod)>) or simmilar packages/methods (get_it, singletons etc).

riverpod example:

```dart
import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final EventSigner eventSigner = Bip340EventSigner("privateKey", "publicKey");
  final EventVerifier eventVerifier = RustEventVerifier();
  final CacheManager cache = MemCacheManager();

  final ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: cache,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});
```

## avoid layout shifts

Sometimes, it can make sense to buffer the response from a query and only update the UI periodically.

The package used to achieve this is [rxdart](https://pub.dev/packages/rxdart).

```dart
import 'package:rxdart/rxdart.dart';
import 'package:ndk/ndk.dart';

...

// query
final myquery = ndk.requests.query(
  filters: [
    Filter(
      authors: ['hexPubkey']
      kinds: [Nip01Event.TEXT_NODE_KIND],
      limit: 10,
    ),
  ],
);


myquery.stream
    // rxdart
    .bufferTime(const Duration(milliseconds: 500))
    // if no events are received in 500ms, an empty list is emitted => filter out
    .where((events) => events.isNotEmpty)
    .listen((events) {
    // update UI
    print(events.toString());
});

```
