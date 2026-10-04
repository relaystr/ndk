import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../../mocks/mock_relay.dart';

void main() async {
  group('NIP-77 timeouts', () {
    const portBase = 4310;
    const itemCount = 4000;

    String idOf(int i) => i.toRadixString(16).padLeft(64, '0');

    /// the client holds every other event, which takes more than one round to
    /// reconcile. Ids the cache does not know are reconciled at created_at 0,
    /// so the relay stores them that way too
    final localIds = [for (var i = 0; i < itemCount; i += 2) idOf(i)];

    Future<MockRelay> negentropyRelay(
      int port, {
      Duration? delayResponse,
    }) async {
      final relay = MockRelay(
        name: "neg relay",
        explicitPort: port,
        signEvents: false,
      );
      for (var i = 0; i < itemCount; i++) {
        relay.negentropyItems[idOf(i)] = 0;
      }
      await relay.startServer(delayResponse: delayResponse);
      return relay;
    }

    Ndk ndkFor(MockRelay relay) => Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [relay.url],
      ),
    );

    Nip77Response reconcile(
      Ndk ndk,
      MockRelay relay, {
      required Duration openTimeout,
      required Duration idleTimeout,
    }) => ndk.nip77.reconcile(
      relayUrl: relay.url,
      filter: Filter(kinds: [Nip01Event.kTextNodeKind]),
      localIds: localIds,
      openTimeout: openTimeout,
      idleTimeout: idleTimeout,
    );

    test('a reconciliation that keeps progressing has no deadline', () async {
      final relay = await negentropyRelay(
        portBase,
        delayResponse: Duration(milliseconds: 700),
      );
      final ndk = ndkFor(relay);
      await Future.delayed(Duration(seconds: 1));

      final stopwatch = Stopwatch()..start();
      final result = await reconcile(
        ndk,
        relay,
        openTimeout: Duration(seconds: 1),
        idleTimeout: Duration(seconds: 1),
      ).future;

      expect(result.needIds, hasLength(itemCount ~/ 2));
      expect(relay.negentropyAnswers, greaterThanOrEqualTo(2));
      expect(
        stopwatch.elapsed,
        greaterThan(Duration(seconds: 1)),
        reason: 'the session outlived both timeouts, so neither caps it',
      );

      await ndk.destroy();
      await relay.stopServer();
    });

    test('a relay that never answers NEG-OPEN times out', () async {
      final relay = await negentropyRelay(portBase + 1)
        ..silenceNegentropyAfter = 0;
      final ndk = ndkFor(relay);
      await Future.delayed(Duration(seconds: 1));

      final response = reconcile(
        ndk,
        relay,
        openTimeout: Duration(seconds: 1),
        idleTimeout: Duration(seconds: 5),
      );

      await expectLater(
        response.future,
        throwsA(
          isA<Nip77TimeoutException>()
              .having((e) => e.openUnanswered, 'openUnanswered', isTrue)
              .having((e) => e.timeout, 'timeout', Duration(seconds: 1)),
        ),
      );

      await ndk.destroy();
      await relay.stopServer();
    });

    test('a relay that goes silent between two rounds times out', () async {
      final relay = await negentropyRelay(portBase + 2)
        ..silenceNegentropyAfter = 1;
      final ndk = ndkFor(relay);
      await Future.delayed(Duration(seconds: 1));

      final response = reconcile(
        ndk,
        relay,
        openTimeout: Duration(seconds: 5),
        idleTimeout: Duration(seconds: 1),
      );

      await expectLater(
        response.future,
        throwsA(
          isA<Nip77TimeoutException>()
              .having((e) => e.openUnanswered, 'openUnanswered', isFalse)
              .having((e) => e.timeout, 'timeout', Duration(seconds: 1)),
        ),
      );

      await ndk.destroy();
      await relay.stopServer();
    });
  });
}
