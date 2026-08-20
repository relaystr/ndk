import 'dart:async';

import 'package:ndk/domain_layer/usecases/requests/verify_event_stream.dart';
import 'package:ndk/domain_layer/usecases/requests/verified_event_cache.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

/// counts how often each event id is handed to the verifier
class CountingEventVerifier implements EventVerifier {
  final Map<String, int> counts = {};
  final EventVerifier delegate;

  CountingEventVerifier({EventVerifier? delegate})
      : delegate = delegate ?? Bip340EventVerifier(useIsolate: false);

  int countFor(String id) => counts[id] ?? 0;

  void reset() => counts.clear();

  @override
  Future<bool> verify(Nip01Event event) async {
    counts.update(event.id, (count) => count + 1, ifAbsent: () => 1);
    return delegate.verify(event);
  }
}

class ControlledEventVerifier implements EventVerifier {
  final Completer<void> started = Completer<void>();
  final Completer<bool> result = Completer<bool>();

  @override
  Future<bool> verify(Nip01Event event) {
    if (!started.isCompleted) {
      started.complete();
    }
    return result.future;
  }
}

class CountingMemCacheManager extends MemCacheManager {
  final Map<String, int> saveIfAbsentCounts = {};

  int saveIfAbsentCountFor(String id) => saveIfAbsentCounts[id] ?? 0;

  void resetSaveIfAbsentCounts() => saveIfAbsentCounts.clear();

  @override
  Future<bool> saveEventIfAbsent(Nip01Event event) async {
    saveIfAbsentCounts.update(
      event.id,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    return super.saveEventIfAbsent(event);
  }
}

void main() async {
  late KeyPair key1;
  late Bip340EventSigner signer;
  late CountingEventVerifier verifier;
  late MockRelay relay1;
  late MockRelay relay2;
  late CountingMemCacheManager cache;
  late Ndk ndk;

  Future<Nip01Event> signedEvent(String content, int createdAt) => signer.sign(
        Nip01Event(
          kind: Nip01Event.kTextNodeKind,
          pubKey: key1.publicKey,
          content: content,
          tags: [],
          createdAt: createdAt,
        ),
      );

  Future<void> receiveAndCacheFromRelay1(Nip01Event event) async {
    final broadcast = ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: [relay1.url],
    );
    await broadcast.broadcastDoneFuture;

    await ndk.config.cache.clearAll();
    verifier.reset();

    final received = await ndk.requests
        .query(
          filter: Filter(ids: [event.id]),
          explicitRelays: [relay1.url],
          cacheRead: false,
        )
        .future;

    expect(received, hasLength(1));
    expect(received.single.id, event.id);
    expect(verifier.countFor(event.id), 1);
  }

  setUp(() async {
    key1 = Bip340.generatePrivateKey();
    signer = Bip340EventSigner(
      privateKey: key1.privateKey,
      publicKey: key1.publicKey,
    );
    verifier = CountingEventVerifier();
    cache = CountingMemCacheManager();

    relay1 = MockRelay(name: "relay 1", explicitPort: 6090);
    relay2 = MockRelay(name: "relay 2", explicitPort: 6091);
    await relay1.startServer();
    await relay2.startServer();

    ndk = Ndk(
      NdkConfig(
        eventVerifier: verifier,
        cache: cache,
        bootstrapRelays: [relay1.url, relay2.url],
        logLevel: LogLevel.off,
      ),
    );
    ndk.accounts.loginExternalSigner(signer: signer);
  });

  tearDown(() async {
    await ndk.destroy();
    await relay1.stopServer();
    await relay2.stopServer();
  });

