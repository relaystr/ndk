@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:web_event_verifier/web_event_verifier.dart';

void main() {
  late WebEventVerifier verifier;
  late Bip340EventSigner signer;

  setUpAll(() {
    verifier = WebEventVerifier();
    final keyPair = Bip340.generatePrivateKey();
    signer = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );
  });

  Future<Nip01Event> createSignedEvent({
    List<List<String>> tags = const [],
    String content = 'test content',
    int kind = 1,
  }) async {
    final event = Nip01Event(
      pubKey: signer.getPublicKey(),
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: kind,
      tags: tags,
      content: content,
    );
    return await signer.sign(event);
  }

  group('WebEventVerifier', () {
    test('verifies valid event', () async {
      final event = await createSignedEvent(content: 'hello world');
      expect(await verifier.verify(event), isTrue);
    });

    test('verifies event with tags', () async {
      final event = await createSignedEvent(
        tags: [
          ['e', 'abc123'],
          ['p', 'def456'],
        ],
        content: 'content with tags',
      );
      expect(await verifier.verify(event), isTrue);
    });

    test('rejects event with tampered id', () async {
      final event = await createSignedEvent();
      final tampered = Nip01Event(
        id: 'aaaa${event.id.substring(4)}',
        pubKey: event.pubKey,
        createdAt: event.createdAt,
        kind: event.kind,
        tags: event.tags,
        content: event.content,
        sig: event.sig,
      );
      expect(await verifier.verify(tampered), isFalse);
    });

    test('rejects event with tampered content', () async {
      final event = await createSignedEvent();
      final tampered = Nip01Event(
        id: event.id,
        pubKey: event.pubKey,
        createdAt: event.createdAt,
        kind: event.kind,
        tags: event.tags,
        content: 'tampered content',
        sig: event.sig,
      );
      expect(await verifier.verify(tampered), isFalse);
    });

    test('rejects event with tampered signature', () async {
      final event = await createSignedEvent();
      final tampered = Nip01Event(
        id: event.id,
        pubKey: event.pubKey,
        createdAt: event.createdAt,
        kind: event.kind,
        tags: event.tags,
        content: event.content,
        sig: 'aaaa${event.sig!.substring(4)}',
      );
      expect(await verifier.verify(tampered), isFalse);
    });

    test('rejects event with null signature', () async {
      final event = Nip01Event(
        pubKey: signer.getPublicKey(),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 1,
        tags: [],
        content: 'unsigned event',
      );
      expect(await verifier.verify(event), isFalse);
    });
  });
}
