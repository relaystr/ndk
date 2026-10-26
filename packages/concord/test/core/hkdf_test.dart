import 'dart:convert';
import 'dart:typed_data';

import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/core/hkdf.dart';
import 'package:test/test.dart';

Uint8List _hex(String hex) => Uint8List.fromList(
  List<int>.generate(
    hex.length ~/ 2,
    (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ),
);

void main() {
  group('HKDF-SHA256 (RFC 5869 test vectors)', () {
    test('case 1: extract + expand with salt and info', () {
      final ikm = _hex('0b' * 22);
      final salt = _hex('000102030405060708090a0b0c');
      final info = _hex('f0f1f2f3f4f5f6f7f8f9');

      final prk = hkdfExtract(ikm: ikm, salt: salt);
      expect(
        bytesToHex(prk),
        '077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5',
      );

      final okm = hkdfExpand(prk: prk, info: info, length: 42);
      expect(
        bytesToHex(okm),
        '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865',
      );
    });

    test('case 3: zero-length salt and info (the Concord shape)', () {
      final ikm = _hex('0b' * 22);
      final prk = hkdfExtract(ikm: ikm, salt: const []);
      expect(
        bytesToHex(prk),
        '19ef24a32c717b167f33a91d6f648bdf96596776afdb6377ac434c1c293ccb04',
      );

      final okm = hkdfExpand(prk: prk, info: Uint8List(0), length: 42);
      expect(
        bytesToHex(okm),
        '8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8',
      );
    });

    test('hkdfSha256 matches extract+expand', () {
      final ikm = _hex('0b' * 22);
      final info = _hex('f0f1f2f3f4f5f6f7f8f9');
      final combined = hkdfSha256(ikm: ikm, info: info, length: 42);
      final prk = hkdfExtract(ikm: ikm, salt: const []);
      final expanded = hkdfExpand(prk: prk, info: info, length: 42);
      expect(bytesToHex(combined), bytesToHex(expanded));
    });

    test('different info blocks produce different keys', () {
      final ikm = _hex('11' * 32);
      final a = hkdfSha256(ikm: ikm, info: utf8.encode('a'));
      final b = hkdfSha256(ikm: ikm, info: utf8.encode('b'));
      expect(bytesToHex(a), isNot(bytesToHex(b)));
      expect(a.length, 32);
    });

    test('rejects over-long output', () {
      expect(
        () => hkdfExpand(
          prk: Uint8List(32),
          info: Uint8List(0),
          length: 255 * 32 + 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
