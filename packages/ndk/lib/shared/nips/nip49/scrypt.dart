import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// scrypt (RFC 7914) on 32-bit words. pointycastle's byte-oriented version is
/// too slow once compiled to JavaScript.
Uint8List scrypt(
  List<int> password,
  List<int> salt, {
  required int n,
  required int r,
  required int p,
  required int dkLen,
}) {
  if (n < 2 || n & (n - 1) != 0) {
    throw ArgumentError.value(n, 'n', 'must be a power of 2 greater than 1');
  }
  final blockWords = 32 * r;
  final b = _bytesToWords(_pbkdf2(password, salt, 128 * r * p));
  final v = Uint32List(blockWords * n);
  final x = Uint32List(blockWords);
  final y = Uint32List(blockWords);
  final t = Uint32List(16);

  for (var i = 0; i < p; i++) {
    final offset = i * blockWords;
    x.setRange(0, blockWords, b, offset);
    for (var j = 0; j < n; j++) {
      v.setRange(j * blockWords, (j + 1) * blockWords, x);
      _blockMix(x, y, t, r);
    }
    for (var j = 0; j < n; j++) {
      final vOffset = (x[blockWords - 16] & (n - 1)) * blockWords;
      for (var k = 0; k < blockWords; k++) {
        x[k] ^= v[vOffset + k];
      }
      _blockMix(x, y, t, r);
    }
    b.setRange(offset, offset + blockWords, x);
  }

  return _pbkdf2(password, _wordsToBytes(b), dkLen);
}

void _blockMix(Uint32List b, Uint32List y, Uint32List t, int r) {
  t.setRange(0, 16, b, (2 * r - 1) * 16);
  for (var i = 0; i < 2 * r; i++) {
    for (var k = 0; k < 16; k++) {
      t[k] ^= b[i * 16 + k];
    }
    _salsa20_8(t);
    final offset = ((i & 1) * r + (i >> 1)) * 16;
    y.setRange(offset, offset + 16, t);
  }
  b.setRange(0, 32 * r, y);
}

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
int _rotl(int a, int bits) {
  a &= 0xffffffff;
  return ((a << bits) | (a >>> (32 - bits))) & 0xffffffff;
}

void _salsa20_8(Uint32List b) {
  var x0 = b[0], x1 = b[1], x2 = b[2], x3 = b[3];
  var x4 = b[4], x5 = b[5], x6 = b[6], x7 = b[7];
  var x8 = b[8], x9 = b[9], x10 = b[10], x11 = b[11];
  var x12 = b[12], x13 = b[13], x14 = b[14], x15 = b[15];

  for (var i = 0; i < 8; i += 2) {
    x4 ^= _rotl(x0 + x12, 7);
    x8 ^= _rotl(x4 + x0, 9);
    x12 ^= _rotl(x8 + x4, 13);
    x0 ^= _rotl(x12 + x8, 18);
    x9 ^= _rotl(x5 + x1, 7);
    x13 ^= _rotl(x9 + x5, 9);
    x1 ^= _rotl(x13 + x9, 13);
    x5 ^= _rotl(x1 + x13, 18);
    x14 ^= _rotl(x10 + x6, 7);
    x2 ^= _rotl(x14 + x10, 9);
    x6 ^= _rotl(x2 + x14, 13);
    x10 ^= _rotl(x6 + x2, 18);
    x3 ^= _rotl(x15 + x11, 7);
    x7 ^= _rotl(x3 + x15, 9);
    x11 ^= _rotl(x7 + x3, 13);
    x15 ^= _rotl(x11 + x7, 18);
    x1 ^= _rotl(x0 + x3, 7);
    x2 ^= _rotl(x1 + x0, 9);
    x3 ^= _rotl(x2 + x1, 13);
    x0 ^= _rotl(x3 + x2, 18);
    x6 ^= _rotl(x5 + x4, 7);
    x7 ^= _rotl(x6 + x5, 9);
    x4 ^= _rotl(x7 + x6, 13);
    x5 ^= _rotl(x4 + x7, 18);
    x11 ^= _rotl(x10 + x9, 7);
    x8 ^= _rotl(x11 + x10, 9);
    x9 ^= _rotl(x8 + x11, 13);
    x10 ^= _rotl(x9 + x8, 18);
    x12 ^= _rotl(x15 + x14, 7);
    x13 ^= _rotl(x12 + x15, 9);
    x14 ^= _rotl(x13 + x12, 13);
    x15 ^= _rotl(x14 + x13, 18);
  }

  b[0] += x0;
  b[1] += x1;
  b[2] += x2;
  b[3] += x3;
  b[4] += x4;
  b[5] += x5;
  b[6] += x6;
  b[7] += x7;
  b[8] += x8;
  b[9] += x9;
  b[10] += x10;
  b[11] += x11;
  b[12] += x12;
  b[13] += x13;
  b[14] += x14;
  b[15] += x15;
}

/// PBKDF2-HMAC-SHA256 with a single iteration, which is all scrypt uses.
Uint8List _pbkdf2(List<int> password, List<int> salt, int length) {
  final hmac = Hmac(sha256, password);
  final out = Uint8List(length);
  for (var i = 1, offset = 0; offset < length; i++, offset += 32) {
    final block = hmac.convert([
      ...salt,
      (i >> 24) & 0xff,
      (i >> 16) & 0xff,
      (i >> 8) & 0xff,
      i & 0xff,
    ]).bytes;
    out.setRange(offset, min(offset + 32, length), block);
  }
  return out;
}

Uint32List _bytesToWords(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return Uint32List.fromList([
    for (var i = 0; i < bytes.length; i += 4) data.getUint32(i, Endian.little),
  ]);
}

Uint8List _wordsToBytes(Uint32List words) {
  final data = ByteData(words.length * 4);
  for (var i = 0; i < words.length; i++) {
    data.setUint32(i * 4, words[i], Endian.little);
  }
  return data.buffer.asUint8List();
}
