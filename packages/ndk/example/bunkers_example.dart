import 'package:ndk/ndk.dart';

Future<void> main() async {
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  try {
    await ndk.accounts.loginWithBunkerUrl(
        bunkerUrl:
            "bunker://a1fe3664f7a2b24db97e5b63869e8011c947f9abd8c03f98befafd27c38467d2?relay=wss://relay.nsec.app&secret=devsecret123",
        bunkers: ndk.bunkers);

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
