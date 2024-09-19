import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  group('lists', () {

    KeyPair key0 = Bip340.generatePrivateKey();
    KeyPair key1 = Bip340.generatePrivateKey();
    final Nip51List followSetKey0 = Nip51List(
      pubKey: key0.publicKey,
      kind: Nip51List.FOLLOW_SET,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      elements: [
        Nip51ListElement(
          tag: Nip51List.PUB_KEY,
          value: key1.publicKey,
          private: false
        )]
    );


    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 4095);
      await relay0.startServer(textNotes: {
        key0: await followSetKey0.toEvent(null)
      });

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

    test('lists get follow set', ()  async {
      Bip340EventSigner signer = Bip340EventSigner(key0.privateKey, key0.publicKey);
      Nip51List? followSet = await ndk.lists.getSingleNip51List(Nip51List.FOLLOW_SET, signer);
      expect(followSetKey0.kind, followSet!.kind);
      expect(followSetKey0.elements.length, followSet.elements.length);
      expect(followSetKey0.elements.first.value, followSet.elements.first.value);
    });
  });
}
