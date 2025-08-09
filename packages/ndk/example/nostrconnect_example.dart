import 'package:ndk/ndk.dart';

Future<void> main() async {
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  final nostrConnect = NostrConnect(
      relays: ["wss://relay.nsec.app"],
      appName: "NDK nostr connect example",
      appUrl: "https://dart-nostr.com/");

  print('Logging in with ${nostrConnect.nostrConnectURL}');
  print('Enter this URI into your Nostr Connect client to log in.');

  try {
    await ndk.accounts.loginWithNostrConnect(
        nostrConnect: nostrConnect, bunkers: ndk.bunkers);

    print('Successfully logged in with bunker!');
    print('Logged in as: ${ndk.accounts.getPublicKey()}');

    // Test signing an event
    final event = Nip01Event(
      pubKey: ndk.accounts.getPublicKey()!,
      kind: 1,
      content: 'Hello from NIP-46 with new simplified API!',
      tags: [],
    );

    await ndk.accounts.sign(event);
    print('Event signed successfully!');
    print('Event ID: ${event.id}');
  } catch (e) {
    print('Error: $e');
  }

  await ndk.destroy();
}
