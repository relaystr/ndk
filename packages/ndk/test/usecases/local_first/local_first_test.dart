import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip09/deletion.dart';
import 'package:ndk/shared/nips/nip25/reactions.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  group('local first', () {
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
      final relay = MockRelay(name: 'local-first-relay');
      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [relay.url],
        pendingDeliveryRetryInterval: const Duration(seconds: 1),
      );

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final event = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'offline-first public api note',
        createdAt: 1_700_000_000,
      );

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            timeout: const Duration(seconds: 1),
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
      await _waitForRelayConnected(
        ndk: ndk,
        relayUrl: relay.url,
        timeout: const Duration(seconds: 20),
      );

      final relayAfterReconnect = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(ids: [event.id]),
        timeout: const Duration(seconds: 15),
      );

      expect(
        relayAfterReconnect.map((e) => e.id),
        contains(event.id),
        reason:
            'Local-first should auto-deliver the unpublished event after the relay becomes reachable.',
      );

      await relay.stopServer();
    });

    test(
        'partial success keeps local visibility and should later deliver only to relays that were offline',
        () async {
      final relayOnline = MockRelay(name: 'relay-online');
      final relayOffline = MockRelay(name: 'relay-offline');
      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [relayOnline.url, relayOffline.url],
      );

      await relayOnline.startServer();

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final event = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'partial success note',
        createdAt: 1_700_000_010,
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

      final offlineRelayEventually = await _waitForRelayEvents(
        relay: relayOffline,
        filter: Filter(ids: [event.id]),
        timeout: const Duration(seconds: 8),
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
      final relay = MockRelay(name: 'reaction-relay');
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

      final relayReaction = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(
          authors: [authorKey.publicKey],
          kinds: [Reaction.kKind],
        ),
        timeout: const Duration(seconds: 8),
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
      final relay = MockRelay(name: 'replaceable-relay');
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final version1 = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: 30023,
        tags: const [
          ['d', 'article-1']
        ],
        content: 'version 1',
        createdAt: 1_700_000_030,
      );

      final version2 = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: 30023,
        tags: const [
          ['d', 'article-1']
        ],
        content: 'version 2',
        createdAt: 1_700_000_031,
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
      await _waitForRelayConnected(
        ndk: ndk,
        relayUrl: relay.url,
        timeout: const Duration(seconds: 20),
      );

      final relayCurrent = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(
          authors: [authorKey.publicKey],
          kinds: [30023],
          tags: {
            'd': ['article-1']
          },
        ),
        timeout: const Duration(seconds: 8),
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
        'offline publish survives ndk restart and is later delivered after relay comes online',
        () async {
      final relay = MockRelay(name: 'restart-relay');
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final event = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'restart persistence note',
        createdAt: 1_700_000_035,
      );

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            timeout: const Duration(milliseconds: 300),
          )
          .broadcastDoneFuture;

      final localBeforeRestart = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;
      expect(localBeforeRestart.map((e) => e.id), contains(event.id));

      await ndk.destroy();
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);
      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final localAfterRestart = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;
      expect(localAfterRestart.map((e) => e.id), contains(event.id));

      await relay.startServer();
      await _waitForRelayConnected(
        ndk: ndk,
        relayUrl: relay.url,
        timeout: const Duration(seconds: 20),
      );

      final relayAfterReconnect = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(ids: [event.id]),
        timeout: const Duration(seconds: 8),
      );

      expect(
        relayAfterReconnect.map((e) => e.id),
        contains(event.id),
        reason:
            'A locally queued event should survive process restart and still be delivered once the relay becomes reachable.',
      );

      await relay.stopServer();
    });

    test(
        'incoming deletion hides a previously cached foreign event from app queries',
        () async {
      final relay = MockRelay(name: 'incoming-deletion-relay');
      final remoteAuthor = Bip340.generatePrivateKey();
      final rootEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'event later deleted',
          createdAt: 1_700_000_050,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      final deletionEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Deletion.kKind,
          tags: [
            ['e', rootEvent.id],
            ['k', rootEvent.kind.toString()],
          ],
          content: 'delete root event',
          createdAt: 1_700_000_051,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      await relay.startServer(textNotes: {remoteAuthor: rootEvent});

      final cachedRoot = await ndk.requests
          .query(
            filter: Filter(ids: [rootEvent.id]),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 1),
          )
          .future;
      expect(cachedRoot.map((e) => e.id), contains(rootEvent.id));

      await _publishFixtureEventToRelay(relay.url, deletionEvent);

      final fetchedDeletion = await ndk.requests
          .query(
            filter: Filter(
              authors: [remoteAuthor.publicKey],
              kinds: [Deletion.kKind],
              ids: [deletionEvent.id],
            ),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 1),
          )
          .future;
      expect(fetchedDeletion.map((e) => e.id), contains(deletionEvent.id));

      final localAfterDeletion = await ndk.requests
          .query(
            filter: Filter(ids: [rootEvent.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;

      expect(
        localAfterDeletion.map((e) => e.id),
        isNot(contains(rootEvent.id)),
        reason:
            'After a valid remote deletion is seen, app-level local-first reads should stop returning the deleted foreign event.',
      );

      await relay.stopServer();
    });

    test(
        'deletion received before target should keep the later foreign target suppressed locally',
        () async {
      final relay = MockRelay(name: 'deletion-first-relay');
      final remoteAuthor = Bip340.generatePrivateKey();
      final rootEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'event that should stay tombstoned',
          createdAt: 1_700_000_060,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      final deletionEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Deletion.kKind,
          tags: [
            ['e', rootEvent.id],
            ['k', rootEvent.kind.toString()],
          ],
          content: 'delete before target arrives',
          createdAt: 1_700_000_061,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      await relay.startServer();

      await _publishFixtureEventToRelay(relay.url, deletionEvent);

      final fetchedDeletion = await ndk.requests
          .query(
            filter: Filter(
              authors: [remoteAuthor.publicKey],
              kinds: [Deletion.kKind],
              ids: [deletionEvent.id],
            ),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 1),
          )
          .future;
      expect(fetchedDeletion.map((e) => e.id), contains(deletionEvent.id));

      await _publishFixtureEventToRelay(relay.url, rootEvent);

      final targetFetch = await ndk.requests
          .query(
            filter: Filter(ids: [rootEvent.id]),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 1),
          )
          .future;
      expect(
        targetFetch.map((e) => e.id),
        isNot(contains(rootEvent.id)),
        reason:
            'Once a tombstone is known locally, a later fetch of that foreign target should already be suppressed at the public query layer.',
      );

      final localAfterLateTarget = await ndk.requests
          .query(
            filter: Filter(ids: [rootEvent.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;

      expect(
        localAfterLateTarget.map((e) => e.id),
        isNot(contains(rootEvent.id)),
        reason:
            'If the deletion arrived first, later sync of the deleted foreign target should remain suppressed instead of resurrecting locally.',
      );

      await relay.stopServer();
    });

    test(
        'relay refresh replaces stale cached metadata with the newest remote version',
        () async {
      final relay = MockRelay(name: 'metadata-convergence-relay');
      final remoteAuthor = Bip340.generatePrivateKey();
      final oldMetadataEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Metadata.kKind,
          tags: const [],
          content: jsonEncode({'name': 'old-name'}),
          createdAt: 1_700_000_070,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      final newMetadataEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Metadata.kKind,
          tags: const [],
          content: jsonEncode({'name': 'new-name'}),
          createdAt: 1_700_000_071,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      await relay
          .startServer(metadatas: {remoteAuthor.publicKey: oldMetadataEvent});

      final cachedOldMetadata = await ndk.metadata.loadMetadata(
        remoteAuthor.publicKey,
        forceRefresh: true,
        idleTimeout: const Duration(seconds: 1),
      );
      expect(cachedOldMetadata?.name, 'old-name');

      await relay.stopServer();
      await relay
          .startServer(metadatas: {remoteAuthor.publicKey: newMetadataEvent});

      final refreshedMetadata = await ndk.metadata.loadMetadata(
        remoteAuthor.publicKey,
        forceRefresh: true,
        idleTimeout: const Duration(seconds: 1),
      );
      expect(
        refreshedMetadata?.name,
        'new-name',
        reason:
            'A newer replaceable metadata event from the relay should overwrite the stale cached materialized view.',
      );

      final localCurrentMetadata =
          await ndk.metadata.loadMetadata(remoteAuthor.publicKey);
      expect(localCurrentMetadata?.name, 'new-name');

      await relay.stopServer();
    });

    test(
        'connected relay rejecting first should keep local visibility and later succeed via periodic retry',
        () async {
      final relay = MockRelay(
        name: 'retry-relay',
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

      final event = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'connected retry note',
        createdAt: 1_700_000_040,
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

      final event = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'permanent failure note',
        createdAt: 1_700_000_041,
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

    test(
        'network-backed interactive signer queues locally while signer transport relay is offline and publishes once that relay connects',
        () async {
      final publishRelay = MockRelay(name: 'signer-publish-relay');
      final signerRelay = MockRelay(name: 'signer-transport-relay');
      final signer = _ControllableInteractiveSigner(
        keyPair: authorKey,
        available: false,
        requiresSignerNetwork: true,
        transportRelayUrls: () => [signerRelay.url],
      );

      await publishRelay.startServer();
      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [publishRelay.url, signerRelay.url],
        pendingDeliveryRetryInterval: const Duration(seconds: 1),
      );
      ndk.accounts.loginExternalSigner(signer: signer);

      final event = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'network signer offline then online',
        createdAt: 1_700_000_080,
      );

      try {
        await ndk.broadcast
            .broadcast(
              nostrEvent: event,
              specificRelays: [publishRelay.url],
              timeout: const Duration(milliseconds: 300),
            )
            .broadcastDoneFuture;
      } catch (_) {}

      final localWhileSignerOffline = await _waitForCachedEvents(
        ndk: ndk,
        filter: Filter(ids: [event.id]),
      );
      expect(localWhileSignerOffline.map((e) => e.id), contains(event.id));

      await Future<void>.delayed(const Duration(seconds: 2));
      expect(
        publishRelay.receivedEvents.where((e) => e.id == event.id),
        isEmpty,
        reason:
            'While the network-backed signer transport relay is unavailable, local-first should keep the event queued without publishing to target relays.',
      );

      signer.available = true;
      await signerRelay.startServer();
      await ndk.connectivity.tryReconnect();
      await _waitForRelayConnected(
        ndk: ndk,
        relayUrl: signerRelay.url,
        timeout: const Duration(seconds: 10),
      );

      final relayAfterSignerTransportOnline = await _waitForRelayEvents(
        relay: publishRelay,
        filter: Filter(ids: [event.id]),
        timeout: const Duration(seconds: 10),
      );

      expect(
        relayAfterSignerTransportOnline.map((e) => e.id),
        contains(event.id),
        reason:
            'When the signer transport relay comes online, local-first should retry signing and then immediately publish to connected delivery relays.',
      );

      await publishRelay.stopServer();
      await signerRelay.stopServer();
    });

    test(
        'interactive signer queue survives restart and later signs plus publishes when signer becomes available',
        () async {
      final relay = MockRelay(name: 'interactive-restart-relay');
      final failingSigner = _ControllableInteractiveSigner(
        keyPair: authorKey,
        available: false,
        requiresSignerNetwork: false,
      );

      await relay.startServer();
      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [relay.url],
        pendingDeliveryRetryInterval: const Duration(seconds: 1),
      );
      ndk.accounts.loginExternalSigner(signer: failingSigner);

      final event = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'interactive signer restart persistence',
        createdAt: 1_700_000_081,
      );

      try {
        await ndk.broadcast
            .broadcast(
              nostrEvent: event,
              specificRelays: [relay.url],
              timeout: const Duration(milliseconds: 300),
            )
            .broadcastDoneFuture;
      } catch (_) {}

      final localBeforeRestart = await _waitForCachedEvents(
        ndk: ndk,
        filter: Filter(ids: [event.id]),
      );
      expect(localBeforeRestart.map((e) => e.id), contains(event.id));
      expect(
        relay.receivedEvents.where((e) => e.id == event.id),
        isEmpty,
        reason:
            'If interactive signing cannot complete yet, the event should remain local without being published.',
      );

      await ndk.destroy();

      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [relay.url],
        pendingDeliveryRetryInterval: const Duration(seconds: 1),
      );
      ndk.accounts.loginExternalSigner(
        signer: _ControllableInteractiveSigner(
          keyPair: authorKey,
          available: true,
          requiresSignerNetwork: false,
        ),
      );

      final localAfterRestart = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;
      expect(localAfterRestart.map((e) => e.id), contains(event.id));

      final relayAfterRestart = await _waitForRelayEvents(
        relay: relay,
        filter: Filter(ids: [event.id]),
        timeout: const Duration(seconds: 10),
      );

      expect(
        relayAfterRestart.map((e) => e.id),
        contains(event.id),
        reason:
            'Unsigned interactive-signing work should survive restart and later complete once a compatible signer becomes available again.',
      );

      await relay.stopServer();
    });

    test(
        'successful network signing while publish relay is offline should still deliver later when the target relay reconnects',
        () async {
      final publishRelay = MockRelay(name: 'signed-then-publish-later-relay');
      final signerRelay = MockRelay(name: 'signer-online-relay');
      final signer = _ControllableInteractiveSigner(
        keyPair: authorKey,
        available: true,
        requiresSignerNetwork: true,
        transportRelayUrls: () => [signerRelay.url],
      );

      await signerRelay.startServer();
      ndk = await _createNdk(
        tempDir.path,
        bootstrapRelays: [publishRelay.url, signerRelay.url],
        pendingDeliveryRetryInterval: const Duration(seconds: 1),
      );
      ndk.accounts.loginExternalSigner(signer: signer);

      await _waitForRelayConnected(
        ndk: ndk,
        relayUrl: signerRelay.url,
        timeout: const Duration(seconds: 10),
      );

      final event = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'signed now publish later',
        createdAt: 1_700_000_082,
      );

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [publishRelay.url],
            timeout: const Duration(milliseconds: 300),
          )
          .broadcastDoneFuture;

      final localSignedWhilePublishOffline = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            cacheRead: true,
            cacheWrite: false,
            timeout: const Duration(milliseconds: 300),
          )
          .future;
      expect(
          localSignedWhilePublishOffline.map((e) => e.id), contains(event.id));

      await Future<void>.delayed(const Duration(seconds: 2));
      expect(
        publishRelay.receivedEvents.where((e) => e.id == event.id),
        isEmpty,
        reason:
            'Even if signing succeeds immediately, target relay delivery should stay queued while the publish relay is still offline.',
      );

      await publishRelay.startServer();
      await _waitForRelayConnected(
        ndk: ndk,
        relayUrl: publishRelay.url,
        timeout: const Duration(seconds: 15),
      );

      final relayAfterPublishReconnect = await _waitForRelayEvents(
        relay: publishRelay,
        filter: Filter(ids: [event.id]),
        timeout: const Duration(seconds: 10),
      );

      expect(
        relayAfterPublishReconnect.map((e) => e.id),
        contains(event.id),
        reason:
            'After signing succeeded while the publish relay was offline, the queued signed event should later be delivered once that relay reconnects.',
      );

      await publishRelay.stopServer();
      await signerRelay.stopServer();
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

