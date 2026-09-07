import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_relay.dart';

void main() async {
  group('NIP-77 relay authentication', () {
    const portBase = 4300;

    final key1 = Bip340.generatePrivateKey();

    Account signableAccount(KeyPair key) => Account(
          pubkey: key.publicKey,
          type: AccountType.privateKey,
          signer: Bip340EventSigner(
            privateKey: key.privateKey!,
            publicKey: key.publicKey,
          ),
        );

    Ndk ndkFor(MockRelay relay) => Ndk(
          NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            bootstrapRelays: [relay.url],
          ),
        );

    /// a relay holding one event the client does not have, so a successful
    /// reconciliation is told apart from one that simply never ran
    Future<MockRelay> negentropyRelay({
      required int port,
      bool requireAuth = true,
      bool refuseWithClosed = false,
    }) async {
      final relay = MockRelay(
        name: "neg relay",
        explicitPort: port,
        signEvents: false,
      )
        ..requireAuthForNegentropy = requireAuth
        ..refuseNegentropyWithClosed = refuseWithClosed;
      relay.negentropyItems['a' * 64] = 1000;
      // the relay only challenges once it refuses, which is what `allow` waits
      // for, so the challenge has to be offered on every connection
      relay.sendAuthChallenge = true;
      relay.requireAuthForRequests = true;
      await relay.startServer();
      return relay;
    }

    Filter notesOf(KeyPair key) =>
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key.publicKey]);

    test('require reconciles on a bound connection from the start', () async {
      final relay = await negentropyRelay(port: portBase);
      final ndk = ndkFor(relay);
      await Future.delayed(Duration(seconds: 1));

      final response = ndk.nip77.reconcile(
        relayUrl: relay.url,
        filter: notesOf(key1),
        auth: RelayAuth.require(signableAccount(key1)),
        timeout: Duration(seconds: 10),
      );

      final result = await response.future;
      expect(result.needIds, contains('a' * 64));
      expect(relay.connectionsAuthenticatedAs(key1.publicKey), 1);
      expect(
        relay.negOpensNotAuthenticatedAs(key1.publicKey),
        isEmpty,
        reason: 'require never opens a negotiation on the anonymous connection',
      );

      await ndk.destroy();
      await relay.stopServer();
    });

    test('allow reconciles after the relay refuses', () async {
      final relay = await negentropyRelay(port: portBase + 1);
      final ndk = ndkFor(relay);
      await Future.delayed(Duration(seconds: 1));

      final response = ndk.nip77.reconcile(
        relayUrl: relay.url,
        filter: notesOf(key1),
        auth: RelayAuth.allow(signableAccount(key1)),
        timeout: Duration(seconds: 10),
      );

      final result = await response.future;
      expect(result.needIds, contains('a' * 64));
      expect(relay.connectionsAuthenticatedAs(key1.publicKey), 1);
      expect(
        relay.negOpensNotAuthenticatedAs(key1.publicKey),
        isNotEmpty,
        reason: 'allow tries the anonymous connection before authenticating',
      );

      await ndk.destroy();
      await relay.stopServer();
    });

    test('allow reconciles when the relay refuses with CLOSED', () async {
      final relay = await negentropyRelay(
        port: portBase + 2,
        refuseWithClosed: true,
      );
      final ndk = ndkFor(relay);
      await Future.delayed(Duration(seconds: 1));

      final response = ndk.nip77.reconcile(
        relayUrl: relay.url,
        filter: notesOf(key1),
        auth: RelayAuth.allow(signableAccount(key1)),
        timeout: Duration(seconds: 10),
      );

      final result = await response.future;
      expect(result.needIds, contains('a' * 64));
      expect(relay.connectionsAuthenticatedAs(key1.publicKey), 1);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('never stays unattributable when a relay refuses', () async {
      final relay = await negentropyRelay(port: portBase + 3);
      final ndk = ndkFor(relay);

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );
      await Future.delayed(Duration(seconds: 1));

      final response = ndk.nip77.reconcile(
        relayUrl: relay.url,
        filter: notesOf(key1),
        auth: const RelayAuth.never(),
        timeout: Duration(seconds: 10),
      );

      await expectLater(
        response.future,
        throwsA(isA<Nip77AuthRequiredException>()),
      );
      expect(relay.connectionsAuthenticatedAs(key1.publicKey), 0);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('without auth it authenticates as the logged account', () async {
      final relay = await negentropyRelay(port: portBase + 4);
      final ndk = ndkFor(relay);

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );
      await Future.delayed(Duration(seconds: 1));

      final response = ndk.nip77.reconcile(
        relayUrl: relay.url,
        filter: notesOf(key1),
        timeout: Duration(seconds: 10),
      );

      final result = await response.future;
      expect(result.needIds, contains('a' * 64));
      expect(relay.connectionsAuthenticatedAs(key1.publicKey), 1);

      await ndk.destroy();
      await relay.stopServer();
    });

    test('require with an account that cannot sign reaches no relay', () async {
      final relay = await negentropyRelay(port: portBase + 5);
      final ndk = ndkFor(relay);
      await Future.delayed(Duration(seconds: 1));

      final watchOnly = Account(
        pubkey: key1.publicKey,
        type: AccountType.publicKey,
        signer: Bip340EventSigner(privateKey: null, publicKey: key1.publicKey),
      );

      final response = ndk.nip77.reconcile(
        relayUrl: relay.url,
        filter: notesOf(key1),
        auth: RelayAuth.require(watchOnly),
        timeout: Duration(seconds: 10),
      );

      await expectLater(
        response.future,
        throwsA(isA<Nip77AuthUnavailableException>()),
      );
      expect(
        relay.receivedNegOpens,
        isEmpty,
        reason: 'an impossible reconciliation is sent to no relay at all',
      );

      await ndk.destroy();
      await relay.stopServer();
    });

    test('reconciles anonymously when the relay does not require auth',
        () async {
      final relay = await negentropyRelay(
        port: portBase + 6,
        requireAuth: false,
      );
      relay.requireAuthForRequests = false;
      relay.sendAuthChallenge = false;
      final ndk = ndkFor(relay);
      await Future.delayed(Duration(seconds: 1));

      final response = ndk.nip77.reconcile(
        relayUrl: relay.url,
        filter: notesOf(key1),
        auth: const RelayAuth.never(),
        timeout: Duration(seconds: 10),
      );

      final result = await response.future;
      expect(result.needIds, contains('a' * 64));
      expect(relay.connectionsAuthenticatedAs(key1.publicKey), 0);

      await ndk.destroy();
      await relay.stopServer();
    });
  });
}
