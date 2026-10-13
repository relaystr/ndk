import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

import '../../mocks/mock_relay.dart';

void main() {
  Future<void> loadMetadataFollowsWriteRelay(NdkEngine engine) async {
    final key = Bip340.generatePrivateKey();
    final metadata = Metadata(pubKey: key.publicKey, name: 'nip65-profile');

    final profileRelay = MockRelay(name: 'profile relay');
    final signedMetadataEvent = Nip01Utils.signWithPrivateKey(
      event: metadata.toEvent(),
      privateKey: key.privateKey!,
    );
    await profileRelay.startServer(
      metadatas: {key.publicKey: signedMetadataEvent},
    );

    final relayList = Nip65.fromMap(key.publicKey, {
      profileRelay.url: ReadWriteMarker.readWrite,
    });
    final signedRelayListEvent = Nip01Utils.signWithPrivateKey(
      event: relayList.toEvent(),
      privateKey: key.privateKey!,
    );
    final relayListBootstrap = MockRelay(name: 'relay list bootstrap');
    await relayListBootstrap.startServer();

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [relayListBootstrap.url],
        engine: engine,
      ),
    );

    await ndk.relays.seedRelaysConnected;

    addTearDown(() async {
      await ndk.destroy();
      await relayListBootstrap.stopServer();
      await profileRelay.stopServer();
    });

    await ndk.broadcast
        .broadcast(
          nostrEvent: signedRelayListEvent,
          specificRelays: [relayListBootstrap.url],
          saveToCache: false,
        )
        .broadcastDoneFuture;

    final loaded = await ndk.metadata.loadMetadata(key.publicKey);

    expect(loaded?.name, equals(metadata.name));
  }

  test('loadMetadata follows the author write relay (RELAY_SETS)', () async {
    await loadMetadataFollowsWriteRelay(NdkEngine.RELAY_SETS);
  });

  test('loadMetadata follows the author write relay (JIT)', () async {
    await loadMetadataFollowsWriteRelay(NdkEngine.JIT);
  });
}
