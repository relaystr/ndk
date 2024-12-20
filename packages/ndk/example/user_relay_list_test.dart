// ignore_for_file: avoid_print

import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

void main() async {
  test('user relay list', () async {
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

    // Use a prebuilt ndk usecase (userRelayLists in this case)
    final response = await ndk.userRelayLists.getSingleUserRelayList(
        '30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177');

    // read entity
    print("RELAYS:");
    print(response?.relays.length ?? "no relays");
    print(response!.toNip65());

    expect(response, isNotNull, reason: 'response is Null');
    expect(response.relays.length, greaterThan(0),
        reason: 'relay list is empty');
  });
}
