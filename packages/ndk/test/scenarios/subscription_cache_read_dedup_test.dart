import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

/// Both tests use `cacheRead: true` on a subscription, which is not the default.
/// They probe what the concurrency check does once subscriptions become
/// eligible for it.
void main() {
  group('subscription with cacheRead enabled', () {
    late MockRelay queryRelay;
    late MockRelay subscriptionRelay;

    setUp(() async {
      queryRelay = MockRelay(name: "query relay");
      subscriptionRelay = MockRelay(name: "subscription relay");
      await queryRelay.startServer();
      await subscriptionRelay.startServer();
    });

    tearDown(() async {
      await queryRelay.stopServer();
      await subscriptionRelay.stopServer();
    });

    Future<void> waitForSubscriptionRegistration(MockRelay relay) async {
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (DateTime.now().isBefore(deadline)) {
        if (relay.activeSubscriptionCount > 0) return;
        await Future.delayed(const Duration(milliseconds: 25));
      }
      throw TimeoutException('MockRelay did not register the subscription.');
    }

    Ndk createNdk() => Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        eventVerifier: MockEventVerifier(),
        bootstrapRelays: [queryRelay.url, subscriptionRelay.url],
      ),
    );

    test(
      'keeps receiving live events when a query shares its filter',
      () async {
        final key = Bip340.generatePrivateKey();

        final ndk = createNdk();
        addTearDown(ndk.destroy);

        final publisher = createNdk();
        addTearDown(publisher.destroy);

        final filter = Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key.publicKey],
        );

        // query first so it owns the in-flight entry for this filter
        final query = ndk.requests.query(
          filter: filter.clone(),
          explicitRelays: [queryRelay.url],
        );
        final subscription = ndk.requests.subscription(
          filter: filter.clone(),
          explicitRelays: [subscriptionRelay.url],
          cacheRead: true,
        );

        final liveEvent = Completer<Nip01Event>();
        subscription.stream.listen((event) {
          if (!liveEvent.isCompleted) liveEvent.complete(event);
        });

        await query.future;
        await waitForSubscriptionRegistration(subscriptionRelay);

        final event = Nip01Utils.signWithPrivateKey(
          event: Nip01Event(
            pubKey: key.publicKey,
            kind: Nip01Event.kTextNodeKind,
            tags: [],
            content: 'event published after the query finished',
          ),
          privateKey: key.privateKey!,
        );

        await publisher.broadcast
            .broadcast(
              nostrEvent: event,
              specificRelays: [subscriptionRelay.url],
            )
            .broadcastDoneFuture;

        final received = await liveEvent.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException(
            'subscription received no live event: it was merged into the query '
            'and closed at EOSE',
          ),
        );

        expect(received.id, equals(event.id));
      },
    );

    test('does not stall a query that shares its filter', () async {
      final key = Bip340.generatePrivateKey();

      final ndk = createNdk();
      addTearDown(ndk.destroy);

      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key.publicKey],
      );

      // same relay on both, so only the request lifetime differs
      final subscription = ndk.requests.subscription(
        filter: filter.clone(),
        explicitRelays: [queryRelay.url],
        cacheRead: true,
      );
      subscription.stream.listen((_) {});

      await waitForSubscriptionRegistration(queryRelay);

      final events = await ndk.requests
          .query(filter: filter.clone(), explicitRelays: [queryRelay.url])
          .future
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException(
              'query never completed: it was merged into a subscription stream '
              'that never closes, and its own timeout was cancelled',
            ),
          );

      expect(events, isEmpty);
    });
  });
}
