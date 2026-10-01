import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() {
  for (final engine in NdkEngine.values) {
    authHandlerTests(engine);
  }
  nip77AuthHandlerTests();
}

Nip01Event _textNote(KeyPair key, String content) =>
    Nip01Utils.signWithPrivateKey(
      event: Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key.publicKey,
        content: content,
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      privateKey: key.privateKey!,
    );

Account _signable(KeyPair key) => Account(
      pubkey: key.publicKey,
      type: AccountType.privateKey,
      signer: Bip340EventSigner(
        privateKey: key.privateKey!,
        publicKey: key.publicKey,
      ),
    );

Filter _notesOf(KeyPair key) =>
    Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key.publicKey]);

/// Records every question and answers with [answer].
class _Handler {
  final FutureOr<bool> Function(String url) answer;
  final List<(String, String)> asked = [];

  _Handler(this.answer);

  Future<bool> call(String url, String pubkey) async {
    asked.add((url, pubkey));
    return answer(url);
  }
}

void authHandlerTests(NdkEngine engine) {
  group('AuthHandler [${engine.name}]', () {
    final key = Bip340.generatePrivateKey();

    Future<MockRelay> authRelay({bool requireAuthForEvents = false}) async {
      final relay = MockRelay(
        name: "auth relay",
        requireAuthForRequests: true,
        requireAuthForEvents: requireAuthForEvents,
        signEvents: false,
      );
      await relay.startServer(textNotes: {key: _textNote(key, "note")});
      return relay;
    }

    Ndk ndkFor(List<MockRelay> relays, _Handler? handler) => Ndk(
          NdkConfig(
            eventVerifier: MockEventVerifier(),
            cache: MemCacheManager(),
            bootstrapRelays: [for (final relay in relays) relay.url],
            engine: engine,
            authHandler: handler?.call,
          ),
        );

    Iterable<RelayConnectionKey> boundKeys(Ndk ndk, String url) =>
        ndk.relays.globalState.relays.keys
            .where((k) => !k.isAnonymous && k.url == url);

    test('require goes out only where the handler agrees', () async {
      final relays = [await authRelay(), await authRelay(), await authRelay()];
      final refused = relays.last;
      final handler = _Handler((url) => url != refused.url);
      final ndk = ndkFor(relays, handler);

      const requestId = 'require-handler';
      final response = ndk.requests.requestNostrEvent(
        NdkRequest.query(
          requestId,
          filters: [_notesOf(key)],
          explicitRelays: [for (final relay in relays) relay.url],
          timeoutDuration: const Duration(seconds: 5),
          auth: AuthPolicy.require(_signable(key)),
        ),
      );

      expect(await response.future, isNotEmpty);
      expect(handler.asked.map((q) => q.$2), everyElement(key.publicKey));
      expect(handler.asked, hasLength(3));
      for (final relay in relays.take(2)) {
        expect(relay.connectionsThatRequested(requestId), 1);
      }
      expect(refused.connectionsThatRequested(requestId), 0);
      expect(refused.receivedAuths, 0);
      expect(boundKeys(ndk, refused.url), isEmpty);

      await ndk.destroy();
      for (final relay in relays) {
        await relay.stopServer();
      }
    });

    test('allow reveals nothing once the handler says no', () async {
      final relay = await authRelay();
      final handler = _Handler((_) => false);
      final ndk = ndkFor([relay], handler);

      final response = ndk.requests.query(
        filter: _notesOf(key),
        explicitRelays: [relay.url],
        auth: AuthPolicy.allow(_signable(key)),
      );

      expect(await response.future, isEmpty);
      expect(handler.asked, [(relay.url, key.publicKey)]);
      expect(relay.receivedAuths, 0);
      expect(boundKeys(ndk, relay.url), isEmpty);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('never is not asked about', () async {
      final relay = await authRelay();
      final handler = _Handler((_) => true);
      final ndk = ndkFor([relay], handler);
      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );

      final response = ndk.requests.query(
        filter: _notesOf(key),
        explicitRelays: [relay.url],
        auth: const AuthPolicy.never(),
      );

      expect(await response.future, isEmpty);
      expect(handler.asked, isEmpty);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('without auth or handler the logged account stays hidden', () async {
      final relay = await authRelay();
      final ndk = ndkFor([relay], null);
      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );

      final response = ndk.requests.query(
        filter: _notesOf(key),
        explicitRelays: [relay.url],
      );

      expect(await response.future, isEmpty);
      expect(relay.receivedAuths, 0);
      expect(boundKeys(ndk, relay.url), isEmpty);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('without auth the handler is asked about the logged account',
        () async {
      final relay = await authRelay();
      final handler = _Handler((_) => false);
      final ndk = ndkFor([relay], handler);
      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );

      final response = ndk.requests.query(
        filter: _notesOf(key),
        explicitRelays: [relay.url],
      );

      expect(await response.future, isEmpty);
      expect(handler.asked, [(relay.url, key.publicKey)]);
      expect(relay.receivedAuths, 0);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('a handler that throws is a refusal', () async {
      final relay = await authRelay();
      final ndk = ndkFor(
        [relay],
        _Handler((_) => throw StateError('no ui to ask')),
      );

      final response = ndk.requests.query(
        filter: _notesOf(key),
        explicitRelays: [relay.url],
        auth: AuthPolicy.require(_signable(key)),
      );

      expect(await response.future, isEmpty);
      expect(relay.receivedAuths, 0);
      expect(boundKeys(ndk, relay.url), isEmpty);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('a connection is asked about once, not per request', () async {
      final relay = await authRelay();
      final handler = _Handler((_) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return true;
      });
      final ndk = ndkFor([relay], handler);
      final account = _signable(key);

      NdkResponse query() => ndk.requests.query(
            filter: _notesOf(key),
            explicitRelays: [relay.url],
            auth: AuthPolicy.require(account),
          );

      final concurrent = await Future.wait([query().future, query().future]);
      expect(concurrent, everyElement(isNotEmpty));
      expect(await query().future, isNotEmpty);
      expect(handler.asked, hasLength(1));

      await ndk.destroy();
      await relay.stopServer();
    });

    test('a bound connection coming back is not asked about again', () async {
      final relay = await authRelay();
      final handler = _Handler((_) => true);
      final ndk = ndkFor([relay], handler);

      final response = ndk.requests.subscription(
        filter: _notesOf(key),
        explicitRelays: [relay.url],
        auth: AuthPolicy.require(_signable(key)),
      );
      final subId = response.requestId;

      await _waitUntil(
        () => relay.subscriptionsAuthenticatedAs(key.publicKey).contains(subId),
        reason: 'the subscription never reached an authenticated connection',
      );
      await relay.closeClientSockets();
      await _waitUntil(
        () => relay.subscriptionsAuthenticatedAs(key.publicKey).contains(subId),
        reason: 'the bound connection never came back',
      );

      expect(handler.asked, hasLength(1));

      await ndk.requests.closeSubscription(subId);
      await ndk.destroy();
      await relay.stopServer();
    });

    test('waiting on the handler does not spend the query timeout', () async {
      final relay = await authRelay();
      final ndk = ndkFor(
        [relay],
        _Handler((_) async {
          await Future.delayed(const Duration(milliseconds: 1500));
          return true;
        }),
      );

      final response = ndk.requests.query(
        filter: _notesOf(key),
        explicitRelays: [relay.url],
        timeout: const Duration(seconds: 1),
        auth: AuthPolicy.require(_signable(key)),
      );

      expect(await response.future, isNotEmpty);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('concurrent questions keep the timeout paused until the last',
        () async {
      final relays = [await authRelay(), await authRelay()];
      final slow = relays.last;
      final ndk = ndkFor(
        relays,
        _Handler((url) async {
          if (url == slow.url) {
            await Future.delayed(const Duration(milliseconds: 1500));
          }
          return true;
        }),
      );

      const requestId = 'paused-until-last';
      final response = ndk.requests.requestNostrEvent(
        NdkRequest.query(
          requestId,
          filters: [_notesOf(key)],
          explicitRelays: [for (final relay in relays) relay.url],
          timeoutDuration: const Duration(seconds: 1),
          auth: AuthPolicy.require(_signable(key)),
        ),
      );

      await response.future;
      expect(slow.connectionsThatRequested(requestId), 1);

      await ndk.destroy();
      for (final relay in relays) {
        await relay.stopServer();
      }
    });

    test('a request closed while the handler decides does not time out',
        () async {
      final relay = await authRelay();
      final answer = Completer<bool>();
      final handler = _Handler((_) => answer.future);
      final ndk = ndkFor([relay], handler);

      var timeouts = 0;
      final response = ndk.requests.requestNostrEvent(
        NdkRequest.subscription(
          'closed-while-asking',
          filters: [_notesOf(key)],
          explicitRelays: [relay.url],
          auth: AuthPolicy.require(_signable(key)),
        )
          ..timeoutDuration = const Duration(milliseconds: 300)
          ..timeoutCallbackUserFacing = () => timeouts++,
      );

      await _waitUntil(
        () => handler.asked.isNotEmpty,
        reason: 'the handler was never asked',
      );
      await ndk.requests.closeSubscription(response.requestId);
      answer.complete(true);
      await Future.delayed(const Duration(milliseconds: 600));

      expect(timeouts, 0);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('waiting on the handler does not spend the broadcast timeout',
        () async {
      final relay = await authRelay(requireAuthForEvents: true);
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay.url],
          engine: engine,
          defaultBroadcastTimeout: const Duration(seconds: 1),
          authHandler: (_, _) async {
            await Future.delayed(const Duration(milliseconds: 1500));
            return true;
          },
        ),
      );

      final result = await ndk.broadcast
          .broadcast(
            nostrEvent: _textNote(key, "slow consent"),
            specificRelays: [relay.url],
            auth: AuthPolicy.require(_signable(key)),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isTrue);

      await ndk.destroy();
      await relay.stopServer();
    });
  });
}

void nip77AuthHandlerTests() {
  group('AuthHandler NIP-77', () {
    test('waiting on the handler does not spend the reconciliation timeout',
        () async {
      final key = Bip340.generatePrivateKey();
      final relay = MockRelay(name: "neg relay", signEvents: false)
        ..requireAuthForNegentropy = true
        ..requireAuthForRequests = true;
      relay.negentropyItems['a' * 64] = 1000;
      await relay.startServer();

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay.url],
          authHandler: (_, _) async {
            await Future.delayed(const Duration(milliseconds: 1500));
            return true;
          },
        ),
      );

      final result = await ndk.nip77
          .reconcile(
            relayUrl: relay.url,
            filter: _notesOf(key),
            timeout: const Duration(seconds: 1),
            auth: AuthPolicy.require(_signable(key)),
          )
          .future;

      expect(result.needIds, contains('a' * 64));

      await ndk.destroy();
      await relay.stopServer();
    });
  });
}

Future<void> _waitUntil(
  bool Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason);
    }
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
