// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

void main() async {
  for (final engine in NdkEngine.values) {
    nip42Tests(engine);
  }
}

/// The AUTH re-route lives under the engines, so both must reach an
/// authenticated connection the same way.
void nip42Tests(NdkEngine engine) {
  final portBase = 3900 + engine.index * 20;

  group('NIP-42 [${engine.name}]', () {
    KeyPair key1 = Bip340.generatePrivateKey();

    Map<KeyPair, String> keyNames = {key1: "key1"};

    Nip01Event textNote(KeyPair key) {
      Nip01Event event = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key.publicKey,
        content: "some note from key ${keyNames[key1]}",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: key.privateKey!,
      );
      return signedEvent;
    }

    Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};

    test('respond to auth challenge', () async {
      MockRelay relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase,
        requireAuthForRequests: true,
        signEvents: false,
      );
      await relay1.startServer(textNotes: key1TextNotes);

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          // logLevel: Logger.logLevels.trace,
          bootstrapRelays: [relay1.url],
          engine: engine,
        ),
      );

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      await Future.delayed(Duration(seconds: 1));
      final response = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
      );
      await expectLater(response.stream, emitsInAnyOrder(key1TextNotes.values));

      // TODO: Create events and do some requests
      await ndk.destroy();
      await relay1.stopServer();
    });

    test(
      "check that relay does not return events if we don't provide a signer",
      () async {
        MockRelay relay1 = MockRelay(
          name: "relay 1",
          explicitPort: portBase,
          requireAuthForRequests: true,
        );
        await relay1.startServer(textNotes: key1TextNotes);

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            // logLevel: Logger.logLevels.trace,
            bootstrapRelays: [relay1.url],
            engine: engine,
          ),
        );

        await Future.delayed(Duration(seconds: 1));
        final response = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey],
          ),
        );
        List<Nip01Event> events = await response.future;
        expect(events, isEmpty);
        await ndk.destroy();
        await relay1.stopServer();
      },
    );
  });

  group('NIP-42 authenticateAs [${engine.name}]', () {
    KeyPair key1 = Bip340.generatePrivateKey();
    KeyPair key2 = Bip340.generatePrivateKey();

    Nip01Event textNote(KeyPair key, String content) {
      Nip01Event event = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key.publicKey,
        content: content,
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: key.privateKey!,
      );
      return signedEvent;
    }

    test('authenticateAs sends AUTH for specified pubkey', () async {
      MockRelay relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 1,
        requireAuthForRequests: true,
        signEvents: false,
      );

      final note1 = textNote(key1, "note from key1");
      await relay1.startServer(textNotes: {key1: note1});

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay1.url],
          engine: engine,
        ),
      );

      // Add account but don't login (so no default signer)
      final account1 = Account(
        pubkey: key1.publicKey,
        type: AccountType.privateKey,
        signer: Bip340EventSigner(
          privateKey: key1.privateKey!,
          publicKey: key1.publicKey,
        ),
      );
      ndk.accounts.addAccount(
        pubkey: account1.pubkey,
        type: account1.type,
        signer: account1.signer,
      );

      await Future.delayed(Duration(seconds: 1));

      // Use authenticateAs to specify which account to auth
      final response = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
        authenticateAs: [account1],
      );

      List<Nip01Event> events = await response.future;
      expect(events, isNotEmpty);
      expect(events.first.content, equals("note from key1"));

      await ndk.destroy();
      await relay1.stopServer();
    });

    test('authenticateAs uses the first signable account', () async {
      MockRelay relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 2,
        requireAuthForRequests: true,
        signEvents: false,
      );

      final note1 = textNote(key1, "note from key1");
      final note2 = textNote(key2, "note from key2");
      await relay1.startServer(textNotes: {key1: note1, key2: note2});

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay1.url],
          engine: engine,
        ),
      );

      // Add both accounts
      final account1 = Account(
        pubkey: key1.publicKey,
        type: AccountType.privateKey,
        signer: Bip340EventSigner(
          privateKey: key1.privateKey!,
          publicKey: key1.publicKey,
        ),
      );
      final account2 = Account(
        pubkey: key2.publicKey,
        type: AccountType.privateKey,
        signer: Bip340EventSigner(
          privateKey: key2.privateKey!,
          publicKey: key2.publicKey,
        ),
      );
      ndk.accounts.addAccount(
        pubkey: account1.pubkey,
        type: account1.type,
        signer: account1.signer,
      );
      ndk.accounts.addAccount(
        pubkey: account2.pubkey,
        type: account2.type,
        signer: account2.signer,
      );

      await Future.delayed(Duration(seconds: 1));

      // Use authenticateAs with both accounts
      final response = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey, key2.publicKey],
        ),
        authenticateAs: [account1, account2],
      );

      List<Nip01Event> events = await response.future;
      expect(events.length, equals(2));
      // one request, one identity: the second account is never revealed
      expect(relay1.connectionsAuthenticatedAs(key2.publicKey), 0);

      await ndk.destroy();
      await relay1.stopServer();
    });

    test('auth wins over authenticateAs', () async {
      MockRelay relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 8,
        requireAuthForRequests: true,
        signEvents: false,
      );

      final note1 = textNote(key1, "note from key1");
      await relay1.startServer(textNotes: {key1: note1});

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay1.url],
          engine: engine,
        ),
      );

      final account1 = Account(
        pubkey: key1.publicKey,
        type: AccountType.privateKey,
        signer: Bip340EventSigner(
          privateKey: key1.privateKey!,
          publicKey: key1.publicKey,
        ),
      );
      final account2 = Account(
        pubkey: key2.publicKey,
        type: AccountType.privateKey,
        signer: Bip340EventSigner(
          privateKey: key2.privateKey!,
          publicKey: key2.publicKey,
        ),
      );
      ndk.accounts.addAccount(
        pubkey: account1.pubkey,
        type: account1.type,
        signer: account1.signer,
      );
      ndk.accounts.addAccount(
        pubkey: account2.pubkey,
        type: account2.type,
        signer: account2.signer,
      );

      await Future.delayed(Duration(seconds: 1));

      final response = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
        auth: RelayAuth.allow(account1),
        authenticateAs: [account2],
      );

      List<Nip01Event> events = await response.future;
      expect(events, isNotEmpty);
      expect(relay1.connectionsAuthenticatedAs(key1.publicKey), 1);
      expect(relay1.connectionsAuthenticatedAs(key2.publicKey), 0);

      await ndk.destroy();
      await relay1.stopServer();
    });

    test(
      'late AUTH - second subscription gets AUTH from stored challenge',
      () async {
        MockRelay relay1 = MockRelay(
          name: "relay 1",
          explicitPort: portBase + 3,
          requireAuthForRequests: true,
          signEvents: false,
        );

        final note1 = textNote(key1, "note from key1");
        final note2 = textNote(key2, "note from key2");
        await relay1.startServer(textNotes: {key1: note1, key2: note2});

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            bootstrapRelays: [relay1.url],
            engine: engine,
          ),
        );

        // Add both accounts
        final account1 = Account(
          pubkey: key1.publicKey,
          type: AccountType.privateKey,
          signer: Bip340EventSigner(
            privateKey: key1.privateKey!,
            publicKey: key1.publicKey,
          ),
        );
        final account2 = Account(
          pubkey: key2.publicKey,
          type: AccountType.privateKey,
          signer: Bip340EventSigner(
            privateKey: key2.privateKey!,
            publicKey: key2.publicKey,
          ),
        );
        ndk.accounts.addAccount(
          pubkey: account1.pubkey,
          type: account1.type,
          signer: account1.signer,
        );
        ndk.accounts.addAccount(
          pubkey: account2.pubkey,
          type: account2.type,
          signer: account2.signer,
        );

        await Future.delayed(Duration(seconds: 1));

        // First subscription with account1
        final response1 = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey],
          ),
          authenticateAs: [account1],
        );
        List<Nip01Event> events1 = await response1.future;
        expect(events1, isNotEmpty);
        expect(events1.first.content, equals("note from key1"));

        // Second subscription with account2 - should use stored challenge
        final response2 = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key2.publicKey],
          ),
          authenticateAs: [account2],
        );
        List<Nip01Event> events2 = await response2.future;
        expect(events2, isNotEmpty);
        expect(events2.first.content, equals("note from key2"));

        await ndk.destroy();
        await relay1.stopServer();
      },
    );

    // NOTE: This test was testing a "restricted access" model where you can only
    // see events from pubkeys you're authenticated as. This is NOT basic NIP-42.
    // Basic NIP-42 is "any auth" - once authenticated, you can access all data.
    // Restricted access requires: gift wrap, "+" tag on events, or relay-specific
    // config to restrict access by author. See draft NIP for "Restricted Events".
    test(
      'request for non-authenticated account is rejected',
      skip: 'Not basic NIP-42 - would require restricted events implementation',
      () async {
        MockRelay relay1 = MockRelay(
          name: "relay 1",
          explicitPort: portBase + 5,
          requireAuthForRequests: true,
          signEvents: false,
        );

        final note1 = textNote(key1, "note from key1");
        final note2 = textNote(key2, "note from key2");
        await relay1.startServer(textNotes: {key1: note1, key2: note2});

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            bootstrapRelays: [relay1.url],
            engine: engine,
          ),
        );

        // Only add account1, NOT account2
        final account1 = Account(
          pubkey: key1.publicKey,
          type: AccountType.privateKey,
          signer: Bip340EventSigner(
            privateKey: key1.privateKey!,
            publicKey: key1.publicKey,
          ),
        );
        ndk.accounts.addAccount(
          pubkey: account1.pubkey,
          type: account1.type,
          signer: account1.signer,
        );

        await Future.delayed(Duration(seconds: 1));

        // Authenticate only account1
        final response1 = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey],
          ),
          authenticateAs: [account1],
        );
        List<Nip01Event> events1 = await response1.future;
        expect(
          events1,
          isNotEmpty,
          reason: "account1 is authenticated, should get events",
        );

        // Try to request key2's data WITHOUT authenticating key2
        // This should fail because key2 is not authenticated
        final response2 = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key2.publicKey],
          ),
          // NOT passing authenticateAs for key2, and key2 is not logged in
        );
        List<Nip01Event> events2 = await response2.future;
        expect(
          events2,
          isEmpty,
          reason: "key2 is NOT authenticated, should NOT get events",
        );

        await ndk.destroy();
        await relay1.stopServer();
      },
    );

    test(
      'fallback to logged account when no auth is specified',
      () async {
        MockRelay relay1 = MockRelay(
          name: "relay 1",
          explicitPort: portBase + 4,
          requireAuthForRequests: true,
          signEvents: false,
        );

        final note1 = textNote(key1, "note from key1");
        await relay1.startServer(textNotes: {key1: note1});

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            bootstrapRelays: [relay1.url],
            engine: engine,
          ),
        );

        // Login with key1 (sets as logged account)
        ndk.accounts.loginPrivateKey(
          pubkey: key1.publicKey,
          privkey: key1.privateKey!,
        );

        await Future.delayed(Duration(seconds: 1));

        // Query without auth, should fallback to the logged account
        final response = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey],
          ),
        );

        List<Nip01Event> events = await response.future;
        expect(events, isNotEmpty);
        expect(events.first.content, equals("note from key1"));

        await ndk.destroy();
        await relay1.stopServer();
      },
    );

    test(
      'auth-required opens a second connection instead of promoting',
      () async {
        MockRelay relay1 = MockRelay(
          name: "relay 1",
          explicitPort: portBase + 6,
          requireAuthForRequests: true,
          signEvents: false,
        );

        final note1 = textNote(key1, "note from key1");
        await relay1.startServer(textNotes: {key1: note1});

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            bootstrapRelays: [relay1.url],
            engine: engine,
          ),
        );

        ndk.accounts.loginPrivateKey(
          pubkey: key1.publicKey,
          privkey: key1.privateKey!,
        );

        await Future.delayed(Duration(seconds: 1));

        final response = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey],
          ),
        );
        expect(await response.future, isNotEmpty);

        final keysForRelay = ndk.relays.globalState.relays.keys
            .where((key) => key.url == relay1.url)
            .toList();

        expect(
          keysForRelay.where((key) => key.isAnonymous),
          hasLength(1),
          reason: 'the anonymous connection must stay anonymous',
        );
        expect(
          keysForRelay.where((key) => key.pubkey == key1.publicKey),
          hasLength(1),
          reason: 'the request must move to its own authenticated connection',
        );

        await ndk.destroy();
        await relay1.stopServer();
      },
    );

    test('closing all transports leaves no authenticated connection', () async {
      MockRelay relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 7,
        requireAuthForRequests: true,
        signEvents: false,
      );

      await relay1.startServer(
        textNotes: {key1: textNote(key1, "note from key1")},
      );

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay1.url],
          engine: engine,
        ),
      );

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      await Future.delayed(Duration(seconds: 1));

      await ndk.requests
          .query(
            filter: Filter(
              kinds: [Nip01Event.kTextNodeKind],
              authors: [key1.publicKey],
            ),
          )
          .future;

      expect(
        ndk.relays.globalState.relays.keys.where((key) => !key.isAnonymous),
        isNotEmpty,
        reason: 'the query must have opened an authenticated connection',
      );

      await ndk.relays.closeAllTransports();

      expect(
        ndk.relays.globalState.relays,
        isEmpty,
        reason: 'an authenticated connection must not survive the close',
      );

      await ndk.destroy();
      await relay1.stopServer();
    });
  });

  group('NIP-42 RelayAuth [${engine.name}]', () {
    final key1 = Bip340.generatePrivateKey();

    Nip01Event textNote(KeyPair key, String content) {
      final event = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key.publicKey,
        content: content,
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      return Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: key.privateKey!,
      );
    }

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
            engine: engine,
          ),
        );

    Filter notesOf(KeyPair key) =>
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key.publicKey]);

    test('never stays unattributable even when a relay refuses', () async {
      final relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 9,
        requireAuthForRequests: true,
        signEvents: false,
      );
      await relay1.startServer(
        textNotes: {key1: textNote(key1, "note from key1")},
      );

      final ndk = ndkFor(relay1);
      // logged in, so the only thing keeping the identity hidden is the policy
      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      await Future.delayed(Duration(seconds: 1));

      final response = ndk.requests.query(
        filter: notesOf(key1),
        auth: const RelayAuth.never(),
      );

      expect(await response.future, isEmpty);
      expect(relay1.receivedAuths, 0);
      expect(
        ndk.relays.globalState.relays.keys.where((key) => !key.isAnonymous),
        isEmpty,
        reason: 'never must not open a connection bound to any identity',
      );

      await ndk.destroy();
      await relay1.stopServer();
    });

    test('allow authenticates once the relay refuses', () async {
      final relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 10,
        requireAuthForRequests: true,
        signEvents: false,
      );
      await relay1.startServer(
        textNotes: {key1: textNote(key1, "note from key1")},
      );

      final ndk = ndkFor(relay1);
      final account1 = signableAccount(key1);
      ndk.accounts.addAccount(
        pubkey: account1.pubkey,
        type: account1.type,
        signer: account1.signer,
      );

      await Future.delayed(Duration(seconds: 1));

      final response = ndk.requests.query(
        filter: notesOf(key1),
        auth: RelayAuth.allow(account1),
      );

      expect(await response.future, isNotEmpty);
      expect(relay1.connectionsAuthenticatedAs(key1.publicKey), 1);
      expect(
        ndk.relays.globalState.relays.keys.where((key) => key.isAnonymous),
        hasLength(1),
        reason: 'allow starts anonymous and leaves that connection anonymous',
      );

      await ndk.destroy();
      await relay1.stopServer();
    });

    test('allow does not authenticate to a relay that never refuses', () async {
      // challenges on connect, but serves requests to anyone
      final relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 15,
        requireAuthForEvents: true,
        signEvents: false,
      );
      await relay1.startServer(
        textNotes: {key1: textNote(key1, "note from key1")},
      );

      final ndk = ndkFor(relay1);
      final account1 = signableAccount(key1);
      ndk.accounts.addAccount(
        pubkey: account1.pubkey,
        type: account1.type,
        signer: account1.signer,
      );

      await Future.delayed(Duration(seconds: 1));

      final response = ndk.requests.query(
        filter: notesOf(key1),
        auth: RelayAuth.allow(account1),
      );

      expect(await response.future, isNotEmpty);
      // an eager authentication is fire and forget, so leave it time to land
      await Future.delayed(Duration(seconds: 1));
      expect(
        relay1.receivedAuths,
        0,
        reason: 'allow reveals the identity only once a relay refuses',
      );

      await ndk.destroy();
      await relay1.stopServer();
    });

    test('require sends the REQ only on the bound connection', () async {
      final relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 11,
        requireAuthForRequests: true,
        signEvents: false,
      );
      await relay1.startServer(
        textNotes: {key1: textNote(key1, "note from key1")},
      );

      final ndk = ndkFor(relay1);
      final account1 = signableAccount(key1);
      ndk.accounts.addAccount(
        pubkey: account1.pubkey,
        type: account1.type,
        signer: account1.signer,
      );

      await Future.delayed(Duration(seconds: 1));

      const requestId = 'require-bound-refusing';
      final response = ndk.requests.requestNostrEvent(
        NdkRequest.query(
          requestId,
          filters: [notesOf(key1)],
          timeoutDuration: Duration(seconds: 5),
          auth: RelayAuth.require(account1),
        ),
      );

      expect(await response.future, isNotEmpty);
      expect(
        relay1.subscriptionsRequestedOutside(key1.publicKey),
        isNot(contains(requestId)),
        reason: 'the REQ must never be written to an unauthenticated socket',
      );
      expect(relay1.connectionsThatRequested(requestId), 1);

      await ndk.destroy();
      await relay1.stopServer();
    });

    test('require binds even when the relay never refuses', () async {
      // challenges on connect, but serves requests to anyone
      final relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 12,
        requireAuthForEvents: true,
        signEvents: false,
      );
      await relay1.startServer(
        textNotes: {key1: textNote(key1, "note from key1")},
      );

      final ndk = ndkFor(relay1);
      final account1 = signableAccount(key1);
      ndk.accounts.addAccount(
        pubkey: account1.pubkey,
        type: account1.type,
        signer: account1.signer,
      );

      await Future.delayed(Duration(seconds: 1));

      const requestId = 'require-bound-quiet';
      final response = ndk.requests.requestNostrEvent(
        NdkRequest.query(
          requestId,
          filters: [notesOf(key1)],
          timeoutDuration: Duration(seconds: 5),
          auth: RelayAuth.require(account1),
        ),
      );

      expect(await response.future, isNotEmpty);
      expect(
        relay1.subscriptionsRequestedOutside(key1.publicKey),
        isNot(contains(requestId)),
        reason: 'require must not wait for a refusal to bind the connection',
      );
      expect(relay1.connectionsThatRequested(requestId), 1);

      await ndk.destroy();
      await relay1.stopServer();
    });

    test('require serves a relay that never challenges, unattributed',
        () async {
      // NIP-42 has no way to authenticate unprompted, so a relay that never
      // challenges never learns who asked. The connection is still bound: it is
      // the only identity that socket may ever assume.
      final relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 14,
        signEvents: false,
      );
      await relay1.startServer(
        textNotes: {key1: textNote(key1, "note from key1")},
      );

      // no bootstrap relay, so every connection relay 1 sees comes from the
      // request itself
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [],
          engine: engine,
        ),
      );
      final account1 = signableAccount(key1);
      ndk.accounts.addAccount(
        pubkey: account1.pubkey,
        type: account1.type,
        signer: account1.signer,
      );

      final response = ndk.requests.query(
        filter: notesOf(key1),
        explicitRelays: [relay1.url],
        auth: RelayAuth.require(account1),
      );

      expect(await response.future, isNotEmpty);
      expect(
        ndk.relays.globalState.relays.keys.map((key) => key.pubkey),
        contains(key1.publicKey),
        reason: 'the request must open the connection bound to its account',
      );
      // the jit engine discovers relays on anonymous connections and only then
      // routes the request onto the bound one, so it pays for a second socket
      expect(relay1.connectedClientCount, engine == NdkEngine.JIT ? 2 : 1);
      expect(relay1.receivedAuths, 0);

      await ndk.destroy();
      await relay1.stopServer();
    });

    test('require with an account that cannot sign sends nothing', () async {
      final relay1 = MockRelay(
        name: "relay 1",
        explicitPort: portBase + 13,
        signEvents: false,
      );
      await relay1.startServer(
        textNotes: {key1: textNote(key1, "note from key1")},
      );

      final ndk = ndkFor(relay1);
      final watchOnly = Account(
        pubkey: key1.publicKey,
        type: AccountType.publicKey,
        signer: Bip340EventSigner(privateKey: null, publicKey: key1.publicKey),
      );

      await Future.delayed(Duration(seconds: 1));

      // no connection can carry it, so it ends on its timeout
      final response = ndk.requests.query(
        filter: notesOf(key1),
        auth: RelayAuth.require(watchOnly),
        timeout: Duration(seconds: 2),
      );

      expect(await response.future, isEmpty);
      expect(relay1.receivedAuths, 0);

      await ndk.destroy();
      await relay1.stopServer();
    });
  });
}
