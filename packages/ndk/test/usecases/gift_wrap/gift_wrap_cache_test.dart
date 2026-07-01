import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';

/// Tests for [GiftWrap.tryFromGiftWrapFromCache].
///
/// The method reads only from the decrypted-payload sidecar cache (no network,
/// no decryption). Each branch is exercised:
///  - non gift-wrap kind -> throws
///  - missing seal sidecar -> null
///  - missing rumor sidecar -> null
///  - invalid seal signature (when verifySignature) -> throws
///  - verifySignature:false skips verification
///  - happy path returns the cached rumor
///  - viewer pubkey comes from the signer (logged-in or custom)
void main() {
  group('GiftWrap.tryFromGiftWrapFromCache', () {
    late Ndk ndk;
    late CacheManager cache;
    late GiftWrap giftWrap;

    late KeyPair alice; // recipient / viewer
    late KeyPair bob; // sender

    setUp(() {
      alice = Bip340.generatePrivateKey();
      bob = Bip340.generatePrivateKey();

      ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [],
        ),
      );
      cache = ndk.config.cache;

      giftWrap = GiftWrap(
        accounts: ndk.accounts,
        eventVerifier: MockEventVerifier(),
        eventSignerFactory: ndk.config.eventSignerFactory,
        decryptedEventPayloads: ndk.decryptedEventPayloads,
      );

      ndk.accounts.loginPrivateKey(
        pubkey: alice.publicKey,
        privkey: alice.privateKey!,
      );
    });

    tearDown(() => ndk.destroy());

    int now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

    /// Builds a real, signed kind:13 seal (from bob -> alice) plus a gift wrap
    /// around it addressed to alice. The seal has a stable id used to key the
    /// rumor sidecar. Login state is restored to alice on return.
    Future<({Nip01Event seal, Nip01Event giftWrap})> buildArtifacts({
      String content = 'hello',
      int kind = 1,
    }) async {
      ndk.accounts.logout();
      ndk.accounts.loginPrivateKey(
        pubkey: bob.publicKey,
        privkey: bob.privateKey!,
      );
      final rumor = await giftWrap.createRumor(
        customPubkey: bob.publicKey,
        content: content,
        kind: kind,
        tags: const [],
      );
      final seal = await giftWrap.sealRumor(
        rumor: rumor,
        recipientPubkey: alice.publicKey,
      );
      final wrap = await giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: alice.publicKey,
      );
      ndk.accounts.logout();
      ndk.accounts.loginPrivateKey(
        pubkey: alice.publicKey,
        privkey: alice.privateKey!,
      );
      return (seal: seal, giftWrap: wrap);
    }

    DecryptedEventPayloadRecord sealSidecar(
      Nip01Event wrap,
      Nip01Event seal,
      String viewer,
    ) =>
        DecryptedEventPayloadRecord(
          eventId: wrap.id,
          viewerPubKey: viewer,
          scheme: DecryptedPayloadScheme.giftWrap,
          status: DecryptedPayloadStatus.ready,
          plaintextContent: Nip01EventModel.fromEntity(seal).toJsonString(),
          createdAt: now(),
          updatedAt: now(),
        );

    DecryptedEventPayloadRecord rumorSidecar(
      Nip01Event seal,
      Nip01Event rumor,
      String viewer,
    ) =>
        DecryptedEventPayloadRecord(
          eventId: seal.id,
          viewerPubKey: viewer,
          scheme: DecryptedPayloadScheme.seal,
          status: DecryptedPayloadStatus.ready,
          plaintextContent: Nip01EventModel.fromEntity(rumor).toJsonString(),
          createdAt: now(),
          updatedAt: now(),
        );

    test('throws when event is not a gift wrap kind', () async {
      final notAWrap = Nip01Event(
        pubKey: alice.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'nope',
      );
      expect(
        () => giftWrap.tryFromGiftWrapFromCache(giftWrap: notAWrap),
        throwsA(isA<Exception>()),
      );
    });

    test('returns null when no seal sidecar is cached', () async {
      final artifacts = await buildArtifacts();
      // cache is empty -> nothing to read
      final result =
          await giftWrap.tryFromGiftWrapFromCache(giftWrap: artifacts.giftWrap);
      expect(result, isNull);
    });

    test('returns null when seal sidecar exists but rumor sidecar is missing',
        () async {
      final artifacts = await buildArtifacts();
      // store only the seal plaintext
      await cache.saveDecryptedEventPayloadRecord(
        sealSidecar(artifacts.giftWrap, artifacts.seal, alice.publicKey),
      );

      final result =
          await giftWrap.tryFromGiftWrapFromCache(giftWrap: artifacts.giftWrap);
      expect(result, isNull);
    });

    test('returns the cached rumor when both sidecars are present', () async {
      final artifacts = await buildArtifacts(content: 'cached body');
      // The rumor that was wrapped.
      final rumor = await giftWrap.createRumor(
        customPubkey: bob.publicKey,
        content: 'cached body',
        kind: 1,
        tags: const [],
      );
      await cache.saveDecryptedEventPayloadRecord(
        sealSidecar(artifacts.giftWrap, artifacts.seal, alice.publicKey),
      );
      await cache.saveDecryptedEventPayloadRecord(
        rumorSidecar(artifacts.seal, rumor, alice.publicKey),
      );

      final result =
          await giftWrap.tryFromGiftWrapFromCache(giftWrap: artifacts.giftWrap);
      expect(result, isNotNull);
      expect(result!.content, 'cached body');
      expect(result.kind, 1);
      expect(result.pubKey, bob.publicKey);
    });

    test('throws when seal signature verification fails', () async {
      final artifacts = await buildArtifacts(content: 'tampered');
      final rumor = await giftWrap.createRumor(
        customPubkey: bob.publicKey,
        content: 'tampered',
        kind: 1,
        tags: const [],
      );
      await cache.saveDecryptedEventPayloadRecord(
        sealSidecar(artifacts.giftWrap, artifacts.seal, alice.publicKey),
      );
      await cache.saveDecryptedEventPayloadRecord(
        rumorSidecar(artifacts.seal, rumor, alice.publicKey),
      );

      // GiftWrap whose verifier always rejects signatures.
      final strictGiftWrap = GiftWrap(
        accounts: ndk.accounts,
        eventVerifier: MockEventVerifier(result: false),
        eventSignerFactory: ndk.config.eventSignerFactory,
        decryptedEventPayloads: ndk.decryptedEventPayloads,
      );

      expect(
        () => strictGiftWrap.tryFromGiftWrapFromCache(
            giftWrap: artifacts.giftWrap),
        throwsA(isA<Exception>()),
      );
    });

    test('skips signature verification when verifySignature is false',
        () async {
      final artifacts = await buildArtifacts(content: 'skip verify');
      final rumor = await giftWrap.createRumor(
        customPubkey: bob.publicKey,
        content: 'skip verify',
        kind: 1,
        tags: const [],
      );
      await cache.saveDecryptedEventPayloadRecord(
        sealSidecar(artifacts.giftWrap, artifacts.seal, alice.publicKey),
      );
      await cache.saveDecryptedEventPayloadRecord(
        rumorSidecar(artifacts.seal, rumor, alice.publicKey),
      );

      // Verifier rejects everything, but verification is bypassed.
      final lenientGiftWrap = GiftWrap(
        accounts: ndk.accounts,
        eventVerifier: MockEventVerifier(result: false),
        eventSignerFactory: ndk.config.eventSignerFactory,
        decryptedEventPayloads: ndk.decryptedEventPayloads,
      );

      final result = await lenientGiftWrap.tryFromGiftWrapFromCache(
        giftWrap: artifacts.giftWrap,
        verifySignature: false,
      );
      expect(result, isNotNull);
      expect(result!.content, 'skip verify');
    });

    test('uses the custom signer pubkey as the cache viewer', () async {
      final artifacts = await buildArtifacts(content: 'custom viewer');

      // A third party viewer (carol) with her own keypair.
      final carol = Bip340.generatePrivateKey();
      final carolSigner = Bip340EventSigner(
        privateKey: carol.privateKey,
        publicKey: carol.publicKey,
      );

      // Author the rumor as bob so it is independent of carol/alice.
      ndk.accounts.logout();
      ndk.accounts.loginPrivateKey(
        pubkey: bob.publicKey,
        privkey: bob.privateKey!,
      );
      final rumor = await giftWrap.createRumor(
        customPubkey: bob.publicKey,
        content: 'custom viewer',
        kind: 1,
        tags: const [],
      );
      // Alice stays logged out here; the custom signer is the only source of
      // the viewer pubkey.
      ndk.accounts.logout();

      // Sidecars keyed under carol's pubkey.
      await cache.saveDecryptedEventPayloadRecord(
        sealSidecar(artifacts.giftWrap, artifacts.seal, carol.publicKey),
      );
      await cache.saveDecryptedEventPayloadRecord(
        rumorSidecar(artifacts.seal, rumor, carol.publicKey),
      );

      final result = await giftWrap.tryFromGiftWrapFromCache(
        giftWrap: artifacts.giftWrap,
        customSigner: carolSigner,
      );
      expect(result, isNotNull);
      expect(result!.content, 'custom viewer');

      // Sanity: without the signer (no logged-in account) it throws rather
      // than silently returning null.
      expect(
        () => giftWrap.tryFromGiftWrapFromCache(giftWrap: artifacts.giftWrap),
        throwsA(anyOf(isA<Exception>(), isA<String>())),
      );
    });

    test('sidecars are viewer-scoped: wrong viewer gets no seal', () async {
      final artifacts = await buildArtifacts();
      final rumor = await giftWrap.createRumor(
        customPubkey: bob.publicKey,
        content: 'scoped',
        kind: 1,
        tags: const [],
      );
      // Store under bob's pubkey, not alice's (the current viewer).
      await cache.saveDecryptedEventPayloadRecord(
        sealSidecar(artifacts.giftWrap, artifacts.seal, bob.publicKey),
      );
      await cache.saveDecryptedEventPayloadRecord(
        rumorSidecar(artifacts.seal, rumor, bob.publicKey),
      );

      final result =
          await giftWrap.tryFromGiftWrapFromCache(giftWrap: artifacts.giftWrap);
      expect(result, isNull);
    });

    test('happy path mirrors a real fromGiftWrap decryption', () async {
      // Full end-to-end: bob wraps for alice, alice decrypts with fromGiftWrap
      // (which populates sidecars), then the cache-only read returns the same
      // rumor without any further decryption.
      ndk.accounts.logout();
      ndk.accounts.loginPrivateKey(
        pubkey: bob.publicKey,
        privkey: bob.privateKey!,
      );
      final rumor = await giftWrap.createRumor(
        customPubkey: bob.publicKey,
        content: 'round trip',
        kind: 14,
        tags: const [
          ['p', 'unused'],
        ],
      );
      final wrap = await giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: alice.publicKey,
      );
      ndk.accounts.logout();
      ndk.accounts.loginPrivateKey(
        pubkey: alice.publicKey,
        privkey: alice.privateKey!,
      );

      final decrypted = await giftWrap.fromGiftWrap(giftWrap: wrap);

      final fromCache =
          await giftWrap.tryFromGiftWrapFromCache(giftWrap: wrap);
      expect(fromCache, isNotNull);
      expect(fromCache!.id, decrypted.id);
      expect(fromCache.content, decrypted.content);
      expect(fromCache.kind, decrypted.kind);

      // The cached JSON round-trips to the same event id.
      final rec = await cache.loadDecryptedEventPayloadRecord(
        eventId: wrap.id,
        viewerPubKey: alice.publicKey,
      );
      expect(rec, isNotNull);
      expect(jsonDecode(rec!.plaintextContent!)['kind'], GiftWrap.kSealEventKind);
    });
  });
}
