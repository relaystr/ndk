import 'dart:io';

import 'package:ndk/data_layer/repositories/cache_manager/sembast_cache_manager.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/logger/logger.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip25/reactions.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  group('local first outbox public api', () {
    late Directory tempDir;
    late KeyPair authorKey;
    late Ndk ndk;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('local_first_public_api');
      authorKey = Bip340.generatePrivateKey();
    });

    tearDown(() async {
      await ndk.destroy();
      await tempDir.delete(recursive: true);
    });

    test(
        'offline publish is locally readable and eventually reaches relay when relay comes online',
        () async {
      final relay = MockRelay(name: 'local-first-relay', explicitPort: 5301);
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final event = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: authorKey.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'offline-first public api note',
          createdAt: 1_700_000_000,
        ),
        privateKey: authorKey.privateKey!,
      );

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            timeout: const Duration(milliseconds: 300),
          )
          .broadcastDoneFuture;

      final localWhileOffline = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;

      expect(localWhileOffline.map((e) => e.id), contains(event.id));

      await relay.startServer();
      await Future<void>.delayed(const Duration(seconds: 1));

      final relayAfterReconnect = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(ids: [event.id]),
      );

      expect(
        relayAfterReconnect.map((e) => e.id),
        contains(event.id),
        reason:
            'Local-first outbox should auto-deliver the unpublished event after the relay becomes reachable.',
      );

      await relay.stopServer();
    });

    test(
        'partial success keeps local visibility and should later deliver only to relays that were offline',
        () async {
      final relayOnline = MockRelay(name: 'relay-online', explicitPort: 5302);
      final relayOffline = MockRelay(name: 'relay-offline', explicitPort: 5303);
      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [relayOnline.url, relayOffline.url],
      );

      await relayOnline.startServer();

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final event = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: authorKey.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'partial success note',
          createdAt: 1_700_000_010,
        ),
        privateKey: authorKey.privateKey!,
      );

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relayOnline.url, relayOffline.url],
            timeout: const Duration(milliseconds: 300),
          )
          .broadcastDoneFuture;

      final localVisible = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;
      expect(localVisible.map((e) => e.id), contains(event.id));

      final onlineRelayEvents = await _waitForRelayEvents(
        relay: relayOnline,
        filter: Filter(ids: [event.id]),
      );
      expect(onlineRelayEvents.map((e) => e.id), contains(event.id));

      await relayOffline.startServer();
      await Future<void>.delayed(const Duration(seconds: 1));

      final offlineRelayEventually = await _waitForRelayEvents(
        relay: relayOffline,
        filter: Filter(ids: [event.id]),
      );

      expect(
        offlineRelayEventually.map((e) => e.id),
        contains(event.id),
        reason:
            'After one relay succeeded and another was offline, local-first delivery should later flush only the missing relay.',
      );

      await relayOnline.stopServer();
      await relayOffline.stopServer();
    });

    test(
        'offline reaction to a cached root is locally visible and should later reach the relay',
        () async {
      final relay = MockRelay(name: 'reaction-relay', explicitPort: 5304);
      final remoteAuthor = Bip340.generatePrivateKey();
      final rootEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'root event',
          createdAt: 1_700_000_020,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      await relay.startServer(textNotes: {remoteAuthor: rootEvent});

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final cachedRoot = await ndk.requests
          .query(
            filter: Filter(ids: [rootEvent.id]),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 1),
          )
          .future;
      expect(cachedRoot.map((e) => e.id), contains(rootEvent.id));

      await relay.stopServer();

      await ndk.broadcast
          .broadcastReaction(
            eventId: rootEvent.id,
            customRelays: [relay.url],
            reaction: '♡',
          )
          .broadcastDoneFuture;

      final localReaction = await ndk.requests
          .query(
            filter: Filter(
              authors: [authorKey.publicKey],
              kinds: [Reaction.kKind],
            ),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;

      expect(localReaction.map((e) => e.content), contains('♡'));

      await relay.startServer(textNotes: {remoteAuthor: rootEvent});
      await Future<void>.delayed(const Duration(seconds: 1));

      final relayReaction = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(
          authors: [authorKey.publicKey],
          kinds: [Reaction.kKind],
        ),
      );

      expect(
        relayReaction.map((e) => e.content),
        contains('♡'),
        reason:
            'A reaction created while offline should be immediately visible locally and later delivered when the relay becomes reachable again.',
      );

      await relay.stopServer();
    });

    test(
        'offline replaceable supersession shows latest locally and should later deliver only the newest version',
        () async {
      final relay = MockRelay(name: 'replaceable-relay', explicitPort: 5305);
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final version1 = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: authorKey.publicKey,
          kind: 30023,
          tags: const [
            ['d', 'article-1']
          ],
          content: 'version 1',
          createdAt: 1_700_000_030,
        ),
        privateKey: authorKey.privateKey!,
      );

      final version2 = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: authorKey.publicKey,
          kind: 30023,
          tags: const [
            ['d', 'article-1']
          ],
          content: 'version 2',
          createdAt: 1_700_000_031,
        ),
        privateKey: authorKey.privateKey!,
      );

      await ndk.broadcast
          .broadcast(
            nostrEvent: version1,
            specificRelays: [relay.url],
            timeout: const Duration(milliseconds: 300),
          )
          .broadcastDoneFuture;
      await ndk.broadcast
          .broadcast(
            nostrEvent: version2,
            specificRelays: [relay.url],
            timeout: const Duration(milliseconds: 300),
          )
          .broadcastDoneFuture;

      final localCurrent = await ndk.requests
          .query(
            filter: Filter(
              authors: [authorKey.publicKey],
              kinds: [30023],
              tags: {
                'd': ['article-1']
              },
            ),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;

      expect(localCurrent.length, 1);
      expect(localCurrent.single.content, 'version 2');

      await relay.startServer();
      await Future<void>.delayed(const Duration(seconds: 1));

      final relayCurrent = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(
          authors: [authorKey.publicKey],
          kinds: [30023],
          tags: {
            'd': ['article-1']
          },
        ),
      );

      expect(
        relayCurrent.map((e) => e.content),
        contains('version 2'),
        reason:
            'When multiple offline versions of a replaceable event exist, local-first delivery should later flush only the newest visible version.',
      );
      expect(
        relayCurrent.where((e) => e.content == 'version 1'),
        isEmpty,
        reason:
            'Superseded replaceable versions should not later be delivered after the current one replaced them locally.',
      );
      expect(
        relay.receivedEvents.where((e) => e.content == 'version 1'),
        isEmpty,
        reason:
            'Superseded replaceable versions should be skipped by local-first flush instead of being sent and relying on relay-side conflict resolution.',
      );
      expect(
        relay.receivedEvents.where((e) => e.content == 'version 2').length,
        1,
        reason:
            'Only the current replaceable version should be delivered during delayed flush.',
      );

      await relay.stopServer();
    });

    test(
        'connected relay rejecting first should keep local visibility and later succeed via periodic retry',
        () async {
      final relay = MockRelay(
        name: 'retry-relay',
        explicitPort: 5306,
        rejectFirstEventPublishes: 1,
        rejectEventMessage: 'rate-limited: retry later',
      );
      await relay.startServer();
      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [relay.url],
        pendingDeliveryRetryInterval: const Duration(seconds: 1),
      );

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final event = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: authorKey.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'connected retry note',
          createdAt: 1_700_000_040,
        ),
        privateKey: authorKey.privateKey!,
      );

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            timeout: const Duration(milliseconds: 500),
          )
          .broadcastDoneFuture;

      final localVisible = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;
      expect(localVisible.map((e) => e.id), contains(event.id));

      expect(
        relay.receivedEvents.where((e) => e.id == event.id).length,
        1,
        reason:
            'The first connected publish attempt should reach the relay and be rejected without disconnecting.',
      );
      expect(
        relay.matchingEvents(Filter(ids: [event.id])),
        isEmpty,
        reason:
            'Rejected events should not be visible on the relay before the retry succeeds.',
      );

      final eventuallyStored = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(ids: [event.id]),
        timeout: const Duration(seconds: 8),
      );

      expect(
        eventuallyStored.map((e) => e.id),
        contains(event.id),
        reason:
            'A connected relay that first rejects with a transient error should later receive the event through the periodic due-retry path.',
      );
      expect(
        relay.receivedEvents.where((e) => e.id == event.id).length,
        2,
        reason:
            'The retry path should produce a second publish attempt after the initial transient rejection.',
      );

      await relay.stopServer();
    });

    test(
        'connected relay returning permanent failure should keep local visibility without periodic retry spam',
        () async {
      final relay = MockRelay(
        name: 'permanent-failure-relay',
        explicitPort: 5307,
        rejectFirstEventPublishes: 99,
        rejectEventMessage: 'policy violation: forbidden kind',
      );
      await relay.startServer();
      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [relay.url],
        pendingDeliveryRetryInterval: const Duration(seconds: 1),
      );

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final event = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: authorKey.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'permanent failure note',
          createdAt: 1_700_000_041,
        ),
        privateKey: authorKey.privateKey!,
      );

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            timeout: const Duration(milliseconds: 500),
          )
          .broadcastDoneFuture;

      final localVisible = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;
      expect(localVisible.map((e) => e.id), contains(event.id));

      expect(
        relay.receivedEvents.where((e) => e.id == event.id).length,
        1,
        reason:
            'The initial publish attempt should still reach the connected relay before being rejected permanently.',
      );

      await Future<void>.delayed(const Duration(seconds: 4));

      expect(
        relay.matchingEvents(Filter(ids: [event.id])),
        isEmpty,
        reason:
            'A permanently rejected event should never appear on the relay if the relay keeps refusing it.',
      );
      expect(
        relay.receivedEvents.where((e) => e.id == event.id).length,
        1,
        reason:
            'Permanent failures should not be retried by the periodic retry pump.',
      );

      await relay.stopServer();
    });
  });
}

Future<Ndk> _createNdk(
  String databasePath, {
  List<String> bootstrapRelays = const [],
  Duration? pendingDeliveryRetryInterval,
}) async {
  final cache = await SembastCacheManager.create(databasePath: databasePath);
  return Ndk(
    NdkConfig(
      cache: cache,
      eventVerifier: MockEventVerifier(),
      bootstrapRelays: bootstrapRelays,
      ignoreRelays: const [],
      logLevel: LogLevel.all,
      pendingDeliveryRetryInterval:
          pendingDeliveryRetryInterval ?? const Duration(seconds: 15),
      cashuUserSeedphrase: CashuUserSeedphrase(
        seedPhrase: CashuSeed.generateSeedPhrase(),
      ),
    ),
  );
}

Future<List<Nip01Event>> _waitForRelayEvents({
  required MockRelay relay,
  required Filter filter,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final result = relay.matchingEvents(filter);
    if (result.isNotEmpty) {
      return result;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  return relay.matchingEvents(filter);
}
