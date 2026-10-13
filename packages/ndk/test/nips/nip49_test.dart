import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip49/scrypt.dart';
import 'package:test/test.dart';

void main() {
  const privateKey =
      '3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683';

  test('decrypts the NIP-49 test vector', () async {
    const ncryptsec =
        'ncryptsec1qgg9947rlpvqu76pj5ecreduf9jxhselq2nae2kghhvd5g7dgjtcxfqtd67p9m0w57lspw8gsq6yphnm8623nsl8xn9j4jdzz84zm3frztj3z7s35vpzmqf6ksu8r89qk5z2zxfmu5gv8th8wclt0h4p';

    expect(await Nip49.decrypt(ncryptsec, 'nostr'), privateKey);
  });

  test('round trips a private key', () async {
    final ncryptsec = await Nip49.encrypt(
      privateKey,
      'password',
      logN: 8,
      keySecurity: Nip49KeySecurity.secure,
    );

    expect(ncryptsec, startsWith('ncryptsec1'));
    expect(await Nip49.decrypt(ncryptsec, 'password'), privateKey);
  });

  test('rejects a wrong password', () async {
    final ncryptsec = await Nip49.encrypt(privateKey, 'password', logN: 8);

    expect(
      Nip49.decrypt(ncryptsec, 'wrong'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('normalizes the password to NFKC', () async {
    final ncryptsec = await Nip49.encrypt(privateKey, 'ÅΩẛ̣', logN: 8);

    expect(await Nip49.decrypt(ncryptsec, 'ÅΩṩ'), privateKey);
  });

  test('rejects a string that is not an ncryptsec', () {
    expect(
      Nip49.decrypt(Nip19.encodePrivateKey(privateKey), 'password'),
      throwsA(isA<FormatException>()),
    );
  });

  test('scrypt matches the RFC 7914 test vectors', () {
    expect(
      hex.encode(
        scrypt(
          utf8.encode('password'),
          utf8.encode('NaCl'),
          n: 1024,
          r: 8,
          p: 16,
          dkLen: 64,
        ),
      ),
      'fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b3731622eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640',
    );
    expect(
      hex.encode(
        scrypt(
          utf8.encode('pleaseletmein'),
          utf8.encode('SodiumChloride'),
          n: 16384,
          r: 8,
          p: 1,
          dkLen: 64,
        ),
      ),
      '7023bdcb3afd7348461c06cd81fd38ebfda8fbba904f8e3ea9b543f6545da1f2d5432955613f0fcf62d49705242a9af9e61e85dc0d651e40dfcf017b45575887',
    );
  });
}
