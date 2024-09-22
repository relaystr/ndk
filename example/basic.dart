import 'package:ndk/ndk.dart';

void main(List<String> arguments) async {
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
}
