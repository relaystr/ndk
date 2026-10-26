import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// HKDF-SHA256 exactly as CORD-02 Appendix A.1 freezes it:
///
/// ```text
/// hkdf(secret, label, id, epoch):
///     HKDF-SHA256(
///         ikm  = secret,
///         salt = ∅,                                       // zero-length
///         info = utf8(label) || 0x00 || id[32] || epoch_be[8],
///         len  = 32 )
/// ```
///
/// The salt is zero-length (RFC 5869 allows it; the extract step becomes
/// HMAC with an all-zero key of hash length — implemented here as an empty
/// key per the spec's literal "∅"). Validated against RFC 5869 test
/// vectors in the test suite.
Uint8List hkdfSha256({
  required Uint8List ikm,
  required Uint8List info,
  int length = 32,
}) {
  final prk = hkdfExtract(ikm: ikm, salt: const <int>[]);
  return hkdfExpand(prk: prk, info: info, length: length);
}

/// RFC 5869 HKDF-Extract.
Uint8List hkdfExtract({required Uint8List ikm, required List<int> salt}) {
  final hmac = Hmac(sha256, salt);
  return Uint8List.fromList(hmac.convert(ikm).bytes);
}

/// RFC 5869 HKDF-Expand.
Uint8List hkdfExpand({
  required Uint8List prk,
  required Uint8List info,
  required int length,
}) {
  if (length > 255 * 32) {
    throw ArgumentError.value(length, 'length', 'too long for SHA-256 HKDF');
  }
  final hashLen = 32;
  final n = (length + hashLen - 1) ~/ hashLen;
  final okm = <int>[];
  var previous = <int>[];
  for (var i = 1; i <= n; i++) {
    final hmac = Hmac(sha256, prk);
    previous = hmac.convert(<int>[...previous, ...info, i]).bytes;
    okm.addAll(previous);
  }
  return Uint8List.fromList(okm.sublist(0, length));
}

/// utf8(label) bytes for use in an HKDF info block.
Uint8List labelBytes(String label) => Uint8List.fromList(utf8.encode(label));
