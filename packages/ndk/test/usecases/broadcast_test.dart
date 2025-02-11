import 'package:ndk/shared/nips/nip25/reactions.dart';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() async {
  group('broadcast', () {
    KeyPair key0 = Bip340.generatePrivateKey();

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5095);
      await relay0.startServer();

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay0.url],
        ignoreRelays: [],
      );

      ndk = Ndk(config);

      await ndk.relays.seedRelaysConnected;
    });

    tearDown(() async {
      await ndk.destroy();
      await relay0.stopServer();
    });

    test('broadcast deletion', () async {
      ndk.accounts.loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event = Nip01Event(pubKey: key0.publicKey, kind: Nip01Event.kTextNodeKind, tags: [], content: "");
      NdkBroadcastResponse response = ndk.broadcast.broadcast(nostrEvent: event);
      await response.broadcastDoneFuture;

      List<Nip01Event> list = await ndk.requests.query(filters: [Filter(authors: [event.pubKey], kinds: [Nip01Event.kTextNodeKind])]).future;
      expect(list.first, event);

      response = ndk.broadcast.broadcastDeletion(eventId: event.id);
      await response.broadcastDoneFuture;

      list = await ndk.requests.query(filters: [Filter(authors: [event.pubKey], kinds: [Nip01Event.kTextNodeKind])]).future;
      expect(list, isEmpty);

    });

    test('broadcast reaction', () async {
      ndk.accounts.loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event = Nip01Event(pubKey: key0.publicKey, kind: Nip01Event.kTextNodeKind, tags: [], content: "");
      NdkBroadcastResponse response = ndk.broadcast.broadcast(nostrEvent: event);
      await response.broadcastDoneFuture;

      List<Nip01Event> list = await ndk.requests.query(filters: [Filter(authors: [event.pubKey], kinds: [Nip01Event.kTextNodeKind])]).future;
      expect(list.first, event);

      final reaction = "♡";
      response = ndk.broadcast.broadcastReaction(eventId: event.id, reaction: reaction);
      await response.broadcastDoneFuture;

      list = await ndk.requests.query(filters: [Filter(authors: [event.pubKey], kinds: [Reaction.kKind])]).future;
      expect(list.first.content, reaction);

    });
  });
}
