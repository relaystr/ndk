import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('Nip17FileCrypto', () {
    test('encrypts and decrypts AES-256-GCM with fresh key/nonce pairs',
        () async {
      final plaintext = Uint8List.fromList(utf8.encode('private evidence'));
      final first = await Nip17FileCrypto.encrypt(plaintext);
      final second = await Nip17FileCrypto.encrypt(plaintext);

      expect(first.key, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(first.nonce, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(first.ciphertext.length, plaintext.length + 16);
      expect(first.key, isNot(second.key));
      expect(first.nonce, isNot(second.nonce));

      final metadata = Nip17FileMetadata.fromEncryptedFile(
        url: Uri.parse('https://blossom.example/${first.encryptedSha256}.bin'),
        mimeType: 'image/jpeg',
        encryptedFile: first,
      );
      expect(
        await Nip17FileCrypto.decrypt(
          ciphertext: first.ciphertext,
          metadata: metadata,
        ),
        plaintext,
      );
    });

    test('decrypts the Amethyst-compatible ciphertext plus tag framing',
        () async {
      final ciphertext = _hex(
        'c8334e228b18508f2542ce4486973164c6ec05bd5e6f60a72916fcf61cf327dcae751877e35ee4',
      );
      final metadata = Nip17FileMetadata(
        url: Uri.parse('https://blossom.example/vector.bin'),
        mimeType: 'application/octet-stream',
        encryptionAlgorithm: Nip17FileMetadata.aesGcm,
        decryptionKey:
            '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f',
        decryptionNonce: '101112131415161718191a1b1c1d1e1f',
        encryptedSha256:
            '83af07e6b24e6a15833ef85e34b598ee66535917f2ba1ed190420f9853b62f5f',
        originalSha256:
            '09bc44e4cd50386d8f2028b2c8eeefeaefdd98efa0c716cdefcdfb0f512ea468',
        size: ciphertext.length,
      );

      final plaintext = await Nip17FileCrypto.decrypt(
        ciphertext: ciphertext,
        metadata: metadata,
      );
      expect(utf8.decode(plaintext), 'BitBlik NIP-17 evidence');
    });

    test('rejects an encrypted hash mismatch before decryption', () async {
      final encrypted = await Nip17FileCrypto.encrypt(
        Uint8List.fromList(utf8.encode('evidence')),
      );
      final tampered = Uint8List.fromList(encrypted.ciphertext)..[0] ^= 1;
      final metadata = Nip17FileMetadata.fromEncryptedFile(
        url: Uri.parse('https://blossom.example/file.bin'),
        mimeType: 'image/png',
        encryptedFile: encrypted,
      );

      await expectLater(
        Nip17FileCrypto.decrypt(ciphertext: tampered, metadata: metadata),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects tampering even when the encrypted hash is replaced',
        () async {
      final encrypted = await Nip17FileCrypto.encrypt(
        Uint8List.fromList(utf8.encode('evidence')),
      );
      final tampered = Uint8List.fromList(encrypted.ciphertext)..[0] ^= 1;
      final metadata = Nip17FileMetadata(
        url: Uri.parse('https://blossom.example/file.bin'),
        mimeType: 'image/png',
        encryptionAlgorithm: Nip17FileMetadata.aesGcm,
        decryptionKey: encrypted.key,
        decryptionNonce: encrypted.nonce,
        encryptedSha256: sha256.convert(tampered).toString(),
        originalSha256: encrypted.originalSha256,
        size: tampered.length,
      );

      await expectLater(
        Nip17FileCrypto.decrypt(ciphertext: tampered, metadata: metadata),
        throwsA(anything),
      );
    });
  });

  group('Nip17FileMetadata', () {
    test('round-trips required kind-15 tags', () async {
      final encrypted = await Nip17FileCrypto.encrypt(Uint8List.fromList([1]));
      final metadata = Nip17FileMetadata.fromEncryptedFile(
        url: Uri.parse('https://blossom.example/file.bin'),
        mimeType: 'image/webp',
        encryptedFile: encrypted,
        dimensions: '1x1',
      );
      final rumor = Nip01Event(
        pubKey: 'a' * 64,
        kind: Dms.kFileMessageKind,
        tags: [
          ['p', 'b' * 64],
          ...metadata.toTags(),
        ],
        content: metadata.url.toString(),
      );

      final parsed = Nip17FileMetadata.tryParse(rumor);
      expect(parsed, isNotNull);
      expect(parsed!.mimeType, 'image/webp');
      expect(parsed.size, encrypted.size);
      expect(parsed.dimensions, '1x1');
    });

    test('rejects duplicated private metadata tags', () async {
      final encrypted = await Nip17FileCrypto.encrypt(Uint8List.fromList([1]));
      final metadata = Nip17FileMetadata.fromEncryptedFile(
        url: Uri.parse('https://blossom.example/file.bin'),
        mimeType: 'image/png',
        encryptedFile: encrypted,
      );
      final rumor = Nip01Event(
        pubKey: 'a' * 64,
        kind: Dms.kFileMessageKind,
        tags: [
          ['p', 'b' * 64],
          ...metadata.toTags(),
          ['x', encrypted.encryptedSha256],
        ],
        content: metadata.url.toString(),
      );

      expect(Nip17FileMetadata.tryParse(rumor), isNull);
    });

    test('accepts base64url key and nonce from older clients', () async {
      final key = Uint8List(32);
      final nonce = Uint8List(12);
      final rumor = Nip01Event(
        pubKey: 'a' * 64,
        kind: Dms.kFileMessageKind,
        tags: [
          ['p', 'b' * 64],
          ['file-type', 'image/png'],
          ['encryption-algorithm', Nip17FileMetadata.aesGcm],
          ['decryption-key', base64Url.encode(key).replaceAll('=', '')],
          ['decryption-nonce', base64Url.encode(nonce).replaceAll('=', '')],
          ['x', '1' * 64],
          ['ox', '2' * 64],
          ['size', '17'],
        ],
        content: 'https://blossom.example/file.bin',
      );

      expect(Nip17FileMetadata.tryParse(rumor), isNotNull);
    });
  });
}

Uint8List _hex(String value) => Uint8List.fromList([
      for (var i = 0; i < value.length; i += 2)
        int.parse(value.substring(i, i + 2), radix: 16),
    ]);
