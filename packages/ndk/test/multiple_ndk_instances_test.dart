import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import 'mocks/mock_relay.dart';

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  String reason = 'condition never became true',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail(reason);
}

Ndk _createNdk({List<String> bootstrapRelays = const []}) => Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        eventVerifier: Bip340EventVerifier(),
        bootstrapRelays: bootstrapRelays,
      ),
    );

void main() {
  group('multiple NDK instances', () {
    test('own independent runtime state', () async {
      final first = _createNdk();
      final second = _createNdk();

      expect(first.relays.globalState, isNot(same(second.relays.globalState)));

      first.relays.globalState.blockedRelays.add('wss://blocked.example');
      expect(second.relays.globalState.blockedRelays, isEmpty);

      await first.destroy();
      await second.destroy();
    });

    test(
      'destroying one instance leaves the other subscribed and connected',
      () async {
        final relay = MockRelay(name: 'multiple-ndk-lifecycle');
        await relay.startServer();

        final first = _createNdk(bootstrapRelays: [relay.url]);
        final second = _createNdk(bootstrapRelays: [relay.url]);
        var secondDestroyed = false;

        try {
          await Future.wait([
            first.relays.seedRelaysConnected,
            second.relays.seedRelaysConnected,
          ]);
          await _waitUntil(
            () => relay.connectedClientCount == 2,
            reason: 'each NDK instance did not open its own relay connection',
          );

          final key = Bip340.generatePrivateKey();
          final receivedByFirst = Completer<Nip01Event>();
          final firstSubscription = first.requests.subscription(
            id: 'same-subscription-id',
            filter: Filter(
              kinds: [Nip01Event.kTextNodeKind],
              authors: [key.publicKey],
            ),
            explicitRelays: [relay.url],
          );
          firstSubscription.stream.listen((event) {
            if (!receivedByFirst.isCompleted) receivedByFirst.complete(event);
          });

          second.requests.subscription(
            id: 'same-subscription-id',
            filter: Filter(
              kinds: [Nip01Event.kTextNodeKind],
              authors: [key.publicKey],
            ),
            explicitRelays: [relay.url],
          );

          await _waitUntil(
            () => relay.activeSubscriptionCount == 2,
            reason: 'both NDK subscriptions were not registered',
          );

          secondDestroyed = true;
          await second.destroy();

          await _waitUntil(
            () =>
                relay.connectedClientCount == 1 &&
                relay.activeSubscriptionCount == 1,
            reason: 'destroying the second NDK affected the first NDK runtime',
          );

          first
              .relays
              .globalState
              .relays[RelayConnectionKey.anonymous(relay.url)]!
              .relay
              .lastConnectTry = 0;
          await relay.closeClientSockets();
          await _waitUntil(
            () =>
                relay.connectedClientCount == 1 &&
                relay.activeSubscriptionCount == 1,
            reason: 'the destroyed NDK reconnected or the live NDK did not',
          );

          final event = Nip01Utils.signWithPrivateKey(
            event: Nip01Event(
              pubKey: key.publicKey,
              kind: Nip01Event.kTextNodeKind,
              tags: const [],
              content: 'first instance remains live',
            ),
            privateKey: key.privateKey!,
          );
          await first.broadcast.broadcast(
              nostrEvent: event,
              specificRelays: [relay.url]).broadcastDoneFuture;

          expect(
            (await receivedByFirst.future.timeout(const Duration(seconds: 2)))
                .id,
            event.id,
          );
        } finally {
          if (!secondDestroyed) await second.destroy();
          await first.destroy();
          await relay.stopServer();
        }
      },
    );

    test('broadcast acknowledgements cannot cross instances', () async {
      final acceptingRelay = MockRelay(name: 'multiple-ndk-accept');
      final rejectingRelay = MockRelay(
        name: 'multiple-ndk-reject',
        rejectFirstEventPublishes: 1,
        rejectEventMessage: 'blocked: test rejection',
      );
      await acceptingRelay.startServer(
        delayResponse: const Duration(milliseconds: 300),
      );
      await rejectingRelay.startServer();

      final first = _createNdk(bootstrapRelays: [acceptingRelay.url]);
      final second = _createNdk(bootstrapRelays: [rejectingRelay.url]);

      try {
        await Future.wait([
          first.relays.seedRelaysConnected,
          second.relays.seedRelaysConnected,
        ]);

        final key = Bip340.generatePrivateKey();
        final event = Nip01Utils.signWithPrivateKey(
          event: Nip01Event(
            pubKey: key.publicKey,
            kind: Nip01Event.kTextNodeKind,
            tags: const [],
            content: 'same event, independent broadcasts',
          ),
          privateKey: key.privateKey!,
        );

        final accepted = first.broadcast.broadcast(
          nostrEvent: event,
          specificRelays: [acceptingRelay.url],
          timeout: const Duration(seconds: 2),
        );
        final rejected = second.broadcast.broadcast(
          nostrEvent: event,
          specificRelays: [rejectingRelay.url],
          timeout: const Duration(seconds: 2),
        );

        final results = await Future.wait([
          accepted.broadcastDoneFuture,
          rejected.broadcastDoneFuture,
        ]);

        expect(results[0], hasLength(1));
        expect(results[0].single.relayUrl, acceptingRelay.url);
        expect(results[0].single.broadcastSuccessful, isTrue);
        expect(results[1], hasLength(1));
        expect(results[1].single.relayUrl, rejectingRelay.url);
        expect(results[1].single.broadcastSuccessful, isFalse);
      } finally {
        await first.destroy();
        await second.destroy();
        await acceptingRelay.stopServer();
        await rejectingRelay.stopServer();
      }
    });

    test('NIP-42 authentication uses each instance account', () async {
      final relay = MockRelay(
        name: 'multiple-ndk-auth',
        requireAuthForRequests: true,
        signEvents: false,
        challengePerConnection: true,
      );
      final noteKey = Bip340.generatePrivateKey();
      final note = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: noteKey.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: const [],
          content: 'authenticated result',
        ),
        privateKey: noteKey.privateKey!,
      );
      await relay.startServer(textNotes: {noteKey: note});

      final firstKey = Bip340.generatePrivateKey();
      final secondKey = Bip340.generatePrivateKey();
      final first = _createNdk(bootstrapRelays: [relay.url]);
      final second = _createNdk(bootstrapRelays: [relay.url]);

      try {
        first.accounts.loginPrivateKey(
          pubkey: firstKey.publicKey,
          privkey: firstKey.privateKey!,
        );
        second.accounts.loginPrivateKey(
          pubkey: secondKey.publicKey,
          privkey: secondKey.privateKey!,
        );

        await Future.wait([
          first.relays.seedRelaysConnected,
          second.relays.seedRelaysConnected,
        ]);

        final results = await Future.wait([
          first.requests.query(
            filter: Filter(ids: [note.id]),
            explicitRelays: [relay.url],
            authenticateAs: [first.accounts.getLoggedAccount()!],
          ).future,
          second.requests.query(
            filter: Filter(ids: [note.id]),
            explicitRelays: [relay.url],
            authenticateAs: [second.accounts.getLoggedAccount()!],
          ).future,
        ]);

        expect(results[0].map((event) => event.id), contains(note.id));
        expect(results[1].map((event) => event.id), contains(note.id));
        expect(relay.connectionsAuthenticatedAs(firstKey.publicKey), 1);
        expect(relay.connectionsAuthenticatedAs(secondKey.publicKey), 1);

        final firstConnectionKeys = first.relays.globalState.relays.keys;
        final secondConnectionKeys = second.relays.globalState.relays.keys;
        expect(
          firstConnectionKeys,
          contains(RelayConnectionKey.authenticated(
            relay.url,
            firstKey.publicKey,
          )),
        );
        expect(
          firstConnectionKeys,
          isNot(contains(RelayConnectionKey.authenticated(
            relay.url,
            secondKey.publicKey,
          ))),
        );
        expect(
          secondConnectionKeys,
          contains(RelayConnectionKey.authenticated(
            relay.url,
            secondKey.publicKey,
          )),
        );
        expect(
          secondConnectionKeys,
          isNot(contains(RelayConnectionKey.authenticated(
            relay.url,
            firstKey.publicKey,
          ))),
        );
      } finally {
        await first.destroy();
        await second.destroy();
        await relay.stopServer();
      }
    });
  });
}
