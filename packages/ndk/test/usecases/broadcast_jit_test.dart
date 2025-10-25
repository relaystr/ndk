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
      relay0 = MockRelay(name: "relay 0", explicitPort: 5085);
      await relay0.startServer(nip65s: {
        key0: Nip65(
            pubKey: key0.publicKey,
            relays: {relay0.url: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000)
      });

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay0.url],
        ignoreRelays: [],
        logLevel: LogLevel.all,
      );

      ndk = Ndk(config);

      //cache.saveUserRelayList(UserRelayList.fromNip65(Nip65(pubKey: key0.publicKey, relays: {relay0.url: ReadWriteMarker.readWrite},createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 )));
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

  group('broadcast JIT - strategies', () {
    KeyPair key1 = Bip340.generatePrivateKey();
    KeyPair keyOther = Bip340.generatePrivateKey();

    late MockRelay relay1;
    late MockRelay relay2;
    late MockRelay relay3;
    late Ndk ndk;

    setUp(() async {
      relay1 = MockRelay(name: "relay 1", explicitPort: 5086);
      relay2 = MockRelay(name: "relay 2", explicitPort: 5087);
      relay3 = MockRelay(name: "relay 3", explicitPort: 5088);
      await relay1.startServer(nip65s: {
        key1: Nip65(
            pubKey: key1.publicKey,
            relays: {relay1.url: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000)
      });
      await relay2.startServer();

      await relay3.startServer();

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay1.url],
        //logLevel: Level.all,
        ignoreRelays: [],
      );

      ndk = Ndk(config);

      // own
      await cache.saveUserRelayList(UserRelayList.fromNip65(
        Nip65(
            pubKey: key1.publicKey,
            relays: {relay1.url: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ));

      // other
      await cache.saveUserRelayList(UserRelayList.fromNip65(
        Nip65(
            pubKey: keyOther.publicKey,
            relays: {relay2.url: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ));

      await cache.saveUserRelayList(UserRelayList.fromNip65(
        Nip65(
            pubKey: key1.publicKey,
            relays: {
              relay1.url: ReadWriteMarker.readWrite,
              relay3.url: ReadWriteMarker.readWrite, // Add new relay
            },
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ));

      await ndk.relays.seedRelaysConnected;
    });

    tearDown(() async {
      await ndk.destroy();
      await relay1.stopServer();
      await relay2.stopServer();
      await relay3.stopServer();
    });

    test('broadcast JIT - specific', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);
      Nip01Event event = Nip01Event(
          pubKey: key1.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "hi there");
      await ndk.broadcast.broadcast(
          nostrEvent: event,
          specificRelays: [relay1.url, relay2.url]).broadcastDoneFuture;

      List<Nip01Event> result = await ndk.requests.query(
        explicitRelays: [relay2.url],
        filters: [
          Filter(authors: [key1.publicKey], kinds: [Nip01Event.kTextNodeKind])
        ],
      ).future;
      expect(result.length, 1);
    });

    test('broadcast JIT - other read', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      Nip01Event event = Nip01Event(
          pubKey: key1.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [
            ["p", keyOther.publicKey]
          ],
          content: "hi other");

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
          )
          .broadcastDoneFuture;

      List<Nip01Event> result = await ndk.requests.query(
        name: "other read",
        explicitRelays: [relay2.url],
        filters: [
          Filter(authors: [key1.publicKey], kinds: [Nip01Event.kTextNodeKind])
        ],
      ).future;
      expect(result.length, 1);
    });

    test('broadcast JIT - connect relay during broadcast', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      // verify relay3 is not initially connected
      expect(ndk.relays.isRelayConnected(relay3.url), false);

      Nip01Event event = Nip01Event(
          pubKey: key1.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "test connection during broadcast");

      // broadcast the event - this should trigger connection to relay3
      await ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;

      // verify the event was broadcast to both relays
      List<Nip01Event> resultRelay1 = await ndk.requests.query(
        explicitRelays: [relay1.url],
        filters: [
          Filter(authors: [key1.publicKey], kinds: [Nip01Event.kTextNodeKind])
        ],
      ).future;
      expect(resultRelay1.length, 1);

      List<Nip01Event> resultRelay3 = await ndk.requests.query(
        explicitRelays: [relay3.url],
        filters: [
          Filter(authors: [key1.publicKey], kinds: [Nip01Event.kTextNodeKind])
        ],
      ).future;
      expect(resultRelay3.length, 1);
    });
  });
}
