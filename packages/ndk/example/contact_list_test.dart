// ignore_for_file: avoid_print

import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

void main() async {
  test('contactList', () async {
    // Create an instance of Ndk
    // It's recommended to keep this instance global as it holds critical application state
    final Ndk ndk = Ndk(
      // Configure the Ndk instance using NdkConfig
      NdkConfig(
        // Use Bip340EventVerifier for event verification
        // in production RustEventVerifier() is recommended
        eventVerifier: Bip340EventVerifier(),

        // Use in-memory cache for storing Nostr data
        cache: MemCacheManager(),
      ),
    );

    // Use a prebuilt ndk usecase (contact list in this case)
    final ContactList? response = await ndk.follows.getContactList(
        '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d');

    // read entity
    print("CONTACTS:");
    print(response?.contacts.length ?? "no contacts");

    expect(response, isNotNull, reason: 'response is Null');
    expect(response!.contacts.length, greaterThan(0),
        reason: 'contact list is empty');
  });
}