  group('re-verification of already verified events (issue #715)', () {
    test('bounds LRU entries by id and signature pair', () {
      final verificationCache = VerifiedEventMemCache(maxSize: 2);

      verificationCache.markVerified('event-1', 'signature-1');
      verificationCache.markVerified('event-1', 'signature-2');

      expect(
        verificationCache.hasVerifiedSignature('event-1', 'signature-1'),
        isTrue,
      );

      verificationCache.markVerified('event-2', 'signature-3');

      expect(
        verificationCache.hasVerifiedSignature('event-1', 'signature-1'),
        isTrue,
      );
      expect(
        verificationCache.hasVerifiedSignature('event-1', 'signature-2'),
        isFalse,
      );
      expect(
        verificationCache.hasVerifiedSignature('event-2', 'signature-3'),
        isTrue,
      );
    });

    test('clear prevents pending verification from repopulating the cache',
        () async {
      final verificationCache = VerifiedEventMemCache();
      verificationCache.markVerified('existing-id', 'existing-signature');

      final event = await signedEvent('pending during clear', 1000);
      final controlledVerifier = ControlledEventVerifier();
      final verification = verificationCache.verifyOnce(
        event,
        controlledVerifier,
      );
      await controlledVerifier.started.future;

      verificationCache.clear();

      expect(
        verificationCache.hasVerifiedSignature(
          'existing-id',
          'existing-signature',
        ),
        isFalse,
      );

      controlledVerifier.result.complete(true);
      expect(await verification, isTrue);
      expect(
        verificationCache.hasVerifiedSignature(event.id, event.sig),
        isFalse,
      );
    });

    test('does not re-verify an event delivered more than once', () async {
      final event = await signedEvent("duplicate", 1000);

      final results = await VerifyEventStream(
        unverifiedStreamInput: Stream.fromIterable([event, event, event]),
        eventVerifier: verifier,
      )()
          .toList();

      expect(results.length, equals(3));
      expect(
        verifier.countFor(event.id),
        equals(1),
        reason: 'an event already verified should not be verified again',
      );
    });

    test('does not verify an event that already carries validSig true',
        () async {
      final event = (await signedEvent("cached", 1000)).copyWith(
        validSig: true,
      );

      await VerifyEventStream(
        unverifiedStreamInput: Stream.fromIterable([event]),
        eventVerifier: verifier,
      )()
          .toList();

      expect(
        verifier.countFor(event.id),
        equals(0),
        reason: 'validSig true means the signature was already checked',
      );
    });

    test(
      'does not trust a concurrent duplicate before verification rejects it',
      () async {
        final event = (await signedEvent('invalid duplicate', 1000)).copyWith(
          sig: List.filled(128, '0').join(),
        );
        final controlledVerifier = ControlledEventVerifier();
        final localVerifier = CountingEventVerifier(
          delegate: controlledVerifier,
        );
        final emitted = <Nip01Event>[];
        final errors = <Object>[];
        final done = Completer<void>();

        VerifyEventStream(
          unverifiedStreamInput: Stream.fromIterable([event, event]),
          eventVerifier: localVerifier,
        )()
            .listen(
          emitted.add,
          onError: (Object error) => errors.add(error),
          onDone: done.complete,
        );

        await controlledVerifier.started.future;
        await Future<void>.delayed(Duration.zero);

        expect(localVerifier.countFor(event.id), 1);
        expect(
          emitted,
          isEmpty,
          reason: 'the duplicate must wait for the shared verification future',
        );

        controlledVerifier.result.complete(false);
        await done.future;

        expect(emitted, isEmpty);
        expect(errors, isEmpty);
        expect(localVerifier.countFor(event.id), 1);
      },
    );

    test(
      'does not trust a concurrent duplicate when verification throws',
      () async {
        final event = (await signedEvent('throwing duplicate', 1000)).copyWith(
          sig: List.filled(128, '0').join(),
        );
        final controlledVerifier = ControlledEventVerifier();
        final localVerifier = CountingEventVerifier(
          delegate: controlledVerifier,
        );
        final emitted = <Nip01Event>[];
        final errors = <Object>[];
        final done = Completer<void>();

        VerifyEventStream(
          unverifiedStreamInput: Stream.fromIterable([event, event]),
          eventVerifier: localVerifier,
        )()
            .listen(
          emitted.add,
          onError: (Object error) => errors.add(error),
          onDone: done.complete,
        );

        await controlledVerifier.started.future;
        await Future<void>.delayed(Duration.zero);

        expect(localVerifier.countFor(event.id), 1);
        expect(
          emitted,
          isEmpty,
          reason: 'the duplicate must not escape while verification is pending',
        );

        controlledVerifier.result.completeError(
          StateError('verification failed'),
        );
        await done.future;

        expect(emitted, isEmpty);
        expect(errors, isNotEmpty);
        expect(errors, everyElement(isA<StateError>()));
        expect(localVerifier.countFor(event.id), 1);
      },
    );

    test('verifies an event once when two relays deliver it', () async {
      final event = await signedEvent("shared", 1000);

      for (final url in [relay1.url, relay2.url]) {
        final response = ndk.broadcast.broadcast(
          nostrEvent: event,
          specificRelays: [url],
        );
        await response.broadcastDoneFuture;
      }

      await ndk.config.cache.clearAll();
      verifier.reset();
      cache.resetSaveIfAbsentCounts();

      final events = await ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
        explicitRelays: [relay1.url, relay2.url],
      ).future;

      expect(events.length, equals(1));
      expect(
        verifier.countFor(event.id),
        equals(1),
        reason: 'the second copy should be deduplicated before verification',
      );
      expect(
        cache.saveIfAbsentCountFor(event.id),
        1,
        reason: 'persistence should run once within a single request',
      );
      expect(
        await cache.loadEventSources(event.id),
        containsAll([relay1.url, relay2.url]),
        reason: 'persistence deduplication must not discard relay provenance',
      );
    });

    test('does not re-verify an event a previous request verified', () async {
      final event = await signedEvent("re-requested", 1000);
      final response = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relay1.url],
      );
      await response.broadcastDoneFuture;

      await ndk.config.cache.clearAll();
      verifier.reset();
      cache.resetSaveIfAbsentCounts();

      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
      );

