import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  group('lists', () {
    KeyPair key0 = Bip340.generatePrivateKey();
    KeyPair key1 = Bip340.generatePrivateKey();
    Bip340EventSigner signer0 =
        Bip340EventSigner(key0.privateKey, key0.publicKey);
    Bip340EventSigner signer1 =
        Bip340EventSigner(key1.privateKey, key1.publicKey);

    final Nip51List bookmarkListKey0 = Nip51List(
        pubKey: key0.publicKey,
        kind: Nip51List.BOOKMARKS,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        elements: [
          Nip51ListElement(
              tag: Nip51List.PUB_KEY, value: key1.publicKey, private: false)
        ]);

    final Nip51Set favoriteRelaysKey1 = Nip51Set(
        pubKey: key1.publicKey,
        name: "my favorite relays",
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        elements: [
          Nip51ListElement(
              tag: Nip51List.RELAY, value: "wss://bla.com", private: true)
        ]);

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 4096);
      Nip01Event event0 = await bookmarkListKey0.toEvent(signer0);
      Nip01Event event1 = await favoriteRelaysKey1.toEvent(signer1);

      await signer0.sign(event0);
      await signer1.sign(event1);

      await relay0.startServer(textNotes: {key0: event0, key1: event1});

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        bootstrapRelays: [relay0.url],
      );

      ndk = Ndk(config);
    });

    tearDown(() async {
      await relay0.stopServer();
    });

    test('lists get bookmarks', () async {
      Nip51List? bookmarks =
          await ndk.lists.getSingleNip51List(Nip51List.BOOKMARKS, signer0);
      expect(bookmarkListKey0.kind, bookmarks!.kind);
      expect(bookmarkListKey0.elements.length, bookmarks.elements.length);
      expect(bookmarkListKey0.elements.first.value,
          bookmarks.elements.first.value);
    });

    test('lists get favorite relays', () async {
      Nip51Set? relays = await ndk.lists
          .getSingleNip51RelaySet(favoriteRelaysKey1.name, signer1);
      expect(favoriteRelaysKey1.kind, relays!.kind);
      expect(favoriteRelaysKey1.elements.length, relays.elements.length);
      expect(
          favoriteRelaysKey1.elements.first.value, relays.elements.first.value);
    });
  });
}
