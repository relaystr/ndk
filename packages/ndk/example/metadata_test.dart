// ignore_for_file: avoid_print

import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

void main() async {
  test('metadata', () async {
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

    // Use a prebuilt ndk usecase (metadata in this case)
    final Metadata? response = await ndk.metadata.loadMetadata(
        '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d');

    // read entity
    print("METADATA:");
    print("name: ${response?.name ?? 'no name'}");
    print("lud16: ${response?.lud16 ?? 'no lud16'}");
    print("sources: ${response?.sources ?? 'no sources'}");

    expect(response, isNotNull, reason: 'response is Null');
    expect(response!.nip05, isNotEmpty, reason: 'nip05 is empty');
    ndk.destroy();
  });
}
