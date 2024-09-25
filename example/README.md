# NDK

## Basic example

```dart
  // Create an instance of Ndk
  // It's recommended to keep this instance global as it holds critical application state
  Ndk ndk = Ndk(
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
  NdkResponse response = ndk.requests.query(
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

```dart
  Ndk ndk = Ndk(
    NdkConfig(
      eventVerifier: RustEventVerifier(),
      cache: MemCacheManager(),
    ),
  );
```

**Available configs:**

eventVerifier: Bip340EventVerifier(), RustEventVerifier(), \
cache: MemCacheManager(), \
bootstrapRelays: ['wss://myrelay.example'], \
engine: NdkEngine.RELAY_SETS, NdkEngine.JIT \
eventSigner: Bip340EventSigner('nsec1...', 'npub1...'), \
ignoreRelays: ['wss://bad.reputation']

#### 2️⃣ Usecase

Use a prebuilt ndk usecase (contact list in this case)

```dart
 final ContactList? response = await ndk.follows.getContactList('npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6');
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
