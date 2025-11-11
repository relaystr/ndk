// ignore_for_file: avoid_print

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import 'mocks/mock_event_verifier.dart';
import 'mocks/mock_relay.dart';

void main() async {
  KeyPair key1 = Bip340.generatePrivateKey();
  KeyPair key2 = Bip340.generatePrivateKey();
  KeyPair key3 = Bip340.generatePrivateKey();
  KeyPair key4 = Bip340.generatePrivateKey();

  Map<KeyPair, String> keyNames = {
    key1: "key1",
    key2: "key2",
    key3: "key3",
    key4: "key4",
  };

  Nip01Event textNote(KeyPair key2) {
    Nip01Event event = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key2.publicKey,
        content: "some note from key ${keyNames[key2]}",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    event.sign(key2.privateKey!);
    return event;
  }

  Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};

  group('Ndk', () {
    test('query simple note LISTS',
        timeout: const Timeout(Duration(seconds: 3)), () async {
      MockRelay relay1 =
          MockRelay(name: "relay 1", explicitPort: 3960, signEvents: false);
      await relay1.startServer(textNotes: key1TextNotes);

      final ndk = Ndk(
        NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            engine: NdkEngine.RELAY_SETS,
            bootstrapRelays: [relay1.url]),
      );
      await ndk.relays.seedRelaysConnected;
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final response = ndk.requests.query(filters: [
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey])
      ]);

      await expectLater(response.stream, emitsInAnyOrder(key1TextNotes.values));

      final response2 = ndk.requests.query(filters: [
        Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey, key2.publicKey],
        )
      ]);

      await expectLater(
          response2.stream, emitsInAnyOrder(key1TextNotes.values));

      await relay1.stopServer();
    });

    test('query simple event by id',
        timeout: const Timeout(Duration(seconds: 3)), () async {
      MockRelay relay1 =
          MockRelay(name: "relay 1", explicitPort: 3961, signEvents: false);
      await relay1.startServer(textNotes: key1TextNotes);

      final cache = MemCacheManager();

      final ndk = Ndk(
        NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: cache,
            engine: NdkEngine.RELAY_SETS,
            bootstrapRelays: [relay1.url]),
      );
      await ndk.relays.seedRelaysConnected;

      final response = ndk.requests.query(filters: [
        Filter(ids: [key1TextNotes[key1]!.id])
      ]);

      await expectLater(response.stream, emitsInAnyOrder(key1TextNotes.values));

      await cache.saveEvent(key1TextNotes[key1]!);

      final response2 = ndk.requests.query(filters: [
        Filter(ids: [key1TextNotes[key1]!.id])
      ]);

      await expectLater(
          response2.stream, emitsInAnyOrder(key1TextNotes.values));

      await relay1.stopServer();
    });
    // ================================================================================================

    test('verify signatures of events', () async {
      MockRelay relay1 =
          MockRelay(name: "relay 1", explicitPort: 3962, signEvents: false);
      await relay1.startServer(textNotes: key1TextNotes);

      final ndk = Ndk(
        NdkConfig(
            eventVerifier: MockEventVerifier(result: false),
            cache: MemCacheManager(),
            engine: NdkEngine.RELAY_SETS,
            bootstrapRelays: [relay1.url]),
      );

      final response = ndk.requests.query(
        filters: [
          Filter(authors: [key1.publicKey], kinds: [Nip01Event.kTextNodeKind])
        ],
      );
      // ignore: unused_local_variable
      await for (final event in response.stream) {
        fail("should not emit any events, since relay does not sign");
      }
      await relay1.stopServer();
    });
  });
}
