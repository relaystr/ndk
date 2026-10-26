import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Encoding rules that apply everywhere (CORD-01 "Encoding", checklist
/// "Encoding"):
///
///  * hex is lowercase, every 32-byte value is 64 lowercase hex characters
///  * pubkeys are x-only hex, never bech32
///  * tag values are strings; an integer tag is its decimal form without
///    leading zeros
///  * empty content is `""`, never null

final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');

/// Throws [FormatException] unless [hex] is 64 lowercase hex characters.
String checkHex32(String hex, [String what = 'value']) {
  if (!_hex64.hasMatch(hex)) {
    throw FormatException('$what must be 64 lowercase hex characters', hex);
  }
  return hex;
}

/// Lowercases and validates a hex string of any length.
String checkHex(String hex, [String what = 'value']) {
  if (hex.length.isOdd || !RegExp(r'^[0-9a-f]*$').hasMatch(hex)) {
    throw FormatException('$what must be lowercase hex', hex);
  }
  return hex;
}

Uint8List hexToBytes(String hex) {
  checkHex(hex);
  return Uint8List.fromList(
    List<int>.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ),
  );
}

String bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Canonical decimal form for integer tag values: no leading zeros.
String decimalTag(int value) {
  if (value < 0) {
    throw FormatException('tag integers are non-negative', '$value');
  }
  return '$value';
}

/// Parses a decimal-string tag value, rejecting leading zeros and garbage.
/// Returns null when the value is malformed (such values are *dropped*,
/// never interpreted — checklist).
int? tryParseDecimal(String value) {
  if (value.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(value)) return null;
  if (value.length > 1 && value.startsWith('0')) return null; // leading zero
  return int.tryParse(value);
}

/// Concatenates byte blocks.
Uint8List concatBytes(List<List<int>> parts) {
  final total = parts.fold<int>(0, (n, p) => n + p.length);
  final out = Uint8List(total);
  var offset = 0;
  for (final part in parts) {
    out.setRange(offset, offset + part.length, part);
    offset += part.length;
  }
  return out;
}

/// u64 big-endian encoding, used for epochs in every frozen derivation.
Uint8List u64Be(int value) {
  if (value < 0) {
    throw RangeError.value(value, 'epoch', 'must be non-negative');
  }
  final out = Uint8List(8);
  var v = value;
  for (var i = 7; i >= 0; i--) {
    out[i] = v & 0xFF;
    v >>= 8;
  }
  return out;
}

/// Decodes a u64 big-endian block.
int u64BeDecode(Uint8List bytes, [int offset = 0]) {
  var v = 0;
  for (var i = 0; i < 8; i++) {
    v = (v << 8) | bytes[offset + i];
  }
  return v;
}

/// UTF-8 byte length, for the protocol's byte-based caps.
int utf8Length(String s) => utf8.encode(s).length;

/// `jsonEncode` with a stable entry point for the protocol's content strings.
String encodeJson(Object? value) => jsonEncode(value);

/// sha256 over raw bytes, lowercase hex.
String sha256Hex(List<int> data) =>
    bytesToHex(Uint8List.fromList(sha256.convert(data).bytes));

/// NIP-01 event id: `sha256([0, pubkey, created_at, kind, tags, content])`.
///
/// This is the id of both signed events and unsigned rumors (the rumor's id
/// inside a seal uses exactly this serialization).
String canonicalEventId({
  required String pubkey,
  required int createdAt,
  required int kind,
  required List<List<String>> tags,
  required String content,
}) {
  return sha256Hex(
    utf8.encode(jsonEncode([0, pubkey, createdAt, kind, tags, content])),
  );
}

/// Canonical event JSON in the order the spec shows:
/// `id, kind, pubkey, content, tags, created_at` (+ `sig` when present).
///
/// For a plaintext seal this exact string is the seal's content and is
/// carried **byte-verbatim** on re-wrap (CORD-01), so the order is fixed
/// here rather than left to a JSON library.
String canonicalEventJson({
  required String id,
  required int kind,
  required String pubkey,
  required String content,
  required List<List<String>> tags,
  required int createdAt,
  String? sig,
}) {
  final map = <String, Object?>{
    'id': id,
    'kind': kind,
    'pubkey': pubkey,
    'content': content,
    'tags': tags,
    'created_at': createdAt,
    'sig': ?sig,
  };
  return jsonEncode(map);
}
