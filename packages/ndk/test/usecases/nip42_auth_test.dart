import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() {
  test('request on auth-required relay should return events after AUTH',
      () async {
    final key = Bip340.generatePrivateKey();
    final relay = MockRelay(
      name: "relay",
      requireAuthForRequests: true,
    );

    final testEvent = await Bip340EventSigner(
      privateKey: key.privateKey!,
      publicKey: key.publicKey,
    ).sign(Nip01Event(
      pubKey: key.publicKey,
      kind: Nip01Event.kTextNodeKind,
      tags: [],
      content: "test event",
    ));

    await relay.startServer(textNotes: {key: testEvent});

    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay.url],
    ));

    ndk.accounts.loginPrivateKey(
      pubkey: key.publicKey,
      privkey: key.privateKey!,
    );

    final result = await ndk.requests.query(
      filter: Filter(kinds: [Nip01Event.kTextNodeKind]),
      explicitRelays: [relay.url],
    ).future;

    expect(result, isNotEmpty);
    expect(result.first.content, "test event");

    await ndk.destroy();
    await relay.stopServer();
  });

  test('broadcast on auth-required relay should succeed after AUTH', () async {
    final key = Bip340.generatePrivateKey();
    final relay = MockRelay(
      name: "relay",
      requireAuthForEvents: true,
    );

    await relay.startServer();

    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay.url],
    ));

    ndk.accounts.loginPrivateKey(
      pubkey: key.publicKey,
      privkey: key.privateKey!,
    );

    final event = Nip01Event(
      pubKey: key.publicKey,
      kind: Nip01Event.kTextNodeKind,
      tags: [],
      content: "test broadcast",
    );

    final result = await ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: [relay.url],
    ).broadcastDoneFuture;

    expect(result.any((r) => r.broadcastSuccessful), isTrue);

    await ndk.destroy();
    await relay.stopServer();
  });

  test('gift wrap broadcast on auth-required relay should authenticate as sender',
      timeout: const Timeout(Duration(seconds: 5)), () async {
    final senderKey = Bip340.generatePrivateKey();
    final recipientKey = Bip340.generatePrivateKey();
    final relay = MockRelay(
      name: "gift wrap auth relay",
      requireAuthForEvents: true,
    );

    await relay.startServer();

    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay.url],
      defaultBroadcastTimeout: const Duration(seconds: 2),
    ));

    addTearDown(() async {
      await ndk.destroy();
      await relay.stopServer();
    });

    ndk.accounts.loginPrivateKey(
      pubkey: senderKey.publicKey,
      privkey: senderKey.privateKey!,
    );

    final rumor = await ndk.giftWrap.createRumor(
      content: "gift wrap auth-required broadcast",
      kind: Nip01Event.kTextNodeKind,
      tags: [
        ["p", recipientKey.publicKey]
      ],
    );
    final giftWrap = await ndk.giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: recipientKey.publicKey,
    );

    final result = await ndk.broadcast.broadcast(
      nostrEvent: giftWrap,
      specificRelays: [relay.url],
    ).broadcastDoneFuture;

    expect(result.any((r) => r.broadcastSuccessful), isTrue);
  });

  test(
      'request should complete when relay requires auth but sends no challenge',
      timeout: const Timeout(Duration(seconds: 5)), () async {
    final key = Bip340.generatePrivateKey();
    final relay = MockRelay(
      name: "relay auth no challenge",
      requireAuthForRequests: true,
      sendAuthChallenge: false,
    );

    await relay.startServer();

    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay.url],
    ));

    final result = await ndk.requests
        .query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key.publicKey],
          ),
        )
        .future;

    expect(result, isEmpty);

    await ndk.destroy();
    await relay.stopServer();
  });
}
