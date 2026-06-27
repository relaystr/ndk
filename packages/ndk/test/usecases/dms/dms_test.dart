import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

/// Tests for the NIP-17 [Dms] usecase.
///
/// These are integration tests: a real [Ndk] instance talks to an in-process
/// [MockRelay]. Gift wrap / seal cryptography is exercised end-to-end, so the
/// happy-path tests prove the full send -> store -> load -> decrypt cycle.
void main() async {
  group('dms', () {
    late MockRelay relay;
    late Ndk ndk;

    // Sender (the logged-in user in most tests)
    late KeyPair alice;
    // Peer
    late KeyPair bob;

    setUp(() async {
      alice = Bip340.generatePrivateKey();
      bob = Bip340.generatePrivateKey();

      relay = MockRelay(name: 'dm relay', explicitPort: 5201);
      await relay.startServer();

      final cache = MemCacheManager();
      final config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay.url],
        ignoreRelays: [],
      );
      ndk = Ndk(config);
      await ndk.relays.seedRelaysConnected;

      // Alice logs in
      ndk.accounts.loginPrivateKey(
        pubkey: alice.publicKey,
        privkey: alice.privateKey!,
      );
    });

    tearDown(() async {
      await ndk.destroy();
      await relay.stopServer();
    });

    /// Publishes a NIP-17 DM relay list (kind 10050) for [pubKey] containing
    /// [urls], signed with [privKey], directly into the relay's storage.
    Future<void> publishDmRelayList(
      KeyPair owner, {
      required List<String> urls,
    }) async {
      final event = Nip01Event(
        pubKey: owner.publicKey,
        kind: Nip51List.kDmRelays,
        content: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tags: [
          for (final url in urls) ['relay', url],
        ],
      );
      final signed = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: owner.privateKey!,
      );
      await ndk.config.cache.saveEvent(signed);
    }

    test('requires a logged-in account to send', () async {
      ndk.accounts.logout();
      expect(
        () => ndk.dms.sendMessage(
          recipientPubKey: bob.publicKey,
          content: 'hi',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sendMessage throws when sender has no DM relays', () async {
      // Alice logged in but has no kind 10050 anywhere
      await expectLater(
        ndk.dms.sendMessage(
          recipientPubKey: bob.publicKey,
          content: 'hi',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sendMessage throws when recipient has no DM relays', () async {
      await publishDmRelayList(alice, urls: [relay.url]);

      expect(
        ndk.dms.sendMessage(
          recipientPubKey: bob.publicKey,
          content: 'hi',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sendMessage broadcasts a wrapped copy to each side\'s DM relays',
        () async {
      await publishDmRelayList(alice, urls: [relay.url]);
      await publishDmRelayList(bob, urls: [relay.url]);

      await ndk.dms.sendMessage(
        recipientPubKey: bob.publicKey,
        content: 'hello bob',
      );

      // The mock relay should have received two distinct gift wrap events
      // (one for the recipient, one for the sender).
      final giftWraps = relay.receivedEvents
          .where((e) => e.kind == GiftWrap.kGiftWrapEventkind)
          .toList();
      expect(giftWraps.length, greaterThanOrEqualTo(2));

      final recipients = giftWraps
          .map((e) => e.pTags)
          .expand((p) => p)
          .toSet();
      expect(recipients, containsAll([alice.publicKey, bob.publicKey]));
    });

    test('sendMessage with additional tags keeps the p tag on the rumor',
        () async {
      await publishDmRelayList(alice, urls: [relay.url]);
      await publishDmRelayList(bob, urls: [relay.url]);

      await ndk.dms.sendMessage(
        recipientPubKey: bob.publicKey,
        content: 'with subject',
        additionalTags: const [
          ['subject', 'greeting'],
        ],
      );

      // Login as bob and load the conversation to verify the rumor carries the
      // extra tag through the gift wrap.
      ndk.accounts.logout();
      ndk.accounts.loginPrivateKey(
        pubkey: bob.publicKey,
        privkey: bob.privateKey!,
      );
      await publishDmRelayList(bob, urls: [relay.url]);

      final conversations = await ndk.dms.loadConversations(
        timeout: const Duration(seconds: 10),
      );
      expect(conversations, isNotEmpty);

      final aliceConv = conversations.firstWhere(
        (c) => c.peerPubKey == alice.publicKey,
      );
      expect(aliceConv.messages, isNotEmpty);
      final rumor = aliceConv.messages.first.rumor;
      expect(
        rumor.tags.any((t) =>
            t.length >= 2 && t[0] == 'subject' && t[1] == 'greeting'),
        isTrue,
      );
    });

    test('loadConversations throws when not logged in', () async {
      ndk.accounts.logout();
      expect(
        ndk.dms.loadConversations(),
        throwsA(isA<Exception>()),
      );
    });

    test('loadConversations throws when user has no DM relays', () async {
      await expectLater(
        ndk.dms.loadConversations(),
        throwsA(isA<Exception>()),
      );
    });

    test('loadConversations returns empty when no messages exist', () async {
      await publishDmRelayList(alice, urls: [relay.url]);

      final conversations = await ndk.dms.loadConversations(
        timeout: const Duration(seconds: 10),
      );
      expect(conversations, isEmpty);
    });

    test('loadConversation returns empty list for unknown peer', () async {
      await publishDmRelayList(alice, urls: [relay.url]);

      final messages = await ndk.dms.loadConversation(
        peerPubKey: bob.publicKey,
        timeout: const Duration(seconds: 10),
      );
      expect(messages, isEmpty);
    });

    test(
        'send then load round-trip groups messages by peer and marks direction',
        () async {
      await publishDmRelayList(alice, urls: [relay.url]);
      await publishDmRelayList(bob, urls: [relay.url]);

      // Alice sends two messages to bob. createdAt is second-precision, so we
      // wait > 1s between sends to guarantee a strict ordering.
      await ndk.dms.sendMessage(
        recipientPubKey: bob.publicKey,
        content: 'message 1',
      );
      await Future.delayed(const Duration(seconds: 2));
      await ndk.dms.sendMessage(
        recipientPubKey: bob.publicKey,
        content: 'message 2',
      );

      // Alice can load her own conversations from her DM relays
      final aliceConversations = await ndk.dms.loadConversations(
        timeout: const Duration(seconds: 10),
      );
      expect(aliceConversations.length, 1);
      final aliceConv = aliceConversations.first;
      expect(aliceConv.peerPubKey, bob.publicKey);
      expect(aliceConv.messages.length, 2);
      // Alice authored these, so they are outgoing for her.
      for (final m in aliceConv.messages) {
        expect(m.isOutgoing, isTrue);
      }
      // messages are sorted ascending by createdAt; second message is newest
      expect(aliceConv.latestMessage.content, 'message 2');

      // Bob logs in and sees the conversation as incoming.
      ndk.accounts.logout();
      ndk.accounts.loginPrivateKey(
        pubkey: bob.publicKey,
        privkey: bob.privateKey!,
      );

      final bobConversation = await ndk.dms.loadConversation(
        peerPubKey: alice.publicKey,
        timeout: const Duration(seconds: 10),
      );
      expect(bobConversation.length, 2);
      for (final m in bobConversation) {
        expect(m.isOutgoing, isFalse);
        expect(m.peerPubKey, alice.publicKey);
      }
      final contents = bobConversation.map((m) => m.content).toSet();
      expect(contents, containsAll(['message 1', 'message 2']));
    });

    test('conversations are sorted by latest message descending', () async {
      await publishDmRelayList(alice, urls: [relay.url]);
      await publishDmRelayList(bob, urls: [relay.url]);

      final carol = Bip340.generatePrivateKey();
      await publishDmRelayList(carol, urls: [relay.url]);

      // Send to bob first, then carol. createdAt is second-precision so we
      // space the sends by > 1s to guarantee carol's conversation is newer.
      await ndk.dms.sendMessage(
        recipientPubKey: bob.publicKey,
        content: 'to bob',
      );
      await Future.delayed(const Duration(seconds: 2));
      await ndk.dms.sendMessage(
        recipientPubKey: carol.publicKey,
        content: 'to carol',
      );

      final conversations = await ndk.dms.loadConversations(
        timeout: const Duration(seconds: 10),
      );
      expect(conversations.length, 2);
      // carol's conversation is newer -> first
      expect(conversations.first.peerPubKey, carol.publicKey);
      expect(conversations.last.peerPubKey, bob.publicKey);
    });

    test('loadConversationsSnapshot reads only from cache', () async {
      await publishDmRelayList(alice, urls: [relay.url]);

      // Nothing in cache -> empty
      var snapshot = await ndk.dms.loadConversationsSnapshot();
      expect(snapshot, isEmpty);

      // Populate cache by sending + loading
      await publishDmRelayList(bob, urls: [relay.url]);
      await ndk.dms.sendMessage(
        recipientPubKey: bob.publicKey,
        content: 'cached msg',
      );
      await ndk.dms.loadConversations(
        timeout: const Duration(seconds: 10),
      );

      snapshot = await ndk.dms.loadConversationsSnapshot();
      // After a network load, the gift wraps are cached and decryptable via
      // the decrypted payload sidecar cache.
      final bobConv = snapshot.where((c) => c.peerPubKey == bob.publicKey);
      expect(bobConv, isNotEmpty);
      expect(bobConv.first.messages.first.content, 'cached msg');
    });

    test('loadConversationSnapshot reads only from cache', () async {
      await publishDmRelayList(alice, urls: [relay.url]);

      var messages = await ndk.dms.loadConversationSnapshot(
        peerPubKey: bob.publicKey,
      );
      expect(messages, isEmpty);
    });

    test('parseWrappedMessage returns null for non-DM rumor kind', () async {
      await publishDmRelayList(alice, urls: [relay.url]);
      await publishDmRelayList(bob, urls: [relay.url]);

      // Build a gift wrap around a kind:1 event (not kind 14) addressed to
      // alice so she can decrypt it.
      final rumor = await ndk.giftWrap.createRumor(
        content: 'not a dm',
        kind: 1,
        tags: [
          ['p', bob.publicKey],
        ],
      );
      final wrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: alice.publicKey,
      );

      final parsed = await ndk.dms.parseWrappedMessage(
        wrappedEvent: wrap,
      );
      expect(parsed, isNull);
    });

    test('parseWrappedMessage parses a valid incoming DM', () async {
      await publishDmRelayList(alice, urls: [relay.url]);
      await publishDmRelayList(bob, urls: [relay.url]);

      // Bob authors a DM rumor and wraps it for alice.
      final rumor = await ndk.giftWrap.createRumor(
        customPubkey: bob.publicKey,
        content: 'hi alice',
        kind: Dms.kMessageKind,
        tags: [
          ['p', alice.publicKey],
        ],
      );
      final wrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: alice.publicKey,
      );

      final parsed = await ndk.dms.parseWrappedMessage(
        wrappedEvent: wrap,
      );
      expect(parsed, isNotNull);
      expect(parsed!.content, 'hi alice');
      expect(parsed.peerPubKey, bob.publicKey);
      expect(parsed.isOutgoing, isFalse);
    });

    test('parseWrappedMessage resolves outgoing direction for author',
        () async {
      await publishDmRelayList(alice, urls: [relay.url]);
      await publishDmRelayList(bob, urls: [relay.url]);

      // Alice authors a DM rumor and wraps it for herself (sender copy).
      final rumor = await ndk.giftWrap.createRumor(
        content: 'self copy',
        kind: Dms.kMessageKind,
        tags: [
          ['p', bob.publicKey],
        ],
      );
      final wrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: alice.publicKey,
      );

      final parsed = await ndk.dms.parseWrappedMessage(
        wrappedEvent: wrap,
      );
      expect(parsed, isNotNull);
      expect(parsed!.isOutgoing, isTrue);
      expect(parsed.peerPubKey, bob.publicKey);
    });

    test('kMessageKind is the NIP-17 text message kind (14)', () {
      expect(Dms.kMessageKind, 14);
    });
  });
}
