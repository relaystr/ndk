import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip09/deletion.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  group('local first subscription public api', () {
    late Directory tempDir;
    late Ndk ndk;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'local_first_subscription',
      );
    });

    tearDown(() async {
      await ndk.destroy();
      await tempDir.delete(recursive: true);
    });

    test(
        'cache-backed subscription emits cached event first and later continues with live relay updates',
        () async {
      final relay = MockRelay(
        name: 'subscription-relay',
        explicitPort: await _reservePort(),
      );
      final remoteAuthor = Bip340.generatePrivateKey();
      final cachedEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'cached event',
          createdAt: 1_700_000_080,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      final liveEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'live event',
          createdAt: 1_700_000_081,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      await relay.startServer(textNotes: {remoteAuthor: cachedEvent});

      final initiallyCached = await ndk.requests
          .query(
            filter: Filter(ids: [cachedEvent.id]),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 4),
          )
          .future;
      expect(initiallyCached.map((e) => e.id), contains(cachedEvent.id));

      final receivedEvents = <Nip01Event>[];
      final cachedSeen = Completer<void>();
      final liveSeen = Completer<void>();
      final subscription = ndk.requests.subscription(
        filter: Filter(
          authors: [remoteAuthor.publicKey],
          kinds: [Nip01Event.kTextNodeKind],
        ),
        cacheRead: true,
        cacheWrite: true,
        explicitRelays: [relay.url],
      );
      final sub = subscription.stream.listen((event) {
        receivedEvents.add(event);
        if (event.id == cachedEvent.id && !cachedSeen.isCompleted) {
          cachedSeen.complete();
        }
        if (event.id == liveEvent.id && !liveSeen.isCompleted) {
          liveSeen.complete();
        }
      });
      addTearDown(sub.cancel);

      await cachedSeen.future.timeout(const Duration(seconds: 2));

      await _publishFixtureEventToRelay(relay.url, liveEvent);
      await liveSeen.future.timeout(const Duration(seconds: 2));

      expect(receivedEvents.map((e) => e.id), contains(cachedEvent.id));
      expect(receivedEvents.map((e) => e.id), contains(liveEvent.id));

      await relay.stopServer();
    });

    test(
        'cache-backed subscription does not emit tombstoned foreign events or resurrect them later',
        () async {
      final relay =
          MockRelay(
            name: 'subscription-delete-relay',
            explicitPort: await _reservePort(),
          );
      final remoteAuthor = Bip340.generatePrivateKey();
      final targetEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'deleted target',
          createdAt: 1_700_000_090,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      final deletionEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Deletion.kKind,
          tags: [
            ['e', targetEvent.id],
            ['k', targetEvent.kind.toString()],
          ],
          content: 'delete target',
          createdAt: 1_700_000_091,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      await relay.startServer(textNotes: {remoteAuthor: targetEvent});

      final cachedTarget = await ndk.requests
          .query(
            filter: Filter(ids: [targetEvent.id]),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 1),
          )
          .future;
      expect(cachedTarget.map((e) => e.id), contains(targetEvent.id));

      await _publishFixtureEventToRelay(relay.url, deletionEvent);
      final syncedDeletion = await ndk.requests
          .query(
            filter: Filter(ids: [deletionEvent.id], kinds: [Deletion.kKind]),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 1),
          )
          .future;
      expect(syncedDeletion.map((e) => e.id), contains(deletionEvent.id));

      final emittedEvents = <Nip01Event>[];
      final subscription = ndk.requests.subscription(
        filter: Filter(ids: [targetEvent.id]),
        cacheRead: true,
        cacheWrite: true,
        explicitRelays: [relay.url],
      );
      final sub = subscription.stream.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(emittedEvents, isEmpty);

      await _publishFixtureEventToRelay(relay.url, targetEvent);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(
        emittedEvents.map((e) => e.id),
        isNot(contains(targetEvent.id)),
        reason:
            'A tombstoned foreign target should stay suppressed on the public reactive stream even if replayed later.',
      );

      await relay.stopServer();
    });

    test(
        'cache-backed subscription emits cached replaceable winner then newer live replacement but not stale late event',
        () async {
      final relay =
          MockRelay(
            name: 'subscription-replaceable-relay',
            explicitPort: await _reservePort(),
          );
      final remoteAuthor = Bip340.generatePrivateKey();
      final writerNdk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [relay.url],
        ),
      );
      addTearDown(writerNdk.destroy);
      final cachedVersion = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Metadata.kKind,
          tags: const [],
          content: jsonEncode({'name': 'version-1'}),
          createdAt: 1_700_000_100,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      final newerVersion = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Metadata.kKind,
          tags: const [],
          content: jsonEncode({'name': 'version-2'}),
          createdAt: 1_700_000_101,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      final staleVersion = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: remoteAuthor.publicKey,
          kind: Metadata.kKind,
          tags: const [],
          content: jsonEncode({'name': 'version-0'}),
          createdAt: 1_700_000_099,
        ),
        privateKey: remoteAuthor.privateKey!,
      );
      ndk = await _createNdk(tempDir.path, bootstrapRelays: [relay.url]);

      await relay.startServer(
        metadatas: {remoteAuthor.publicKey: cachedVersion},
      );

      final cachedLoad = await ndk.requests
          .query(
            filter: Filter(
              authors: [remoteAuthor.publicKey],
              kinds: [Metadata.kKind],
            ),
            explicitRelays: [relay.url],
            timeout: const Duration(seconds: 1),
          )
          .future;
      expect(cachedLoad.map((e) => e.id), contains(cachedVersion.id));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final receivedContents = <String>[];
      final cachedSeen = Completer<void>();
      final newerSeen = Completer<void>();
      final subscription = ndk.requests.subscription(
        filter: Filter(
          authors: [remoteAuthor.publicKey],
          kinds: [Metadata.kKind],
        ),
        cacheRead: true,
        cacheWrite: true,
        explicitRelays: [relay.url],
      );
      final sub = subscription.stream.listen((event) {
        receivedContents.add(event.content);
        if (event.id == cachedVersion.id && !cachedSeen.isCompleted) {
          cachedSeen.complete();
        }
        if (event.id == newerVersion.id && !newerSeen.isCompleted) {
          newerSeen.complete();
        }
      });
      addTearDown(sub.cancel);

      await cachedSeen.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await writerNdk.broadcast.broadcast(
        nostrEvent: newerVersion,
        specificRelays: [relay.url],
      ).broadcastDoneFuture;
      await newerSeen.future.timeout(const Duration(seconds: 2));

      await writerNdk.broadcast.broadcast(
        nostrEvent: staleVersion,
        specificRelays: [relay.url],
      ).broadcastDoneFuture;
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(receivedContents, contains(jsonEncode({'name': 'version-1'})));
      expect(receivedContents, contains(jsonEncode({'name': 'version-2'})));
      expect(
        receivedContents,
        isNot(contains(jsonEncode({'name': 'version-0'}))),
        reason:
            'A stale replaceable event that arrives after a newer winner should not be emitted on the local-first reactive stream.',
      );

      await relay.stopServer();
    });
  });
}

Future<int> _reservePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<Ndk> _createNdk(
  String databasePath, {
  List<String> bootstrapRelays = const [],
}) async {
  final cache = await SembastCacheManager.create(databasePath: databasePath);
  return Ndk(
    NdkConfig(
      cache: cache,
      eventVerifier: MockEventVerifier(),
      bootstrapRelays: bootstrapRelays,
      ignoreRelays: const [],
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