Future<void> _publishFixtureEventToRelay(
  String relayUrl,
  Nip01Event event,
) async {
  final socket = await WebSocket.connect(relayUrl);
  final completer = Completer<void>();

  late final StreamSubscription<dynamic> subscription;
  subscription = socket.listen(
    (message) {
      if (message is! String) {
        return;
      }

      final decoded = jsonDecode(message);
      if (decoded is! List || decoded.isEmpty || decoded[0] != 'OK') {
        return;
      }
      if (decoded.length < 4 || decoded[1] != event.id) {
        return;
      }

      if (decoded[2] == true) {
        completer.complete();
      } else {
        completer.completeError(
          StateError('Fixture relay rejected event ${event.id}: ${decoded[3]}'),
        );
      }
    },
    onError: completer.completeError,
  );

  socket.add(jsonEncode([
    'EVENT',
    {
      'id': event.id,
      'pubkey': event.pubKey,
      'created_at': event.createdAt,
      'kind': event.kind,
      'tags': event.tags,
      'content': event.content,
      'sig': event.sig,
    },
  ]));

  await completer.future.timeout(const Duration(seconds: 2));
  await subscription.cancel();
  await socket.close();
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

Future<List<Nip01Event>> _waitForCachedEvents({
  required Ndk ndk,
  required Filter filter,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final result = await ndk.requests
        .query(
          filter: filter,
          cacheRead: true,
          cacheWrite: false,
          timeout: const Duration(milliseconds: 300),
        )
        .future;
    if (result.isNotEmpty) {
      return result;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  return ndk.requests
      .query(
        filter: filter,
        cacheRead: true,
        cacheWrite: false,
        timeout: const Duration(milliseconds: 300),
      )
      .future;
}

Future<void> _waitForRelayConnected({
  required Ndk ndk,
  required String relayUrl,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final current = ndk.relays.getRelayConnectivity(relayUrl);
  if (current?.isConnected == true) {
    return;
  }

  await ndk.connectivity.relayConnectivityChanges
      .firstWhere(
        (relays) => relays[relayUrl]?.isConnected == true,
      )
      .timeout(timeout);
}

class _ControllableInteractiveSigner implements EventSigner {
  final KeyPair keyPair;
  final bool requiresSignerNetwork;
  final Iterable<String> Function() _transportRelayUrlsProvider;
  bool available;
  final Bip340EventSigner _innerSigner;

  _ControllableInteractiveSigner({
    required this.keyPair,
    required this.available,
    required this.requiresSignerNetwork,
    Iterable<String> Function()? transportRelayUrls,
  })  : _transportRelayUrlsProvider =
            transportRelayUrls ?? (() => const <String>[]),
        _innerSigner = Bip340EventSigner(
          privateKey: keyPair.privateKey!,
          publicKey: keyPair.publicKey,
        );

  @override
  bool get requiresInteractiveSigning => true;

  @override
  Iterable<String> get signerTransportRelayUrls =>
      _transportRelayUrlsProvider();

  @override
  bool canSign() => true;

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async =>
      null;

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async =>
      null;

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async =>
      null;

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async =>
      null;

  @override
  String getPublicKey() => keyPair.publicKey;

  @override
  List<PendingSignerRequest> get pendingRequests => const [];

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      const Stream.empty();

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    if (!available) {
      throw Exception(
        requiresSignerNetwork
            ? 'temporary network signer offline'
            : 'temporary interactive signer unavailable',
      );
    }

    return _innerSigner.sign(event);
  }
}
