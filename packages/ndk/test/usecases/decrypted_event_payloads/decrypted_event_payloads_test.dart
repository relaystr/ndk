import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('DecryptedEventPayloads', () {
    late CacheManager cacheManager;
    late DecryptedEventPayloads usecase;
    late Nip01Event event;

    setUp(() {
      cacheManager = MemCacheManager();
      usecase = DecryptedEventPayloads(cacheManager: cacheManager);
      event = Nip01Event(
        pubKey: 'author-pubkey',
        kind: 4,
        tags: const [],
        content: 'ciphertext',
      );
    });

    test('decrypts on miss and persists plaintext sidecar', () async {
      final plaintext = await usecase.loadOrDecrypt(
        event: event,
        viewerPubKey: 'viewer-pubkey',
        scheme: DecryptedPayloadScheme.nip44,
        decrypt: () async => 'hello plaintext',
      );

      expect(plaintext, 'hello plaintext');

      final stored = await cacheManager.loadDecryptedEventPayloadRecord(
        eventId: event.id,
        viewerPubKey: 'viewer-pubkey',
      );

      expect(stored, isNotNull);
      expect(stored!.status, DecryptedPayloadStatus.ready);
      expect(stored.plaintextContent, 'hello plaintext');
      expect(stored.scheme, DecryptedPayloadScheme.nip44);
      expect(stored.sourceEventPubKey, event.pubKey);
      expect(stored.sourceEventKind, event.kind);
    });

    test('returns cached plaintext without calling decrypt again', () async {
      await cacheManager.saveDecryptedEventPayloadRecord(
        DecryptedEventPayloadRecord(
          eventId: event.id,
          viewerPubKey: 'viewer-pubkey',
          scheme: DecryptedPayloadScheme.nip44,
          status: DecryptedPayloadStatus.ready,
          plaintextContent: 'cached plaintext',
          createdAt: 1,
          updatedAt: 1,
          decryptedAt: 1,
          sourceEventPubKey: event.pubKey,
          sourceEventKind: event.kind,
        ),
      );

      var decryptCalls = 0;
      final plaintext = await usecase.loadOrDecrypt(
        event: event,
        viewerPubKey: 'viewer-pubkey',
        scheme: DecryptedPayloadScheme.nip44,
        decrypt: () async {
          decryptCalls += 1;
          return 'should not happen';
        },
      );

      expect(plaintext, 'cached plaintext');
      expect(decryptCalls, 0);
    });

    test('persists classified decrypt failures and rethrows', () async {
      await expectLater(
        () => usecase.loadOrDecrypt(
          event: event,
          viewerPubKey: 'viewer-pubkey',
          scheme: DecryptedPayloadScheme.nip44,
          decrypt: () async => throw StateError('boom'),
          classifyFailure: (_, __) => DecryptedPayloadStatus.permanentFailure,
        ),
        throwsA(isA<StateError>()),
      );

      final stored = await cacheManager.loadDecryptedEventPayloadRecord(
        eventId: event.id,
        viewerPubKey: 'viewer-pubkey',
      );
      expect(stored, isNotNull);
      expect(stored!.status, DecryptedPayloadStatus.permanentFailure);
      expect(stored.failureReason, contains('boom'));
      expect(stored.plaintextContent, isNull);
    });

    test('coalesces concurrent decrypts for the same event and viewer',
        () async {
      var decryptCalls = 0;

      final futures = List.generate(
        2,
        (_) => usecase.loadOrDecrypt(
          event: event,
          viewerPubKey: 'viewer-pubkey',
          scheme: DecryptedPayloadScheme.nip44,
          decrypt: () async {
            decryptCalls += 1;
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return 'shared plaintext';
          },
        ),
      );

      final results = await Future.wait(futures);

      expect(results, ['shared plaintext', 'shared plaintext']);
      expect(decryptCalls, 1);
    });
  });
}
