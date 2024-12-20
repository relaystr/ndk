// ignore_for_file: avoid_print

import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

void main() async {
  test('basic', () async {
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

    int eventCount = 0;

    // Process the events as they arrive
    await for (final event in response.stream) {
      print(event);
      eventCount++;
    }

    expect(eventCount, greaterThan(0),
        reason: 'No events were emitted from the stream');
  });
}
