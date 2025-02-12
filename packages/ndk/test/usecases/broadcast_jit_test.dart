import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip25/reactions.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() async {
  group('broadcast JIT', () {
    KeyPair key0 = Bip340.generatePrivateKey();

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5095);
      await relay0.startServer(nip65s: {
        key0: Nip65(pubKey: key0.publicKey, relays: {relay0.url: ReadWriteMarker.readWrite},createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 )
      });

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay0.url],
        ignoreRelays: [],
      );

      ndk = Ndk(config);

      cache.saveUserRelayList(UserRelayList.fromNip65(Nip65(pubKey: key0.publicKey, relays: {relay0.url: ReadWriteMarker.readWrite},createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 )));
      await ndk.relays.seedRelaysConnected;
    });

    tearDown(() async {
      await ndk.destroy();
      await relay0.stopServer();
    });

    test('broadcast 2 events', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "");
      await ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;

      List<Nip01Event> result = await ndk.requests.query(
        filters: [
          Filter(authors: [key0.publicKey], kinds: [Nip01Event.kTextNodeKind])
        ],
      ).future;
      expect(result.length, 1);

      event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "my content");
      await ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;

      result = await ndk.requests.query(
        filters: [
          Filter(authors: [key0.publicKey], kinds: [Nip01Event.kTextNodeKind])
        ],
      ).future;
      expect(result.length, 2);
    });

    test('broadcast deletion', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "");
      NdkBroadcastResponse response =
          ndk.broadcast.broadcast(nostrEvent: event);
      await response.broadcastDoneFuture;

      List<Nip01Event> list = await ndk.requests.query(filters: [
        Filter(authors: [event.pubKey], kinds: [Nip01Event.kTextNodeKind])
      ]).future;
      expect(list.first, event);

      response = ndk.broadcast.broadcastDeletion(eventId: event.id);
      await response.broadcastDoneFuture;

      list = await ndk.requests.query(filters: [
        Filter(authors: [event.pubKey], kinds: [Nip01Event.kTextNodeKind])
      ]).future;
      expect(list, isEmpty);
    });

    test('broadcast reaction', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "");
      NdkBroadcastResponse response =
          ndk.broadcast.broadcast(nostrEvent: event);
      await response.broadcastDoneFuture;

      List<Nip01Event> list = await ndk.requests.query(filters: [
        Filter(authors: [event.pubKey], kinds: [Nip01Event.kTextNodeKind])
      ]).future;
      expect(list.first, event);

      final reaction = "♡";
      response = ndk.broadcast
          .broadcastReaction(eventId: event.id, reaction: reaction);
      await response.broadcastDoneFuture;

      list = await ndk.requests.query(filters: [
        Filter(authors: [event.pubKey], kinds: [Reaction.kKind])
      ]).future;
      expect(list.first.content, reaction);
    });
  });
}
