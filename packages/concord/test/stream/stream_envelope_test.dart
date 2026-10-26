import 'dart:typed_data';

import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/stream/stream_envelope.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

GroupKey _key(int fill) => groupKey(
  secret: Uint8List.fromList(List.filled(32, fill)),
  label: 'concord/channel',
  id: Uint8List.fromList(List.filled(32, fill + 1)),
  epoch: 0,
);

Nip01Event _rumor(String author, {String content = 'Hey chat!', int? at}) =>
    StreamEnvelope.makeRumor(
      pubkey: author,
      kind: 9,
      content: content,
      createdAt: at,
      tags: const [
        [
          'channel',
          '0707070707070707070707070707070707070707070707070707070707070707',
        ],
        ['epoch', '0'],
        ['ms', '417'],
      ],
    );

Future<Nip01Event> _signAsLocal(Nip01Event e, String sk) =>
    signWithLocalKey(e, sk);

void main() {
  final plane = _key(0x11);
  final author = Bip340.generatePrivateKey();

  group('stream wrap round-trips (CORD-01)', () {
    test('encrypted seal (Chat/Guestbook/rekey planes)', () async {
      final rumor = _rumor(author.publicKey);
      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys.fromGroupKey(plane),
        form: SealForm.encrypted,
        signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
      );

      expect(wrapped.event.kind, 1059);
      expect(wrapped.event.pubKey, plane.pk);
      // Fixed author, ephemeral p — NIP-59 reversed.
      expect(wrapped.event.pTags, hasLength(1));
      expect(
        wrapped.event.pTags.first,
        Bip340.getPublicKey(wrapped.ephemeralSk),
      );
      // created_at is never tweaked, at any layer.
      expect(wrapped.event.createdAt, rumor.createdAt);

      final opened = await StreamEnvelope.unwrap(
        wrap: wrapped.event,
        expectedStreamPk: plane.pk,
        convKey: plane.convKey,
        expectedForm: SealForm.encrypted,
      );
      expect(opened.author, author.publicKey);
      expect(opened.rumor.id, rumor.id);
      expect(opened.rumor.kind, 9);
      expect(opened.rumor.content, 'Hey chat!');
      expect(opened.seal.kind, 20013);
      expect(opened.seal.createdAt, rumor.createdAt);
      expect(opened.rumor.tags, rumor.tags);
    });

    test('plaintext seal (Control Plane only)', () async {
      final rumor = _rumor(author.publicKey, content: '{"name":"Vector"}');
      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys.fromGroupKey(plane),
        form: SealForm.plaintext,
        signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
      );

      final opened = await StreamEnvelope.unwrap(
        wrap: wrapped.event,
        expectedStreamPk: plane.pk,
        convKey: plane.convKey,
        expectedForm: SealForm.plaintext,
      );
      expect(opened.seal.kind, 20014);
      // The plaintext seal's content IS the rumor's serialized JSON,
      // byte-verbatim.
      expect(opened.seal.content, StreamEnvelope.rumorJson(rumor));
      expect(opened.rumor.id, rumor.id);
    });

    test('write-restricted split: staff signer, member read key', () async {
      // Control Plane: wrap signed by the control_root-derived signer,
      // content encrypted under the community_root-derived read key.
      final readKey = _key(0x21);
      final signer = _key(0x31);
      final rumor = _rumor(author.publicKey);

      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys(
          signerSk: signer.sk,
          signerPk: signer.pk,
          convKey: readKey.convKey,
        ),
        form: SealForm.plaintext,
        signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
      );
      expect(wrapped.event.pubKey, signer.pk);

      // A member holding only the read key + the signer's pubkey opens it.
      final opened = await StreamEnvelope.unwrap(
        wrap: wrapped.event,
        expectedStreamPk: signer.pk,
        convKey: readKey.convKey,
      );
      expect(opened.rumor.id, rumor.id);
    });
  });

  group('stream wrap verification failures', () {
    test('wrong conversation key fails', () async {
      final rumor = _rumor(author.publicKey);
      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys.fromGroupKey(plane),
        form: SealForm.encrypted,
        signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
      );
      final impostor = _key(0x55);
      await expectLater(
        StreamEnvelope.unwrap(
          wrap: wrapped.event,
          expectedStreamPk: plane.pk,
          convKey: impostor.convKey,
        ),
        throwsFormatException,
      );
    });

    test('wrap at the wrong stream address is refused', () async {
      final rumor = _rumor(author.publicKey);
      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys.fromGroupKey(plane),
        form: SealForm.encrypted,
        signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
      );
      await expectLater(
        StreamEnvelope.unwrap(
          wrap: wrapped.event,
          expectedStreamPk: _key(0x66).pk,
          convKey: plane.convKey,
        ),
        throwsFormatException,
      );
    });

    test('tampered wrap content fails the MAC', () async {
      final rumor = _rumor(author.publicKey);
      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys.fromGroupKey(plane),
        form: SealForm.encrypted,
        signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
      );
      // Flip one base64 character of the payload.
      final chars = wrapped.event.content.split('');
      chars[40] = chars[40] == 'A' ? 'B' : 'A';
      final tampered = wrapped.event.copyWith(content: chars.join());
      await expectLater(
        StreamEnvelope.unwrap(
          wrap: tampered,
          expectedStreamPk: plane.pk,
          convKey: plane.convKey,
        ),
        throwsA(anything),
      );
    });

    test('forged wrap signature is refused', () async {
      final rumor = _rumor(author.publicKey);
      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys.fromGroupKey(plane),
        form: SealForm.encrypted,
        signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
      );
      final forged = wrapped.event.copyWith(
        sig: Bip340.sign(wrapped.event.id, _key(0x77).sk),
      );
      await expectLater(
        StreamEnvelope.unwrap(
          wrap: forged,
          expectedStreamPk: plane.pk,
          convKey: plane.convKey,
        ),
        throwsFormatException,
      );
    });

    test(
      'rumor author must equal the seal signer (impersonation check)',
      () async {
        // A hostile author encrypts a rumor written under someone else's
        // name, sealed with their own signature.
        final victim = Bip340.generatePrivateKey();
        final victimPub = Bip340.getPublicKey(victim.privateKey!);
        final rumor = _rumor(victimPub);

        final sealContent = await nip44EncryptWithKey(
          StreamEnvelope.rumorJson(rumor),
          plane.convKey,
        );
        final seal = await signWithLocalKey(
          Nip01Event(
            pubKey: author.publicKey,
            kind: 20013,
            tags: const [],
            content: sealContent,
            createdAt: rumor.createdAt,
          ),
          author.privateKey!,
        );
        final sealJson = canonicalEventJson(
          id: seal.id,
          kind: seal.kind,
          pubkey: seal.pubKey,
          content: seal.content,
          tags: seal.tags,
          createdAt: seal.createdAt,
          sig: seal.sig,
        );
        final wrapContent = await nip44EncryptWithKey(sealJson, plane.convKey);
        const ephPk =
            'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
        final wrapId = canonicalEventId(
          pubkey: plane.pk,
          createdAt: rumor.createdAt,
          kind: 1059,
          tags: const [
            ['p', ephPk],
          ],
          content: wrapContent,
        );
        final wrap = Nip01Event(
          id: wrapId,
          pubKey: plane.pk,
          kind: 1059,
          tags: const [
            ['p', ephPk],
          ],
          content: wrapContent,
          sig: Bip340.sign(wrapId, plane.sk),
          createdAt: rumor.createdAt,
        );

        await expectLater(
          StreamEnvelope.unwrap(
            wrap: wrap,
            expectedStreamPk: plane.pk,
            convKey: plane.convKey,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('author'),
            ),
          ),
        );
      },
    );

    test(
      'an embedded rumor id that disagrees with the bytes is refused',
      () async {
        // Plaintext seal: the seal's content IS the rumor JSON. Doctor the
        // embedded id, re-sign the seal, re-wrap.
        final rumor = _rumor(author.publicKey);
        final doctored = StreamEnvelope.rumorJson(
          rumor,
        ).replaceFirst(rumor.id, 'e' * 64);
        final badSeal = await signWithLocalKey(
          Nip01Event(
            pubKey: author.publicKey,
            kind: 20014,
            tags: const [],
            content: doctored,
            createdAt: rumor.createdAt,
          ),
          author.privateKey!,
        );
        final newSealJson = canonicalEventJson(
          id: badSeal.id,
          kind: badSeal.kind,
          pubkey: badSeal.pubKey,
          content: badSeal.content,
          tags: badSeal.tags,
          createdAt: badSeal.createdAt,
          sig: badSeal.sig,
        );
        final newWrapContent = await nip44EncryptWithKey(
          newSealJson,
          plane.convKey,
        );
        final eph = Bip340.generatePrivateKey();
        final wrapId = canonicalEventId(
          pubkey: plane.pk,
          createdAt: rumor.createdAt,
          kind: 1059,
          tags: [
            ['p', eph.publicKey],
          ],
          content: newWrapContent,
        );
        final wrap = Nip01Event(
          id: wrapId,
          pubKey: plane.pk,
          kind: 1059,
          tags: [
            ['p', eph.publicKey],
          ],
          content: newWrapContent,
          sig: Bip340.sign(wrapId, plane.sk),
          createdAt: rumor.createdAt,
        );

        await expectLater(
          StreamEnvelope.unwrap(
            wrap: wrap,
            expectedStreamPk: plane.pk,
            convKey: plane.convKey,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('id'),
            ),
          ),
        );
      },
    );

    test('seal form violations are refused', () async {
      final rumor = _rumor(author.publicKey);
      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys.fromGroupKey(plane),
        form: SealForm.encrypted,
        signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
      );
      // A reader that expects a plaintext seal drops an encrypted one.
      await expectLater(
        StreamEnvelope.unwrap(
          wrap: wrapped.event,
          expectedStreamPk: plane.pk,
          convKey: plane.convKey,
          expectedForm: SealForm.plaintext,
        ),
        throwsFormatException,
      );
    });
  });

  group('caps and limits', () {
    test(
      'a rumor exceeding the NIP-44 plaintext cap is refused at wrap',
      () async {
        final rumor = _rumor(author.publicKey, content: 'x' * 70000);
        await expectLater(
          StreamEnvelope.wrapRumor(
            rumor: rumor,
            keys: PlaneKeys.fromGroupKey(plane),
            form: SealForm.encrypted,
            signSeal: (seal) => _signAsLocal(seal, author.privateKey!),
          ),
          throwsA(isA<SizeError>()),
        );
      },
    );
  });

  group('makeRumor', () {
    test('computes the NIP-01 id and has no signature', () {
      final rumor = _rumor(author.publicKey);
      expect(rumor.sig, isNull);
      expect(
        rumor.id,
        canonicalEventId(
          pubkey: rumor.pubKey,
          createdAt: rumor.createdAt,
          kind: rumor.kind,
          tags: rumor.tags,
          content: rumor.content,
        ),
      );
    });
  });
}
