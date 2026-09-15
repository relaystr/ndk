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

    Ndk ndkFor(MockRelay relay) => Ndk(
          NdkConfig(
            eventVerifier: MockEventVerifier(),
            cache: MemCacheManager(),
            bootstrapRelays: [relay.url],
            defaultBroadcastTimeout: const Duration(seconds: 2),
            engine: engine,
          ),
        );

    Future<MockRelay> authRelay({bool requireAuth = true}) async {
      final relay = MockRelay(
        name: "broadcast auth relay",
        requireAuthForEvents: requireAuth,
      );
      // the relay only challenges once it refuses an event, which is what
      // `allow` waits for, so every connection has to be offered a challenge
      relay.sendAuthChallenge = true;
      await relay.startServer();
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
            auth: const RelayAuth.never(),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isFalse);
      expect(
        relay.acceptedAuths,
        0,
        reason: 'a broadcast that may reveal nobody never answers a challenge',
      );
      expect(relay.connectionsAuthenticatedAs(key.publicKey), 0);

      await ndk.destroy();
      await relay.stopServer();
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
            auth: RelayAuth.allow(account),
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

      await ndk.destroy();
      await relay.stopServer();
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
            auth: RelayAuth.allow(account),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isTrue);
      expect(
        relay.connectionsAuthenticatedAs(key.publicKey),
        0,
        reason: 'nothing asked for an identity, so none was revealed',
      );
      expect(relay.eventsAuthenticatedAs(key.publicKey), isEmpty);

      await ndk.destroy();
      await relay.stopServer();
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
            auth: RelayAuth.require(account),
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

      await relay.stopServer();
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
            auth: RelayAuth.require(account),
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

      await ndk.destroy();
      await bootstrap.stopServer();
      await target.stopServer();
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
            auth: RelayAuth.require(account),
          )
          .broadcastDoneFuture;

      expect(
        ndk.relays.globalState.relays.keys.where(
          (connectionKey) => connectionKey.pubkey == key.publicKey,
        ),
        isNotEmpty,
        reason: 'require opens its bound connection whether or not it is asked',
      );

      await ndk.destroy();
      await relay.stopServer();
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
            auth: RelayAuth.require(handedOver),
          )
          .broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isTrue);
      expect(relay.connectionsAuthenticatedAs(key.publicKey), greaterThan(0));
      expect(
        relay.connectionsAuthenticatedAs(other.publicKey),
        0,
        reason: 'the logged account is not the one that was named',
      );

      await ndk.destroy();
      await relay.stopServer();
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
          auth: RelayAuth.require(watchOnly),
        ),
        throwsA(isA<BroadcastAuthUnavailableException>()),
      );
      expect(
        relay.receivedEvents,
        isEmpty,
        reason: 'an impossible broadcast is sent to no relay at all',
      );

      await ndk.destroy();
      await relay.stopServer();
    });

    test('without auth a refusal still authenticates as the author', () async {
      final relay = await authRelay();
      final ndk = ndkFor(relay);
      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );

      final result = await ndk.broadcast.broadcast(
        nostrEvent: noteFrom(key, "default"),
        specificRelays: [relay.url],
      ).broadcastDoneFuture;

      expect(result.any((r) => r.broadcastSuccessful), isTrue);
      expect(relay.connectionsAuthenticatedAs(key.publicKey), greaterThan(0));

      await ndk.destroy();
      await relay.stopServer();
    });
  });
}
