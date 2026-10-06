import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  for (final engine in NdkEngine.values) {
    broadcastAuthTests(engine);
  }
}

/// The identity a broadcast may be attributed to is decided above the engines,
/// so both must reach the same connection.
void broadcastAuthTests(NdkEngine engine) {
  group('broadcast relay authentication [${engine.name}]', () {
    final key = Bip340.generatePrivateKey();
    final other = Bip340.generatePrivateKey();

    Account signableAccount(KeyPair k) => Account(
      pubkey: k.publicKey,
      type: AccountType.privateKey,
      signer: Bip340EventSigner(
        privateKey: k.privateKey!,
        publicKey: k.publicKey,
      ),
    );

    Ndk ndkFor(MockRelay relay) {
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay.url],
          // This suite tests identity policy, not network latency. Allow the
          // anonymous refusal, bound connection, AUTH, and EVENT retry to
          // complete even when the full suite competes for CPU.
          defaultBroadcastTimeout: const Duration(seconds: 10),
          engine: engine,
        ),
      );
      addTearDown(ndk.destroy);
      return ndk;
    }

    Future<MockRelay> authRelay({
      bool requireAuth = true,
      Duration? delayResponse,
    }) async {
      final relay = MockRelay(
        name: "broadcast auth relay",
        requireAuthForEvents: requireAuth,
      );
      // Offer a challenge on every connection; `allow` must still wait for
      // an EVENT refusal before disclosing an identity.
      relay.sendAuthChallenge = true;
      addTearDown(relay.stopServer);
      await relay.startServer(delayResponse: delayResponse);
      return relay;
    }

    Nip01Event noteFrom(KeyPair k, String content) => Nip01Event(
      pubKey: k.publicKey,
      kind: Nip01Event.kTextNodeKind,
      tags: [],
      content: content,
    );

    test('never stays unattributable and does not deliver', () async {
      final relay = await authRelay();
      final ndk = ndkFor(relay);
      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );

      final result = await ndk.broadcast
          .broadcast(
            nostrEvent: noteFrom(key, "never"),
            specificRelays: [relay.url],
            auth: const AuthPolicy.never(),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isFalse);
      expect(
        relay.acceptedAuths,
        0,
        reason: 'a broadcast that may reveal nobody never answers a challenge',
      );
      expect(relay.connectionsAuthenticatedAs(key.publicKey), 0);
    });

    test('allow authenticates only once the relay refuses', () async {
      final relay = await authRelay();
      final ndk = ndkFor(relay);
      final account = signableAccount(key);
      final event = noteFrom(key, "allow");

      final result = await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            customSigner: account.signer,
            auth: AuthPolicy.allow(account),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isTrue);
      expect(
        relay.eventsNotAuthenticatedAs(key.publicKey),
        contains(event.id),
        reason: 'allow starts on the anonymous connection',
      );
      expect(
        relay.eventsAuthenticatedAs(key.publicKey),
        contains(event.id),
        reason: 'and moves to a bound one once refused',
      );
    });

    test('allow does not authenticate to a relay that never refuses', () async {
      final relay = await authRelay(requireAuth: false);
      final ndk = ndkFor(relay);
      final account = signableAccount(key);
      final event = noteFrom(key, "allow unrefused");

      final result = await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            customSigner: account.signer,
            auth: AuthPolicy.allow(account),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isTrue);
      expect(
        relay.connectionsAuthenticatedAs(key.publicKey),
        0,
        reason: 'nothing asked for an identity, so none was revealed',
      );
      expect(relay.eventsAuthenticatedAs(key.publicKey), isEmpty);
    });

    test('require sends the event only on the bound connection', () async {
      final relay = await authRelay();
      final ndk = ndkFor(relay);
      final account = signableAccount(key);
      final event = noteFrom(key, "require");

      final result = await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            customSigner: account.signer,
            auth: AuthPolicy.require(account),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isTrue);

      // asserted after the connections are gone: what carried the event has to
      // outlive the socket that carried it
      await ndk.destroy();

      expect(
        relay.eventsNotAuthenticatedAs(key.publicKey),
        isEmpty,
        reason: 'the event never touches the anonymous connection',
      );
      expect(
        relay.eventsAuthenticatedAs(key.publicKey),
        contains(event.id),
        reason: 'and it went out as the identity that was required',
      );
    });

    test('require never opens the anonymous connection', () async {
      // bootstrapping to another relay, so the only reason to reach the target
      // at all is this broadcast
      final bootstrap = await authRelay(requireAuth: false);
      final target = await authRelay();
      final ndk = ndkFor(bootstrap);
      final account = signableAccount(key);

      await ndk.broadcast
          .broadcast(
            nostrEvent: noteFrom(key, "require alone"),
            specificRelays: [target.url],
            customSigner: account.signer,
            auth: AuthPolicy.require(account),
          )
          .broadcastDoneFuture;

      expect(
        ndk.relays.globalState.relays.keys.where(
          (connectionKey) =>
              connectionKey.url == target.url && connectionKey.isAnonymous,
        ),
        isEmpty,
        reason: 'a socket we opened is one the relay saw, sent on or not',
      );
      expect(
        ndk.relays.globalState.relays.keys.where(
          (connectionKey) => connectionKey.pubkey == key.publicKey,
        ),
        isNotEmpty,
        reason: 'the bound connection is the one that was opened',
      );
    });

    test('require binds even when the relay never refuses', () async {
      final relay = await authRelay(requireAuth: false);
      final ndk = ndkFor(relay);
      final account = signableAccount(key);
      final event = noteFrom(key, "require unrefused");

      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            customSigner: account.signer,
            auth: AuthPolicy.require(account),
          )
          .broadcastDoneFuture;

      expect(
        ndk.relays.globalState.relays.keys.where(
          (connectionKey) => connectionKey.pubkey == key.publicKey,
        ),
        isNotEmpty,
        reason: 'require opens its bound connection whether or not it is asked',
      );
    });

    test('authenticates as an account NDK never registered', () async {
      final relay = await authRelay();
      final ndk = ndkFor(relay);
      // logged in as one identity, broadcasting as another that was handed
      // over rather than registered
      ndk.accounts.loginPrivateKey(
        pubkey: other.publicKey,
        privkey: other.privateKey!,
      );
      final handedOver = signableAccount(key);
      final event = noteFrom(key, "unregistered");

      final result = await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            customSigner: handedOver.signer,
            auth: AuthPolicy.require(handedOver),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isTrue);
      expect(relay.connectionsAuthenticatedAs(key.publicKey), greaterThan(0));
      expect(
        relay.connectionsAuthenticatedAs(other.publicKey),
        0,
        reason: 'the logged account is not the one that was named',
      );
    });

    test('require with an account that cannot sign reaches no relay', () async {
      final relay = await authRelay();
      final ndk = ndkFor(relay);

      final watchOnly = Account(
        pubkey: key.publicKey,
        type: AccountType.publicKey,
        signer: Bip340EventSigner(privateKey: null, publicKey: key.publicKey),
      );

      // the call itself throws, so a caller that only reads the future later
      // never faces an error nobody was listening to
      expect(
        () => ndk.broadcast.broadcast(
          nostrEvent: noteFrom(key, "impossible"),
          specificRelays: [relay.url],
          customSigner: signableAccount(key).signer,
          auth: AuthPolicy.require(watchOnly),
        ),
        throwsA(isA<BroadcastAuthUnavailableException>()),
      );
      expect(
        relay.receivedEvents,
        isEmpty,
        reason: 'an impossible broadcast is sent to no relay at all',
      );
    });

    test(
      'without auth a delayed refusal still authenticates as the author',
      () async {
        final relay = await authRelay(
          delayResponse: const Duration(milliseconds: 600),
        );
        final ndk = ndkFor(relay);
        ndk.accounts.loginPrivateKey(
          pubkey: key.publicKey,
          privkey: key.privateKey!,
        );

        final elapsed = Stopwatch()..start();
        final result = await ndk.broadcast
            .broadcast(
              nostrEvent: noteFrom(key, "default"),
              specificRelays: [relay.url],
            )
            .broadcastDoneFuture;

        expect(
          result.any((r) => r.broadcastSuccessful),
          isTrue,
          reason:
              'elapsed=${elapsed.elapsed}; AUTH received=${relay.receivedAuths}; '
              'accepted=${relay.acceptedAuths}; responses='
              '${result.map((r) => '${r.okReceived}/${r.broadcastSuccessful}/${r.msg}').toList()}',
        );
        expect(relay.connectionsAuthenticatedAs(key.publicKey), greaterThan(0));
      },
    );
  });
}
