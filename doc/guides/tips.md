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

## apps using ndk

- [example app](https://github.com/relaystr/ndk/tree/master/packages/sample-app)
- [yana](https://github.com/frnandu/yana)
- [camelus](https://github.com/leo-lox/camelus)
- [zapstore](https://github.com/zapstore)
