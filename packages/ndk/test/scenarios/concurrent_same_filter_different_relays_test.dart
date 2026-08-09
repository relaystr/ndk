import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() {
  Nip01Event textNote(KeyPair key, String content) {
    return Nip01Event(
      kind: Nip01Event.kTextNodeKind,
      pubKey: key.publicKey,
      content: content,
      tags: [],
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  test(
    'same filter on two different relays should not share results',
    () async {
      final key = Bip340.generatePrivateKey();

      final noteOnRelay1 = textNote(key, "note only on relay 1");
      final noteOnRelay2 = textNote(key, "note only on relay 2");

      final relay1 = MockRelay(name: "relay 1");
      final relay2 = MockRelay(name: "relay 2");

      await relay1.startServer(textNotes: {key: noteOnRelay1});
      await relay2.startServer(textNotes: {key: noteOnRelay2});
      addTearDown(relay1.stopServer);
      addTearDown(relay2.stopServer);

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay1.url, relay2.url],
        ),
      );
      addTearDown(ndk.destroy);

      await ndk.connectivity.relayConnectivityChanges
          .firstWhere(
            (relays) =>
                relays[relay1.url]?.isConnected == true &&
                relays[relay2.url]?.isConnected == true,
          )
          .timeout(const Duration(seconds: 10));

      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key.publicKey],
      );

      final results = await Future.wait([
        ndk.requests.query(filter: filter, explicitRelays: [relay1.url]).future,
        ndk.requests.query(filter: filter, explicitRelays: [relay2.url]).future,
      ]);

      expect(
        results[0].map((e) => e.id),
        contains(noteOnRelay1.id),
        reason: 'query on relay 1 should return the event stored on relay 1',
      );
      expect(
        results[1].map((e) => e.id),
        contains(noteOnRelay2.id),
        reason: 'query on relay 2 should return the event stored on relay 2',
      );
    },
  );
}
