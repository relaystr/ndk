import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  group('metadatas', () {
    KeyPair key0 = Bip340.generatePrivateKey();
    final Metadata network0Metadata =
        Metadata(pubKey: key0.publicKey, name: "network0");
    network0Metadata.updatedAt = 100;

    final Metadata cache0Metadata =
        Metadata(pubKey: key0.publicKey, name: "cache0");

    //? network last
    KeyPair key1 = Bip340.generatePrivateKey();
    final Metadata network1Metadata =
        Metadata(pubKey: key1.publicKey, name: "network1");

    final Metadata cache1Metadata =
        Metadata(pubKey: key1.publicKey, name: "cache1");
    cache1Metadata.updatedAt = 100;

    late var relay0;
    late var ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5095);
      await relay0.startServer(textNotes: {
        key0: network0Metadata.toEvent(),
        key1: network1Metadata.toEvent(),
      });

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        bootstrapRelays: [relay0.url],
      );

      ndk = Ndk(config);

      cache.saveMetadata(cache0Metadata);
      //cache.saveContactList(cache1ContactList);
    });

    tearDown(() async {
      await ndk.destroy();
      await relay0.stopServer();
    });

    test('metadata equal', () {
      expect(cache0Metadata, equals(cache0Metadata));
      expect(cache0Metadata, equals(network0Metadata));
    });

    test('getMetadata - cache', () async {
      final rcvMetadata = await ndk.metadata.loadMetadata(key0.publicKey);

      // cache
      expect(rcvMetadata, equals(cache0Metadata));
    });

    test('getMetadata- network', () async {
      final rcvMetadata = await ndk.metadata.loadMetadata(
        key1.publicKey,
        forceRefresh: true,
      );

      // cache
      expect(rcvMetadata!.name, equals(network1Metadata.name));
    });

    test('getMetadatas - network', () async {
      final rcvMetadatas = await ndk.metadata
          .loadMetadatas([key0.publicKey, key1.publicKey], null);

      expect(rcvMetadatas.length, 1); // only one is missing
    });
  });
}
