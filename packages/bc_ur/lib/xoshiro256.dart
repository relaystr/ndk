import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:ur/utils.dart';
import 'package:ur/constants.dart';

// Mask for 64-bit unsigned integers
final BigInt _MASK64 = MAX_UINT64;

BigInt rotl(BigInt x, int k) {
  return ((x << k) | (x >> (64 - k))) & _MASK64;
}

final List<BigInt> JUMP = [
  BigInt.parse('1733541517147835066'), // 0x180ec6d33cfd0aba
  BigInt.parse('15369461998538869804'), // 0xd5a61266f0c9392c
  BigInt.parse('12197330014494892970'), // 0xa9582618e03fc9aa
  BigInt.parse('4138621300654548508') // 0x39abdc4529b1661c
];

final List<BigInt> LONG_JUMP = [
  BigInt.parse('8555335991981124543'), // 0x76e15d3efefdcbbf
  BigInt.parse('14194738350262587827'), // 0xc5004e441c522fb3
  BigInt.parse('8593769755450971713'), // 0x77710069854ee241
  BigInt.parse('4111657796531716661') // 0x39109bb02acbe635
];

class Xoshiro256 {
  List<BigInt> s = List<BigInt>.filled(4, BigInt.zero);

  Xoshiro256([List<BigInt>? arr]) {
    if (arr != null) {
      for (int i = 0; i < 4; i++) {
        s[i] = arr[i];
      }
    }
  }

  void _setS(Uint8List arr) {
    for (int i = 0; i < 4; i++) {
      int o = i * 8;
      BigInt v = BigInt.zero;
      for (int n = 0; n < 8; n++) {
        v = (v << 8) | BigInt.from(arr[o + n]);
        // print("v: " + v.toString());
      }
      s[i] = v;
    }
    // print("s: " + s.toString());
  }

  void _hashThenSetS(Uint8List buf) {
    var digest = sha256.convert(buf).bytes;
    _setS(Uint8List.fromList(digest));
  }

  static Xoshiro256 fromInt8Array(Uint8List arr) {
    var x = Xoshiro256();
    x._setS(arr);
    return x;
  }

  static Xoshiro256 fromBytes(Uint8List buf) {
    var x = Xoshiro256();
    x._hashThenSetS(buf);
    return x;
  }

  static Xoshiro256 fromCrc32(int crc32) {
    var x = Xoshiro256();
    var buf = intToBytes(crc32);
    x._hashThenSetS(buf);
    return x;
  }

  static Xoshiro256 fromString(String s) {
    var x = Xoshiro256();
    var buf = stringToBytes(s);
    x._hashThenSetS(buf);
    return x;
  }

  BigInt next() {
    var temp = (s[1] * BigInt.from(5)) & _MASK64;
    temp = rotl(temp, 7);
    var resultRaw = (temp * BigInt.from(9)) & _MASK64;

    BigInt t = (s[1] << 17) & _MASK64;

    s[2] ^= s[0];
    s[3] ^= s[1];
    s[1] ^= s[2];
    s[0] ^= s[3];

    s[2] ^= t;

    s[3] = rotl(s[3], 45);

    return resultRaw;
  }

  double nextDouble() {
    BigInt m = MAX_UINT64 + BigInt.one;
    BigInt nxt = next();
    return nxt / m;
  }

  int nextInt(int low, int high) {
    return (nextDouble() * (high - low + 1) + low).floor();
  }

  int nextByte() {
    return nextInt(0, 255);
  }

  Uint8List nextData(int count) {
    var result = Uint8List(count);
    for (int i = 0; i < count; i++) {
      result[i] = nextByte();
    }
    return result;
  }

  void jump() {
    BigInt s0 = BigInt.zero,
        s1 = BigInt.zero,
        s2 = BigInt.zero,
        s3 = BigInt.zero;
    for (int i = 0; i < JUMP.length; i++) {
      for (int b = 0; b < 64; b++) {
        if ((JUMP[i] & (BigInt.one << b)) != BigInt.zero) {
          s0 ^= s[0];
          s1 ^= s[1];
          s2 ^= s[2];
          s3 ^= s[3];
        }
        next();
      }
    }
    s[0] = s0;
    s[1] = s1;
    s[2] = s2;
    s[3] = s3;
  }

  void longJump() {
    BigInt s0 = BigInt.zero,
        s1 = BigInt.zero,
        s2 = BigInt.zero,
        s3 = BigInt.zero;
    for (int i = 0; i < LONG_JUMP.length; i++) {
      for (int b = 0; b < 64; b++) {
        if ((LONG_JUMP[i] & (BigInt.one << b)) != BigInt.zero) {
          s0 ^= s[0];
          s1 ^= s[1];
          s2 ^= s[2];
          s3 ^= s[3];
        }
        next();
      }
    }
    s[0] = s0;
    s[1] = s1;
    s[2] = s2;
    s[3] = s3;
  }
}
