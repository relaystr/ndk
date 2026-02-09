import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:nostr_bunker/nostr_bunker.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
// import '../mocks/mock_relay.dart';

void main() {
  test('two unapproved requests should be pending', () async {
    // TODO use the mock relay
    // Start mock relay
    // final mockRelay = MockRelay(
    //   name: 'nip46-bunker-test-relay',
    //   explicitPort: 4048,
    // );
    // await mockRelay.startServer();

    final relayUrl = "wss://nostr-01.uid.ovh";
    // final relayUrl = mockRelay.url;

    // Generate user keypair
    final userKeyPair = Bip340.generatePrivateKey();
    final userPubkey = userKeyPair.publicKey;

    // Create bunker
    final bunker = Bunker(
      privateKeys: [userKeyPair.privateKey!],
      defaultBunkerRelays: [relayUrl],
    );

    final bunkerUrl = bunker.getBunkerUrl(
      userPubkey: userPubkey,
      appAuthorisationMode: AuthorisationMode.allwaysAsk,
      enableApp: true,
    );

    // Collect pending requests from bunker
    final bunkerPendingRequests = <Nip46Request>[];
    bunker.pendingRequestsStream.listen((request) {
      bunkerPendingRequests.add(request);
    });

    // Create client
    final clientNdk = Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        eventVerifier: MockEventVerifier(),
        bootstrapRelays: [relayUrl],
      ),
    );

    await clientNdk.accounts.loginWithBunkerUrl(
      bunkerUrl: bunkerUrl,
      bunkers: clientNdk.bunkers,
    );

    final signer = clientNdk.accounts.getLoggedAccount()!.signer;

    // Start 2 sign requests without awaiting
    signer
        .sign(
          Nip01Event(pubKey: userPubkey, kind: 1, tags: [], content: 'First'),
        )
        .ignore();
    signer
        .sign(
          Nip01Event(pubKey: userPubkey, kind: 1, tags: [], content: 'Second'),
        )
        .ignore();

    await Future.delayed(Duration(seconds: 1));

    expect(signer.pendingRequests.length, equals(2));

    // Cancel one of the requests
    final requestToCancel = signer.pendingRequests.first;
    signer.cancelRequest(requestToCancel.id);

    await Future.delayed(Duration(seconds: 1));

    expect(signer.pendingRequests.length, equals(1));

    // Approve all requests via bunker
    for (final request in bunkerPendingRequests) {
      bunker.processRequest(request);
    }

    await Future.delayed(Duration(seconds: 1));

    expect(signer.pendingRequests.length, equals(0));

    // Cleanup
    await signer.dispose();
    bunker.stop();
    bunker.dispose();
    await clientNdk.destroy();
    // await mockRelay.stopServer();
  });
}
