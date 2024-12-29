# NDK

## Basic example

This example uses a generic low level nostr request

```dart
import 'package:ndk/ndk.dart';

// Create an instance of Ndk
// It's recommended to keep this instance global as it holds critical application state
final ndk = Ndk(
  // Configure the Ndk instance using NdkConfig
  NdkConfig(
    // Use Bip340EventVerifier for event verification
    // in production RustEventVerifier() is recommended
    eventVerifier: Bip340EventVerifier(),
    // Use in-memory cache for storing Nostr data
    cache: MemCacheManager(),
  ),
);

// Create a query request using the Ndk instance
final response = ndk.requests.query(
  filters: [
    // Define a filter for the query
    Filter(
      // Query for fiatjaf npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6
      authors: [
        '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d'
      ],
      // Query for text note events (kind 1)
      kinds: [Nip01Event.TEXT_NODE_KIND],
      // Limit the results to 10 events
      limit: 10,
    ),
  ],
);
// Process the events as they arrive
await for (final event in response.stream) {
  print(event);
}
```

## breakdown

### initialize

#### 1️⃣ Initialize a global `ndk` object

setup your preferred config/dependencies.

```dart
final ndk = Ndk(
  NdkConfig(
    eventVerifier: RustEventVerifier(),
    cache: MemCacheManager(),

    // optional:
    logLevel: Logger.logLevels.debug,
    bootstrapRelays: ["wss://myrelay.example", "wss://myrelay2.example"],
    ignoreRelays: ['wss://bad.reputation']
    engine: NdkEngine.JIT,
    defaultQueryTimeout: Duration(seconds: 10),
    eventOutFilters: [MyEventFilter()],
  ),
);
```

$~~~~~~~~~~~$

#### 2️⃣ Usecase

Use a prebuilt ndk usecase (contact list in this case)

```dart
final ContactList? response = await ndk.follows.getContactList('3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d');
```

#### 3️⃣ read response

depending on the usecase entity or a `NdkResponse` is returned

```dart
// read entity
print(response)
// read NdkResponse
final response_stream = ndkResponse.stream;
final response_future = ndkResponse.future;
```

## imports

`import 'package:ndk/ndk.dart';` \
 contains everything exposed by ndk.\
If you want to reuse ndk entities you can use them like this:

```dart
import 'package:ndk/entities.dart' as ndk_entities;

final ndk_entities.Nip01Event myEvent = ndk_entities.Nip01Event(...);
```

other imports:

```dart
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';
import 'package:ndk_amber/ndk_amber.dart';
```

## tip: how to keep the ndk obj global

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

  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: cache,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});
```

## more examples

- [Nostr wallet Connect](https://github.com/relaystr/ndk/tree/master/packages/ndk/example/nwc)
- [Zaps](https://github.com/relaystr/ndk/tree/master/packages/ndk/example/zaps)
- [example folder github](https://github.com/relaystr/ndk/tree/master/packages/ndk/example)
- [example app](https://github.com/relaystr/ndk/tree/master/packages/sample-app)
- [yana](https://github.com/frnandu/yana)
- [camelus](https://github.com/leo-lox/camelus)
