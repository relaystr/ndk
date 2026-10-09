import 'dart:convert';
import 'dart:typed_data';

import 'package:bech32/bech32.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../../isolates/isolate_manager.dart';
import '../nip19/hrps.dart';
import '../nip19/nip19_utils.dart';
import '../nip44/utils.dart';
import 'scrypt.dart';

/// How the private key was handled before being encrypted.
enum Nip49KeySecurity {
  /// Known to have been handled insecurely (stored or pasted unencrypted).
  insecure(0x00),

  /// Not known to have been handled insecurely.
  secure(0x01),

  /// The client does not track it.
  unknown(0x02);

  final int value;

  const Nip49KeySecurity(this.value);
}

/// NIP-49 private key encryption (`ncryptsec`).
/// https://github.com/nostr-protocol/nips/blob/master/49.md
class Nip49 {
  static const int defaultLogN = 16;

  /// 1 GiB of scrypt memory, the same cap as nostr-tools.
  static const int maxLogN = 20;

  static const int _version = 0x02;
  static const int _payloadLength = 91;

  /// Encrypts the hex [privateKey] with [password] into an `ncryptsec` string.
  ///
  /// [logN] is the scrypt cost: 2^logN rounds, 64 MiB of memory at 16.
  static Future<String> encrypt(
    String privateKey,
    String password, {
    int logN = defaultLogN,
    Nip49KeySecurity keySecurity = Nip49KeySecurity.unknown,
  }) async {
    final privateKeyBytes = hex.decode(privateKey);
    if (privateKeyBytes.length != 32) {
      throw ArgumentError.value(privateKey, 'privateKey', 'must be 32 bytes');
    }
    RangeError.checkValueInInterval(logN, 1, maxLogN, 'logN');

    final salt = secureRandomBytes(16);
    final nonce = secureRandomBytes(24);
    final associatedData = [keySecurity.value];

    final symmetricKey = await _deriveKey(password, salt, logN);
    final secretBox = await Xchacha20.poly1305Aead().encrypt(
      privateKeyBytes,
      secretKey: SecretKey(symmetricKey),
      nonce: nonce,
      aad: associatedData,
    );

    final payload = [
      _version,
      logN,
      ...salt,
      ...nonce,
      ...associatedData,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];
    final data = Nip19Utils.convertBits(payload, 8, 5, true);
    final input = Bech32(Hrps.kNcryptsec, data);
    return Bech32Encoder().convert(input, input.hrp.length + data.length + 10);
  }

  /// Decrypts an `ncryptsec` string with [password] and returns the hex
  /// private key.
  ///
  /// Throws [SecretBoxAuthenticationError] when the password is wrong.
  static Future<String> decrypt(String ncryptsec, String password) async {
    final decoded = Bech32Decoder().convert(ncryptsec, ncryptsec.length);
    if (decoded.hrp != Hrps.kNcryptsec) {
      throw FormatException('Not an ${Hrps.kNcryptsec}', ncryptsec);
    }
    final payload = Nip19Utils.convertBits(decoded.data, 5, 8, false);
    if (payload.length != _payloadLength || payload[0] != _version) {
      throw FormatException('Unsupported ${Hrps.kNcryptsec}', ncryptsec);
    }

    final logN = payload[1];
    RangeError.checkValueInInterval(logN, 1, maxLogN, 'logN');
    final salt = Uint8List.fromList(payload.sublist(2, 18));
    final nonce = payload.sublist(18, 42);
    final associatedData = payload.sublist(42, 43);
    final cipherText = payload.sublist(43, 75);
    final mac = payload.sublist(75);

    final symmetricKey = await _deriveKey(password, salt, logN);
    final privateKey = await Xchacha20.poly1305Aead().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(symmetricKey),
      aad: associatedData,
    );
    return hex.encode(privateKey);
  }

  static Future<Uint8List> _deriveKey(
    String password,
    Uint8List salt,
    int logN,
  ) {
    return IsolateManager.instance.runInComputeIsolate(_scrypt, (
      password: password,
      salt: salt,
      logN: logN,
    ));
  }

  static Uint8List _scrypt(
    ({String password, Uint8List salt, int logN}) params,
  ) {
    return scrypt(
      utf8.encode(unorm.nfkc(params.password)),
      params.salt,
      n: 1 << params.logN,
      r: 8,
      p: 1,
      dkLen: 32,
    );
  }
}
