import 'dart:developer';

import 'package:ndk/ndk.dart';

Future<void> main() async {
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  final nostrConnect = NostrConnect(
      relays: ["wss://relay.nsec.app"],
      appName: "NDK nostr connect example",
      appUrl: "https://dart-nostr.com/");

  log('Logging in with ${nostrConnect.nostrConnectURL}');
  log('Enter this URI into your Nostr Connect client to log in.');

  try {
    await ndk.accounts.loginWithNostrConnect(
        nostrConnect: nostrConnect, bunkers: ndk.bunkers);

    log('Successfully logged in with bunker!');
    log('Logged in as: ${ndk.accounts.getPublicKey()}');

    // Test signing an event
    final event = Nip01EventService.createEventCalculateId(
      pubKey: ndk.accounts.getPublicKey()!,
      kind: 1,
      content: 'Hello from NIP-46 with new simplified API!',
      tags: [],
    );

    final signedEvent = await ndk.accounts.sign(event);
    log('Event signed successfully!');
    log('Event ID: ${signedEvent.id}');
  } catch (e) {
    log('Error: $e');
  }

  await ndk.destroy();
}
