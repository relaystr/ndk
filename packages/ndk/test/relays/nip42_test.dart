// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

void main() async {
  group('NIP-42', () {
    KeyPair key1 = Bip340.generatePrivateKey();

    Map<KeyPair, String> keyNames = {
      key1: "key1",
    };

    Nip01Event textNote(KeyPair key) {
      Nip01Event event = Nip01Event(
          kind: Nip01Event.kTextNodeKind,
          pubKey: key.publicKey,
          content: "some note from key ${keyNames[key1]}",
          tags: [],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
      event.sign(key.privateKey!);
      return event;
    }

    Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};

    test('respond to auth challenge', () async {
      MockRelay relay1 = MockRelay(
          name: "relay 1", explicitPort: 3900, requireAuthForRequests: true, signEvents: false);
      await relay1.startServer(textNotes: key1TextNotes);

      final ndk = Ndk(
        NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            // logLevel: Logger.logLevels.trace,
            bootstrapRelays: [relay1.url]),
      );

      ndk.accounts.loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      await Future.delayed(Duration(seconds: 1));
      final response = ndk.requests.query(filters: [
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey])
      ]);
      List<Nip01Event> events = await response.future;
      await expectLater(response.stream, emitsInAnyOrder(key1TextNotes.values));

      // TODO: Create events and do some requests
      await ndk.destroy();
      await relay1.stopServer();
    });

    test("check that relay does not return events if we don't provide a signer",
        () async {
      MockRelay relay1 = MockRelay(
          name: "relay 1", explicitPort: 3900, requireAuthForRequests: true);
      await relay1.startServer(textNotes: key1TextNotes);

      final ndk = Ndk(
        NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            // logLevel: Logger.logLevels.trace,
            bootstrapRelays: [relay1.url]),
      );

      await Future.delayed(Duration(seconds: 1));
      final response = ndk.requests.query(filters: [
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey])
      ]);
      List<Nip01Event> events = await response.future;
      expect(events, isEmpty);
      await ndk.destroy();
      await relay1.stopServer();
    });
  });
}
