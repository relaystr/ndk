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

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5096);
      await relay0.startServer(metadatas: {
        key0.publicKey: network0Metadata.toEvent(),
        key1.publicKey: network1Metadata.toEvent(),
      });

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        bootstrapRelays: [relay0.url],
      );

      ndk = Ndk(config);

      await ndk.relays.seedRelaysConnected;
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

    test('broadcast metadata', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Metadata metadata = Metadata(pubKey: key0.publicKey);
      await ndk.metadata.broadcastMetadata(metadata);

      Metadata? result =
          await ndk.metadata.loadMetadata(key0.publicKey, forceRefresh: true);
      expect(result!.pubKey, metadata.pubKey);

      metadata.name = "my name";
      await ndk.metadata.broadcastMetadata(metadata);
      result =
          await ndk.metadata.loadMetadata(key0.publicKey, forceRefresh: true);
      expect(result!.name, metadata.name);
    });
  });
}