      await ndk.requests
          .query(
            filter: filter,
            explicitRelays: [relay1.url],
            cacheRead: false,
          )
          .future;
      await ndk.requests
          .query(
            filter: filter,
            explicitRelays: [relay1.url],
            cacheRead: false,
          )
          .future;

      expect(
        verifier.countFor(event.id),
        equals(1),
        reason: 'an event verified by a previous request stays verified',
      );
      expect(
        cache.saveIfAbsentCountFor(event.id),
        2,
        reason: 'each request performs its own insert-if-absent attempt',
      );
    });

    test(
      'does not return or cache a verified id with tampered content',
      () async {
        final event = await signedEvent('canonical content', 1000);
        await receiveAndCacheFromRelay1(event);

        final forgedEvent = event.copyWith(content: 'forged content');
        relay2.textNotes = {key1: forgedEvent};

        final received = await ndk.requests
            .query(
              filter: Filter(ids: [event.id]),
              explicitRelays: [relay2.url],
              cacheRead: false,
            )
            .future;

        final cached = await ndk.config.cache.loadEvent(event.id);
        expect(cached, isNotNull);
        expect(cached!.content, event.content);
        expect(cached.sig, event.sig);
        expect(
          verifier.countFor(event.id),
          1,
          reason: 'an invalid id should be rejected before signature checking',
        );

        expect(
          received,
          isEmpty,
          reason: 'an event whose payload does not hash to its id is invalid',
        );
      },
    );

    test(
      'does not return or cache a verified id with an invalid signature',
      () async {
        final event = await signedEvent('canonical signature', 1000);
        await receiveAndCacheFromRelay1(event);

        final forgedEvent = event.copyWith(
          sig: List.filled(128, '0').join(),
        );
        relay2.textNotes = {key1: forgedEvent};

        final received = await ndk.requests
            .query(
              filter: Filter(ids: [event.id]),
              explicitRelays: [relay2.url],
              cacheRead: false,
            )
            .future;

        final cached = await ndk.config.cache.loadEvent(event.id);
        expect(cached, isNotNull);
        expect(cached!.content, event.content);
        expect(cached.sig, event.sig);
        expect(
          verifier.countFor(event.id),
          2,
          reason: 'a different signature must be verified before reuse',
        );

        expect(
          received,
          isEmpty,
          reason: 'a cached id must not validate a different signature',
        );
      },
    );

    test(
      'checks persistence again for a cached event in a later request',
      () async {
        final event = await signedEvent('valid relay duplicate', 1000);
        await receiveAndCacheFromRelay1(event);

        final cachedBefore = await ndk.config.cache.loadEvent(event.id);
        expect(cachedBefore, isNotNull);
        cache.resetSaveIfAbsentCounts();

        relay2.textNotes = {key1: event};

        final received = await ndk.requests
            .query(
              filter: Filter(ids: [event.id]),
              explicitRelays: [relay2.url],
              cacheRead: false,
            )
            .future;

        expect(received, hasLength(1));
        expect(received.single.id, event.id);
        expect(
          cache.saveIfAbsentCountFor(event.id),
          1,
          reason: 'the first occurrence in each request checks persistence',
        );

        final cachedAfter = await ndk.config.cache.loadEvent(event.id);
        expect(cachedAfter, isNotNull);
        expect(cachedAfter!.content, cachedBefore!.content);
        expect(cachedAfter.sig, cachedBefore.sig);

        final sources = await ndk.config.cache.loadEventSources(event.id);
        expect(sources, containsAll([relay1.url, relay2.url]));
      },
    );

    test('stores a verified duplicate again after the cache is cleared',
        () async {
      final event = await signedEvent('valid duplicate after clear', 1000);
      await receiveAndCacheFromRelay1(event);

      await cache.clearAll();
      cache.resetSaveIfAbsentCounts();
      relay2.textNotes = {key1: event};

      final received = await ndk.requests
          .query(
            filter: Filter(ids: [event.id]),
            explicitRelays: [relay2.url],
            cacheRead: false,
          )
          .future;

      expect(received, hasLength(1));
      expect(verifier.countFor(event.id), 1);
      expect(cache.saveIfAbsentCountFor(event.id), 1);
      expect(await cache.loadEvent(event.id), isNotNull);
    });
  });
}
