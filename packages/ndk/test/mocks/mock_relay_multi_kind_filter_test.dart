import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import 'mock_event_verifier.dart';
import 'mock_relay.dart';

void main() {
  group('MockRelay multi-kind filter matching', () {
    late MockRelay mockRelay;

    setUp(() async {
      mockRelay = MockRelay(name: 'multi-kind-filter-test-relay');
      await mockRelay.startServer();
    });

    tearDown(() async {
      await mockRelay.stopServer();
    });

    test(
      'a filter with kinds [10002, 3, 0, 30382] should return stored events of all kinds',
      () async {
        final keyPair = Bip340.generatePrivateKey();

        final ndkWriter = Ndk(
          NdkConfig(
            cache: MemCacheManager(),
            eventVerifier: MockEventVerifier(),
            bootstrapRelays: [mockRelay.url],
          ),
        );

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        final relayListEvent = Nip01Event(
          pubKey: keyPair.publicKey,
          kind: Nip65.kKind,
          tags: [
            ['r', 'wss://write.example.com'],
          ],
          content: '',
          createdAt: now - 1,
        );
        final signedRelayList = Nip01Utils.signWithPrivateKey(
          event: relayListEvent,
          privateKey: keyPair.privateKey!,
        );
        await ndkWriter.broadcast
            .broadcast(
              nostrEvent: signedRelayList,
              specificRelays: [mockRelay.url],
            )
            .broadcastDoneFuture;

        final contactListEvent = Nip01Event(
          pubKey: keyPair.publicKey,
          kind: ContactList.kKind,
          tags: [
            ['p', keyPair.publicKey],
          ],
          content: '',
          createdAt: now,
        );
        final signedContactList = Nip01Utils.signWithPrivateKey(
          event: contactListEvent,
          privateKey: keyPair.privateKey!,
        );
        await ndkWriter.broadcast
            .broadcast(
              nostrEvent: signedContactList,
              specificRelays: [mockRelay.url],
            )
            .broadcastDoneFuture;

        final metadataEvent = Metadata(
          pubKey: keyPair.publicKey,
          name: 'multi-kind-profile',
        ).toEvent();
        final signedMetadata = Nip01Utils.signWithPrivateKey(
          event: metadataEvent,
          privateKey: keyPair.privateKey!,
        );
        await ndkWriter.broadcast
            .broadcast(
              nostrEvent: signedMetadata,
              specificRelays: [mockRelay.url],
            )
            .broadcastDoneFuture;

        final assertionEvent = Nip01Event(
          pubKey: keyPair.publicKey,
          kind: 30382,
          tags: [
            ['d', keyPair.publicKey],
          ],
          content: '',
          createdAt: now,
        );
        final signedAssertion = Nip01Utils.signWithPrivateKey(
          event: assertionEvent,
          privateKey: keyPair.privateKey!,
        );
        await ndkWriter.broadcast
            .broadcast(
              nostrEvent: signedAssertion,
              specificRelays: [mockRelay.url],
            )
            .broadcastDoneFuture;

        // Fresh client to bypass any local cache
        final ndkReader = Ndk(
          NdkConfig(
            cache: MemCacheManager(),
            eventVerifier: MockEventVerifier(),
            bootstrapRelays: [mockRelay.url],
          ),
        );

        final received = await ndkReader.requests
            .query(
              filter: Filter(
                kinds: [Nip65.kKind, ContactList.kKind, Metadata.kKind, 30382],
                authors: [keyPair.publicKey],
              ),
            )
            .future;

        expect(
          received.map((event) => event.id),
          contains(signedContactList.id),
          reason: 'The contact list should match the combined filter.',
        );
        expect(
          received.map((event) => event.id),
          contains(signedMetadata.id),
          reason: 'The metadata should match the combined filter.',
        );
        expect(
          received.map((event) => event.id),
          contains(signedAssertion.id),
          reason:
              'The stored kind 30382 event should match the combined filter.',
        );
        expect(
          received.map((event) => event.id),
          contains(signedRelayList.id),
          reason:
              'The stored kind 10002 event should match the combined filter; '
              'the mock skips general event matching when a specialized '
              'branch handled the filter.',
        );

        await ndkWriter.destroy();
        await ndkReader.destroy();
      },
    );
  });
}
